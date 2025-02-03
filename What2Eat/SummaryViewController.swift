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

    var userAllergens: [Allergen] = []
    
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
        SummaryTableView.estimatedRowHeight = 30
        SummaryTableView.rowHeight = 40

                // Setup stars for user rating
        setStarRating(Float(product?.userRating ?? 0))
        setupEmptyStars()
        setupStarTapGestures()
        
      
       
    }
    
    
    // MARK: - TableView DataSource & Delegate Methods
    

    
    // MARK: - TableView DataSource & Delegate Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 1 {
            var sections = 0
            if let product = product {
                if !product.pros.isEmpty { sections += 1 }
                if !product.cons.isEmpty { sections += 1 }
            }
            return sections
        } else if tableView.tag == 2 {
            return 1 // For allergens (or other data)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            if let product = product {
                // Adjust section index based on the available pros and cons
                if !product.pros.isEmpty && section == 0 {
                    return product.pros.count // Pros section
                } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                    return product.cons.count // Cons section
                }
            }
        } else if tableView.tag == 2 {
            return userAllergens.count // Allergen section
        }
        return 0
    }



    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsCell", for: indexPath) as! HighlightsCell
            
            if let product = product {
                if !product.pros.isEmpty && indexPath.section == 0 {
                    // Pros section
                    let pro = product.pros[indexPath.row]
                    cell.HighlightText.text = pro.description
                    cell.iconImage.image = UIImage(systemName: "checkmark.square.fill")
                    cell.iconImage.tintColor = .systemGreen
                } else if !product.cons.isEmpty && indexPath.section == (product.pros.isEmpty ? 0 : 1) {
                    // Cons section
                    let con = product.cons[indexPath.row]
                    cell.HighlightText.text = con.description
                    cell.iconImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    cell.iconImage.tintColor = .systemRed
                }
            }
            
            return cell
        } else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            let allergen = userAllergens[indexPath.row]
            cell.AlertText.text = "Contains \(allergen.rawValue)"
            return cell
        }
        
        return UITableViewCell()
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20 // Adjust header height as needed
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: -10, width: tableView.frame.size.width, height: 25)
        
        // Customize the appearance of the header
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

        titleLabel.textColor = .black // Text color
        titleLabel.textAlignment = .left // Align text to the left
        
        if let product = product {
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
            return 40
        } else if tableView.tag == 2 {
            return 25
        }
        return 0
    }
    private func updateSummaryTableHeight() {
        guard let product = product else { return }

        var numberOfRows = 0
        var headerHeight: CGFloat = 0
        if !product.pros.isEmpty {
            numberOfRows += product.pros.count
            headerHeight += 40
        }
        if !product.cons.isEmpty {
            numberOfRows += product.cons.count
            headerHeight += 40
        }

        // Calculate the new height based on the number of rows and row height
        let rowHeight: CGFloat = 42 // Match the row height set in tableView(_:heightForRowAt:)
        let newHeight = (CGFloat(numberOfRows) * rowHeight) + headerHeight // 80 for header heights

        // Update the height constraint
        SummaryTableHeight.constant = newHeight

        // Force layout update to avoid animation delays
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

    
    
    // MARK: - User Allergens
    
//    func fetchUserAllergensFromFirebase() {
//        guard let userId = Auth.auth().currentUser?.uid else {
//            print("User not logged in. Unable to fetch allergens.")
//            userAllergens = []
//            AlertView.isHidden = true
//            return
//        }
//
//        let db = Firestore.firestore()
//        let userRef = db.collection("users").document(userId)
//
//        userRef.getDocument { [weak self] (document, error) in
//            if let error = error {
//                print("Error fetching user allergens: \(error.localizedDescription)")
//                self?.userAllergens = []
//                self?.AlertView.isHidden = true
//                return
//            }
//
//            guard let document = document, document.exists,
//                  let allergenList = document.data()?["allergies"] as? [String] else {
//                print("No allergens found for user.")
//                self?.userAllergens = []
//                self?.AlertView.isHidden = true
//                return
//            }
//
//            // Map allergen strings to the Allergen enum
//            let allUserAllergens = allergenList.compactMap { Allergen(rawValue: $0) }
//
//            // Filter allergens to match the product's ingredients if available
//            if let productIngredients = self?.product?.ingredients {
//                self?.userAllergens = allUserAllergens.filter { allergen in
//                    productIngredients.contains { ingredient in
//                        ingredient.lowercased().contains(allergen.rawValue.lowercased())
//                    }
//                }
//            } else {
//                self?.userAllergens = []
//            }
//
//            // Update the alert view with the filtered allergens
//            self?.updateAlertView()
//        }
//    }
//    
//    func updateAlertView() {
//        let allergenCount = userAllergens.count
//        if allergenCount == 0 {
//            AlertView.isHidden = true
//        } else {
//            AlertView.isHidden = false
//            AlertViewHeight.constant = CGFloat(allergenCount * 25 + 38)
//            AlertTableView.reloadData()
//        }
//    }
    
    
    // MARK: - Public Update Method
    
    /// Call this method from the parent view controller once the product is fetched.
    func updateWithProduct(_ product: ProductData) {
        self.product = product
        
        // Update UI on the main thread
        DispatchQueue.main.async {
            // Update star rating and number of ratings
            self.setStarRating(product.userRating)
            self.NumberOfRatings.text = "\(product.numberOfRatings) Ratings"
            
            // Update table view height for pros & cons
            self.updateSummaryTableHeight()
            self.fetchUserRatingFromFirestore()
            
            // Reload the summary table view to reflect new data
            self.SummaryTableView.reloadData()
            
            // Now that product is available, fetch allergens again to update alert view
            
        }
    }

}
