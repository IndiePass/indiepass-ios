//
//  ChannelUnreadStatus.swift
//  IndiePass
//
//  Created by Edward Hinkle on 3/14/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public enum ChannelUnreadStatus: Codable {
    case unreadCount(count: Int)
    case unread
    case read
    case none
    
    enum CodingKeys: String, CodingKey {
        case unreadCount
        case unread
        case read
        case none
    }
    
    var readIdentifier: String {
        switch self {
        case .none:
            return "none"
        case .read:
            return "read"
        case .unread:
            return "unread"
        case .unreadCount:
            return "unreadCount"
        }
    }
    
    var unreadCount: Int {
        switch self {
        case .none:
            return -1
        case .read:
            return 0
        case .unread:
            return 1
        case .unreadCount(let count):
            return count
        }
    }
    
    public init(status: String, count: Int) {
        switch status {
        case "none":
            self = .none
        case "read":
            self = .read
        case "unread":
            self = .unread
        case "unreadCount":
            self = .unreadCount(count: count)
        default:
            self = .none
        }
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let intValue = try! container.decodeIfPresent(Int.self, forKey: .unreadCount) {
            print("int: \(intValue)")
            if intValue > 0 {
                self = .unreadCount(count: intValue)
            } else {
                self = .read
            }
        } else if let boolValue = try! container.decodeIfPresent(Bool.self, forKey: .unread) {
            print("bool: \(boolValue)")
            if boolValue {
                self = .unread
            } else {
                self = .read
            }
        } else {
            self = .none
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .unreadCount(let count):
            try container.encode(count, forKey: .unreadCount)
        case .unread:
            try container.encode(true, forKey: .unread)
        case .read:
            try container.encode(false, forKey: .read)
        case .none:
            try container.encode("null", forKey: .none)
        }
    }
}
