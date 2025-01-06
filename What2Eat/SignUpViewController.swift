import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    @IBOutlet var nameTextField: UITextField!
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
    
    @IBAction func SignUpbuttonTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        // Show the activity indicator (loading)
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false // Disable user interaction to prevent further taps
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            // Hide the activity indicator
           
            self.view.isUserInteractionEnabled = true // Re-enable user interaction

            if let error = error {
                // Show error in alert box
                self.showAlert(message: "Sign-up error: \(error.localizedDescription)")
                return
            }
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true

            guard let user = authResult?.user else { return }
            let changeRequest = user.createProfileChangeRequest()
            self.activityIndicator.startAnimating()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
              

                if let error = error {
                    // Show error in alert box
                    self.showAlert(message: "Profile update error: \(error.localizedDescription)")
                    return
                }
                self.activityIndicator.stopAnimating()
                self.navigateToTabBarController()
                print("User registered with name: \(user.displayName ?? "No name")")
                
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
