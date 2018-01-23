//
//  TimelineTableViewCell.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/18/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class TimelineTableViewCell: UITableViewCell {

    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorPhoto: UIImageView!
    @IBOutlet weak var postContent: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postDate: UILabel!
    
    func setContent(ofPost post: Jf2Post) {
        
        postContent.text = post.name ?? post.content?.text ?? post.summary ?? "Content Can't Display"
        authorName.text = post.author?.name ?? "Unknown"
        
        postImage.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        postImage.isHidden = false
        
        if let imageUrl = post.photo?[0], let image = post.photoImage?[imageUrl] {
            // display the downloaded photo
            postImage.image = image.image
        } else {
            if post.photo != nil, post.photo!.count > 0 {
                // if we are here, then there is an unloaded photo
                post.downloadPhoto(photoIndex: 0) { returnedImage in
                    DispatchQueue.main.async {
                        
                        if let photo = returnedImage {
                            
                            if photo.size.width > self.postImage.frame.width {
                                let size = CGSize(width: self.postImage.frame.width, height: max(200, self.postImage.frame.width * photo.size.height / photo.size.width))
                                self.postImage.image = photo.scaledAspectFit(to: size)
                            } else {
                                self.postImage.image = photo
                            }

                        }
                    }
                }
            } else {
                // this means there are no photos to load
                postImage.image = nil
                postImage.isHidden = true
            }
        }
        
        if let authorImageUrl = post.author?.photo?[0],
            let authorImage = post.author?.photoImage?[authorImageUrl] {
            authorPhoto.image = authorImage.image
        } else {
            if post.author?.photo != nil, post.author!.photo!.count > 0 {
                post.author?.downloadPhoto(photoIndex: 0) { returnedAuthorPhoto in
                    DispatchQueue.main.async {
                        self.authorPhoto.image = returnedAuthorPhoto
                    }
                }
            } else {
                authorPhoto.image = nil
            }
        }
        
        if let publishedDate = post.published {
            //               let publishedDate = ISO8601DateFormatter().date(from: dateString) {
            
            if Calendar.current.isDateInToday(publishedDate) {
                postDate.text = "Today at " + DateFormatter.localizedString(from: publishedDate, dateStyle: .none, timeStyle: .short)
            } else {
                postDate.text = " " + DateFormatter.localizedString(from: publishedDate, dateStyle: .medium, timeStyle: .short)
            }
        }
    }

}
