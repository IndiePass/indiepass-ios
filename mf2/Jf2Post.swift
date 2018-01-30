//
//  Jf2Post.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/28/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

public class Jf2Post: Codable {
    var type: Mf2Type? = nil
    var name: String? = nil
    var author: Jf2Post? = nil
    var published: Date? = nil
    var start: Date? = nil
    var url: URL? = nil
    var photo: [URL]? = nil
    var photoImage: [URL: MicropubPhoto]? = nil
    var category: [String]? = nil
    var location: [String]? = nil
    var attendee: [URL]? = nil
    var syndication: [URL]? = nil
    var content: Jf2Content? = nil
    var refs: [URL : Jf2Post]? = nil
    var summary: String? = nil
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try? values.decode(Mf2Type.self, forKey: .type)
        name = try? values.decode(String.self, forKey: .name)
        author = try? values.decode(Jf2Post.self, forKey: .author)
        url = try? values.decode(URL.self, forKey: .url)
        photo = try? values.decode([URL].self, forKey: .photo)
        // TODO: get single photo if not array
        if photo == nil {
            photo = try? [values.decode(URL.self, forKey: .photo)]
        }
        category = try? values.decode([String].self, forKey: .category)
        location = try? values.decode([String].self, forKey: .location)
        attendee = try? values.decode([URL].self, forKey: .attendee)
        syndication = try? values.decode([URL].self, forKey: .syndication)
        content = try? values.decode(Jf2Content.self, forKey: .content)
        refs = try? values.decode([URL: Jf2Post].self, forKey: .refs)
        summary = try? values.decode(String.self, forKey: .summary)
        photoImage = nil
        
        // set up various date and time formattors
        let iso601SpaceVariant = DateFormatter()
        iso601SpaceVariant.dateFormat = "yyyy'-'MM'-'dd HH':'mm':'ssZZZZZ"
        
        if let dateString = try? values.decode(String.self, forKey: .published) {
            published = ISO8601DateFormatter().date(from: dateString) ?? iso601SpaceVariant.date(from: dateString)
        } else {
            published = nil
        }
        
        if let dateString = try? values.decode(String.self, forKey: .start) {
            start = ISO8601DateFormatter().date(from: dateString) ?? iso601SpaceVariant.date(from: dateString)
            print("start date?")
            print(dateString)
            print(start)
        } else {
            start = nil
        }
        
    }
    
    public func downloadPhoto(photoIndex: Int) {
        guard let photos = photo, photoIndex < photos.count else {
            print("Error no photos")
            return
        }
        
        if self.photoImage == nil {
            self.photoImage = [:]
        }
        
        Jf2Post.downloadPhoto(fromUrl: photos[photoIndex]) { image in
            var newPhoto = MicropubPhoto()
            newPhoto.image = image
            newPhoto.uploadedUrl = self.photo?[0]
            self.photoImage?[newPhoto.uploadedUrl!] = newPhoto
        }
    }
    
    public func downloadPhoto(photoIndex: Int, _ completion: @escaping (UIImage?) -> Swift.Void) {
        guard let photos = photo, photoIndex < photos.count else {
            print("Error no photos")
            return
        }
        
        if self.photoImage == nil {
            self.photoImage = [:]
        }
        
        Jf2Post.downloadPhoto(fromUrl: photos[photoIndex]) { image in
            var newPhoto = MicropubPhoto()
            newPhoto.image = image
            newPhoto.uploadedUrl = self.photo?[0]
            self.photoImage?[newPhoto.uploadedUrl!] = newPhoto
            completion(newPhoto.image)
        }
    }
    
    public static func downloadPhoto(fromUrl url: URL, _ completion: @escaping (UIImage?) -> Swift.Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .returnCacheDataElseLoad
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil, let imageData = data else {
                print("error parsing photo \(url)")
                print(response)
                print(error)
                completion(nil)
                return
            }
            completion(UIImage(data: imageData))
        }
        task.resume()
    }
}

public struct Jf2Content: Codable {
    var text: String?
    var html: String?
}
