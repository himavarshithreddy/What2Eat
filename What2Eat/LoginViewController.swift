import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

class LoginViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var verificationCodeTextField: UITextField!
    @IBOutlet var sendCodeButton: UIButton!
    
    // MARK: - Properties
    var verificationID: String?
    var currentUserUID: String?
    var activityIndicator: UIActivityIndicatorView!

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initially hide the verification code field
        verificationCodeTextField.isHidden = true
        
        // Initialize and set up the activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        
        // Additional setup if needed...
    }
    
    // MARK: - Actions
    @IBAction func sendCodeButtonTapped(_ sender: Any) {
        // First step: sending the verification code
        if verificationCodeTextField.isHidden {
            guard let phoneNumber = phoneTextField.text, !phoneNumber.isEmpty else {
                showAlert(message: "Please enter a valid phone number.")
                return
            }
            
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                
                if let error = error {
                    self.showAlert(message: "Error sending verification code: \(error.localizedDescription)")
                    return
                }
                
                // Save the verification ID for later use
                self.verificationID = verificationID
                
                // Show the verification code text field and update the button title
                self.verificationCodeTextField.isHidden = false
                self.sendCodeButton.setTitle("Verify Code", for: .normal)
            }
        } else {
            // Second step: verifying the code
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
                
                // Successfully signed in
                if let user = authResult?.user {
                    // Save the current user's UID for later use
                    self.currentUserUID = user.uid
                    
                    // Fetch Firestore user data
                    self.fetchUserData(uid: user.uid) { userData in
                        if userData.isEmpty {
                            // New user: present NameViewController to collect the name
                            self.presentNameViewController()
                        } else {
                            // Existing user: navigate directly to the main app
                            self.navigateToTabBarController()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Firestore Methods
    private func fetchUserData(uid: String, completion: @escaping ([String: Any]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                self.showAlert(message: "Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                completion([:])  // No user data found
                return
            }
            
            completion(document.data() ?? [:])
        }
    }
    
    private func createNewUser(uid: String, name: String, profileImageUrl: String? = nil) {
        let db = Firestore.firestore()
        
        // Create a dictionary with the basic user details.
        var newUserData: [String: Any] = [
            "name": name,
            "dietaryRestrictions": [],
            "allergies": [],
            "recentScans": []
        ]
        
        // If a profile image URL is provided and it's not empty, add it to the data.
        if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
            newUserData["profileImageUrl"] = profileImageUrl
        }
        
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

    
    // MARK: - Navigation Methods
    private func navigateToTabBarController() {
        if let windowScene = view.window?.windowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
    
    // Present NameViewController as a pop-up to collect the user's name
    private func presentNameViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nameVC = storyboard.instantiateViewController(withIdentifier: "NameViewController") as? NameViewController {
            nameVC.delegate = self
            nameVC.modalPresentationStyle = .pageSheet
            nameVC.isModalInPresentation = true  // Prevents swipe-to-dismiss
            
  
            let customDetent = UISheetPresentationController.Detent.custom { context in
                   return 300 // Replace with your desired height
               }
            
            if let sheet = nameVC.sheetPresentationController {
                // Choose a detent that fits your design, e.g., .medium()
                sheet.detents = [customDetent]
                sheet.preferredCornerRadius = 16  // Optional, for a rounded look
            }
            
            present(nameVC, animated: true, completion: nil)
        }
    }


    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    @IBAction func ContinueAsGuest(_ sender: Any) {
           self.navigateToTabBarController()
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
                        // User document does not exist, create a new one.
                        // Pass in the profile image URL from Google if available.
                        let profileImageUrl = user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
                        self.createNewUser(
                            uid: authResult?.user.uid ?? "",
                            name: user.profile?.name ?? "",
                            profileImageUrl: profileImageUrl
                        )
                    } else {
                        // User data exists, proceed
                        _ = Users(
                            name: userData["name"] as? String ?? "",
                            dietaryRestrictions: userData["dietaryRestrictions"] as? [String] ?? [],
                            allergies: userData["allergies"] as? [String] ?? [],
                            recentScans: userData["recentScans"] as? [String] ?? []
                        )
                        self.navigateToTabBarController()
                    }
                }
            }
        }
    }
}

// MARK: - NameViewControllerDelegate
extension LoginViewController: NameViewControllerDelegate {
    func didEnterName(_ name: String) {
        // Once the user enters their name, create a new user document in Firestore
        guard let uid = self.currentUserUID else {
            print("User UID not available!")
            return
        }
        createNewUser(uid: uid, name: name)
    }
}
