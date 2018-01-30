//
//  IndieAuthTokenResponse.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/27/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public struct IndieAuthTokenResponse: Codable {
    let access_token: String
    let scope: String
    let me: URL
}
