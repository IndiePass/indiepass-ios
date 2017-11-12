//
//  ReplyViewController.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 7/14/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class ReplyViewController: UIViewController {
    
    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var noteText: UITextView!
    
    var replyUrl: URL? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.automaticallyAdjustsScrollViewInsets = false

//        let keyboardToolbar = UIToolbar()
//        keyboardToolbar.sizeToFit()
//        keyboardToolbar.isTranslucent = false
//        keyboardToolbar.barTintColor = UIColor.white
//        
//        let addButton = UIBarButtonItem(
//            barButtonSystemItem: .done,
//            target: self,
//            action: #selector(buttonPressed)
//        )
//        addButton.tintColor = UIColor.black
//        keyboardToolbar.items = [addButton]
//        noteText.inputAccessoryView = keyboardToolbar
    }
    
    func buttonPressed() {
        print("test");
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
