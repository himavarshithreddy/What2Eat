import UIKit
import FirebaseFirestore
import FirebaseAuth

class LabelScanDetailsViewController: UIViewController {
    var capturedImage: UIImage?
    var productModel: ProductResponse?
    var healthScore: Int?
    var productAnalysis: ProductAnalysis?
    private var user: Users?
    var cachedSavedProductIDs = Set<String>()
    private var db = Firestore.firestore()
    
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var SummarySegmentView: UIView!
    @IBOutlet weak var IngredientsSegmentView: UIView!
    @IBOutlet weak var NutritionSegmentView: UIView!
    @IBOutlet var ProductImage: UIImageView!
    @IBOutlet var ProductName: UILabel!
    
    private var progressLayer: CAShapeLayer!
    weak var summaryVC: SummaryLabelViewController?
    weak var ingredientsVC: IngredientsLabelViewController?
    weak var nutritionVC: NutritionLabelViewController?
    var savedProductId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCircularProgressBar()
        fetchUserData { user in
                    guard let user = user else {
                        print("[DEBUG] Failed to fetch user data")
                        return
                    }
                    self.user = user
                    print("[DEBUG] User data fetched: \(user)")
                    
                    // Trigger extraction once user data is available
                    
                }
        setupProductDetails()
        
        let bookmarkButton = UIBarButtonItem(
            image: UIImage(systemName: "bookmark"),
            style: .plain,
            target: self,
            action: #selector(saveButtonTapped(_:))
        )
        bookmarkButton.tintColor = .systemOrange
        navigationItem.rightBarButtonItem = bookmarkButton
        
        self.view.bringSubviewToFront(SummarySegmentView)
        self.navigationItem.hidesBackButton = true
        
