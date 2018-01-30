//
//  IndieAuthProfile.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/22/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public struct IndieAuthProfile: Codable {
    let type: Mf2Type
    let name: String
    let url: URL
    let photo: URL
}
