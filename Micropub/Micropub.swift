//
//  Micropub.swift
//  Indigenous
//
//  Created by Edward Hinkle on 11/14/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

func sendMicropub(forAction: String, aboutUrl: URL, completion: @escaping () -> Swift.Void) {
    
    DispatchQueue.global(qos: .background).async {
        var entryString = ""
        
        guard let encodedUrl = aboutUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?.replacingOccurrences(of: "+", with: "%2B") else {
            print("Encoding URL failed")
            return
        }
        
        print("Check on encoding url")
        print(aboutUrl.absoluteString)
        print(encodedUrl)
        
        switch(forAction) {
            case "Like":
                entryString = "h=entry&like-of=\(encodedUrl)"
            case "Repost":
                entryString = "h=entry&repost-of=\(encodedUrl)"
            case "Bookmark":
                entryString = "h=entry&bookmark-of=\(encodedUrl)"
            case "Listen":
                entryString = "h=entry&listen-of=\(encodedUrl)"
            default:
                print("ERROR")
        }
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
           let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            
                var request = URLRequest(url: micropubDetails.micropub_endpoint)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let bodyString = "\(entryString)&access_token=\(micropubDetails.access_token)"
                let bodyData = bodyString.data(using:String.Encoding.utf8, allowLossyConversion: false)
                request.httpBody = bodyData
            
                // set up the session
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
            
                let task = session.dataTask(with: request) { (data, response, error) in
                    completion()
                }
                task.resume()
        }
    }
}

func sendMicropub(note: String, completion: @escaping () -> Swift.Void) {
    
    DispatchQueue.global(qos: .background).async {
        let entryString = "h=entry&content=\(note)"
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            
                var request = URLRequest(url: micropubDetails.micropub_endpoint)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let bodyString = "\(entryString)&access_token=\(micropubDetails.access_token)"
                let bodyData = bodyString.data(using:String.Encoding.utf8, allowLossyConversion: false)
                request.httpBody = bodyData
                
                // set up the session
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
                
                let task = session.dataTask(with: request) { (data, response, error) in
                    completion()
                }
                task.resume()
        }
    }
}
