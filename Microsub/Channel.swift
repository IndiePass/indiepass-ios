//
//  Channel.swift
//  Indigenous
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try! container.decode(String.self, forKey: .uid)
        name = try! container.decode(String.self, forKey: .name)
        
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .unread) {
            if boolValue != nil {
                if boolValue! {
                    print(1);
                    unread = .unread
                } else {
                    print(2);
                    unread = .read
                }
            } else {
                print(3);
                unread = .read
            }
        } else if let intValue = try! container.decodeIfPresent(Int.self, forKey: .unread) {
            if intValue > 0 {
                print(4);
                unread = .unreadCount(count: intValue)
            } else {
                print(5);
                unread = .read
            }
        } else {
            print(6);
            unread = .none
        }
    }
}
