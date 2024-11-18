//
//  AllergyCell.swift
//  What2Eat
//
//  Created by admin20 on 08/11/24.
//

import UIKit

class AllergyCell: UICollectionViewCell {
    
    @IBOutlet weak var allergyButton: UIButton!
    
    private var isSelectedAllergy: Bool = false
        
        override func awakeFromNib() {
            super.awakeFromNib()
            setupButton() // Set up button styles
        }
        
        private func setupButton() {
            var config = UIButton.Configuration.filled() // Use filled button style
            config.baseBackgroundColor = UIColor(red: 240/255, green: 233/255, blue: 222/255, alpha: 1)
            config.baseForegroundColor = .black
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            
            allergyButton.configuration = config
            allergyButton.layer.borderWidth = 0.5
            allergyButton.layer.cornerRadius = 15
            allergyButton.layer.borderColor = UIColor.black.cgColor
            
            allergyButton.addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
        }
        
        @objc private func toggleSelection() {
            isSelectedAllergy.toggle()
            
            var config = allergyButton.configuration
            config?.baseBackgroundColor = isSelectedAllergy ?
                UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1) :
                UIColor(red: 240/255, green: 233/255, blue: 222/255, alpha: 1)
            config?.baseForegroundColor = isSelectedAllergy ? .white : .black
            
            allergyButton.configuration = config
        }
    }


