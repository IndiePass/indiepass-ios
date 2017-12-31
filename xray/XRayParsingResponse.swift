//
//  XRayParsingResponse.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/28/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public class XRayParsingResponse: Codable {
    let url: URL
    let code: Int
    let data: Jf2Post
}
