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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard product != nil else {
              print("Product is nil")
              return
          }
        NutritionTableView.delegate = self
        NutritionTableView.dataSource = self
        

        // Do any additional setup after loading the view.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nutrients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCell", for: indexPath) as! NutritionCell
        let nutrition = nutrients[indexPath.row]
        var nutritionValue: Double = 0.0  // Default value

                switch nutrition.name {
                case "Calories":
                    nutritionValue = Double(product?.nutritionInfo.energy ?? 0)
                case "Fats":
                    nutritionValue = product?.nutritionInfo.fats ?? 0
                case "Sugars":
                    nutritionValue = product?.nutritionInfo.sugars ?? 0
                case "Protein":
                    nutritionValue = product?.nutritionInfo.protein ?? 0
                case "Sodium":
                    nutritionValue = product?.nutritionInfo.sodium ?? 0
                case "Carbohydrates":
                    nutritionValue = product?.nutritionInfo.carbohydrates ?? 0
                case "Vitamin B":
                    nutritionValue = product?.nutritionInfo.vitaminB ?? 0
                case "Iron":
                    nutritionValue = product?.nutritionInfo.iron ?? 0
                default:
                    break
                }
        cell.NutrientLabel.text = nutrition.name
        
        cell.NutrientGrams.text = String(format: "%.1f g", nutritionValue)

        cell.NutritionProgress.progress = Float(nutritionValue/100)

           return cell
    }
    
   
    

    
}
