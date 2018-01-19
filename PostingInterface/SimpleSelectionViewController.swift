//
//  SimpleSelectionViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/14/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class SimpleSelectionViewController: UIViewController, SimpleSelectionReadOnlyDelegate, UITextFieldDelegate {
    
    public var delegate: SimpleSelectionDelegate? = nil
    public var options: [SimpleSelectionItem] = []
    public var readOnly: Bool = false
    var tableViewController: SimpleSelectionTableViewController? = nil
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    @IBAction func createNewItem(_ sender: UIButton) {
        if !readOnly {
            add()
        }
    }
    
    func add() {
        if let newItemText = searchField.text, !newItemText.isEmpty {
            let newItem = SimpleSelectionItem(label: newItemText, selected: true)
            tableViewController?.add(item: newItem)
            delegate?.newCreated(item: newItem)
            searchField.text = ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchField.delegate = self
        if readOnly {
            addButton.isHidden = true
        } else {
            addButton.isHidden = false
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !readOnly {
            add()
            return true
        } else {
            return false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func selectionWasUpdated(currentlySelected: [Int]) -> Void {
        delegate?.selectionWasUpdated(currentlySelected: currentlySelected)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "displayTagsView" {
            if let nextVC = segue.destination as? SimpleSelectionTableViewController {
                tableViewController = nextVC
                nextVC.options = self.options
                nextVC.delegate = self
            }
        }
    }

}
