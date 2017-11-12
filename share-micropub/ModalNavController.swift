//
//  ModalNavController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 11/9/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class ModalNavController: UINavigationController, HalfModalPresentable {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isHalfModalMaximized() ? .default : .lightContent
    }
}

