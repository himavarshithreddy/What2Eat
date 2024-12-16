//
//  AllergyViewController.swift
//  What2Eat
//
//  Created by admin20 on 08/11/24.
//

import UIKit


class AllergyViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    
    
    @IBOutlet weak var allergyLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let allergies: [String] = [
        "🐄Dairy",
        "🥜Peanuts",
        "🌰Tree Nuts",
        "🥚Eggs",
        "🌾Soy",
        "🍞Wheat",
        "🐟Fish",
        "🦀Shellfish",
        "🍖Milk",
        "🍂Sesame",
        "🍄Nuts"
    ]
    let allergenMapping: [String: Allergen] = [
        "🐄Dairy": .dairy,
        "🥜Peanuts": .peanuts,
        "🌰Tree Nuts": .treeNuts,
        "🥚Eggs": .eggs,
        "🌾Soy": .soy,
        "🍞Wheat": .wheat,
        "🐟Fish": .fish,
        "🦀Shellfish": .shellfish,
        "🍖Milk": .milk,
        "🍂Sesame": .sesame,
        "🍄Nuts": .nuts
    ]
    var selectedAllergens: [Allergen] = []
        
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
            return allergies.count
        }
            
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllergyCell", for: indexPath) as! AllergyCell
            let allergy = allergies[indexPath.row]
            cell.allergyButton.setTitle(allergy, for: .normal)
            cell.allergyButton.titleLabel?.textAlignment = .center
            cell.allergyButton.tag = indexPath.row
            cell.allergyButton.addTarget(self, action: #selector(allergyButtonTapped(_:)), for: .touchUpInside)
            return cell
        }
    @objc private func allergyButtonTapped(_ sender: UIButton) {
           let allergy = allergies[sender.tag]
           guard let mappedAllergen = allergenMapping[allergy] else { return }
           
           if selectedAllergens.contains(mappedAllergen) {
               selectedAllergens.removeAll { $0 == mappedAllergen }
           } else {
               selectedAllergens.append(mappedAllergen)
           }
       }
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let title = allergies[indexPath.item]
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
                    
                let firstRowGroup = self.createRowGroup(withCount: 2, item: item)
                let secondRowGroup = self.createRowGroup(withCount: 3, item: item)
                let thirdRowGroup = self.createRowGroup(withCount: 2, item: item)
                let fourthRowGroup = self.createRowGroup(withCount: 3, item: item)
                let fifthRowGroup = self.createRowGroup(withCount: 2, item: item)
                    
                let nestedGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(240)
                    ),
                    subitems: [
                        firstRowGroup,
                        secondRowGroup,
                        thirdRowGroup,
                        fourthRowGroup,
                        fifthRowGroup
                    ]
                )
                nestedGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(15)
                let section = NSCollectionLayoutSection(group: nestedGroup)
                section.interGroupSpacing = 25
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                    
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
            rowGroup.interItemSpacing = .fixed(12)
            rowGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
                
            return rowGroup
        }
    @IBAction func ContinueButton(_ sender: Any) {
        sampleUser.allergies = selectedAllergens
                
                print("Updated User Allergens: \(sampleUser.allergies)")
    }
}
    

    

