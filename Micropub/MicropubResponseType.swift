//
//  MicropubResponseType.swift
//  IndiePass
//
//  Created by Edward Hinkle on 12/29/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public enum MicropubResponseType: String, Codable {
    case rsvp = "RSVP"
    case like = "Like"
    case repost = "Repost"
    case bookmark = "Bookmark"
    case listen = "Listened"
    case watch = "Watched"
    case read = "Read"
    case reply = "Reply"
}
