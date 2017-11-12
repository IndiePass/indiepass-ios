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
    
    enum IndieWebEndpointType: String {
        case Authorization = "authorization_endpoint"
        case Token = "token_endpoint"
        case Micropub = "micropub"
    }
    
    @IBOutlet weak var indieAuthDomain: UITextField?
    @IBOutlet weak var progressDisplay: UIStackView!
    @IBOutlet weak var loginDisplay: UIStackView!
    @IBOutlet weak var domainInput: UITextField!
    
    @IBAction func readAboutIndieAuth(_ sender: UIButton) {
        if let openUrl = URL(string: indieAuthSetupUrl) {
            DispatchQueue.main.sync {
                let safariVC = SFSafariViewController(url: openUrl)
                self.present(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func loginWithIndieAuth(_ sender: UIButton?) {
        
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
                
                if let authorizationEndpoints = meEndpoints["authorization_endpoint"] {
//                    let authorizationUrl = IndieAuth.buildAuthorizationURL(forEndpoint: authorizationEndpoints[0], meUrl: url!, redirectURI: callbackUrl!, clientId: appClientId, state: "Testing", scope: "read follow mute block create update")
                    let authorizationUrl = IndieAuth.buildAuthorizationURL(forEndpoint: authorizationEndpoints[0], meUrl: url!, redirectURI: callbackUrl!, clientId: appClientId, state: "Testing", scope: "create")
                    
                    if let openUrl = authorizationUrl {
                        DispatchQueue.main.sync {
                            let safariVC = SFSafariViewController(url: openUrl)
                            safariVC.delegate = self
                            self.present(safariVC, animated: true, completion: nil)
                        }
                    }
                }
            }
            
        } else {
            print("Error, url not valid")
        }
        
    }
    
    // Recieve a response URL from a authorization request or a token request. Process the url and call the appropriate functions to continue
    public func indieAuthProcess(urlResponse: URL) {
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
                    // Hide Safari View Controller
                    self.presentedViewController?.dismiss(animated: true, completion: nil)
                    self.dismiss(animated: true, completion: nil)
                    self.progressDisplay?.isHidden = true
                    self.loginDisplay?.isHidden = false
                }
                
            }
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

