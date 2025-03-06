import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class HeightViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let unitSegmentedControl = UISegmentedControl(items: ["FT", "CM"])
    private let heightDisplayLabel = UILabel()
    private let slider = UISlider()
    private let sliderTrackView = UIView()
    private let nextButton = UIButton(type: .system)
    
    private let isEditingProfile: Bool
    private let profileData: UserProfileData  // Stores height in cm internally
    
    // MARK: - Initializer
    
    init(profileData: UserProfileData, isEditingProfile: Bool = false) {
        self.profileData = profileData
        self.isEditingProfile = isEditingProfile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupProgressBar()
        setupUI()
        setupConstraints()
        setupActions()
        
        // Default unit & initial display
        unitSegmentedControl.selectedSegmentIndex = 0
        sliderChanged()
        
        // Hide progress & change button title if editing
        if isEditingProfile {
            progressView.isHidden = true
            nextButton.setTitle("Save", for: .normal)
        }
    }
    
    // MARK: - Setup Progress Bar
    
    private func setupProgressBar() {
        let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        progressView.progressTintColor = orangeColor
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.8
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        
        // Title
        titleLabel.text = "How tall are you?"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = " "
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
        slider.minimumValue = 86   // ~120 cm
        slider.maximumValue = 220  // ~220 cm
        slider.value = 153         // Default
        slider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(createPillThumbImage(), for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        // Custom tick marks
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
            // Progress Bar
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            // Unit Segmented Control
            unitSegmentedControl.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            unitSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            unitSegmentedControl.widthAnchor.constraint(equalToConstant: 100),
            unitSegmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            // Slider Track
            sliderTrackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            sliderTrackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            sliderTrackView.widthAnchor.constraint(equalToConstant: 50),
            sliderTrackView.heightAnchor.constraint(equalToConstant: 400),
            
            // Slider
            slider.centerXAnchor.constraint(equalTo: sliderTrackView.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: sliderTrackView.centerYAnchor),
            slider.widthAnchor.constraint(equalTo: sliderTrackView.heightAnchor),
            slider.heightAnchor.constraint(equalTo: sliderTrackView.widthAnchor),
            
            // Height Display
            heightDisplayLabel.centerYAnchor.constraint(equalTo: sliderTrackView.centerYAnchor),
            heightDisplayLabel.leadingAnchor.constraint(equalTo: sliderTrackView.trailingAnchor, constant: 40),
            heightDisplayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 337),
            nextButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    // MARK: - Custom Track and Thumb
    
    private func createCustomVerticalSliderTrack(into parentView: UIView, numberOfTicks: Int) {
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
    
    private func createPillThumbImage() -> UIImage {
        let size = CGSize(width: 24, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let rect = CGRect(origin: .zero, size: size)
        let cornerRadius = rect.width / 2
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        orangeColor.setFill()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Setup Actions
    
    private func setupActions() {
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        unitSegmentedControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func sliderChanged() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let cmValue = round(slider.value)
        profileData.height = Double(cmValue)
        
        if unitSegmentedControl.selectedSegmentIndex == 0 {
            let (feet, inches) = cmToFeetInches(Double(cmValue))
            let attributedText = NSMutableAttributedString(
                string: "\(feet)",
                attributes: [.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            let ftUnit = NSAttributedString(
                string: " ft ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    .foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(ftUnit)
            let inchesNumber = NSAttributedString(
                string: "\(inches)",
                attributes: [.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            attributedText.append(inchesNumber)
            let inUnit = NSAttributedString(
                string: " in",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    .foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(inUnit)
            heightDisplayLabel.attributedText = attributedText
        } else {
            let cmValueInt = Int(cmValue)
            let attributedText = NSMutableAttributedString(
                string: "\(cmValueInt)",
                attributes: [.font: UIFont.systemFont(ofSize: 55, weight: .bold)]
            )
            let cmUnit = NSAttributedString(
                string: " cm",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    .foregroundColor: UIColor.lightGray
                ]
            )
            attributedText.append(cmUnit)
            heightDisplayLabel.attributedText = attributedText
        }
    }
    
    @objc private func unitChanged() {
        sliderChanged()
    }
    
    @objc private func nextButtonTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if isEditingProfile {
            updateFirebaseHeight()
        } else {
            let nextVC = ActivityLevelViewController(profileData: profileData)
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    // MARK: - Firebase Update
    
    private func updateFirebaseHeight() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        let updatedData: [String: Any] = [
            "height": profileData.height
        ]
        
        db.collection("users").document(uid).setData(updatedData, merge: true) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: "Error saving height: \(error.localizedDescription)")
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Unit Conversion Helpers
    
    private func cmToFeetInches(_ cm: Double) -> (Int, Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(round(totalInches.truncatingRemainder(dividingBy: 12)))
        return (feet, inches)
    }
    
    private func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet * 12 + inches)
        return totalInches * 2.54
    }
    
    // MARK: - Alert Helper
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
