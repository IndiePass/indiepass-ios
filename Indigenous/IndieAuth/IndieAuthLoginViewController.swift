//
//  ViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 4/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import SafariServices

let callbackUrl = URL(string: "indigenous://auth/callback")
let appClientId = "http://indigenous.abode.pub"
let indieAuthSetupUrl = "https://indieauth.com/setup"
let kSafariViewControllerCloseNotification = "kSafariViewControllerCloseNotification"

public class IndieAuthLoginViewController: UIViewController, UITextFieldDelegate, SFSafariViewControllerDelegate {
    
    var userEndpoints: [String : [URL]] = [:]
    var userAccessToken: String? = nil
    var userScope: String? = nil
    var authSession: SFAuthenticationSession?
    
    enum IndieWebEndpointType: String {
        case Authorization = "authorization_endpoint"
        case Token = "token_endpoint"
        case Micropub = "micropub"
    }
    
    @IBOutlet weak var indieAuthDomain: UITextField?
    @IBOutlet weak var progressDisplay: UIStackView!
    @IBOutlet weak var loginDisplay: UIStackView!
    @IBOutlet weak var domainInput: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func cancelLogin(_ sender: UIButton = UIButton()) {
        authSession?.cancel()
        cancelButton?.isHidden = true
        loginDisplay?.isHidden = false
        progressDisplay?.isHidden = true
    }
    