        let backImage = UIImage(systemName: "chevron.left")
        let customBackButton = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(customBackButtonPressed))
        customBackButton.title = "Back"
        self.navigationItem.leftBarButtonItem = customBackButton
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewListCreated(_:)), name: Notification.Name("NewListCreated"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBookmarkIcon()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSummaryLabel",
           let vc = segue.destination as? SummaryLabelViewController {
            summaryVC = vc
        } else if segue.identifier == "showIngredientsLabel",
                  let vc = segue.destination as? IngredientsLabelViewController {
            ingredientsVC = vc
        } else if segue.identifier == "showNutritionLabel",
                  let vc = segue.destination as? NutritionLabelViewController {
            nutritionVC = vc
        } else if segue.identifier == "Createnewlist",
                  let navigationController = segue.destination as? UINavigationController,
                  let newListVC = navigationController.topViewController as? NewListViewController {
            newListVC.productId = savedProductId // Use the generated ID
        }
    }

    @IBAction func SegmentAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: self.view.bringSubviewToFront(SummarySegmentView)
        case 1: self.view.bringSubviewToFront(IngredientsSegmentView)
        case 2: self.view.bringSubviewToFront(NutritionSegmentView)
        default: break
        }
    }

    private func setupCircularProgressBar() {
        let centerPoint = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        let radius = progressView.bounds.width / 2
        let circularPath = UIBezierPath(
            arcCenter: centerPoint,
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
        
        if let healthScore = healthScore {
            if healthScore < 40 {
                progressLabel.textColor = .systemRed
                progressLayer.strokeColor = UIColor.systemRed.cgColor
            } else if healthScore < 75 {
                progressLabel.textColor = .systemOrange
                progressLayer.strokeColor = UIColor.orange.cgColor
            } else {
                progressLabel.textColor = .systemGreen
                progressLayer.strokeColor = UIColor.systemGreen.cgColor
            }
        }
    }

    private func setupProductDetails() {
        ProductName.text = productModel?.name
        ProductImage.image = capturedImage
        
        if let nutritionVC = nutritionVC, let user = user {
                    // Parse nutrition data with RDA percentages
            let rdaPercentages = getRDAPercentages(product: productModel!, user: user)
            let nutritionDetails = productModel!.nutrition.map {
                        NutritionDetail(
                            name: $0.name,
                            value: "\($0.value) \($0.unit)",
                            rdaPercentage: Int(rdaPercentages[$0.name.lowercased()] ?? 0.0)
                        )
                    }
                    nutritionVC.updateNutrition(with: nutritionDetails)
                } else {
                    // Fallback if no user data or nutritionVC isn't ready
                    let parsedNutrition = productModel!.nutrition.map {
                        NutritionDetail(name: $0.name, value: "\($0.value) \($0.unit)", rdaPercentage: 0)
                    }
                    nutritionVC?.updateNutrition(with: parsedNutrition)
                }
        if let summaryVC = summaryVC {
            summaryVC.productAnalysis = self.productAnalysis
            summaryVC.ingredients = productModel!.ingredients
        }
        if let ingredientsVC = ingredientsVC {
            ingredientsVC.ingredients = productModel!.ingredients
        }
        
        if let healthScore = healthScore {
            setProgress(to: CGFloat(healthScore) / 100)
        } else {
            print("Warning: healthScore is nil")
        }
    }

    @objc func saveButtonTapped(_ sender: UIBarButtonItem) {
        guard let user = Auth.auth().currentUser else {
            showSignInAlert()
            return
        }

        guard let product = productModel else {
            print("No product to save or unsave")
            return
        }

        if let savedId = savedProductId {
            let alert = UIAlertController(
                title: "Remove from Saved?",
                message: "Are you sure you want to remove this product from your saved scans?",
                preferredStyle: .actionSheet
            )
            alert.view.tintColor = .systemOrange
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                CoreDataManager.shared.deleteScanWithLabelProduct(withId: savedId)
                self.savedProductId = nil
                self.removeProductFromAllLists(productId: savedId)
                self.updateBookmarkIcon()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            // Generate a new UUID
            let newId = UUID().uuidString
            self.savedProductId = newId
            
            // Save to Core Data with the generated ID
            CoreDataManager.shared.saveScanWithLabelProduct(productModel!, image: capturedImage, healthScore: healthScore,analysis: productAnalysis, id: newId)
            
            // Fetch lists and show action sheet
            fetchUserSavedLists { savedLists in
                self.showAddProductActionSheet(for: product, savedLists: savedLists, productId: newId)
            }
        }
    }

    private func showSignInAlert() {
        let alert = UIAlertController(
            title: "Sign In Required",
            message: "You need to sign in to save products to your lists.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Sign In", style: .default) { _ in
            if let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                self.present(signInVC, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func fetchUserSavedLists(completion: @escaping ([SavedList]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
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

    private func showAddProductActionSheet(for product: ProductResponse, savedLists: [SavedList], productId: String) {
        let actionSheet = UIAlertController(title: "Select a List to add to", message: nil, preferredStyle: .actionSheet)
        
        for list in savedLists {
            let action = UIAlertAction(title: list.name, style: .default) { _ in
                self.addProductToList(savedList: list, productId: productId)
            }
            action.setValue(UIColor.systemOrange, forKey: "titleTextColor")
            actionSheet.addAction(action)
        }
        
        let newListAction = UIAlertAction(title: "New List", style: .default) { _ in
            self.performSegue(withIdentifier: "Createnewlist", sender: self)
        }
        newListAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
        actionSheet.addAction(newListAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // If user cancels, remove from Core Data since it was just added
            if let id = self.savedProductId {
                CoreDataManager.shared.deleteScanWithLabelProduct(withId: id)
                self.savedProductId = nil
                self.updateBookmarkIcon()
            }
        }
        cancelAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
        actionSheet.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true)
        }
    }

    private func addProductToList(savedList: SavedList, productId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
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
                return
            }
            
            if let listIndex = lists.firstIndex(where: { ($0["listId"] as? String) == savedList.listId }) {
                var listDict = lists[listIndex]
                var products = listDict["products"] as? [String] ?? []
                if !products.contains(productId) {
                    products.append(productId)
                    listDict["products"] = products
                    lists[listIndex] = listDict
                    
                    userDocRef.updateData(["savedLists": lists]) { error in
                        if let error = error {
                            print("Error updating saved list: \(error)")
                        } else {
                            self.cachedSavedProductIDs.insert(productId)
                            self.updateBookmarkIcon()
                        }
                    }
                }
            }
        }
    }

    private func removeProductFromAllLists(productId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
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
                return
            }
            
            var changed = false
            for (i, var listDict) in lists.enumerated() {
                if var products = listDict["products"] as? [String], products.contains(productId) {
                    products.removeAll(where: { $0 == productId })
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
                        self.cachedSavedProductIDs.remove(productId)
                        self.updateBookmarkIcon()
                    }
                }
            }
        }
    }

    private func updateBookmarkIcon() {
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: self.savedProductId != nil ? "bookmark.fill" : "bookmark")
        }
        
        if let productId = savedProductId {
            fetchUserSavedLists { _ in
                let isProductSavedInCloud = self.cachedSavedProductIDs.contains(productId)
                if self.savedProductId != nil && !isProductSavedInCloud {
                    // Local save exists but not in cloud - could prompt to sync if needed
                }
            }
        }
    }

    @objc private func handleNewListCreated(_ notification: Notification) {
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

    @objc func customBackButtonPressed() {
        if savedProductId == nil {
            let alert = UIAlertController(title: "Save Scan?", message: "Do you want to save this scan for future reference?", preferredStyle: .alert)
            alert.view.tintColor = .systemOrange
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                self.saveButtonTapped(self.navigationItem.rightBarButtonItem!)
                self.navigationController?.popViewController(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Don't Save", style: .cancel, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

