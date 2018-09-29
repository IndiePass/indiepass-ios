//
//  MicropubPost.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/9/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

public struct MicropubPost: Codable {
    let type: Mf2Type
    var properties: MicropubPostProperties
    
    enum CodingKeys: String, CodingKey {
        case type
        case properties
    }
    
    public init(type: Mf2Type, properties: MicropubPostProperties) {
        self.type = type
        self.properties = properties
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // TODO:
        let typeStringArray = try container.decode([String].self, forKey: .type)
        let typeString = typeStringArray[0].components(separatedBy: "h-")[1]
        self.type = Mf2Type(rawValue: typeString)!
        self.properties = try container.decode(MicropubPostProperties.self, forKey: CodingKeys.properties)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(["h-\(type)"], forKey: .type)
        try container.encode(properties, forKey: .properties)
    }
    
    public func isEmpty() -> Bool {
        return properties.isEmpty()
    }
    
    static func == (first: MicropubPost, second: MicropubPost) -> Bool {
        if (first.type == second.type) {
            return first.properties == second.properties
        }
        return false
    }
    
    static func send(post: MicropubPost, as type: MicropubSendType, forUser user: IndieAuthAccount, completion: @escaping (_ error: String?) -> Swift.Void) {
        DispatchQueue.global(qos: .background).async {
            
            var request = URLRequest(url: user.micropub_endpoint)
            request.httpMethod = "POST"
            request.setValue("Bearer \(user.access_token)", forHTTPHeaderField: "Authorization")
            request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
            
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
                // TODO: Add Access Token??
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
                    print("Failed encoding data")
                    completion("Error creating micropub request")
                }
            }
            
