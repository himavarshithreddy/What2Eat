import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseStorage
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
        
        verificationCodeTextField.isHidden = true
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
    }
    
    // MARK: - Actions
    @IBAction func sendCodeButtonTapped(_ sender: Any) {
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
                
                self.verificationID = verificationID
                self.verificationCodeTextField.isHidden = false
                self.sendCodeButton.setTitle("Verify Code", for: .normal)
            }
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
                if let uid = authResult?.user.uid {
                    self.handleUserAuthentication(uid: uid, googleName: user.profile?.name, googleImageUrl: user.profile?.imageURL(withDimension: 200)?.absoluteString)
                }
            }
        }
    }
    
    @IBAction func continueAsGuest(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        navigateToTabBarController()
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
                completion(nil) // No user data found
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
             "iconName": "heart.fill", // Use a default SF Symbol icon (or your own)
             "products": []  // Initially empty
         ]
        if let googleImageUrl = googleImageUrl, let url = URL(string: googleImageUrl) {
            // Download Google profile image
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("Failed to get image data")
                    return
                }
                
                // Upload image to Firebase Storage
                storageRef.putData(data, metadata: nil) { _, error in
                    if let error = error {
                        print("Error uploading image: \(error.localizedDescription)")
                        return
                    }
                    
                    // Get download URL
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
                        
                        // Save user data to Firestore
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
                                        print("Error encoding new user for UserDefaults: \(error.localizedDescription)")
                                    }
                            print("New user created successfully")
                            self.navigateToProfileSetupViewController()
                        }
                    }
                }
            }.resume()
        } else {
            // If user is not using Google, create a new user with an empty profileImageUrl
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
                "savedLists": [defaultList]// No profile picture for non-Google sign-ins
            ]
            
            db.collection("users").document(uid).setData(newUserData) { error in
                if let error = error {
                    print("Error creating new user: \(error.localizedDescription)")
                    return
                }
                print("New user created successfully")
                do {
                            let encoder = JSONEncoder()
                            let encodedData = try encoder.encode(newUser)
                            UserDefaults.standard.set(encodedData, forKey: "currentUser")
                        } catch {
                            print("Error encoding new user for UserDefaults: \(error.localizedDescription)")
                        }
                
                self.navigateToProfileSetupViewController()
            }
        }
    }

    // MARK: - Navigation Methods
    private func handleUserAuthentication(uid: String, googleName: String? = nil, googleImageUrl: String? = nil) {
        fetchUserData(uid: uid) { user in
            if let user = user {
                // Save to UserDefaults for returning users
                do {
                    let encoder = JSONEncoder()
                    let userData = try encoder.encode(user)
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                } catch {
                    print("Error encoding user to UserDefaults: \(error.localizedDescription)")
                }
                
                // Check if profile is complete
                print(user)
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
            navigationController.navigationBar.isHidden = true // Optional: hide nav bar
            window.rootViewController = navigationController
            
            window.makeKeyAndVisible()
        }
       
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
