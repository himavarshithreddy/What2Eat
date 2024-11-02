//
//  IngredientsViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class IngredientsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var ingredientsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        ingredientsTableView.delegate = self
        ingredientsTableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ingredients.count
    }
  
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath) as! IngredientCell
                let ingredient = ingredients[indexPath.row]
                
                cell.ingredientLabel.text = ingredient.name
                cell.riskLevelLabel.text = ingredient.riskLevel
                cell.riskLevelLabel.textColor = ingredient.riskColor
        let infoButton = UIButton(type: .infoLight)
       
        cell.accessoryView = infoButton
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let verticalPadding: CGFloat = 8
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding/2)
        cell.layer.mask = maskLayer
    }
    

   
    

   

}
