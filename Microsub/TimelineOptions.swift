//
//  TimelineOptions.swift
//  IndiePass
//
//  Created by Edward Hinkle on 1/25/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

struct TimelineOptions: Codable {
    let before: String?
    let after: String?
    
    public init(before: String?) {
        self.before = before
        self.after = nil
    }
    
    public init(after: String?) {
        self.after = after
        self.before = nil
    }
    
    public init(before: String?, after: String?) {
        self.before = before
        self.after = after
    }
    
    func asDictionary() -> [String: String] {
        var options: [String: String] = [:]
        if before != nil {
            options["before"] = before
        }
        if after != nil {
            options["after"] = after
        }
        return options
    }
}
