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
    var userDietaryRestrictions: [DietaryRestriction] = []
    var dietaryRestrictionAlerts: [DietaryRestriction] = []
    
    @IBOutlet var RemoveRating: UILabel!
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

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SummaryTableView.dataSource = self
        SummaryTableView.delegate = self
        AlertTableView.dataSource = self
        AlertTableView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(removeUserRating))
            
            // Add gesture to the label
        RemoveRating.addGestureRecognizer(tapGesture)
        RemoveRating.isHidden = true
        AlertView.isHidden = true
        SummaryTableView.estimatedRowHeight = 30
        SummaryTableView.rowHeight = UITableView.automaticDimension
        
        // Setup rating UI
        setStarRating(Float(product?.userRating ?? 0))
        setupEmptyStars()
        setupStarTapGestures()
        
        fetchUserAllergensForSummary()
        fetchUserDietaryRestrictions()
        AlertTableView.sectionHeaderHeight = 0
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let product = product {
            setStarRating(product.userRating)
        }
        fetchUserRatingFromFirestore()
    }
    
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
            return (productAllergenAlerts.isEmpty && dietaryRestrictionAlerts.isEmpty) ? 0 : 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            if let product = productAnalysis {
                if !product.pros.isEmpty && section == 0 {
                    return product.pros.count
                } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                    return product.cons.count
                }
            }
        } else if tableView.tag == 2 {
            return productAllergenAlerts.count + dietaryRestrictionAlerts.count
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
                    let pro = product.pros[indexPath.row]
                    cell.HighlightText.text = pro.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "checkmark.square.fill")
                    cell.iconImage.tintColor = .systemGreen
                    
                    if pro.summaryPoint != "Contains some nutrients" {
                        let proValueText = pro.value < 0.1 ? "<0.1" : String(format: "%.1f", pro.value)
                        cell.DescriptionText.text = pro.value >= 85 ? ">85% of your RDA, check serving size, may exceed your needs" : "\(proValueText)% of your recommended daily Intake."
                        cell.ProgressBar.progress = Float(pro.value) / 100.0
                        cell.ProgressBar.progressTintColor = .systemGreen
                        cell.ProgressBar.alpha = 1
                    } else {
                        cell.DescriptionText.text = "Check Nutrition tab for more Details"
                        cell.ProgressBar.progress = 0.0
                        cell.ProgressBar.alpha = 0.0
                    }
                    
                } else if !product.cons.isEmpty && indexPath.section == (product.pros.isEmpty ? 0 : 1) {
                    let con = product.cons[indexPath.row]
                    cell.HighlightText.text = con.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    cell.iconImage.tintColor = .systemRed
                    if con.summaryPoint != "No major concerns detected" {
                        let conValueText = con.value < 0.1 ? "<0.1" : String(format: "%.1f", con.value)
                        cell.DescriptionText.text = con.value >= 100 ? ">100% of your RDA, check serving size" : "\(conValueText)% of your recommended daily Intake."
                        cell.ProgressBar.progress = Float(con.value) / 100.0
                        cell.ProgressBar.progressTintColor = .systemRed
                        cell.ProgressBar.alpha = 1
                    } else {
                        cell.DescriptionText.text = "Check Nutrition tab for more Details"
                        cell.ProgressBar.progress = 0.0
                        cell.ProgressBar.alpha = 0.0
                    }
                }
            }
            
            cell.configureExpandButton(isExpanded: isExpanded)
            cell.onExpandButtonTapped = { [weak self] in
                guard let self = self else { return }
                self.expandedIndexPaths[indexPath] = !isExpanded
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
                self.updateSummaryTableHeight()
            }
            
            cell.DescriptionText.isHidden = !isExpanded
            cell.ProgressBar.isHidden = !isExpanded
            cell.HighlightText.numberOfLines = 0
            cell.DescriptionText.numberOfLines = 0
            return cell
            
        } else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            let totalAllergens = productAllergenAlerts.count
            if indexPath.row < totalAllergens {
                let allergen = productAllergenAlerts[indexPath.row]
                cell.AlertText.text = "Contains \(allergen.rawValue)"
            } else {
                let dietaryIndex = indexPath.row - totalAllergens
                let restriction = dietaryRestrictionAlerts[dietaryIndex]
                cell.AlertText.text = "Violates \(restriction.rawValue)"
            }
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
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        
        if let product = productAnalysis {
            if !product.pros.isEmpty && section == 0 {
                titleLabel.text = "What’s Good 🙂"
            } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                titleLabel.text = "What’s Concerning ❗"
            }
        }
        
        headerView.addSubview(titleLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 1 {
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            return isExpanded ? 100 : 50
        } else if tableView.tag == 2 {
            return 25
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 1 {
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            expandedIndexPaths[indexPath] = !isExpanded
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            updateSummaryTableHeight()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func updateSummaryTableHeight() {
        guard let product = productAnalysis else { return }
        var totalHeight: CGFloat = 0
        var headerHeight: CGFloat = 0
        
        if !product.pros.isEmpty {
            headerHeight += 50
            for row in 0..<product.pros.count {
                let indexPath = IndexPath(row: row, section: 0)
                let isExpanded = expandedIndexPaths[indexPath] ?? false
                totalHeight += isExpanded ? 100 : 50
            }
        }
        if !product.cons.isEmpty {
            headerHeight += 50
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
    
    private func updateUI() {
        updateSummaryTableHeight()
        updateAlertView()
        SummaryTableView.reloadData()
        AlertTableView.reloadData()
    }
    
    // MARK: - Rating Star Methods
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
            star.tintColor = .gray
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
        guard Auth.auth().currentUser != nil else {
            showAuthenticationAlert()
            return
        }
        let rating = tappedStar.tag
        updateProductRating(newRating: rating)
        updateUserRatingStars(rating)
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
    
    // MARK: - Updated Rating Mechanism with Firestore Transaction
    func updateProductRating(newRating: Int) {
        guard let product = product, let userId = Auth.auth().currentUser?.uid else { return }
        let productId = product.id

        RemoveRating.isHidden = false
        let db = Firestore.firestore()
        let productRef = db.collection("products").document(productId)
        let userRatingRef = productRef.collection("ratings").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let productDoc: DocumentSnapshot
            do {
                productDoc = try transaction.getDocument(productRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            var oldUserRating: Int? = nil
            if let userRatingDoc = try? transaction.getDocument(userRatingRef),
               userRatingDoc.exists,
               let existingRating = userRatingDoc.data()?["rating"] as? Int {
                oldUserRating = existingRating
            }
            
            let oldAverage = productDoc.data()?["userRating"] as? Float ?? 0.0
            let oldCount = productDoc.data()?["numberOfRatings"] as? Int ?? 0
            
            var newCount = oldCount
            var newAverage: Float = oldAverage
            
            if let oldRating = oldUserRating {
                newAverage = ((oldAverage * Float(oldCount)) - Float(oldRating) + Float(newRating)) / Float(oldCount)
            } else {
                newCount += 1
                newAverage = ((oldAverage * Float(oldCount)) + Float(newRating)) / Float(newCount)
            }
            
            transaction.updateData([
                "userRating": newAverage,
                "numberOfRatings": newCount
            ], forDocument: productRef)
            
            transaction.setData([
                "rating": newRating,
                "timestamp": Timestamp()
            ], forDocument: userRatingRef)
            
            return ["newAverage": newAverage, "newCount": newCount]
        }) { (result, error) in
            if let error = error {
                print("Transaction error: \(error.localizedDescription)")
            } else {
                print("Rating updated successfully!")
                if let result = result as? [String: Any],
                   let newAverage = result["newAverage"] as? Float,
                   let newCount = result["newCount"] as? Int {
                    if var product = self.product {
                        product.userRating = round(newAverage * 10) / 10.0
                        product.numberOfRatings = newCount
                        self.product = product
                        DispatchQueue.main.async {
                            self.setStarRating(product.userRating)
                            self.NumberOfRatings.text = "\(product.numberOfRatings) Ratings"
                        }
                    }
                }
                self.fetchUserRatingFromFirestore()
            }
        }
    }
    
    func fetchUserRatingFromFirestore() {
        guard let productId = product?.id,
              let userId = Auth.auth().currentUser?.uid else {
            print("Product ID or user not available")
            return
        }
        
        let db = Firestore.firestore()
        let userRatingRef = db.collection("products").document(productId).collection("ratings").document(userId)
        
        userRatingRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user rating: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists, let rating = document.data()?["rating"] as? Int {
                DispatchQueue.main.async {
                    self.userRating = rating
                    self.RemoveRating.isHidden = false
                    self.updateUserRatingStars(rating)
                }
            } else {
                DispatchQueue.main.async {
                    self.userRating = 0
                    self.setupEmptyStars()
                }
            }
        }
    }
    
    // MARK: - Allergen and Dietary Restrictions Methods
    func fetchUserAllergensForSummary() {
        let defaults = UserDefaults.standard
        if let localAllergies = defaults.array(forKey: "localAllergies") as? [String], !localAllergies.isEmpty {
            userAllergens = localAllergies.compactMap { Allergen(rawValue: $0) }
            compareAllergens()
        } else if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            userDocument.getDocument { [weak self] (document, error) in
                if let document = document, document.exists,
                   let allergiesFromDB = document.get("allergies") as? [String] {
                    self?.userAllergens = allergiesFromDB.compactMap { Allergen(rawValue: $0) }
                    defaults.set(allergiesFromDB, forKey: "localAllergies")
                    self?.compareAllergens()
                }
            }
        }
    }
    
    func compareAllergens() {
        guard let product = product else {
            self.productAllergenAlerts = []
            updateAlertView()
            return
        }
        
        var alerts: [Allergen] = []
        
        func checkForMatches(_ items: [String], against allergens: [Allergen]) -> [Allergen] {
            var matchedAllergens: [Allergen] = []
            for allergen in allergens {
                if let synonyms = allergenMapping[allergen.rawValue] {
                    for synonym in synonyms {
                        for item in items {
                            if item.lowercased().contains(synonym.lowercased()) {
                                if !matchedAllergens.contains(allergen) {
                                    matchedAllergens.append(allergen)
                                }
                                break
                            }
                        }
                    }
                }
            }
            return matchedAllergens
        }
        
        if let productAllergens = product.allergens {
            let allergenMatches = checkForMatches(productAllergens, against: userAllergens)
            alerts.append(contentsOf: allergenMatches)
        }
        
        let ingredientMatches = checkForMatches(product.ingredients, against: userAllergens)
        for match in ingredientMatches {
            if !alerts.contains(match) {
                alerts.append(match)
            }
        }
        
        productAllergenAlerts = alerts
        updateAlertView()
    }
    
    func updateAlertView() {
        let totalAlerts = productAllergenAlerts.count + dietaryRestrictionAlerts.count
        if totalAlerts == 0 {
            AlertView.isHidden = true
        } else {
            AlertView.isHidden = false
            AlertViewHeight.constant = CGFloat(30 * totalAlerts + 35)
        }
        AlertTableView.reloadData()
    }
    
    func fetchUserDietaryRestrictions() {
        let defaults = UserDefaults.standard
        if let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String], !localRestrictions.isEmpty {
            userDietaryRestrictions = localRestrictions.compactMap { dietaryRestrictionMapping[$0] }
            compareDietaryRestrictions()
        } else if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            userDocument.getDocument { [weak self] (document, error) in
                if let document = document, document.exists,
                   let restrictionsFromDB = document.get("dietaryRestrictions") as? [String] {
                    self?.userDietaryRestrictions = restrictionsFromDB.compactMap { dietaryRestrictionMapping[$0] }
                    defaults.set(restrictionsFromDB, forKey: "localDietaryRestrictions")
                    self?.compareDietaryRestrictions()
                }
            }
        }
    }
    
    func compareDietaryRestrictions() {
        guard let product = product else {
            dietaryRestrictionAlerts = []
            updateAlertView()
            return
        }
        var alerts: [DietaryRestriction] = []
        for restriction in userDietaryRestrictions {
            if let rule = dietaryRestrictionRules[restriction], !rule(product) {
                alerts.append(restriction)
            }
        }
        dietaryRestrictionAlerts = alerts
        updateAlertView()
    }
    
    // MARK: - Product Update Method
    func updateWithProduct(_ product: ProductData) {
        self.product = product
        DispatchQueue.main.async {
            fetchUserData { user in
                guard let user = user else { return }
                self.productAnalysis = generateProsAndCons(product: product, user: user)
            }
            self.setStarRating(product.userRating)
            self.NumberOfRatings.text = "\(product.numberOfRatings) Ratings"
            self.updateSummaryTableHeight()
            self.fetchUserRatingFromFirestore()
            self.SummaryTableView.reloadData()
            self.compareAllergens()
            self.compareDietaryRestrictions()
        }
    }
    @objc func removeUserRating() {
        RemoveRating.isHidden = true
        guard let product = product, let userId = Auth.auth().currentUser?.uid else { return }
        let productId = product.id
        let db = Firestore.firestore()
        let productRef = db.collection("products").document(productId)
        let userRatingRef = productRef.collection("ratings").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Get the product document
            let productDoc: DocumentSnapshot
            do {
                productDoc = try transaction.getDocument(productRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let oldAverage = productDoc.data()?["userRating"] as? Float,
                  let oldCount = productDoc.data()?["numberOfRatings"] as? Int,
                  oldCount > 0 else {
                return nil
            }
            
            // Get the user's rating document
            let userRatingDoc: DocumentSnapshot
            do {
                userRatingDoc = try transaction.getDocument(userRatingRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            // Ensure the user had previously rated
            guard let oldUserRating = userRatingDoc.data()?["rating"] as? Int else {
                // Nothing to remove since no rating exists
                return nil
            }
            
            // Calculate new aggregate values after removal
            let newCount = oldCount - 1
            var newAverage: Float = 0.0
            if newCount > 0 {
                newAverage = ((oldAverage * Float(oldCount)) - Float(oldUserRating)) / Float(newCount)
            }
            
            // Update the product document with new average and count
            transaction.updateData([
                "userRating": newAverage,
                "numberOfRatings": newCount
            ], forDocument: productRef)
            
            // Delete the user's rating document
            transaction.deleteDocument(userRatingRef)
            
            return ["newAverage": newAverage, "newCount": newCount]
            
        }) { (result, error) in
            if let error = error {
                print("Failed to remove rating: \(error.localizedDescription)")
            } else {
                print("User rating removed successfully!")
                if let result = result as? [String: Any],
                   let newAverage = result["newAverage"] as? Float,
                   let newCount = result["newCount"] as? Int {
                    if var product = self.product {
                        product.userRating = newAverage
                        product.numberOfRatings = newCount
                        self.product = product
                        DispatchQueue.main.async {
                            self.setStarRating(product.userRating)
                            self.NumberOfRatings.text = "\(product.numberOfRatings) Ratings"
                            self.setupEmptyStars()
                        }
                    }
                }
                self.fetchUserRatingFromFirestore()
            }
        }
    }

}