            //set up the session
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request) { (data, response, error) in
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 201: fallthrough
                    case 202:
                        completion(nil)
                    case 400:
                        completion("Authorization failure. Log out and back in")
                    default:
                        completion("Micropub Response Status Code: \(httpResponse.statusCode)")
                    }
                } else {
                    completion("Error sending micropub post")
                }
            }
            task.resume()
            
        }
    }
    
    static func convertToData(fromString textString: String) -> Data {
        return textString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
    }
    
    static func uploadToMediaEndpoint(image: UIImage, withId id: String, ofType type: String, withName name: String, forUser user: IndieAuthAccount, withDelegate delegate: URLSessionTaskDelegate?, completion: @escaping (URL) -> Swift.Void) {
        DispatchQueue.global(qos: .background).async {
            
            if let mediaEndpoint = user.micropub_config?.mediaEndpoint {
                var request = URLRequest(url: mediaEndpoint)
                request.httpMethod = "POST"
                request.setValue("Bearer \(user.access_token)", forHTTPHeaderField: "Authorization")
                request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
                
                // Set Content-Type in HTTP header.
                let boundaryConstant = "Boundary-\(NSUUID().uuidString)";
                let contentType = "multipart/form-data; boundary=" + boundaryConstant
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                let fileName = name
                let mimeType = type
                let fieldName = "file"
                let imageData: Data = image.jpegData(compressionQuality: 1)!
                var sendData = Data()
                
                sendData.append(convertToData(fromString: "--\(boundaryConstant)\r\n"))
                sendData.append(convertToData(fromString: "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"))
                sendData.append(convertToData(fromString: "Content-Type: \(mimeType)\r\n\r\n"))
                sendData.append(imageData)
                sendData.append(convertToData(fromString: "\r\n"))
                sendData.append(convertToData(fromString: "--\(boundaryConstant)--\r\n"))
                
                request.httpBody = sendData
                
                //set up the session
                let config = URLSessionConfiguration.default
                let opQueue = OperationQueue()
                let session = URLSession(configuration: config, delegate: delegate, delegateQueue: opQueue)
                session.sessionDescription = id
                
                let task = session.dataTask(with: request) { (data, response, error) in
                    if let httpResponse = response as? HTTPURLResponse {
                        
                        if error != nil {
                            print("Error Found")
                        }
                        
                        if httpResponse.statusCode == 201 {
                            if let imageUrl = URL(string: (httpResponse.allHeaderFields["Location"] as? String)!) {
                                completion(imageUrl)
                            }
                        } else {
                            print("Wrong Status Code")
                        }
                    }
                }
                task.resume()
            }
            
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
    var likeOf: String? = nil
    var bookmarkOf: String? = nil
    var rsvp: MicropubRsvpValue? = nil
    var listenOf: String? = nil
    var watchOf: String? = nil
    var readOf: String? = nil
    var published: Date? = nil
    var updated: Date? = nil
    var photo: [MicropubPhoto]? = nil
    
//    // TODO: Figure out how to store Location internally
//    //let syndication: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case content
        case summary
        case category
        case inReplyTo = "in-reply-to"
        case repostOf = "repost-of"
        case mpSyndicateTo = "mp-syndicate-to"
        case likeOf = "like-of"
        case bookmarkOf = "bookmark-of"
        case rsvp
        case listenOf = "listen-of"
        case watchOf = "watch-of"
        case readOf = "read-of"
        case published
        case updated
        case photo
    }
    
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
        if likeOf != nil {
            try container.encode([likeOf], forKey: .likeOf)
        }
        if bookmarkOf != nil {
            try container.encode([bookmarkOf], forKey: .bookmarkOf)
        }
        if rsvp != nil {
            try container.encode([rsvp], forKey: .rsvp)
        }
        if listenOf != nil {
            try container.encode([listenOf], forKey: .listenOf)
        }
        if watchOf != nil {
            try container.encode([watchOf], forKey: .watchOf)
        }
        if readOf != nil {
            try container.encode([readOf], forKey: .readOf)
        }
        if published != nil {
            try container.encode([published], forKey: .published)
        }
        if updated != nil {
            try container.encode([updated], forKey: .updated)
        }
        if photo != nil {
            try container.encode(photo!.map { photoInfo in
                return photoInfo.uploadedUrl
            }, forKey: .photo)
        }
    }
    
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = container.contains(.name) ? try container.decode([String?].self, forKey: .name)[0] : nil
        self.content = container.contains(.content) ? try container.decode([String?].self, forKey: .content)[0] : nil
        self.summary = container.contains(.summary) ? try container.decode([String?].self, forKey: .summary)[0] : nil
        self.category = container.contains(.category) ? try container.decode([String].self, forKey: .category) : nil
        self.inReplyTo = container.contains(.inReplyTo) ? try container.decode([String?].self, forKey: .inReplyTo)[0] : nil
        self.repostOf = container.contains(.repostOf) ? try container.decode([String?].self, forKey: .repostOf)[0] : nil
        self.mpSyndicateTo = container.contains(.mpSyndicateTo) ? try container.decode([String].self, forKey: .mpSyndicateTo) : nil
        self.likeOf = container.contains(.likeOf) ? try container.decode([String?].self, forKey: .likeOf)[0] : nil
        self.bookmarkOf = container.contains(.bookmarkOf) ? try container.decode([String?].self, forKey: .bookmarkOf)[0] : nil
        self.rsvp = container.contains(.rsvp) ? try container.decode([MicropubRsvpValue?].self, forKey: .rsvp)[0] : nil
        self.listenOf = container.contains(.listenOf) ? try container.decode([String?].self, forKey: .listenOf)[0] : nil
        self.watchOf = container.contains(.watchOf) ? try container.decode([String?].self, forKey: .watchOf)[0] : nil
        self.readOf = container.contains(.readOf) ? try container.decode([String?].self, forKey: .readOf)[0] : nil
        self.published = container.contains(.published) ? try container.decode([Date?].self, forKey: .published)[0] : nil
        self.updated = container.contains(.updated) ? try container.decode([Date?].self, forKey: .updated)[0] : nil
        self.photo = container.contains(.photo) ? try container.decode([MicropubPhoto].self, forKey: .photo) : nil
    }
    
    public func isEmpty() -> Bool {
        // We will loop through every case where we could NOT be empty and return false.
        if let name = self.name {
            if !name.isEmpty {
                return false
            }
        }
        if let content = self.content {
            if !content.isEmpty {
                return false
            }
        }
        if let summary = self.summary {
            if !summary.isEmpty {
                return false
            }
        }
        if let category = self.category {
            if category.count != 0 {
                return false // not empty array
            }
        }
        if let inReplyTo = self.inReplyTo {
            if !inReplyTo.isEmpty {
                return false
            }
        }
        if let repostOf = self.repostOf {
            if !repostOf.isEmpty {
                return false
            }
        }
        if let mpSyndicateTo = self.mpSyndicateTo {
            if mpSyndicateTo.count != 0 {
                return false // not empty array
            }
        }
        if let likeOf = self.likeOf {
            if !likeOf.isEmpty {
                return false
            }
        }
        if let bookmarkOf = self.bookmarkOf {
            if !bookmarkOf.isEmpty {
                return false
            }
        }
        if self.rsvp != nil {
            return false // enum, so if not nil, it's a value
        }
        if let listenOf = self.listenOf {
            if !listenOf.isEmpty {
                return false
            }
        }
        if let watchOf = self.watchOf {
            if !watchOf.isEmpty {
                return false
            }
        }
        if let readOf = self.readOf {
            if !readOf.isEmpty {
                return false
            }
        }
        if self.published != nil {
            return false // date, so if not nil, it's a value
        }
        if self.updated != nil {
            return false // date, so if not nil, it's a value
        }
        if let photo = self.photo {
            if photo.count != 0 {
                return false // not empty array
            }
        }
        
        // since we got to the end, we must be empty
        return true
    }
    
    static func == (first: MicropubPostProperties, second: MicropubPostProperties) -> Bool {
        // The best way to determine they are equal is to find out if anything is NOT equal
        if first.name != second.name {
            return false
        }
        if first.content != second.content {
            return false
        }
        if first.summary != second.summary {
            return false
        }
        if let firstCategory = first.category, let secondCategory = second.category {
            if firstCategory != secondCategory {
                return false
            }
        }
        if first.inReplyTo != second.inReplyTo {
            return false
        }
        if first.repostOf != second.repostOf {
            return false
        }
        if let firstSyndicateTo = first.mpSyndicateTo, let secondSyndicateTo = second.mpSyndicateTo {
            if firstSyndicateTo != secondSyndicateTo {
                return false
            }
        }
        if first.likeOf != second.likeOf {
            return false
        }
        if first.bookmarkOf != second.bookmarkOf {
            return false
        }
        if first.rsvp != second.rsvp {
            return false
        }
        if first.listenOf != second.listenOf {
            return false
        }
        if first.watchOf != second.watchOf {
            return false
        }
        if first.readOf != second.readOf {
            return false
        }
        if first.published != second.published {
            return false
        }
        if first.updated != second.updated {
            return false
        }
        // TODO: Figure out how to check if photos are equal
//        if let firstPhoto = first.photo, let secondPhoto = second.photo {
//            for (index, photo) in 0..<firstPhoto.count {
//                if firstPhoto[index] != secondPhoto[index] {
//                    return false
//                }
//            }
//        }
        
        // If we reached here than all the properties have matched
        return true
    }
    
    func getPropertiesAsString() -> [(String, String?)] {
        
        var returnArray = [
            (CodingKeys.name.rawValue, self.name),
            (CodingKeys.content.rawValue, self.content),
            (CodingKeys.summary.rawValue, self.summary),
            (CodingKeys.inReplyTo.rawValue, self.inReplyTo),
            (CodingKeys.repostOf.rawValue, self.repostOf),
            (CodingKeys.likeOf.rawValue, self.likeOf),
            (CodingKeys.bookmarkOf.rawValue, self.bookmarkOf),
            (CodingKeys.rsvp.rawValue, self.rsvp?.rawValue),
            (CodingKeys.listenOf.rawValue, self.listenOf),
            (CodingKeys.watchOf.rawValue, self.watchOf),
            (CodingKeys.readOf.rawValue, self.readOf)
        ]
        
        if let categories = self.category {
            for category in categories {
                returnArray.append(("\(CodingKeys.category.rawValue)[]", category))
            }
        }
        
        if let syndicateTargets = self.mpSyndicateTo {
            for syndicateTarget in syndicateTargets {
                returnArray.append(("\(CodingKeys.mpSyndicateTo.rawValue)[]", syndicateTarget))
            }
        }
        
        if let publishedDate = self.published {
            returnArray.append((CodingKeys.published.rawValue, ISO8601DateFormatter().string(from: publishedDate)))
        }
        
        if let updatedDate = self.updated {
            returnArray.append((CodingKeys.updated.rawValue, ISO8601DateFormatter().string(from: updatedDate)))
        }
        
        if let photos = self.photo {
            if photos.count > 1 {
                for photo in photos {
                    if let photoUrl = photo.uploadedUrl {
                        returnArray.append(("\(CodingKeys.photo.rawValue)[]", photoUrl.absoluteString))
                    } else {
                        // TODO: Upload photo as multipart?
                    }
                }
            } else {
                if let photoUrl = photos[0].uploadedUrl {
                    returnArray.append(("\(CodingKeys.photo.rawValue)", photoUrl.absoluteString))
                }
            }
        }
        
        return returnArray
    }
}
