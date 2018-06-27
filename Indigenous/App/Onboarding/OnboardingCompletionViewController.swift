//
//  OnboardingCompletionViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 6/26/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class OnboardingCompletionViewController: OnboardingTemplateViewController {

    var dataController: DataController!
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowLoginForm",
            let nextVC = segue.destination as? IndieAuthLoginViewController {
            nextVC.dataController = dataController
        }
    }

}
