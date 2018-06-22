//
//  ChannelSettingsViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 5/20/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit
import CoreData

class ChannelSettingsViewController: UIViewController, HalfModalPresentable {
    
    public var uid: String!
    var dataController: DataController!
    var context: NSManagedObjectContext? = nil
    var delegate: ChannelSettingsDelegate? = nil
    
    private var channelData: ChannelData? = nil
    
    @IBOutlet weak var autoReadSwitch: UISwitch!
    @IBOutlet weak var markAllPostsButton: UIButton!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    @IBAction func switchAutoRead(_ sender: UISwitch) {
        channelData?.autoRead = sender.isOn
        // TODO: Need to track failure to save and present error
        try? context?.save()
    }
    
    @IBAction func markAllPosts(_ sender: UIButton) {
        delegate?.markAllPostsAsRead()
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateMarkAllPostsButtonText() {
        if let int32Count = channelData?.unreadCount {
            if let unreadCount = Int(exactly: int32Count) {
                if unreadCount > 0 {
                    markAllPostsButton.setTitle("Mark All Posts Read", for: .normal)
                }
            }
        } else {
            markAllPostsButton.setTitle("Mark All Posts Unread", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = ThemeManager.currentTheme().backgroundColor
        
        closeButton.image = UIImage.fontAwesomeIcon(name: .times, textColor: UIColor.black, size: CGSize(width: 30, height: 30))

        context = dataController.persistentContainer.viewContext
        context?.automaticallyMergesChangesFromParent = true
        context?.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        context?.perform { [weak self] in
            if let context = self?.context, let uid = self?.uid, let channelData = try? ChannelData.findChannel(byId: uid, in: context) {
                self?.channelData = channelData
                if let autoReadOn = self?.channelData?.autoRead {
                    self?.autoReadSwitch.isOn = autoReadOn
                    self?.updateMarkAllPostsButtonText()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
