//
//  IngredientDetailViewController.swift
//  What2Eat
//
//  Created by sumanaswi on 10/11/24.
//

import UIKit

class IngredientDetailViewController: UIViewController {
    @IBOutlet weak var riskLevelLabel: UILabel!
    @IBOutlet weak var nutritionalInfoLabel: UILabel!
    @IBOutlet weak var potentialConcernsLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var riskLevelText: String?
    var riskLevelColor: UIColor?
    var nutritionalInfoText: String?
    var potentialConcernsText: String?
    var descriptionText: String?
   

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the labels with the provided data
        riskLevelLabel.text = " \(riskLevelText ?? "N/A")"
         riskLevelLabel.textColor = riskLevelColor
        nutritionalInfoLabel.text = nutritionalInfoText
       potentialConcernsLabel.text = potentialConcernsText
        descriptionLabel.text = descriptionText
    }
}

