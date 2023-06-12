//
//  StringProtocol+Extension.swift
//  IndiePass
//
//  Created by Antonio Rodrigues on 5/30/23.
//

import Foundation

extension StringProtocol {
    var html2AttributedString: NSAttributedString? {
        Data(utf8).html2AttributedString
    }
    var html2String: String {
        html2AttributedString?.string ?? ""
    }
}
