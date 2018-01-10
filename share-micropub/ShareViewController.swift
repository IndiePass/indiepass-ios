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
    
//    var micropubAuth: [String: Any]? = nil
    var sharingType: String? = nil
    var sharingContent: URLComponents? = nil
    var extensionItems: [NSExtensionItem]? = nil
    var micropubActions: [MicropubTypes] = []
    var currentAccount: IndieAuthAccount? = nil
    var activeAccount: Int = 0
    var shouldAnimateIn: Bool = true
    
//    var micropubActions = ["Like", "Repost", "Bookmark", "Reply"]
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Responses"
        case 1:
            return "Settings"
        default:
            return nil
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0:
                return micropubActions.count
            case 1:
                return 1;
            default:
                return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ResponseCell", for: indexPath)
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ResponseCell", for: indexPath)
            cell.textLabel?.text = micropubActions[indexPath.row].rawValue
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        if let accountDetails = currentAccount {
            cell.textLabel?.text = "Account"
            cell.detailTextLabel?.text = IndieAuth.getSimpleDomain(forAccount: accountDetails)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
        
                if (indexPath.section == 0) {
                    switch(micropubActions[indexPath.row]) {
                        case .like:
                            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, forUser: micropubDetails, completion: shareComplete)
                        case .repost:
                            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, forUser: micropubDetails, completion: shareComplete)
                        case .bookmark:
                            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, forUser: micropubDetails, completion: shareComplete)
                        case .listen:
                            sendMicropub(forAction: micropubActions[indexPath.row], aboutUrl: sharingContent!.url!, forUser: micropubDetails, completion: shareComplete)
                        case .reply:
                            performSegue(withIdentifier: "showReplyView", sender: self)
                        default:
                            let alert = UIAlertController(title: "Oops", message: "This action isn't built yet", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                    }
                }
        }

    }
    
    func shareComplete() {
        if let delegate = self.navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
            delegate.interactiveDismiss = false
        }
        
        DispatchQueue.main.async {
            self.dismiss(animated: true) { () in
                if let presentingVC = self.parent?.transitioningDelegate as? HalfModalTransitioningDelegate,
                    let micropubVC = presentingVC.viewController as? MicropubShareViewController {
                    micropubVC.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReplyView",
        let nextVC = segue.destination as? ReplyViewController {
            nextVC.replyUrl = sharingContent?.url
            
        }
        
        if segue.identifier == "showAccountSelection",
            let nextVC = segue.destination as? AccountSelectorTableViewController {
            nextVC.activeUserAccount = activeAccount
            nextVC.userAccountChanged = { [weak self](user) in
                if let vc = self {
                    vc.activeAccount = user
                }
            }
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
        
        dismiss(animated: true) { () in
            if let presentingVC = self.parent?.transitioningDelegate as? HalfModalTransitioningDelegate,
                let micropubVC = presentingVC.viewController as? MicropubShareViewController {
                micropubVC.extensionContext!.cancelRequest(withError: NSError(domain: "pub.abode.indigenous", code: 1))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        activeAccount = defaults?.integer(forKey: "defaultAccount") ?? 0
        
        self.clearsSelectionOnViewWillAppear = false
    
        let itemProvider = extensionItems?.first?.attachments?.first as! NSItemProvider
        let propertyList = String(kUTTypePropertyList)
        let plainText = String(kUTTypePlainText)
        let urlAttachment = String(kUTTypeURL)
        
        DispatchQueue.global(qos: .background).async {
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
    //            print(extensionItems?.first?.attachments)
            }
        }
    }
    
    private func shareUrl(url: URLComponents) {
        sharingType = "url"
        sharingContent = url
        if let parsingUrl = url.url {
            XRay.parse(url: parsingUrl) { parsedData, error in
                print("Done Parsing!")
                if error != nil {
                    print("Error")
                    print(error ?? "")
                }
                if let post = parsedData?.data {
                    self.updateOptions(forPost: post)
                }
            }
        }
    }
    
    private func updateOptions(forPost post: Jf2Post) {
        
        micropubActions = []
        
        switch post.type {
            case .event:
                micropubActions.append(MicropubTypes.rsvp)
                micropubActions.append(MicropubTypes.like)
                micropubActions.append(MicropubTypes.repost)
                micropubActions.append(MicropubTypes.bookmark)
            case .entry:
                micropubActions.append(MicropubTypes.like)
                micropubActions.append(MicropubTypes.repost)
                micropubActions.append(MicropubTypes.bookmark)
                if currentAccount?.me.absoluteString == "https://eddiehinkle.com/" {
                    micropubActions.append(MicropubTypes.listen)
                    micropubActions.append(MicropubTypes.watch)
                    micropubActions.append(MicropubTypes.read)
                }
            case .card:
                micropubActions.append(MicropubTypes.poke)
                micropubActions.append(MicropubTypes.bookmark)
        case .cite:
                print("Cite not supported")
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        micropubActions = [MicropubTypes.like, MicropubTypes.repost, MicropubTypes.bookmark]
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            
                currentAccount = micropubDetails
        
                if (currentAccount?.me.absoluteString == "https://eddiehinkle.com/") {
                    micropubActions.append(MicropubTypes.listen)
                }
            
                if (animated && shouldAnimateIn) {
                    self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
                
                    UIView.animate(withDuration: 0.20, animations: { () -> Void in
                        self.view.transform = .identity
                    })
                    
                    shouldAnimateIn = false
                }
        }
        
        tableView.reloadData()
        
    }
    


//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//        print("Outpuing Content")
//        print(contentText)
//
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//    }

}
