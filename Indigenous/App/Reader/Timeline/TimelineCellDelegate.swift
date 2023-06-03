//
//  TimelineCellDelegate.swift
//  Indigenous
//
//  Created by Edward Hinkle on 6/23/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation
import UIKit

public protocol TimelineCellDelegate : NSObjectProtocol {
    func shareUrl(url: URL) -> Void
    func replyToUrl(url: URL) -> Void
    func moreOptions(post: Jf2Post, sourceButton: UIBarButtonItem) -> Void
}
