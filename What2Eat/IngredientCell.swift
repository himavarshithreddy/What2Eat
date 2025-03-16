//
//  IngredientCell.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class IngredientCell: UITableViewCell {

    var minHeight: CGFloat? = 0
    @IBOutlet weak var ingredientLabel: UILabel!
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
           let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
           guard let minHeight = minHeight else { return size }
           return CGSize(width: size.width, height: max(size.height, minHeight))
       }
    
    
}
