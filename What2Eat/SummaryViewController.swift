//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var product: ProductData?
    var isUserRatingPresent: Bool = false
    var productAnalysis: ProductAnalysis?
    var userAllergens: [Allergen] = []
        var productAllergenAlerts: [Allergen] = []
    var expandedIndexPaths: [IndexPath: Bool] = [:] 
    
    @IBOutlet weak var UserRatingStarStack: UIStackView!
    @IBOutlet weak var AlertView: UIView!
    @IBOutlet weak var AlertTableView: UITableView!
    @IBOutlet weak var SummaryTableView: UITableView!
    @IBOutlet weak var AlertViewHeight: NSLayoutConstraint!
    @IBOutlet weak var SummaryTableHeight: NSLayoutConstraint!
    @IBOutlet weak var RatingText: UILabel!
    @IBOutlet weak var NumberOfRatings: UILabel!
    @IBOutlet weak var RateStarStackView: UIStackView!
    var userRating: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up table view delegates & data sources
        SummaryTableView.dataSource = self
        SummaryTableView.delegate = self
        AlertTableView.dataSource = self
        AlertTableView.delegate = self
        AlertView.isHidden = true
        SummaryTableView.estimatedRowHeight = 30
        SummaryTableView.rowHeight = UITableView.automaticDimension

                // Setup stars for user rating
        setStarRating(Float(product?.userRating ?? 0))
        setupEmptyStars()
        setupStarTapGestures()
        fetchUserAllergensForSummary()
        AlertTableView.sectionHeaderHeight = 0  // Explicit header height
        updateUI()
       
    }
    
    
    // MARK: - TableView DataSource & Delegate Methods
    

    
    // MARK: - TableView DataSource & Delegate Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 1 {
            var sections = 0
            if let product = productAnalysis {
                if !product.pros.isEmpty { sections += 1 }
                if !product.cons.isEmpty { sections += 1 }
            }
            return sections
        } else if tableView.tag == 2 {
            return productAllergenAlerts.isEmpty ? 0 : 1 // For allergens (or other data)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            if let product = productAnalysis {
                // Adjust section index based on the available pros and cons
                if !product.pros.isEmpty && section == 0 {
                    return product.pros.count // Pros section
                } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                    return product.cons.count // Cons section
                }
            }
        } else if tableView.tag == 2 {
         
            return productAllergenAlerts.count
            // Allergen section
        }
        return 0
    }



    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsCell", for: indexPath) as! HighlightsCell
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            if let product = productAnalysis {
                if !product.pros.isEmpty && indexPath.section == 0 {
                    // Pros section
                    let pro = product.pros[indexPath.row]
                    cell.HighlightText.text = pro.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "checkmark.square.fill")
                    cell.iconImage.tintColor = .systemGreen
                    if pro.summaryPoint != "Contains some nutrients" {
                        cell.DescriptionText.text = "\(pro.value)% of your recommended daily Intake."
                        cell.ProgressBar.progress = Float(pro.value) / 100.0
                        cell.ProgressBar.progressTintColor = .systemGreen
                        cell.ProgressBar.alpha=1
                       
                    }
                    else{
                        cell.DescriptionText.text = "Check Nutrition tab for more Details"
                        cell.ProgressBar.progress=0.0
                        cell.ProgressBar.alpha=0.0
                      
                    }
                    
                } else if !product.cons.isEmpty && indexPath.section == (product.pros.isEmpty ? 0 : 1) {
                    // Cons section
                    let con = product.cons[indexPath.row]
                    cell.HighlightText.text = con.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    cell.iconImage.tintColor = .systemRed
                    if con.summaryPoint != "No major concerns detected"{
                        cell.DescriptionText.text = "\(con.value)% of your recommended daily Intake."
                        cell.ProgressBar.progress = Float(con.value) / 100.0
                        cell.ProgressBar.progressTintColor = .systemRed
                        cell.ProgressBar.alpha=1
                    }
                    else{
                        cell.DescriptionText.text = "Check Nutrition tab for more Details"
                        cell.ProgressBar.progress=0.0
                        cell.ProgressBar.alpha=0.0
                    }
                   
                    
                }
            }
            cell.configureExpandButton(isExpanded: isExpanded)
                    cell.onExpandButtonTapped = { [weak self] in
                        guard let self = self else { return }
                        // Toggle the expanded state
                        self.expandedIndexPaths[indexPath] = !isExpanded
                        // Reload the row to reflect the new state
                        tableView.beginUpdates()
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        tableView.endUpdates()
                        // Update the table height
                        self.updateSummaryTableHeight()
                    }
            // Show/Hide elements based on expanded state
            cell.DescriptionText.isHidden = !isExpanded
            cell.ProgressBar.isHidden = !isExpanded
            
            // Enable wrapping for longer text
            cell.HighlightText.numberOfLines = 0
            cell.DescriptionText.numberOfLines = 0
            return cell
        } else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            let allergen = productAllergenAlerts[indexPath.row]
                        cell.AlertText.text = "Contains \(allergen.rawValue)"
            return cell
        }
        
        return UITableViewCell()
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.tag == 1 {
               return 30
           } else if tableView.tag == 2 {
               return 0
           }
           return 0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableView.tag == 1 else { return nil }
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: -10, width: tableView.frame.size.width, height: 25)
        
        // Customize the appearance of the header
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

        titleLabel.textColor = .black // Text color
        titleLabel.textAlignment = .left // Align text to the left
        
        if let product = productAnalysis {
            // Determine section titles based on pros and cons availability
            if !product.pros.isEmpty && section == 0 {
                titleLabel.text = "What’s Good 🙂" // For pros
            } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                titleLabel.text = "What’s Concerning ❗" // For cons
            }
        }

        // Add the label to the header view
        headerView.addSubview(titleLabel)
        
        return headerView
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 1 {
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            return isExpanded ? 100 : 50 // Collapsed height: 60, Expanded height: 120
        } else if tableView.tag == 2 {
            return 25 // Original height for AlertTableView
        }
        return 0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 1 {
            // Toggle the expanded state
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            expandedIndexPaths[indexPath] = !isExpanded
            
            // Reload the row to reflect the new state
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            // Update the table height
            updateSummaryTableHeight()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func updateSummaryTableHeight() {
        guard let product = productAnalysis else { return }
        var totalHeight: CGFloat = 0
        var headerHeight: CGFloat = 0
        

        if !product.pros.isEmpty {
            headerHeight += 50 // Header height for "What’s Good"
            for row in 0..<product.pros.count {
                let indexPath = IndexPath(row: row, section: 0)
                let isExpanded = expandedIndexPaths[indexPath] ?? false
                totalHeight += isExpanded ? 100 : 50
            }
        }
        if !product.cons.isEmpty {
            headerHeight += 50 // Header height for "What’s Concerning"
            let section = product.pros.isEmpty ? 0 : 1
            for row in 0..<product.cons.count {
                let indexPath = IndexPath(row: row, section: section)
                let isExpanded = expandedIndexPaths[indexPath] ?? false
                totalHeight += isExpanded ? 100 : 50
            }
        }
        let newHeight = totalHeight + headerHeight
        SummaryTableHeight.constant = newHeight
        self.view.layoutIfNeeded()
    }

    
    
    // MARK: - View Appearance
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let product = product {
            setStarRating(product.userRating)
        }
        fetchUserRatingFromFirestore()
    }
    
    
    // MARK: - Star Rating Setup
    private func updateUI() {
        updateSummaryTableHeight()
        updateAlertView()
        SummaryTableView.reloadData()
        AlertTableView.reloadData()
    }
    func setStarRating(_ rating: Float) {
        let starViews = UserRatingStarStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        RatingText.text = String(format: "%.1f", rating)
        NumberOfRatings.text = "\(product?.numberOfRatings ?? 0) Ratings"
        
        for (index, star) in starViews.enumerated() {
            if rating >= Float(index) + 1 {
                star.image = UIImage(systemName: "star.fill")
            } else if rating > Float(index) {
                star.image = UIImage(systemName: "star.leadinghalf.filled")
            } else {
                star.image = UIImage(systemName: "star")
            }
        }
    }
    
    func setupEmptyStars() {
        let starViews = RateStarStackView.arrangedSubviews.compactMap { $0 as? UIImageView }
        for star in starViews {
            star.image = UIImage(systemName: "star")
        }
    }
    
    func setupStarTapGestures() {
        let starViews = RateStarStackView.arrangedSubviews.compactMap { $0 as? UIImageView }
        for (index, star) in starViews.enumerated() {
            star.tag = index + 1
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(starTapped(_:)))
            star.isUserInteractionEnabled = true
            star.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func starTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedStar = sender.view as? UIImageView else { return }
        
        // Check if user is authenticated
        guard Auth.auth().currentUser != nil else {
            // Show an alert if user is not authenticated
            showAuthenticationAlert()
            return
        }
        
        let rating = tappedStar.tag
        
        // Update the product rating logic
        updateProductRating(newRating: rating)
        
        // Update the UI stars
        updateUserRatingStars(rating)
        
        // Update the user's local rating
        userRating = rating
    }

    func showAuthenticationAlert() {
        let alertController = UIAlertController(title: "Sign In Required",
                                                message: "You need to be signed in to rate this product. Please sign in first.",
                                                preferredStyle: .alert)
        alertController.view.tintColor = .systemOrange
      
        let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
     
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    
    func updateUserRatingStars(_ rating: Int) {
        let starViews = RateStarStackView.arrangedSubviews.compactMap { $0 as? UIImageView }
        for (index, star) in starViews.enumerated() {
            if index < rating {
                star.image = UIImage(systemName: "star.fill")
                star.tintColor = .orange
            } else {
                star.image = UIImage(systemName: "star")
                star.tintColor = .gray
            }
        }
    }
    
    func updateProductRating(newRating: Int) {
        guard var product = product else { return }
        
        var totalScore = product.userRating * Float(product.numberOfRatings)
        
        if userRating > 0 {
            // User is updating an existing rating; subtract old rating
            totalScore -= Float(userRating)
        } else {
            // User is rating for the first time; increase rating count
            product.numberOfRatings += 1
        }
        
        totalScore += Float(newRating)
        let newAverage = totalScore / Float(product.numberOfRatings)
        product.userRating = round(newAverage * 10) / 10.0
        
        self.product = product
        setStarRating(product.userRating)
        NumberOfRatings.text = "\(product.numberOfRatings) Ratings"

        // Save rating to Firestore only if it's a new rating or changed
        if userRating != newRating {
            saveRatingToFirestore(newRating: newRating)
            updateProductScoreInFirebase(newAverage: product.userRating, numberOfRatings: product.numberOfRatings)
        }
        
        // Update local user rating
        userRating = newRating
    }

    func updateProductScoreInFirebase(newAverage: Float, numberOfRatings: Int) {
        guard let productId = product?.id else { return }
        
        let db = Firestore.firestore()
        let productRef = db.collection("products").document(productId)
        
        // Update the product document with the new average rating and number of ratings
        productRef.updateData([
            "userRating": newAverage,
            "numberOfRatings": numberOfRatings
        ]) { error in
            if let error = error {
                print("Error updating product score: \(error.localizedDescription)")
            } else {
                print("Product score updated successfully!")
            }
        }
    }

    func saveRatingToFirestore(newRating: Int) {
        guard let productId = product?.id else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Query to check if a rating already exists for this user and product
        db.collection("ratings")
            .whereField("productId", isEqualTo: productId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Firestore query error: \(error.localizedDescription)")
                    return
                }
                
                let ratingData: [String: Any] = [
                    "productId": productId,
                    "userId": userId,
                    "rating": newRating
                ]
                
                if let document = querySnapshot?.documents.first {
                    // Update existing rating
                    document.reference.updateData(ratingData) { error in
                        if let error = error {
                            print("Error updating rating: \(error.localizedDescription)")
                        } else {
                            print("Rating successfully updated!")
                        }
                    }
                } else {
                    // Add new rating
                    db.collection("ratings").addDocument(data: ratingData) { error in
                        if let error = error {
                            print("Error saving rating: \(error.localizedDescription)")
                        } else {
                            print("Rating successfully saved!")
                        }
                    }
                }
            }
    }
    func fetchUserRatingFromFirestore() {
        // Ensure productId and userId are available
        guard let productId = product?.id else {
            print("Error: Product ID is missing.")
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in. Skipping rating fetch.")
            return
        }
        
        print("Fetching rating for product: \(productId), user: \(userId)")
        
        let db = Firestore.firestore()
        
        // Query the ratings collection for a document matching productId and userId
        db.collection("ratings")
            .whereField("productId", isEqualTo: productId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Firestore query error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No matching documents found.")
                    DispatchQueue.main.async {
                        self?.userRating = 0
                        self?.setupEmptyStars()
                    }
                    return
                }
                
                // Check if a document was found
                if let document = documents.first {
                    print("Document found: \(document.documentID)")
                    guard let rating = document.data()["rating"] as? Int else {
                        print("Error: 'rating' field is missing or not an Int.")
                        return
                    }
                    DispatchQueue.main.async {
                        self?.userRating = rating
                        self?.updateUserRatingStars(rating)
                        print("Updated user rating to \(rating)")
                    }
                } else {
                    print("No existing rating found for this user/product.")
                    DispatchQueue.main.async {
                        self?.userRating = 0
                        self?.setupEmptyStars()
                    }
                }
            }
    }

    
    
    
    
    // MARK: - Public Update Method
    
    /// Call this method from the parent view controller once the product is fetched.
    func updateWithProduct(_ product: ProductData) {
        self.product = product
        
        // Update UI on the main thread
        DispatchQueue.main.async {
            fetchUserData { user in
                guard let user = user else {
                    return
                }
                
                self.productAnalysis = generateProsAndCons(product: product, user: user)
            }
            // Update star rating and number of ratings
            self.setStarRating(product.userRating)
            self.NumberOfRatings.text = "\(product.numberOfRatings) Ratings"
            
            // Update table view height for pros & cons
            self.updateSummaryTableHeight()
            self.fetchUserRatingFromFirestore()
            
            // Reload the summary table view to reflect new data
            self.SummaryTableView.reloadData()
            self.compareAllergens()
            
            
        }
    }
    func fetchUserAllergensForSummary() {
            if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                let userDocument = db.collection("users").document(uid)
                userDocument.getDocument { [weak self] (document, error) in
                    if let error = error {
                        print("Error fetching user allergens: \(error.localizedDescription)")
                    } else if let document = document, document.exists,
                              let allergiesFromDB = document.get("allergies") as? [String] {
                        self?.userAllergens = allergiesFromDB.compactMap { Allergen(rawValue: $0) }
                        // Once fetched, compare with product ingredients
                        self?.compareAllergens()
                    }
                }
            } else {
                let defaults = UserDefaults.standard
                if let localAllergies = defaults.array(forKey: "localAllergies") as? [String] {
                    userAllergens = localAllergies.compactMap { Allergen(rawValue: $0) }
                    compareAllergens()
                }
            }
        }
    
    func compareAllergens() {
        guard let productIngredients = product?.ingredients else {
            self.productAllergenAlerts = []
            updateAlertView()
            return
        }
        
        var alerts: [Allergen] = []
        
        // For each user-selected allergen, check its mapped synonyms
        for allergen in userAllergens {
            if let synonyms = allergenMapping[allergen.rawValue] {
                for synonym in synonyms {
                    for ingredient in productIngredients {
                        if ingredient.lowercased().contains(synonym.lowercased()) {
                            if !alerts.contains(allergen) {
                                alerts.append(allergen)
                            }
                            // Once a synonym matches for this allergen, break out
                            break
                        }
                    }
                }
            }
        }
        
        productAllergenAlerts = alerts
        updateAlertView()
    }

    func updateAlertView() {
            if productAllergenAlerts.isEmpty {
                AlertView.isHidden = true
            } else {
                AlertView.isHidden = false
                // Assuming each alert row is 25 points in height
                AlertViewHeight.constant = CGFloat(30*productAllergenAlerts.count+35)
            }
            AlertTableView.reloadData()
        }
    
}
