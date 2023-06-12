//
//  AccountViewController.swift
//  IndiePass
//
//  Created by Eddie Hinkle on 6/10/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    
    let defaults = UserDefaults(suiteName: AppGroup)

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
                usernameDisplay.text = micropubDetails.me.absoluteString
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var usernameDisplay: UILabel!

    @IBAction func logOutAccount(_ sender: UIButton) {
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        var micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data]
        micropubAccounts?.remove(at: activeAccount)
        defaults?.set(0, forKey: "activeAccount")
        defaults?.set(micropubAccounts, forKey: "micropubAccounts")
        
        if let numberOfAccounts = micropubAccounts?.count, numberOfAccounts < 1 {
            if let mainVC = self.parent as? MainViewController {
                mainVC.showLoginScreen()
            }
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
