//
//  IngredientsLabelViewController.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit

class IngredientsLabelViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
   
    var ingredientDetails: [IngredientDetail] = [] {
            didSet {
                DispatchQueue.main.async {
                    self.ingredientsLabelTableView.reloadData()
                }
            }
        }
    
    @IBOutlet var ingredientsLabelTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ingredientsLabelTableView.delegate = self
                ingredientsLabelTableView.dataSource = self
                
                loadIngredientData()
        // Do any additional setup after loading the view.
    }
    func loadIngredientData() {
            // Replace with your actual data source if available
            ingredientDetails = [
                IngredientDetail(name: "Sugar",
                                 description: "A common sweetener extracted from sugar cane or sugar beets.",
                                 potentialConcern: "High consumption may lead to health issues.",
                                 regulatoryStatus: "Approved",
                                 riskLevel: "Low"),
                IngredientDetail(name: "Milk",
                                 description: "Dairy product obtained from cows.",
                                 potentialConcern: "Contains allergens for lactose-intolerant individuals.",
                                 regulatoryStatus: "Approved",
                                 riskLevel: "High"),
                IngredientDetail(name: "Flour",
                                 description: "Ground wheat product, often used in baking.",
                                 potentialConcern: "May contain gluten which is problematic for some.",
                                 regulatoryStatus: "Approved",
                                 riskLevel: "Medium")
            ]
        }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ingredientsLabelTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return ingredientDetails.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientsLabelCell", for: indexPath) as? IngredientsLabelCell else {
                return UITableViewCell()
            }
            
            let ingredient = ingredientDetails[indexPath.row]
            cell.ingredientLabel.text = ingredient.name
            
            // Map risk level to display text and color
            let mapping = riskLevelDisplayAndColor(for: ingredient.riskLevel)
            cell.riskLabel.text = mapping.displayText
            cell.riskLabel.textColor = mapping.color
            cell.riskLabel.isHidden = false
            cell.accessoryType = .detailButton
            
            return cell
        }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 8
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(
            x: cell.bounds.origin.x,
            y: cell.bounds.origin.y,
            width: cell.bounds.width,
            height: cell.bounds.height
        ).insetBy(dx: 0, dy: verticalPadding / 2)
        cell.layer.mask = maskLayer
    }
        // Helper function to map risk level strings to display values and colors
        func riskLevelDisplayAndColor(for riskLevel: String) -> (displayText: String, color: UIColor) {
            switch riskLevel.lowercased() {
            case "risk-free":
                return ("Risk-free", UIColor.systemGreen)
            case "low":
                return ("Low Risk", UIColor(red: 152/255, green: 168/255, blue: 124/255, alpha: 1))
            case "medium":
                return ("Medium Risk", UIColor(red: 204/255, green: 85/255, blue: 0/255, alpha: 1))
            case "high":
                return ("High Risk", UIColor.red)
            default:
                return (riskLevel, UIColor.black)
            }
        }
    
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           // Deselect the row if needed
           tableView.deselectRow(at: indexPath, animated: true)
       }
       
       // When tapping the accessory (detail) button, present details in a popup.
       func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
           let ingredient = ingredientDetails[indexPath.row]
           presentIngredientDetails(ingredient)
       }
       
       // MARK: - Presenting Ingredient Details
       
       func presentIngredientDetails(_ detail: IngredientDetail) {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let ingredientDetailVC = storyboard.instantiateViewController(withIdentifier: "IngredientDetailViewController") as? IngredientDetailViewController {
               
               ingredientDetailVC.ingredientName = detail.name
               let mapping = riskLevelDisplayAndColor(for: detail.riskLevel)
               ingredientDetailVC.riskLevelText = mapping.displayText
               ingredientDetailVC.riskLevelColor = mapping.color
               ingredientDetailVC.descriptionText = detail.description
               ingredientDetailVC.potentialConcernsText = detail.potentialConcern
               ingredientDetailVC.regulatoryStatus = detail.regulatoryStatus
               
               ingredientDetailVC.modalPresentationStyle = .pageSheet
               if let sheet = ingredientDetailVC.sheetPresentationController {
                   let customDetent = UISheetPresentationController.Detent.custom { _ in
                       return 350
                   }
                   sheet.detents = [customDetent]
                   sheet.prefersGrabberVisible = true
                   sheet.preferredCornerRadius = 22
               }
               
               present(ingredientDetailVC, animated: true, completion: nil)
           }
       }
   }

    


