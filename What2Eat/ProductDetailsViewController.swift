
import UIKit

class ProductDetailsViewController: UIViewController {
    var product: Product?
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
           setupCircularProgressBar()
           setupProductDetails()  // Set up product details
           setProgress(to: CGFloat(product!.healthScore))
           self.view.bringSubviewToFront(SummarySegmentView)
       }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          // Check the identifier of each segue and pass `product` to each child view controller
          if segue.identifier == "showSummary",
             let summaryVC = segue.destination as? SummaryViewController {
              summaryVC.product = product
          } else if segue.identifier == "showIngredients",
                    let ingredientsVC = segue.destination as? IngredientsViewController {
              ingredientsVC.product = product
          } else if segue.identifier == "showNutrition",
                    let nutritionVC = segue.destination as? NutritionViewController {
              nutritionVC.product = product
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
                   progressLabel.text = "\(percentage)" // Set the text as percentage
           
           
       }
    @IBAction func SavedButtonTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Select a List to add to", message:nil, preferredStyle: .actionSheet)
        for list in sampleLists {
            let action = UIAlertAction(title: list.name, style: .default) { _ in
                print("Selected list: \(list)")
            }
            //actionSheet.view.backgroundColor = UIColor(red: 221, green: 215, blue: 205, alpha: 1)
            actionSheet.view.tintColor = .systemOrange
            actionSheet.view.layer.cornerRadius = 14
            actionSheet.view.layer.masksToBounds = true
            actionSheet.addAction(action)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionSheet.addAction(cancelAction)

                // Present the action sheet
                present(actionSheet, animated: true, completion: nil)
    }
    private func setupProductDetails() {
          if let product = product {
              
              self.title = product.name
              progressLabel.text = "\(Int(product.healthScore))"
              ProductName.text = product.name
              ProductImage.image = UIImage(named: product.imageURL)
              
             
          }
      }
}
