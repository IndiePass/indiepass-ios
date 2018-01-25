//
//  Timeline.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/25/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

class Timeline {
    
    public var accountDetails: IndieAuthAccount? = nil
    public var channel: Channel? = nil
    public var posts: [Jf2Post] = []
    var currentOptions: TimelineOptions? = nil
    
    func getNextTimeline(completion: @escaping (_ error: String?, _ timelinePosts: [Jf2Post]?) -> Swift.Void) {
        
        DispatchQueue.global(qos: .background).async {
            guard self.accountDetails != nil else {
                completion("Account Details are not set", nil)
                return
            }
            
            guard self.channel != nil else {
                completion("Channel is not set", nil)
                return
            }
            
            guard self.currentOptions?.before != nil else {
                completion("No before token present", nil)
                return
            }
            
            let options = TimelineOptions(before: self.currentOptions?.before)
            
            Timeline.fetchTimelineData(withAccount: self.accountDetails!, forChannel: self.channel!, withOptions: options) { error, timelineResponse in
                
                guard error == nil else {
                    completion(error, nil)
                    return
                }
                
                self.currentOptions = TimelineOptions(before: timelineResponse?.paging?.before,
                                                      after: self.currentOptions?.after)
                
                if let timelineItems = timelineResponse?.items {
                    self.posts.append(contentsOf: timelineItems)
                    completion(nil, timelineItems)
                } else {
                    completion(nil, [])
                }
            }
        }
        
    }
    
    func getPreviousTimeline(completion: @escaping (_ error: String?, _ timelinePosts: [Jf2Post]?) -> Swift.Void) {
        
        DispatchQueue.global(qos: .background).async {
            guard self.accountDetails != nil else {
                completion("Account Details are not set", nil)
                return
            }
            
            guard self.channel != nil else {
                completion("Channel is not set", nil)
                return
            }
            
            guard self.currentOptions?.after != nil else {
                completion("No after token present", nil)
                return
            }
            
            let options = TimelineOptions(after: self.currentOptions?.after)
            
            Timeline.fetchTimelineData(withAccount: self.accountDetails!, forChannel: self.channel!, withOptions: options) { error, timelineResponse in
                
                guard error == nil else {
                    completion(error, nil)
                    return
                }
                
                print("Analyze returned options")
                print(timelineResponse?.paging)
                
                self.currentOptions = TimelineOptions(before: self.currentOptions?.before,
                                                      after: timelineResponse?.paging?.after)
                
                if let timelineItems = timelineResponse?.items {
                    self.posts.append(contentsOf: timelineItems)
                    completion(nil, timelineItems)
                } else {
                    completion(nil, [])
                }
            }
        }
        
    }
    
    func getTimeline(completion: @escaping (_ error: String?, _ timelinePosts: [Jf2Post]?) -> Swift.Void) {

        DispatchQueue.global(qos: .background).async {
            guard self.accountDetails != nil else {
                completion("Account Details are not set", nil)
                return
            }

            guard self.channel != nil else {
                completion("Channel is not set", nil)
                return
            }
            
            Timeline.fetchTimelineData(withAccount: self.accountDetails!, forChannel: self.channel!, withOptions: nil) { error, timelineResponse in

                    guard error == nil else {
                        completion(error, nil)
                        return
                    }
                
                    self.currentOptions = TimelineOptions(before: timelineResponse?.paging?.before,
                                                          after: timelineResponse?.paging?.after)
                
                    if let timelineItems = timelineResponse?.items {
                        self.posts.append(contentsOf: timelineItems)
                        completion(nil, timelineItems)
                    } else {
                        completion(nil, [])
                    }
            }
        }

    }
    
    static func fetchTimelineData(withAccount account: IndieAuthAccount,
                                  forChannel channel: Channel,
                                  withOptions options: TimelineOptions?,
                                  completion: @escaping (_ error: String?, _ timelinePosts: TimelineApiResponse?) -> Swift.Void) {
        
        guard let microsubEndpoint = account.microsub_endpoint else {
            completion("microsubEndpoint failure", nil)
            return
        }
        
        guard var microsubUrl = URLComponents(url: microsubEndpoint, resolvingAgainstBaseURL: false) else {
            completion("Making url of microsub fails", nil)
            return
        }
        
        if microsubUrl.queryItems == nil {
            microsubUrl.queryItems = []
        }
        
        microsubUrl.queryItems?.append(URLQueryItem(name: "action", value: "timeline"))
        microsubUrl.queryItems?.append(URLQueryItem(name: "channel", value: channel.uid))
        
        if options != nil {
            for (name, value) in options!.asDictionary() {
                microsubUrl.queryItems?.append(URLQueryItem(name: name, value: value))
            }
        }
        
        guard let microsub = microsubUrl.url else {
            completion("Error making final url", nil)
            return
        }
        
        var request = URLRequest(url: microsub)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(account.access_token)", forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            // check for any errors
            guard error == nil else {
                completion("error calling POST on \(microsubUrl)", nil)
                print(error ?? "No error present")
                return
            }
            
            // Check if endpoint is in the HTTP Header fields
            if let httpResponse = response as? HTTPURLResponse, let body = String(data: data!, encoding: .utf8) {
                if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                    if httpResponse.statusCode == 200 {
                        if contentType == "application/json" {
                            let timelineResponse = try! JSONDecoder().decode(TimelineApiResponse.self, from: body.data(using: .utf8)!)
                            completion(nil, timelineResponse)
                        }
                    } else {
                        completion("Status Code not 200", nil)
                        print(httpResponse)
                        print(body)
                    }
                }
            }
            
        }
        
        task.resume()
    }
}
