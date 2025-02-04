import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class ProductDetailsViewController: UIViewController {
    var product: ProductData? {
        didSet {
            // Whenever the product is updated, pass it on to the child view controllers if available.
            if let product = product {
                summaryVC?.updateWithProduct(product)
                ingredientsVC?.updateWithProduct(product)
//                nutritionVC?.updateWithProduct(product)
            }
        }
    }
   
    var productId: String?
    private var isSaved: Bool {
        return false
    }
    
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var SummarySegmentView: UIView!
    @IBOutlet var ProductImage: UIImageView!
    @IBOutlet var ProductName: UILabel!
    @IBOutlet weak var IngredientsSegmentView: UIView!
    @IBOutlet weak var NutritionSegmentView: UIView!
    
    private var progressLayer: CAShapeLayer!
    
    // Weak references to embedded child view controllers
    weak var summaryVC: SummaryViewController?
    weak var ingredientsVC: IngredientsViewController?
    weak var nutritionVC: NutritionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let productId = productId else {
            print("❌ No productId found!")
            return
        }
        print("🔍 Fetching product for ID: \(productId)")
        
        // Fetch product details asynchronously
        fetchProductDetails(productId: productId) { [weak self] fetchedProduct in
            guard let self = self, let fetchedProduct = fetchedProduct else {
                print("❌ Failed to fetch product for ID: \(productId)")
                return
            }
            
            self.product = fetchedProduct
            print("✅ Fetched product: \(fetchedProduct)")
            
            DispatchQueue.main.async {
                self.setupProductDetails()
                self.setProgress(to: CGFloat(fetchedProduct.healthScore) / 100)
                self.view.bringSubviewToFront(self.SummarySegmentView)
              
                // Explicitly update the child view controllers if they are already loaded.
                self.summaryVC?.updateWithProduct(fetchedProduct)
                self.ingredientsVC?.updateWithProduct(fetchedProduct)
//                self.nutritionVC?.updateWithProduct(fetchedProduct)
            }
        }
        
        setupCircularProgressBar()
        
        let bookmarkButton = UIBarButtonItem(
            image: UIImage(systemName: isSaved ? "bookmark.fill" : "bookmark"),
            style: .plain,
            target: self,
            action: #selector(SavedButtonTapped(_:))
        )
        bookmarkButton.tintColor = .systemOrange
        navigationItem.rightBarButtonItem = bookmarkButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductSavedNotification(_:)), name: Notification.Name("ProductSaved"), object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Detect embedded segues and store references so we can update them later.
        if segue.identifier == "showSummary",
           let vc = segue.destination as? SummaryViewController {
            summaryVC = vc
            // Update immediately if product is already available
            if let product = product { vc.updateWithProduct(product) }
        } else if segue.identifier == "showIngredients",
                  
                  let vc = segue.destination as? IngredientsViewController {
            
            ingredientsVC = vc
            if let product = product { vc.updateWithProduct(product) }
        } else if segue.identifier == "showNutrition",
                  let vc = segue.destination as? NutritionViewController {
            nutritionVC = vc
//            if let product = product { vc.updateWithProduct(product) }
        } else if segue.identifier == "Createnewlist",
                  let navigationController = segue.destination as? UINavigationController,
                  let newListVC = navigationController.topViewController as? NewListViewController {
            newListVC.product = product
        }
    }
    
    // MARK: - Segmented Control Action
    
    @IBAction func SegmentAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.view.bringSubviewToFront(SummarySegmentView)
        case 1:
            self.view.bringSubviewToFront(IngredientsSegmentView)
        case 2:
            self.view.bringSubviewToFront(NutritionSegmentView)
        default:
            break
        }
    }
    
    // MARK: - Notification Handling
    
    @objc private func handleProductSavedNotification(_ notification: Notification) {
        guard let savedProduct = notification.object as? ProductData else { return }
        if savedProduct.id == product?.id {
            updateBookmarkIcon(for: navigationItem.rightBarButtonItem!)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ProductSaved"), object: nil)
    }
    
    // MARK: - Circular Progress Setup
    
    private func setupCircularProgressBar() {
        let center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        let radius = progressView.bounds.width / 2
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius - 18,
            startAngle: -CGFloat.pi / 2,
            endAngle: 1.5 * CGFloat.pi,
            clockwise: true
        )
        
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.path = circularPath.cgPath
        backgroundLayer.strokeColor = UIColor.white.cgColor
        backgroundLayer.lineWidth = 17
        backgroundLayer.fillColor = UIColor.clear.cgColor
        progressView.layer.addSublayer(backgroundLayer)
        
        progressLayer = CAShapeLayer()
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor.orange.cgColor
        progressLayer.lineWidth = 17
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        progressView.layer.addSublayer(progressLayer)
    }
    
    func setProgress(to progress: CGFloat, animated: Bool = true) {
        let clampedProgress = min(max(progress, 0), 1)
        progressLayer.strokeEnd = clampedProgress
        let percentage = Int(clampedProgress * 100)
        progressLabel.text = "\(percentage)"
        if let product = product {
            if product.healthScore < 40 {
                progressLabel.textColor = .systemRed
                progressLayer.strokeColor = UIColor.systemRed.cgColor
            } else if product.healthScore < 75 {
                progressLayer.strokeColor = UIColor.orange.cgColor
                progressLabel.textColor = .systemOrange
            } else {
                progressLayer.strokeColor = UIColor.systemGreen.cgColor
                progressLabel.textColor = .systemGreen
            }
        }
    }
    
    // MARK: - Bookmark Actions
    
    @IBAction func SavedButtonTapped(_ sender: UIBarButtonItem) {
        guard let product = product else {
            print("No product to save or unsave")
            return
        }
        
        if isSaved {
            removeProductFromAllLists(product)
            NotificationCenter.default.post(name: Notification.Name("ProductUnsaved"), object: product)
            print("\(product.name) removed from lists")
        } else {
            let actionSheet = UIAlertController(title: "Select a List to add to", message: nil, preferredStyle: .actionSheet)
            for (index, list) in sampleLists.enumerated() {
                let action = UIAlertAction(title: list.name, style: .default) { _ in
                    self.addProductToList(at: index, product: product)
                    NotificationCenter.default.post(name: Notification.Name("ProductSaved"), object: product)
                    self.updateBookmarkIcon(for: sender)
                }
                actionSheet.addAction(action)
                action.setValue(UIColor.systemOrange, forKey: "titleTextColor")
            }
            let newListAction = UIAlertAction(title: "New List", style: .default) { _ in
                self.performSegue(withIdentifier: "Createnewlist", sender: self)
            }
            newListAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
            actionSheet.addAction(newListAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(cancelAction)
            cancelAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
            present(actionSheet, animated: true, completion: nil)
            return
        }
        
        updateBookmarkIcon(for: sender)
    }
    
    private func addProductToList(at index: Int, product: ProductData) {
        guard sampleLists.indices.contains(index) else {
            print("Invalid list index")
            return
        }
        if sampleLists[index].products.contains(where: { $0.id == product.id }) {
            print("\(product.name) is already in the list \(sampleLists[index].name)")
            return
        }
        sampleLists[index].products.append(product)
        print("\(product.name) added to \(sampleLists[index].name)")
    }
    
    private func removeProductFromAllLists(_ product: ProductData) {
        for (index, list) in sampleLists.enumerated() {
            if let productIndex = list.products.firstIndex(where: { $0.id == product.id }) {
                sampleLists[index].products.remove(at: productIndex)
            }
        }
    }
    
    private func isProductInAnyList(_ product: ProductData) -> Bool {
        return sampleLists.contains { list in
            list.products.contains { $0.id == product.id }
        }
    }
    
    @objc private func updateBookmarkIcon(for button: UIBarButtonItem) {
        let iconName = isSaved ? "bookmark.fill" : "bookmark"
        button.image = UIImage(systemName: iconName)
    }
    
    // MARK: - Product Details UI Setup
    
    private func setupProductDetails() {
        if let product = product {
            ProductName.text = product.name
            if let url = URL(string: product.imageURL) {
                        ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product"))
                    } else {
                        // Fallback: if the URL is invalid, try to load from assets
                        ProductImage.image = UIImage(named:"placeholder_product")
                    }
        }
    }
    
    // MARK: - Fetch Product Details
    
    func fetchProductDetails(productId: String, completion: @escaping (ProductData?) -> Void) {
        let db = Firestore.firestore()
        db.collection("products").document(productId).getDocument(source: .default) { (document, error) in
            if let error = error {
                print("❌ Error fetching product details: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                print("✅ Product Details Fetched: \(data)")
                
                // Extract data from Firestore
                let name = data["name"] as? String ?? "Unknown"
                let barcode = data["barcode"] as? String ?? ""
                let imageURL = data["imageURL"] as? String ?? ""
                let ingredients = data["ingredients"] as? [String] ?? []
                let artificialIngredients = data["artificialIngredients"] as? [String] ?? []
                
                // Filter out empty strings from pros and cons arrays
                let pros = (data["pros"] as? [String] ?? []).filter { !$0.isEmpty }
                let cons = (data["cons"] as? [String] ?? []).filter { !$0.isEmpty }
                
                let userRating = data["userRating"] as? Float ?? 0.0
                let numberOfRatings = data["numberOfRatings"] as? Int ?? 0
                let categoryId = data["categoryId"] as? String ?? ""
                let healthScore = data["healthScore"] as? Double ?? 0.0
                let nutritionInfo = data["nutritionInfo"] as? [String: String] ?? [:]
                
                // Create the ProductData object, ensuring pros and cons are always arrays (empty if needed)
                let fetchedProduct = ProductData(
                    id: productId,
                    barcode: barcode,
                    name: name,
                    imageURL: imageURL,
                    ingredients: ingredients,
                    artificialIngredients: artificialIngredients,
                    nutritionInfo: nutritionInfo,
                    userRating: userRating,
                    numberOfRatings: numberOfRatings,
                    categoryId: categoryId,
                    pros: pros.isEmpty ? [] : pros,  // Use an empty array if no pros
                    cons: cons.isEmpty ? [] : cons,  // Use an empty array if no cons
                    healthScore: healthScore
                )
                self.product = fetchedProduct
                completion(fetchedProduct)
            } else {
                print("⚠️ No product found with ID: \(productId)")
                completion(nil)
            }
        }
    }


}
