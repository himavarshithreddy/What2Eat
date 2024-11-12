//
//  ExploreViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class ExploreViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UISearchBarDelegate {
    
    
    var filteredCategories: [Category] = []
    private var searchBar: UISearchBar?
    
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var CollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let flowLayout = CollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                   flowLayout.estimatedItemSize = .zero
               }
        CollectionView.delegate = self
        CollectionView.dataSource = self
        SearchBar.delegate=self
        filteredCategories = Categories
        
        // Do any additional setup after loading the view.
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
        cell.layer.cornerRadius = 8
        let category = filteredCategories[indexPath.item]
        if let CategoryCell = cell as? CategoryCollectionViewCell {
            CategoryCell.CategoryName.text = category.name
            CategoryCell.CategoryImage.image = UIImage(named: category.imageName)
        }
        
              return cell
     }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
         if kind == UICollectionView.elementKindSectionHeader {
             let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ExploreHeaderView", for: indexPath) as! ExploreHeaderView
           
             return headerView
         }
         return UICollectionReusableView()
     }
     
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
          filteredCategories = searchText.isEmpty ? Categories : Categories.filter { $0.name.lowercased().contains(searchText.lowercased()) }
       
        CollectionView.reloadData()
      }
      
      func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
          searchBar.resignFirstResponder()
      }
    
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
         return CGSize(width: collectionView.frame.width, height: 25) // Adjust height as needed
     }
    
     
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         let width = (collectionView.frame.width-10) / 2
         return CGSize(width: width, height: 115)
     }
     
    


    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let selectedCategory = filteredCategories[indexPath.item]
            
          
            performSegue(withIdentifier: "showExploreProducts", sender: selectedCategory)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showExploreProducts",
               let destination = segue.destination as? ExploreProductsViewController,
               let selectedCategory = sender as? Category {
                
                destination.category = selectedCategory
            }
        }

}
