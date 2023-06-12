//
//  TimelineMarkAsReadRequest.swift
//  IndiePass
//
//  Created by Edward Hinkle on 2/19/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

struct TimelineMarkAsReadRequest: Codable {
    let action = "timeline"
    let channel: String
    let method: TimelineMarkAsReadMethod
    let entries: [String]?
    let lastReadEntry: String?
    
    init(channel: String, method: TimelineMarkAsReadMethod, entries: [String]) {
        self.channel = channel
        self.method = method
        self.entries = entries
        self.lastReadEntry = nil
    }
    
    init(channel: String, method: TimelineMarkAsReadMethod, lastReadEntry: String) {
        self.channel = channel
        self.method = method
        self.lastReadEntry = lastReadEntry
        self.entries = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case action
        case channel
        case method
        case entries = "entry"
        case lastReadEntry = "last_read_entry"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(action, forKey: .action)
        try container.encode(channel, forKey: .channel)
        try container.encode(method, forKey: .method)
        
        if (lastReadEntry != nil) {
            try container.encode(lastReadEntry, forKey: .lastReadEntry)
        } else {
            try container.encode(entries, forKey: .entries)
        }
    }
    
    public func toData() -> Data? {
        var dataString = "action=\(action)&channel=\(channel)&method=\(method.rawValue)"
        if (lastReadEntry != nil) {
            dataString += "&\(CodingKeys.lastReadEntry.rawValue)=\(lastReadEntry!)"
        } else {
            for entry in entries! {
                dataString += "&\(CodingKeys.entries.rawValue)[]=\(entry)"
            }
        }
        print("Checking data string")
        print(dataString)
        return dataString.data(using: .utf8, allowLossyConversion: false)
    }
}

enum TimelineMarkAsReadMethod: String, Codable {
    case MarkRead = "mark_read"
    case MarkUnread = "mark_unread"
}
