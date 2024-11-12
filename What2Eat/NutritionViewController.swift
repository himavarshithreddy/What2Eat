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
        NutritionTableView.delegate = self
        NutritionTableView.dataSource = self
        

        // Do any additional setup after loading the view.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nutritionFacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCell", for: indexPath) as! NutritionCell
        let nutritionFact = nutritionFacts[indexPath.row]
        cell.NutrientLabel.text = nutritionFact.name
        cell.NutrientGrams.text = nutritionFact.amount

        cell.NutritionProgress.progress = nutritionFact.percentage

           return cell
    }
    

  
    

    
}
