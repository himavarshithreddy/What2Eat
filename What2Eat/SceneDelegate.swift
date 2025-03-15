//
//  SceneDelegate.swift
//  What2Eat
//
//  Created by admin68 on 23/10/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
       // guard let _ = (scene as? UIWindowScene) else { return }
            guard let windowScene = (scene as? UIWindowScene) else { return }
            window = UIWindow(windowScene: windowScene)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            var initialViewController: UIViewController
            
            if !UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) {
                // First-time user: Show LoginViewController and present OnboardingViewController
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
                loginVC.modalPresentationStyle = .fullScreen
                onboardingVC.modalPresentationStyle = .fullScreen
                
                initialViewController = loginVC
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loginVC.present(onboardingVC, animated: true, completion: nil)
                }
                
                // Set flag that onboarding has been shown
               
            } else {
                // Returning user: Show MainTabBarController
                initialViewController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
            }
            
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }


    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
   

}
