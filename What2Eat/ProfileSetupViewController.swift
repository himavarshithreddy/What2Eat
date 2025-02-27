import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ProfileSetupViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Set Up Your Profile"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Let’s get to know you better!"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Your Name"
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.textColor = .darkText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0)) // Padding
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let genderTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Gender (Male/Female)"
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.textColor = .darkText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let ageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Age (years)"
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.keyboardType = .numberPad
        textField.textColor = .darkText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let weightTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Weight (kg)"
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.keyboardType = .decimalPad
        textField.textColor = .darkText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let heightTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Height (cm)"
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.keyboardType = .decimalPad
        textField.textColor = .darkText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let activityLevelTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Activity Level"
        textField.borderStyle = .none
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 12
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)
        textField.layer.shadowRadius = 4
        textField.textColor = .darkText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let activityPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save & Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityLevels = ["Sedentary", "Moderate", "Heavy"]
    private var selectedActivityLevel: String?
   
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupPicker()
        setupActions()
        prefillGoogleName()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(genderTextField)
        contentView.addSubview(ageTextField)
        contentView.addSubview(weightTextField)
        contentView.addSubview(heightTextField)
        contentView.addSubview(activityLevelTextField)
        contentView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            nameTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            genderTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            genderTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            genderTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            genderTextField.heightAnchor.constraint(equalToConstant: 50),
            
            ageTextField.topAnchor.constraint(equalTo: genderTextField.bottomAnchor, constant: 20),
            ageTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            ageTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            ageTextField.heightAnchor.constraint(equalToConstant: 50),
            
            weightTextField.topAnchor.constraint(equalTo: ageTextField.bottomAnchor, constant: 20),
            weightTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weightTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weightTextField.heightAnchor.constraint(equalToConstant: 50),
            
            heightTextField.topAnchor.constraint(equalTo: weightTextField.bottomAnchor, constant: 20),
            heightTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            heightTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            heightTextField.heightAnchor.constraint(equalToConstant: 50),
            
            activityLevelTextField.topAnchor.constraint(equalTo: heightTextField.bottomAnchor, constant: 20),
            activityLevelTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityLevelTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            activityLevelTextField.heightAnchor.constraint(equalToConstant: 50),
            
            saveButton.topAnchor.constraint(equalTo: activityLevelTextField.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 220),
            saveButton.heightAnchor.constraint(equalToConstant: 55),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Setup Picker
    private func setupPicker() {
        activityPicker.delegate = self
        activityPicker.dataSource = self
        activityLevelTextField.inputView = activityPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spaceButton, doneButton], animated: false)
        activityLevelTextField.inputAccessoryView = toolbar
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Action Handlers
    @objc private func donePicker() {
        let selectedRow = activityPicker.selectedRow(inComponent: 0)
        selectedActivityLevel = activityLevels[selectedRow]
        activityLevelTextField.text = selectedActivityLevel
        view.endEditing(true)
    }
    
    @objc private func saveButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              let gender = genderTextField.text?.lowercased(), !gender.isEmpty, ["male", "female"].contains(gender),
              let ageText = ageTextField.text, let age = Int(ageText), age > 0,
              let weightText = weightTextField.text, let weight = Double(weightText), weight > 0,
              let heightText = heightTextField.text, let height = Double(heightText), height > 0,
              let activityLevel = selectedActivityLevel else {
            showAlert(message: "Please fill all fields correctly.")
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated.")
            return
        }
        
        updateUserProfile(uid: uid, name: name, gender: gender, age: age, weight: weight, height: height, activityLevel: activityLevel)
    }
    
    // MARK: - Firestore Update
    private func updateUserProfile(uid: String, name: String, gender: String, age: Int, weight: Double, height: Double, activityLevel: String) {
            let db = Firestore.firestore()
            
            let updatedUserData: [String: Any] = [
                "name": name,
                "dietaryRestrictions": [],
                "allergies": [],
                "gender": gender,
                "age": age,
                "weight": weight,
                "height": height,
                "activityLevel": activityLevel
            ]
            
            // Save to Firestore
            db.collection("users").document(uid).setData(updatedUserData) { error in
                if let error = error {
                    self.showAlert(message: "Error saving profile: \(error.localizedDescription)")
                    return
                }
                
                // Create Users object
                let user = Users(
                    name: name,
                    dietaryRestrictions: [],
                    allergies: [],
                    gender: gender,
                    age: age,
                    weight: weight,
                    height: height,
                    activityLevel: activityLevel
                )
                
                // Save to UserDefaults
                do {
                    let encoder = JSONEncoder()
                    let userData = try encoder.encode(user)
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    isOnboarding = true
                    self.navigateToAllergyViewController()
                } catch {
                    print("Error encoding user to UserDefaults: \(error.localizedDescription)")
                    self.showAlert(message: "Error saving profile locally.")
                }
            }
        }
    
    // MARK: - Prefill Google Name
    private func prefillGoogleName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let data = document?.data(), let googleName = data["name"] as? String, !googleName.isEmpty {
                self?.nameTextField.text = googleName
            }
        }
    }
    
    // MARK: - Navigation with Transition
    private func navigateToAllergyViewController() {
      
        guard let windowScene = view.window?.windowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("Unable to find window for navigation")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let allergyNavController = storyboard.instantiateViewController(withIdentifier: "AllergyNavController")
        
        // Add fade transition
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .fade
        window.layer.add(transition, forKey: kCATransition)
        
        window.rootViewController = allergyNavController
        window.makeKeyAndVisible()
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.view.tintColor = UIColor(red: 228/255, green: 113/255, blue: 45/255, alpha: 1)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension ProfileSetupViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return activityLevels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return activityLevels[row]
    }
}
