//
//  ChannelData.swift
//  IndiePass
//
//  Created by Edward Hinkle on 5/10/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit
import CoreData

class ChannelData: NSManagedObject {

    class func findChannel(byId uid: String, in context: NSManagedObjectContext) throws -> ChannelData? {
        let request: NSFetchRequest<ChannelData> = ChannelData.fetchRequest()
        request.predicate = NSPredicate(format: "uid = %@", uid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ChannelData.findChannelById -- database inconsistancy")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return nil
    }
    
    class func findOrCreateChannel(matching channelInfo: Channel, in context: NSManagedObjectContext) throws -> ChannelData {
        let request: NSFetchRequest<ChannelData> = ChannelData.fetchRequest()
        request.predicate = NSPredicate(format: "uid = %@", channelInfo.uid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ChannelData.findOrCreateChannel -- database inconsistancy")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let channelData = ChannelData(context: context)
        channelData.uid = channelInfo.uid
        channelData.name = channelInfo.name
        channelData.unreadStatus = channelInfo.unread.readIdentifier
        channelData.unreadCount = Int32(exactly: channelInfo.unread.unreadCount) ?? 0
        return channelData
    }
    
    class func updateOrCreateChannel(matching channelInfo: Channel, in context: NSManagedObjectContext) throws -> ChannelData {
        let request: NSFetchRequest<ChannelData> = ChannelData.fetchRequest()
        request.predicate = NSPredicate(format: "uid = %@", channelInfo.uid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ChannelData.findOrCreateChannel -- database inconsistancy")
                let channelData = matches[0]
                channelData.name = channelInfo.name
                channelData.unreadStatus = channelInfo.unread.readIdentifier
                channelData.unreadCount = Int32(exactly: channelInfo.unread.unreadCount) ?? 0
                return channelData
            }
        } catch {
            throw error
        }
        
        let channelData = ChannelData(context: context)
        channelData.uid = channelInfo.uid
        channelData.name = channelInfo.name
        channelData.unreadStatus = channelInfo.unread.readIdentifier
        channelData.unreadCount = Int32(exactly: channelInfo.unread.unreadCount) ?? 0
        return channelData
    }
    
    class func updateOrCreateChannel(matching channelInfo: Channel, withPosition position: Int, in context: NSManagedObjectContext) throws -> ChannelData {
        let request: NSFetchRequest<ChannelData> = ChannelData.fetchRequest()
        request.predicate = NSPredicate(format: "uid = %@", channelInfo.uid)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "ChannelData.updateOrCreateChannel -- database inconsistancy")
                let channelData = matches[0]
                channelData.name = channelInfo.name
                channelData.unreadStatus = channelInfo.unread.readIdentifier
                channelData.unreadCount = Int32(exactly: channelInfo.unread.unreadCount) ?? 0
                channelData.sort = Int32(position)
                return channelData
            }
        } catch {
            throw error
        }
        
        let channelData = ChannelData(context: context)
        channelData.uid = channelInfo.uid
        channelData.name = channelInfo.name
        channelData.unreadStatus = channelInfo.unread.readIdentifier
        channelData.unreadCount = Int32(exactly: channelInfo.unread.unreadCount) ?? 0
        channelData.sort = Int32(position)
        return channelData
    }
    
}
