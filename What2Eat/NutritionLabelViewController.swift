//
//  NutritionLabelViewController.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit

class NutritionLabelViewController:UIViewController, UITableViewDelegate, UITableViewDataSource,UIPopoverPresentationControllerDelegate {

    @IBOutlet var NutritionLabelTableView: UITableView!
    
    var nutritionData: [(name: String, value: String)] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        NutritionLabelTableView.delegate = self
        NutritionLabelTableView.dataSource = self
        loadNutritionData()

    }
    func loadNutritionData() {
            // Sample local data; replace with your actual data if available.
            nutritionData = [
                (name: "Calories", value: "250 kcal"),
                (name: "Total Fat", value: "10 g"),
                (name: "Sodium", value: "200 mg"),
                (name: "Carbohydrates", value: "30 g"),
                (name: "Protein", value: "5 g")
            ]
        NutritionLabelTableView.reloadData()
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
            
            return cell
        }
        
        // MARK: - UITableViewDelegate Methods
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Deselect row immediately after selection
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    


