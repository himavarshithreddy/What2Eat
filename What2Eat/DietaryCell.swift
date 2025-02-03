import UIKit

class DietaryCell: UICollectionViewCell {

    @IBOutlet weak var dietaryButton: UIButton!
    
    var isSelectedDietary: Bool = false {
        didSet {
            updateButtonAppearance()  // Update the appearance whenever the selection state changes
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButton()
    }
        
    private func setupButton() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.white
        config.cornerStyle = .capsule
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        dietaryButton.configuration = config
        dietaryButton.layer.borderWidth = 1
        dietaryButton.layer.cornerRadius = 15
        dietaryButton.layer.borderColor = UIColor.black.cgColor
        dietaryButton.addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
    }

    @objc private func toggleSelection() {
        isSelectedDietary.toggle()
    }
    
    private func updateButtonAppearance() {
        var config = dietaryButton.configuration
        config?.baseBackgroundColor = isSelectedDietary ?
            UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1) : // Selected color
        UIColor.white // Default color
        config?.baseForegroundColor = isSelectedDietary ? .white : .black
        
        dietaryButton.configuration = config
    }

    func setSelectedState(isSelected: Bool) {
        isSelectedDietary = isSelected
    }
}
