//
//  TimelineApiPaging.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/25/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

struct TimelineApiPaging: Codable {
    let before: String?
    let after: String?
}
