//
//  DietaryViewController.swift
//  What2Eat
//
//  Created by admin20 on 14/11/24.


import UIKit

class DietaryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {

    @IBOutlet weak var dietaryLabel: UILabel!
    
    @IBOutlet weak var SaveButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let dietaryOptions = [
        "🌾Gluten-Free",
        "🐄Dairy-Free",
        "🥜Nut-Free",
        "🌱Vegan",
        "🍃Vegetarian",
        "🍭Low Sugar",
        "🥓Keto",
        "💓High Blood Pressure"
    ]
    let dietaryRestrictionMapping: [String: DietaryRestriction] = [
        "🌾Gluten-Free": .glutenFree,
        "🐄Dairy-Free": .dairyFree,
        "🥜Nut-Free": .nutFree,
        "🌱Vegan": .vegan,
        "🍃Vegetarian": .vegetarian,
        "🍭Low Sugar": .lowSugar,
        "🥓Keto": .keto,
        "💓High Blood Pressure": .highBP
    ]
    var selectedDietaryRestrictions: [DietaryRestriction] = []
       
    override func viewDidLoad() {
               super.viewDidLoad()
               setupCollectionView()
           }
           
           private func setupCollectionView() {
               collectionView.collectionViewLayout = createCompositionalLayout()
               collectionView.delegate = self
               collectionView.dataSource = self
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
               
               // Create 7 row groups
               let firstRowGroup = self.createRowGroup(withCount: 2, item: item)
               let secondRowGroup = self.createRowGroup(withCount: 3, item: item)
               let thirdRowGroup = self.createRowGroup(withCount: 2, item: item)
               let fourthRowGroup = self.createRowGroup(withCount: 3, item: item)
               let fifthRowGroup = self.createRowGroup(withCount: 2, item: item)
               let sixthRowGroup = self.createRowGroup(withCount: 3, item: item)
               let seventhRowGroup = self.createRowGroup(withCount: 2, item: item)
               
               // Combine all row groups in a vertical layout
               let nestedGroup = NSCollectionLayoutGroup.vertical(
                   layoutSize: NSCollectionLayoutSize(
                       widthDimension: .fractionalWidth(1.0),
                       heightDimension: .estimated(300) // Adjusted for compact spacing
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
               section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) // Reduced insets
               
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
        sampleUser.dietaryRestrictions = selectedDietaryRestrictions
        print("Updated User Dietary Restrictions: \(sampleUser.dietaryRestrictions)")
        SaveButton.setTitle("Saved",for: .normal)
    }
}
