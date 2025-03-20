import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseStorage
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var verificationCodeTextField: UITextField!
    @IBOutlet var sendCodeButton: UIButton!
    @IBOutlet var ResendCodeLabel: UILabel!
    @IBOutlet var VerificationView: UIView!
    @IBOutlet var googleSignInButton: UIButton!
    @IBOutlet var appleSignInButton: UIButton!
    
    // MARK: - Properties
    var verificationID: String?
    var currentUserUID: String?
    private var resendTimer: Timer?
    private var resendCooldown: Int = 0

    
    // Activity Indicators
    private let phoneAuthIndicator = UIActivityIndicatorView(style: .medium)
    private let googleAuthIndicator = UIActivityIndicatorView(style: .medium)
    private let appleAuthIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initial UI setup
        verificationCodeTextField.isHidden = true
        ResendCodeLabel.isHidden = true
        VerificationView.isHidden = true
        
        // Set text field delegates
        phoneTextField.delegate = self
        verificationCodeTextField.delegate = self
        
        // Configure resend code label with tap gesture
        ResendCodeLabel.isUserInteractionEnabled = true
        ResendCodeLabel.text = "Resend Code"
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(resendCodeTapped))
        ResendCodeLabel.addGestureRecognizer(tapGesture1)
        
        // Configure activity indicators
        setupActivityIndicators()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                // Ensure that tap gestures in subviews (like buttons) aren’t canceled
                tapGesture.cancelsTouchesInView = false
                view.addGestureRecognizer(tapGesture)
    }
    @objc func dismissKeyboard() {
           view.endEditing(true)
       }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resendTimer?.invalidate()
    }
    
    // MARK: - Helper Methods
    private func setupActivityIndicators() {
        // Phone Auth Indicator
        phoneAuthIndicator.color = .white
        phoneAuthIndicator.hidesWhenStopped = true
        sendCodeButton.addSubview(phoneAuthIndicator)
        phoneAuthIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            phoneAuthIndicator.centerXAnchor.constraint(equalTo: sendCodeButton.centerXAnchor),
            phoneAuthIndicator.centerYAnchor.constraint(equalTo: sendCodeButton.centerYAnchor)
        ])
        
        // Google Auth Indicator
        googleAuthIndicator.color = .black
        googleAuthIndicator.hidesWhenStopped = true
        googleSignInButton.addSubview(googleAuthIndicator)
        googleAuthIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            googleAuthIndicator.centerXAnchor.constraint(equalTo: googleSignInButton.centerXAnchor),
            googleAuthIndicator.centerYAnchor.constraint(equalTo: googleSignInButton.centerYAnchor)
        ])
        
        // Apple Auth Indicator
        appleAuthIndicator.color = .white
        appleAuthIndicator.hidesWhenStopped = true
        appleSignInButton.addSubview(appleAuthIndicator)
        appleAuthIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            appleAuthIndicator.centerXAnchor.constraint(equalTo: appleSignInButton.centerXAnchor),
            appleAuthIndicator.centerYAnchor.constraint(equalTo: appleSignInButton.centerYAnchor)
        ])
    }
    
    private func showLoading(for button: UIButton, indicator: UIActivityIndicatorView, originalTitle: String) {
        button.setTitle("", for: .normal)
        button.titleLabel!.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setImage(nil, for: .normal)
        button.imageView!.isHidden = true
        indicator.startAnimating()
       
    }
    
    private func hideLoading(for button: UIButton, indicator: UIActivityIndicatorView, originalTitle: String) {
        indicator.stopAnimating()
        button.setTitle(originalTitle, for: .normal)
        button.titleLabel!.font = .systemFont(ofSize: 17, weight: .semibold)
      
        button.imageView!.isHidden = false
        if button == googleSignInButton {
                    button.setImage(UIImage(named: "icons8-google-48"), for: .normal) // Replace with your actual Google icon name
                } else if button == appleSignInButton {
                    button.setImage(UIImage(named: "Logo - SIWA - Left-aligned - White - Medium"), for: .normal) // Replace with your actual Apple icon name
                }
        button.isEnabled = true
    }
    
    // MARK: - Actions
    @IBAction func sendCodeButtonTapped(_ sender: Any) {
        let originalTitle = verificationCodeTextField.isHidden ? "Continue" : "Verify Code"
        
        if verificationCodeTextField.isHidden {
            guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
                showAlert(message: "Please enter a phone number.")
                return
            }
            
            if !isValidPhoneNumber(phoneNumber) {
                showAlert(message: "Please enter a valid phone number starting with '+' followed by digits.")
                return
            }
            
            showLoading(for: sendCodeButton, indicator: phoneAuthIndicator, originalTitle: originalTitle)
            sendVerificationCode(phoneNumber: phoneNumber)
        } else {
            guard let verificationCode = verificationCodeTextField.text, !verificationCode.isEmpty else {
                showAlert(message: "Please enter the verification code.")
                return
            }
            
            guard let verificationID = self.verificationID else {
                showAlert(message: "Verification ID not found.")
                return
            }
            
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
            
            showLoading(for: sendCodeButton, indicator: phoneAuthIndicator, originalTitle: originalTitle)
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }
                
                self.hideLoading(for: self.sendCodeButton, indicator: self.phoneAuthIndicator, originalTitle: originalTitle)
                
                if let error = error {
                    self.showAlert(message: "Error verifying code: \(error.localizedDescription)")
                    return
                }
                
                if let user = authResult?.user {
                    self.currentUserUID = user.uid
                    self.handleUserAuthentication(uid: user.uid)
                }
            }
        }
    }
    
    @IBAction func GoogleSignInButtonTapped(_ sender: Any) {
        showLoading(for: googleSignInButton, indicator: googleAuthIndicator, originalTitle: "Continue with Google")
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            self.hideLoading(for: self.googleSignInButton, indicator: self.googleAuthIndicator, originalTitle: "Continue with Google")
            
            if let error = error {
                self.showAlert(message: "Error Signing In: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
                self.showAlert(message: "No user found")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            showLoading(for: self.googleSignInButton, indicator: self.googleAuthIndicator, originalTitle: "Continue with Google")
            Auth.auth().signIn(with: credential) { authResult, error in
                self.hideLoading(for: self.googleSignInButton, indicator: self.googleAuthIndicator, originalTitle: "Continue with Google")
                
                if let error = error {
                    self.showAlert(message: "Error Signing In: \(error.localizedDescription)")
                    return
                }
                
                if let uid = authResult?.user.uid {
                    self.handleUserAuthentication(uid: uid, googleName: user.profile?.name, googleImageUrl: user.profile?.imageURL(withDimension: 200)?.absoluteString)
                }
            }
        }
    }
    
    @IBAction func SigninwithAppleButtonTapped(_ sender: Any) {
        showLoading(for: appleSignInButton, indicator: appleAuthIndicator, originalTitle: "Continue with Apple")
        startSignInWithAppleFlow()
    }
    
    @objc func resendCodeTapped() {
        guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
            showAlert(message: "Please enter a phone number.")
            return
        }
        
        if resendCooldown == 0 {
            showLoading(for: sendCodeButton, indicator: phoneAuthIndicator, originalTitle: "Verify Code")
            sendVerificationCode(phoneNumber: phoneNumber, isResend: true)
        }
    }
   
    // MARK: - Firestore Methods
    private func fetchUserData(uid: String, completion: @escaping (Users?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                self.showAlert(message: "Error fetching user data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil)
                return
            }
            
            let user = Users(
                name: data["name"] as? String ?? "",
                dietaryRestrictions: data["dietaryRestrictions"] as? [String] ?? [],
                allergies: data["allergies"] as? [String] ?? [],
                gender: data["gender"] as? String ?? "",
                age: data["age"] as? Int ?? 0,
                weight: data["weight"] as? Double ?? 0.0,
                height: data["height"] as? Double ?? 0.0,
                activityLevel: data["activityLevel"] as? String ?? ""
            )
            completion(user)
        }
    }
    
    private func createNewUser(uid: String, googleName: String? = nil, googleImageUrl: String? = nil) {
        let db = Firestore.firestore()
        let newUser = Users(
            name: googleName ?? "",
            dietaryRestrictions: [],
            allergies: [],
            gender: "",
            age: 0,
            weight: 0.0,
            height: 0.0,
            activityLevel: ""
        )
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        let defaultListId = UUID().uuidString
        let defaultList: [String: Any] = [
            "listId": defaultListId,
            "name": "Favorites",
            "iconName": "heart.fill",
            "products": []
        ]
        
        if let googleImageUrl = googleImageUrl, let url = URL(string: googleImageUrl) {
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("Failed to get image data")
                    return
                }
                
                storageRef.putData(data, metadata: nil) { _, error in
                    if let error = error {
                        print("Error uploading image: \(error.localizedDescription)")
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error fetching download URL: \(error.localizedDescription)")
                            return
                        }
                        
                        let profileImageUrl = url?.absoluteString ?? ""
                        let newUserData: [String: Any] = [
                            "name": googleName ?? "",
                            "dietaryRestrictions": [],
                            "allergies": [],
                            "gender": "",
                            "age": 0,
                            "weight": 0.0,
                            "height": 0.0,
                            "activityLevel": "",
                            "profileImageUrl": profileImageUrl,
                            "savedLists": [defaultList]
                        ]
                        
                        db.collection("users").document(uid).setData(newUserData) { error in
                            if let error = error {
                                print("Error creating new user: \(error.localizedDescription)")
                                return
                            }
                            do {
                                let encoder = JSONEncoder()
                                let encodedData = try encoder.encode(newUser)
                                UserDefaults.standard.set(encodedData, forKey: "currentUser")
                            } catch {
                                print("Error encoding new user: \(error.localizedDescription)")
                            }
                            self.navigateToProfileSetupViewController()
                        }
                    }
                }
            }.resume()
        } else {
            let newUserData: [String: Any] = [
                "name": googleName ?? "",
                "dietaryRestrictions": [],
                "allergies": [],
                "gender": "",
                "age": 0,
                "weight": 0.0,
                "height": 0.0,
                "activityLevel": "",
                "profileImageUrl": "",
                "savedLists": [defaultList]
            ]
            
            db.collection("users").document(uid).setData(newUserData) { error in
                if let error = error {
                    print("Error creating new user: \(error.localizedDescription)")
                    return
                }
                do {
                    let encoder = JSONEncoder()
                    let encodedData = try encoder.encode(newUser)
                    UserDefaults.standard.set(encodedData, forKey: "currentUser")
                } catch {
                    print("Error encoding new user: \(error.localizedDescription)")
                }
                self.navigateToProfileSetupViewController()
            }
        }
    }
    
    // MARK: - Navigation Methods
    private func handleUserAuthentication(uid: String, googleName: String? = nil, googleImageUrl: String? = nil) {
        fetchUserData(uid: uid) { user in
            if let user = user {
                do {
                    let encoder = JSONEncoder()
                    let userData = try encoder.encode(user)
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                } catch {
                    print("Error encoding user to UserDefaults: \(error.localizedDescription)")
                }
                
                if user.name.isEmpty || user.gender.isEmpty || user.age == 0 || user.weight == 0.0 || user.height == 0.0 || user.activityLevel.isEmpty {
                    self.navigateToProfileSetupViewController()
                } else {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    self.navigateToTabBarController()
                }
            } else {
                self.createNewUser(uid: uid, googleName: googleName, googleImageUrl: googleImageUrl)
            }
        }
    }
    
    private func navigateToTabBarController() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if hasCompletedOnboarding {
            if let windowScene = view.window?.windowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") {
                window.rootViewController = tabBarController
                window.makeKeyAndVisible()
            }
        } else {
            navigateToProfileSetupViewController()
        }
    }
    
    private func navigateToProfileSetupViewController() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        isOnboarding = true
        let profileData = UserProfileData()
        if let windowScene = view.window?.windowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let nameGenderVC = NameGenderViewController(profileData: profileData)
            let navigationController = UINavigationController(rootViewController: nameGenderVC)
            navigationController.navigationBar.isHidden = true
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - Helper Methods
    private func sendVerificationCode(phoneNumber: String, isResend: Bool = false) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self = self else { return }
            
            self.hideLoading(for: self.sendCodeButton, indicator: self.phoneAuthIndicator, originalTitle: isResend ? "Verify Code" : "Continue")
            
            if let error = error {
                self.showAlert(message: "Error sending verification code: \(error.localizedDescription)")
                return
            }
            
            self.verificationID = verificationID
            self.VerificationView.isHidden = false
            self.verificationCodeTextField.isHidden = false
            self.ResendCodeLabel.isHidden = false
            
            self.verificationCodeTextField.becomeFirstResponder()
            self.sendCodeButton.setTitle("Verify Code", for: .normal)
            
            self.startResendCooldown()
            
            if isResend {
                self.showStatusMessage("Code Successfully Resent")
            }
        }
    }
    
    private func startResendCooldown() {
        resendCooldown = 30
        ResendCodeLabel.isUserInteractionEnabled = false
        resendTimer?.invalidate()
        
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.resendCooldown -= 1
            if self.resendCooldown > 0 {
                self.ResendCodeLabel.text = "Resend Code in \(self.resendCooldown)s"
            } else {
                timer.invalidate()
                self.ResendCodeLabel.text = "Resend Code"
                self.ResendCodeLabel.isUserInteractionEnabled = true
            }
        }
    }
    
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^\\+(\\d{10,}|\\d{2} \\d{10,})$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: phoneNumber)
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showStatusMessage(_ message: String) {
        let toastView = UIView()
        toastView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.9)
        toastView.layer.cornerRadius = 10
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        toastView.addSubview(toastLabel)
        view.addSubview(toastView)
        
        NSLayoutConstraint.activate([
            toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastView.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            toastView.heightAnchor.constraint(equalToConstant: 40),
            
            toastLabel.centerXAnchor.constraint(equalTo: toastView.centerXAnchor),
            toastLabel.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
            toastLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 15),
            toastLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -15)
        ])
        
        toastView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                toastView.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        })
    }
    
    // MARK: - Apple Sign In
    private var currentNonce: String?
    
    private func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneTextField {
            if newText.hasPrefix("+") {
                let remaining = String(newText.dropFirst())
                let pattern1 = "^\\d*$"
                let pattern2 = "^\\d{2} \\d*$"
                if remaining.range(of: pattern1, options: .regularExpression) != nil ||
                   remaining.range(of: pattern2, options: .regularExpression) != nil {
                    return newText.count <= 14
                }
            }
            return false
        } else if textField == verificationCodeTextField {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet) && newText.count <= 6
        }
        return true
    }
}

// MARK: - Extensions
extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                hideLoading(for: appleSignInButton, indicator: appleAuthIndicator, originalTitle: "Continue with Apple")
                showAlert(message: "Invalid state: No login request was sent.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                hideLoading(for: appleSignInButton, indicator: appleAuthIndicator, originalTitle: "Continue with Apple")
                showAlert(message: "Unable to fetch identity token.")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                hideLoading(for: appleSignInButton, indicator: appleAuthIndicator, originalTitle: "Continue with Apple")
                showAlert(message: "Unable to serialize token string.")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }
                
                self.hideLoading(for: self.appleSignInButton, indicator: self.appleAuthIndicator, originalTitle: "Continue with Apple")
                
                if let error = error {
                    self.showAlert(message: "Error signing in with Apple: \(error.localizedDescription)")
                    return
                }
                
                if let user = authResult?.user {
                    let fullName = appleIDCredential.fullName?.givenName ?? ""
                    self.handleUserAuthentication(uid: user.uid, googleName: fullName)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        hideLoading(for: appleSignInButton, indicator: appleAuthIndicator, originalTitle: "Continue with Apple")
        showAlert(message: "Continue with Apple failed: \(error.localizedDescription)")
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
