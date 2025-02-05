import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class RecentScanHViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var recentScanTableView: UITableView!
    
    
    var recentScansProducts: [(id: String, name: String, healthScore: Int, imageURL: String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recentScanTableView.dataSource = self
        recentScanTableView.delegate = self
        
        // Fetch product IDs from local storage and then fetch details from Firebase.
        fetchRecentScans()
    }
    
    // MARK: - Table View Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentScansProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentScansHCell", for: indexPath) as! RecentScanHTableViewCell
        
        let product = recentScansProducts[indexPath.row]
        
        // Configure cell labels
        cell.recentScanName.text = product.name
        cell.recentScanText.text = "\(product.healthScore)"
        cell.recentScanCircle.layer.cornerRadius = cell.recentScanCircle.frame.height / 2
        
        // Set health score color based on the value
        if product.healthScore < 40 {
            cell.recentScanCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.recentScanCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else if product.healthScore <= 100 {
            cell.recentScanCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        // Load product image from URL
        if let url = URL(string: product.imageURL) {
            cell.recentScanImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product"))
        } else {
            cell.recentScanImage.image = UIImage(named: "placeholder_product")
        }
        
        cell.layer.cornerRadius = 8
        return cell
    }
    
    // MARK: - Fetching Recent Scans from Local Storage & Firebase
    
    func fetchRecentScans() {
        // Fetch recent scans from local storage
        let recentScans = getRecentScans() // Get sorted scans based on index
        
        if !recentScans.isEmpty {
            print("Fetching recent scans from local storage.")
            self.fetchProductsDetails(from: recentScans)
            
        } else {
            print("No recent scans found in local storage.")
           
           
        }
    }
    private func getRecentScans() -> [String] {
        let defaults = UserDefaults.standard
        
        // Retrieve the scans
        guard var localScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] else {
            return []
        }
        
        // Forcefully sort scans based on timestamp in descending order
        // Ensure the most recent scan (highest timestamp) is first
        localScans.sort { (scan1, scan2) -> Bool in
            let timestamp1 = scan1["index"] as? TimeInterval ?? 0
            let timestamp2 = scan2["index"] as? TimeInterval ?? 0
            return timestamp1 > timestamp2
        }
        
        // Extract only the product IDs in sorted order
        let productIds = localScans.compactMap { $0["productId"] as? String }
        
        return productIds
    }
    
    func fetchProductsDetails(from productIDs: [String]) {
        let dispatchGroup = DispatchGroup()
        // Clear any existing products.
        recentScansProducts.removeAll()
        
        // Loop through each product ID and fetch its details from Firebase.
        for productId in productIDs {
            dispatchGroup.enter()
            fetchProductDetailsFromFirebase(productId: productId) { product in
                if let product = product {
                    self.recentScansProducts.append(product)
                }
                dispatchGroup.leave()
            }
        }
        
        // Once all products are fetched, reload the table view.
        dispatchGroup.notify(queue: .main) {
            self.recentScanTableView.reloadData()
        }
    }
    
    func fetchProductDetailsFromFirebase(productId: String, completion: @escaping ((id: String, name: String, healthScore: Int, imageURL: String)?) -> Void) {
        let db = Firestore.firestore()
        let productRef = db.collection("products").document(productId)
        
        productRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let name = data?["name"] as? String ?? "Unknown Product"
                let healthScore = data?["healthScore"] as? Int ?? 0
                let imageURL = data?["imageURL"] as? String ?? ""
                
                // Return the complete product details as a tuple.
                completion((id: productId, name: name, healthScore: healthScore, imageURL: imageURL))
            } else {
                print("Error fetching product details for \(productId): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    // MARK: - Delete Recent Scans
    
    @IBAction func DeleteRecentScans(_ sender: Any) {
        let alertController = UIAlertController(title: "Confirm Deletion",
                                                  message: "Are you sure you want to delete all recent scans?",
                                                  preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            // Remove the local storage entry and clear the current array.
            UserDefaults.standard.removeObject(forKey: "localRecentScans")
            self.recentScansProducts.removeAll()
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
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = recentScansProducts[indexPath.row]
        // Pass only the product ID to the product details view controller.
        performSegue(withIdentifier: "showproductdetailsfromrecentscans", sender: selectedProduct.id)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showproductdetailsfromrecentscans",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let productId = sender as? String {
            destinationVC.productId = productId
        }
    }
    
    // MARK: - Editing (Delete Row)
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let removedProduct = recentScansProducts[indexPath.row]
            recentScansProducts.remove(at: indexPath.row)
            
            // Update the stored product IDs in local storage.
            if var localRecentScans = UserDefaults.standard.array(forKey: "localRecentScans") as? [[String: Any]] {
                localRecentScans.removeAll { dict in
                    dict["productId"] as? String == removedProduct.id
                }
                UserDefaults.standard.set(localRecentScans, forKey: "localRecentScans")
                print("Product removed from local recent scans.")
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
