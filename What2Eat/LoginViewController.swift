import UIKit
import FirebaseAuth
class LoginViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    // Declare the activity indicator
    var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
}
