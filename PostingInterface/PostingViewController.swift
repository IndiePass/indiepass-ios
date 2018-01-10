//
//  PostingViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/9/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class PostingViewController: UIViewController {

    var activeAccount: IndieAuthAccount? = nil
    var currentPost: MicropubPost? = nil
    
    @IBOutlet weak var postContentField: UITextView!
    
    @IBAction func cancelModal(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendPost(_ sender: Any) {
        if let account = activeAccount, var post = currentPost {
            post.properties.content = postContentField.text
            
            MicropubPost.send(post: post, as: .json, forUser: account) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postContentField.becomeFirstResponder()
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccountId = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let currentAccount = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccountId]) {
            
                activeAccount = currentAccount
                currentPost = MicropubPost(type: .entry, properties: MicropubPostProperties())
            
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
