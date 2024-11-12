//
//  NutritionViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class NutritionViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var NutritionTableView: UITableView!
    var product: Product?
    var nutrients: [Nutrient] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NutritionTableView.delegate = self
        NutritionTableView.dataSource = self
        if let product = product{
            let nutritionInfo = product.nutritionInfo

            nutrients.append(Nutrient(name: "Calories", value: "\(nutritionInfo.calories) kcal", percentage: nil))
            nutrients.append(Nutrient(name: "Fats", value: "\(nutritionInfo.fats) g", percentage: nil))
            nutrients.append(Nutrient(name: "Sugars", value: "\(nutritionInfo.sugars) g", percentage: nil))
            nutrients.append(Nutrient(name: "Protein", value: "\(nutritionInfo.protein) g", percentage: nil))
            nutrients.append(Nutrient(name: "Sodium", value: "\(nutritionInfo.sodium) mg", percentage: nil))
            nutrients.append(Nutrient(name: "Carbohydrates", value: "\(nutritionInfo.carbohydrates) g", percentage: nil))
            for vitamin in nutritionInfo.vitamins {
                nutrients.append(Nutrient(name: vitamin.name, value: "\(vitamin.dailyValue)%", percentage: Float(vitamin.dailyValue) / 100.0))
            }
            
            // Adding minerals
            for mineral in nutritionInfo.minerals {
                nutrients.append(Nutrient(name: mineral.name, value: "\(mineral.dailyValue)%", percentage: Float(mineral.dailyValue) / 100.0))
            }
        }
 }
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nutrients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCell", for: indexPath) as! NutritionCell
        let nutrient = nutrients[indexPath.row]
        
        cell.NutrientLabel.text = nutrient.name
        cell.NutrientGrams.text = nutrient.value
        
        if let percentage = nutrient.percentage {
            cell.NutritionProgress.progress = percentage
            cell.NutritionProgress.isHidden = false
        } else {
            cell.NutritionProgress.isHidden = true
        }

        return cell
    }
}
    
