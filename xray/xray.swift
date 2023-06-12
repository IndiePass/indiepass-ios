//
//  xray.swift
//  IndiePass
//
//  Created by Edward Hinkle on 12/28/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public class XRay {

    public static func parse(url: URL, completion: @escaping (_ parsedData: XRayParsingResponse?, _ errorMessage: String?) -> ()) {
        
        let xrayUrl = URL(string: "https://xray.abode.pub/parse")!
        let requestBody: String = "url=\(url.absoluteString)"
        
        var request = URLRequest(url: xrayUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
        request.httpBody = requestBody.data(using: .utf8, allowLossyConversion: false)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling POST on \(xrayUrl) with \(requestBody)")
                print(error ?? "No error present")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                        if contentType == "application/json" {
                            print("content type is application json")
//                            print(String(data: data!, encoding: .utf8))
                            if let parsedPost = try? JSONDecoder().decode(XRayParsingResponse.self, from: data!) {
                                print("finished jf2")
                                print(parsedPost)
                                completion(parsedPost, nil)
                            }
                        } else {
                            print("content type wrong")
                            print(httpResponse)
                            completion(nil, "Recieved the following HTTP Status Code " + String(httpResponse.statusCode))
                        }
                    }
                } else {
                    print("status code wrong")
                    print(httpResponse)
                    completion(nil, "Recieved the following HTTP Status Code " + String(httpResponse.statusCode))
                }
            }
        }
        task.resume()
        
    }

}
