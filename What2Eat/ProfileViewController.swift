import UIKit
import FirebaseAuth
import Firebase

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let options = ["Edit Health Info"]
    let icons = ["square.and.pencil"]
    
    @IBOutlet var SignOutButton: UIButton!
    @IBOutlet var UserName: UILabel!
    @IBOutlet weak var tableview: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self
        updateUserName()
        
    }
    func updateUserName() {
           guard let userId = Auth.auth().currentUser?.uid else {
               UserName.text = "Guest"
               SignOutButton.setTitle("Sign In", for: .normal)
               return
           }

           let db = Firestore.firestore()
           let userRef = db.collection("users").document(userId)
           
           userRef.getDocument { (document, error) in
               if let error = error {
                   print("Error fetching user document: \(error.localizedDescription)")
                   self.UserName.text = "Guest"
                   return
               }
               
               if let document = document, document.exists, let fullName = document.data()?["name"] as? String {
                   let firstName = fullName.components(separatedBy: " ").first ?? fullName
                   self.UserName.text = "Hi, \(firstName)"
                   self.SignOutButton.setTitle("Sign Out", for: .normal)
               } else {
                   self.UserName.text = "Guest"
                   self.SignOutButton.setTitle("Sign In", for: .normal)
               }
           }
       }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textColor = UIColor.black
        cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        cell.imageView?.tintColor = UIColor.gray
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let user = Auth.auth().currentUser {
                        // Proceed to the Edit Health Info screen if the user is signed in
                        performSegue(withIdentifier: "EditHealthInfo", sender: self)
                    } else {
                        // Show an alert if the user is not signed in
                        let alert = UIAlertController(title: "Sign In Required", message: "You need to be signed in to edit your health info.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        present(alert, animated: true, completion: nil)
                    }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            SignOutButton.setTitle("Sign In", for: .normal)
            UserName.text = "Guest"
            
            // Optional: Notify other screens (like HomeVC) if needed
            if let homeVC = self.navigationController?.viewControllers.first(where: { $0 is HomeViewController }) as? HomeViewController {
                homeVC.updateUserName()
            }
        } catch let error as NSError {
            print("Error signing out: %@", error.localizedDescription)
        }
    }

    @IBAction func SignOutButtonTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            signOut()  // Sign out the user if they are signed in
        } else {
            // If user is not signed in, present the login screen modally
            presentLoginScreen()
        }
    }

    func presentLoginScreen() {
        // Fade out the current view before transitioning
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0
        }) { _ in
            // After the fade-out animation completes, transition to the login screen
            if let windowScene = self.view.window?.windowScene {
                if let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    if let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                        // Set the LoginViewController as the root view controller
                        window.rootViewController = loginViewController
                        window.makeKeyAndVisible()
                        
                        // Fade in the login screen after it's set as the root view controller
                        UIView.animate(withDuration: 0.5, animations: {
                            self.view.alpha = 1
                        })
                    }
                }
            }
        }
    }
}
