//
//  SearchResultsViewController.swift
//  What2Eat
//
//  Created by admin68 on 15/12/24.
//

import UIKit
import FirebaseFirestore

class SearchResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var productIDs: [String]?  // Received from SearchViewController
    var searchResults: [(id: String, name: String, imageURL: String, healthScore: Int)] = []
    
    @IBOutlet var SearchResultsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SearchResultsTableView.delegate = self
        SearchResultsTableView.dataSource = self
        
        if let productIDs = productIDs {
            fetchProductsFromFirestore(productIDs: productIDs)
        }
    }
    
    // MARK: - Fetch Product Details from Firestore
    // MARK: - Fetch Product Details from Firestore
    func fetchProductsFromFirestore(productIDs: [String]) {
        let db = Firestore.firestore()
        let productRef = db.collection("products")
        
        // Clear existing search results
        searchResults.removeAll()
        
        for productID in productIDs {
            productRef.document(productID).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching product \(productID): \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data() {
                    let name = data["name"] as? String ?? "Unknown"
                    let imageURL = data["imageURL"] as? String ?? ""
                    let healthScore = data["healthScore"] as? Int ?? 0
                    
                    let product = (id: productID, name: name, imageURL: imageURL, healthScore: healthScore)
                    
                    DispatchQueue.main.async {
                        self.searchResults.append(product)
                        
                        // Sort the results based on health score (highest first)
                        self.searchResults.sort { $0.healthScore > $1.healthScore }
                        
                        // Reload the table view to reflect the sorted results
                        self.SearchResultsTableView.reloadData()
                    }
                }
            }
        }
    }

    // MARK: - TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsTableViewCell", for: indexPath) as! SearchResultsTableViewCell
        let product = searchResults[indexPath.row]
        
        // Configure cell with fetched product data
        cell.ProductName.text = product.name
        cell.ProductScore.text = String(product.healthScore)
        
        if let url = URL(string: product.imageURL) {
            cell.ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
                } else {
                    // Fallback: if the URL is invalid, try to load from assets
                    cell.ProductImage.image = UIImage(named:"placeholder_product_nobg")
                }
        
        // Set health score color
        if product.healthScore < 40 {
            cell.ProductCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.ProductCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else {
            cell.ProductCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        cell.ProductCircle.layer.cornerRadius = 20
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // MARK: - Product Selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProductID = searchResults[indexPath.row].id
        performSegue(withIdentifier: "showproductfromresults", sender: selectedProductID)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showproductfromresults",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let productID = sender as? String {
            destinationVC.productId = productID  // Pass only productID
        }
    }
}
