import UIKit

class HeightViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let unitSegmentedControl = UISegmentedControl(items: ["FT", "CM"])
    
    // Displays something like "5 ft 8 in" or "165 cm"
    private let heightDisplayLabel = UILabel()
    
    // Vertical slider
    private let slider = UISlider()
    
    // Custom track behind the slider
    private let sliderTrackView = UIView()
    
    private let nextButton = UIButton(type: .system)
    
    // Data model passed in (storing height in cm internally)
    private let profileData: UserProfileData
    
    // MARK: - Initializer
    
    init(profileData: UserProfileData) {
        self.profileData = profileData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        setupConstraints()
        setupActions()
        
        // Initial state: start with "FT" unit and update display accordingly.
        unitSegmentedControl.selectedSegmentIndex = 0
        sliderChanged()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        
        // Title Label
        titleLabel.text = "How tall are you?"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.text = "We’re all heights here! Share yours."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.textAlignment = .left
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Unit Segmented Control
        unitSegmentedControl.backgroundColor = .systemGray6
        unitSegmentedControl.selectedSegmentTintColor = orangeColor
        unitSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        unitSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        unitSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(unitSegmentedControl)
        
        // Height Display Label
        heightDisplayLabel.font = .systemFont(ofSize: 55, weight: .bold)
        heightDisplayLabel.textColor = orangeColor
        heightDisplayLabel.textAlignment = .center
        heightDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heightDisplayLabel)
        
        // Slider Track View
        sliderTrackView.backgroundColor = .clear
        sliderTrackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sliderTrackView)
        
        // Vertical Slider
        slider.minimumValue = 86  // 120 cm (about 2 ft 10 in)
        slider.maximumValue = 220  // 220 cm (about 7 ft 3 in)
        slider.value = 153         // Default value (~5 ft 0 in)
        
        // Rotate slider to make it vertical
        slider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        
        // Hide default track so we can use our custom track view
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        
        // Set the custom pill-shaped thumb image (defined below)
        // Increased the pill height to 120 so it appears longer horizontally on screen
        slider.setThumbImage(createPillThumbImage(), for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        // Create custom tick marks for the slider track
        createCustomVerticalSliderTrack(into: sliderTrackView, numberOfTicks: 20)
        
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        nextButton.backgroundColor = orangeColor
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 14
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
    }
    
    // MARK: - Setup Constraints
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Unit Segmented Control (top-right)
            unitSegmentedControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            unitSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            unitSegmentedControl.widthAnchor.constraint(equalToConstant: 100),
            unitSegmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            // Slider Track View (left)
            sliderTrackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            sliderTrackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            sliderTrackView.widthAnchor.constraint(equalToConstant: 50),
            sliderTrackView.heightAnchor.constraint(equalToConstant: 400),
            
            // Slider (aligned with the track)
            slider.centerXAnchor.constraint(equalTo: sliderTrackView.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: sliderTrackView.centerYAnchor),
            // Swapped width/height for vertical orientation
            slider.widthAnchor.constraint(equalTo: sliderTrackView.heightAnchor),
            slider.heightAnchor.constraint(equalTo: sliderTrackView.widthAnchor),
            
            // Height Display Label
            heightDisplayLabel.centerYAnchor.constraint(equalTo: sliderTrackView.centerYAnchor),
            heightDisplayLabel.leadingAnchor.constraint(equalTo: sliderTrackView.trailingAnchor, constant: 40),
            heightDisplayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 337),
            nextButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    // MARK: - Setup Actions
    
    private func setupActions() {
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        unitSegmentedControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Custom Track and Thumb
    
    /// Creates a custom vertical slider track with tick marks.
    private func createCustomVerticalSliderTrack(into parentView: UIView, numberOfTicks: Int) {
        // Vertical line
        let trackLine = UIView()
        trackLine.backgroundColor = UIColor.systemGray5
        trackLine.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(trackLine)
        
        NSLayoutConstraint.activate([
            trackLine.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            trackLine.topAnchor.constraint(equalTo: parentView.topAnchor),
            trackLine.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            trackLine.widthAnchor.constraint(equalToConstant: 2)
        ])
        
        // Tick marks
        let totalHeight: CGFloat = 400
        let tickSpacing = totalHeight / CGFloat(numberOfTicks)
        
        for i in 0...numberOfTicks {
            let tickView = UIView()
            tickView.backgroundColor = (i % 5 == 0) ? UIColor.systemGray : UIColor.systemGray4
            tickView.translatesAutoresizingMaskIntoConstraints = false
            parentView.addSubview(tickView)
            
            let tickWidth: CGFloat = (i % 5 == 0) ? 24 : 12
            let yPosition = totalHeight - (CGFloat(i) * tickSpacing)
            
            NSLayoutConstraint.activate([
                tickView.trailingAnchor.constraint(equalTo: trackLine.leadingAnchor, constant: -16),
                tickView.widthAnchor.constraint(equalToConstant: tickWidth),
                tickView.heightAnchor.constraint(equalToConstant: 1),
                tickView.topAnchor.constraint(equalTo: parentView.topAnchor, constant: yPosition)
            ])
        }
    }
    
//    Creates a tall pill shape in the unrotated coordinate space
//    / Increased height to 120 for a longer pill.
    private func createPillThumbImage() -> UIImage {
        // TALL in code => WIDE after rotation
        let size = CGSize(width: 24, height: 100) // Adjust to make the pill longer
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let rect = CGRect(origin: .zero, size: size)
        
        // Use half of the width or the smaller dimension for the corner radius
        let cornerRadius = rect.width / 2  // 24/2 = 12
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
       let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        
        orangeColor.setFill()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Actions
    
    @objc private func sliderChanged() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let cmValue = round(slider.value)
        profileData.height = Double(cmValue)
        
        if unitSegmentedControl.selectedSegmentIndex == 0 {
            let (feet, inches) = cmToFeetInches(Double(cmValue))
            
            // Create mutable attributed string for the number and units separately.
            let attributedText = NSMutableAttributedString(
                string: "\(feet)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            
            // Append unit "ft" with a smaller font size and lightGray color.
            let ftUnit = NSAttributedString(
                string: " ft ",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(ftUnit)
            
            // Append inches number.
            let inchesNumber = NSAttributedString(
                string: "\(inches)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            attributedText.append(inchesNumber)
            
            // Append unit "in" with a smaller font size and lightGray color.
            let inUnit = NSAttributedString(
                string: " in",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(inUnit)
            
            heightDisplayLabel.attributedText = attributedText
        } else {
            // For centimeters.
            let cmValueInt = Int(cmValue)
            let attributedText = NSMutableAttributedString(
                string: "\(cmValueInt)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            
            let cmUnit = NSAttributedString(
                string: " cm",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(cmUnit)
            
            heightDisplayLabel.attributedText = attributedText
        }
    }


    
    @objc private func unitChanged() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let cmValue = round(slider.value)
        profileData.height = Double(cmValue)
        
        if unitSegmentedControl.selectedSegmentIndex == 0 {
            let (feet, inches) = cmToFeetInches(Double(cmValue))
            
            // Create mutable attributed string for the number and units separately.
            let attributedText = NSMutableAttributedString(
                string: "\(feet)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            
            // Append unit "ft" with a smaller font size and lightGray color.
            let ftUnit = NSAttributedString(
                string: " ft ",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(ftUnit)
            
            // Append inches number.
            let inchesNumber = NSAttributedString(
                string: "\(inches)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            attributedText.append(inchesNumber)
            
            // Append unit "in" with a smaller font size and lightGray color.
            let inUnit = NSAttributedString(
                string: " in",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(inUnit)
            
            heightDisplayLabel.attributedText = attributedText
        } else {
            // For centimeters.
            let cmValueInt = Int(cmValue)
            let attributedText = NSMutableAttributedString(
                string: "\(cmValueInt)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            
            let cmUnit = NSAttributedString(
                string: " cm",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(cmUnit)
            
            heightDisplayLabel.attributedText = attributedText
        }
    }
    
    @objc private func nextButtonTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Navigate to the next screen (for example, WeightViewController)
        let nextVC = WeightViewController(profileData: profileData)
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    // MARK: - Unit Conversion Helpers
    
    private func cmToFeetInches(_ cm: Double) -> (Int, Int) {
        // 1 inch = 2.54 cm; 1 foot = 12 inches
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(round(totalInches.truncatingRemainder(dividingBy: 12)))
        return (feet, inches)
    }
    
    private func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet * 12 + inches)
        return totalInches * 2.54
    }
}
