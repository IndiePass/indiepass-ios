//
//  MicropubTypes.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/29/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public enum MicropubTypes: String, Codable {
    case rsvp = "RSVP"
    case like
    case repost
    case bookmark
    case listen
    case watch
    case read
    case poke
    case reply
}
