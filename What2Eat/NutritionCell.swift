//
//  NutritionCell.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class NutritionCell: UITableViewCell {

    @IBOutlet weak var NutrientLabel: UILabel!
    

    @IBOutlet weak var NutrientGrams: UILabel!
    
    @IBOutlet var RDAPercentage: UILabel!
    @IBOutlet weak var NutritionProgress: UIProgressView!
    var minHeight: CGFloat? = 0
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
           let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
           guard let minHeight = minHeight else { return size }
           return CGSize(width: size.width, height: max(size.height, minHeight))
       }
}
