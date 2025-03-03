import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ActivityLevelViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let activityStackView = UIStackView()
    private let sedentaryButton = UIButton(type: .system)
    private let moderateButton = UIButton(type: .system)
    private let heavyButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    
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
        progressView.progress = 1.0 // 5/5 complete
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Title
        titleLabel.text = "How Active Are You?"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Activity Selection
        activityStackView.axis = .vertical
        activityStackView.spacing = 15
        activityStackView.distribution = .fillEqually
        activityStackView.translatesAutoresizingMaskIntoConstraints = false
        
        sedentaryButton.setTitle("Sedentary (Little or no exercise)", for: .normal)
        sedentaryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        sedentaryButton.backgroundColor = .systemGray6
        sedentaryButton.setTitleColor(.darkText, for: .normal)
        sedentaryButton.layer.cornerRadius = 12
        sedentaryButton.translatesAutoresizingMaskIntoConstraints = false
        
        moderateButton.setTitle("Moderate (Exercise 3-5 days/week)", for: .normal)
        moderateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        moderateButton.backgroundColor = .systemGray6
        moderateButton.setTitleColor(.darkText, for: .normal)
        moderateButton.layer.cornerRadius = 12
        moderateButton.translatesAutoresizingMaskIntoConstraints = false
        
        heavyButton.setTitle("Heavy (Intense exercise daily)", for: .normal)
        heavyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        heavyButton.backgroundColor = .systemGray6
        heavyButton.setTitleColor(.darkText, for: .normal)
        heavyButton.layer.cornerRadius = 12
        heavyButton.translatesAutoresizingMaskIntoConstraints = false
        
        activityStackView.addArrangedSubview(sedentaryButton)
        activityStackView.addArrangedSubview(moderateButton)
        activityStackView.addArrangedSubview(heavyButton)
        view.addSubview(activityStackView)
        
        // Save Button
        saveButton.setTitle("Save & Continue", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveButton.backgroundColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            activityStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            activityStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            activityStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            activityStackView.heightAnchor.constraint(equalToConstant: 180),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 220),
            saveButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func setupActions() {
        sedentaryButton.addTarget(self, action: #selector(activitySelected(_:)), for: .touchUpInside)
        moderateButton.addTarget(self, action: #selector(activitySelected(_:)), for: .touchUpInside)
        heavyButton.addTarget(self, action: #selector(activitySelected(_:)), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    @objc private func activitySelected(_ sender: UIButton) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        sedentaryButton.backgroundColor = .systemGray6
        moderateButton.backgroundColor = .systemGray6
        heavyButton.backgroundColor = .systemGray6
        sedentaryButton.setTitleColor(.darkText, for: .normal)
        moderateButton.setTitleColor(.darkText, for: .normal)
        heavyButton.setTitleColor(.darkText, for: .normal)
        
        sender.backgroundColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        sender.setTitleColor(.white, for: .normal)
        
        switch sender {
        case sedentaryButton: profileData.activityLevel = "Sedentary"
        case moderateButton: profileData.activityLevel = "Moderate"
        case heavyButton: profileData.activityLevel = "Heavy"
        default: break
        }
    }
    
    @objc private func saveTapped() {
        guard !profileData.activityLevel.isEmpty else {
            showAlert(message: "Please select an activity level.")
            return
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        updateUserProfile()
    }
    
    private func updateUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": profileData.name,
            "dietaryRestrictions": [],
            "allergies": [],
            "gender": profileData.gender,
            "age": profileData.age,
            "weight": profileData.weight,
            "height": profileData.height,
            "activityLevel": profileData.activityLevel
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.showAlert(message: "Error saving profile: \(error.localizedDescription)")
                return
            }
            
            let user = Users(
                name: self.profileData.name,
                dietaryRestrictions: [],
                allergies: [],
                gender: self.profileData.gender,
                age: self.profileData.age,
                weight: self.profileData.weight,
                height: self.profileData.height,
                activityLevel: self.profileData.activityLevel
            )
            
            do {
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(user)
                UserDefaults.standard.set(encodedData, forKey: "currentUser")
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                self.navigateToAllergyViewController()
            } catch {
                self.showAlert(message: "Error saving locally: \(error.localizedDescription)")
            }
        }
    }
    
    private func navigateToAllergyViewController() {
        guard let windowScene = view.window?.windowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("Unable to find window for navigation")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let allergyNavController = storyboard.instantiateViewController(withIdentifier: "AllergyNavController")
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .fade
        window.layer.add(transition, forKey: kCATransition)
        window.rootViewController = allergyNavController
        window.makeKeyAndVisible()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.view.tintColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        present(alert, animated: true)
    }
}
