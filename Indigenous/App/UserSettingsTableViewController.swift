//
//  UserSettingsTableViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/27/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class UserSettingsTableViewController: UITableViewController, IndieAuthDelegate {

    var userAccounts: [IndieAuthAccount] = []
    var activeUserAccount: Int = 0
    var defaultUserAccount: Int = 0
    var userSettings: [String] = []
    var loginDisplayedAsModal: Bool? = nil
    
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
        userAccounts.removeAll()
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        activeUserAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        defaultUserAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0:
                return userSettings.count + 2
            case 1:
                return userAccounts.count + 1
            default:
                return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserAccountCell", for: indexPath)
            
            if (indexPath.row < userAccounts.count) {
                cell.textLabel?.text = userAccounts[indexPath.row].me.absoluteString.components(separatedBy: "://").last?.components(separatedBy: "/").first
                
                if (activeUserAccount == indexPath.row) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                
                if (defaultUserAccount == indexPath.row) {
                    cell.imageView?.image = UIImage.fontAwesomeIcon(name: .userCircleO, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
                } else {
                    cell.imageView?.image = UIImage.fontAwesomeIcon(name: .user, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
                }
            } else {
                cell.textLabel?.text = "Add New Micropub Account"
                cell.imageView?.image = nil
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserSettingCell", for: indexPath)
        if indexPath.row < userSettings.count {
            print(indexPath)
            print(userSettings.count)
        } else {
            if indexPath.row == userSettings.count {
                if (defaultUserAccount == activeUserAccount) {
                    cell.textLabel?.text = "This account is the default"
                    cell.isUserInteractionEnabled = false
                    cell.textLabel?.isEnabled = false
                } else {
                    cell.textLabel?.text = "Make this account default"
                    cell.isUserInteractionEnabled = true
                    cell.textLabel?.isEnabled = true
                }
                cell.detailTextLabel?.text = ""
            } else if indexPath.row == userSettings.count + 1 {
                cell.textLabel?.text = "Log Out"
                cell.textLabel?.textColor = UIColor(red: 1, green: 0.2196078431, blue: 0.137254902, alpha: 1)
                cell.detailTextLabel?.text = userAccounts[activeUserAccount].me.absoluteString.components(separatedBy: "://").last?.components(separatedBy: "/").first
                cell.detailTextLabel?.textColor = UIColor(red: 1, green: 0.2196078431, blue: 0.137254902, alpha: 1)
            }
        }
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return userAccounts[activeUserAccount].me.absoluteString.components(separatedBy: "://").last?.components(separatedBy: "/").first
            default:
                return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
        if indexPath.section == 1 {
            
            if (indexPath.row < userAccounts.count) {
                activeUserAccount = indexPath.row
                defaults?.set(activeUserAccount, forKey: "activeAccount")
                refreshAccountData()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                showLoginScreen()
            }
            
        } else {
            
            if (indexPath.row < userSettings.count) {
                // todo: Settings
                
            } else {
                if indexPath.row == userSettings.count {
                    makeCurrentUserDefault()
                } else if indexPath.row == userSettings.count + 1 {
                    logOutCurrentUser()
                }
            }
        }
        
    }
    
    func logOutCurrentUser() {
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        var activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        let defaultAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
        var micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        
        if let accountToRemove = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            IndieAuth.revokeIndieAuthToken(forAccount: accountToRemove) { errorMessage in
                if errorMessage != nil {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
                micropubAccounts.remove(at: activeAccount)
                if (activeAccount == defaultAccount) {
                    activeAccount = 0
                    defaults?.set(0, forKey: "defaultAccount")
                } else {
                    activeAccount = defaultAccount
                }
                
                defaults?.set(activeAccount, forKey: "activeAccount")
                defaults?.set(micropubAccounts, forKey: "micropubAccounts")
                
                if micropubAccounts.count < 1 {
                    self.showLoginScreen(displayAsModal: true)
                } else {
                    self.refreshAccountData()
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func makeCurrentUserDefault() {
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        defaults?.set(activeAccount, forKey: "defaultAccount")
        refreshAccountData()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func showLoginScreen(displayAsModal modal: Bool = false) {
        loginDisplayedAsModal = modal
        
        let loginViewController = storyboard?.instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
    
        loginViewController.delegate = self
        loginViewController.displayedAsModal = loginDisplayedAsModal
        loginViewController.title = "Add New Micropub"
        
        DispatchQueue.main.async {
            if let displayedModal = self.loginDisplayedAsModal, displayedModal == true {
                self.present(loginViewController, animated: true, completion: nil)
            } else {
                self.navigationController?.pushViewController(loginViewController, animated: true)
            }
        }
    }
    
    func loggedIn() {
        if let displayedModal = loginDisplayedAsModal, displayedModal == true { } else {
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
        loginDisplayedAsModal = nil
        refreshAccountData()
        DispatchQueue.main.sync {
            self.tableView.reloadData()
        }
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
