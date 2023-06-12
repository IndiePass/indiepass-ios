//
//  SimpleSelectionReadOnlyDelegate.swift
//  IndiePass
//
//  Created by Edward Hinkle on 1/15/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public protocol SimpleSelectionReadOnlyDelegate: NSObjectProtocol {
    func selectionWasUpdated(currentlySelected: [Int]) -> Void
}
