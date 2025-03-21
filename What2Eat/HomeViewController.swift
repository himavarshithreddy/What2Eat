//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin68 on 19/11/24.
//  Updated for caching and new recentScans structure
//

import UIKit
import WebKit
import FirebaseFirestore
import QuartzCore
import FirebaseAuth
import SDWebImage
import UserNotifications
import CoreData

// MARK: - UIImage Extension for Circular Cropping
extension UIImage {
    func circularImage(size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIBezierPath(ovalIn: rect).addClip()
        self.draw(in: rect)
        let circularImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return circularImage
    }

    static func imageWithInitial(_ initial: String, size: CGSize, backgroundColor: UIColor = .systemTeal, textColor: UIColor = .white, font: UIFont? = nil) -> UIImage? {
        let font = font ?? UIFont.boldSystemFont(ofSize: size.width / 2)
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        let path = UIBezierPath(ovalIn: rect)
        backgroundColor.setFill()
        path.fill()
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let textSize = initial.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height)
        
        initial.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension String {
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.width)
    }
}

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    var recommendedProducts: [(id: String, name: String, healthScore: Int, imageURL: String)] = []
    var recentScansProducts: [(id: String, name: String, healthScore: Int, imageURL: String, type: String)] = []
    private var profileListener: ListenerRegistration?
    
    @IBOutlet var CategoriesView: UIView!
    @IBOutlet var HomeHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var HomeView: UIView!
    @IBOutlet var recentScansSeeAll: UIButton!
    @IBOutlet var searchView: UIView!
    @IBOutlet var noRecentScansLabel: UILabel!
    @IBOutlet var ScanNowButton: UIButton!
    @IBOutlet var UserName: UILabel!
    @IBOutlet var RecentScansTableView: UITableView!
    @IBOutlet var HomeImage: UIImageView!
    @IBOutlet var rightbarButton: UIButton!
    
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    // Properties for CategoriesView
    private var categories: [(id: String, name: String)] = []
    private var selectedCategory: String = "All"
    private var popularProducts: [(id: String, name: String, healthScore: Int, imageURL: String)] = []
    private let db = Firestore.firestore()
    
    // UI Elements for CategoriesView
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let productCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestNotificationPermission()
        markOnboardingComplete()
        HomeImage.transform = CGAffineTransform(rotationAngle: .pi * 1.845)
        collectionView.delegate = self
        RecentScansTableView.delegate = self
        RecentScansTableView.dataSource = self
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        self.navigationController?.navigationBar.isHidden = true
        updateUserName()
        setupRightBarButton()
        scanNowButtonUI()
        noRecentScansLabel.isHidden = true
        setupProfileListener()
        fetchRecentScans {
            self.HomeHeight.constant = CGFloat(min(self.recentScansProducts.count, 4) * 75 + 950)
        }
        fetchRecommendedProducts {
            self.collectionView.reloadData()
        }
        let statusBarView = UIView()
        statusBarView.backgroundColor = UIColor(red: 254/255, green: 139/255, blue: 54/255, alpha: 1)
        HomeView.backgroundColor = UIColor(red: 254/255, green: 139/255, blue: 54/255, alpha: 1)
        view.addSubview(statusBarView)
        
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusBarView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarView.heightAnchor.constraint(equalToConstant: statusBarHeight)
        ])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchBarTapped))
        searchView.addGestureRecognizer(tapGesture)
        searchView.isUserInteractionEnabled = true
        
        setupCategoriesView()
        fetchCategoriesFromFirebase()
        listenForCategoryUpdates()
        fetchPopularProducts(for: selectedCategory)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge]) { [weak self] granted, error in
            if granted {
                print("Permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        profileListener?.remove()
        self.navigationController?.navigationBar.isHidden = false
    }
    
    deinit {
        profileListener?.remove()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupProfileListener()
        fetchRecentScans {
            self.HomeHeight.constant = CGFloat(min(self.recentScansProducts.count, 4) * 75 + 950)
        }
        updateUserName()
        self.navigationController?.navigationBar.isHidden = true
        self.collectionView.reloadData()
        fetchRecommendedProducts {
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        setupProfileListener()
    }
    
    func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
    }
    
    func updateUserName() {
        guard let userId = Auth.auth().currentUser?.uid else {
            UserName.text = "Hi, Guest"
            return
        }
        
        if let cachedName = UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
            let firstName = cachedName.components(separatedBy: " ").first ?? cachedName
            UserName.text = "Hi, \(firstName)"
        } else {
            UserName.text = "Hi, User"
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            guard let document = document, document.exists,
                  let fullName = document.data()?["name"] as? String else {
                print("No username found for user.")
                return
            }
            if fullName != UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                DispatchQueue.main.async {
                    self.UserName.text = "Hi, \(firstName)"
                }
                UserDefaults.standard.set(fullName, forKey: "cachedUserName_\(userId)")
            }
        }
    }
    
    func scanNowButtonUI() {
        ScanNowButton.layer.borderWidth = 1.5
        ScanNowButton.layer.borderColor = UIColor(red: 255/255, green: 120/255, blue: 30/255, alpha: 0.8).cgColor
        ScanNowButton.layer.masksToBounds = true
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            return recommendedProducts.count
        } else if collectionView == categoryCollectionView {
            return categories.count
        } else if collectionView == productCollectionView {
            return popularProducts.count + 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickforyouCell", for: indexPath) as! HomePickForYouCell
            let product = recommendedProducts[indexPath.row]
            cell.picktitle.text = product.name
            cell.pickscoreLabel.text = "\(product.healthScore)"
            cell.pickImage.sd_setImage(with: URL(string: product.imageURL), placeholderImage: UIImage(named: "placeholder_product_nobg"))
            cell.pickview.layer.borderColor = UIColor.white.cgColor
            cell.pickview.layer.borderWidth = 3
            cell.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1)
            if product.healthScore < 40 {
                cell.pickview.layer.backgroundColor = UIColor.systemRed.cgColor
            } else if product.healthScore < 75 {
                cell.pickview.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
            } else {
                cell.pickview.layer.backgroundColor = UIColor.systemGreen.cgColor
            }
            cell.layer.cornerRadius = 10
            return cell
        } else if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            let category = categories[indexPath.item].name
            cell.configure(with: category, isSelected: category == selectedCategory)
            return cell
        } else if collectionView == productCollectionView {
            if indexPath.item == popularProducts.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SeeAllCell", for: indexPath) as! SeeAllCell
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCardCell", for: indexPath) as! ProductCardCell
                let product = popularProducts[indexPath.item]
                cell.configure(with: product)
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView {
            if !recommendedProducts.isEmpty {
                let selectedProduct = recommendedProducts[indexPath.row]
                performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct.id)
            }
        } else if collectionView == categoryCollectionView {
            selectedCategory = categories[indexPath.item].name
            categoryCollectionView.reloadData()
            fetchPopularProducts(for: selectedCategory)
        } else if collectionView == productCollectionView {
            if indexPath.item == popularProducts.count {
                if let selectedCategoryTuple = categories.first(where: { $0.name == selectedCategory }) {
                    performSegue(withIdentifier: "showExploreProducts", sender: selectedCategoryTuple)
                }
            } else if !popularProducts.isEmpty {
                let selectedProduct = popularProducts[indexPath.row]
                performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct.id)
            }
        }
    }
    
    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section, env) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.4), heightDimension: .absolute(200))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            return section
        }
        return layout
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            return CGSize(width: collectionView.frame.width * 0.4, height: 200)
        } else if collectionView == categoryCollectionView {
            let category = categories[indexPath.item].name
            let width = category.uppercased().width(withConstrainedHeight: 40, font: .systemFont(ofSize: 14, weight: .bold)) + 24
            return CGSize(width: width, height: 40)
        } else if collectionView == productCollectionView {
            if indexPath.item == popularProducts.count {
                let width = "See All".width(withConstrainedHeight: 40, font: .systemFont(ofSize: 14, weight: .semibold)) + 24
                return CGSize(width: width, height: 100)
            } else {
                let width = 220
                let height = 100
                return CGSize(width: width, height: height)
            }
        }
        return .zero
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(recentScansProducts.count, 4)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentScansCell", for: indexPath) as! RecentScansCell
        let product = recentScansProducts[indexPath.row]
        
        if product.type == "barcode", let url = URL(string: product.imageURL) {
            cell.ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
        } else if product.type == "label" {
            if let imageData = CoreDataManager.shared.fetchLabelProduct(by: product.id)?.imageData,
               let image = UIImage(data: imageData) {
                cell.ProductImage.image = image
            } else {
                cell.ProductImage.image = UIImage(named: "placeholder_product_nobg")
            }
        } else {
            cell.ProductImage.image = UIImage(named: "placeholder_product_nobg")
        }
        
        cell.ProductName.text = product.name
        cell.ProductScore.text = "\(product.healthScore)"
        cell.ProductScoreView.layer.cornerRadius = cell.ProductScoreView.frame.height / 2
        
        if product.healthScore < 40 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.ProductScoreView.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else if product.healthScore <= 100 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.layer.cornerRadius = 8
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct = recentScansProducts[indexPath.row]
        if selectedProduct.type == "barcode" {
            performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct.id)
        } else if selectedProduct.type == "label" {
            performSegue(withIdentifier: "showLabelScanDetails", sender: selectedProduct.id)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 4
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding / 2)
        cell.layer.mask = maskLayer
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showproductdetailsfromhome",
           let destinationVC = segue.destination as? ProductDetailsViewController,
           let productId = sender as? String {
            destinationVC.productId = productId
        } else if segue.identifier == "showLabelScanDetails",
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
        } else if segue.identifier == "showExploreProducts",
                  let destination = segue.destination as? ExploreProductsViewController,
                  let selectedCategory = sender as? (id: String, name: String) {
            destination.categoryId = selectedCategory.id
        }
    }
    
    private func fetchRecentScans(completion: @escaping () -> Void) {
        let recentScans = getRecentScans()
        if !recentScans.isEmpty {
            print("Fetching recent scans from local storage.")
            fetchProductsDetails(from: recentScans, completion: completion)
            toggleTableViewVisibility(isEmpty: false)
        } else {
            print("No recent scans found in local storage.")
            toggleTableViewVisibility(isEmpty: true)
            completion()
        }
    }
    
    private func getRecentScans() -> [(type: String, id: String)] {
        let defaults = UserDefaults.standard
        guard var localScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] else {
            return []
        }
        localScans.sort { (scan1, scan2) -> Bool in
            let timestamp1 = scan1["index"] as? TimeInterval ?? 0
            let timestamp2 = scan2["index"] as? TimeInterval ?? 0
            return timestamp1 > timestamp2
        }
        return localScans.compactMap {
            guard let type = $0["type"] as? String,
                  let id = $0["id"] as? String else { return nil }
            return (type: type, id: id)
        }
    }
    
    private func fetchProductsDetails(from scans: [(type: String, id: String)], completion: @escaping () -> Void) {
        var productsDetails: [(id: String, name: String, healthScore: Int, imageURL: String, type: String)] = []
        let dispatchGroup = DispatchGroup()
        let db = Firestore.firestore()

        for scan in scans {
            dispatchGroup.enter()
            if scan.type == "barcode" {
                let productRef = db.collection("products").document(scan.id)
                productRef.getDocument { (document, error) in
                    if let error = error {
                        print("Error fetching barcode product document: \(error)")
                    } else if let document = document, document.exists,
                              let name = document.data()?["name"] as? String,
                              let healthScore = document.data()?["healthScore"] as? Int,
                              let imageURL = document.data()?["imageURL"] as? String {
                        productsDetails.append((id: scan.id, name: name, healthScore: healthScore, imageURL: imageURL, type: "barcode"))
                    }
                    dispatchGroup.leave()
                }
            } else if scan.type == "label" {
                if let labelProduct = CoreDataManager.shared.fetchLabelProduct(by: scan.id) {
                    let name = labelProduct.name ?? "Unnamed Product"
                    let healthScore = Int(labelProduct.healthScore)
                    let imageURL = "" // No Firebase URL; image is in Core Data
                    productsDetails.append((id: scan.id, name: name, healthScore: healthScore, imageURL: imageURL, type: "label"))
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.recentScansProducts = productsDetails
            self.RecentScansTableView.reloadData()
            completion()
        }
    }
    
    func toggleTableViewVisibility(isEmpty: Bool) {
        if isEmpty {
            RecentScansTableView.isHidden = true
            noRecentScansLabel.isHidden = false
            recentScansSeeAll.isHidden = true
        } else {
            RecentScansTableView.isHidden = false
            noRecentScansLabel.isHidden = true
            recentScansSeeAll.isHidden = false
        }
    }
    
    func fetchRecommendedProducts(completion: @escaping () -> Void) {
        let defaults = UserDefaults.standard
        let recommendations = defaults.array(forKey: "recommendations") as? [String] ?? []
        if recommendations.isEmpty {
            self.fetchTopHealthScoreProducts { topProducts in
                self.recommendedProducts = topProducts
                completion()
            }
            return
        }
        let db = Firestore.firestore()
        var fetchedProducts: [(id: String, name: String, healthScore: Int, imageURL: String)] = []
        let dispatchGroup = DispatchGroup()
        for productId in recommendations {
            dispatchGroup.enter()
            let productRef = db.collection("products").document(productId)
            productRef.getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data() {
                    if let name = data["name"] as? String,
                       let healthScore = data["healthScore"] as? Int,
                       let imageURL = data["imageURL"] as? String {
                        fetchedProducts.append((id: productId, name: name, healthScore: healthScore, imageURL: imageURL))
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            let filteredProducts = fetchedProducts.filter { recommended in
                !self.recentScansProducts.contains(where: { $0.id == recommended.id })
            }
            if filteredProducts.isEmpty {
                self.fetchTopHealthScoreProducts { topProducts in
                    self.recommendedProducts = topProducts
                    completion()
                }
            } else {
                self.recommendedProducts = filteredProducts
                completion()
            }
        }
    }
    
    func fetchTopHealthScoreProducts(completion: @escaping ([(id: String, name: String, healthScore: Int, imageURL: String)]) -> Void) {
        let db = Firestore.firestore()
        db.collection("products")
            .order(by: "healthScore", descending: true)
            .limit(to: 6)
            .getDocuments { (snapshot, error) in
                var topProducts: [(id: String, name: String, healthScore: Int, imageURL: String)] = []
                if let error = error {
                    print("Error fetching top products: \(error)")
                }
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        if let name = data["name"] as? String,
                           let healthScore = data["healthScore"] as? Int,
                           let imageURL = data["imageURL"] as? String {
                            topProducts.append((id: document.documentID, name: name, healthScore: healthScore, imageURL: imageURL))
                        }
                    }
                }
                completion(topProducts)
            }
    }
    
    private func setupProfileListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            updateProfilePictureAsGuest()
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        profileListener = userRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to profile updates: \(error.localizedDescription)")
                self.updateProfilePictureFromCache(userId: userId)
                return
            }
            
            guard let document = document, document.exists else {
                print("User document does not exist")
                self.updateProfilePictureAsGuest()
                return
            }
            
            let data = document.data() ?? [:]
            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
            
            if !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                UserDefaults.standard.set(profileImageUrl, forKey: "cachedProfileImageUrl_\(userId)")
                SDWebImageManager.shared.loadImage(with: url, options: [.refreshCached], progress: nil) { (image, _, error, cacheType, finished, imageURL) in
                    if let image = image {
                        let size = CGSize(width: 32, height: 32)
                        let circularImage = image.circularImage(size: size)
                        DispatchQueue.main.async {
                            self.rightbarButton.setImage(circularImage.withRenderingMode(.alwaysOriginal), for: .normal)
                        }
                    } else {
                        self.setInitialImage(from: data)
                    }
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "cachedProfileImageUrl_\(userId)")
                self.setInitialImage(from: data)
            }
        }
    }
    
    private func updateProfilePictureAsGuest() {
        let initial = "G"
        let size = CGSize(width: 32, height: 32)
        if let image = UIImage.imageWithInitial(initial, size: size) {
            DispatchQueue.main.async {
                self.rightbarButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }
    
    private func updateProfilePictureFromCache(userId: String) {
        if let cachedProfileImageUrl = UserDefaults.standard.string(forKey: "cachedProfileImageUrl_\(userId)"),
           let url = URL(string: cachedProfileImageUrl) {
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { (image, data, error, cacheType, finished, imageURL) in
                if let image = image {
                    let size = CGSize(width: 32, height: 32)
                    let circularImage = image.circularImage(size: size)
                    DispatchQueue.main.async {
                        self.rightbarButton.setImage(circularImage.withRenderingMode(.alwaysOriginal), for: .normal)
                    }
                }
            }
        } else {
            self.updateProfilePictureAsGuest()
        }
    }
    
    private func setInitialImage(from data: [String: Any]) {
        var initial = "G"
        if let fullName = data["name"] as? String, !fullName.isEmpty {
            initial = String(fullName.prefix(1))
        }
        let size = CGSize(width: 32, height: 32)
        if let image = UIImage.imageWithInitial(initial, size: size) {
            DispatchQueue.main.async {
                self.rightbarButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }
    
    func setupRightBarButton() {
        rightbarButton.layer.cornerRadius = rightbarButton.frame.height / 2
        rightbarButton.clipsToBounds = true
        rightbarButton.isUserInteractionEnabled = true
        updateProfilePictureAsGuest()
    }
    
    @objc func searchBarTapped() {
        performSegue(withIdentifier: "showSearchScreen", sender: self)
    }
    
    private func setupCategoriesView() {
        CategoriesView.backgroundColor = .white
        
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        CategoriesView.addSubview(categoryCollectionView)
        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: CategoriesView.topAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: CategoriesView.leadingAnchor, constant: 0),
            categoryCollectionView.trailingAnchor.constraint(equalTo: CategoriesView.trailingAnchor, constant: 0),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        
        productCollectionView.translatesAutoresizingMaskIntoConstraints = false
        CategoriesView.addSubview(productCollectionView)
        NSLayoutConstraint.activate([
            productCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 20),
            productCollectionView.leadingAnchor.constraint(equalTo: CategoriesView.leadingAnchor, constant: 0),
            productCollectionView.trailingAnchor.constraint(equalTo: CategoriesView.trailingAnchor, constant: 0),
            productCollectionView.heightAnchor.constraint(equalToConstant: 120),
            productCollectionView.bottomAnchor.constraint(equalTo: CategoriesView.bottomAnchor, constant: 0)
        ])
        
        productCollectionView.delegate = self
        productCollectionView.dataSource = self
        productCollectionView.register(ProductCardCell.self, forCellWithReuseIdentifier: "ProductCardCell")
        productCollectionView.register(SeeAllCell.self, forCellWithReuseIdentifier: "SeeAllCell")
    }
    
    func fetchCategoriesFromFirebase() {
        db.collection("categories")
            .getDocuments(source: .cache) { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching categories from cache: \(error.localizedDescription)")
                    self.fetchCategoriesFromServer()
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    print("Loaded categories from cache ✅")
                    self.processCategories(documents: documents)
                } else {
                    print("Cache empty, fetching from server...")
                    self.fetchCategoriesFromServer()
                }
            }
    }
    
    func fetchCategoriesFromServer() {
        db.collection("categories")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching categories from Firestore: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents {
                    print("Fetched categories from Firestore 🌍")
                    self.processCategories(documents: documents)
                }
            }
    }
    
    func listenForCategoryUpdates() {
        db.collection("categories").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error listening for category updates: \(error.localizedDescription)")
                return
            }
            
            if let documents = querySnapshot?.documents {
                print("Received updated categories in real-time 🔄")
                self.processCategories(documents: documents)
            }
        }
    }
    
    func processCategories(documents: [QueryDocumentSnapshot]) {
        let fetchedCategories = documents.map { (id: $0.documentID, name: $0.data()["name"] as? String ?? "") }
        var allCategory: (id: String, name: String) = (id: "All", name: "All")
        var otherCategories = fetchedCategories
        
        otherCategories.sort { (cat1, cat2) -> Bool in
            if let num1 = Int(cat1.id), let num2 = Int(cat2.id) {
                return num1 < num2
            }
            return cat1.id < cat2.id
        }
        
        self.categories = [allCategory] + otherCategories
        self.categoryCollectionView.reloadData()
        if !self.categories.contains(where: { $0.name == self.selectedCategory }) {
            self.selectedCategory = "All"
            self.fetchPopularProducts(for: "All")
        }
    }
    
    func fetchPopularProducts(for category: String) {
        var query: Query
        
        if category == "All" {
            query = db.collection("products").order(by: "healthScore", descending: true).limit(to: 4)
        } else {
            guard let categoryId = categories.first(where: { $0.name == category })?.id else {
                print("Category ID not found for \(category)")
                popularProducts = []
                productCollectionView.reloadData()
                return
            }
            query = db.collection("products")
                .whereField("categoryId", isEqualTo: categoryId)
                .order(by: "healthScore", descending: true)
                .limit(to: 4)
        }
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching popular products: \(error)")
                return
            }
            self.popularProducts = snapshot?.documents.compactMap { doc -> (id: String, name: String, healthScore: Int, imageURL: String)? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let healthScore = data["healthScore"] as? Int,
                      let imageURL = data["imageURL"] as? String else {
                    return nil
                }
                return (id: doc.documentID, name: name, healthScore: healthScore, imageURL: imageURL)
            } ?? []
            self.productCollectionView.reloadData()
        }
    }
}

