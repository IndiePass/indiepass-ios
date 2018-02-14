//
//  Command.swift
//  Indigenous
//
//  Created by Edward Hinkle on 2/13/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public struct Command {
    let name: String
    let url: URL
    let body: [String:String]
    
    func sendCommand() {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyString = ""
        for (key, value) in body {
            bodyString += "\(key)=\(value)&"
        }
        bodyString.remove(at: bodyString.index(before: bodyString.endIndex))
        
        let bodyData = bodyString.data(using:String.Encoding.utf8, allowLossyConversion: false)
        request.httpBody = bodyData
        
        // set up the session
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling POST on \(self.url)")
                print(error ?? "No error present")
                return
            }
            
            // Check if endpoint is in the HTTP Header fields
            if let httpResponse = response as? HTTPURLResponse, let body = String(data: data!, encoding: .utf8) {
                if httpResponse.statusCode == 200 {
                    // TODO: Find a way to communicate command status
                    print("Command Successfully Sent")
                } else {
                    print("Status Code not 200")
                    print(httpResponse)
                    print(body)
                }
            }
            
        }
        
        task.resume()
    }
}
