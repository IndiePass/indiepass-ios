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
//let callbackUrl = URL(string: "https://indigenous.abode.pub/ios-login-redirect")
let appClientId = "https://indigenous.abode.pub/ios/"
let indieAuthSetupUrl = "https://indigenous.abode.pub/ios/help/#indieauth"
let kSafariViewControllerCloseNotification = "kSafariViewControllerCloseNotification"

public class IndieAuthLoginViewController: UIViewController, UITextFieldDelegate, SFSafariViewControllerDelegate {
    
    var userEndpoints: [String : [URL]] = [:]
    var userAccessToken: String? = nil
    var userScope: String? = nil
    var authSession: SFAuthenticationSession?
    var delegate: IndieAuthDelegate?
    var displayedAsModal: Bool? = nil
    var dataController: DataController!
    
    enum IndieWebEndpointType: String {
        case Authorization = "authorization_endpoint"
        case Token = "token_endpoint"
        case Micropub = "micropub"
    }
    
    @IBOutlet weak var indieAuthDomain: UITextField?
    @IBOutlet weak var domainInput: UITextField!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var domainView: UIView!
    @IBOutlet weak var authorizingText: UILabel!
    @IBOutlet weak var authorizingProgressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indieAuthLink: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var indieAuthInfo: UIStackView!
    
    @IBAction func cancelLogin(_ sender: UIButton = UIButton()) {
        authSession?.cancel()
        progressView?.isHidden = true
        loginView?.isHidden = false
        indieAuthInfo?.isHidden = false
    }
    
    @IBAction func readAboutIndieAuth(_ sender: UIButton) {
        if let openUrl = URL(string: indieAuthSetupUrl),
        UIApplication.shared.canOpenURL(openUrl) {
            UIApplication.shared.open(openUrl)
        }
    }
    
