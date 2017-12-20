//
//  MainViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 5/2/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class MainViewController: UINavigationController, IndieAuthDelegate {
    
    var loginViewController: UIViewController? = nil
    var backupViewControllers: [UIViewController]? = nil

    func showLoginScreen() {
        let loginViewController = storyboard?.instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
        
        loginViewController.delegate = self
        
        DispatchQueue.main.async {
            self.viewControllers = [loginViewController]
            self.popViewController(animated: true)
        }
    }

    func hideLoginScreen() {
        DispatchQueue.main.async {
            if let restoreViewControllers = self.backupViewControllers {
                self.viewControllers = restoreViewControllers
                self.popViewController(animated: true)
            }
        }
    }
    
    func loggedIn() {
        hideLoginScreen()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backupViewControllers = [self.viewControllers.first!]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        if micropubAuth == nil {
            showLoginScreen()
        } else {
            // todo: What we need to do if we are logged in
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
