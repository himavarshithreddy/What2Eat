import UIKit
import FirebaseFirestore

class IngredientsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {

    
    var product: ProductData? {
        didSet {
            
            DispatchQueue.main.async {
                self.fetchRiskLevels()
                self.ingredientsTableView.reloadData()
               
               
            }
        }
    }
    
    var ingredientRiskLevels: [String: String] = [:]  // Stores ingredient name -> risk level
        var ingredientDetailsCache: [String: IngredientDetail] = [:]
    @IBOutlet weak var ingredientsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ingredientsTableView.delegate = self
        ingredientsTableView.dataSource = self
        ingredientsTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ingredientsTableView.reloadData()
    }
    
    func updateWithProduct(_ product: ProductData) {
        self.product = product
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return product?.ingredients.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath) as! IngredientCell
           
           if let ingredient = product?.ingredients[indexPath.row] {
               cell.ingredientLabel.text = ingredient.description
               if let riskLevel = ingredientRiskLevels[ingredient.description] {
                       let mapping = riskLevelDisplayAndColor(for: riskLevel)
                       cell.riskLevelLabel.text = mapping.displayText
                       cell.riskLevelLabel.textColor = mapping.color
                       cell.riskLevelLabel.isHidden = false
                       cell.accessoryType = .detailButton
                   } else {
                       cell.riskLevelLabel.isHidden = true
                       cell.accessoryType = .none
                   }
           }
           
        
           return cell
       }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 8
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
    func fetchRiskLevels() {
        guard let ingredients = product?.ingredients else { return }
        
        let db = Firestore.firestore()
        
        for ingredient in ingredients {
            let formattedName = ingredient.description.lowercased().replacingOccurrences(of: "\\s+", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            print(formattedName)
            
            db.collection("ingredients").document(formattedName).getDocument { document, error in
                if let error = error {
                    print("Error fetching risk level for \(ingredient.description): \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    print("No document found for \(ingredient.description)")
                    return
                }
                
                let riskLevel = data["RiskLevel"] as? String ?? "N/A"
                
                DispatchQueue.main.async {
                    self.ingredientRiskLevels[ingredient.description] = riskLevel
                    self.ingredientsTableView.reloadData()
                }
            }
        }
    }

    
      func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
          let ingredient = product!.ingredients[indexPath.row]
          let ingredientName = ingredient.description
          
          // Check if details are already cached
          if let cachedDetails = ingredientDetailsCache[ingredientName] {
              presentIngredientDetails(cachedDetails)
          } else {
              fetchIngredientDetails(ingredientName)
          }
      }
    func riskLevelDisplayAndColor(for riskLevel: String) -> (displayText: String, color: UIColor) {
          switch riskLevel.lowercased() {
          case "risk-free":
              return ("Risk-free", UIColor.systemGreen)
          case "low":
              return ("Low Risk", UIColor(red: 152/255, green: 168/255, blue: 124/255, alpha: 1))
          case "medium":
              return ("Medium Risk", UIColor(red: 204/255, green: 85/255, blue: 0/255, alpha: 1))
          case "high":
              return ("High Risk", UIColor.red)
          default:
              return (riskLevel, UIColor.black)
          }
      }
    func fetchIngredientDetails(_ ingredientName: String) {
        let db = Firestore.firestore()
        let formattedName = ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("ingredients").document(formattedName).getDocument { document, error in
            if let error = error {
                print("Error fetching details for \(ingredientName): \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("No document found for \(ingredientName)")
                return
            }
            
            print("Snapshot data for \(ingredientName): \(data)")
            
            let details = IngredientDetail(
                name: ingredientName,
                description: data["Description"] as? String ?? "No description",
                potentialConcern: data["PotentialConcern"] as? String ?? "No concerns",
                regulatoryStatus: data["RegulatoryStatus"] as? String ?? "No info",
                riskLevel: data["RiskLevel"] as? String ?? "N/A"
            )
            
            self.ingredientDetailsCache[ingredientName] = details
            
            DispatchQueue.main.async {
                self.presentIngredientDetails(details)
            }
        }
    }

        // Show ingredient details in popup
        func presentIngredientDetails(_ details: IngredientDetail) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let ingredientDetailVC = storyboard.instantiateViewController(withIdentifier: "IngredientDetailViewController") as? IngredientDetailViewController {
                
                ingredientDetailVC.ingredientName = details.name
                let mapping = riskLevelDisplayAndColor(for: details.riskLevel)
                            ingredientDetailVC.riskLevelText = mapping.displayText
                            ingredientDetailVC.riskLevelColor = mapping.color
                ingredientDetailVC.descriptionText = details.description
                ingredientDetailVC.potentialConcernsText = details.potentialConcern
                ingredientDetailVC.regulatoryStatus = details.regulatoryStatus
                
                
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
            }
        }
        
        
    }
