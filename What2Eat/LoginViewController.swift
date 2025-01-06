import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

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
                self.navigateToTabBarController()
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
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self){
            signInResult, error in if let error = error {
                print("Error Signing In: \(error.localizedDescription)")
                return
            }
            guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
                print("No user found")
                return
            }
            
            let crendentail = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: crendentail) { authResult , error in
                if let error = error {
                    print("Error Signing In: \(error.localizedDescription)")
                    return
                    
                }
                print("User signed in successfully")
                self.navigateToTabBarController()
                
            }
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

    @IBAction func ContinueAsGuest(_ sender: Any) {
        self.navigateToTabBarController()
    }
}
