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

class TimelineViewController: UITableViewController, UITableViewDataSourcePrefetching, PostingViewDelegate {
    
    var channel: Channel? = nil
    var timeline: [Jf2Post] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeline.count
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let post = timeline[indexPath.row]
            if post.photo != nil, post.photo!.count > 0 {
                post.downloadPhoto(photoIndex: 0)
            }
            if post.author?.photo != nil, post.author!.photo!.count > 0 {
                post.author?.downloadPhoto(photoIndex: 0)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let replyAction = UIContextualAction(style: .normal, title:  "Reply", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            let post = self.timeline[indexPath.row]
            
            self.performSegue(withIdentifier: "showReplyView", sender: post)
            success(true)
        })
        
        replyAction.image = UIImage(named: "tick")
        replyAction.backgroundColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)

        return UISwipeActionsConfiguration(actions: [replyAction])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let viewAction = UIContextualAction(style: .normal, title:  "View", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            
            let post = self.timeline[indexPath.row]
            
            if let postUrl = post.url {
                let safariVC = SFSafariViewController(url: postUrl)
                self.present(safariVC, animated: true)
                success(true)
            } else {
                success(false)
            }
        })
        viewAction.image = UIImage(named: "tick")
        viewAction.backgroundColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [viewAction])
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTimelineCell", for: indexPath) as? TimelineTableViewCell {
            
            let post = timeline[indexPath.row]
            cell.setContent(ofPost: post)
            return cell
            
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineCell", for: indexPath)
        let post = timeline[indexPath.row]
        cell.textLabel?.text = post.name ?? post.content?.text ?? post.summary ?? "Content Can't Display"
        var subtitle = post.author?.name ?? "Unknown"
        if let publishedDate = post.published {
//            let publishedDate = ISO8601DateFormatter().date(from: dateString) {
            
            if Calendar.current.isDateInToday(publishedDate) {
                subtitle += " Today at " + DateFormatter.localizedString(from: publishedDate, dateStyle: .none, timeStyle: .short)
            } else {
                subtitle += " " + DateFormatter.localizedString(from: publishedDate, dateStyle: .medium, timeStyle: .short)
            }
        }
        cell.detailTextLabel?.text = subtitle
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
//        let post = timeline[indexPath.row]
//
//        if let postUrl = post.url {
//            let safariVC = SFSafariViewController(url: postUrl)
//            present(safariVC, animated: true, completion: nil)
//        }
    }
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
//        getChannelData {
//            DispatchQueue.main.async {
//                refreshControl.endRefreshing()
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
//        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
//        getChannelData()
        
        getSingleChannelData(channel: self.channel!) {
            let totalRowsToPrefetch = self.timeline.count < 9 ? self.timeline.count : 8
            for row in 0..<totalRowsToPrefetch {
                print("Prefetching for row \(row)")
                let post = self.timeline[row]
                if post.photo != nil, post.photo!.count > 0 {
                    post.downloadPhoto(photoIndex: 0)
                }
                if post.author?.photo != nil, post.author!.photo!.count > 0 {
                    post.author?.downloadPhoto(photoIndex: 0)
                }
            }
        }
    }
    
    func getSingleChannelData(channel: Channel, callback: (() -> ())? = nil) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        let activeAccount = defaults?.integer(forKey: "activeAccount") ?? 0
        if let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
        
                guard let microsubEndpoint = micropubDetails.microsub_endpoint else {
                    print("microsubEndpoint failure")
                    return
                }
            
                guard var microsubUrl = URLComponents(url: microsubEndpoint, resolvingAgainstBaseURL: false) else {
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
                                    let timelineResponse = try! JSONDecoder().decode(TimelineApiResponse.self, from: body.data(using: .utf8)!)
                                    
                                    self.timeline = timelineResponse.items
                                    
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
    }
    
    func removePostingView() {
        navigationController?.popViewController(animated: true)
    }
    
}

