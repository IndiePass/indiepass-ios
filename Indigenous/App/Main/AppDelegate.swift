//
//  AppDelegate.swift
//  Indigenous
//
//  Created by Eddie Hinkle on 4/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import AVKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "Indigenous")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        UINavigationBar.appearance().shadowImage = UIImage()
        
        dataController.load()
        
        let mainVC = window?.rootViewController as! MainViewController
        mainVC.dataController = dataController
        
        let session: AVAudioSession = AVAudioSession.sharedInstance();
        try? session.setCategory(AVAudioSessionCategoryPlayback)
        
        return true
    }
    
    func applicationHandleRemoteNotification(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject])
    {
        
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        if let itemType = ShortcutItemType(rawValue: shortcutItem.type) {
        
            switch itemType {
            case .NewPost:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "createNewPost"), object: self)
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print("Attempting URL Call in App Delegate")
        
//        let urlToOpen = URLComponents(url: url.absoluteURL, resolvingAgainstBaseURL: false)
//
//        if urlToOpen?.host == "auth" && urlToOpen?.path == "/callback" {
//            print("ABOUT TO CALL INDIE AUTH PROCESS")
//            if let indieAuthLoginVC = self.window?.rootViewController?.presentedViewController as? IndieAuthLoginViewController {
//
//            }
//        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        dataController.saveContext()
    }

}

