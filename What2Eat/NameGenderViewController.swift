import UIKit
import Firebase
import FirebaseAuth

class NameGenderViewController: UIViewController {
    
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nameTextField = UITextField()
    private let genderLabel = UILabel()
    private let genderStackView = UIStackView()
    private let maleButton = UIButton(type: .system)
    private let femaleButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    
    private let themeColor = UIColor(red: 245/255, green: 105/255, blue: 0/255, alpha: 1)
    private let backgroundGradientLayer = CAGradientLayer()
    
    private let profileData: UserProfileData
    private let isEditingProfile: Bool
    
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
        setupBackground()
        setupUI()
        setupActions()
        setupKeyboardDismissal()
        prefillGoogleName()
        animateElements()
        
        if isEditingProfile {
                    progressView.isHidden = true
                    nextButton.setTitle("Save", for: .normal)
                }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }
    
    private func setupBackground() {
        // Create a subtle gradient background
        backgroundGradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(white: 0.97, alpha: 1.0).cgColor
        ]
        backgroundGradientLayer.locations = [0.0, 1.0]
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }
    
    private func setupUI() {
        // Progress Bar
        progressView.progressTintColor = themeColor
        progressView.trackTintColor = .systemGray5
        progressView.progress = 0.2 // 1/5 complete
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Title
        titleLabel.text = "Tell Us About Yourself"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = themeColor
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "We'll use this to personalize your experience"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Name Text Field
        nameTextField.placeholder = "Your Name"
        nameTextField.backgroundColor = .white
        nameTextField.layer.cornerRadius = 12
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.systemGray5.cgColor
        nameTextField.layer.shadowColor = UIColor.black.cgColor
        nameTextField.layer.shadowOpacity = 0.08
        nameTextField.layer.shadowOffset = CGSize(width: 0, height: 2)
        nameTextField.layer.shadowRadius = 6
        nameTextField.textColor = .darkText
        nameTextField.font = .systemFont(ofSize: 17)
        
        // Add padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: nameTextField.frame.height))
        nameTextField.leftView = paddingView
        nameTextField.leftViewMode = .always
        nameTextField.rightView = paddingView
        nameTextField.rightViewMode = .always
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameTextField)
        
        // Gender Label
        genderLabel.text = "Gender"
        genderLabel.font = .systemFont(ofSize: 17, weight: .medium)
        genderLabel.textColor = .darkGray
        genderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(genderLabel)
        
        // Gender Selection
        genderStackView.axis = .vertical
        genderStackView.spacing = 20
        genderStackView.distribution = .fillEqually
        genderStackView.translatesAutoresizingMaskIntoConstraints = false
        
        configureGenderButton(maleButton, title: "Male", imageName: "male")
        configureGenderButton(femaleButton, title: "Female", imageName: "female")

        
        genderStackView.addArrangedSubview(maleButton)
        genderStackView.addArrangedSubview(femaleButton)
        view.addSubview(genderStackView)
        
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = themeColor
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 14
//        nextButton.layer.shadowColor = themeColor.cgColor
//        nextButton.layer.shadowOpacity = 0.3
//        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
//        nextButton.layer.shadowRadius = 8
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            nameTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            nameTextField.heightAnchor.constraint(equalToConstant: 55),
            
            genderLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 30),
            genderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            
            genderStackView.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 15),
//            genderStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
//            genderStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
//            genderStackView.heightAnchor.constraint(equalToConstant: 65),
//
            genderStackView.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 15),
               genderStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//               genderStackView.widthAnchor.constraint(equalToConstant: 344),
