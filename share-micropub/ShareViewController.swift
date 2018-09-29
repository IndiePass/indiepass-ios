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

class ShareViewController: UITableViewController, HalfModalPresentable, PostingViewDelegate {
    
//    var micropubAuth: [String: Any]? = nil
    var sharingType: String? = nil
    var sharingContent: URLComponents? = nil
    var extensionItems: [NSExtensionItem]? = nil
    var micropubActions: [MicropubResponseType] = []
    var currentAccount: IndieAuthAccount? = nil
    var activeAccount: Int = 0
    var shouldAnimateIn: Bool = true
    var replyContext: Jf2Post? = nil
    
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
                            let alert = UIAlertController(title: "Oops", message: "This action isn't built yet", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController: UIViewController? = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController
        }
        
        if segue.identifier == "showReplyView" {
            if let postingVC = destinationViewController as? PostingViewController {
                postingVC.currentPost = MicropubPost(type: .entry,
                                                     properties: MicropubPostProperties())
                postingVC.currentPost?.properties.inReplyTo = sharingContent?.string
                if replyContext != nil {
                    postingVC.replyContext = replyContext
                }
                postingVC.displayAsModal = false
                postingVC.delegate = self
                postingVC.title = "New Reply"
                self.maximizeToFullScreen()
            }
        }
        
        if segue.identifier == "showAccountSelection",
            let nextVC = destinationViewController as? AccountSelectorTableViewController {
            nextVC.activeUserAccount = activeAccount
            nextVC.userAccountChanged = { [weak self](user) in
                if let vc = self {
                    vc.activeAccount = user
                }
            }
        }
    }
    
    func removePostingView() {
        navigationController?.popViewController(animated: true)
    }
    
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
        
        replyContext = post
        
        if let postType = post.type {
            micropubActions = []
            
            switch postType {
            case .event:
                micropubActions.append(.rsvp)
                micropubActions.append(.like)
                micropubActions.append(.repost)
                micropubActions.append(.bookmark)
                micropubActions.append(.reply)
            case .card:
                micropubActions.append(.bookmark)
            case .cite:
                print("Cite not supported")
                micropubActions.append(.like)
                micropubActions.append(.bookmark)
            case .feed:
                print("Feed not supported yet")
                micropubActions.append(.like)
                micropubActions.append(.bookmark)
            case .entry:
                micropubActions.append(.reply)
                micropubActions.append(.like)
                micropubActions.append(.repost)
                micropubActions.append(.bookmark)
                if currentAccount?.me.absoluteString == "https://eddiehinkle.com/" {
                    micropubActions.append(.listen)
                    micropubActions.append(.watch)
                    micropubActions.append(.read)
                }
            case .review, .app, .item, .product:
                micropubActions.append(.reply)
                micropubActions.append(.like)
                micropubActions.append(.repost)
                micropubActions.append(.bookmark)
            case .recipe:
                micropubActions.append(.reply)
                micropubActions.append(.like)
                micropubActions.append(.repost)
                micropubActions.append(.bookmark)
            case .repo:
                micropubActions.append(.reply)
                micropubActions.append(.like)
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isHalfModalFullscreen() {
            self.reduceToHalfScreen()
        }
        
        micropubActions = [.reply, .like, .repost, .bookmark]
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
            
                currentAccount = micropubDetails
        
                if (currentAccount?.me.absoluteString == "https://eddiehinkle.com/") {
                    micropubActions.append(.listen)
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
