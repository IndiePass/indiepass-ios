//
//  IndieAuthScope.swift
//  IndiePass
//
//  Created by Edward Hinkle on 12/22/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public enum IndieAuthScope: String, Codable {
    case read
    case follow
    case mute
    case block
    case channels
    case create
    case update
    case delete
    case media
}
