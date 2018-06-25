//
//  FullArticleViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 6/19/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit
import WebKit

class FullArticleViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate {

    var currentPost: Jf2Post? = nil
    var cachedStyleString: String = ""
    var timeline: Timeline!
    
    private var account: IndieAuthAccount? = nil
    
    @IBOutlet weak var contentView: WKWebView!
    @IBOutlet weak var safariButton: UIBarButtonItem!
    @IBOutlet weak var likeButton: UIBarButtonItem!
    @IBOutlet weak var repostButton: UIBarButtonItem!
    @IBOutlet weak var replyButton: UIBarButtonItem!
    @IBOutlet weak var moreButton: UIBarButtonItem!
    
    private func styleString() -> String {
        
        if cachedStyleString.isEmpty {
//            let path = Bundle.main.path(forResource: "LightStylesheet", ofType: "css")!
//            let s = try! String(contentsOfFile: path, encoding: .utf8)
//            cachedStyleString = "\n\(s)\n"
        }
        
        return cachedStyleString
    }
    
    // MARK: - IBAction Methods
    @IBAction func responseButtonPressed(_ sender: UIBarButtonItem) {
        switch sender.title {
        case "Like":
            if let url = currentPost?.url, account != nil {
                sendMicropub(forAction: .like, aboutUrl: url, forUser: account!) {
                    // TODO: Need to display an alert based on if it was successful or not
                }
            }
        case "Repost":
            if let url = currentPost?.url, account != nil {
                sendMicropub(forAction: .repost, aboutUrl: url, forUser: account!) {
                    // TODO: Need to display an alert based on if it was successful or not
                }
            }
        case "Reply":
            if let url = currentPost?.url, account != nil {
                performSegue(withIdentifier: "showReplyView", sender: currentPost)
            }
        case "Safari":
            if let url = currentPost?.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        default:
            if let url = currentPost?.url {
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                present(activityViewController, animated: true, completion: {})
            }
        }
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        if let postId = currentPost?.id, let url = currentPost?.url, account != nil {
            let alert = UIAlertController(title: "More Options", message: "\(url)", preferredStyle: .actionSheet)
            if let popoverController = alert.popoverPresentationController {
                popoverController.barButtonItem = moreButton
            }
            
            if let isRead = currentPost?.isRead {
                if isRead {
                    alert.addAction(UIAlertAction(title: "Mark as Unread", style: .default, handler: { [weak self] action in
                        self?.timeline?.markAsUnread(posts: [postId]) { response in
                            // TODO: Handle errors
                        }
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: "Mark as Read", style: .default, handler: { [weak self] action in
                        self?.timeline?.markAsRead(posts: [postId]) { response in
                            // TODO: Handle errors
                        }
                    }))
                }
            }
            alert.addAction(UIAlertAction(title: "Mark posts below as read", style: .default, handler: { [weak self] action in
                self?.timeline?.markAsRead(postsBefore: postId) { response in
                    // TODO: Handle errors
                }
            }))
            alert.addAction(UIAlertAction(title: "Delete post", style: .default, handler: { [weak self] action in
                self?.timeline?.removePost(postId: postId) { response in
                    // TODO: Handle errors
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if(velocity.y>0) {
            //Code will work without the animation block.I am using animation block incase if you want to set any delay to it.
            UIView.animate(withDuration: 2.5, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
            }, completion: nil)
            
        } else {
            UIView.animate(withDuration: 2.5, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.setToolbarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    // MARK: - WKNavigationDelegate Methods
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url,
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                print(url)
                print("Redirected to browser. No need to open it locally")
                decisionHandler(.cancel)
            } else {
                print("Open it locally")
                decisionHandler(.allow)
            }
        } else {
            print("not a user click")
            decisionHandler(.allow)
        }
    }
    
    // MARK: - LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeManager.currentTheme().backgroundColor
        navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = ""
        
        likeButton.image = UIImage.fontAwesomeIcon(name: .thumbsOUp, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        repostButton.image = UIImage.fontAwesomeIcon(name: .retweet, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        replyButton.image = UIImage.fontAwesomeIcon(name: .reply, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        moreButton.image = UIImage.fontAwesomeIcon(name: .ellipsisH, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        safariButton.image = UIImage.fontAwesomeIcon(name: .safari, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        
        contentView.isOpaque = true;
        contentView.backgroundColor = UIColor.clear
        contentView.scrollView.delegate = self
        contentView.navigationDelegate = self
        
        let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let headerSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
        
        var htmlBeforeString = "<html><head><meta name=\"viewport\" content=\"width=device-width, user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0\" /><style>"
        htmlBeforeString += "body { background-color: \(ThemeManager.currentTheme().backgroundColor.toHexString()); color: \(ThemeManager.currentTheme().textColor.toHexString()); font-size: calc(\(bodySize)px + 1.0vw); }"
        htmlBeforeString += "h1.post-title { font: -apple-system-headline; font-size: calc(\(headerSize)px + 1.0vw); color: \(ThemeManager.currentTheme().mainColor.toHexString()); margin-top: 0px; margin-bottom: 25px; }"
        htmlBeforeString += "h2, h3, h4, h5, h6, h7 { margin-top: 0; margin-bottom: 25px; }"
        htmlBeforeString += "img { max-width: 100%; margin-bottom: 10px; }"
        htmlBeforeString += "a { color: \(ThemeManager.currentTheme().mainColor.toHexString()); }"
        htmlBeforeString += "a:active { color: \(ThemeManager.currentTheme().deepColor.toHexString()); }"
        htmlBeforeString += "</style></head><body>"
        let htmlAfterString = "</body></html>"
        
        if let htmlContent = currentPost?.content?.html {
            
            var htmlString = ""
            if let postName = currentPost?.name {
                htmlString += "<h1 class='post-title'>\(postName)</h1>"
            }
            htmlString += "\(htmlBeforeString)\(htmlContent)\(htmlAfterString)"
            contentView.loadHTMLString(htmlString, baseURL: nil)
            
        } else if let textContent = currentPost?.content?.text {
            
            var htmlString = ""
            if let postName = currentPost?.name {
                htmlString += "<h1 class='post-title'>\(postName)</h1>"
            }
            htmlString += "\(htmlBeforeString)<p>\(textContent.replacingOccurrences(of: "\n", with: "<br>"))</p>\(htmlAfterString)"
            contentView.loadHTMLString(htmlString, baseURL: nil)
            
        }
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] {
            account = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount])
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
