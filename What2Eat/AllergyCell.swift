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
        config.baseBackgroundColor = UIColor.white
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
        updateButtonAppearance()
    }
    
    private func updateButtonAppearance() {
        var config = allergyButton.configuration
        config?.baseBackgroundColor = isSelectedAllergy ?
            UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1) :
        UIColor.white
        config?.baseForegroundColor = isSelectedAllergy ? .white : .black
        
        allergyButton.configuration = config
    }

    // This method will allow us to set the button's state programmatically
    func setSelectedState(isSelected: Bool) {
        isSelectedAllergy = isSelected
        updateButtonAppearance()
    }
}
