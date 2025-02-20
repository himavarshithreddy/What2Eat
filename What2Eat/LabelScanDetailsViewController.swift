//
//  LabelScanDetailsViewController.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit

class LabelScanDetailsViewController: UIViewController {

    var product: ProductData?
    
    @IBOutlet weak var progressView: UIView!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var SummarySegmentView: UIView!
    
    @IBOutlet weak var IngredientsSegmentView: UIView!
    
    @IBOutlet weak var NutritionSegmentView: UIView!
    
    @IBOutlet var ProductImage: UIImageView!
    
    
  
    @IBOutlet var ProductName: UILabel!
    
    private var progressLayer: CAShapeLayer!
    weak var summaryVC: SummaryViewController?
    weak var ingredientsVC: IngredientsViewController?
    weak var nutritionVC: NutritionViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProductDetails()
        setupCircularProgressBar()
        
        // Do any additional setup after loading the view.
        self.view.bringSubviewToFront(SummarySegmentView)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "showSummary",
              let vc = segue.destination as? SummaryViewController {
               summaryVC = vc
               if let product = product { vc.updateWithProduct(product) }
           } else if segue.identifier == "showIngredients",
                     let vc = segue.destination as? IngredientsViewController {
               ingredientsVC = vc
               if let product = product { vc.updateWithProduct(product) }
           } else if segue.identifier == "showNutrition",
                     let vc = segue.destination as? NutritionViewController {
               nutritionVC = vc
               if let product = product { vc.updateWithProduct(product) }
           }
       }
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
            let centerPoint = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
            let radius = progressView.bounds.width / 2
            let circularPath = UIBezierPath(
                arcCenter: centerPoint,
                radius: radius - 18,
                startAngle: -CGFloat.pi / 2,
                endAngle: 1.5 * CGFloat.pi,
                clockwise: true
            )
            
            // Background circle.
            let backgroundLayer = CAShapeLayer()
            backgroundLayer.path = circularPath.cgPath
            backgroundLayer.strokeColor = UIColor.white.cgColor
            backgroundLayer.lineWidth = 17
            backgroundLayer.fillColor = UIColor.clear.cgColor
            progressView.layer.addSublayer(backgroundLayer)
            
            // Progress circle.
            progressLayer = CAShapeLayer()
            progressLayer.path = circularPath.cgPath
            progressLayer.strokeColor = UIColor.orange.cgColor
            progressLayer.lineWidth = 17
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.lineCap = .round
            progressLayer.strokeEnd = 0
            progressView.layer.addSublayer(progressLayer)
        }
        
        // Update the progress bar and label.
        func setProgress(to progress: CGFloat, animated: Bool = true) {
            let clampedProgress = min(max(progress, 0), 1)
            progressLayer.strokeEnd = clampedProgress
            let percentage = Int(clampedProgress * 100)
            progressLabel.text = "\(percentage)"
            
            // Update colors based on the product's health score.
            if let product = product {
                if product.healthScore < 40 {
                    progressLabel.textColor = .systemRed
                    progressLayer.strokeColor = UIColor.systemRed.cgColor
                } else if product.healthScore < 75 {
                    progressLabel.textColor = .systemOrange
                    progressLayer.strokeColor = UIColor.orange.cgColor
                } else {
                    progressLabel.textColor = .systemGreen
                    progressLayer.strokeColor = UIColor.systemGreen.cgColor
                }
            }
        }
        
        // MARK: - Setup Product Details UI
        private func setupProductDetails() {
            guard let product = product else { return }
            
            ProductName.text = product.name
            if let url = URL(string: product.imageURL) {
                ProductImage.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder_product_nobg"))
            } else {
                ProductImage.image = UIImage(named:"placeholder_product_nobg")
            }
        }
    
    

}
