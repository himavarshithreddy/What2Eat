//
//  DietaryCell.swift
//  What2Eat
//
//  Created by admin20 on 14/11/24.
//

import UIKit

class DietaryCell: UICollectionViewCell {

    @IBOutlet weak var dietaryButton: UIButton!
    private var isSelectedDietary: Bool = false
        
        override func awakeFromNib() {
            super.awakeFromNib()
            setupButton()
        }
        
    private func setupButton() {
            var config = UIButton.Configuration.filled() // Use filled button style
            config.baseBackgroundColor = UIColor(red: 240/255, green: 233/255, blue: 222/255, alpha: 1)
            config.baseForegroundColor = .black
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            
            dietaryButton.configuration = config
            dietaryButton.layer.borderWidth = 0.5
            dietaryButton.layer.cornerRadius = 15
            dietaryButton.layer.borderColor = UIColor.black.cgColor
            
            dietaryButton.addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
        }
        
        @objc private func toggleSelection() {
            isSelectedDietary.toggle()
            
            var config = dietaryButton.configuration
            config?.baseBackgroundColor = isSelectedDietary ?
                UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1) :
                UIColor(red: 240/255, green: 233/255, blue: 222/255, alpha: 1)
            config?.baseForegroundColor = isSelectedDietary ? .white : .black
            
            dietaryButton.configuration = config
        }
    }

