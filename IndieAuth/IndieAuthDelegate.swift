//
//  IndieAuthDelegate.swift
//  IndiePass
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Foundation

public protocol IndieAuthDelegate : NSObjectProtocol {
    func loggedIn() -> Void
}
