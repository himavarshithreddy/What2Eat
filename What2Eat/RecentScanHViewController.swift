import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage
import CoreData

class RecentScanHViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var recentScanTableView: UITableView!
    
    var recentScansProducts: [(id: String, name: String, healthScore: Int, imageURL: String, type: String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recentScanTableView.dataSource = self
        recentScanTableView.delegate = self
        
        // Fetch recent scans
        fetchRecentScans()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchRecentScans() // Refresh on reappearance
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
        
        // Set health score color
        if product.healthScore < 40 {
            cell.recentScanCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.recentScanCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else if product.healthScore <= 100 {
            cell.recentScanCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        // Load product image based on type
        if product.type == "barcode", let url = URL(string: product.imageURL) {
            cell.recentScanImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
        } else if product.type == "label" {
            if let imageData = CoreDataManager.shared.fetchLabelProduct(by: product.id)?.imageData,
               let image = UIImage(data: imageData) {
                cell.recentScanImage.image = image
            } else {
                cell.recentScanImage.image = UIImage(named: "placeholder_product_nobg")
            }
        } else {
            cell.recentScanImage.image = UIImage(named: "placeholder_product_nobg")
        }
        
        cell.layer.cornerRadius = 8
        return cell
    }
    
    // MARK: - Fetching Recent Scans
    
    func fetchRecentScans() {
        let recentScans = ScanManager.getRecentScans()
        if !recentScans.isEmpty {
            print("Fetching recent scans from local storage.")
            fetchProductsDetails(from: recentScans)
        } else {
            print("No recent scans found in local storage.")
            recentScansProducts.removeAll()
            recentScanTableView.reloadData()
        }
    }
    
    func fetchProductsDetails(from scans: [[String: Any]]) {
        let dispatchGroup = DispatchGroup()
        recentScansProducts.removeAll()
        
        for scan in scans {
            guard let type = scan["type"] as? String, let id = scan["id"] as? String else { continue }
            dispatchGroup.enter()
            
            if type == "barcode" {
                fetchProductDetailsFromFirebase(productId: id) { product in
                    if let product = product {
                        self.recentScansProducts.append((id: product.id, name: product.name, healthScore: product.healthScore, imageURL: product.imageURL, type: "barcode"))
                    }
                    dispatchGroup.leave()
                }
            } else if type == "label" {
                fetchLabelProductDetailsFromCoreData(labelId: id) { product in
                    if let product = product {
                        self.recentScansProducts.append(product)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
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
                completion((id: productId, name: name, healthScore: healthScore, imageURL: imageURL))
            } else {
                print("Error fetching product details for \(productId): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    func fetchLabelProductDetailsFromCoreData(labelId: String, completion: @escaping ((id: String, name: String, healthScore: Int, imageURL: String, type: String)?) -> Void) {
        if let labelProduct = CoreDataManager.shared.fetchLabelProduct(by: labelId) {
            let name = labelProduct.name ?? "Unnamed Product"
            let healthScore = Int(labelProduct.healthScore)
            let imageURL = "" // No Firebase URL; image is in Core Data
            completion((id: labelId, name: name, healthScore: healthScore, imageURL: imageURL, type: "label"))
        } else {
            print("Label product not found in Core Data for ID: \(labelId)")
            completion(nil)
        }
    }
    
    // MARK: - Delete Recent Scans
    
    @IBAction func DeleteRecentScans(_ sender: Any) {
        let alertController = UIAlertController(title: "Confirm Deletion",
                                                message: "Are you sure you want to delete all recent scans? This will not affect saved products.",
                                                preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete All", style: .destructive) { _ in
            ScanManager.clearRecentScans()
            self.recentScansProducts.removeAll()
            self.recentScanTableView.reloadData()
            self.navigationController?.popViewController(animated: true)
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
        if selectedProduct.type == "barcode" {
            performSegue(withIdentifier: "showproductdetailsfromrecentscans", sender: selectedProduct.id)
        } else if selectedProduct.type == "label" {
            performSegue(withIdentifier: "showLabelScanDetailsFromRecent", sender: selectedProduct.id)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showproductdetailsfromrecentscans",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let productId = sender as? String {
            destinationVC.productId = productId
        } else if segue.identifier == "showLabelScanDetailsFromRecent",
                  let destinationVC = segue.destination as? LabelScanDetailsViewController,
                  let labelScanId = sender as? String {
            if let labelProduct = CoreDataManager.shared.fetchLabelProduct(by: labelScanId) {
                destinationVC.productId = labelScanId
                destinationVC.productModel = ProductResponse(
                    id: labelScanId,
                    name: labelProduct.name ?? "",
                    ingredients: (try? JSONDecoder().decode([String].self, from: labelProduct.ingredients ?? Data())) ?? [],
                    nutrition: (try? JSONDecoder().decode([Nutrition].self, from: labelProduct.nutrition ?? Data())) ?? [],
                    healthscore: HealthScore(Energy: "0", Sugars: "0", Sodium: "0", Protein: "0", Fiber: "0", FruitsVegetablesNuts: "0", SaturatedFat: "0") // Placeholder
                )
                destinationVC.healthScore = Int(labelProduct.healthScore)
                destinationVC.capturedImage = labelProduct.imageData.flatMap { UIImage(data: $0) }
                destinationVC.productAnalysis = try? JSONDecoder().decode(ProductAnalysis.self, from: labelProduct.analysis ?? Data())
            }
        }
    }
    
    // MARK: - Editing (Delete Row)
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let removedProduct = recentScansProducts[indexPath.row]
            recentScansProducts.remove(at: indexPath.row)
            
            // Remove from recent scans using ScanManager
            ScanManager.deleteFromRecentScans(id: removedProduct.id)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - Core Data Manager Extension

