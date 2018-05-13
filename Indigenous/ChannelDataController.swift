//
//  ChannelDataController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 5/10/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation
import CoreData

class ChannelDataController {
    
    var container: NSPersistentContainer!
    var fetchedResultsController: NSFetchedResultsController<ChannelData>?
    var activeFilter: ChannelListFilter?
    var activeSorting: ChannelListSort?
    
    func getChannels() -> [Channel] {
        return []
    }
    
    public func updateChannels(withFilter filter: ChannelListFilter, callback: (() -> ())) {
        activeFilter = filter
        updateChannels {
            callback()
        }
    }
    
    public func updateChannels(sortBy sort: ChannelListSort, callback: (() -> ())) {
        activeSorting = sort
        updateChannels {
            callback()
        }
    }
    
    public func updateChannels(withFilter filter: ChannelListFilter, sortBy sort: ChannelListSort, callback: (() -> ())) {
        activeFilter = filter
        activeSorting = sort
        updateChannels {
            callback()
        }
    }
    
    public func updateChannels(callback: (() -> ())) {
        if let context = container?.viewContext {
            let request: NSFetchRequest<ChannelData> = ChannelData.fetchRequest()
            
            if let sortingType = activeSorting {
                switch sortingType {
                case .Alphabetical:
                    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                case .UnreadCount:
                    request.sortDescriptors = [NSSortDescriptor(key: "unreadCount", ascending: false)]
                case .Manual:
                    request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
                }
            } else {
                request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
            }
            
            if let filteringType = activeFilter {
                switch filteringType {
                case .UnreadOnly:
                    request.predicate = NSPredicate(format: "any unreadCount > 0")
                case .Search(let searchText):
                    request.predicate = NSPredicate(format: "any name contains[c] %@", searchText)
                case .None:
                    request.predicate = NSPredicate(format: "TRUEPREDICATE")
                }
            } else {
                request.predicate = NSPredicate(format: "TRUEPREDICATE")
            }
            
            fetchedResultsController = NSFetchedResultsController<ChannelData>(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            try? fetchedResultsController?.performFetch()
            callback()
        } else {
            callback()
        }
    }
    
    func filterChannels(forSearchText searchText: String) {
//        searchChannels = channels.filter { channel in
//            if searchText.isEmpty {
//                return true
//            }
//            return channel.name.lowercased().contains(searchText.lowercased())
//        }
//        
//        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func getChannelData(callback: (() -> ())? = nil) {}
    
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
                                
                                self?.container.performBackgroundTask { context in
                                    var channelIndex = 0
                                    channelResponse.channels.forEach { channelInfo in
                                        _ = try? ChannelData.updateOrCreateChannel(
                                            matching: channelInfo,
                                            withPosition: channelIndex,
                                            in: context
                                        )
                                        channelIndex += 1
                                    }
                                    // TODO: Should probably check for errors here and do something
                                    try? context.save()
                                    self?.printDebugStats()
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
    
    func printDebugStats() {
//        if let context = container?.viewContext {
//            context.perform {
//                if let channelCount = try? context.count(for: ChannelData.fetchRequest()) {
//                    print("\(channelCount) Channels")
//                }
//            }
//        }
    }
}
