import UIKit

class AgeViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let agePicker = UIDatePicker()
    private let nextButton = UIButton(type: .system)
    
    private let profileData: UserProfileData
    
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
        progressView.progress = 0.8 // 4/5 complete
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Title
        titleLabel.text = "How Old Are You?"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Age Picker (wheel style)
        agePicker.datePickerMode = .date
        agePicker.preferredDatePickerStyle = .wheels
        agePicker.tintColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        agePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(agePicker)
        
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
            
            agePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            agePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 220),
            nextButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func setupActions() {
        agePicker.addTarget(self, action: #selector(ageChanged), for: .valueChanged)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    @objc private func ageChanged() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: agePicker.date, to: Date())
        if let age = ageComponents.year {
            profileData.age = age
        }
    }
    
    @objc private func nextTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let nextVC = ActivityLevelViewController(profileData: profileData)
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
