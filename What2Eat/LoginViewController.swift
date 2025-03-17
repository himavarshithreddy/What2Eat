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
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var VerificationView: UIView!
    // MARK: - Properties
    var verificationID: String?
    var currentUserUID: String?
    private var resendTimer: Timer?
    private var resendCooldown: Int = 0
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initial UI setup
        verificationCodeTextField.isHidden = true
        ResendCodeLabel.isHidden = true
        VerificationView.isHidden = true
        
        // Configure activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.color = UIColor(red: 254/255, green: 139/255, blue: 54/255, alpha: 1)
        
        // Set text field delegates
        phoneTextField.delegate = self
        verificationCodeTextField.delegate = self
        
        // Configure resend code label with tap gesture
        ResendCodeLabel.isUserInteractionEnabled = true
        ResendCodeLabel.text = "Resend Code"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(resendCodeTapped))
        ResendCodeLabel.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resendTimer?.invalidate()
    }
    
    // MARK: - Actions
    @IBAction func sendCodeButtonTapped(_ sender: Any) {
        if verificationCodeTextField.isHidden {
            // Send verification code
            guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
                showAlert(message: "Please enter a phone number.")
                return
            }
            
            if !isValidPhoneNumber(phoneNumber) {
                showAlert(message: "Please enter a valid phone number starting with '+' followed by digits.")
                return
            }
            
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            sendVerificationCode(phoneNumber: phoneNumber)
        } else {
            // Verify code
            guard let verificationCode = verificationCodeTextField.text, !verificationCode.isEmpty else {
                showAlert(message: "Please enter the verification code.")
                return
            }
            
            guard let verificationID = self.verificationID else {
                showAlert(message: "Verification ID not found.")
                return
            }
            
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
            
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            
            Auth.auth().signIn(with: credential) { authResult, error in
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                
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
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
            if let error = error {
                self.showAlert(message: "Error Signing In: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
                self.showAlert(message: "No user found")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
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
    
//    @IBAction func continueAsGuest(_ sender: Any) {
//        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
//        navigateToTabBarController()
//    }
    
    @objc func resendCodeTapped() {
        guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
            showAlert(message: "Please enter a phone number.")
            return
        }
        
        if resendCooldown == 0 {
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
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
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
    
    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneTextField {
            // Must start with "+"
            if newText.hasPrefix("+") {
                let remaining = String(newText.dropFirst())
                let pattern1 = "^\\d*$"
                let pattern2 = "^\\d{2} \\d*$"
                // Check if the remaining text matches either pattern
                if remaining.range(of: pattern1, options: .regularExpression) != nil ||
                   remaining.range(of: pattern2, options: .regularExpression) != nil {
                    return newText.count <= 14      // Enforce max length
                }
            }
            return false // Disallow if it doesn’t start with "+"
        } else if textField == verificationCodeTextField {
            // For verification code: only digits, max 6
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet) && newText.count <= 6
        }
        return true
    }


    @IBAction func SigninwithAppleButtonTapped(_ sender: Any) {
        
        activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            startSignInWithAppleFlow()
        
        
    }
    private var currentNonce: String?

    // Add these methods before your existing actions
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
        
        // Animate toast appearance and disappearance
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
}
// Add these extensions at the bottom of your file
extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                activityIndicator.stopAnimating()
                view.isUserInteractionEnabled = true
                showAlert(message: "Invalid state: No login request was sent.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                activityIndicator.stopAnimating()
                view.isUserInteractionEnabled = true
                showAlert(message: "Unable to fetch identity token.")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                activityIndicator.stopAnimating()
                view.isUserInteractionEnabled = true
                showAlert(message: "Unable to serialize token string.")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                
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
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
        showAlert(message: "Sign in with Apple failed: \(error.localizedDescription)")
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
