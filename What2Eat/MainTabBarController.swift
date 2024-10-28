//
//  MainTabBarController.swift
//  What2Eat
//
//  Created by admin20 on 28/10/24.
//

import UIKit

// MARK: - TabBarController
class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        customizeTabBar()
    }
    
    private func setupViewControllers() {
        // Home Tab
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        // Explore Tab
        let exploreVC = ExploreViewController()
        let exploreNav = UINavigationController(rootViewController: exploreVC)
        exploreNav.tabBarItem = UITabBarItem(
            title: "Explore",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )
        
        // Additional Tabs
        // Replace the placeholder scanVC with:
        let scanVC = ScanViewController()
        let scanNav = UINavigationController(rootViewController: scanVC)
        scanNav.tabBarItem = UITabBarItem(
            title: "Scan",
            image: UIImage(systemName: "barcode.viewfinder"),
            selectedImage: UIImage(systemName: "barcode.viewfinder")
        )
        
        let savedVC = UIViewController() // Placeholder for saved tab
        savedVC.tabBarItem = UITabBarItem(
            title: "Saved",
            image: UIImage(systemName: "bookmark"),
            selectedImage: UIImage(systemName: "bookmark.fill")
        )
        
        let profileVC = UIViewController() // Placeholder for profile tab
        profileVC.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
        
        viewControllers = [homeNav, exploreNav, scanVC, savedVC, profileVC]
    }
    
    private func customizeTabBar() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // Set the tint color for the selected item
        tabBar.tintColor = .systemOrange
    }
}

// MARK: - ExploreViewController

