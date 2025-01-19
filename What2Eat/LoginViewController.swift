import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var verificationCodeTextField: UITextField!
    
    @IBOutlet var sendCodeButton: UIButton!
    var verificationID: String?
    // Declare the activity indicator
    var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        verificationCodeTextField.isHidden = true
        guard let clientID = FirebaseApp.app()?.options.clientID else { fatalError("Google client ID not found") }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        // Initialize the activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }
    
    @IBAction func sendCodeButtonTapped(_ sender: Any) {
            // If the text field is not empty and it's the first step (send code)
            if verificationCodeTextField.isHidden {
                guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
                    showAlert(message: "Please enter a valid phone number.")
                    return
                }
                
                // Show activity indicator
                activityIndicator.startAnimating()
                view.isUserInteractionEnabled = false // Disable user interaction
                
                PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true // Enable user interaction
                    
                    if let error = error {
                        self.showAlert(message: "Error sending verification code: \(error.localizedDescription)")
                        return
                    }
                    
                    // Save the verification ID for later use when verifying the code
                    self.verificationID = verificationID
                    
                    // Show the verification code field and change the button text
                    self.verificationCodeTextField.isHidden = false
                    self.sendCodeButton.setTitle("Verify Code", for: .normal)
                }
            } else {
                // If the verification code text field is visible, verify the code
                guard let verificationCode = verificationCodeTextField.text, !verificationCode.isEmpty else {
                    showAlert(message: "Please enter the verification code.")
                    return
                }
                
                guard let verificationID = self.verificationID else {
                    showAlert(message: "Verification ID not found.")
                    return
                }
                
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
                
                // Sign in the user with the phone number credential
                activityIndicator.startAnimating()
                view.isUserInteractionEnabled = false // Disable user interaction
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true // Enable user interaction
                    
                    if let error = error {
                        self.showAlert(message: "Error verifying code: \(error.localizedDescription)")
                        return
                    }
                    
                    if let user = authResult?.user {
                        print("User logged in: \(user.phoneNumber ?? "No phone number")")
                        self.fetchUserData(uid: user.uid) { userData in
                            if userData.isEmpty {
                                // User document does not exist, create a new one
                                self.createNewUser(uid: user.uid, name: "Guest")
                            } else {
                                // User data exists, proceed
                                _ = Users(
                                    name: userData["name"] as? String ?? "",
                                    dietaryRestrictions: userData["dietaryRestrictions"] as? [String] ?? [],
                                    allergies: userData["allergies"] as? [String] ?? [],
                                    recentlyViewedProducts: userData["recentlyViewedProducts"] as? [String] ?? []
                                )
                                self.navigateToTabBarController()
                            }
                        }
                    }
                }
            }
        }
            
    private func navigateToTabBarController() {
        // Get the active window from UIWindowScene (iOS 13+)
        if let windowScene = view.window?.windowScene {
            if let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                // Instantiate the Tab Bar Controller from the storyboard
                if let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") {
                    // Set the Tab Bar Controller as the root view controller
                    window.rootViewController = tabBarController
                    window.makeKeyAndVisible()
                }
            }
        }
    }
    
    // Function to show alert with custom message
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func GoogleSignInButtonTapped(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                print("Error Signing In: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
                print("No user found")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error Signing In: \(error.localizedDescription)")
                    return
                }
                
                print("User signed in successfully")
                
                // Fetch the user from Firestore
                self.fetchUserData(uid: authResult?.user.uid ?? "") { userData in
                    if userData.isEmpty {
                        // User document does not exist, create a new one
                        self.createNewUser(uid: authResult?.user.uid ?? "", name: user.profile?.name ?? "")
                    } else {
                        // User data exists, proceed
                        _ = Users(
                            name: userData["name"] as? String ?? "",
                            dietaryRestrictions: userData["dietaryRestrictions"] as? [String] ?? [],
                            allergies: userData["allergies"] as? [String] ?? [],
                            recentlyViewedProducts: userData["recentlyViewedProducts"] as? [String] ?? []
                        )
                        // Continue to the next screen
                        self.navigateToTabBarController()
                    }
                }
            }
        }
    }

    // Fetch user data from Firestore
    private func fetchUserData(uid: String, completion: @escaping ([String: Any]) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                self.showAlert(message: "Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            // Check if the document exists, if not, return an empty dictionary
            guard let document = document, document.exists else {
                completion([:])
                return
            }

            // Pass the document data to the completion handler
            completion(document.data() ?? [:])
        }
    }


    // Function to create a new user document in Firestore
    private func createNewUser(uid: String, name: String) {
        let db = Firestore.firestore()
        
        // Default data for a new user
        let newUserData: [String: Any] = [
            "name": name,
            "dietaryRestrictions": [],
            "allergies": [],
            "recentlyViewedProducts": []
        ]
        
        // Create the document in the 'users' collection with the user's UID as document ID
        db.collection("users").document(uid).setData(newUserData) { error in
            if let error = error {
                print("Error creating new user: \(error.localizedDescription)")
                self.showAlert(message: "Error creating new user: \(error.localizedDescription)")
                return
            }
            
            print("New user created successfully")
            self.navigateToTabBarController()
        }
    }


    private func highlightField(_ textField: UITextField) {
            textField.layer.borderColor = UIColor.red.cgColor
            textField.layer.borderWidth = 1.0
            textField.layer.cornerRadius = 5.0
        }

        // Function to remove the red border when the user starts editing
        @objc private func textFieldEditingDidBegin(_ textField: UITextField) {
            textField.layer.borderColor = UIColor.clear.cgColor
            textField.layer.borderWidth = 0
        }

    @IBAction func ContinueAsGuest(_ sender: Any) {
        self.navigateToTabBarController()
    }
}
