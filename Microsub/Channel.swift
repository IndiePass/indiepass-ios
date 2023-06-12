//
//  Channel.swift
//  IndiePass
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

struct Channel: Codable {
    let uid: String
    let name: String
    let unread: ChannelUnreadStatus
    
    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case unread
    }
    
    public init(uniqueId uid: String, withName name: String) {
        self.uid = uid
        self.name = name
        self.unread = .none
    }
    
    public init(fromData data: ChannelData) {
        uid = data.uid!
        name = data.name!
        unread = ChannelUnreadStatus(status: data.unreadStatus!, count: Int(exactly: data.unreadCount)!)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try! container.decode(String.self, forKey: .uid)
        name = try! container.decode(String.self, forKey: .name)
        
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .unread) {
            if boolValue != nil {
                if boolValue! {
                    unread = .unread
                } else {
                    unread = .read
                }
            } else {
                unread = .read
            }
        } else if let intValue = try! container.decodeIfPresent(Int.self, forKey: .unread) {
            if intValue > 0 {
                unread = .unreadCount(count: intValue)
            } else {
                unread = .read
            }
        } else {
            unread = .none
        }
    }
}