    @IBAction func loginWithIndieAuth(_ sender: UIButton?) {
        
        progressView?.isHidden = false
        loginView?.isHidden = true
        indieAuthInfo?.isHidden = true
        
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
                var authScope = ["create"];
                print("User Endponts")
                print(self.userEndpoints)
                
                // todo: Figure out when these scopes would be added to the request
                // "follow mute block update"
                
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
                
                if self.userEndpoints["microsub"] != nil {
                    // if a microsub endpoint is found, request read authorization
                    authScope.append("read")
                }
                
                let authorizationUrl = IndieAuth.buildAuthorizationURL(forEndpoint: authorizationEndpoints[0], meUrl: url!, redirectURI: callbackUrl!, clientId: appClientId, state: RandomString(length: 12), scope: authScope.joined(separator: " "))
                
                if let openUrl = authorizationUrl {
                    DispatchQueue.main.async {
                        self.authSession = SFAuthenticationSession(url: openUrl, callbackURLScheme: callbackUrl?.absoluteString) { (callback: URL?, error: Error? ) in
                            //Handle auth
                            print("completion called")
                            guard error == nil, let successURL = callback else {
                                print("In guard statement")
                                print(String(describing: callback))
                                print(String(describing: error))
                                self.progressView?.isHidden = true
                                self.loginView?.isHidden = false
                                self.indieAuthInfo?.isHidden = false
                                return
                            }
                            
                            DispatchQueue.global(qos: .background).async {
                                self.indieAuthProcess(loginFor: url!, urlResponse: successURL)
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
    public func indieAuthProcess(loginFor meUrl: URL, urlResponse: URL) {
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
        
        print(responseType ?? "")
        print(responseItems)
        
        if let type = responseType {
            switch type {
            case "code":
                indieAuthProcess(authorizationCode: responseItems["code"]!, state: responseItems["state"] ?? "", meUrl: meUrl)
            case "access_token":
                print("Run Token")
            default: break
            }
        }
    }
    
    public func indieAuthProcess(authorizationCode: String, state: String, meUrl: URL) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        var micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        
        let copyOfUserEndpoints = userEndpoints;
        
        if let tokenEndpoints = userEndpoints["token_endpoint"] {
            IndieAuth.makeTokenRequest(forEndpoint: tokenEndpoints[0], meUrl: meUrl, code: authorizationCode, redirectURI: callbackUrl!, clientId: appClientId, state: state) { [weak self] _, scope, accessToken in
                
                guard scope.lowercased().contains("create") || scope.lowercased().contains("post") else {
                    // TODO: Figure out why this error screen isn't working
                    // What is wrong??
                    self?.presentErrorLoginAgain("Recieved scope of \(scope), you must be authorized with at least create scope.")
                    return
                }
                
                var accountScopes: [IndieAuthScope] = []
                scope.components(separatedBy: "+").forEach { scopeString in
                    if let newScope = IndieAuthScope(rawValue: scopeString) {
                        accountScopes.append(newScope)
                    }
                    
                }
                
                // todo: Fetch User's Endpoint and create profile
                let accountProfile = Jf2Post()
                accountProfile.type = .card
                accountProfile.name = "Test"
                accountProfile.url = meUrl
                accountProfile.photo = [URL(string: "https://eddiehinkle.com/images/profile.jpg")!]
                
                guard let micropubEndpoint = copyOfUserEndpoints["micropub"]?.first else {
                    print("ERROR! no micropub endpoint")
                    return
                }
                
                guard let authorizationEndpoint = copyOfUserEndpoints["authorization_endpoint"]?.first else {
                    print("ERROR! no authorization endpoint")
                    return
                }
                
                guard let tokenEndpoint = copyOfUserEndpoints["token_endpoint"]?.first else {
                    print("ERROR! no token endpoint")
                    return
                }
                
                IndieAuth.getMicropubConfig(forEndpoint: micropubEndpoint, withToken: accessToken) { [weak self] config, error in
                    
                    var micropubConfig = config
                    
                    IndieAuth.getSyndicationTargets(forEndpoint: micropubEndpoint, withToken: accessToken) { [weak self] syndicateTargets, error in
                        
                        if error != nil && syndicateTargets == nil {
                            print("Error on Syndication Targets")
                            print(error ?? "")
                        } else {
                            micropubConfig?.syndicateTo = syndicateTargets
                        }
                    
                        if let newAccount = try? JSONEncoder().encode(IndieAuthAccount(profile: accountProfile,
                                                                                       access_token: accessToken,
                                                                                       scope: accountScopes,
                                                                                       me: meUrl,
                                                                                       micropub_endpoint: micropubEndpoint,
                                                                                       authorization_endpoint: authorizationEndpoint,
                                                                                       token_endpoint: tokenEndpoint,
                                                                                       microsub_endpoint: copyOfUserEndpoints["microsub"]?.first,
                                                                                       micropub_config: micropubConfig)) {
                            micropubAccounts.append(newAccount)
                        }
                        
                        // The active account should now be the last item in the accounts array
                        let activeAccount = micropubAccounts.count - 1
                        
                        let defaultAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
                        
                        defaults?.set(defaultAccount, forKey: "defaultAccount")
                        defaults?.set(micropubAccounts, forKey: "micropubAccounts")
                        defaults?.set(activeAccount, forKey: "activeAccounts")
                        
                        print("processing completed")
                        
                        if let displayedModal = self?.displayedAsModal, displayedModal == true {
                            DispatchQueue.main.async {
                                self?.dismiss(animated: true, completion: nil)
                            }
                        } else {
                            let appView = UIStoryboard(name: "Main", bundle: nil)
                            if let appVC = appView.instantiateInitialViewController() as? MainViewController,
                            let dataController = self?.dataController {
                                appVC.dataController = dataController
                                self?.present(appVC, animated: true, completion: nil)
                            }
                        }
                        
                    }
                }
            }
        }
        
    }
    
    private func presentErrorLoginAgain(_ errorString: String) {
        DispatchQueue.main.async {
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
        view.backgroundColor = ThemeManager.currentTheme().mainColor
        domainView.backgroundColor = ThemeManager.currentTheme().backgroundColor
        authorizingText.textColor = ThemeManager.currentTheme().backgroundColor
        authorizingProgressIndicator.color = ThemeManager.currentTheme().backgroundColor
        domainInput.textColor = ThemeManager.currentTheme().mainColor
        indieAuthDomain?.delegate = self
        indieAuthLink.tintColor = ThemeManager.currentTheme().backgroundColor
        loginButton.tintColor = ThemeManager.currentTheme().backgroundColor
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        DispatchQueue.main.async { [weak self] in
            self?.domainInput?.becomeFirstResponder()
        }
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

