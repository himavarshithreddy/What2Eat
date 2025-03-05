//
//  HighlightsLabelCell.swift
//  What2Eat
//
//  Created by admin20 on 21/02/25.
//

import UIKit

class HighlightsLabelCell: UITableViewCell {

   
    @IBOutlet var iconImage: UIImageView!
    
    @IBOutlet var HighlightText: UILabel!
    
    @IBOutlet var DescriptionText: UILabel!
    
    @IBOutlet var expandButton: UIButton!
    var onExpandButtonTapped: (() -> Void)?
    @IBOutlet var ProgressBar: UIProgressView!
    override func awakeFromNib() {
            super.awakeFromNib()
        ProgressBar.layer.cornerRadius = 20
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
            
        }
    override func prepareForReuse() {
            super.prepareForReuse()
            DescriptionText.isHidden = false
            ProgressBar.isHidden = false
            onExpandButtonTapped = nil
        }
        
        // Update button appearance based on expanded state
        func configureExpandButton(isExpanded: Bool) {
            let imageName = isExpanded ? "chevron.up" : "chevron.down"
            expandButton.setImage(UIImage(systemName: imageName), for: .normal)
            expandButton.tintColor = .systemGray
        }
        
        @objc private func expandButtonTapped() {
            onExpandButtonTapped?()
        }
      
}
