import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

// Assuming your SavedList model is defined somewhere in your project:


class ProductDetailsViewController: UIViewController {
    var product: ProductData? {
        didSet {
            // Whenever the product is updated, pass it on to the child view controllers if available.
            if let product = product {
                summaryVC?.updateWithProduct(product)
                ingredientsVC?.updateWithProduct(product)
                nutritionVC?.updateWithProduct(product)
            }
        }
    }
    var cachedSavedProductIDs = Set<String>()

    var productId: String?
    
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
        updateBookmarkIcon()
        guard let productId = productId else {
            print("❌ No productId found!")
            return
        }
        print("🔍 Fetching product for ID: \(productId)")
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewListCreated(_:)), name: Notification.Name("NewListCreated"), object: nil)
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
              
                // Update child view controllers
                self.summaryVC?.updateWithProduct(fetchedProduct)
                self.ingredientsVC?.updateWithProduct(fetchedProduct)
                self.nutritionVC?.updateWithProduct(fetchedProduct)
            }
        }
        
        setupCircularProgressBar()
        
        let bookmarkButton = UIBarButtonItem(
            image: UIImage(systemName: "bookmark"),
            style: .plain,
            target: self,
            action: #selector(savedButtonTapped(_:))
        )
        bookmarkButton.tintColor = .systemOrange
        navigationItem.rightBarButtonItem = bookmarkButton
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserSavedLists { savedLists in
            var newCache = Set<String>()
            for list in savedLists {
                for prodId in list.products {
                    newCache.insert(prodId)
                }
            }
            self.cachedSavedProductIDs = newCache
            self.updateBookmarkIcon()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewListCreated(_:)), name: Notification.Name("NewListCreated"), object: nil)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateBookmarkIcon()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Detect embedded segues and store references so we can update them later.
        if segue.identifier == "showSummary",
           let vc = segue.destination as? SummaryViewController {
            summaryVC = vc
            if let product = product { vc.updateWithProduct(product) }
        } else if segue.identifier == "showIngredients",
                  let vc = segue.destination as? IngredientsViewController {
            ingredientsVC = vc
            if let product = product { vc.updateWithProduct(product) }
        } else if segue.identifier == "showNutrition",
                  let vc = segue.destination as? NutritionViewController {
            nutritionVC = vc
            if let product = product { vc.updateWithProduct(product) }
        } else if segue.identifier == "Createnewlist",
                  let navigationController = segue.destination as? UINavigationController,
                  let newListVC = navigationController.topViewController as? NewListViewController {
            newListVC.productId = product?.id
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
    
    @objc func savedButtonTapped(_ sender: UIBarButtonItem) {
        guard let user = Auth.auth().currentUser else {
                showSignInAlert()
                return
            }

        guard let product = product else {
            print("No product to save or unsave")
            return
        }
        
        // Fetch the user's saved lists from Firestore.
        fetchUserSavedLists { savedLists in
            // Check if the product is already saved in any list.
            if savedLists.contains(where: { $0.products.contains(product.id) }) {
                // Already saved → Remove the product from all lists.
                self.removeProductFromAllLists(product: product)
            } else {
                // Not saved → Show an action sheet with the available lists.
                self.showAddProductActionSheet(for: product, savedLists: savedLists)
            }
        }
    }
    private func showSignInAlert() {
        let alert = UIAlertController(
            title: "Sign In Required",
            message: "You need to sign in to save products to your lists.",
            preferredStyle: .alert
        )
        
        let signInAction = UIAlertAction(title: "Sign In", style: .default) { _ in
            // Redirect to the sign-in screen (Modify as per your app's navigation)
            if let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                self.present(signInVC, animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(signInAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    // Fetch the saved lists from Firestore for the current user.
    private func fetchUserSavedLists(completion: @escaping ([SavedList]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)
        userDocRef.getDocument(source: .server) { document, error in
            if let error = error {
                print("Error fetching saved lists: \(error)")
                completion([])
                return
            }
            guard let document = document,
                  document.exists,
                  let data = document.data(),
                  let listsArray = data["savedLists"] as? [[String: Any]] else {
                completion([])
                return
            }
            let lists = listsArray.compactMap { dict -> SavedList? in
                guard let listId = dict["listId"] as? String,
                      let name = dict["name"] as? String,
                      let iconName = dict["iconName"] as? String else {
                    return nil
                }
                let products = dict["products"] as? [String] ?? []
                return SavedList(listId: listId, name: name, iconName: iconName, products: products)
            }
            // Update the local cache:
            var newCache = Set<String>()
            for list in lists {
                for prodId in list.products {
                    newCache.insert(prodId)
                }
            }
            self.cachedSavedProductIDs = newCache
            completion(lists)
        }
    }

    
    // Display an action sheet to let the user select a list to add the product to.
    private func showAddProductActionSheet(for product: ProductData, savedLists: [SavedList]) {
        let actionSheet = UIAlertController(title: "Select a List to add to", message: nil, preferredStyle: .actionSheet)
        for list in savedLists {
            let action = UIAlertAction(title: list.name, style: .default) { _ in
                self.addProductToList(savedList: list, product: product)
            }
            action.setValue(UIColor.systemOrange, forKey: "titleTextColor")
            actionSheet.addAction(action)
        }
        let newListAction = UIAlertAction(title: "New List", style: .default) { _ in
            self.performSegue(withIdentifier: "Createnewlist", sender: self)
        }
        newListAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
        actionSheet.addAction(newListAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
        actionSheet.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    // Update a saved list in Firestore by adding the product's ID.
    private func addProductToList(savedList: SavedList, product: ProductData) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)
        
        userDocRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            guard let document = document,
                  document.exists,
                  var data = document.data(),
                  var lists = data["savedLists"] as? [[String: Any]] else {
                print("Could not fetch saved lists")
                return
            }
            
            if let listIndex = lists.firstIndex(where: { ($0["listId"] as? String) == savedList.listId }) {
                var listDict = lists[listIndex]
                var products = listDict["products"] as? [String] ?? []
                if !products.contains(product.id) {
                    products.append(product.id)
                    listDict["products"] = products
                    lists[listIndex] = listDict
                    
                    userDocRef.updateData(["savedLists": lists]) { error in
                        if let error = error {
                            print("Error updating saved list: \(error)")
                        } else {
                            print("\(product.name) added to \(savedList.name)")
                            self.cachedSavedProductIDs.insert(product.id)
                            self.updateBookmarkIcon()
                          
                        }
                    }
                } else {
                    print("\(product.name) is already in the list \(savedList.name)")
                }
            }
        }
    }
    
    // Remove the product from all saved lists in Firestore.
    private func removeProductFromAllLists(product: ProductData) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)
        
        userDocRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            guard let document = document,
                  document.exists,
                  var data = document.data(),
                  var lists = data["savedLists"] as? [[String: Any]] else {
                print("Could not fetch saved lists")
                return
            }
            
            var changed = false
            for (i, var listDict) in lists.enumerated() {
                if var products = listDict["products"] as? [String], products.contains(product.id) {
                    products.removeAll(where: { $0 == product.id })
                    listDict["products"] = products
                    lists[i] = listDict
                    changed = true
                }
            }
            if changed {
                userDocRef.updateData(["savedLists": lists]) { error in
                    if let error = error {
                        print("Error updating saved lists: \(error)")
                    } else {
                        print("\(product.name) removed from all lists")
                        self.cachedSavedProductIDs.remove(product.id)
                        self.updateBookmarkIcon()
                    }
                }
            }
        }
    }
    
    // MARK: - Product Details UI Setup
    private func setupProductDetails() {
        if let product = product {
            ProductName.text = product.name
            if let url = URL(string: product.imageURL) {
                ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
            } else {
                ProductImage.image = UIImage(named:"placeholder_product_nobg")
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
                let barcode = data["barcode"] as? [String] ?? []
                let imageURL = data["imageURL"] as? String ?? ""
                let ingredients = data["ingredients"] as? [String] ?? []
                let artificialIngredients = data["artificialIngredients"] as? [String] ?? []
                let pros = (data["pros"] as? [String] ?? []).filter { !$0.isEmpty }
                let cons = (data["cons"] as? [String] ?? []).filter { !$0.isEmpty }
                let userRating = data["userRating"] as? Float ?? 0.0
                let numberOfRatings = data["numberOfRatings"] as? Int ?? 0
                let categoryId = data["categoryId"] as? String ?? ""
                let healthScore = data["healthScore"] as? Double ?? 0.0
                let nutritionInfo = data["nutritionInfo"] as? [String: String] ?? [:]
                
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
                    pros: pros,
                    cons: cons,
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
    private func updateBookmarkIcon() {
        guard let product = product else { return }
        
        // If the cache is empty, fetch from Firestore to repopulate it
        if cachedSavedProductIDs.isEmpty {
            fetchUserSavedLists { savedLists in
                var newCache = Set<String>()
                for list in savedLists {
                    for prodId in list.products {
                        newCache.insert(prodId)
                    }
                }
                self.cachedSavedProductIDs = newCache
                let isProductSaved = newCache.contains(product.id)
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: isProductSaved ? "bookmark.fill" : "bookmark")
                }
            }
        } else {
            // Otherwise, use the current cache
            let isProductSaved = cachedSavedProductIDs.contains(product.id)
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: isProductSaved ? "bookmark.fill" : "bookmark")
            }
        }
    }
    @objc private func handleNewListCreated(_ notification: Notification) {
            // When a new list is created from ProductDetails (and the product is saved in it),
            // refresh the cache and update the bookmark icon.
            fetchUserSavedLists { savedLists in
                var newCache = Set<String>()
                for list in savedLists {
                    for prodId in list.products {
                        newCache.insert(prodId)
                    }
                }
                self.cachedSavedProductIDs = newCache
                self.updateBookmarkIcon()
            }
        }

}
