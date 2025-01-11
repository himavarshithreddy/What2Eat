import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    // Declare the activity indicator
    var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { fatalError("Google client ID not found") }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        // Initialize the activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        // Show the activity indicator (loading)
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false // Disable user interaction to prevent further taps
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            // Hide the activity indicator
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true // Re-enable user interaction
            
            if let error = error {
                // Show error in alert box
                self.showAlert(message: "Login error: \(error.localizedDescription)")
                return
            }
            
            // If login is successful, navigate to the Tab Bar Controller
            if let user = authResult?.user {
                print("User logged in: \(user.email ?? "No email")")
                self.fetchUserData(uid: user.uid) { userData in
                    // Map the fetched data to the User model
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

    func resetPassword(forEmail email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                // Handle error
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            // Inform the user that the reset email has been sent
            let alert = UIAlertController(title: "Success", message: "Password reset email sent.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    @IBAction func resetPasswordButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            // Handle empty email field
            let alert = UIAlertController(title: "Error", message: "Please enter your email address.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        resetPassword(forEmail: email)
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
