//
//  AppDelegate.swift
//  IndiePass
//
//  Created by Eddie Hinkle on 4/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import AVKit
import CoreData

let AppGroup = "group.app.indiepass"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "IndiePass")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        // Configure Crashlytics for Crash Reporting
        Fabric.with([Crashlytics.self])
        
        // Configure the theme
        ThemeManager.applyTheme(theme: ThemeManager.currentTheme(), window: window)
        
        // Loading CoreData
        dataController.load()
        
        // Set up background audio
        let session: AVAudioSession = AVAudioSession.sharedInstance();
        try? session.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.spokenAudio)
        
        // Check if has any user accounts
        let defaults = UserDefaults(suiteName: AppGroup)
        let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data] ?? [Data]()
        let loggedIn = micropubAccounts.count >= 1
        
        if loggedIn {
            // Add shortcut for creating a new post
            let shortcutItem = UIApplicationShortcutItem(type: ShortcutItemType.NewPost.rawValue, localizedTitle: "New Post")
            UIApplication.shared.shortcutItems = [shortcutItem]

            let appView = UIStoryboard(name: "Main", bundle: nil)
            if let appVC = appView.instantiateInitialViewController() as? MainViewController {
                appVC.dataController = dataController
                self.window?.rootViewController = appVC
                self.window?.makeKeyAndVisible()
            }
        } else {
            // We should empty the shortcut items
            UIApplication.shared.shortcutItems = []
            let onboardingView = UIStoryboard(name: "Onboarding", bundle: nil)

            if let onboardingVC = onboardingView.instantiateInitialViewController() as? OnboardingViewController {
                onboardingVC.dataController = dataController
                self.window?.rootViewController = onboardingVC
                self.window?.makeKeyAndVisible()
            }
        }
        
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == "app.indiepass.viewTimeline" {
            if let appVC = self.window?.rootViewController as? MainViewController,
               let channelsVC = appVC.viewControllers[0] as? ChannelViewController,
               let channelName = userActivity.userInfo?["name"] as? String,
               let channelId = userActivity.userInfo?["id"] as? String {
               
                    let channel = Channel(uniqueId: channelId, withName: channelName)
                
                    let timelineStoryboard = UIStoryboard(name: "Timeline", bundle: nil)
                    if let timelineVC = timelineStoryboard.instantiateInitialViewController() as? TimelineViewController {
                    
                        timelineVC.uid = channel.uid
                        timelineVC.dataController = dataController
                        timelineVC.title = channel.name
  
                        appVC.setViewControllers([channelsVC, timelineVC], animated: false)
                }
            }
            return true
        }
        
        return false
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
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


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
