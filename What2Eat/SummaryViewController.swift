//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit

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
        if let product = product {
                    userAllergens = product.getAllergensForUser(sampleUser) // Replace sampleUser with actual user
                }
        setStarRating(product!.userRating)
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
    
    func setStarRating(_ rating: Float) {
        let starViews = UserRatingStarStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        RatingText.text = "\(rating)"
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
        
       
        updateUserRatingStars(rating)
        
        
    }
    func updateUserRatingStars(_ rating: Int) {
        let starViews = RateStarStackView.arrangedSubviews.compactMap { $0 as? UIImageView }
        
        for (index, star) in starViews.enumerated() {
            if index < rating {
                star.image = UIImage(systemName: "star.fill")
                star.tintColor = .orange
            } else {
                star.image = UIImage(systemName: "star")
            }
        }
    }


        
    }


