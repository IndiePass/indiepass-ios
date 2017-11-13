//
//  MicropubShareViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 6/10/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import Social

class MicropubShareViewController: UIViewController, UINavigationControllerDelegate {

    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    var extensionItems: [NSExtensionItem] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        guard micropubAuth != nil else {
            let alert = UIAlertController(title: "Not logged in", message: "You are not currently logged in. Please open Indigenous and log in before using the Share extension.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default) { action in
                self.cancelShareSheet()
            })
            self.present(alert, animated: true)
            return
        }
        
        extensionItems = extensionContext?.inputItems as! [NSExtensionItem]
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
        
        if let modalNavVC = segue.destination as? ModalNavController {
            modalNavVC.delegate = self
           if let shareVC = modalNavVC.viewControllers.first as? ShareViewController {
             shareVC.extensionItems = extensionItems
           }
        }
    }
    
    public func finishedShareSheet() {
        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    public func cancelShareSheet() {
        self.extensionContext!.cancelRequest(withError: NSError(domain: "pub.abode.indigenous", code: 1))
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
