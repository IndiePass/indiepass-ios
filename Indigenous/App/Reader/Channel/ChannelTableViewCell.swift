//
//  ChannelTableViewCell.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class ChannelTableViewCell: UITableViewCell {

    var data: Channel? = nil
    
    @IBOutlet weak var channelName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setContent(ofChannel channel: Channel) {
        self.data = channel
        self.channelName?.text = data!.name
        if data!.unread > 0 {
            self.channelName?.font = UIFont.boldSystemFont(ofSize: 17.0)
        } else {
            self.channelName?.font = UIFont.systemFont(ofSize: 17.0)
        }
    }

}
