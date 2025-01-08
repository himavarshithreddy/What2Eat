//
//  ExploreViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit
import FirebaseFirestore



class ExploreViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UISearchBarDelegate {
    
    let db = Firestore.firestore()
    var categories: [Category] = []

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
        fetchCategoriesFromFirebase()
              
                
                // Do any additional setup after loading the view.
            }
    func fetchCategoriesFromFirebase() {
        db.collection("categories").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching categories: \(error.localizedDescription)")
                return
            }
            
            // Clear the existing categories array
            self.categories = []
            
            // Parse documents into Category model
            querySnapshot?.documents.forEach { document in
                let data = document.data()
                if let idString = data["id"] as? String,
                   let id = UUID(uuidString: idString),
                   let name = data["name"] as? String,
                   let imageName = data["imageName"] as? String {
                    let category = Category(id: id, name: name, imageName: imageName)
                    self.categories.append(category)
                }
            }
            
            // Reload the collection view on the main thread
            DispatchQueue.main.async {
                self.CollectionView.reloadData()
            }
        }
    }
            func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return categories.count
            }
            
            func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                 let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
                cell.layer.cornerRadius = 8
                let category = categories[indexPath.item]
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
                    let selectedCategory = categories[indexPath.item]
                    
                  
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
