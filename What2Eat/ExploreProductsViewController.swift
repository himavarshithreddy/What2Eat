import UIKit
import FirebaseFirestore
import SDWebImage

class ExploreProductsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let db = Firestore.firestore()
    var categoryId: String?
    var filteredProducts: [ProductList] = [] // Directly storing products here

    @IBOutlet weak var ExploreProductsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ExploreProductsTableView.delegate = self
        ExploreProductsTableView.dataSource = self
        
        fetchProductsForCategory()
    }
    
    func fetchProductsForCategory() {
        guard let categoryId = categoryId else {
            print("❌ Category ID not found")
            return
        }
        
        db.collection("products")
            .whereField("categoryId", isEqualTo: categoryId)
            .getDocuments(source: .default) { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching products: \(error.localizedDescription)")
                    return
                }
                
                self.filteredProducts = [] // Clear previous results
                
                querySnapshot?.documents.forEach { document in
                    let data = document.data()
                    
                    if let name = data["name"] as? String,
                       let imageUrl = data["imageURL"] as? String,
                       let healthScore = data["healthScore"] as? Int {
                        let productId = document.documentID
                        
                        let product = ProductList(id: productId,name: name, healthScore: healthScore, imageURL: imageUrl)
                        self.filteredProducts.append(product)
                    }
                }
                
                print("✅ Products in category \(categoryId): \(self.filteredProducts)")
                
                // Refresh UI
                DispatchQueue.main.async {
                    self.ExploreProductsTableView.reloadData()
                }
            }
    }
    
    // MARK: - TableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreProductsCell", for: indexPath) as! ExploreProductsCell
        let product = filteredProducts[indexPath.row]
        
        // Set Health Score Circle Color
        if product.healthScore < 40 {
            cell.ExploreScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.ExploreScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else {
            cell.ExploreScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        cell.ExploreProductsName.text = product.name
        cell.ExploreScoretext.text = String(product.healthScore)
        cell.ExploreScoreCircle.layer.cornerRadius = 20
        
        // Load image using SDWebImage
        if let imageUrl = URL(string: product.imageURL) {
            cell.ExploreProductsImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_product"))
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProductId = filteredProducts[indexPath.row].id
        performSegue(withIdentifier: "showProductDetails", sender: selectedProductId)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showProductDetails",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let productId = sender as? String {
            destinationVC.productId = productId
        }
    }
}


