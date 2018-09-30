//
//  TimelineViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//
import UIKit
import Social
import MobileCoreServices
import SafariServices
import CoreData

class TimelineViewController: UITableViewController, UITableViewDataSourcePrefetching,
                                                     PostingViewDelegate,
                                                     UINavigationControllerDelegate,
                                                     ChannelSettingsDelegate,
                                                     TimelineCellDelegate {
    
    var channelSettingsTransitioningDelegate: HalfModalTransitioningDelegate?
    let impactFeedback = UIImpactFeedbackGenerator()
    
//    var channel: Channel? = nil
    var uid: String!
    var channelData: ChannelData? = nil
    var timeline: Timeline? = nil
    var account: IndieAuthAccount? = nil
    var fetchingOlderData: Bool = false
    var fetchingNewerData: Bool = false
    var previousDataAvailable: Bool = true
    var mediaTimeTracking: [Int: String] = [:]
    var context: NSManagedObjectContext? = nil
    private var isTransitioning: Bool = true
    private var selectedRowIndex: Int? = nil
    private var thereIsCellTapped: Bool = false
    
    @IBOutlet weak var channelSettingsButton: UIBarButtonItem!
    
    var dataController: DataController!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Only mark as read if auto read is set AND we are not transitioning to a new view controller
        if let autoReadOn = self.channelData?.autoRead, autoReadOn, !isTransitioning {
            if let post = self.timeline?.posts[indexPath.row], let postId = post.id, let postIsRead = post.isRead, !postIsRead {
                // Mark cell as read
                post.isRead = true

                // Send read to server
                timeline?.markAsRead(posts: [postId]) { error in
                    if error != nil {
                        post.isRead = false

                        // TODO: Present error?
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return timeline?.posts.count ?? 0
        } else {
            return 1
        }
    }
    
    @IBAction func handleRefresh(_ sender: UIRefreshControl) {
        if !fetchingNewerData {
            fetchingNewerData = true
            
            timeline?.getNextTimeline { error, newPosts in
                
                guard error == nil else {
                    print("Error while fetching timeline")
                    print(error ?? "")
                    self.fetchingNewerData = false
                    DispatchQueue.main.async {
                        sender.endRefreshing()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if let newPostsCount = newPosts?.count {
//                        let beforeContentSize = self.tableView.contentSize
                        
                        let indexPaths = (0..<newPostsCount).map { IndexPath(row: $0, section: 0) }
                        self.tableView.insertRows(at: indexPaths, with: .automatic)
                        
                        // This code is a failed attempt at keeping the TableView's position static while adding entries to the top so you can continue scrolling
//                        let afterContentSize = self.tableView.contentSize
//                        let afterContentOffset = self.tableView.contentOffset
//                        let newContentOffset = CGPoint(x: afterContentOffset.x, y: afterContentOffset.y + afterContentSize.height - beforeContentSize.height)
//                        print("Before offset: \(self.tableView.contentOffset), After offset: \(newContentOffset)")
//                        self.tableView.setContentOffset(newContentOffset, animated: false)
//                        print("Offset should be after: \(self.tableView.contentOffset)")
//                        self.view.layoutIfNeeded()
                    }
                    self.fetchingNewerData = false
                    sender.endRefreshing()
                }
            }
        } else {
            sender.endRefreshing()
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Estimate height based on if a photo exists
        let post = timeline!.posts[indexPath.row]
        var cellHeight: CGFloat = 160
        
        if let photoCount = post.photo?.count, photoCount > 0 {
            cellHeight += 200
        }
        
        return cellHeight
    }
    
    // TODO: I'd love to get this autoscrolling load to work, but right now it makes you lose your position
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let contentHeight = scrollView.contentSize.height
//        let actualPosition = scrollView.contentOffset.y
//        let refreshBoundary = scrollView.contentSize.height - (tableView.frame.size.height * 2);
//
//        if !fetchingOlderData, contentHeight > 0, actualPosition > 0 {
////            let refreshBoundary = scrollView.contentSize.height - tableView.frame.size.height;
//
//            if (actualPosition >= refreshBoundary) {
//                fetchingOlderData = true
//                timeline?.getPreviousTimeline { error, newPosts in
//                    guard error == nil else {
//                        print("Error while fetching previous timeline")
//                        print(error)
//                        return
//                    }
//
//                    DispatchQueue.main.async {
//                        if let allPostsCount = self.timeline?.posts.count, let newPostsCount = newPosts?.count {
//                            let indexPaths = (allPostsCount - newPostsCount ..< allPostsCount).map { IndexPath(row: $0, section: 0) }
//                            self.tableView.insertRows(at: indexPaths, with: .none)
//                        }
//                        self.fetchingOlderData = false
//                    }
//                }
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if indexPath.section == 0 {
                let post = timeline!.posts[indexPath.row]
                if post.photo != nil, post.photo!.count > 0 {
                    post.downloadPhoto(photoIndex: 0)
                }
                if post.author?.photo != nil, post.author!.photo!.count > 0 {
                    post.author?.downloadPhoto(photoIndex: 0)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let post = self.timeline!.posts[indexPath.row]
        
        guard post.url != nil else {
            return UISwipeActionsConfiguration(actions: [])
        }
        
        let replyAction = UIContextualAction(style: .normal, title:  "Reply", handler: { [weak self] (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in

            if let fragmentTime = self?.mediaTimeTracking[indexPath.row] {
                if post.url != nil {
                    print("#t=\(fragmentTime)")
                    var urlComponent = URLComponents(url: post.url!, resolvingAgainstBaseURL: false)
                    urlComponent?.fragment = "t=\(fragmentTime)"
                    print("Full URL: \(String(describing: urlComponent?.string))")
                    post.url = urlComponent?.url
                }
            }
            
            if post.isRead != nil, let postId = post.id {
                post.isRead = true
                DispatchQueue.main.async {
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.timeline?.markAsRead(posts: [postId]) { error in
                        if error != nil {
                            print("Error Marking post as read \(error ?? "")")
                        }
                    }
                }
            }
            
            self?.isTransitioning = true
            self?.performSegue(withIdentifier: "showReplyView", sender: post)
            success(true)
        })
        
        replyAction.image = UIImage.fontAwesomeIcon(name: .reply, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        replyAction.backgroundColor = ThemeManager.currentTheme().deepColor

        return UISwipeActionsConfiguration(actions: [replyAction])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let post = self.timeline!.posts[indexPath.row]
        
            guard post.url != nil else {
                return UISwipeActionsConfiguration(actions: [])
            }
            
            let viewAction = UIContextualAction(style: .normal, title:  "View", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                
                self.isTransitioning = true
                self.performSegue(withIdentifier: "showFullArticle", sender: post)
                if post.isRead != nil, let postId = post.id {
                    post.isRead = true
                    DispatchQueue.global(qos: .background).async { [weak self] in
                        self?.timeline?.markAsRead(posts: [postId]) { error in
                            if error != nil {
                                print("Error Marking post as read \(error ?? "")")
                            }
                        }
                    }
                }

                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }

                success(true)
            })
            viewAction.image = UIImage.fontAwesomeIcon(name: .alignLeft, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
            viewAction.backgroundColor = ThemeManager.currentTheme().deepColor
            
//            let shareAction = UIContextualAction(style: .normal, title:  "Share", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//
//                if let postUrl = post.url {
//                    let shareVC = UIActivityViewController(activityItems: [postUrl], applicationActivities: nil)
//                    shareVC.popoverPresentationController?.sourceView = self.view
//                    self.present(shareVC, animated: true, completion: nil)
//                    success(true)
//                } else {
//                    success(false)
//                }
//            })
//
//            shareAction.image = UIImage(named: "tick")
//            shareAction.backgroundColor = #colorLiteral(red: 0.8063602448, green: 0.371145457, blue: 0.3616603613, alpha: 1)
        
            return UISwipeActionsConfiguration(actions: [viewAction])
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadMoreTimelineCell", for: indexPath)
            cell.textLabel?.text = previousDataAvailable ? "Load More Posts" : "No More Posts"
            return cell
        }
        
        let post = timeline!.posts[indexPath.row]
        
//        if let photoCount = post.photo?.count, photoCount > 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTimelineCell", for: indexPath) as! TimelinePhotoTableViewCell
        cell.account = self.account
        cell.delegate = self
        cell.setContent(ofPost: post)
        cell.mediaControlCallback = { [weak self] currentTime in
            if let time = currentTime {
                self?.mediaTimeTracking[indexPath.row] = String(describing: time)
            } else {
                self?.mediaTimeTracking.removeValue(forKey: indexPath.row)
            }
        }
        return cell
//        }
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "TextTimelineCell", for: indexPath) as! TimelineTextTableViewCell
//        cell.setContent(ofPost: post)
//        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            timeline?.getPreviousTimeline { error, newPosts in
                DispatchQueue.main.async {
                    guard error == nil else {
                        print("Error while fetching timeline")
                        print(error ?? "")
                        self.previousDataAvailable = false
                        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                        return
                    }
                    
                    if let allPostsCount = self.timeline?.posts.count, let newPostsCount = newPosts?.count {
                        let indexPaths = (allPostsCount - newPostsCount ..< allPostsCount).map { IndexPath(row: $0, section: 0) }
                        self.tableView.insertRows(at: indexPaths, with: .automatic)
                    }
                    self.fetchingOlderData = false
                }
            }
        }
        
        self.tableView.beginUpdates()
        
        // If there is a previous selected row index, we should hide the response bar
        if selectedRowIndex != nil, selectedRowIndex != -1 {
            if let previousTimelineCell = tableView.cellForRow(at: IndexPath(row: selectedRowIndex!, section: 0)) as? TimelinePhotoTableViewCell {
                previousTimelineCell.hideResponseBar()
            }
        }

        if selectedRowIndex != indexPath.row {
            // If a new cell is tapped, we need to track that and display the new response bar
            thereIsCellTapped = true
            selectedRowIndex = indexPath.row
            if let currentTimelineCell = tableView.cellForRow(at: indexPath) as? TimelinePhotoTableViewCell {
                currentTimelineCell.displayResponseBar()
                if let isRead = currentTimelineCell.post?.isRead, !isRead, let postId = currentTimelineCell.post?.id {
                    currentTimelineCell.displayAsRead()
                    timeline?.markAsRead(posts: [postId]) { _ in
                        // TODO: Handle errors
                    }
                }
            }
        }
        else {
            // there is no cell selected anymore, hide everything
            thereIsCellTapped = false
            selectedRowIndex = -1
        }
        
        self.tableView.endUpdates()
        
        
        //let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
//        let post = timeline[indexPath.row]
//
//        if let postUrl = post.url {
//            let safariVC = SFSafariViewController(url: postUrl)
//            present(safariVC, animated: true, completion: nil)
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isTransitioning = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isTransitioning = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isTransitioning = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelSettingsButton.image = UIImage.fontAwesomeIcon(name: .gear, textColor: UIColor.black, size: CGSize(width: 30, height: 30))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        context = dataController.persistentContainer.viewContext
        context?.automaticallyMergesChangesFromParent = true
        context?.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        context?.perform { [weak self] in
            if let context = self?.context, let uid = self?.uid, let channelData = try? ChannelData.findChannel(byId: uid, in: context) {
                self?.channelData = channelData
            
                let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
                let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
                if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
                    let account = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]),
                    let channelData = self?.channelData {
                 
                        print("about to load timeline")
                    
                        self?.account = account
                        self?.timeline = Timeline()
                        self?.timeline?.accountDetails = account
                        self?.timeline?.channel = Channel(fromData: channelData)
                        self?.timeline?.getTimeline { error, _ in
                            guard error == nil else {
                                print("Error while fetching main timeline")
                                print(error ?? "")
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }

                            if let postsCount = self?.timeline?.posts.count {
                                let totalRowsToPrefetch = postsCount < 9 ? postsCount : 8
                                for row in 0..<totalRowsToPrefetch {
                                    print("Prefetching for row \(row)")
                                    if let post = self?.timeline?.posts[row] {
                                        if post.photo != nil, post.photo!.count > 0 {
                                            post.downloadPhoto(photoIndex: 0)
                                        }
                                        if post.author?.photo != nil, post.author!.photo!.count > 0 {
                                            post.author?.downloadPhoto(photoIndex: 0)
                                        }
                                    }
                                }
                            }

                        }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController: UIViewController? = segue.destination
        if let navigationController = destinationViewController as? UINavigationController {
            destinationViewController = navigationController.visibleViewController
        }
        
        if segue.identifier == "showReplyView" {
            if let postingVC = destinationViewController as? PostingViewController {
                postingVC.currentPost = MicropubPost(type: .entry,
                                                     properties: MicropubPostProperties())
                
                if let replyPost = sender as? Jf2Post {
                    postingVC.currentPost?.properties.inReplyTo = replyPost.url?.absoluteString
                }
                
                postingVC.displayAsModal = false
                postingVC.delegate = self
                postingVC.title = "New Reply"
            }
        }
        
        if segue.identifier == "showChannelSettings" {
            self.channelSettingsTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.channelSettingsTransitioningDelegate
            
            if let channelSettingsNavVC = segue.destination as? ChannelSettingsNavigationController {
                channelSettingsNavVC.delegate = self
                if let channelSettingsVC = channelSettingsNavVC.viewControllers[0] as? ChannelSettingsViewController {
                    channelSettingsVC.dataController = dataController
                    channelSettingsVC.delegate = self
                    channelSettingsVC.title = "\(channelData?.name ?? "Channel") Settings"
                    channelSettingsVC.uid = channelData?.uid
                }
            }
        }
        
        if segue.identifier == "showFullArticle" {
            if let fullViewVC = destinationViewController as? FullArticleViewController {
                
                if let fullPost = sender as? Jf2Post {
                    fullViewVC.currentPost = fullPost
                    fullViewVC.timeline = timeline
                }
                
//                postingVC.displayAsModal = false
//                postingVC.delegate = self
            }
        }
    }
    
    func removePostingView() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - TimelineCellDelegate Methods
    func shareUrl(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true) { [weak self] in
            self?.impactFeedback.impactOccurred()
        }
    }
    
    func replyToUrl(url: URL) {
        let replyToPost = Jf2Post()
        replyToPost.url = url
        performSegue(withIdentifier: "showReplyView", sender: replyToPost)
    }
    
    func moreOptions(post: Jf2Post, sourceButton: UIBarButtonItem) {
        if let postId = post.id, let url = post.url, account != nil {
            let alert = UIAlertController(title: "More Options", message: "\(url)", preferredStyle: .actionSheet)
            if let popoverController = alert.popoverPresentationController {
                popoverController.barButtonItem = sourceButton
            }
            
            if post.isRead != nil {
                if post.isRead! {
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
            self.present(alert, animated: true) { [weak self] in
                self?.impactFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - ChannelSettingsDelegate Methods
    func markAllPostsAsRead() {
        timeline?.markAllPostsAsRead { [weak self] error in
            if error != nil {
                print("ERROR MARKING AS READ")
                return
            }

            if let posts = self?.timeline?.posts {
                for post in posts {
                    post.isRead = true
                }

                DispatchQueue.main.async {
                    if let visibleRows = self?.tableView.indexPathsForVisibleRows {
                        self?.tableView.reloadRows(at: visibleRows, with: .none)
                    }
                }
            }
        }
    }
    
}

