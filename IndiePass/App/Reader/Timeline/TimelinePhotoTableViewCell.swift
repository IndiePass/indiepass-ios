//
//  TimelineTableViewCell.swift
//  IndiePass
//
//  Created by Edward Hinkle on 1/18/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class TimelinePhotoTableViewCell: UITableViewCell {

    var post: Jf2Post? = nil
    var player: AVPlayer? = nil
    var playerToken: Any? = nil
    var mediaControlCallback: ((_ currentTime: Int?) -> ())?
    private var unreadIndicator: CALayer? = nil
    
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
    
    func setContent(ofPost postData: Jf2Post) {
        
        post = postData
        
        postTitle.text = post?.name
        let postText: String?
        if let text = post?.content?.text {
            postText = text
        } else if let text = post?.content?.html?.html2String {
            postText = text
        } else {
            postText = post?.summary
        }
        postContent.text = postText
        
        authorName.text = post?.author?.name ?? URLComponents.init(url: (post?.url)!, resolvingAgainstBaseURL: false)?.host ?? "Unknown"
        
        postImage.isHidden = false
        postImageHeight.constant = 200
        postImage.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        
        if let imageUrl = post?.photo?[0], let image = post?.photoImage?[imageUrl] {
            // display the downloaded photo
            postImage.image = image.image
        } else {
            if post?.photo != nil, post!.photo!.count > 0 {
                postImage.image = nil
                postImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
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
                authorPhoto.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
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
            let borderWidth: CGFloat = 4
            
            if unreadIndicator == nil {
                unreadIndicator = CALayer()
                unreadIndicator!.borderColor = #colorLiteral(red: 0.7994786501, green: 0.1424995661, blue: 0.1393664181, alpha: 1)
                unreadIndicator!.borderWidth = borderWidth
                
                contentView.layer.addSublayer(unreadIndicator!)
                contentView.layer.masksToBounds = true
            }

            DispatchQueue.main.async { [weak self] in
                if let frameHeight = self?.contentView.frame.height {
                    self?.unreadIndicator!.frame = CGRect(x: 0, y: 0, width: borderWidth, height: frameHeight)
                }
            }
            unreadIndicator!.isHidden = false
        } else {
            print("Read Post \(String(describing: post?.name))")
            unreadIndicator?.isHidden = true
        }
        
    }
    
    public func getMediaFragment() -> (attribute: String, fragmentTime: String)? {
        if let currentTime = self.player?.currentItem?.currentTime().seconds {
            return (attribute: "audio", fragmentTime: String(currentTime))
        }
     
        return nil
    }

}
