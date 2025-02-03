import UIKit
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class ProductDetailsViewController: UIViewController {
    var product: ProductData?
    var products:Product?
    var productId: String?
    private var isSaved: Bool {
            return isProductInAnyList(products!)
        }
    @IBOutlet weak var progressView: UIView!


    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var SummarySegmentView: UIView!
   
    @IBOutlet var ProductImage: UIImageView!
    @IBOutlet var ProductName: UILabel!
    @IBOutlet weak var IngredientsSegmentView: UIView!
    @IBOutlet weak var NutritionSegmentView: UIView!
    private var progressLayer: CAShapeLayer!

       override func viewDidLoad() {
           super.viewDidLoad()
          
           guard let productId = productId else {
                  print("❌ No productId found!")
                  return
              }
           fetchProductDetails(productId: productId) { [weak self] fetchedProduct in
                   guard let self = self, let fetchedProduct = fetchedProduct else { return }
                   
                   self.product = fetchedProduct
                   self.setupProductDetails()
                   self.setProgress(to: CGFloat(fetchedProduct.healthScore) / 100)
               }
              
            
           setupCircularProgressBar()
         
           self.view.bringSubviewToFront(SummarySegmentView)
           let bookmarkButton = UIBarButtonItem(
                       image: UIImage(systemName: isSaved ? "bookmark.fill" : "bookmark"),
                       style: .plain,
                       target: self,
                       action: #selector(SavedButtonTapped(_:))
                   )
                   bookmarkButton.tintColor = .systemOrange
                   navigationItem.rightBarButtonItem = bookmarkButton
           NotificationCenter.default.addObserver(self, selector: #selector(handleProductSavedNotification(_:)), name: Notification.Name("ProductSaved"), object: nil)

           
       }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          // Check the identifier of each segue and pass `product` to each child view controller
          if segue.identifier == "showSummary",
             let summaryVC = segue.destination as? SummaryViewController {
              summaryVC.product = products
          } else if segue.identifier == "showIngredients",
                    let ingredientsVC = segue.destination as? IngredientsViewController {
              ingredientsVC.product = products
          } else if segue.identifier == "showNutrition",
                    let nutritionVC = segue.destination as? NutritionViewController {
              nutritionVC.product = products
          }
        else if segue.identifier == "Createnewlist",
                let navigationController = segue.destination as? UINavigationController,
                           let newListVC = navigationController.topViewController as? NewListViewController {
                            newListVC.product = products
          }
      }

       // Function to set up the circular progress bar
    @IBAction func SegmentAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
            self.view.bringSubviewToFront(SummarySegmentView)
        case 1:
            self.view.bringSubviewToFront(IngredientsSegmentView)
        case 2:
            self.view.bringSubviewToFront(NutritionSegmentView)
        default:
            break
        }
        
    }
    @objc private func handleProductSavedNotification(_ notification: Notification) {
        guard let savedProduct = notification.object as? Product else { return }
        
        // Check if the saved product matches the current product
        if savedProduct.id == products?.id {
            updateBookmarkIcon(for: navigationItem.rightBarButtonItem!)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ProductSaved"), object: nil)
    }


    private func setupCircularProgressBar() {
           // 1. Define the circular path
           let center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
           let radius = progressView.bounds.width / 2
           let circularPath = UIBezierPath(
               arcCenter: center,
               radius: radius-18,
               startAngle: -CGFloat.pi / 2,
               endAngle: 1.5 * CGFloat.pi,
               clockwise: true
           )

           // 2. Create the background layer
           let backgroundLayer = CAShapeLayer()
           backgroundLayer.path = circularPath.cgPath
           backgroundLayer.strokeColor = UIColor.white.cgColor
           backgroundLayer.lineWidth = 17 // Set thickness of the circle
           backgroundLayer.fillColor = UIColor.clear.cgColor // No fill, just the outline
           progressView.layer.addSublayer(backgroundLayer)

           // 3. Create the progress layer
           progressLayer = CAShapeLayer()
           progressLayer.path = circularPath.cgPath
           progressLayer.strokeColor = UIColor.orange.cgColor
           progressLayer.lineWidth = 17 // Same thickness as background layer
           progressLayer.fillColor = UIColor.clear.cgColor // No fill
           progressLayer.lineCap = .round // Makes the ends of the progress line rounded
           progressLayer.strokeEnd = 0 // Start with an empty progress (0% filled)
           progressView.layer.addSublayer(progressLayer)
       }

       // Function to update the progress with animation
       func setProgress(to progress: CGFloat, animated: Bool = true) {
           // Clamp the progress between 0 and 1
           let clampedProgress = min(max(progress, 0), 1)
           
           // Update the strokeEnd property
           progressLayer.strokeEnd = clampedProgress
           let percentage = Int(clampedProgress * 100)
        progressLabel.text = "\(percentage)"
           if product!.healthScore < 40 {
               progressLabel.textColor = .systemRed
               progressLayer.strokeColor = UIColor.systemRed.cgColor
                   }
                   else if product!.healthScore < 75 {
                       progressLayer.strokeColor = UIColor.orange.cgColor
                       progressLabel.textColor = .systemOrange
                   }
                   else if product!.healthScore < 100 {
                       progressLayer.strokeColor = UIColor.systemGreen.cgColor
                       progressLabel.textColor = .systemGreen
                   }// Set the text as percentage
           
           
       }
    @IBAction func SavedButtonTapped(_ sender: UIBarButtonItem) {
        guard let product = product else {
                print("No product to save or unsave")
                return
            }

            if isSaved {

                removeProductFromAllLists(products!)
                NotificationCenter.default.post(name: Notification.Name("ProductUnsaved"), object: product)
                print("\(product.name) removed from lists")
            } else {

                let actionSheet = UIAlertController(title: "Select a List to add to", message: nil, preferredStyle: .actionSheet)
                for (index, list) in sampleLists.enumerated() {
                    let action = UIAlertAction(title: list.name, style: .default) { _ in
                        self.addProductToList(at: index, product: self.products!)
                        NotificationCenter.default.post(name: Notification.Name("ProductSaved"), object: product)
                        self.updateBookmarkIcon(for: sender)
                    }
                    actionSheet.addAction(action)
                    action.setValue(UIColor.systemOrange, forKey: "titleTextColor")
                }
                let newListAction = UIAlertAction(title: "New List", style: .default) { _ in
                         
                          self.performSegue(withIdentifier: "Createnewlist", sender: self)
                      }
                      newListAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
                      actionSheet.addAction(newListAction)

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionSheet.addAction(cancelAction)
                cancelAction.setValue(UIColor.systemOrange, forKey: "titleTextColor")
                present(actionSheet, animated: true, completion: nil)
                return
            }

            updateBookmarkIcon(for: sender)
        }

    private func addProductToList(at index: Int, product: Product) {
            guard sampleLists.indices.contains(index) else {
                print("Invalid list index")
                return
            }

            if sampleLists[index].products.contains(where: { $0.id == product.id }) {
                print("\(product.name) is already in the list \(sampleLists[index].name)")
                return
            }

            sampleLists[index].products.append(product)
            print("\(product.name) added to \(sampleLists[index].name)")
        }

    private func removeProductFromAllLists(_ product: Product) {
        for (index, list) in sampleLists.enumerated() {
            if let productIndex = list.products.firstIndex(where: { $0.id == product.id }) {
                sampleLists[index].products.remove(at: productIndex) // Access list by index to make it mutable
            }
        }
    }
    private func isProductInAnyList(_ product: Product) -> Bool {
            return sampleLists.contains { list in
                list.products.contains { $0.id == product.id }
            }
        }

    @objc private func updateBookmarkIcon(for button: UIBarButtonItem) {
        let iconName = isSaved ? "bookmark.fill" : "bookmark"
        button.image = UIImage(systemName: iconName)
    }

    

    private func setupProductDetails() {
            if let product = product {
                ProductName.text = product.name
                ProductImage.image = UIImage(named: product.imageURL)
            }
        }
    func fetchProductDetails(productId: String, completion: @escaping (ProductData?) -> Void) {
        let db = Firestore.firestore()
        db.collection("products").document(productId).getDocument(source: .default) { (document, error) in
            if let error = error {
                print("❌ Error fetching product details: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let document = document, document.exists, let data = document.data() {
                print("✅ Product Details Fetched: \(data)")

                // Extracting basic product details
                let name = data["name"] as? String ?? "Unknown"
                let barcode = data["barcode"] as? String ?? ""
                let imageURL = data["imageURL"] as? String ?? ""
                let ingredients = data["ingredients"] as? [String] ?? []
                let artificialIngredients = data["artificialIngredients"] as? [String] ?? []
                let pros = data["pros"] as? [String] ?? []
                let cons = data["cons"] as? [String] ?? []
                let userRating = data["userRating"] as? Double ?? 0.0
                let numberOfRatings = data["numberOfRatings"] as? Int ?? 0
                let categoryId = data["categoryId"] as? String ?? ""
                let healthScore = data["healthScore"] as? Double ?? 0.0

                // Handling dynamic nutritionInfo
                let nutritionInfo = data["nutritionInfo"] as? [String: String] ?? [:]

                // Create Product instance
                let fetchedProduct = ProductData(
                    id: productId,
                    barcode: barcode,
                    name: name,
                    imageURL: imageURL,
                    ingredients: ingredients,
                    artificialIngredients: artificialIngredients,
                    nutritionInfo: nutritionInfo,
                    userRating: userRating,
                    numberOfRatings: numberOfRatings,
                    categoryId: categoryId,
                    pros: pros,
                    cons: cons,
                    healthScore: healthScore
                )

                completion(fetchedProduct)
                print(fetchedProduct)
            } else {
                print("⚠️ No product found with ID: \(productId)")
                completion(nil)
            }
        }
    }


    }
