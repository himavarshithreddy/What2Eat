//
//  IngredientsLabelCell.swift
//  What2Eat
//
//  Created by admin20 on 20/02/25.
//

import UIKit

class IngredientsLabelCell: UITableViewCell {

    @IBOutlet var ingredientLabel: UILabel!
    
    var minHeight: CGFloat? = 0
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
           let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
           guard let minHeight = minHeight else { return size }
           return CGSize(width: size.width, height: max(size.height, minHeight))
       }
    
}
