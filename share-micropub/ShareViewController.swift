//
//  ShareViewController.swift
//  ShareMicropub
//
//  Created by Eddie Hinkle on 5/2/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

//class ModalViewController: UIViewController,  {
//    @IBAction func maximizeButtonTapped(sender: AnyObject) {
//        maximizeToFullScreen()
//    }
//
//    @IBAction func cancelButtonTapped(sender: AnyObject) {
//        if let delegate = navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
//            delegate.interactiveDismiss = false
//        }
//
//        dismiss(animated: true, completion: nil)
//    }
//}


//SLComposeServiceViewController

class ShareViewController: UITableViewController, HalfModalPresentable {
    
    var micropubAuth: [String: Any]? = nil
    var sharingType: String? = nil
    var sharingContent: URLComponents? = nil
    var extensionItems: [NSExtensionItem]? = nil

//    var micropubActions = ["Like", "Repost", "Bookmark", "Reply"]
    var micropubActions = ["Like", "Repost", "Bookmark"]
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return micropubActions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        cell.textLabel?.text = micropubActions[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        switch(micropubActions[indexPath.row]) {
            case "Like":
                sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!)
            case "Repost":
                sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!)
            case "Bookmark":
                sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!)
            case "Reply":
                performSegue(withIdentifier: "showReplyView", sender: self)
            default:
                let alert = UIAlertController(title: "Oops", message: "This action isn't built yet", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }

    }
        
    func sendMicropub(forAction: String, aboutUrl: URL) {
        
        var entryString = ""
        
        switch(forAction) {
            case "Like":
                entryString = "h=entry&like-of=\(aboutUrl.absoluteString)"
            case "Repost":
                entryString = "h=entry&repost-of=\(aboutUrl.absoluteString)"
            case "Bookmark":
                entryString = "h=entry&bookmark-of=\(aboutUrl.absoluteString)"
            default:
                print("ERROR")
        }
        
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
        
        if let micropubDetails = micropubAuth,
            let micropubEndpoint = URL(string: micropubDetails["micropub_endpoint"] as! String) {
            print(micropubEndpoint)
            
            var request = URLRequest(url: micropubEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyString = "\(entryString)&access_token=\(micropubDetails["access_token"]!)"
            let bodyData = bodyString.data(using:String.Encoding.utf8, allowLossyConversion: false)
            request.httpBody = bodyData
            
            // set up the session
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request) { (data, response, error) in
                print("Done with Task")
                print(data)
                print(response)
                print(error)
                
                if let delegate = self.navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
                    delegate.interactiveDismiss = false
                }
                
                self.dismiss(animated: true, completion: nil)
                self.parent?.parent?.parent?.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
            }
            task.resume()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReplyView",
        let nextVC = segue.destination as? ReplyViewController {
            nextVC.replyUrl = sharingContent?.url
            
        }
    }
    
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
    
    @IBAction func cancelShare(_ sender: UIBarButtonItem) {
        if let delegate = navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
            delegate.interactiveDismiss = false
        }

        dismiss(animated: true, completion: nil)
        self.parent?.parent?.parent?.extensionContext!.cancelRequest(withError: NSError(domain: "pub.abode.indigenous", code: 1))
        
        // todo: Need to figure out how to fix this
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loading View")
        print(extensionItems?.first)

        let itemProvider = extensionItems?.first?.attachments?.first as! NSItemProvider
        let propertyList = String(kUTTypePropertyList)
        let plainText = String(kUTTypePlainText)
        let urlAttachment = String(kUTTypeURL)
        if itemProvider.hasItemConformingToTypeIdentifier(propertyList) {
            itemProvider.loadItem(forTypeIdentifier: propertyList, options: nil, completionHandler: { (item, error) -> Void in
                guard let dictionary = item as? NSDictionary else { return }
                OperationQueue.main.addOperation {
                    print();
                    if let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary,
                        let urlString = results["URL"] as? String,
                        let itemUrl = URLComponents(string: urlString){
                            self.shareUrl(url: itemUrl)
                    }
                }
            })
        } else if itemProvider.hasItemConformingToTypeIdentifier(plainText) {
            itemProvider.loadItem(forTypeIdentifier: plainText, options: nil, completionHandler: { (item, error) -> Void in
                if let itemString = item as? String,
                   let itemUrl = URLComponents(string: itemString) {
                    self.shareUrl(url: itemUrl)
                }
            })
        } else if itemProvider.hasItemConformingToTypeIdentifier(urlAttachment) {
            itemProvider.loadItem(forTypeIdentifier: urlAttachment, options: nil, completionHandler: { (item, error) -> Void in
                if let url = item as? URL,
                   let itemUrl = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    self.shareUrl(url: itemUrl)
                }
            })
        } else {
            print("error")
            print(extensionItems?.first?.attachments)
        }
    }
    
    private func shareUrl(url: URLComponents) {
        print("Time to Share a URL")
        print(url)
        
        sharingType = "url"
        sharingContent = url
        
//        textView?.text = " "
//        reloadConfigurationItems()
    }
    
    private func checkMicropubAuth() {
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        self.micropubAuth = defaults?.dictionary(forKey: "micropubAuth")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
        
        UIView.animate(withDuration: 0.20, animations: { () -> Void in
            self.view.transform = .identity
        })
        
        //checkMicropubAuth()
//        self.reloadConfigurationItems()
        //if self.micropubAuth == nil {
//            self.textView?.text = "You have to log in before you can post using micropub"
//            self.textView?.textColor = UIColor.red
//            self.textView?.isUserInteractionEnabled = false
        //}
        
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
    
    func showLoginScreen() {
        let loginViewController = storyboard?.instantiateViewController(withIdentifier: "indieAuthLoginView") as! IndieAuthLoginViewController
        
        DispatchQueue.main.async {
            self.present(loginViewController, animated: true, completion: nil)
        }
    }

}
