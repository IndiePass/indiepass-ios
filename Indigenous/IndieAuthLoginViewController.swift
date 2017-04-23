//
//  ViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 4/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import SafariServices

class IndieAuthLoginViewController: UIViewController,UITextFieldDelegate {
    
    enum IndieWebEndpointType: String {
        case Authorization = "authorization_endpoint"
        case Token = "token_endpoint"
        case Micropub = "micropub"
    }
    
    @IBOutlet weak var indieAuthDomain: UITextField?
    
    @IBAction func readAboutIndieAuth(_ sender: UIButton) {
        if let openUrl = URL(string: "https://indieauth.com/setup") {
            let safariVC = SFSafariViewController(url: openUrl)
            self.present(safariVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func loginWithIndieAuth(_ sender: UIButton?) {
    
        var url: URL? = nil
        
        if let urlDescription = indieAuthDomain?.text {
            // Take url from text field and convert it to a normalized URL
            url = normalizeMeURL(url: urlDescription)
        }
        
        if (url != nil) {
            // URL is normalized, next step
            discoverEndpoint(.Authorization, atUrl: url!) { endpointUrl in
                if let authorizationEndpoint = endpointUrl {
                    print("Authorization Endpoint Found \(authorizationEndpoint)")
                } else {
                    print("Authorization Endpoint Failed");
                }
            }
            
        } else {
            print("Error, url not valid")
        }
        
    }
    
    // Input: Any URL or string like "eddiehinkle.com"
    // Output: Normlized URL (default to http if no scheme, default "/" path)
    //         or return false if not a valid URL (has query string params, etc)
    private func normalizeMeURL(url: String) -> URL? {
        
        var meUrl = URLComponents(string: url)
        
        // If there is no scheme or host, the host is probably in the path
        if (meUrl?.scheme == nil && meUrl?.host == nil) {
            // If the path is nil or empty, then our url is probably empty. Mayday!
            if (meUrl?.path == nil || meUrl?.path == "") {
                return nil;
            }
            
            // Split the path into segments so we can seperate the host and the path
            let pathSegments = meUrl?.path.characters.split(separator: "/").map(String.init)
            
            meUrl?.host = pathSegments?.first;
            meUrl?.path = "/" + (pathSegments?.dropFirst().joined() ?? "")
        }
        
        // If no scheme, we default to http
        if (meUrl?.scheme == nil) {
            meUrl?.scheme = "http"
        } else if (meUrl?.scheme != "http" && meUrl?.scheme != "https") {
            // If there is a scheme, we only accept http and https schemes
            print("Scheme existed and wasn't http or https: \(meUrl?.scheme ?? "No Scheme")")
            return nil
        }
        
        // We default to a path of /
        if (meUrl?.path == nil || meUrl?.path == "") {
            meUrl?.path = "/"
        }
        
        // We don't want query or fragment messing up our url. Just set those to nil
        meUrl?.fragment = nil
        meUrl?.query = nil
        
        return meUrl?.url
    }
    
    private func discoverEndpoint(_ endpointType: IndieWebEndpointType, atUrl meUrl: URL, completion: @escaping (URL?) -> ()) {
        let request = URLRequest(url: meUrl)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on \(meUrl)")
                print(error ?? "No error present")
                return
            }
            
            // Check if endpoint is in the HTTP Header fields
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.allHeaderFields)
                if let linkHeaderString = httpResponse.allHeaderFields["Link"] as? String {
                    print("Link Headers Found")
                    let linkHeaders = linkHeaderString.characters.split(separator: ",").map({charactersSequence in
                        let matched = self.matches(for: "<([a-zA-Z:\\/\\.]+)>; rel=\"\(endpointType.rawValue)\"", in: String.init(charactersSequence))
                        print(matched)
//                        let header = charactersSequence.split(separator: "; rel=\"").map(String.init)
//                        print (header)
                    })
                    
                    print(linkHeaders)
                    //endpointType.rawValue
//                    if let headerUrl = URL(string: headerEndpoint) {
//                        completion(headerUrl)
                        completion(nil)
                        return
//                    }
                    
                }
            }

            // Check if endpoint is in the HTML Head
//            if let responseData = data {
//                
//            }
            
            
            completion(nil)
        }
        
         task.resume()
    }

    
    
    
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loginWithIndieAuth(nil)
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indieAuthDomain?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Utlity Methods
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

}

