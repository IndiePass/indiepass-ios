//
//  MainViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 5/2/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UINavigationController, IndieAuthDelegate {
    
    var loginViewController: UIViewController? = nil
    var backupViewControllers: [UIViewController]? = nil
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    func showLoginScreen() {
        let loginViewController = storyboard?.instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
        
        loginViewController.delegate = self
        
        DispatchQueue.main.async {
            self.viewControllers = [loginViewController]
            self.popViewController(animated: true)
        }
    }

    func hideLoginScreen() {
        DispatchQueue.main.async { [weak self] in
            if let restoreViewControllers = self?.backupViewControllers {
                self?.viewControllers = restoreViewControllers
                if let channelVC = self?.viewControllers.first as? ChannelViewController {
                    channelVC.dataController = ChannelDataController()
                    channelVC.dataController.container = self?.container
                }
                self?.popViewController(animated: true)
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
        let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        
        if micropubAccounts.count < 1 {
            showLoginScreen()
            UIApplication.shared.shortcutItems = []
        } else {
            // todo: What we need to do if we are logged in
            print("Logged in")
            let shortcutItem = UIApplicationShortcutItem(type: ShortcutItemType.NewPost.rawValue, localizedTitle: "New Post")
            UIApplication.shared.shortcutItems = [shortcutItem]
//            let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
//            let micropubAuth = micropubAccounts[activeAccount]
            
            if let channelVC = viewControllers.first as? ChannelViewController {
                channelVC.dataController = ChannelDataController()
                channelVC.dataController.container = container
            }
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
