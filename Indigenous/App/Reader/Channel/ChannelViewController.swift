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
import CoreData

public enum ChannelListFilter {
    case None
    case UnreadOnly
    case Search(searchText: String)
    
    var value: String {
        switch self {
        case .None:
            return "none"
        case .UnreadOnly:
            return "unread"
        case .Search(let searchText):
            return searchText
        }
    }
    
    static func fromValue(value: String) -> ChannelListFilter {
        switch value {
        case "none":
            return .None
        case "unread":
            return .UnreadOnly
        default:
            return .Search(searchText: value)
        }
    }
}

public enum ChannelListSort: String {
    case Alphabetical
    case UnreadCount
    case Manual
}

class ChannelViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, NSFetchedResultsControllerDelegate {
    
    var channels: [Channel] = []
    var cachedChannels: [Channel] = []
    var filteredChannels: [Channel] = []
    var searchChannels: [Channel] = []
    var selectedChannel: Channel? = nil
    var timelines: [[Jf2Post]] = []
    var commands: [Command] = []
    var searchController: UISearchController? = nil
    
    var standardFiltering: ChannelListFilter = .None
    var currentFiltering: ChannelListFilter = .None
    var currentSorting: ChannelListSort = .Manual
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<ChannelData>!
    
    var currentAccount: IndieAuthAccount? = nil
    
//    @IBOutlet weak var notificationButton: UIBarButtonItem!
    @IBOutlet weak var accountButton: UIBarButtonItem!
    
    func updateFilteringAndSorting() {
        updateChannels { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
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
                request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
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
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        fetchChannelData {
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            searchController.searchBar.showsBookmarkButton = false
        } else {
            searchController.searchBar.showsBookmarkButton = true
        }
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            UserDefaults(suiteName: "group.software.studioh.indigenous")?.set(ChannelListFilter.Search(searchText: searchText).value, forKey: "ChannelFilter")
            currentFiltering = .Search(searchText: searchText)
        } else {
            UserDefaults(suiteName: "group.software.studioh.indigenous")?.set(standardFiltering.value, forKey: "ChannelFilter")
            currentFiltering = standardFiltering
        }
        updateFilteringAndSorting()
    }
    
