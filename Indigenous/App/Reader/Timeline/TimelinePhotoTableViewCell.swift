//
//  TimelineTableViewCell.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/18/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class TimelinePhotoTableViewCell: UITableViewCell {

    var post: Jf2Post? = nil
    var account: IndieAuthAccount? = nil
    var player: AVPlayer? = nil
    var playerToken: Any? = nil
    var mediaControlCallback: ((_ currentTime: Int?) -> ())?
    var delegate: TimelineCellDelegate? = nil
    
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorPhoto: UIImageView!
    @IBOutlet weak var postContent: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postDate: UILabel!
    @IBOutlet weak var postTitle: UILabel!
    
    @IBOutlet weak var authorPhotoWidth: NSLayoutConstraint!
    @IBOutlet weak var authorPhotoHeight: NSLayoutConstraint!
    @IBOutlet weak var postImageHeight: NSLayoutConstraint!
    @IBOutlet weak var audioPlayerView: UIView!
    @IBOutlet weak var audioControl: UIButton!
    @IBOutlet weak var audioPlayerCurrentTime: UILabel!
    @IBOutlet weak var audioPlayerProgressBar: UIProgressView!
    @IBOutlet weak var audioPlayerHeight: NSLayoutConstraint!
    @IBOutlet weak var audioLoading: UIActivityIndicatorView!
    @IBOutlet weak var replyIcon: UILabel!
    
    @IBOutlet weak var likeButton: UIBarButtonItem!
    @IBOutlet weak var repostButton: UIBarButtonItem!
    @IBOutlet weak var replyButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var responseToolbar: UIToolbar!
    @IBOutlet weak var responseToolbarHeight: NSLayoutConstraint!
    
    @IBAction func responseButtonPressed(_ sender: UIBarButtonItem) {
        switch sender.title {
        case "Like":
            if let url = post?.url, account != nil {
                sendMicropub(forAction: .like, aboutUrl: url, forUser: account!) {
                    // TODO: Need to display an alert based on if it was successful or not
                }
            }
        case "Repost":
            if let url = post?.url, account != nil {
                sendMicropub(forAction: .repost, aboutUrl: url, forUser: account!) {
                    // TODO: Need to display an alert based on if it was successful or not
                }
            }
        case "Reply":
            if let url = post?.url, account != nil {
                delegate?.replyToUrl(url: url)
            }
        default:
            if let url = post?.url, account != nil {
                delegate?.shareUrl(url: url)
            }
        }
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        if post != nil {
            delegate?.moreOptions(post: post!, sourceButton: moreButton)
        }
    }
    
    @IBAction func activatedAudioControl(_ sender: Any) {
        if player == nil {
            if let audioUrl = post?.audio?[0] {
                audioControl?.isHidden = true
                audioLoading?.isHidden = false
                let playerItem = AVPlayerItem(url: audioUrl)
                
                // TODO: When status changes it should say: Loading, Play or Pause
                playerItem.addObserver(self,
                                       forKeyPath: #keyPath(AVPlayerItem.status),
                                       options: [.old, .new],
                                       context: nil)
                
                player = AVPlayer(playerItem: playerItem)
                player?.volume = 1.0
                playAudio()
            }
        } else if player?.timeControlStatus == .paused  {
            playAudio()
        } else {
            pauseAudio()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        // Only handle observations for the playerItemContext
//        guard context ==  else {
//            super.observeValue(forKeyPath: keyPath,
//                               of: object,
//                               change: change,
//                               context: context)
//            return
//        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                audioControl?.isHidden = false
                audioLoading?.isHidden = true
            case .failed:
                // TODO: Need to do something about the error
                print("ERROR!")
            case .unknown:
                audioControl?.isHidden = true
                audioLoading?.isHidden = false
            }
        }
    }
    
    func playAudio() {
        let session: AVAudioSession = AVAudioSession.sharedInstance();
        try? session.setActive(true)
        player?.play()
        audioControl?.setTitle(String.fontAwesomeIcon(name: .pause), for: .normal)
        
        let interval = CMTime(seconds: 1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        playerToken =
            player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) {
                [weak self] time in
                
                if self?.player?.timeControlStatus == .playing {
                    var totalSeconds = Int(time.seconds)
                    let totalMinutes = totalSeconds / 60
                    totalSeconds = totalSeconds % 60
                    self?.audioPlayerCurrentTime.text = "\(totalMinutes):\(totalSeconds < 10 ? "0" : "")\(totalSeconds)"
                    if let totalSeconds = self?.player?.currentItem?.duration.seconds {
                        let currentSeconds = time.seconds
                        self?.audioPlayerProgressBar.setProgress(Float(currentSeconds / totalSeconds), animated: true)
                        self?.mediaControlCallback?(Int(currentSeconds))
                    }
                }
        }
    }
    
    func pauseAudio() {
        player?.pause()
        audioControl?.setTitle(String.fontAwesomeIcon(name: .play), for: .normal)
        if let token = playerToken {
            player?.removeTimeObserver(token)
        }
        playerToken = nil
        let session: AVAudioSession = AVAudioSession.sharedInstance();
        try? session.setActive(false)
    }
    
    func displayResponseBar() {
        responseToolbar.setBackgroundImage(nil, forToolbarPosition: .bottom, barMetrics: .default)
        likeButton.image = UIImage.fontAwesomeIcon(name: .thumbsOUp, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        repostButton.image = UIImage.fontAwesomeIcon(name: .retweet, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        replyButton.image = UIImage.fontAwesomeIcon(name: .reply, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        moreButton.image = UIImage.fontAwesomeIcon(name: .ellipsisH, textColor: UIColor.white, size: CGSize(width: 30, height: 30))
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            self?.responseToolbarHeight.constant = 44
        })
    }
    
    func hideResponseBar() {
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            self?.responseToolbarHeight.constant = 0
        })
    }
    
    func setContent(ofPost postData: Jf2Post) {
        
        post = postData
        
        
        postTitle.text = post?.name
        postContent.text = post?.content?.text ?? post?.summary ?? nil
        
        if let likeOfCount = post?.likeOf?.count,
            likeOfCount > 0,
            let likeOfUrl = post?.likeOf?[0],
            let likeOfComponents = URLComponents(url: likeOfUrl, resolvingAgainstBaseURL: false) {
            // TODO: Make sure this isn't wrapped in an optional
            postContent.text = "liked a post\(likeOfComponents.host != nil ? " on \(likeOfComponents.host!)" : "")."
        }
        
        if let bookmarkOfCount = post?.bookmarkOf?.count,
            bookmarkOfCount > 0,
            let bookmarkOfUrl = post?.bookmarkOf?[0],
            let bookmarkOfComponents = URLComponents(url: bookmarkOfUrl, resolvingAgainstBaseURL: false) {
            // TODO: Make sure this isn't wrapped in an optional
            postContent.text = "bookmarked a post\(bookmarkOfComponents.host != nil ? " on \(bookmarkOfComponents.host!)" : "")."
        }
        
        if let name = post?.author?.name {
            authorName.text = name
        } else if let postUrl = post?.url {
            authorName.text = URLComponents.init(url: postUrl, resolvingAgainstBaseURL: false)?.host
        } else {
            authorName.text = "Unknown"
        }
        
        postImage.isHidden = false
        postImageHeight.constant = 200
        postImage.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        
        if let imageUrl = post?.photo?[0], let image = post?.photoImage?[imageUrl] {
            // display the downloaded photo
            postImage.image = image.image
        } else {
            if post?.photo != nil, post!.photo!.count > 0 {
                postImage.image = nil
                postImage.backgroundColor = ThemeManager.currentTheme().backgroundColor
                // if we are here, then there is an unloaded photo
                post?.downloadPhoto(photoIndex: 0) { returnedImage in
                    DispatchQueue.main.async {
                        self.postImage.image = returnedImage
                    }
                }
            } else {
                // this means there are no photos to load
                postImage.image = nil
                postImage.isHidden = true
                postImageHeight.constant = 0
            }
        }
        
        authorPhoto.isHidden = false
        authorPhotoHeight.constant = 50
        authorPhotoWidth.constant = 50
        
        if let authorImageUrl = post?.author?.photo?[0],
            let authorImage = post?.author?.photoImage?[authorImageUrl] {
            authorPhoto.image = authorImage.image
        } else {
            if post?.author?.photo != nil, post!.author!.photo!.count > 0 {
                authorPhoto.backgroundColor = ThemeManager.currentTheme().backgroundColor
                authorPhoto.image = nil
                post?.author?.downloadPhoto(photoIndex: 0) { returnedAuthorPhoto in
                    DispatchQueue.main.async {
                        self.authorPhoto.image = returnedAuthorPhoto
                    }
                }
            } else {
                authorPhoto.image = nil
                authorPhoto.isHidden = true
                authorPhotoHeight.constant = 0
                authorPhotoWidth.constant = 0
            }
        }
        
        if let totalAudios = post?.audio?.count, totalAudios > 0 {
            audioPlayerView.isHidden = false
            audioPlayerHeight.constant = 50
            audioControl?.titleLabel?.font = UIFont.fontAwesome(ofSize: 25)
            audioControl?.setTitle(String.fontAwesomeIcon(name: .play), for: .normal)
        } else {
            audioPlayerView.isHidden = true
            audioPlayerHeight.constant = 0
        }
        
        if let publishedDate = post?.published {
            postDate.text = Jf2Post.displayDate(dateToDisplay: publishedDate)
        }
        
        if postContent.text == nil || postContent.text == "" {
            postContent.isHidden = true
        } else {
            postContent.isHidden = false
        }
        
        if postTitle.text == nil || postTitle.text == "" {
            postTitle.isHidden = true
        } else {
            postTitle.isHidden = false
            // Since a post title exists, we should also truncate the post content to 280 characters
            postContent.text = postContent.text?.trunc(length: 140)
        }
        
        if let replyCount = post?.inReplyTo?.count, replyCount > 0 {
            replyIcon.isHidden = false
            replyIcon.text = String.fontAwesomeIcon(name: .commentsO)
            replyIcon.font = UIFont.fontAwesome(ofSize: 10)
        } else {
            replyIcon.isHidden = true
        }

        if let postRead = post?.isRead, postRead == false {
            print("Unread Post \(String(describing: post?.name))")

            DispatchQueue.main.async { [weak self] in
                
            }
            backgroundColor = ThemeManager.currentTheme().mainColor.withAlphaComponent(0.2)
        } else {
            print("Read Post \(String(describing: post?.name))")
            backgroundColor = ThemeManager.currentTheme().backgroundColor
        }
        
    }
    
    public func getMediaFragment() -> (attribute: String, fragmentTime: String)? {
        if let currentTime = self.player?.currentItem?.currentTime().seconds {
            return (attribute: "audio", fragmentTime: String(currentTime))
        }
     
        return nil
    }

}
