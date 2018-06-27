//
//  OnboardingViewController.swift
//  Indigenous
//
//  Created by Edward Hinkle on 6/26/18.
//  Copyright © 2018 Studio H, LLC. All rights reserved.
//

import UIKit

class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pages = [UIViewController]()
    var currentIndex = 0
    let startingIndex = 0
    var dataController: DataController!
    
    // MARK: - UIPageViewControllerDataSource Methods
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return pages.last
        }
        
        guard pages.count > previousIndex else {
            return nil
        }
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else {
            return pages.first
        }
        
        guard pages.count > nextIndex else {
            return nil
        }
        
        return pages[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
    
    // MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        dataSource = self
        view.backgroundColor = ThemeManager.currentTheme().mainColor
        
        if let introPage = storyboard?.instantiateViewController(withIdentifier: "onboardingTemplate") as? OnboardingTemplateViewController {
            introPage.titleText = "Open up the internet"
            introPage.contentText = "Indigenous allows you to engage with the Internet as you do on social media sites, but posts it all on your website. Use the built-in reader to read and respond to posts across the internet. Indigenous doesn’t track or store any of your information. You choose a service you trust or host it yourself."
            introPage.primaryIcon = .commentsO
            pages.append(introPage)
        }

        if let micropubPage = storyboard?.instantiateViewController(withIdentifier: "onboardingTemplate") as? OnboardingTemplateViewController {
            micropubPage.titleText = "Writing"
            micropubPage.contentText = "Post to any website or microblog that supports Micropub. Some popular services that can support Micropub is Micro.blog, Wordpress and Known."
            micropubPage.buttonText = "Learn About Micropub"
            micropubPage.buttonUrl = URL(string: "https://indigenous.abode.pub/micropub")
            micropubPage.primaryIcon = .commenting
            pages.append(micropubPage)
        }
        
        if let microsubPage = storyboard?.instantiateViewController(withIdentifier: "onboardingTemplate") as? OnboardingTemplateViewController {
            microsubPage.titleText = "Reading"
            microsubPage.contentText = "You can read posts within Indigenous if your website supports Microsub. The primary service that currently supports Microsub is Aperture."
            microsubPage.buttonText = "Learn About Microsub"
            microsubPage.buttonUrl = URL(string: "https://indigenous.abode.pub/microsub")
            microsubPage.primaryIcon = .newspaperO
            pages.append(microsubPage)
        }
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginPage = mainStoryboard.instantiateViewController(withIdentifier: "indieAuthLoginView") as? IndieAuthLoginViewController {
            loginPage.dataController = dataController
            pages.append(loginPage)
        }
        
        currentIndex = startingIndex
        setViewControllers([pages[currentIndex]], direction: .forward, animated: false, completion: nil)
    }
    
}
