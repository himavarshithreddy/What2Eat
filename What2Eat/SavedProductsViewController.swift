import UIKit
import FirebaseFirestore
import FirebaseAuth

class SavedProductsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    @IBOutlet weak var SavedProductsTableView: UITableView!
    
    // Passed from SavedViewController
    var listId: String?
    struct SavedProduct {
        let id: String
        let name: String
        let healthScore: Double
        let imageURL: String
    }

    // Local array to hold fetched products
    var products: [SavedProduct] = []
    
    let db = Firestore.firestore()
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SavedProductsTableView.delegate = self
        SavedProductsTableView.dataSource = self
        
        // Get the logged-in user ID
        if let currentUser = Auth.auth().currentUser {
            userId = currentUser.uid
        } else {
            print("User not logged in")
        }
        
        // Use the listId to fetch the saved list details and then its products
        if let listId = listId {
            fetchSavedListAndProducts(for: listId)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProductChange(_:)),
            name: Notification.Name("ProductUnsaved"),
            object: nil
        )
    }
    
    // Fetch the saved list (from the user's document) using the listId,
    // then extract its product IDs and fetch the corresponding product details.
    func fetchSavedListAndProducts(for listId: String) {
        guard let userId = userId else { return }
        let userDocRef = db.collection("users").document(userId)
        userDocRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            guard let data = snapshot?.data(),
                  let lists = data["savedLists"] as? [[String: Any]] else {
                print("No saved lists found")
                return
            }
            
            // Find the saved list with the matching listId
            if let savedListDict = lists.first(where: { ($0["listId"] as? String) == listId }) {
                // Optionally, update the navigation title using the list's name
                if let listName = savedListDict["name"] as? String {
                    self.navigationItem.title = listName
                }
                // Extract the product IDs array (make sure your Firestore saved list contains this field)
                if let productIds = savedListDict["products"] as? [String], !productIds.isEmpty {
                    self.fetchProducts(with: productIds)
                } else {
                    print("No products saved in this list")
                    self.products = []
                    self.SavedProductsTableView.reloadData()
                }
            } else {
                print("Saved list not found")
            }
        }
    }
    
    // Fetch products from the "products" collection using an "in" query.
    // We use the .selectFields method to fetch only the required fields.
    func fetchProducts(with productIds: [String]) {
        // Note: The "in" query supports a maximum of 10 elements. For more, consider batching.
        db.collection("products")
            .whereField(FieldPath.documentID(), in: productIds)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching products: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                self.products = documents.compactMap { doc in
                    let data = doc.data()
                    let id = doc.documentID
                    guard let name = data["name"] as? String,
                          let healthScore = data["healthScore"] as? Double,
                          let imageURL = data["imageURL"] as? String else {
                        return nil
                    }
                    return SavedProduct(id: id, name: name, healthScore: healthScore, imageURL: imageURL)
                }
                
                DispatchQueue.main.async {
                    self.SavedProductsTableView.reloadData()
                }
            }

    }
    
    // Handles any change (e.g., unsaving a product) by removing it locally.
    @objc func handleProductChange(_ notification: Notification) {
        if let unsavedProduct = notification.object as? SavedProduct {
            self.products.removeAll { $0.id == unsavedProduct.id }
            self.SavedProductsTableView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - TableView Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedProductsCell", for: indexPath) as! SavedProductsCell
        
        let product = products[indexPath.row]
        
        // Set score circle background color based on healthScore
        if product.healthScore < 40 {
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.ScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else if product.healthScore < 100 {
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        cell.SavedProductsName.text = product.name
        
        if let url = URL(string: product.imageURL) {
            cell.SavedProductsImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product"))
        } else {
            cell.SavedProductsImage.image = UIImage(named: "placeholder_product")
        }
        cell.Scoretext.text = String(Int(product.healthScore))
        cell.ScoreCircle.layer.cornerRadius = 20
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // When a product is selected, pass its id to the product details screen.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = products[indexPath.row]
        performSegue(withIdentifier: "showProductDetailsfromSaved", sender: selectedProduct)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProductDetailsfromSaved",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let selectedProduct = sender as? SavedProduct {
            // Pass just the product id.
            destinationVC.productId = selectedProduct.id
        }
    }
}
