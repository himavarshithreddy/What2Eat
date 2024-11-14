
import UIKit

class IngredientDetailViewController: UIViewController {
    @IBOutlet weak var riskLevelLabel: UILabel!
    @IBOutlet weak var nutritionalInfoLabel: UILabel!
    @IBOutlet weak var potentialConcernsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var IngredientName: UILabel!
    
    var riskLevelText: String?
    var riskLevelColor: UIColor?
    var nutritionalInfoText: String?
    var potentialConcernsText: String?
    var descriptionText: String?
    var ingredientName: String?
   

    override func viewDidLoad() {
        
        super.viewDidLoad()
       
        
        // Configure the labels with the provided data
        riskLevelLabel.text = " \(riskLevelText ?? "N/A")"
         riskLevelLabel.textColor = riskLevelColor
        IngredientName.text = ingredientName
        nutritionalInfoLabel.text = nutritionalInfoText
       potentialConcernsLabel.text = potentialConcernsText
        descriptionLabel.text = descriptionText
    }
   
    @IBAction func CancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
}

