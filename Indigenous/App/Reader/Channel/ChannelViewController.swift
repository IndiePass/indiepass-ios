//
//  ChannelViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Crashlytics

class ChannelViewController: UITableViewController {
        
    var channels: [Channel] = []
    var selectedChannel: Channel? = nil
    var timelines: [[Jf2Post]] = []
    var commands: [Command] = []
    
    var currentAccount: IndieAuthAccount? = nil
    
//    @IBOutlet weak var notificationButton: UIBarButtonItem!
    @IBOutlet weak var accountButton: UIBarButtonItem!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if currentAccount?.me.absoluteString == "https://eddiehinkle.com/" {
            return 2
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if currentAccount?.me.absoluteString == "https://eddiehinkle.com/", section == 1 {
            return "Remote Commands"
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentAccount?.me.absoluteString == "https://eddiehinkle.com/", section == 1 {
            return commands.count
        }
        
        print(section)
        print(channels)
        
        return channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if currentAccount?.me.absoluteString == "https://eddiehinkle.com/", indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell", for: indexPath)
            
            if let commandCell = cell as? CommandTableViewCell {
                let command = commands[indexPath.row]
                commandCell.setContent(ofCommand: command)
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath)
     
        if let channelCell = cell as? ChannelTableViewCell {
            let channelData = channels[indexPath.row]
            channelCell.setContent(ofChannel: channelData)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if currentAccount?.me.absoluteString == "https://eddiehinkle.com/", indexPath.section == 1 {
            let command = commands[indexPath.row]
            command.sendCommand()
        }
        
//        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let selectedChannel = channels[indexPath.row]
        
        self.selectedChannel = selectedChannel
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewTimeline",
            let channelCell = sender as? ChannelTableViewCell,
            let nextVC = segue.destination as? TimelineViewController {
                nextVC.channel = channelCell.data
                nextVC.title = channelCell.data?.name
        }
    }
    
    func getSingleChannelData(channel: Int, forTimeline timeline: Channel, callback: (() -> ())? = nil) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
        
                guard let microsubUrl = micropubDetails.microsub_endpoint,
                      var microsubComponents = URLComponents(url: microsubUrl, resolvingAgainstBaseURL: true) else {
                        print("Microsub URL doesn't exist")
                        return
                }
            
                if microsubComponents.queryItems == nil {
                    microsubComponents.queryItems = []
                }
            
                microsubComponents.queryItems?.append(URLQueryItem(name: "action", value: "timeline"))
                microsubComponents.queryItems?.append(URLQueryItem(name: "channel", value: timeline.uid))
            
                guard let microsub = microsubComponents.url else {
                    print("Error making final url")
                    return
                }
            
                var request = URLRequest(url: microsub)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(micropubDetails.access_token)", forHTTPHeaderField: "Authorization")
            
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
            
                let task = session.dataTask(with: request) { (data, response, error) in
                    // check for any errors
                    guard error == nil else {
                        print("error calling POST on \(microsubComponents)")
                        print(error ?? "No error present")
                        return
                    }
                    
                    // Check if endpoint is in the HTTP Header fields
                    if let httpResponse = response as? HTTPURLResponse, let body = String(data: data!, encoding: .utf8) {
                        if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                            if httpResponse.statusCode == 200 {
                                if contentType == "application/json" {
                                    let timelineResponse = try! JSONDecoder().decode(TimelineApiResponse.self, from: body.data(using: .utf8)!)
                                    
        //                            print(self.timelines)
        //                            print("should insert")
        //                            print(channel)
                                    
                                    self.timelines.append(timelineResponse.items)

        //                            timelineResponse.items.forEach { nextPost in
        //                                print(nextPost)
        //
        //                            }
                                    //        movies.sort() { $0.title < $1.title }
                                    
        //                            DispatchQueue.main.async {
        //                                self.tableView.reloadData()
        //                            }
                                    
                                    callback?()
                                }
                            } else {
                                print("Status Code not 200")
                                print(httpResponse)
                                print(body)
                            }
                        }
                    }
                    
                }
            
                task.resume()
        } else {
            print("missing micropubDetails")
        }
    }
    
    func getChannelData(callback: (() -> ())? = nil) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            
                guard let microsubUrl = micropubDetails.microsub_endpoint,
                    var microsubComponents = URLComponents(url: microsubUrl, resolvingAgainstBaseURL: true) else {
                        print("Microsub URL doesn't exist")
                        return
                }
            
                if microsubComponents.queryItems == nil {
                    microsubComponents.queryItems = []
                }
            
                microsubComponents.queryItems?.append(URLQueryItem(name: "action", value: "channels"))
            
                guard let microsub = microsubComponents.url else {
                    print("Error making final url")
                    return
                }
            
                var request = URLRequest(url: microsub)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(micropubDetails.access_token)", forHTTPHeaderField: "Authorization")
            
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
            
                let task = session.dataTask(with: request) { (data, response, error) in
                    // check for any errors
                    guard error == nil else {
                        print("error calling POST on \(microsubUrl)")
                        print(error ?? "No error present")
                        return
                    }
                    
                    // Check if endpoint is in the HTTP Header fields
                    if let httpResponse = response as? HTTPURLResponse, let body = String(data: data!, encoding: .utf8) {
                        if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                            if httpResponse.statusCode == 200 {
                                if contentType == "application/json" {
                                    let channelResponse = try! JSONDecoder().decode(ChannelApiResponse.self, from: body.data(using: .utf8)!)
                                    
                                    self.channels = [];
                                    
                                    channelResponse.channels.forEach { nextChannel in
                                        self.channels.append(nextChannel)
                                    }
                                    
                                    //        movies.sort() { $0.title < $1.title }
                                
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }

                                    callback?()
                                }
                            } else {
                                print("Status Code not 200")
                                print(httpResponse)
                                print(body)
                            }
                        }
                    }
                    
                }
            
                task.resume()
        }
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        getChannelData {
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func handleCreateNewPost() {
        performSegue(withIdentifier: "showPostingInterface", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
               selector: #selector(handleCreateNewPost),
               name: NSNotification.Name(rawValue: "createNewPost"),
               object: nil)

        
//        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
//        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
//        let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
//        if  micropubAccounts.count >= activeAccount + 1,
//            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
//            
//            self.title = micropubDetails.me.absoluteString.components(separatedBy: "://").last?.components(separatedBy: "/").first
//            
////        if let url = URL(string: "https://eddiehinkle.com/images/profile.jpg") {
////            getDataFromUrl(url: url) { data, response, error in
////                guard let data = data, error == nil else { return }
////                print(response?.suggestedFilename ?? url.lastPathComponent)
////                print("Download Finished")
////                DispatchQueue.main.async() {
////                    self.profileIcon?.image = UIImage(data: data)
////                }
////            }
////        }
//        
//            tableView.delegate = self
//            tableView.dataSource = self
//            self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
//            getChannelData()
//        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        accountButton.image = UIImage.fontAwesomeIcon(name: .user, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        accountButton.tintColor = self.view.tintColor
//        notificationButton.image = UIImage.fontAwesomeIcon(name: .globe, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let defaultAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? defaultAccount
        let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        if  micropubAccounts.count >= activeAccount + 1,
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            
            self.currentAccount = micropubDetails
            
            self.title = micropubDetails.me.absoluteString.components(separatedBy: "://").last?.components(separatedBy: "/").first
            
            // log current domain for crash analytics
            Crashlytics.sharedInstance().setUserName(micropubDetails.me.absoluteString)
            CLSLogv("Viewed Channel VC", getVaList([]))

            
//            micropubDetails.profile.downloadPhoto(photoIndex: 0) { photo in
//                if let authorPhoto = photo {
//                    DispatchQueue.main.async {
//                        let button: UIButton = UIButton(type: .custom)
//                        button.setImage(authorPhoto.withRenderingMode(.alwaysOriginal), for: .normal)
//                        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//                        button.contentMode = .scaleAspectFit
//                        self.accountButton.customView = button
//                        
//                    }
//                }
//            }
            
            tableView.delegate = self
            tableView.dataSource = self
            self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
            getChannelData()
            
            if currentAccount?.me.absoluteString == "https://eddiehinkle.com/" {
                commands = [
                    Command(name: "Rebuild Site",
                            url: URL(string: "https://eddiehinkle.com/abode/rebuild/slack/")!,
                            body: ["token": "h0uOKoXJklurbaIY6AbqW9PZ"])
                ]
            }
        }
    }
    
    //    override func isContentValid() -> Bool {
    //        // Do validation of contentText and/or NSExtensionContext attachments here
    //
    //        if self.micropubAuth == nil {
    //            return false
    //        }
    //
    //        return true
    //    }
    //
    //    override func didSelectPost() {
    //        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    //        print("Outpuing Content")
    //        print(contentText)
    //
    //        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    //        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    //    }
    //
    //    override func configurationItems() -> [Any]! {
    //        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    //
    //        var deck: [SLComposeSheetConfigurationItem]? = []
    //
    //        if self.micropubAuth == nil {
    //            print("CREATE LOGIN CONFIGURATION")
    //            let loginConfig = SLComposeSheetConfigurationItem()
    //            loginConfig?.title = "Log In"
    //            loginConfig?.value = nil
    //            loginConfig?.tapHandler = {
    //                // Need to find out how to send "Logged In" info back to the extension so it will make the screen dissapear
    //                // Maybe just redirect via URI scheme to the app login path, then return here via safari://
    //                self.showLoginScreen()
    //            }
    //
    //            deck?.append(loginConfig!)
    //        } else {
    //            // todo: if h-event exists, add RSVP options in one of these
    //            // todo: if h-entry exists: decide what we can do with an h-entry
    //
    //            let actionConfig = SLComposeSheetConfigurationItem()
    //            actionConfig?.title = "Action"
    //            actionConfig?.value = "👍 Like"
    //            actionConfig?.tapHandler = {
    //
    //            }
    //
    //            deck?.append(actionConfig!)
    //        }
    //
    //        if deck?.count == 0 {
    //            deck = nil
    //        }
    //        return deck
    //    }
    
//    func showLoginScreen() {
//        let loginViewController = storyboard?.instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
//
//        DispatchQueue.main.async {
//            self.present(loginViewController, animated: true, completion: nil)
//        }
//    }
    
}
