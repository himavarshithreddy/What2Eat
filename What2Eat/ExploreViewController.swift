//
//  ExploreViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class ExploreViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UISearchBarDelegate {
    


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
              
                
                // Do any additional setup after loading the view.
            }
            func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return Categories.count
            }
            
            func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                 let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
                cell.layer.cornerRadius = 8
                let category = Categories[indexPath.item]
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
             
            
          
                          
             func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
                 return CGSize(width: collectionView.frame.width, height: 25) // Adjust height as needed
             }
            
             
             func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                 let width = (collectionView.frame.width-10) / 2
                 return CGSize(width: width, height: 115)
             }
             
            


            

            func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                    let selectedCategory = Categories[indexPath.item]
                    
                  
                    performSegue(withIdentifier: "showExploreProducts", sender: selectedCategory)
                }
                
                override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                    if segue.identifier == "showExploreProducts",
                       let destination = segue.destination as? ExploreProductsViewController,
                       let selectedCategory = sender as? Category {
                        
                        destination.category = selectedCategory
                    }
                }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        performSegue(withIdentifier: "showsearch", sender: nil)
        
        return false 
    }

        }
