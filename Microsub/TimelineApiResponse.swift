//
//  TimelineApiResponse.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

struct TimelineApiResponse: Codable {
    let items: [Jf2Post]
    let paging: TimelineApiPaging?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.items = try container.decode([Jf2Post].self, forKey: .items)
        
        if let options = try? container.decode(TimelineApiPaging.self, forKey: .paging) {
            self.paging = options
        } else {
            self.paging = nil
        }
    }
}
