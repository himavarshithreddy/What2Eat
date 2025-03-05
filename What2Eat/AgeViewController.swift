import UIKit

class AgeViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Age selection components
    private let ageContainerView = UIView()
    private let leftAgeLabel = UILabel()
    private let centerAgeLabel = UILabel()
    private let rightAgeLabel = UILabel()
    
    private let nextButton = UIButton(type: .system)
    
    private let profileData: UserProfileData
    private var currentAge = 20
    
    private let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
    private let softColor = UIColor(red: 240/255, green: 233/255, blue: 222/255, alpha: 1)
    
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
        profileData.age = currentAge
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        // Progress Bar
        progressView.progressTintColor = orangeColor
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.8 // 4/5 complete
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Title Label
        titleLabel.text = "What's your age?"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = orangeColor
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.text = "Age is Just a Number, but it helps us tailor\nthings just right for you."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Age Container View
        ageContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageContainerView)
        
        // Left Age Label
        leftAgeLabel.text = "19"
        leftAgeLabel.font = .systemFont(ofSize: 40, weight: .heavy)
        leftAgeLabel.textColor = softColor
        leftAgeLabel.textAlignment = .center
        leftAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        ageContainerView.addSubview(leftAgeLabel)
        
        // Center Age Label
        centerAgeLabel.text = "20"
        centerAgeLabel.font = .systemFont(ofSize: 70, weight: .black)
        centerAgeLabel.textColor = orangeColor
        centerAgeLabel.textAlignment = .center
        centerAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        ageContainerView.addSubview(centerAgeLabel)
        
        // Right Age Label
        rightAgeLabel.text = "21"
        rightAgeLabel.font = .systemFont(ofSize: 40, weight: .heavy)
        rightAgeLabel.textColor = softColor
        rightAgeLabel.textAlignment = .center
        rightAgeLabel.translatesAutoresizingMaskIntoConstraints = false
        ageContainerView.addSubview(rightAgeLabel)
        
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = orangeColor
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Subtitle Label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Age Container View
            ageContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ageContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ageContainerView.heightAnchor.constraint(equalToConstant: 80),
            ageContainerView.widthAnchor.constraint(equalToConstant: 300),
            
            // Left Age Label
            leftAgeLabel.centerYAnchor.constraint(equalTo: ageContainerView.centerYAnchor),
            leftAgeLabel.leadingAnchor.constraint(equalTo: ageContainerView.leadingAnchor),
            
            // Center Age Label
            centerAgeLabel.centerXAnchor.constraint(equalTo: ageContainerView.centerXAnchor),
            centerAgeLabel.centerYAnchor.constraint(equalTo: ageContainerView.centerYAnchor),
            
            // Right Age Label
            rightAgeLabel.centerYAnchor.constraint(equalTo: ageContainerView.centerYAnchor),
            rightAgeLabel.trailingAnchor.constraint(equalTo: ageContainerView.trailingAnchor),
            
            // Next Button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 337),
            nextButton.heightAnchor.constraint(equalToConstant: 54)
        ])
        
        // Add gesture recognizers for age selection
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
        leftSwipeGesture.direction = .left
        ageContainerView.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
        rightSwipeGesture.direction = .right
        ageContainerView.addGestureRecognizer(rightSwipeGesture)
    }
    
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    @objc private func handleLeftSwipe() {
        guard currentAge < 100 else { return }
        currentAge += 1
        updateAgeDisplay()
    }
    
    @objc private func handleRightSwipe() {
        guard currentAge > 1 else { return }
        currentAge -= 1
        updateAgeDisplay()
    }
    
    private func updateAgeDisplay() {
        leftAgeLabel.text = "\(max(1, currentAge - 1))"
        centerAgeLabel.text = "\(currentAge)"
        rightAgeLabel.text = "\(min(100, currentAge + 1))"
        
        // Optionally add impact feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Update profile data
        profileData.age = currentAge
    }
    
    @objc private func nextTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        let nextVC = ActivityLevelViewController(profileData: profileData)
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
