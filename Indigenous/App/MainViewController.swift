//
//  MainViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 5/2/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import IndieAuth

class MainViewController: UITabBarController {
    
    var loginViewController: UIViewController? = nil

    func showLoginScreen() {
        let loginViewController = storyboard?.instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
        
        DispatchQueue.main.async {
            self.loginViewController = loginViewController
            self.present(loginViewController, animated: true, completion: nil)
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        if micropubAuth == nil {
            showLoginScreen()
        } else {
            print("Logged in")
            print(micropubAuth)
        }
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
