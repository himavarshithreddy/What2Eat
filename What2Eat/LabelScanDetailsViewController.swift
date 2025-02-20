//
//  LabelScanDetailsViewController.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit

class LabelScanDetailsViewController: UIViewController {

    
    
    @IBOutlet weak var progressView: UIView!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var SummarySegmentView: UIView!
    
    @IBOutlet weak var IngredientsSegmentView: UIView!
    
    @IBOutlet weak var NutritionSegmentView: UIView!
    
    @IBOutlet var ProductImage: UIImageView!
    
    
  
    @IBOutlet var ProductName: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
