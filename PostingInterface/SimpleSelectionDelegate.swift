//
//  SimpleSelectionDelegate.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/15/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation

public protocol SimpleSelectionDelegate: SimpleSelectionReadOnlyDelegate {
    func newCreated(item: SimpleSelectionItem) -> Void
}
