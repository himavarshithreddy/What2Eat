//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit

class SummaryViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    var product: Product?
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
        setStarRating(1.5)
        setupEmptyStars()
        setupStarTapGestures()
       SummaryTableView.dataSource = self
    SummaryTableView.delegate = self
        AlertTableView.dataSource = self
        AlertTableView.delegate = self
        
        let VarAlertViewHeight = CGFloat(alerts.count*25+38)
        let VarSummaryTableHeight = CGFloat(NutritionFacts.count*40)
        AlertViewHeight.constant = VarAlertViewHeight
        SummaryTableHeight.constant = VarSummaryTableHeight
       
      
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            return NutritionFacts.count
               } else if tableView.tag == 2 {
                  
                   return alerts.count
              }
              return 0

       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsCell", for: indexPath) as! HighlightsCell
            let highlights = NutritionFacts[indexPath.row]
            cell.HighlightText.text = highlights.text
            cell.iconImage.image = highlights.icon
            cell.iconImage.tintColor = highlights.iconColor
            if highlights.iconColor == .systemRed {
                cell.HighlightText.textColor = .red
            }
            
            
            return cell
        }else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            let alert = alerts[indexPath.row]
            cell.AlertText.text = alert.text
            return cell
        }else {return UITableViewCell()}
            
        
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
                if tableView.tag == 1 {
                    return 40
                }
                else if tableView.tag == 2 {
        return 25
                }
                else {return 0}
        
            }
    
    func setStarRating(_ rating: Float) {
        let starViews = UserRatingStarStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        RatingText.text = "\(rating)"
        
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
            star.tag = index + 1 // Tag each star from 1 to 5 based on its position
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(starTapped(_:)))
            star.addGestureRecognizer(tapGesture)
        }
    }
    @objc func starTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedStar = sender.view as? UIImageView else { return }
        let rating = tappedStar.tag // Get the star's tag as the rating value
        
        // Update the star images based on the selected rating
        updateUserRatingStars(rating)
        
        // Optionally, you can also save or display the user rating value
        print("User selected a rating of \(rating)")
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


