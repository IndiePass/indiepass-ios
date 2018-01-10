//
//  MicropubConfig.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/10/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public struct MicropubConfig: Codable {
    let mediaEndpoint: URL?
    var syndicateTo: [SyndicateTarget]?
    
    enum CodingKeys: String, CodingKey {
        case mediaEndpoint = "media-endpoint"
        case syndicateTo = "syndicate-to"
    }
}
