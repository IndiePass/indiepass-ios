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
    
    func markAllPostsAsRead(completion: @escaping (_ error: String?) -> Swift.Void) {
        markAsRead(postsBeforeIndex: 0, completion: completion)
    }
    
//    func markAsRead(postIndexes: [Int], completion: @escaping (_ error: String?) -> Swift.Void) {
//
//        // Only use indexes that exist in array, map indexes to post ids
//        let postIds = postIndexes.filter { self.posts.count > $0 }.map { self.posts[$0].id }
//
//        markAsUnread(posts: postIds, completion: completion)
//
//    }
//
//    func markAsUnread(postIndexes: [Int], completion: @escaping (_ error: String?) -> Swift.Void) {
//
//        // Only use indexes that exist in array, map indexes to post ids
//        let postIds = postIndexes.filter { self.posts.count > $0 }.map { self.posts[$0].id }
//
//        markAsUnread(posts: postIds, completion: completion)
//
//    }
    
    func markAsRead(postsBeforeIndex lastReadIndex: Int, completion: @escaping (_ error: String?) -> Swift.Void) {
        
        guard posts.count > lastReadIndex, let postId = posts[lastReadIndex].id else {
            completion("Requested post index does not exist")
            return
        }
        
        markAsRead(postsBefore: postId, completion: completion)
        
    }
    
    func markAsRead(posts: [String], completion: @escaping (_ error: String?) -> Swift.Void) {
        
        guard let channelId = channel?.uid else {
            completion("Channel doesn't exist")
            return
        }
        
        sendReadRequest(markReadRequest: TimelineMarkAsReadRequest(channel: channelId, method: .MarkRead, entries: posts)) { error in
            completion(error)
        }
        
    }
    
    func markAsUnread(posts: [String], completion: @escaping (_ error: String?) -> Swift.Void) {
        
        guard let channelId = channel?.uid else {
            completion("Channel doesn't exist")
            return
        }
        
        sendReadRequest(markReadRequest: TimelineMarkAsReadRequest(channel: channelId, method: .MarkUnread, entries: posts)) { error in
            completion(error)
        }
        
    }
    
    func markAsRead(postsBefore lastReadEntry: String, completion: @escaping (_ error: String?) -> Swift.Void) {
        
        guard let channelId = channel?.uid else {
            completion("Channel doesn't exist")
            return
        }
        
        sendReadRequest(markReadRequest: TimelineMarkAsReadRequest(channel: channelId, method: .MarkRead, lastReadEntry: lastReadEntry)) { error in
            completion(error)
        }
        
    }
    
    func sendReadRequest(markReadRequest: TimelineMarkAsReadRequest, completion: @escaping (_ error: String?) -> Swift.Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let microsubEndpoint = self?.accountDetails?.microsub_endpoint else {
                completion("microsubEndpoint failure")
                return
            }
            
            guard let account = self?.accountDetails else {
                completion("No account details")
                return
            }
            
            guard let requestData = markReadRequest.toData() else {
                completion("Couldn't prepare read request for POST body")
                return
            }
            
            var request = URLRequest(url: microsubEndpoint)
            request.httpMethod = "POST"
            request.httpBody = requestData
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(account.access_token)", forHTTPHeaderField: "Authorization")
            
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            let task = session.dataTask(with: request) { (data, response, error) in
                // check for any errors
                guard error == nil else {
                    completion("error calling POST on \(microsubEndpoint)")
                    print(error ?? "No error present")
                    return
                }
                
                // Check if endpoint is in the HTTP Header fields
                if let httpResponse = response as? HTTPURLResponse, let body = String(data: data!, encoding: .utf8) {
                    if httpResponse.statusCode == 200 {
                        completion(nil)
                    } else {
                        completion("Status Code not 200")
                        print(httpResponse)
                        print(body)
                    }
                }
                
            }
            
            task.resume()
        }
    }
    
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
