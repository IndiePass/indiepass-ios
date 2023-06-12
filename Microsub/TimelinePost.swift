//
//  TimelineItem.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

struct TimelinePost: Codable {
    let type: String?
    let published: String?
    let url: String?
    let name: String?
    let author: Author?
    let category: [String]?
    let photo: [String]?
    let content: TimelinePostContent?
    let syndication: [String]?
    let summary: String?
}
