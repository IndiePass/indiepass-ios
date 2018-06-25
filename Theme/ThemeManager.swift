//
//  ThemeManager.swift
//  Indigenous
//
//  Created by Edward Hinkle on 6/21/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//
import UIKit
import WebKit
import Foundation

extension UIColor {
    func colorFromHexString (_ hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}

enum ThemeStyle: Int {
    case dark, light
}

enum Theme: Int {
    
    case red, blue
    
    var mainColor: UIColor {
        switch self {
        case .red:
            return UIColor().colorFromHexString("DD645E")
        case .blue:
            return UIColor().colorFromHexString("63A8BD")
        }
    }
    
    var textColor: UIColor {
        switch style {
        case .light:
            return UIColor().colorFromHexString("000000")
        case .dark:
            return UIColor().colorFromHexString("FFFFFF")
        }
    }
    
    var style: ThemeStyle {
        switch self {
        case .red:
            return .light
        case .blue:
            return .dark
        }
    }
    
    // Deep means more contrast (darker for light themes and lighter for dark themes)
    var deepColor: UIColor {
        switch style {
        case .light:
            return mainColor.darker(amount: 0.2)
        case .dark:
            return mainColor.lighter(amount: 0.2)
        }
    }
    
    // Shallow means less contrast (lighter for light themes and darker for dark themes)
    var shallowColor: UIColor {
        switch style {
        case .dark:
            return mainColor.darker(amount: 0.2)
        case .light:
            return mainColor.lighter(amount: 0.2)
        }
    }
    
    //Customizing the Navigation Bar
    var barStyle: UIBarStyle {
        switch style {
        case .light:
            return .default
        case .dark:
            return .black
        }
    }
    
    var backgroundColor: UIColor {
        switch style {
        case .light:
            return UIColor().colorFromHexString("ffffff")
        case .dark:
            return UIColor().colorFromHexString("000000")
        }
    }
    
    var secondaryColor: UIColor {
        return deepColor
//        switch style {
//        case .light:
////            return UIColor().colorFromHexString("ffffff")
//        case .dark:
//            return UIColor().colorFromHexString("000000")
//        }
    }
    
    var titleTextColor: UIColor {
        switch style {
        case .light:
            return UIColor().colorFromHexString("000000")
        case .dark:
            return UIColor().colorFromHexString("ffffff")
        }
    }
    var subtitleTextColor: UIColor {
        switch style {
        case .light:
            return UIColor().colorFromHexString("000000")
        case .dark:
            return UIColor().colorFromHexString("ffffff")
        }
    }
}

// Enum declaration
let SelectedThemeKey = "SelectedTheme"

// This will let you use a theme in the app.
class ThemeManager {
    
    // ThemeManager
    static func currentTheme() -> Theme {
        if let storedTheme = (UserDefaults(suiteName: "group.software.studioh.indigenous")?.value(forKey: SelectedThemeKey) as AnyObject).integerValue {
            return Theme(rawValue: storedTheme)!
        } else {
            return .blue
        }
    }
    
    static func applyTheme(theme: Theme) {
        applyTheme(theme: theme, window: nil)
    }
    
    static func applyTheme(theme: Theme, window: UIWindow?) {
        // First persist the selected theme using NSUserDefaults.
        UserDefaults(suiteName: "group.software.studioh.indigenous")?.setValue(theme.rawValue, forKey: SelectedThemeKey)
        UserDefaults(suiteName: "group.software.studioh.indigenous")?.synchronize()
        
        // You get your current (selected) theme and apply the main color to the tintColor property of your application’s window.
        window?.tintColor = theme.mainColor
        
        // MARK: - Global UIView Tint Color
        UIView.appearance().tintColor = theme.mainColor
        
        // MARK: - UI Switch Theme
        UISwitch.appearance().onTintColor = theme.shallowColor
        
        // MARK: - UINavigationBar Theme
        UINavigationBar.appearance().backgroundColor = theme.backgroundColor
        UINavigationBar.appearance().setBackgroundImage(nil, for: .default)
        UINavigationBar.appearance().barStyle = theme.barStyle
        UINavigationBar.appearance().shadowImage = UIImage()
        
        // MARK: - UIToolbar Theme
        UIToolbar.appearance().backgroundColor = theme.backgroundColor
        UIToolbar.appearance().barStyle = theme.barStyle
        
        // MARK: - UITableView Theme
        UITableView.appearance().backgroundColor = theme.backgroundColor
        UITableViewCell.appearance().backgroundColor = theme.backgroundColor
        let selectedCellBackgroundView = UIView()
        selectedCellBackgroundView.backgroundColor = theme.shallowColor
        UITableViewCell.appearance().selectedBackgroundView = selectedCellBackgroundView
        
        // MARK: - UILabel Theme
        UILabel.appearance().textColor = theme.textColor
        
        // MARK: - WKWebView Theme
        WKWebView.appearance().backgroundColor = theme.backgroundColor
        
        // MARK: - UIProgressView Theme
        UIProgressView.appearance().tintColor = theme.mainColor
        

//        UINavigationBar.appearance().setBackgroundImage(theme.navigationBackgroundImage, for: .default)
//        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "backArrow")
//        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "backArrowMaskFixed")
//
//        UITabBar.appearance().barStyle = theme.barStyle
//        UITabBar.appearance().backgroundImage = theme.tabBarBackgroundImage
//
//        let tabIndicator = UIImage(named: "tabBarSelectionIndicator")?.withRenderingMode(.alwaysTemplate)
//        let tabResizableIndicator = tabIndicator?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 2.0, bottom: 0, right: 2.0))
//        UITabBar.appearance().selectionIndicatorImage = tabResizableIndicator
//
//        let controlBackground = UIImage(named: "controlBackground")?.withRenderingMode(.alwaysTemplate)
//            .resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3))
//        let controlSelectedBackground = UIImage(named: "controlSelectedBackground")?
//            .withRenderingMode(.alwaysTemplate)
//            .resizableImage(withCapInsets: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3))
//
//        UISegmentedControl.appearance().setBackgroundImage(controlBackground, for: .normal, barMetrics: .default)
//        UISegmentedControl.appearance().setBackgroundImage(controlSelectedBackground, for: .selected, barMetrics: .default)
//
//        UIStepper.appearance().setBackgroundImage(controlBackground, for: .normal)
//        UIStepper.appearance().setBackgroundImage(controlBackground, for: .disabled)
//        UIStepper.appearance().setBackgroundImage(controlBackground, for: .highlighted)
//        UIStepper.appearance().setDecrementImage(UIImage(named: "fewerPaws"), for: .normal)
//        UIStepper.appearance().setIncrementImage(UIImage(named: "morePaws"), for: .normal)
//
//        UISlider.appearance().setThumbImage(UIImage(named: "sliderThumb"), for: .normal)
//        UISlider.appearance().setMaximumTrackImage(UIImage(named: "maximumTrack")?
//            .resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0.0, bottom: 0, right: 6.0)), for: .normal)
//        UISlider.appearance().setMinimumTrackImage(UIImage(named: "minimumTrack")?
//            .withRenderingMode(.alwaysTemplate)
//            .resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 6.0, bottom: 0, right: 0)), for: .normal)
//
//        UISwitch.appearance().onTintColor = theme.mainColor.withAlphaComponent(0.3)
//        UISwitch.appearance().thumbTintColor = theme.mainColor
    }
}
