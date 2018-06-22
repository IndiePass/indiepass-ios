//
//  CommandTableViewCell.swift
//  Indigenous
//
//  Created by Edward Hinkle on 12/20/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import UIKit

class CommandTableViewCell: UITableViewCell, CommandDelegate {
    
    @IBOutlet weak var commandName: UILabel!
    @IBOutlet weak var commandActivity: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setContent(ofCommand command: Command) {
        commandActivity.isHidden = true
        commandActivity.color = ThemeManager.currentTheme().mainColor
        self.commandName?.text = command.name
        command.delegate = self
    }
    
    func statusUpdate(runningStatus isRunning: Bool) {
        self.isSelected = false
        if isRunning {
            self.commandActivity.startAnimating()
            self.commandActivity.isHidden = false
        } else {
            self.commandActivity.isHidden = true
            self.commandActivity.stopAnimating()
        }
    }
    
}

