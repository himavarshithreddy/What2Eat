//
//  NutritionLabelViewController.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit

class NutritionLabelViewController:UIViewController, UITableViewDelegate, UITableViewDataSource,UIPopoverPresentationControllerDelegate {

    @IBOutlet var NutritionLabelTableView: UITableView!
  
    var nutritionData: [NutritionDetail] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        NutritionLabelTableView.delegate = self
        NutritionLabelTableView.dataSource = self
    }
    
        
        // MARK: - UITableViewDataSource Methods
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return nutritionData.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            // Ensure your storyboard cell reuse identifier is set to "NutritionLabelCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionLabelCell", for: indexPath) as? NutritionLabelCell else {
                return UITableViewCell()
            }
            
            let nutrition = nutritionData[indexPath.row]
            cell.NutrientLabel.text = nutrition.name
            cell.NutrientGrams.text = nutrition.value
            cell.RDAPercentage.text = "\(nutrition.rdaPercentage)%"
            cell.minHeight = 60
            return cell
        }
        
        // MARK: - UITableViewDelegate Methods
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Deselect row immediately after selection
            tableView.deselectRow(at: indexPath, animated: true)
        }
    func updateNutrition(with details: [NutritionDetail]) {
          self.nutritionData = details
          DispatchQueue.main.async {
              self.NutritionLabelTableView.reloadData()
          }
      }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        60
//    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 6
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
    }

    


