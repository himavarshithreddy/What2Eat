import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
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
    private let isEditingProfile: Bool
    private var currentAge = 20
    
    private let orangeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
    private let softColor = UIColor(red: 240/255, green: 233/255, blue: 222/255, alpha: 1)
    
    init(profileData: UserProfileData, isEditingProfile: Bool = false) {
           self.profileData = profileData
           self.isEditingProfile = isEditingProfile
           super.init(nibName: nil, bundle: nil)
       }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
           super.viewDidLoad()
           view.backgroundColor = .white
        if profileData.age != 0 {
                currentAge = profileData.age
            } else {
                currentAge = 20
            }
            profileData.age = currentAge
        
           setupUI()
           setupActions()
        updateAgeDisplay()
           // Adjust UI for editing mode
           if isEditingProfile {
               progressView.isHidden = true
               nextButton.setTitle("Save", for: .normal)
           }
       }
    
    private func setupUI() {
        // Progress Bar
        progressView.progressTintColor = orangeColor
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.4 // 4/5 complete
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
        subtitleLabel.textColor = .clear
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
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 337),
            nextButton.heightAnchor.constraint(equalToConstant: 54)
        ])
        
        // Add gesture recognizers for age selection
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        // Remove the swipe gestures and add a pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        ageContainerView.addGestureRecognizer(panGesture)
    }
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // Determine the horizontal movement
        let translation = gesture.translation(in: ageContainerView)
        // Define a threshold for each age increment (adjust as needed)
        let threshold: CGFloat = 20.0

        if abs(translation.x) >= threshold {
            // Calculate steps: negative translation (left swipe) should increase age,
            // positive translation (right swipe) should decrease age.
            let steps = Int(translation.x / threshold)
            // Update the current age while clamping it between 1 and 100.
            // Note: Subtracting steps works because a leftward pan (negative translation)
            // results in adding to the age.
            currentAge = min(max(currentAge - steps, 1), 100)
            updateAgeDisplay()
            // Reset translation so that the next increment is measured from zero.
            gesture.setTranslation(.zero, in: ageContainerView)
        }
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
    private func updateFirebaseProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        let updatedData: [String: Any] = [
            "age": profileData.age
        ]
        
        db.collection("users").document(uid).setData(updatedData, merge: true) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: "Error saving age: \(error.localizedDescription)")
            } else {
                // Update UserDefaults
                if let savedData = UserDefaults.standard.data(forKey: "currentUser"),
                   var savedUser = try? JSONDecoder().decode(Users.self, from: savedData) {
                    
                    // Update only the age field
                    savedUser.age = self.profileData.age

                    do {
                        let encoder = JSONEncoder()
                        let encodedData = try encoder.encode(savedUser)
                        UserDefaults.standard.set(encodedData, forKey: "currentUser")
                    } catch {
                        self.showAlert(message: "Error updating local data: \(error.localizedDescription)")
                    }
                }
                if isEditingProfile {
                    
                    self.navigationController?.popViewController(animated: true)
                } else {
                    let nextVC = WeightViewController(profileData: profileData)
                   
                    navigationController?.pushViewController(nextVC, animated: true)
                }
               
            }
        }
    }

    @objc private func nextTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        updateFirebaseProfile()
       
    }
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
