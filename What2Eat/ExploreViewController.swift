//
//  ExploreViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class ExploreViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var CollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let flowLayout = CollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                   flowLayout.estimatedItemSize = .zero
               }
        CollectionView.delegate = self
        CollectionView.dataSource = self
       
    
               
        
        // Do any additional setup after loading the view.
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
        cell.layer.cornerRadius = 8
        let category = categories[indexPath.row]
        
        if let CategoryCell = cell as? CategoryCollectionViewCell {
            CategoryCell.CategoryName.text = category.name
            CategoryCell.CategoryImage.image = UIImage(named: category.imageName)
       
        
        }
        
              return cell
     }
     
     // MARK: - UICollectionViewDelegateFlowLayout
     
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         let width = (collectionView.frame.width-10) / 2
         return CGSize(width: width, height: 115)
     }
     
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
         return 10
     }
     
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
         return 5
     }
     
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
         return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
     }


    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
