//
//  AccountViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 6/10/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    
    let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        usernameDisplay.text = micropubAuth?["me"] as? String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var usernameDisplay: UILabel!

    @IBAction func logOutAccount(_ sender: UIButton) {
        defaults?.removeObject(forKey: "micropubAuth")
        if let mainVC = self.parent as? MainViewController {
            mainVC.showLoginScreen()
        }
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
