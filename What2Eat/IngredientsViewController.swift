import UIKit

class IngredientsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    var product: ProductData?
    @IBOutlet weak var ingredientsTableView: UITableView!
  
    var ingredients: [Ingredient] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        guard product != nil else {
              print("Product is nil")
              return
          }
        ingredientsTableView.delegate = self
        ingredientsTableView.dataSource = self
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return product!.ingredients.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath) as! IngredientCell
        let ingredient = product!.ingredients[indexPath.row]
        cell.ingredientLabel.text = ingredient
        cell.riskLevelLabel.text = ingredient.riskLevel.rawValue
        cell.riskLevelLabel.textColor = UIColor.darkGray
        cell.accessoryType = .detailButton
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
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
            let ingredient = product!.ingredients[indexPath.row]
            
            // Initialize the IngredientDetailViewController
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let ingredientDetailVC = storyboard.instantiateViewController(withIdentifier: "IngredientDetailViewController") as? IngredientDetailViewController {
                
                // Pass the data to the IngredientDetailViewController
                ingredientDetailVC.riskLevelText = ingredient.riskLevel.rawValue
                ingredientDetailVC.riskLevelColor = ingredient.riskColor
                ingredientDetailVC.ingredientName = ingredient.name
                ingredientDetailVC.nutritionalInfoText = ingredient.nutritionalInfo
                ingredientDetailVC.potentialConcernsText = ingredient.potentialConcerns
                ingredientDetailVC.descriptionText = ingredient.description

              
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
                            
                            ingredientDetailVC.presentationController?.delegate = self
                        }
                    }
                    
                    
                }
