//
//  OnboardingTemplateViewController.swift
//  IndiePass
//
//  Created by Edward Hinkle on 6/26/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class OnboardingTemplateViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var learnMore: UIButton!
    @IBOutlet weak var icon: UIImageView!
    
    var titleText: String? = nil
    var contentText: String? = nil
    var buttonText: String? = nil
    var buttonUrl: URL? = nil
    var primaryIcon: FontAwesome? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeManager.currentTheme().mainColor
        titleLabel.text = titleText
        titleLabel.textColor = UIColor.white
        contentLabel.text = contentText
        contentLabel.textColor = UIColor.white
        learnMore.setTitleColor(UIColor.white, for: .normal)
        learnMore.setTitle(buttonText, for: .normal)
        
        if primaryIcon != nil {
            icon.image = UIImage.fontAwesomeIcon(name: primaryIcon!, textColor: UIColor.white, size: CGSize(width: 150, height: 100))
        }
    }
    
    @IBAction func callToAction(_ sender: Any) {
        if let url = buttonUrl, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

}
