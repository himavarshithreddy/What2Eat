import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class WeightViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let unitSegmentedControl = UISegmentedControl(items: ["kg", "lbs"])
    private let weightValueLabel = UILabel()
    private let weightUnitLabel = UILabel()
    private let slider = UISlider()
    private let minValueLabel = UILabel()
    private let maxValueLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    
    private let profileData: UserProfileData
    private let isEditingProfile: Bool
    
    // Updated initializer with an editing flag
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
        
        // Default to 60 for the onboarding flow
        profileData.weight = 60
        
        setupProgressBar()
        setupUI()
        setupActions()
        
        // If editing, hide the progress bar and change button title
        if isEditingProfile {
            progressView.isHidden = true
            continueButton.setTitle("Save", for: .normal)
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupProgressBar() {
        let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        progressView.progressTintColor = orangeColor
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.6  // e.g., step 3 of 5 complete
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
    }
    
    private func setupUI() {
        // Title
        titleLabel.text = "What is your weight?"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Unit Segmented Control
        unitSegmentedControl.selectedSegmentIndex = 0
        unitSegmentedControl.backgroundColor = UIColor.systemGray6
        unitSegmentedControl.selectedSegmentTintColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        unitSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        unitSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .normal)
        unitSegmentedControl.layer.cornerRadius = 24
        unitSegmentedControl.clipsToBounds = true
        unitSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(unitSegmentedControl)
        
        // Weight Value Label
        weightValueLabel.text = "60"
        weightValueLabel.font = .systemFont(ofSize: 70, weight: .bold)
        weightValueLabel.textColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        weightValueLabel.textAlignment = .center
        weightValueLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weightValueLabel)
        
        // Weight Unit Label
        weightUnitLabel.text = "kg"
        weightUnitLabel.font = .systemFont(ofSize: 30, weight: .regular)
        weightUnitLabel.textColor = .lightGray
        weightUnitLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weightUnitLabel)
        
        // Slider
        slider.minimumValue = 5
        slider.maximumValue = 200
        slider.value = 60
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(createThumbImage(), for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        // Slider Track
        let sliderTrackView = createCustomSliderTrack()
        sliderTrackView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(sliderTrackView, belowSubview: slider)
        
        // Min Value Label
        minValueLabel.text = " "
        minValueLabel.font = .systemFont(ofSize: 16, weight: .medium)
        minValueLabel.textColor = .white
        minValueLabel.textAlignment = .center
        minValueLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(minValueLabel)
        
        // Max Value Label
        maxValueLabel.text = " "
        maxValueLabel.font = .systemFont(ofSize: 16, weight: .medium)
        maxValueLabel.textColor = .white
        maxValueLabel.textAlignment = .center
        maxValueLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(maxValueLabel)
        
        // Continue Button
        continueButton.setTitle("Next", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 14
        continueButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Progress Bar
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Unit Segmented Control
            unitSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            unitSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unitSegmentedControl.widthAnchor.constraint(equalToConstant: 320),
            unitSegmentedControl.heightAnchor.constraint(equalToConstant: 48),
            
            // Weight Value Label
            weightValueLabel.topAnchor.constraint(equalTo: unitSegmentedControl.bottomAnchor, constant: 80),
            weightValueLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -20),
            
            // Weight Unit Label
            weightUnitLabel.bottomAnchor.constraint(equalTo: weightValueLabel.bottomAnchor, constant: -10),
            weightUnitLabel.leadingAnchor.constraint(equalTo: weightValueLabel.trailingAnchor, constant: 5),
            
            // Slider Track View
            sliderTrackView.topAnchor.constraint(equalTo: weightValueLabel.bottomAnchor, constant: 60),
            sliderTrackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sliderTrackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            sliderTrackView.heightAnchor.constraint(equalToConstant: 100),
            
            // Slider
            slider.centerYAnchor.constraint(equalTo: sliderTrackView.centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: sliderTrackView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: sliderTrackView.trailingAnchor),
            
            // Min Value Label
            minValueLabel.topAnchor.constraint(equalTo: sliderTrackView.bottomAnchor, constant: 8),
            minValueLabel.leadingAnchor.constraint(equalTo: sliderTrackView.leadingAnchor, constant: 60),
            
            // Max Value Label
            maxValueLabel.topAnchor.constraint(equalTo: sliderTrackView.bottomAnchor, constant: 8),
            maxValueLabel.trailingAnchor.constraint(equalTo: sliderTrackView.trailingAnchor, constant: -60),
            
            // Continue Button
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 337),
            continueButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    // MARK: - Slider Track
    
    private func createCustomSliderTrack() -> UIView {
        let trackView = UIView()
        trackView.backgroundColor = .clear
        
        let trackLine = UIView()
        trackLine.backgroundColor = UIColor.systemGray5
        trackLine.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(trackLine)
        
        for i in 0...20 {
            let tickView = UIView()
            tickView.backgroundColor = i % 5 == 0 ? UIColor.systemGray3 : UIColor.systemGray5
            tickView.translatesAutoresizingMaskIntoConstraints = false
            trackView.addSubview(tickView)
            
            let height: CGFloat = i % 5 == 0 ? 24 : 12
            NSLayoutConstraint.activate([
                tickView.centerXAnchor.constraint(
                    equalTo: trackView.leadingAnchor,
                    constant: CGFloat(i) * (UIScreen.main.bounds.width - 48) / 20
                ),
                tickView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
                tickView.widthAnchor.constraint(equalToConstant: 1),
                tickView.heightAnchor.constraint(equalToConstant: height)
            ])
        }
        
        NSLayoutConstraint.activate([
            trackLine.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            trackLine.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            trackLine.trailingAnchor.constraint(equalTo: trackView.trailingAnchor),
            trackLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return trackView
    }
    
    private func createThumbImage() -> UIImage {
        let size = CGSize(width: 24, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        let rect = CGRect(origin: .zero, size: size)
        context.addRoundedRect(in: rect, cornerWidth: 12, cornerHeight: 12)
        
        let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        orangeColor.setFill()
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        unitSegmentedControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
    }
    
    @objc private func sliderChanged() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let weight = round(slider.value)
        weightValueLabel.text = String(format: "%.0f", weight)
        
        // Update the min and max labels to show values around the current value
        minValueLabel.text = String(format: "%.0f", weight - 1)
        maxValueLabel.text = String(format: "%.0f", weight + 1)
        
        profileData.weight = Double(weight)
    }
    
    @objc private func unitChanged() {
        let isKg = unitSegmentedControl.selectedSegmentIndex == 0
        weightUnitLabel.text = isKg ? "kg" : "lbs"
        
        // Convert the current value if needed
        let currentValue = Double(slider.value)
        if isKg {
            // Convert from lbs to kg
            let kgValue = round(currentValue / 2.20462)
            slider.value = Float(kgValue)
            weightValueLabel.text = String(format: "%.0f", kgValue)
        } else {
            // Convert from kg to lbs
            let lbsValue = round(currentValue * 2.20462)
            slider.value = Float(lbsValue)
            weightValueLabel.text = String(format: "%.0f", lbsValue)
        }
        
        // Update min/max values
        let weight = round(slider.value)
        minValueLabel.text = String(format: "%.0f", weight - 1)
        maxValueLabel.text = String(format: "%.0f", weight + 1)
    }
    
    @objc private func continueTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // If editing, save to Firebase immediately
        if isEditingProfile {
            updateFirebaseWeight()
        } else {
            // Onboarding flow
            let nextVC = HeightViewController(profileData: profileData)
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    // MARK: - Firebase Update
    
    private func updateFirebaseWeight() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        let updatedData: [String: Any] = [
            "weight": profileData.weight
        ]
        
        db.collection("users").document(uid).setData(updatedData, merge: true) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: "Error saving weight: \(error.localizedDescription)")
            } else {
                // Pop back on success
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Alert Helper
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// Extension to make rounded rectangles easier
extension CGContext {
    func addRoundedRect(in rect: CGRect, cornerWidth: CGFloat, cornerHeight: CGFloat) {
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        
        move(to: CGPoint(x: minX + cornerWidth, y: minY))
        addLine(to: CGPoint(x: maxX - cornerWidth, y: minY))
        addArc(tangent1End: CGPoint(x: maxX, y: minY), tangent2End: CGPoint(x: maxX, y: minY + cornerHeight), radius: cornerWidth)
        addLine(to: CGPoint(x: maxX, y: maxY - cornerHeight))
        addArc(tangent1End: CGPoint(x: maxX, y: maxY), tangent2End: CGPoint(x: maxX - cornerWidth, y: maxY), radius: cornerWidth)
        addLine(to: CGPoint(x: minX + cornerWidth, y: maxY))
        addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX, y: maxY - cornerHeight), radius: cornerWidth)
        addLine(to: CGPoint(x: minX, y: minY + cornerHeight))
        addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: minX + cornerWidth, y: minY), radius: cornerWidth)
    }
}
