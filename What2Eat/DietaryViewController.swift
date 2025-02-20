//
//  DietaryViewController.swift
//  What2Eat
//
//  Created by admin20 on 14/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class DietaryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    @IBOutlet weak var dietaryLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet weak var SaveButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
  
    
    var selectedDietaryRestrictions: [DietaryRestriction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchUserDietaryRestrictions()
    }
    
    private func setupCollectionView() {
        collectionView.collectionViewLayout = createCompositionalLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // Fetch saved dietary restrictions either from Firestore (if logged in) or locally.
    private func fetchUserDietaryRestrictions() {
        if let uid = Auth.auth().currentUser?.uid {
            // User is logged in, fetch from Firestore
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            
            userDocument.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching dietary restrictions: \(error.localizedDescription)")
                    self.showAlert(message: "Error fetching dietary restrictions: \(error.localizedDescription)")
                } else if let document = document, document.exists,
                          let restrictions = document.get("dietaryRestrictions") as? [String] {
                    self.selectedDietaryRestrictions = restrictions.compactMap { DietaryRestriction(rawValue: $0) }
                    self.updateUIWithSelectedDietaryRestrictions()
                }
            }
        } else {
            // User not logged in, load from local storage
            let defaults = UserDefaults.standard
            if let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String] {
                self.selectedDietaryRestrictions = localRestrictions.compactMap { DietaryRestriction(rawValue: $0) }
                self.updateUIWithSelectedDietaryRestrictions()
            }
        }
    }
    
    // Update UI: Set the initial state of each cell based on the saved restrictions.
    private func updateUIWithSelectedDietaryRestrictions() {
        for cell in collectionView.visibleCells {
            if let dietaryCell = cell as? DietaryCell {
                let dietaryOption = dietaryOptions[dietaryCell.dietaryButton.tag]
                guard let mappedRestriction = dietaryRestrictionMapping[dietaryOption] else { continue }
                
                dietaryCell.setSelectedState(isSelected: selectedDietaryRestrictions.contains(mappedRestriction))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dietaryOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DietaryCell", for: indexPath) as! DietaryCell
        let dietaryOption = dietaryOptions[indexPath.row]
        cell.dietaryButton.setTitle(dietaryOption, for: .normal)
        cell.dietaryButton.titleLabel?.textAlignment = .center
        cell.dietaryButton.tag = indexPath.row
        
        // Attach action to handle selection
        cell.dietaryButton.addTarget(self, action: #selector(dietaryButtonTapped(_:)), for: .touchUpInside)
        
        // Optionally, set initial state if you want to load saved restrictions
        // (This is done in updateUIWithSelectedDietaryRestrictions(), called after fetchUserDietaryRestrictions)
        
        return cell
    }
    
    @objc private func dietaryButtonTapped(_ sender: UIButton) {
        let dietaryOption = dietaryOptions[sender.tag]
        guard let mappedRestriction = dietaryRestrictionMapping[dietaryOption] else { return }
        
        if selectedDietaryRestrictions.contains(mappedRestriction) {
            selectedDietaryRestrictions.removeAll { $0 == mappedRestriction }
        } else {
            selectedDietaryRestrictions.append(mappedRestriction)
        }
        // Update UI for the tapped button
        sender.isSelected.toggle()
        sender.backgroundColor = sender.isSelected ? .systemOrange : .clear
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = dietaryOptions[indexPath.item]
        let font = UIFont.systemFont(ofSize: 17)
        let size = (title as NSString).size(withAttributes: [.font: font])
        
        let height: CGFloat = 50
        let minWidth: CGFloat = 50
        let width = max(size.width + 98, minWidth)
        
        return CGSize(width: width, height: height)
    }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(100),
                heightDimension: .absolute(50)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Create 7 row groups for a compact layout
            let firstRowGroup = self.createRowGroup(withCount: 2, item: item)
            let secondRowGroup = self.createRowGroup(withCount: 3, item: item)
            let thirdRowGroup = self.createRowGroup(withCount: 2, item: item)
            let fourthRowGroup = self.createRowGroup(withCount: 3, item: item)
            let fifthRowGroup = self.createRowGroup(withCount: 2, item: item)
            let sixthRowGroup = self.createRowGroup(withCount: 3, item: item)
            let seventhRowGroup = self.createRowGroup(withCount: 2, item: item)
            
            let nestedGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(300)
                ),
                subitems: [
                    firstRowGroup,
                    secondRowGroup,
                    thirdRowGroup,
                    fourthRowGroup,
                    fifthRowGroup,
                    sixthRowGroup,
                    seventhRowGroup
                ]
            )
            nestedGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
            
            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.interGroupSpacing = 5
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            return section
        }
    }
    
    private func createRowGroup(withCount count: Int, item: NSCollectionLayoutItem) -> NSCollectionLayoutGroup {
        let items = Array(repeating: item, count: count)
        
        let rowGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(44)
            ),
            subitems: items
        )
        rowGroup.interItemSpacing = .fixed(7)
        rowGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7)
        
        return rowGroup
    }
    
    @IBAction func SaveButtonTapped(_ sender: Any) {
        let selectedDietaryNames = selectedDietaryRestrictions.map { $0.rawValue }
        
        if let uid = Auth.auth().currentUser?.uid {
            // Firestore update
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            
            userDocument.updateData(["dietaryRestrictions": selectedDietaryNames]) { error in
                if let error = error {
                    self.showAlert(message: "Error updating dietary restrictions: \(error.localizedDescription)")
                } else {
                    self.progressView.setProgress(1.0, animated: true)
                    // Navigate back to Profile
                    if isOnboarding {
                        isOnboarding = false
                    self.navigateToTabBarController()
            } else {
                    self.navigateBackToProfile()
                self.showAlert(message: "Health Info updated successfully.")
                                            }
                    print(isOnboarding)
                 
                }
            }
        } else {
            // Local save
            UserDefaults.standard.set(selectedDietaryNames, forKey: "localDietaryRestrictions")
            self.progressView.setProgress(1.0, animated: true)
            // Navigate back to Profile
            if isOnboarding {
                isOnboarding = false
                
            self.navigateToTabBarController()
    } else {
            self.navigateBackToProfile()
        
        self.showAlert(message: "Dietary restrictions updated locally.")
                                    }
          
        }
    }

    private func navigateBackToProfile() {
        if let navController = self.navigationController {
            for viewController in navController.viewControllers {
                if viewController is ProfileViewController {
                    navController.popToViewController(viewController, animated: true)
                    break
                }
            }
        }
    }
    private func navigateToTabBarController() {
        // First, create a brief animation to provide visual feedback
        let fadeView = UIView(frame: self.view.bounds)
        fadeView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        fadeView.alpha = 0
        self.view.addSubview(fadeView)
        
        // Animate the fade view
        UIView.animate(withDuration: 0.2, animations: {
            fadeView.alpha = 1
        }) { _ in
            // After fade completes, navigate with a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fadeView.removeFromSuperview()
                
                // Navigate to TabBarController
                if let windowScene = self.view.window?.windowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                   let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") {
                    
                    // Create transition animation
                    let transition = CATransition()
                    transition.duration = 0.2
                    transition.type = CATransitionType.fade
                    window.layer.add(transition, forKey: nil)
                    
                    window.rootViewController = tabBarController
                    window.makeKeyAndVisible()
                }
            }
        }
    }
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "Update Status", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