// MARK: - Supporting Classes
class CategoryCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with category: String, isSelected: Bool) {
        titleLabel.text = category
        contentView.backgroundColor = isSelected ? UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1) : UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1)
        titleLabel.textColor = isSelected ? .white : .black
    }
}

class ProductCardCell: UICollectionViewCell {
    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let productNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let scoreBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemGreen
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()
    
    private let backgroundLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1).cgColor
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        backgroundLayer.frame = contentView.bounds
        contentView.layer.insertSublayer(backgroundLayer, at: 0)
        
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(productImageView)
        
        scoreBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreBadge)
        
        productNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(productNameLabel)
        
        NSLayoutConstraint.activate([
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            productImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            productImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            productImageView.widthAnchor.constraint(equalToConstant: 80),
            
            scoreBadge.topAnchor.constraint(equalTo: productImageView.topAnchor, constant: 0),
            scoreBadge.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 6),
            scoreBadge.widthAnchor.constraint(equalToConstant: 24),
            scoreBadge.heightAnchor.constraint(equalToConstant: 24),
            
            productNameLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 8),
            productNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            productNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = contentView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with product: (id: String, name: String, healthScore: Int, imageURL: String)) {
        productNameLabel.text = product.name
        scoreBadge.text = "\(product.healthScore)"
        if let url = URL(string: product.imageURL) {
            productImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
        } else {
            productImageView.image = UIImage(named: "placeholder_product_nobg")
        }
        
        if product.healthScore < 40 {
            scoreBadge.backgroundColor = .systemRed
        } else if product.healthScore < 75 {
            scoreBadge.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1)
        } else {
            scoreBadge.backgroundColor = .systemGreen
        }
    }
}

class SeeAllCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "See All"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1)
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension CoreDataManager {
    func fetchLabelProduct(by id: String) -> ScanWithLabelProduct? {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Error fetching label product: \(error)")
            return nil
        }
    }
}
