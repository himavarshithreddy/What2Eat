import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

// Custom card view for activity selection with image on left and two-line text on right
class ActivityCard: UIControl {
    private let horizontalStackView = UIStackView()
    private let textStackView = UIStackView()
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    // Define the new orange color
    private let selectedColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
    
    // Updated initializer with title and subtitle
    init(image: UIImage?, title: String, subtitle: String) {
        super.init(frame: .zero)
        setupView()
        imageView.image = image
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Horizontal stack view: image on left, vertical text on right
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 12
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalStackView)
        
        // Configure image view
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Vertical stack view for the text labels
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 4
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure title label
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .darkText
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure subtitle label
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .darkText
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Assemble the text stack view
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        
        // Add subviews to the horizontal stack view
        horizontalStackView.addArrangedSubview(imageView)
        horizontalStackView.addArrangedSubview(textStackView)
        
        // Set constraints for the horizontal stack view and image view size
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Enforce a larger minimum height for the card
        heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
    }
    
    // Update appearance based on selection state
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? selectedColor : .systemGray6
            titleLabel.textColor = isSelected ? .white : .darkText
            subtitleLabel.textColor = isSelected ? .white : .darkText
            imageView.tintColor = isSelected ? .white : selectedColor
        }
    }
}

class ActivityLevelViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let activityStackView = UIStackView()
    private let saveButton = UIButton(type: .system)
    
    // 1. New property to indicate editing mode
    private let isEditingProfile: Bool
    
    // Updated cards
    private let sedentaryCard = ActivityCard(
        image: UIImage(named: "sedentary"),
        title: "Sedentary",
        subtitle: "(Little or no exercise)"
    )
    private let moderateCard = ActivityCard(
        image: UIImage(named: "moderate"),
        title: "Moderate",
        subtitle: "(Exercise 3-5 days/week)"
    )
    private let heavyCard = ActivityCard(
        image: UIImage(named: "heavy"),
        title: "Heavy",
        subtitle: "(Intense exercise daily)"
    )
    
    private let profileData: UserProfileData
    
    // 2. Updated initializer with an editing flag
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
        setupUI()
        setupActions()
        
        // 3. Hide progress & change button title if editing
        if isEditingProfile {
            progressView.isHidden = true
            saveButton.setTitle("Save", for: .normal)
        }
        if !profileData.activityLevel.isEmpty {
                switch profileData.activityLevel.lowercased() {
                case "sedentary":
                    sedentaryCard.isSelected = true
                case "moderate":
                    moderateCard.isSelected = true
                case "heavy":
                    heavyCard.isSelected = true
                default:
                    break
                }
            }
    }
    
    private func setupUI() {
        // Progress Bar
        progressView.progressTintColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        progressView.trackTintColor = .systemGray5
        progressView.progress = 1.0 // 5/5 complete
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Title Label
        titleLabel.text = "How Active Are You?"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Activity Stack View
        activityStackView.axis = .vertical
        activityStackView.spacing = 15
        activityStackView.distribution = .fillEqually
        activityStackView.translatesAutoresizingMaskIntoConstraints = false
        activityStackView.addArrangedSubview(sedentaryCard)
        activityStackView.addArrangedSubview(moderateCard)
        activityStackView.addArrangedSubview(heavyCard)
        view.addSubview(activityStackView)
        
        // Save Button
        saveButton.setTitle("Save & Continue", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveButton.backgroundColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
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
            activityStackView.heightAnchor.constraint(equalToConstant: 360),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 337),
            saveButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    private func setupActions() {
        let tapSedentary = UITapGestureRecognizer(target: self, action: #selector(activityCardTapped(_:)))
        sedentaryCard.addGestureRecognizer(tapSedentary)
        sedentaryCard.isUserInteractionEnabled = true
        
        let tapModerate = UITapGestureRecognizer(target: self, action: #selector(activityCardTapped(_:)))
        moderateCard.addGestureRecognizer(tapModerate)
        moderateCard.isUserInteractionEnabled = true
        
        let tapHeavy = UITapGestureRecognizer(target: self, action: #selector(activityCardTapped(_:)))
        heavyCard.addGestureRecognizer(tapHeavy)
        heavyCard.isUserInteractionEnabled = true
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    @objc private func activityCardTapped(_ gesture: UITapGestureRecognizer) {
        // Deselect all cards first
        sedentaryCard.isSelected = false
        moderateCard.isSelected = false
        heavyCard.isSelected = false
        
        if let selectedCard = gesture.view as? ActivityCard {
            selectedCard.isSelected = true
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Update profile data based on selected card
            switch selectedCard {
            case sedentaryCard:
                profileData.activityLevel = "Sedentary"
            case moderateCard:
                profileData.activityLevel = "Moderate"
            case heavyCard:
                profileData.activityLevel = "Heavy"
            default:
                break
            }
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
            "activityLevel": profileData.activityLevel
        ]

        db.collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                self.showAlert(message: "Error saving profile: \(error.localizedDescription)")
                return
            }

            // Update UserDefaults
            if let savedData = UserDefaults.standard.data(forKey: "currentUser"),
               var savedUser = try? JSONDecoder().decode(Users.self, from: savedData) {
                
                // Update only the activityLevel field
                savedUser.activityLevel = self.profileData.activityLevel

                do {
                    let encoder = JSONEncoder()
                    let encodedData = try encoder.encode(savedUser)
                    UserDefaults.standard.set(encodedData, forKey: "currentUser")
                } catch {
                    self.showAlert(message: "Error updating local data: \(error.localizedDescription)")
                }
            }

            // If editing, just pop; otherwise, continue onboarding
            if self.isEditingProfile {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.navigateToAllergyViewController()
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
        alert.view.tintColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
        present(alert, animated: true)
    }
}
