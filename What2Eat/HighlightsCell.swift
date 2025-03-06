//
//  HighlightsCell.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit

class HighlightsCell: UITableViewCell {

    
    @IBOutlet weak var HighlightText: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    
    @IBOutlet var DescriptionText: UILabel!
    
    @IBOutlet var expandButton: UIButton!
    @IBOutlet var ProgressBar: UIProgressView!
    
    var onExpandButtonTapped: (() -> Void)?
    
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
