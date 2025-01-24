//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//




//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SummaryViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    var product: Product?
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
        fetchUserAllergensFromFirebase()
    
        if let productId = product?.id {
            if let savedRating = loadUserRatingFromUserDefaults(productId: productId) {
                userRating = savedRating
                updateUserRatingStars(savedRating)
            }
        }
        
        setStarRating(product?.userRating ?? 0)
        setupEmptyStars()
        setupStarTapGestures()
        SummaryTableView.dataSource = self
        SummaryTableView.delegate = self
        AlertTableView.dataSource = self
        AlertTableView.delegate = self
        SummaryTableView.estimatedRowHeight = 40
        let VarAlertViewHeight = CGFloat(userAllergens.count*25+38)
        if userAllergens.count == 0 {
            AlertView.isHidden = true
        }
        let VarSummaryTableHeight = CGFloat(CGFloat(product!.pros.count+product!.cons.count)*52)
        AlertViewHeight.constant = VarAlertViewHeight
        SummaryTableHeight.constant = VarSummaryTableHeight
        
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            return product!.pros.count+product!.cons.count
        } else if tableView.tag == 2 {
            
            return userAllergens.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsCell", for: indexPath) as! HighlightsCell
            let highlights = product!.cons + product!.pros
            let highlight = highlights[indexPath.row]
            cell.HighlightText.text = highlight.description
            cell.iconImage.image = UIImage(systemName:"exclamationmark.triangle.fill")
            cell.iconImage.tintColor = .systemRed
            cell.iconImage.image = indexPath.row < product!.cons.count
            ? UIImage(systemName: "exclamationmark.triangle.fill")
            : UIImage(systemName: "checkmark.square.fill")
            cell.iconImage.tintColor = indexPath.row < product!.cons.count
            ? .systemRed
            : .systemGreen
            
            
            return cell
        }else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            let allergen = userAllergens[indexPath.row]
            cell.AlertText.text = "Contains \(allergen.rawValue)"
            return cell
            
        }else {return UITableViewCell()}
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 1 {
            return UITableView.automaticDimension
        }
        else if tableView.tag == 2 {
            return 25
        }
        else {return 0}
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let productId = product?.id {
            if let savedRating = loadUserRatingFromUserDefaults(productId: productId) {
                userRating = savedRating
                updateUserRatingStars(savedRating)
            }
        }
        
        if let product = product {
            setStarRating(product.userRating)
        }
    }

    
    func setStarRating(_ rating: Float) {
        let starViews = UserRatingStarStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        RatingText.text = String(format: "%.1f", rating)
           NumberOfRatings.text = "\(product!.numberOfRatings) Ratings"
        
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
            star.addGestureRecognizer(tapGesture)
        }
    }
    @objc func starTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedStar = sender.view as? UIImageView else { return }
        let rating = tappedStar.tag
        
        if let productId = product?.id {
            saveUserRatingToUserDefaults(productId: productId, rating: rating)
        }
        
        // Update the product rating logic
        updateProductRating(newRating: rating)
        
        // Update the UI stars
        updateUserRatingStars(rating)
        
        // Update the user's local rating
        userRating = rating
    }
    func saveUserRatingToUserDefaults(productId: UUID, rating: Int) {
        UserDefaults.standard.set(rating, forKey: "userRating_\(productId.uuidString)")
    }
    func loadUserRatingFromUserDefaults(productId: UUID) -> Int? {
        return UserDefaults.standard.integer(forKey: "userRating_\(productId.uuidString)")
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
        
        // Calculate the current total score
        var totalScore = product.userRating * Float(product.numberOfRatings)
        
        // Check if this is a new rating or an update
        if userRating > 0 {
            // Subtract the old rating if the user is updating their rating
            totalScore -= Float(userRating)
        } else {
            // Increment the number of ratings if it's a new rating
            product.numberOfRatings += 1
        }
        
        // Add the new rating to the total score
        totalScore += Float(newRating)
        
        // Update the product's average rating
        let newAverage = totalScore / Float(product.numberOfRatings)
            
            // Round the average rating to 1 decimal place
            product.userRating = round(newAverage * 10) / 10.0
        
        // Save the updated product back to the instance variable
        self.product = product

        // Update the UI
        setStarRating(product.userRating)
        NumberOfRatings.text = "\(product.numberOfRatings) Ratings"
    }

    func fetchUserAllergensFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in. Unable to fetch allergens.")
            userAllergens = [] // Clear allergens if no user is logged in
            AlertView.isHidden = true
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { [weak self] (document, error) in
            if let error = error {
                print("Error fetching user allergens: \(error.localizedDescription)")
                self?.userAllergens = []
                self?.AlertView.isHidden = true
                return
            }

            guard let document = document, document.exists,
                  let allergenList = document.data()?["allergies"] as? [String] else {
                print("No allergens found for user.")
                self?.userAllergens = []
                self?.AlertView.isHidden = true
                return
            }

            // Map allergen strings to the Allergen enum
            let allUserAllergens = allergenList.compactMap { Allergen(rawValue: $0) }

            // Filter allergens to match the product's ingredients
            if let productIngredients = self?.product?.ingredients {
                self?.userAllergens = allUserAllergens.filter { allergen in
                    // Check if any ingredient contains the allergen (case-insensitive)
                    productIngredients.contains { ingredient in
                        ingredient.name.lowercased().contains(allergen.rawValue.lowercased())
                    }
                }
            }

            // Update the alert view with the filtered allergens
            self?.updateAlertView()
        }
    }


    func updateAlertView() {
        let allergenCount = userAllergens.count
        if allergenCount == 0 {
            AlertView.isHidden = true
        } else {
            AlertView.isHidden = false
            AlertViewHeight.constant = CGFloat(allergenCount * 25 + 38)
            AlertTableView.reloadData()
        }
    }


}
                

