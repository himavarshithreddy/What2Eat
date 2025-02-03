//
//  RecentScanHViewController.swift
//  What2Eat
//
//  Created by admin20 on 21/01/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class RecentScanHViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var recentScanTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recentScanTableView.dataSource = self
        recentScanTableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recentScansProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentScansHCell", for: indexPath) as! RecentScanHTableViewCell
        let product = recentScansProducts[indexPath.row]
        cell.recentScanImage.image = UIImage(named: product.imageURL)
        cell.recentScanName.text = product.name
        cell.recentScanText.text = "\(product.healthScore)"
        cell.recentScanCircle.layer.cornerRadius = cell.recentScanCircle.frame.height/2
        
        if product.healthScore < 40 {
            cell.recentScanCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if product.healthScore < 75 {
            
            cell.recentScanCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if product.healthScore <= 100 {
            cell.recentScanCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.layer.cornerRadius = 8
        return cell
    }
    
    func fetchRecentScans() {
        
        
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
                    //
                    return
                }
                
                // Fetch the recentScans field (assuming it's an array of product IDs)
                if let recentScans = document.data()?["recentScans"] as? [String], !recentScans.isEmpty {
                    self.fetchProductsDetails(from: recentScans)
                    //
                } else {
                    print("No recent scans found for this user.")
                    //
                }
            }
        } else {
            
            if let localRecentScans = UserDefaults.standard.array(forKey: "localRecentScans") as? [String], !localRecentScans.isEmpty {
                print("Fetching recent scans from local storage.")
                self.fetchProductsDetails(from: localRecentScans)
                //
            } else {
                print("No recent scans found in local storage.")
                //
            }
        }
    }
    
    
    func fetchProductsDetails(from productIDs: [String]) {
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
            self.recentScanTableView.reloadData()
        }
    }
    @IBAction func DeleteRecentScans(_ sender: Any) {
         let alertController = UIAlertController(title: "Confirm Deletion",
                                                 message: "Are you sure you want to delete all recent scans?",
                                                 preferredStyle: .actionSheet)
         
         let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
             UserDefaults.standard.removeObject(forKey: "localRecentScans")
             recentScansProducts.removeAll()
             self.clearFirebaseRecentScans()
             self.recentScanTableView.reloadData()
         }
         
         let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
         
         alertController.addAction(deleteAction)
         alertController.addAction(cancelAction)
         
         if let popoverController = alertController.popoverPresentationController {
             popoverController.sourceView = self.view
             popoverController.sourceRect = (sender as! UIButton).frame
         }
         
         present(alertController, animated: true, completion: nil)
     }
    func clearFirebaseRecentScans() {
        // Get the Firestore reference
        let db = Firestore.firestore()
        
        // Check if the user is logged in
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User is not logged in. Cannot clear Firebase recent scans.")
            return
        }
        
        // Get a reference to the user's document
        let userRef = db.collection("users").document(userId)
        
        // Update the recentScans field to an empty array
        userRef.updateData(["recentScans": []]) { error in
            if let error = error {
                print("Error clearing recent scans in Firebase: \(error)")
            } else {
                print("Recent scans cleared successfully in Firebase.")
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedProductDetails = recentScansProducts[indexPath.row]
        if let selectedProduct = sampleProducts.first(where: { $0.name == selectedProductDetails.name }) {
            
            performSegue(withIdentifier: "showproductdetailsfromrecentscans", sender: selectedProduct)
            
        }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showproductdetailsfromrecentscans",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let selectedProduct = sender as? ProductData {
            destinationVC.product = selectedProduct
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
          if editingStyle == .delete {
              // Remove the product from the local array
              let removedProduct = recentScansProducts[indexPath.row]
              recentScansProducts.remove(at: indexPath.row)
              
              // Update Firestore or local storage based on the logged-in status
              if let userId = Auth.auth().currentUser?.uid {
                  removeProductFromFirebase(productName: removedProduct.name, userId: userId)
              } else {
                  removeProductFromLocalStorage(productName: removedProduct.name)
              }
              
              // Delete the row from the table view
              tableView.deleteRows(at: [indexPath], with: .fade)
          }
      }
    func removeProductFromFirebase(productName: String, userId: String) {
          let db = Firestore.firestore()
          let userRef = db.collection("users").document(userId)
          
          userRef.getDocument { (document, error) in
              if let error = error {
                  print("Error fetching user document: \(error)")
                  return
              }
              guard let document = document, document.exists else {
                  print("User document does not exist.")
                  return
              }
              if var recentScans = document.data()?["recentScans"] as? [String] {
                  recentScans.removeAll(where: { $0 == productName })
                  userRef.updateData(["recentScans": recentScans]) { error in
                      if let error = error {
                          print("Error updating recent scans in Firebase: \(error)")
                      } else {
                          print("Product removed from Firebase recent scans.")
                      }
                  }
              }
          }
      }
      
      // Remove the product from local storage
    func removeProductFromLocalStorage(productName: String) {
        if var localRecentScans = UserDefaults.standard.array(forKey: "localRecentScans") as? [String] {
            localRecentScans.removeAll(where: { $0 == productName })
            UserDefaults.standard.setValue(localRecentScans, forKey: "localRecentScans")
            print("Product removed from local recent scans.")
        }
    }
}
