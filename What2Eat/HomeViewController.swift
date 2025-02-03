//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin68 on 19/11/24.
//

import UIKit
import WebKit
import FirebaseFirestore
import QuartzCore
import FirebaseAuth

class HomeViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UITableViewDelegate,UITableViewDataSource {
    
    
 
    @IBOutlet var HomeHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet var recentScansSeeAll: UIButton!
    
    @IBOutlet var noRecentScansLabel: UILabel!
    @IBOutlet var ScanNowButton: UIButton!
    @IBOutlet var UserName: UILabel!
    @IBOutlet var RecentScansTableView: UITableView!
   
    @IBOutlet var HomeImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        HomeImage.transform = CGAffineTransform(rotationAngle: .pi*1.845)
        collectionView.delegate = self
        RecentScansTableView.delegate = self
        RecentScansTableView.dataSource = self
        
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        
        updateUserName()
        scanNowButtonUI()
        noRecentScansLabel.isHidden = true
        
    }
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchRecentScans {
                // Adjust the HomeHeight after the data has been fetched and the table view is updated
                self.HomeHeight.constant = CGFloat(min(recentScansProducts.count,4) * 75 + 750)
            }
        updateUserName()
       
    }
    
    func updateUserName() {
        guard let userId = Auth.auth().currentUser?.uid else {
            UserName.text = "Hi, Guest"
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                self.UserName.text = "Hi, Guest"
                return
            }

            guard let document = document, document.exists,
                  let fullName = document.data()?["name"] as? String else {
                print("No username found for user.")
                self.UserName.text = "Hi, Guest"
                return
            }

            let firstName = fullName.components(separatedBy: " ").first ?? fullName
            self.UserName.text = "Hi, \(firstName)"
        }
    }

    
    func scanNowButtonUI() {
        
        
        ScanNowButton.layer.borderWidth=4
        ScanNowButton.layer.borderColor=UIColor(red: 254/255, green: 231/255, blue: 206/255, alpha:0.8).cgColor
        ScanNowButton.layer.masksToBounds = true
    }
    
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sampleUser.picksforyou.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickforyouCell", for: indexPath) as! HomePickForYouCell
        let pick = sampleUser.picksforyou[indexPath.row]
        cell.pickImage.image = UIImage(named: pick.imageURL)
        cell.picktitle.text = pick.name
        cell.pickcategory.text = getCategoryName(for: pick.categoryId)
        
        cell.pickscoreLabel.text = "\(pick.healthScore)"
        
        cell.pickview.layer.cornerRadius = cell.pickview.frame.height/2
        
        if pick.healthScore < 40 {
            cell.pickview.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if pick.healthScore < 75 {
            
            cell.pickview.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if pick.healthScore <= 100 {
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
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.orthogonalScrollingBehavior = .continuous
            return section
            
            
        }
        
        return layout
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(recentScansProducts.count,4)
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentScansCell", for: indexPath) as! RecentScansCell
        let product = recentScansProducts[indexPath.row]
        if let url = URL(string: product.imageURL) {
            cell.ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product"))
        } else {
            cell.ProductImage.image = UIImage(named: "placeholder_product")
        }

        cell.ProductName.text = product.name
        cell.ProductScore.text = "\(product.healthScore)"
        cell.ProductScoreView.layer.cornerRadius = cell.ProductScoreView.frame.height/2
        
        if product.healthScore < 40 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if product.healthScore < 75 {
            
            cell.ProductScoreView.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if product.healthScore <= 100 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.layer.cornerRadius = 8
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    // MARK: - Table View Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedProductDetails = recentScansProducts[indexPath.row]
            
            // Find the product in sampleProducts based on the name
            if let selectedProduct = sampleProducts.first(where: { $0.name == selectedProductDetails.name }) {
                performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct)
            } else {
                print("Product not found in sampleProducts for name: \(selectedProductDetails.name)")
            }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let verticalPadding: CGFloat = 4
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding/2)
        cell.layer.mask = maskLayer
    }
    
    
    func getCategoryName(for categoryId: UUID) -> String {
        if let category = Categories.first(where: { $0.id == categoryId }) {
            return category.name
        }
        return "Unknown Category"
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showproductdetailsfromhome",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let selectedProduct = sender as? ProductData {
            destinationVC.product = selectedProduct
        }
        
    }
    
    // MARK: - Collection View Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedProduct = sampleUser.picksforyou[indexPath.row]
        
        performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct)
    }
    
    func fetchRecentScans(completion: @escaping () -> Void){
        // Adjust the table height based on the number of items
      

        let db = Firestore.firestore()
        
        // Check if the user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            // User is logged in, fetch recent scans from Firestore
            let userRef = db.collection("users").document(userId)
            
            userRef.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching user document: \(error)")
                    return
                }
                
                // Ensure the document exists
                guard let document = document, document.exists else {
                    print("User document does not exist.")
                    self.toggleTableViewVisibility(isEmpty: true)
                    completion()
                    return
                }
                
                // Fetch the recentScans field (assuming it's an array of product IDs)
                if let recentScans = document.data()?["recentScans"] as? [String], !recentScans.isEmpty {
                    self.fetchProductsDetails(from: recentScans, completion: completion)
                    self.toggleTableViewVisibility(isEmpty: false)
                } else {
                    print("No recent scans found for this user.")
                    self.toggleTableViewVisibility(isEmpty: true)
                    completion()
                }
            }
        } else {
            // User is not logged in, fetch recent scans from local storage
            if let localRecentScans = UserDefaults.standard.array(forKey: "localRecentScans") as? [String], !localRecentScans.isEmpty {
                print("Fetching recent scans from local storage.")
                self.fetchProductsDetails(from: localRecentScans, completion: completion)
                self.toggleTableViewVisibility(isEmpty: false)
            } else {
                print("No recent scans found in local storage.")
                self.toggleTableViewVisibility(isEmpty: true)
                completion()
            }
        }
    }

    func toggleTableViewVisibility(isEmpty: Bool) {
        if isEmpty {
            RecentScansTableView.isHidden = true
            noRecentScansLabel.isHidden = false
            recentScansSeeAll.isHidden = true// Show the label
        } else {
            RecentScansTableView.isHidden = false
            noRecentScansLabel.isHidden = true
            recentScansSeeAll.isHidden = false// Hide the label
        }
    }
    
    func fetchProductsDetails(from productIDs: [String], completion: @escaping () -> Void)  {
        let db = Firestore.firestore()
        
        // Create an empty array to store the products' details
        var productsDetails: [(name: String, healthScore: Int, imageURL: String)] = []
        
        // Loop through the product IDs and fetch the details for each product
        let dispatchGroup = DispatchGroup()
        
        for productId in productIDs {
            dispatchGroup.enter()
            let productRef = db.collection("products").document(productId)
            
            productRef.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching product document: \(error)")
                } else {
                    // Ensure the document exists
                    guard let document = document, document.exists else {
                        print("Product document does not exist for ID: \(productId)")
                        dispatchGroup.leave()
                        return
                    }
                    
                    // Extract necessary fields (name, score, and imageURL)
                    if let name = document.data()?["name"] as? String,
                       let healthScore = document.data()?["healthScore"] as? Int,
                       let imageURL = document.data()?["imageURL"] as? String {
                        // Append the product details to the array
                        productsDetails.append((name: name, healthScore: healthScore, imageURL: imageURL))
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        // Once all product details are fetched, update the table view
        dispatchGroup.notify(queue: .main) {
            recentScansProducts = productsDetails
            self.RecentScansTableView.reloadData()
            completion()
        }
    }
}
        

