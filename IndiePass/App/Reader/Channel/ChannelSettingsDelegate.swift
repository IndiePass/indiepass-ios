//
//  ChannelSettingsDelegate.swift
//  IndiePass
//
//  Created by Edward Hinkle on 6/16/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public protocol ChannelSettingsDelegate : NSObjectProtocol {
    func markAllPostsAsRead() -> Void
}
