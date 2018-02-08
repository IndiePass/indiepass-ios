//
//  MicropubConfig.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/10/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public struct MicropubConfig: Codable {
    var mediaEndpoint: URL?
    var syndicateTo: [SyndicateTarget]?
    
    enum CodingKeys: String, CodingKey {
        case mediaEndpoint = "media-endpoint"
        case syndicateTo = "syndicate-to"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.mediaEndpoint = try? container.decode(URL.self, forKey: .mediaEndpoint)
        var syndicationTargets = try? container.decode([SyndicateTarget].self, forKey: .syndicateTo)
        
        if syndicationTargets == nil, let syndicationUrls = try? container.decode([URL].self, forKey: .syndicateTo) {
            syndicationTargets = []
            for syndicateUrl in syndicationUrls {
                syndicationTargets?.append(SyndicateTarget(uid: syndicateUrl))
            }
        }
        
        self.syndicateTo = syndicationTargets
    }
}
