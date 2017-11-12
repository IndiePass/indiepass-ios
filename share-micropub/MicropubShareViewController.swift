//
//  MicropubShareViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 6/10/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import Social

class MicropubShareViewController: UIViewController {

    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    var extensionItems: [NSExtensionItem] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extensionItems = extensionContext?.inputItems as! [NSExtensionItem]
        
        print("grabbing extension")
        print(extensionItems)
        performSegue(withIdentifier: "presentModalNav", sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
        
        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
        
        print("checking vcs")
        print(segue.destination)
        
        if let modalNavVC = segue.destination as? ModalNavController {
           print("inside modal nav")
           if let shareVC = modalNavVC.viewControllers.first as? ShareViewController {
             print("setting extension items")
             shareVC.extensionItems = extensionItems
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
