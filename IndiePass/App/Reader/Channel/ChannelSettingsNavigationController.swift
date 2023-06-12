//
//  ChannelSettingsNavigationController.swift
//  IndiePass
//
//  Created by Edward Hinkle on 5/24/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class ChannelSettingsNavigationController: UINavigationController, HalfModalPresentable {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isHalfModalMaximized() ? .default : .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
