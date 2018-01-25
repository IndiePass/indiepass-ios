//
//  TimelineTableViewCell.swift
//  Indigenous
//
//  Created by Edward Hinkle on 1/18/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class TimelinePhotoTableViewCell: UITableViewCell {

    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorPhoto: UIImageView!
    @IBOutlet weak var postContent: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postDate: UILabel!
    
    func setContent(ofPost post: Jf2Post) {
        
        postContent.text = post.name ?? post.content?.text ?? post.summary ?? ""
        authorName.text = post.author?.name ?? "Unknown"
        
        postImage.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        postImage.isHidden = false
        
        if let imageUrl = post.photo?[0], let image = post.photoImage?[imageUrl] {
            // display the downloaded photo
            postImage.image = image.image
        } else {
            if post.photo != nil, post.photo!.count > 0 {
                postImage.image = nil
                // if we are here, then there is an unloaded photo
                post.downloadPhoto(photoIndex: 0) { returnedImage in
                    DispatchQueue.main.async {
                        self.postImage.image = returnedImage
                    }
                }
            } else {
                // this means there are no photos to load
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
