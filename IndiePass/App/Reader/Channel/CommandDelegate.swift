//
//  CommandDelegate.swift
//  IndiePass
//
//  Created by Edward Hinkle on 5/15/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public protocol CommandDelegate : NSObjectProtocol {
    func statusUpdate(runningStatus isRunning: Bool) -> Void
}
