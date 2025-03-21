import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreData

class SavedProductsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var SavedProductsTableView: UITableView!
    
    var listId: String?
    
    struct SavedProduct {
        let id: String
        let name: String
        let healthScore: Double
        let imageURL: String?
        let imageData: Data?
        let isFromCoreData: Bool // Added to distinguish source
        
        // Initializer for Firebase products
        init(id: String, name: String, healthScore: Double, imageURL: String) {
            self.id = id
            self.name = name
            self.healthScore = healthScore
            self.imageURL = imageURL
            self.imageData = nil
            self.isFromCoreData = false
        }
        
        // Initializer for Core Data products
        init(id: String, name: String, healthScore: Double, imageData: Data) {
            self.id = id
            self.name = name
            self.healthScore = healthScore
            self.imageURL = nil
            self.imageData = imageData
            self.isFromCoreData = true
        }
    }
    
    var products: [SavedProduct] = []
    let db = Firestore.firestore()
    var userId: String?
    
    private let context = CoreDataManager.shared.context
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SavedProductsTableView.delegate = self
        SavedProductsTableView.dataSource = self
        
        if let currentUser = Auth.auth().currentUser {
            userId = currentUser.uid
        } else {
            print("User not logged in")
        }
        
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
            
            if let savedListDict = lists.first(where: { ($0["listId"] as? String) == listId }) {
                if let listName = savedListDict["name"] as? String {
                    self.navigationItem.title = listName
                }
                if let productIds = savedListDict["products"] as? [String], !productIds.isEmpty {
                    self.fetchProductsAndScans(with: productIds)
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
    
    func fetchProductsAndScans(with productIds: [String]) {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", productIds)
        
        do {
            let coreDataProducts = try context.fetch(fetchRequest)
            let coreDataSavedProducts = coreDataProducts.map { product in
                SavedProduct(
                    id: product.id ?? "",
                    name: product.name ?? "Unknown",
                    healthScore: Double(product.healthScore),
                    imageData: product.imageData ?? Data()
                )
            }
            
            let coreDataIds = Set(coreDataProducts.compactMap { $0.id })
            let remainingIds = productIds.filter { !coreDataIds.contains($0) }
            
            if !remainingIds.isEmpty {
                db.collection("products")
                    .whereField(FieldPath.documentID(), in: remainingIds)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error fetching products: \(error)")
                            return
                        }
                        guard let documents = snapshot?.documents else { return }
                        
                        let firebaseProducts = documents.compactMap { doc -> SavedProduct? in
                            let data = doc.data()
                            let id = doc.documentID
                            guard let name = data["name"] as? String,
                                  let healthScore = data["healthScore"] as? Double,
                                  let imageURL = data["imageURL"] as? String else {
                                return nil
                            }
                            return SavedProduct(id: id, name: name, healthScore: healthScore, imageURL: imageURL)
                        }
                        
                        self.products = coreDataSavedProducts + firebaseProducts
                        DispatchQueue.main.async {
                            self.SavedProductsTableView.reloadData()
                        }
                    }
            } else {
                self.products = coreDataSavedProducts
                DispatchQueue.main.async {
                    self.SavedProductsTableView.reloadData()
                }
            }
        } catch {
            print("Error fetching Core Data products: \(error)")
            fetchProducts(with: productIds)
        }
    }
    
    func fetchProducts(with productIds: [String]) {
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
        
        if product.healthScore < 40 {
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.ScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else {
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        cell.SavedProductsName.text = product.name
        cell.Scoretext.text = String(Int(product.healthScore))
        cell.ScoreCircle.layer.cornerRadius = 20
        
        if let imageData = product.imageData, !imageData.isEmpty {
            cell.SavedProductsImage.image = UIImage(data: imageData)
        } else if let urlString = product.imageURL, let url = URL(string: urlString) {
            cell.SavedProductsImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
        } else {
            cell.SavedProductsImage.image = UIImage(named: "placeholder_product_nobg")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = products[indexPath.row]
        if selectedProduct.isFromCoreData {
            performSegue(withIdentifier: "showLabelScanDetailsFromSaved", sender: selectedProduct)
        } else {
            performSegue(withIdentifier: "showProductDetailsfromSaved", sender: selectedProduct)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showProductDetailsfromSaved",
               let destinationVC = segue.destination as? ProductDetailsViewController,
               let selectedProduct = sender as? SavedProduct {
                destinationVC.productId = selectedProduct.id
            } else if segue.identifier == "showLabelScanDetailsFromSaved",
                      let destinationVC = segue.destination as? LabelScanDetailsViewController,
                      let selectedProduct = sender as? SavedProduct {
                // Fetch full Core Data product
                let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", selectedProduct.id)
                fetchRequest.fetchLimit = 1
                
                do {
                    if let coreDataProduct = try context.fetch(fetchRequest).first {
                        // Construct ProductResponse without id (matching ScanWithLabelViewController’s initial pass)
                        let productResponse = ProductResponse(
                            id:coreDataProduct.id ?? "Unknown",
                            name: coreDataProduct.name ?? "Unknown",
                            ingredients: (try? JSONDecoder().decode([String].self, from: coreDataProduct.ingredients ?? Data())) ?? [],
                            nutrition: (try? JSONDecoder().decode([Nutrition].self, from: coreDataProduct.nutrition ?? Data())) ?? [],
                            healthscore: HealthScore(
                                 Energy: "0",
                                 Sugars:"0",
                                 Sodium: "0",
                                 Protein: "0",
                                 Fiber: "0",
                                 FruitsVegetablesNuts: "0",
                                 SaturatedFat:  "0"
                             )
                        )
                        
                        // Set properties matching ScanWithLabelViewController’s navigateToDetailsViewController
                        destinationVC.productModel = productResponse
                        destinationVC.healthScore = Int(coreDataProduct.healthScore)
                        
                        destinationVC.capturedImage = coreDataProduct.imageData != nil ? UIImage(data: coreDataProduct.imageData!) : nil
                        destinationVC.productId = selectedProduct.id // Set after saving, unlike initial scan
                        if let analysisData = coreDataProduct.analysis,
                                         let analysis = try? JSONDecoder().decode(ProductAnalysis.self, from: analysisData) {
                                          destinationVC.productAnalysis = analysis
                                      }
                    }
                } catch {
                    print("Error fetching Core Data product for segue: \(error)")
                }
            }
        }
}
