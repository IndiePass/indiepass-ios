//
//  MicropubPhoto.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/18/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

public struct MicropubPhoto: Codable {
    var image: UIImage? = nil
    var uploadedUrl: URL? = nil
    var progressPercent: Float? = nil
    
    public enum CodingKeys: String, CodingKey {
        case image
    }
    
    public init() {
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        guard let image = UIImage(data: data) else {
            print("Image unable to decode")
            return
        }
        
        self.image = image
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let imageFile = image {
            guard let data = imageFile.pngData() else {
                print("Image unable to encode")
                return
            }
            try? container.encode(data, forKey: CodingKeys.image)
        }
    }
    
    static func == (first: MicropubPhoto, second: MicropubPhoto) -> Bool {
        if first.image != second.image {
            return false
        }
        if first.uploadedUrl != second.uploadedUrl {
            return false
        }
        
        return true
    }
    
    //    static func != (first: MicropubPhoto, second: MicropubPhoto) -> Bool {
    //        return !(first == second)
    //    }
}