    @IBAction func readAboutIndieAuth(_ sender: UIButton) {
        if let openUrl = URL(string: indieAuthSetupUrl) {
            DispatchQueue.main.sync {
                let safariVC = SFSafariViewController(url: openUrl)
                self.present(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func loginWithIndieAuth(_ sender: UIButton?) {
        
        cancelButton?.isHidden = false;
        loginDisplay?.isHidden = true
        progressDisplay?.isHidden = false
    
        var url: URL? = nil
        
        if let urlDescription = indieAuthDomain?.text {
            // Take url from text field and convert it to a normalized URL
            url = IndieAuth.normalizeMeURL(url: urlDescription)
        }
        
        if (url != nil) {
            
            // URL is normalized, next steps
            RealLinkParser.getRelLinks(fromUrl: url!) { meEndpoints in
                
                // We need to save these endpoints for later use
                self.userEndpoints = meEndpoints
                print("User Endponts")
                print(self.userEndpoints)
                
                if let newUrl = self.userEndpoints["url"]?[0] {
                    url = newUrl
                }
                
                guard let authorizationEndpoints = self.userEndpoints["authorization_endpoint"] else {
                    let urlString = url!.absoluteString
                    self.presentErrorLoginAgain("Authorization Endpoint not found on \(urlString)")
                    return
                }
                
                guard self.userEndpoints["token_endpoint"] != nil else {
                    let urlString = url!.absoluteString
                    self.presentErrorLoginAgain("Token Endpoint not found on \(urlString)")
                    return
                }
                
                guard self.userEndpoints["micropub"] != nil else {
                    let urlString = url!.absoluteString
                    self.presentErrorLoginAgain("Micropub Endpoint not found on \(urlString)")
                    return
                }
                
//                    let authorizationUrl = IndieAuth.buildAuthorizationURL(forEndpoint: authorizationEndpoints[0], meUrl: url!, redirectURI: callbackUrl!, clientId: appClientId, state: "Testing", scope: "read follow mute block create update")
                let authorizationUrl = IndieAuth.buildAuthorizationURL(forEndpoint: authorizationEndpoints[0], meUrl: url!, redirectURI: callbackUrl!, clientId: appClientId, state: "Testing", scope: "create")
                
                if let openUrl = authorizationUrl {
                    DispatchQueue.main.sync {
                        self.authSession = SFAuthenticationSession(url: openUrl, callbackURLScheme: callbackUrl?.absoluteString) { (callback: URL?, error: Error? ) in
                            //Handle auth
                            print("completion called")
                            guard error == nil, let successURL = callback else {
                                print("In guard statement")
                                print(callback)
                                print(error)
                                self.cancelButton?.isHidden = true
                                self.loginDisplay?.isHidden = false
                                self.progressDisplay?.isHidden = true
                                return
                            }
                            
                            DispatchQueue.global(qos: .background).async {
                                self.indieAuthProcess(urlResponse: successURL)
                            }
                        }
                        self.authSession?.start()
                    }
                }
            }
            
        } else {
            presentErrorLoginAgain("Sorry, that URL is not valid")
        }
        
    }
    
    // Recieve a response URL from a authorization request or a token request. Process the url and call the appropriate functions to continue
    public func indieAuthProcess(urlResponse: URL) {
        print("indie auth processing begun")
        
        var responseUrlComponents = URLComponents(url: urlResponse.absoluteURL, resolvingAgainstBaseURL: false)
        var responseItems: [String: String] = [:]
        var responseType: String? = nil
        
        if let items = responseUrlComponents?.queryItems {
            for queryItem in items {
                if let value = queryItem.value {
                    if (queryItem.name == "code") {
                        responseType = "code"
                    } else if (queryItem.name == "access_token") {
                        responseType = "access_token"
                    }
                    responseItems[queryItem.name] = value
                }
            }
        }
        
        if let type = responseType {
            switch type {
            case "code":
                if let meUrl = URL(string: responseItems["me"]!) {
                    indieAuthProcess(authorizationCode: responseItems["code"]!, state: responseItems["state"] ?? "", meUrl: meUrl)
                }
            case "access_token":
                print("Run Token")
            default: break
            }
        }
    }
    
    public func indieAuthProcess(authorizationCode: String, state: String, meUrl: URL) {
        
        let copyOfUserEndpoints = userEndpoints;
        
        if let tokenEndpoints = userEndpoints["token_endpoint"] {
            IndieAuth.makeTokenRequest(forEndpoint: tokenEndpoints[0], meUrl: meUrl, code: authorizationCode, redirectURI: callbackUrl!, clientId: appClientId, state: state) { _, scope, accessToken in
                
                guard scope.lowercased().range(of:"create") != nil else {
                    self.presentErrorLoginAgain("Recieved scope of \(scope), you must be authorized with at least create scope.")
                    return
                }
                
                let micropubAuth = [
                    "access_token": accessToken,
                    "scope": scope,
                    "me": meUrl.absoluteString,
                    "microsub_endpoint": copyOfUserEndpoints["microsub"]?.first?.absoluteString ?? "",
                    "micropub_endpoint": copyOfUserEndpoints["micropub"]?.first?.absoluteString ?? "",
                    "authorization_endpoint": copyOfUserEndpoints["authorization_endpoint"]?.first?.absoluteString ?? "",
                    "token_endpoint": copyOfUserEndpoints["token_endpoint"]?.first?.absoluteString ?? ""
                ]
                
                let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
                defaults?.set(micropubAuth, forKey: "micropubAuth")
                
                DispatchQueue.main.sync {
                    self.dismiss(animated: true, completion: nil)
                }
                
            }
        }
        
    }
    
    private func presentErrorLoginAgain(_ errorString: String) {
        DispatchQueue.main.sync {
            let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                self.cancelLogin()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // Mark: View Controller Functions
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loginWithIndieAuth(nil)
        return true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        indieAuthDomain?.delegate = self
        domainInput?.becomeFirstResponder()
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Utlity Methods
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            var matches: [String] = []
            for match in results {
                for n in 1..<match.numberOfRanges {
                    let range = match.range(at: n)
                    let r = text.index(text.startIndex, offsetBy: range.location) ..< text.index(text.startIndex, offsetBy: range.location+range.length)
                    matches.append(text.substring(with: r))
                }
            }
            
            
            
            return matches
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

}

