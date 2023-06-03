//
//  AccountSelectorTableViewController.swift
//  share-micropub
//
//  Created by Edward Hinkle on 12/27/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class AccountSelectorTableViewController: UITableViewController {

    var userAccounts: [IndieAuthAccount] = []
    var activeUserAccount: Int = 0
    var userAccountChanged: ((_ user: Int) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshAccountData()
        tableView.delegate = self
        tableView.dataSource = self
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func refreshAccountData() {
        print("refreshing data")
        userAccounts.removeAll()
        let defaults = UserDefaults(suiteName: "group.software.studioh.indiepass")
        let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        micropubAccounts.forEach { userData in
            if let newAccount = try? JSONDecoder().decode(IndieAuthAccount.self, from: userData) {
                userAccounts.append(newAccount)
            }
        }
        print("accounts?")
        print(userAccounts.count)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userAccounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)

        cell.textLabel?.text = IndieAuth.getSimpleDomain(forAccount: userAccounts[indexPath.row])
        
        if (activeUserAccount == indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
        activeUserAccount = indexPath.row
        refreshAccountData()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        userAccountChanged?(activeUserAccount)
        self.navigationController?.popViewController(animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
