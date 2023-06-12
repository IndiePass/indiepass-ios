//
//  SyndicateTargets.swift
//  IndiePass
//
//  Created by Edward Hinkle on 1/10/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public struct SyndicateTarget: Codable {
    let uid: URL
    let name: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let uid = try? container.decode(URL.self, forKey: .uid)
        var name = try? container.decode(String.self, forKey: .name)
        
        if (name == nil) {
            name = uid?.absoluteString
        }
        
        if let uidValue = uid, let nameValue = name {
            self.uid = uidValue
            self.name = nameValue
        } else {
            throw MicropubError.missingValue("UID Not Found in Config")
        }
    }
    
    public init(uid: URL) {
        self.uid = uid
        self.name = uid.absoluteString
    }
}
