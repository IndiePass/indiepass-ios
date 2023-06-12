//
//  ChannelDataController.swift
//  IndiePass
//
//  Created by Edward Hinkle on 5/10/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import Foundation
import CoreData

class ChannelDataController {
    
    var container: NSPersistentContainer!
    
    func saveContext() {
        let context = container.viewContext
        context.perform {
            try? context.save()
        }
    }
    
    func getChannel(byId uid: String, callback: @escaping ((ChannelData?) -> ())) {
        container.performBackgroundTask { context in
            if let channelData = try? ChannelData.findChannel(byId: uid, in: context) {
                callback(channelData)
            } else {
                callback(nil)
            }
        }
    }
    
    func getChannels() -> [Channel] {
        return []
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
    
    
    
    func printDebugStats() {
        if let context = container?.viewContext {
            context.perform {
                if let channelCount = try? context.count(for: ChannelData.fetchRequest()) {
                    print("\(channelCount) Channels")
                }
            }
        }
    }
}
