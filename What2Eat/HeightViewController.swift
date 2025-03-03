import UIKit

class HeightViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let slider = UISlider()
    private let heightLabel = UILabel()
    private let unitToggle = UISegmentedControl(items: ["cm", "ft"])
    private let nextButton = UIButton(type: .system)
    
    private let profileData: UserProfileData
    private var isCm = true
    
    init(profileData: UserProfileData) {
        self.profileData = profileData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        // Progress Bar
        progressView.progressTintColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.4 // 2/5 complete
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Title
        titleLabel.text = "How Tall Are You?"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Vertical Slider (rotated)
        slider.minimumValue = 100 // cm
        slider.maximumValue = 250 // cm
        slider.value = 170 // Default
        slider.minimumTrackTintColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        slider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        // Height Label
        heightLabel.text = "170 cm"
        heightLabel.font = .systemFont(ofSize: 24, weight: .medium)
        heightLabel.textColor = .darkText
        heightLabel.textAlignment = .center
        heightLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heightLabel)
        
        // Unit Toggle
        unitToggle.selectedSegmentIndex = 0 // cm default
        unitToggle.tintColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        unitToggle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(unitToggle)
        
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 300),
            
            heightLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            heightLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            unitToggle.topAnchor.constraint(equalTo: heightLabel.bottomAnchor, constant: 20),
            unitToggle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 220),
            nextButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func setupActions() {
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        unitToggle.addTarget(self, action: #selector(unitToggled), for: .valueChanged)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    @objc private func sliderChanged() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let height = slider.value
        if isCm {
            heightLabel.text = String(format: "%.0f cm", height)
            profileData.height = Double(height)
        } else {
            let feet = height / 30.48 // cm to ft
            heightLabel.text = String(format: "%.1f ft", feet)
            profileData.height = Double(height) // Store in cm
        }
    }
    
    @objc private func unitToggled() {
        isCm = unitToggle.selectedSegmentIndex == 0
        sliderChanged() // Update display
    }
    
    @objc private func nextTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let nextVC = WeightViewController(profileData: profileData)
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
