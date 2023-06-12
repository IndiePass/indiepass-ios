//
//  UserSettingsTableViewController.swift
//  IndiePass
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
    var fetchingSyndicateTargets = false
    
    let notificationFeedback = UINotificationFeedbackGenerator()
    
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
        let defaults = UserDefaults(suiteName: AppGroup)
        activeUserAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        defaultUserAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
        let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        micropubAccounts.forEach { userData in
            if let newAccount = try? JSONDecoder().decode(IndieAuthAccount.self, from: userData) {
                userAccounts.append(newAccount)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0:
                return userSettings.count + 4
            case 1:
                return userAccounts.count + 1
            case 2:
                return 2
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
                    cell.imageView?.image = UIImage.fontAwesomeIcon(name: .userCircleO, textColor: ThemeManager.currentTheme().textColor, size: CGSize(width: 30, height: 30))
                } else {
                    cell.imageView?.image = UIImage.fontAwesomeIcon(name: .user, textColor: ThemeManager.currentTheme().textColor, size: CGSize(width: 30, height: 30))
                }
            } else {
                cell.textLabel?.text = "Add New Micropub Account"
                cell.imageView?.image = nil
            }
            
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserSettingCell", for: indexPath)
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Cardinal (Light)"
                cell.imageView?.image = nil
            case 1:
                cell.textLabel?.text = "Zombie (Dark)"
                cell.imageView?.image = nil
            default:
                cell.textLabel?.text = nil
                cell.imageView?.image = nil
            }
            cell.detailTextLabel?.text = nil
            
            if (ThemeManager.currentTheme().rawValue == indexPath.row) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserSettingCell", for: indexPath)
        if indexPath.row < userSettings.count {
            print(indexPath)
            print(userSettings.count)
        } else {
            if indexPath.row == userSettings.count {
                cell.textLabel?.text = "Refresh Syndication Targets"
                cell.detailTextLabel?.text = fetchingSyndicateTargets ? "Loading" : ""
            } else if indexPath.row == userSettings.count + 1 {
                cell.textLabel?.text = "View Account Debug Info"
                cell.detailTextLabel?.text = ""
            } else if indexPath.row == userSettings.count + 2 {
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
            } else if indexPath.row == userSettings.count + 3 {
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
            case 2:
                return "Theme"
            default:
                return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let defaults = UserDefaults(suiteName: AppGroup)
        
        if indexPath.section == 1 {
            
            notificationFeedback.notificationOccurred(.success)
            
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
            
        } else if indexPath.section == 2 {
        
            if let theme = Theme(rawValue: indexPath.row) {
                notificationFeedback.notificationOccurred(.success)
                ThemeManager.applyTheme(theme: theme, window: UIApplication.shared.keyWindow)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    UIApplication.shared.keyWindow?.subviews.forEach({ (view: UIView) in
                        view.removeFromSuperview()
                        UIApplication.shared.keyWindow?.addSubview(view)
                    })
                }
            } else {
                // TODO: Present error that apply theme failed
                notificationFeedback.notificationOccurred(.error)
            }
            
            
        } else {
            
            if (indexPath.row < userSettings.count) {
                // todo: Settings
                
            } else {
                if indexPath.row == userSettings.count {
                    notificationFeedback.notificationOccurred(.success)
                    refreshSyndicationTargets()
                } else if indexPath.row == userSettings.count + 1 {
                    // TODO: View DEBUG INFO
                    viewAccountDebug()
                } else if indexPath.row == userSettings.count + 2 {
                    notificationFeedback.notificationOccurred(.success)
                    makeCurrentUserDefault()
                } else if indexPath.row == userSettings.count + 3 {
                    notificationFeedback.notificationOccurred(.success)
                    logOutCurrentUser()
                }
            }
        }
        
    }
    
    func viewAccountDebug() {
        performSegue(withIdentifier: "showAccountDebug", sender: nil)
    }
    
    func refreshSyndicationTargets() {
        fetchingSyndicateTargets = true
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        let defaults = UserDefaults(suiteName: AppGroup)
        let activeAccountId = defaults?.integer(forKey: "activeAccount") ?? 0
        var micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        if var activeAccount = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccountId]) {
            IndieAuth.getSyndicationTargets(forEndpoint: activeAccount.micropub_endpoint, withToken: activeAccount.access_token) { syndicateTargets, error in
                
                guard error == nil else {
                    DispatchQueue.main.sync {
                        let alert = UIAlertController(title: "Syndication Targets Failed", message: error ?? "no message", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                activeAccount.micropub_config?.syndicateTo = syndicateTargets
                // todo: save account info
                if let activeAccountData = try? JSONEncoder().encode(activeAccount) {
                    micropubAccounts[activeAccountId] = activeAccountData
                    defaults?.set(micropubAccounts, forKey: "micropubAccounts")
                    self.fetchingSyndicateTargets = false
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
            }
        }
    
    }
    
    func logOutCurrentUser() {
        let defaults = UserDefaults(suiteName: AppGroup)
        var activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        let defaultAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
        var micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        
        if let accountToRemove = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            IndieAuth.revokeIndieAuthToken(forAccount: accountToRemove) { errorMessage in
                if errorMessage != nil {
//                    DispatchQueue.main.async {
//                        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
//                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                        self.present(alert, animated: true, completion: nil)
//                    }
                    print("Error while reokving auth token")
                    print(String(describing: errorMessage))
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
        let defaults = UserDefaults(suiteName: AppGroup)
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        defaults?.set(activeAccount, forKey: "defaultAccount")
        refreshAccountData()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func showLoginScreen(displayAsModal modal: Bool = false) {
        loginDisplayedAsModal = modal
        
        let loginViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
    
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController: UIViewController? = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController
        }
        
        if segue.identifier == "showAccountDebug",
            let debugVC = destinationViewController as? AccountDebugViewController {
                    let defaults = UserDefaults(suiteName: AppGroup)
                    let activeAccountId = defaults?.integer(forKey: "activeAccount") ?? 0
                    var micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
                    if let activeAccount = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccountId]) {
                        
                            debugVC.debugAccount = activeAccount
                        
                    }
        }
    }

}
