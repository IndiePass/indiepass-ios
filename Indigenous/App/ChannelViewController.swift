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

class ChannelViewController: UITableViewController {
    
//    var micropubAuth: [String: Any]? = nil
//    var sharingType: String? = nil
//    var sharingContent: URLComponents? = nil
//    var extensionItems: [NSExtensionItem]? = nil
//    var micropubActions = ["Like", "Repost", "Bookmark"]
    
    var channels: [[Channel]] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return channels.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 1:
                return "Channels"
            case 2:
                return "Accounts"
            default:
                return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath)
        
        cell.textLabel?.text = channels[indexPath.section][indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
        let selectedChannel = channels[indexPath.section][indexPath.row]
        
        print("Channel selected")
        print(selectedChannel)
        
        if (selectedChannel.uid == "logout") {
            defaults?.removeObject(forKey: "micropubAuth")
            if let mainVC = self.parent as? MainViewController {
                mainVC.showLoginScreen()
            }
        } else {
            getSingleChannelData(channel: selectedChannel) {
                print("All done with timeline")
            }
        }
        
//        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
//        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
//        switch(micropubActions[indexPath.row]) {
//        case "Like":
//            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, completion: shareComplete)
//        case "Repost":
//            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, completion: shareComplete)
//        case "Bookmark":
//            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, completion: shareComplete)
//        case "Listen":
//            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, completion: shareComplete)
//        case "Reply":
//            performSegue(withIdentifier: "showReplyView", sender: self)
//        default:
//            let alert = UIAlertController(title: "Oops", message: "This action isn't built yet", preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
        
    }
    
//    func shareComplete() {
//        if let delegate = self.navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
//            delegate.interactiveDismiss = false
//        }
//
//        DispatchQueue.main.async {
//            self.dismiss(animated: true) { () in
//                if let presentingVC = self.parent?.transitioningDelegate as? HalfModalTransitioningDelegate,
//                    let micropubVC = presentingVC.viewController as? MicropubShareViewController {
//                    micropubVC.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
//                }
//            }
//        }
//    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showReplyView",
//            let nextVC = segue.destination as? ReplyViewController {
//            nextVC.replyUrl = sharingContent?.url
//
//        }
//    }
    
    //    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    //
    //        print(indexPath)
    //
    //        switch(micropubActions[indexPath.row]) {
    //            case "Like":
    //                print("Liking ")
    ////                print(self.parent?.extensionContext!.inputItems)
    //            case "Repost":
    //                print("Reposting ")
    ////                print(self.parent?.extensionContext!.inputItems)
    //            case "Bookmark":
    //                print("Bookmarking ")
    ////                print(self.parent?.extensionContext!.inputItems)
    //            default:
    //                print("oops")
    //        }
    //
    //        print(self.parent?.extensionContext!.inputItems)
    //
    //    }
    
//    @IBAction func cancelShare(_ sender: UIBarButtonItem) {
//
//        if let delegate = navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
//            delegate.interactiveDismiss = false
//        }
//
//        dismiss(animated: true) { () in
//            if let presentingVC = self.parent?.transitioningDelegate as? HalfModalTransitioningDelegate,
//                let micropubVC = presentingVC.viewController as? MicropubShareViewController {
//                micropubVC.extensionContext!.cancelRequest(withError: NSError(domain: "pub.abode.indigenous", code: 1))
//            }
//        }
//    }
    
    func getSingleChannelData(channel: Channel, callback: (() -> ())? = nil) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        guard let microsubEndpoint = micropubAuth?["microsub_endpoint"] as? String else {
            print("microsubEndpoint failure")
            return
        }
        
        guard var microsubUrl = URLComponents(string: microsubEndpoint) else {
            print("Making url of microsub fails")
            return
        }
        
        if microsubUrl.queryItems == nil {
            microsubUrl.queryItems = []
        }
        
        microsubUrl.queryItems?.append(URLQueryItem(name: "action", value: "timeline"))
        microsubUrl.queryItems?.append(URLQueryItem(name: "channel", value: channel.uid))
        
        guard let microsub = microsubUrl.url else {
            print("Error making final url")
            return
        }
        
        guard let access_token = micropubAuth?["access_token"] as? String else {
            print("Access Token Error")
            return
        }
        
        var request = URLRequest(url: microsub)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        
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
                            print("Get Timeline")
                            print(body)
//                            let channelResponse = try! JSONDecoder().decode(ChannelApiResponse.self, from: body.data(using: .utf8)!)
//
//                            channelResponse.channels.forEach { nextChannel in
//                                self.channels.append(nextChannel)
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
    }
    
    func getChannelData(callback: (() -> ())? = nil) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        self.channels = [[], [], []];
        self.channels[0].append(Channel(uid: "default", name: "Home"))
        self.channels[0].append(Channel(uid: "notifications", name: "Notifications"))
        if micropubAuth != nil, let meUrl = micropubAuth?["me"] as? String {
            self.channels[2].append(Channel(uid: "logout", name: "Log out (\(meUrl))"))
        }
        
        guard let microsubEndpoint = micropubAuth?["microsub_endpoint"] as? String else {
            print("microsubEndpoint failure")
            return
        }
        
        guard var microsubUrl = URLComponents(string: microsubEndpoint) else {
            print("Making url of microsub fails")
            return
        }
        
        if microsubUrl.queryItems == nil {
            microsubUrl.queryItems = []
        }
        
        microsubUrl.queryItems?.append(URLQueryItem(name: "action", value: "channels"))
        
        guard let microsub = microsubUrl.url else {
            print("Error making final url")
            return
        }
        
        guard let access_token = micropubAuth?["access_token"] as? String else {
            print("Access Token Error")
            return
        }
        
        var request = URLRequest(url: microsub)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        
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
                            
                            channelResponse.channels.forEach { nextChannel in
                                self.channels[1].append(nextChannel)
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
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        getChannelData {
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        getChannelData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
