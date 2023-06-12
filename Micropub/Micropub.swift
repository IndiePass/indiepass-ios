//
//  Micropub.swift
//  IndiePass
//
//  Created by Edward Hinkle on 11/14/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

func sendMicropub(forAction: MicropubResponseType, aboutUrl: URL, forUser user: IndieAuthAccount, completion: @escaping () -> Swift.Void) {
    
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
            case .like:
                entryString = "h=entry&like-of=\(encodedUrl)&summary=Liked: \(encodedUrl)"
            case .repost:
                entryString = "h=entry&repost-of=\(encodedUrl)&summary=Reposted: \(encodedUrl)"
            case .bookmark:
                entryString = "h=entry&bookmark-of=\(encodedUrl)&summary=Bookmarked: \(encodedUrl)"
            case .listen:
                entryString = "h=entry&listen-of=\(encodedUrl)&summary=Listened: \(encodedUrl)"
            default:
                print("ERROR")
        }
        
        var request = URLRequest(url: user.micropub_endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
        let bodyString = "\(entryString)&access_token=\(user.access_token)"
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

func sendMicropub(note: String, forUser user: IndieAuthAccount, completion: @escaping () -> Swift.Void) {
    DispatchQueue.global(qos: .background).async {
        let entryString = "h=entry&content=\(note)"
            
        var request = URLRequest(url: user.micropub_endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
        let bodyString = "\(entryString)&access_token=\(user.access_token)"
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
