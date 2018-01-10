//
//  MicropubPost.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/9/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public struct MicropubPost: Codable {
    let type: Mf2Type
    var properties: MicropubPostProperties
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(["h-\(type)"], forKey: .type)
        try container.encode(properties, forKey: .properties)
    }
    
    static func send(post: MicropubPost, as type: MicropubSendType, forUser user: IndieAuthAccount, completion: @escaping () -> Swift.Void) {
        DispatchQueue.global(qos: .background).async {
            
            var request = URLRequest(url: user.micropub_endpoint)
            request.httpMethod = "POST"
            request.setValue("Bearer \(user.access_token)", forHTTPHeaderField: "Authorization")
            
            switch type {
            case .urlencoded:
                var entryString = "h=\(post.type)"
                
                for (name, optionalValue) in post.properties.getPropertiesAsString() {
                    if let value = optionalValue {
                        entryString += "&\(name)=\(value)"
                    }
                }

                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let bodyString = "\(entryString)"
                let bodyData = bodyString.data(using:String.Encoding.utf8, allowLossyConversion: false)
                request.httpBody = bodyData

            
            case .json:
//                var entryObject: [String: [String]] = ["type": ["h-\(post.type)"]]
//
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                do {
                    let entryData = try JSONEncoder().encode(post)
                    request.httpBody = entryData
                } catch {
                    print("Failed")
                }
            }
            
            //set up the session
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request) { (data, response, error) in
                completion()
            }
            task.resume()
            
        }
    }
}

public struct MicropubPostProperties: Codable {
    var name: String? = nil
    var content: String? = nil
    var summary: String? = nil
    var category: [String]? = nil
    var inReplyTo: String? = nil
    var repostOf: String? = nil
    var mpSyndicateTo: [String]? = nil
    
    // Dates
//    var published: Date? = nil
//    var updated: Date? = nil
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if name != nil {
            try container.encode([name], forKey: .name)
        }
        if content != nil {
            try container.encode([content], forKey: .content)
        }
        if summary != nil {
            try container.encode([summary], forKey: .summary)
        }
        if category != nil {
            try container.encode(category, forKey: .category)
        }
        if inReplyTo != nil {
            try container.encode([inReplyTo], forKey: .inReplyTo)
        }
        if repostOf != nil {
            try container.encode([repostOf], forKey: .repostOf)
        }
        if mpSyndicateTo != nil {
            try container.encode(mpSyndicateTo, forKey: .mpSyndicateTo)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case content
        case summary
        case category
        case inReplyTo = "in-reply-to"
        case repostOf = "repost-of"
        case mpSyndicateTo = "mp-syndicate-to"
    }
    
    func getPropertiesAsString() -> [String: String?] {
        
        return [
            "name": self.name,
            "content": self.content,
            "summary": self.summary,
            "category": self.category?.joined(separator: ","),
            "in-reply-to": self.inReplyTo,
            "repost-of": self.repostOf,
            "mp-syndicate-to": self.mpSyndicateTo?.joined(separator: ",")
        ]
        
    }
    
//    func getPropertiesAsArray() -> MicropubJsonPost {
//
//        var returnObject = MicropubJsonPost()
//
//        if self.name != nil {
//            returnObject.name = [self.name!]
//        }
//
//        if self.content != nil {
//            returnObject.content = [self.content!]
//        }
//
//        if self.summary != nil {
//            returnObject.summary = [self.summary!]
//        }
//
//        if self.category != nil {
//            returnObject.category = self.category!
//        }
//
//        if self.inReplyTo != nil {
//            returnObject.inReplyTo = [self.inReplyTo!]
//        }
//
//        if self.repostOf != nil {
//            returnObject.repostOf = [self.repostOf!]
//        }
//
//        if self.mpSyndicateTo != nil {
//            returnObject.mpSyndicateTo = self.mpSyndicateTo!
//        }
//
//        return returnObject
//    }
    
    //    // TODO: Figure out how to store Location internally
    //    //let syndication: [String]?
}
