//
//  CommandTableViewCell.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class CommandTableViewCell: UITableViewCell {
    
    @IBOutlet weak var commandName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setContent(ofCommand command: Command) {
        self.commandName?.text = command.name
    }
    
}