//               genderStackView.heightAnchor.constraint(equalToConstant: 388),
            genderStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
               // 2 buttons * 55 height each + 20 spacing
               genderStackView.heightAnchor.constraint(equalToConstant: 388),
            
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 337),
            nextButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    private func configureGenderButton(_ button: UIButton, title: String, imageName: String) {
        // Create a horizontal stack (label on left, image on right)
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        // Lower spacing so the text is closer to the image
        contentStack.spacing = 4
        contentStack.distribution = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Let the button itself handle taps
        contentStack.isUserInteractionEnabled = false

        // Label (30%)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        titleLabel.textColor = .darkText
        titleLabel.tag = 100
        // **Right-align the text** so it sits near the image
        titleLabel.textAlignment = .right
        
        // Image (70%)
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(named: imageName)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add label first, then image
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(iconImageView)
        
        // Add stack to button
        button.addSubview(contentStack)
        
        // Constrain the stack to the button’s edges
        NSLayoutConstraint.activate([
            // Increase if you want more left padding
            contentStack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 0),
            
            // 30% for label, 70% for image
            titleLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.3),
            iconImageView.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.7),
        ])
        
        // Style the button
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray5.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
    }
    
    private func setupActions() {
        maleButton.addTarget(self, action: #selector(genderSelected(_:)), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(genderSelected(_:)), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        // Add text field editing changed action to validate input
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    private func setupKeyboardDismissal() {
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func animateElements() {
        // Initial state
        let elements = [titleLabel, subtitleLabel, nameTextField, genderLabel, genderStackView, nextButton]
        elements.forEach { $0.alpha = 0 }
        elements.forEach { $0.transform = CGAffineTransform(translationX: 0, y: 20) }
        
        // Animation sequence
        UIView.animate(withDuration: 0.5, delay: 0.1, options: [.curveEaseOut], animations: {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [.curveEaseOut], animations: {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.3, options: [.curveEaseOut], animations: {
            self.nameTextField.alpha = 1
            self.nameTextField.transform = .identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.4, options: [.curveEaseOut], animations: {
            self.genderLabel.alpha = 1
            self.genderLabel.transform = .identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseOut], animations: {
            self.genderStackView.alpha = 1
            self.genderStackView.transform = .identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.6, options: [.curveEaseOut], animations: {
            self.nextButton.alpha = 1
            self.nextButton.transform = .identity
        })
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Add visual feedback as user types
        UIView.animate(withDuration: 0.2) {
            if textField.text?.isEmpty == false {
                textField.layer.borderColor = self.themeColor.cgColor
            } else {
                textField.layer.borderColor = UIColor.systemGray5.cgColor
            }
        }
    }
    private func updateButtonLabelColor(for button: UIButton, color: UIColor) {
        for subview in button.subviews {
            if let stack = subview as? UIStackView {
                for arrangedSubview in stack.arrangedSubviews {
                    if let label = arrangedSubview as? UILabel, label.tag == 100 {
                        label.textColor = color
                    }
                }
            }
        }
    }

    
    @objc private func genderSelected(_ sender: UIButton) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        UIView.animate(withDuration: 0.2) {
            if sender == self.maleButton {
                // Male selected
                self.maleButton.backgroundColor = self.themeColor
                self.maleButton.setTitleColor(.white, for: .normal)
                self.updateButtonLabelColor(for: self.maleButton, color: .white)
                // Remove border when selected
                self.maleButton.layer.borderWidth = 0
                
                // Reset female button
                self.femaleButton.backgroundColor = .white
                self.femaleButton.setTitleColor(.darkText, for: .normal)
                self.femaleButton.layer.borderWidth = 1
                self.updateButtonLabelColor(for: self.femaleButton, color: .darkText)
                self.profileData.gender = "male"
            } else {
                // Female selected
                self.femaleButton.backgroundColor = self.themeColor
                self.femaleButton.setTitleColor(.white, for: .normal)
                self.femaleButton.layer.borderWidth = 0
                self.updateButtonLabelColor(for: self.femaleButton, color: .white)
                // Reset male button
                self.maleButton.backgroundColor = .white
                self.maleButton.setTitleColor(.darkText, for: .normal)
                self.maleButton.layer.borderWidth = 1
                self.updateButtonLabelColor(for: self.maleButton, color: .darkText)
                self.profileData.gender = "female"
            }
        }

        // Animate the "Next" button to draw attention
//        UIView.animate(withDuration: 0.3, animations: {
//            self.nextButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
//        }) { _ in
//            UIView.animate(withDuration: 0.2) {
//                self.nextButton.transform = .identity
//            }
//        }
    }

    
    @objc private func nextTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              !profileData.gender.isEmpty else {
            showAlert(message: "Please enter your name and select a gender.")
            if nameTextField.text?.isEmpty == true {
                shakeView(nameTextField)
            }
            if profileData.gender.isEmpty {
                shakeView(genderStackView)
            }
            return
        }
        
        profileData.name = name
        
        if isEditingProfile {
            updateFirebaseProfile()
        } else {
            let nextVC = AgeViewController(profileData: profileData)
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }

    private func updateFirebaseProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        // Create a dictionary with only the updated fields (in this case, name and gender)
        let updatedData: [String: Any] = [
            "name": profileData.name,
            "gender": profileData.gender
        ]
        
        db.collection("users").document(uid).setData(updatedData, merge: true) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: "Error saving profile: \(error.localizedDescription)")
            } else {
                // Optionally update local storage here
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    
    private func shakeView(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-10, 10, -10, 10, -5, 5, -2.5, 2.5, 0]
        view.layer.add(animation, forKey: "shake")
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        // Only adjust view if text field is active and might be covered
        if nameTextField.isFirstResponder && view.frame.origin.y == 0 {
            // Calculate if the text field will be covered
            let textFieldBottom = nameTextField.convert(nameTextField.bounds, to: view).maxY
            let keyboardTop = view.frame.height - keyboardSize.height
            
            if textFieldBottom > keyboardTop {
                // Move view up by the distance the keyboard covers the text field plus padding
                view.frame.origin.y = -(textFieldBottom - keyboardTop + 20)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset view position
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
    
    private func prefillGoogleName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let data = document?.data(), let googleName = data["name"] as? String, !googleName.isEmpty {
                self?.nameTextField.text = googleName
                // Trigger border color change
                self?.textFieldDidChange(self!.nameTextField)
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.view.tintColor = themeColor
        present(alert, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
