//
//  MicropubSyndicationQueryResponse.swift
//  IndiePass
//
//  Created by Edward Hinkle on 1/31/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public struct MicropubSyndicationQueryResponse: Codable {
    var syndicateTo: [SyndicateTarget]?
    
    enum CodingKeys: String, CodingKey {
        case syndicateTo = "syndicate-to"
    }
}
