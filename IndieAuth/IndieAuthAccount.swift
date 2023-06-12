//
//  Account.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/22/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public struct IndieAuthAccount: Codable {
    let profile: Jf2Post
    let access_token: String
    let scope: [IndieAuthScope]
    let me: URL
    let micropub_endpoint: URL
    let authorization_endpoint: URL
    let token_endpoint: URL
    let microsub_endpoint: URL?
    var micropub_config: MicropubConfig?
}

