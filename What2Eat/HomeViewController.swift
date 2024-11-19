//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin68 on 19/11/24.
//

import UIKit
import WebKit

class HomeViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   
    
    @IBOutlet weak var collectionView: UICollectionView!
    
   
    @IBOutlet var HomeImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        HomeImage.transform = CGAffineTransform(rotationAngle: .pi*1.833)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                   flowLayout.estimatedItemSize = .zero
            
               }
        collectionView.register(
            UINib(nibName: "HomePickForYouCellCollectionReusableView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Picksforyouheader"
        )


        // Do any additional setup after loading the view.
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sampleUser.PicksforYou.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickforyouCell", for: indexPath) as! HomePickForYouCell
        let pick = sampleUser.PicksforYou[indexPath.row]
        cell.pickImage.image = UIImage(named: pick.imageURL)
        cell.picktitle.text = pick.name
//        cell.pickcategory.text = pick.categoryId
        
        cell.pickscoreLabel.text = "\(pick.healthScore)"
        
        cell.pickview.layer.cornerRadius = cell.pickview.frame.height/2
        
        if pick.healthScore < 40 {
            cell.pickview.layer.backgroundColor = UIColor.systemRed.cgColor
                }
        else if pick.healthScore < 75 {
                
            cell.pickview.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
                }
        else if pick.healthScore < 100 {
            cell.pickview.layer.backgroundColor = UIColor.systemGreen.cgColor
                }
        cell.layer.cornerRadius = 14
        return cell
        
    }
    
    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout {(section,env)->NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6), heightDimension: .absolute(300))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50)) // Adjust height as needed
                   let header = NSCollectionLayoutBoundarySupplementaryItem(
                       layoutSize: headerSize,
                       elementKind: UICollectionView.elementKindSectionHeader,
                       alignment: .top
                   )
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [header]
            section.orthogonalScrollingBehavior = .continuous
            return section
            
            
        }
        
        return layout
        
    }

}