    private func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController?.searchBar.text?.isEmpty ?? true
    }
    
    private func isSearching() -> Bool {
        return searchController?.isActive ?? false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        UserDefaults(suiteName: "group.software.studioh.indigenous")?.set(standardFiltering.value, forKey: "ChannelFilter")
        currentFiltering = standardFiltering
        updateFilteringAndSorting()
    }
    
    @objc func handleCreateNewPost() {
        performSegue(withIdentifier: "showPostingInterface", sender: nil)
    }
    
    public func updateChannels(callback: (() -> ())) {
        let request: NSFetchRequest<ChannelData> = ChannelData.fetchRequest()

        switch currentSorting {
        case .Alphabetical:
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        case .UnreadCount:
            request.sortDescriptors = [NSSortDescriptor(key: "unreadCount", ascending: false)]
        case .Manual:
            request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
        }
    
        switch currentFiltering {
        case .UnreadOnly:
            request.predicate = NSPredicate(format: "unreadCount > 0")
        case .Search(let searchText):
            request.predicate = NSPredicate(format: "name contains[c] %@", searchText)
        case .None:
            request.predicate = NSPredicate(format: "TRUEPREDICATE")
        }

        fetchedResultsController = NSFetchedResultsController<ChannelData>(
            fetchRequest: request,
            managedObjectContext: dataController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        try? fetchedResultsController?.performFetch()
        callback()
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        let alert = UIAlertController(title: "Filter", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Unread Only", style: .default, handler: { [weak self] action in
//            if let storedTheme = (UserDefaults(suiteName: "group.software.studioh.indigenous")?.value(forKey: SelectedThemeKey) as AnyObject).integerValue
            UserDefaults(suiteName: "group.software.studioh.indigenous")?.set(ChannelListFilter.UnreadOnly.value, forKey: "ChannelFilter")
            self?.currentFiltering = .UnreadOnly
            self?.standardFiltering = .UnreadOnly
            self?.updateFilteringAndSorting()
        }))
        alert.addAction(UIAlertAction(title: "All Channels", style: .default, handler: { [weak self] action in
            UserDefaults(suiteName: "group.software.studioh.indigenous")?.set(ChannelListFilter.None.value, forKey: "ChannelFilter")
            self?.currentFiltering = .None
            self?.standardFiltering = .None
            self?.updateFilteringAndSorting()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func fetchChannelData(callback: (() -> ())? = nil) {
        
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
            request.setValue(UAString(), forHTTPHeaderField: "User-Agent")
            request.setValue("Bearer \(micropubDetails.access_token)", forHTTPHeaderField: "Authorization")
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request) { [weak self] (data, response, error) in
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
                                
                                self?.dataController.persistentContainer.performBackgroundTask { backgroundContext in
                                        var channelIndex = 0
                                        channelResponse.channels.forEach { channelInfo in
                                            _ = try! ChannelData.updateOrCreateChannel(
                                                matching: channelInfo,
                                                withPosition: channelIndex,
                                                in: backgroundContext
                                            )
                                            channelIndex += 1
                                        }
                                        
                                        // TODO: Should probably check for errors here and do something
                                        try? backgroundContext.save()
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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewTimeline",
            let channelCell = sender as? ChannelTableViewCell,
            let nextVC = segue.destination as? TimelineViewController {
            nextVC.uid = channelCell.data?.uid
            nextVC.dataController = dataController
            nextVC.title = channelCell.data?.name
        }
    }
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleCreateNewPost),
                                               name: NSNotification.Name(rawValue: "createNewPost"),
                                               object: nil)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.placeholder = "Search Channels"
        searchController?.searchBar.delegate = self
        searchController?.searchBar.showsBookmarkButton = true
        searchController?.searchBar.setImage(UIImage.fontAwesomeIcon(name: .filter, textColor: ThemeManager.currentTheme().mainColor, size: CGSize(width: 30, height: 30)), for: .bookmark, state: .normal)
        searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        self.definesPresentationContext = true
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
            
            tableView.delegate = self
            tableView.dataSource = self
            self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
            
            if let savedFilter = UserDefaults(suiteName: "group.software.studioh.indigenous")?.string(forKey: "ChannelFilter") {
                currentFiltering = ChannelListFilter.fromValue(value: savedFilter)
            }
            
            // We'll want to fetch new data from the server for unread counts, etc
            fetchChannelData { [weak self] in
                self?.updateFilteringAndSorting()
            }
            
            if currentAccount?.me.absoluteString == "https://eddiehinkle.com/" {
                commands = [
                    Command(name: "Rebuild Site",
                            url: URL(string: "https://eddiehinkle.com/abode/rebuild/slack/")!,
                            body: ["token": "h0uOKoXJklurbaIY6AbqW9PZ"])
                ]
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: - Table View Delegate
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
        
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[0].numberOfObjects
        } else {
            return 0
        }
        
        //        if isSearching() {
        //            return searchChannels.count
        //        } else {
        //            return filteredChannels.count
        //        }
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
            //            let channelData: Channel
            //            if isSearching() {
            //                channelData = searchChannels[indexPath.row]
            //            } else {
            //                channelData = filteredChannels[indexPath.row]
            //            }
            if let channelData = fetchedResultsController?.object(at: indexPath) {
                channelCell.setContent(ofChannel: Channel(fromData: channelData))
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if currentAccount?.me.absoluteString == "https://eddiehinkle.com/", indexPath.section == 1 {
            let command = commands[indexPath.row]
            command.sendCommand()
            return
        } else {
            if let channelData = fetchedResultsController?.object(at: indexPath) {
                let selectedChannel = Channel(fromData: channelData)
                self.selectedChannel = selectedChannel
            }
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: tableView.insertSections([sectionIndex], with: .fade)
        case .delete: tableView.deleteSections([sectionIndex], with: .fade)
        default: break
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
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
