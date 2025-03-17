
import UIKit

class IngredientDetailViewController: UIViewController {
    @IBOutlet weak var riskLevelLabel: UILabel!
    @IBOutlet weak var regulatoryStatusLabel: UILabel!
    @IBOutlet weak var potentialConcernsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var IngredientName: UILabel!
    
    var riskLevelText: String?
    var riskLevelColor: UIColor?
    var regulatoryStatus: String?
    var potentialConcernsText: String?
    var descriptionText: String?
    var ingredientName: String?
   

    override func viewDidLoad() {
        
        super.viewDidLoad()
       
        
        // Configure the labels with the provided data
        riskLevelLabel.text = " \(riskLevelText ?? "N/A")"
         riskLevelLabel.textColor = riskLevelColor
        IngredientName.text = ingredientName
        regulatoryStatusLabel.text = regulatoryStatus
       potentialConcernsLabel.text = potentialConcernsText
        descriptionLabel.text = descriptionText
    }
   
   
}

