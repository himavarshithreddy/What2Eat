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
               let riskLevel = ingredientRiskLevels[ingredient.description] ?? "N/A"
               cell.riskLevelLabel.text = riskLevel
               cell.riskLevelLabel.textColor = UIColor.black
           }
           
           cell.accessoryType = .detailButton
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
            let ingredientName = ingredient.description
            
            db.collection("ingredients")
                .whereField("IngredientName", isEqualTo: ingredientName)
                .getDocuments { querySnapshot, error in
                    
                    if let error = error {
                        print("Error fetching risk level for \(ingredientName): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = querySnapshot, !snapshot.documents.isEmpty else {
                        print("No document found for \(ingredientName)")
                        return
                    }
                    
                    // Assuming there's only one document per ingredient name
                    let document = snapshot.documents[0]
                    let data = document.data()
                    
                    let riskLevel = data["RiskLevel"] as? String ?? "Unknown"
                    
                    DispatchQueue.main.async {
                        self.ingredientRiskLevels[ingredientName] = riskLevel
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
    func fetchIngredientDetails(_ ingredientName: String) {
        let db = Firestore.firestore()
        
        db.collection("ingredients")
          .whereField("IngredientName", isEqualTo: ingredientName)
          .getDocuments { (querySnapshot, error) in
              
              if let error = error {
                  print("Error fetching details for \(ingredientName): \(error.localizedDescription)")
                  return
              }
              
              guard let snapshot = querySnapshot, !snapshot.documents.isEmpty else {
                  print("No document found for \(ingredientName)")
                  return
              }
              
              // Assuming there's only one document per ingredientName:
              let document = snapshot.documents[0]
              let data = document.data()
              
              print("Snapshot data for \(ingredientName): \(data)")
              
              let details = IngredientDetail(
                  name: ingredientName,
                  description: data["Description"] as? String ?? "No description",
                  potentialConcern: data["PotentialConcern"] as? String ?? "No concerns",
                  regulatoryStatus: data["RegulatoryStatus"] as? String ?? "No info",
                  riskLevel: data["RiskLevel"] as? String ?? "Unknown"
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
                ingredientDetailVC.riskLevelText = details.riskLevel
                ingredientDetailVC.riskLevelColor = UIColor.black
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
