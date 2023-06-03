//
//  AccountDebugViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/31/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class AccountDebugViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    public var debugAccount: IndieAuthAccount? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("debugging")
        if let account = debugAccount {
            print(String(describing: debugAccount))
            textView.text = "Debugging: \(account.profile.name ?? ""): \(account.profile.url?.absoluteString ?? "")\n\n"
            
            textView.text = textView.text + "Micropub Endpoint: \(account.micropub_endpoint)"
            if account.microsub_endpoint != nil {
                textView.text = textView.text + "Microsub Endpoint: \(String(describing: account.microsub_endpoint))"
            }
            textView.text = textView.text + "Scopes: \(String(describing: account.scope))\n\n"
            
//            textView.text = textView.text + "Access Token: \(account.access_token)\n\n"
            
            if let config = account.micropub_config {
                if let mediaEndpoint = config.mediaEndpoint {
                    textView.text = textView.text + "Media Endpoint: \(mediaEndpoint)\n\n"
                } else {
                    textView.text = textView.text + "No Media Endpoint Found\n\n"
                }
                
                if let syndicationTargets = config.syndicateTo {
                    textView.text = textView.text + "Syndication Targets: \(String(describing: syndicationTargets))\n\n"
                } else {
                    textView.text = textView.text + "No Syndication Targets Found\n\n"
                }
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
