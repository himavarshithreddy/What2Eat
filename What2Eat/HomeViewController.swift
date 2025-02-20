//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin68 on 19/11/24.
//  Updated for caching to avoid repeated fetching
//

import UIKit
import WebKit
import FirebaseFirestore
import QuartzCore
import FirebaseAuth
import SDWebImage

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

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    var recommendedProducts: [(id: String, name: String, healthScore: Int, imageURL: String, categoryName: String)] = []

    @IBOutlet var HomeHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var recentScansSeeAll: UIButton!
    @IBOutlet var noRecentScansLabel: UILabel!
    @IBOutlet var ScanNowButton: UIButton!
    @IBOutlet var UserName: UILabel!
    @IBOutlet var RecentScansTableView: UITableView!
    @IBOutlet var HomeImage: UIImageView!
    
    // Outlet for the right bar button (profile picture)
    @IBOutlet var rightbarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        markOnboardingComplete()
        HomeImage.transform = CGAffineTransform(rotationAngle: .pi * 1.845)
        collectionView.delegate = self
        RecentScansTableView.delegate = self
        RecentScansTableView.dataSource = self
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        
        updateUserName()
        updateProfilePicture()
        scanNowButtonUI()
        noRecentScansLabel.isHidden = true
        
        fetchRecentScans {
            self.HomeHeight.constant = CGFloat(min(recentScansProducts.count, 4) * 75 + 750)
        }
        fetchRecommendedProducts {
            self.collectionView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchRecentScans {
            self.HomeHeight.constant = CGFloat(min(recentScansProducts.count, 4) * 75 + 750)
        }
        updateUserName()
        updateProfilePicture()
        self.collectionView.reloadData()
        fetchRecommendedProducts {
            self.collectionView.reloadData()
        }
    }
    func markOnboardingComplete() {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.synchronize() // Save immediately
            
        }
    
    // MARK: - Caching User Name
    func updateUserName() {
        guard let userId = Auth.auth().currentUser?.uid else {
            UserName.text = "Hi, Guest"
            return
        }
        
        // Try to load the name from cache first.
        if let cachedName = UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
            let firstName = cachedName.components(separatedBy: " ").first ?? cachedName
            UserName.text = "Hi, \(firstName)"
        } else {
            UserName.text = "Hi, User"
        }
        
        // Then fetch the latest name from Firestore in the background.
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
            // Update if the fetched name differs from the cached value.
            if fullName != UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                DispatchQueue.main.async {
                    self.UserName.text = "Hi, \(firstName)"
                }
                UserDefaults.standard.set(fullName, forKey: "cachedUserName_\(userId)")
            }
        }
    }
    
    // MARK: - Caching Profile Picture
    func updateProfilePicture() {
        guard let userId = Auth.auth().currentUser?.uid else {
            let initial = "G"
            let size = CGSize(width: 32, height: 32)
            if let image = UIImage.imageWithInitial(initial, size: size) {
                self.rightbarButton.image = image.withRenderingMode(.alwaysOriginal)
            }
            return
        }
        
        // Check for a cached profile image URL.
        if let cachedProfileImageUrl = UserDefaults.standard.string(forKey: "cachedProfileImageUrl_\(userId)"),
           let url = URL(string: cachedProfileImageUrl) {
            // SDWebImage will handle cached images automatically.
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { (image, data, error, cacheType, finished, imageURL) in
                if let image = image {
                    let size = CGSize(width: 32, height: 32)
                    let circularImage = image.circularImage(size: size)
                    DispatchQueue.main.async {
                        self.rightbarButton.image = circularImage.withRenderingMode(.alwaysOriginal)
                    }
                }
            }
        } else {
            // If no cached URL exists, fetch from Firestore.
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)
            userRef.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching user document for profile picture: \(error.localizedDescription)")
                    return
                }
                guard let document = document, document.exists else {
                    print("User document does not exist")
                    return
                }
                
                let data = document.data() ?? [:]
                
                if let profileImageUrl = data["profileImageUrl"] as? String,
                   !profileImageUrl.isEmpty,
                   let url = URL(string: profileImageUrl) {
                    // Cache the profile image URL.
                    UserDefaults.standard.set(profileImageUrl, forKey: "cachedProfileImageUrl_\(userId)")
                    SDWebImageDownloader.shared.downloadImage(with: url, completed: { image, data, error, finished in
                        if finished, let image = image {
                            DispatchQueue.main.async {
                                let size = CGSize(width: 32, height: 32)
                                let circularImage = image.circularImage(size: size)
                                self.rightbarButton.image = circularImage.withRenderingMode(.alwaysOriginal)
                            }
                        }
                    })
                } else {
                    // If no image URL is available, generate one using the user’s initial.
                    var initial = "G"
                    if let fullName = data["name"] as? String, !fullName.isEmpty {
                        initial = String(fullName.prefix(1))
                    }
                    let size = CGSize(width: 32, height: 32)
                    if let image = UIImage.imageWithInitial(initial, size: size) {
                        DispatchQueue.main.async {
                            self.rightbarButton.image = image.withRenderingMode(.alwaysOriginal)
                        }
                    }
                }
            }
        }
    }
    
    func scanNowButtonUI() {
        ScanNowButton.layer.borderWidth = 4
        ScanNowButton.layer.borderColor = UIColor(red: 254/255, green: 231/255, blue: 206/255, alpha: 0.8).cgColor
        ScanNowButton.layer.masksToBounds = true
    }
    
    // MARK: - Collection View Methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendedProducts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickforyouCell", for: indexPath) as! HomePickForYouCell
        
        let product = recommendedProducts[indexPath.row]
        cell.picktitle.text = product.name
        cell.pickscoreLabel.text = "\(product.healthScore)"
        cell.pickImage.sd_setImage(with: URL(string: product.imageURL), placeholderImage: UIImage(named: "placeholder_product_nobg"))
     
        cell.pickcategory.text = product.categoryName
        cell.layer.borderColor = UIColor(red: 255/255, green: 234/255, blue: 218/255, alpha: 1).cgColor
        cell.layer.borderWidth = 3
        if product.healthScore < 40 {
            cell.pickview.layer.backgroundColor = UIColor.systemRed.cgColor
        } else if product.healthScore < 75 {
            cell.pickview.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        } else {
            cell.pickview.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        
        cell.layer.cornerRadius = 10
        return cell
    }
    
    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section, env) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6), heightDimension: .absolute(300))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            return section
        }
        return layout
    }
    
    // MARK: - Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(recentScansProducts.count, 4)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentScansCell", for: indexPath) as! RecentScansCell
        let product = recentScansProducts[indexPath.row]
        if let url = URL(string: product.imageURL) {
            cell.ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product"))
        } else {
            cell.ProductImage.image = UIImage(named: "placeholder_product")
        }
        
        cell.ProductName.text = product.name
        cell.ProductScore.text = "\(product.healthScore)"
        cell.ProductScoreView.layer.cornerRadius = cell.ProductScoreView.frame.height / 2
        
        if product.healthScore < 40 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if product.healthScore < 75 {
            cell.ProductScoreView.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if product.healthScore <= 100 {
            cell.ProductScoreView.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.layer.cornerRadius = 8
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProductDetails = recentScansProducts[indexPath.row]
        performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProductDetails.id)
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
        }
    }
    
    // MARK: - Collection View Selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !recommendedProducts.isEmpty {
            let selectedProduct = recommendedProducts[indexPath.row]
            performSegue(withIdentifier: "showproductdetailsfromhome", sender: selectedProduct.id)
        }
    }
    
    func fetchRecentScans(completion: @escaping () -> Void) {
        let recentScans = getRecentScans()
        if !recentScans.isEmpty {
            print("Fetching recent scans from local storage.")
            self.fetchProductsDetails(from: recentScans, completion: completion)
            self.toggleTableViewVisibility(isEmpty: false)
        } else {
            print("No recent scans found in local storage.")
            self.toggleTableViewVisibility(isEmpty: true)
            completion()
        }
    }
    
    private func getRecentScans() -> [String] {
        let defaults = UserDefaults.standard
        guard var localScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] else {
            return []
        }
        localScans.sort { (scan1, scan2) -> Bool in
            let timestamp1 = scan1["index"] as? TimeInterval ?? 0
            let timestamp2 = scan2["index"] as? TimeInterval ?? 0
            return timestamp1 > timestamp2
        }
        let productIds = localScans.compactMap { $0["productId"] as? String }
        return productIds
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
    
    func fetchProductsDetails(from productIDs: [String], completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        var productsDetails: [(id: String, name: String, healthScore: Int, imageURL: String)] = []
        let dispatchGroup = DispatchGroup()
        for productId in productIDs {
            dispatchGroup.enter()
            let productRef = db.collection("products").document(productId)
            productRef.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching product document: \(error)")
                } else {
                    guard let document = document, document.exists else {
                        print("Product document does not exist for ID: \(productId)")
                        dispatchGroup.leave()
                        return
                    }
                    if let name = document.data()?["name"] as? String,
                       let healthScore = document.data()?["healthScore"] as? Int,
                       let imageURL = document.data()?["imageURL"] as? String {
                        productsDetails.append((id: productId, name: name, healthScore: healthScore, imageURL: imageURL))
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            recentScansProducts = productsDetails
            self.RecentScansTableView.reloadData()
            completion()
        }
    }
    
    // MARK: - Fetching Recommended Products for "Picks for You"
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
        var fetchedProducts: [(id: String, name: String, healthScore: Int, imageURL: String, categoryName: String)] = []
        let dispatchGroup = DispatchGroup()
        for productId in recommendations {
            dispatchGroup.enter()
            let productRef = db.collection("products").document(productId)
            productRef.getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data() {
                    if let name = data["name"] as? String,
                       let healthScore = data["healthScore"] as? Int,
                       let imageURL = data["imageURL"] as? String,
                       let categoryId = data["categoryId"] as? String {
                        self.fetchCategoryName(for: categoryId) { categoryName in
                            fetchedProducts.append((id: productId, name: name, healthScore: healthScore, imageURL: imageURL, categoryName: categoryName))
                            dispatchGroup.leave()
                        }
                    } else {
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            let filteredProducts = fetchedProducts.filter { recommended in
                !recentScansProducts.contains(where: { $0.id == recommended.id })
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
    
    func fetchTopHealthScoreProducts(completion: @escaping ([(id: String, name: String, healthScore: Int, imageURL: String, categoryName: String)]) -> Void) {
        let db = Firestore.firestore()
        db.collection("products")
            .order(by: "healthScore", descending: true)
            .limit(to: 6)
            .getDocuments { (snapshot, error) in
                var topProducts: [(id: String, name: String, healthScore: Int, imageURL: String, categoryName: String)] = []
                if let error = error {
                    print("Error fetching top products: \(error)")
                }
                let dispatchGroup = DispatchGroup()
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        if let name = data["name"] as? String,
                           let healthScore = data["healthScore"] as? Int,
                           let imageURL = data["imageURL"] as? String,
                           let categoryId = data["categoryId"] as? String {
                            dispatchGroup.enter()
                            self.fetchCategoryName(for: categoryId) { categoryName in
                                topProducts.append((id: document.documentID, name: name, healthScore: healthScore, imageURL: imageURL, categoryName: categoryName))
                                dispatchGroup.leave()
                            }
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(topProducts)
                }
            }
    }
    
    func fetchCategoryName(for categoryId: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        db.collection("categories").document(categoryId).getDocument { (document, error) in
            if let document = document, document.exists,
               let data = document.data(),
               let name = data["name"] as? String {
                completion(name)
            } else {
                completion("Unknown Category")
            }
        }
    }
}
