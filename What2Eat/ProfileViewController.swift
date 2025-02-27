import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage

// A simple image cache using NSCache
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // Table view options
    let options = ["Edit Health Info"]
    let icons = ["square.and.pencil"]
    
    // Outlets for UI elements
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editProfileButton: UIButton!
    
    // Flag for editing mode
    var isEditingProfile = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchUserProfile()
        setupProfileImageView()
        configureNameTextField()
        
        tableview.delegate = self
        tableview.dataSource = self
        userNameTextField.delegate = self
        
        // Add navigation bar edit button to toggle editing mode
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(editButtonTapped))
        // Start in non-editing mode
        setEditingMode(false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Auth.auth().currentUser != nil {
            fetchUserProfile()
            signOutButton.setTitle("Sign Out", for: .normal)
        } else {
            userNameTextField.text = "Guest"
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray
            signOutButton.setTitle("Sign In", for: .normal)
        }
    }
    
    // MARK: - UI Setup Methods
    
    func configureUI() {
        view.backgroundColor = .systemBackground
        signOutButton.layer.cornerRadius = 8
        signOutButton.clipsToBounds = true
    }
    
    func configureNameTextField() {
        userNameTextField.textAlignment = .center
        userNameTextField.placeholder = "Enter your name"
        userNameTextField.layer.cornerRadius = 8
        userNameTextField.clipsToBounds = true
        userNameTextField.layer.borderWidth = 1
        
        // Add left padding
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 40))
        userNameTextField.leftView = leftPadding
        userNameTextField.leftViewMode = .always
        
        // Create a pencil icon for the right view
        let pencilIcon = UIImageView(image: UIImage(systemName: "pencil"))
        pencilIcon.tintColor = .systemOrange
        pencilIcon.contentMode = .scaleAspectFit
        pencilIcon.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
        userNameTextField.rightView = pencilIcon
        // Initially hide the icon
        userNameTextField.rightViewMode = .never
    }
    
    func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.clipsToBounds = true
        
        // Disable interaction unless in edit mode
        profileImageView.isUserInteractionEnabled = false
    }
    
    /// Toggle editing mode and update UI accordingly
    func setEditingMode(_ editing: Bool) {
        isEditingProfile = editing
        
        // Allow name editing and change background color to indicate mode
        userNameTextField.isUserInteractionEnabled = editing
        userNameTextField.layer.borderColor = UIColor.white.cgColor
        userNameTextField.layer.backgroundColor = editing ? UIColor.systemGray5.cgColor : UIColor.white.cgColor
        
        // Show/hide the pencil icon
        userNameTextField.rightViewMode = editing ? .always : .never
        
        // Show/hide the edit profile button for image selection
        editProfileButton.isHidden = !editing
        
        // Enable tap on the image if in editing mode
        profileImageView.isUserInteractionEnabled = editing
    }
    
    @objc func editButtonTapped() {
        if isEditingProfile {
            // Leaving edit mode – save changes if necessary
            setEditingMode(false)
            navigationItem.rightBarButtonItem?.title = "Edit"
            if let newName = userNameTextField.text, !newName.isEmpty {
                updateUserName(newName)
            }
        } else {
            // Enter editing mode
            setEditingMode(true)
            navigationItem.rightBarButtonItem?.title = "Done"
        }
    }
    
    // MARK: - Fetch and Update User Profile
    
    func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let fullName = data?["name"] as? String ?? "Guest"
                let profileImageUrl = data?["profileImageUrl"] as? String ?? ""
                DispatchQueue.main.async {
                    self.userNameTextField.text = fullName
                    if !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                        // SDWebImage handles caching automatically
                        self.profileImageView.sd_setImage(with: url,
                                                          placeholderImage: UIImage(systemName: "person.circle.fill"))
                    } else {
                        self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                        self.profileImageView.tintColor = .systemGray
                    }
                }
            } else {
                print("Error fetching document: \(error?.localizedDescription ?? "No error")")
            }
        }
    }
    
    func updateUserName(_ name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(["name": name]) { error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
            } else {
                print("Name updated successfully.")
            }
        }
    }
    
    // MARK: - Profile Image Editing
    
    @IBAction func editProfileButtonTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    // UIImagePickerController Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        // Get the chosen image (edited if available)
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
        
        // Immediately update the UI
        profileImageView.image = selectedImage
        
        // Cache the image for consistency
        ImageCache.shared.setObject(selectedImage, forKey: "profileImage")
        
        // Upload the new profile image to Firebase Storage
        uploadProfileImage(selectedImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func uploadProfileImage(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        
        storageRef.putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching download URL: \(error.localizedDescription)")
                    return
                }
                
                if let imageUrl = url?.absoluteString {
                    self.updateUserProfileImage(imageUrl)
                }
            }
        }
    }
    
    func updateUserProfileImage(_ imageUrl: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(["profileImageUrl": imageUrl]) { error in
            if let error = error {
                print("Error updating profile image URL: \(error.localizedDescription)")
            } else {
                print("Profile image updated successfully.")
            }
        }
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell",
                                                 for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textColor = .black
        cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        cell.imageView?.tintColor = .gray
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if Auth.auth().currentUser != nil {
                performSegue(withIdentifier: "EditHealthInfo", sender: self)
            } else {
                let alert = UIAlertController(title: "Sign In Required",
                                              message: "You need to be signed in to edit your health info.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .default,
                                              handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UITextField Delegate Methods
    
    // Limit user name to 15 characters
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let currentText = userNameTextField.text ?? ""
        guard let textRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        return updatedText.count <= 15
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if isEditingProfile, let newName = textField.text, !newName.isEmpty {
            updateUserName(newName)
        }
    }
    
    // MARK: - Sign Out Methods
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "currentUser")
            signOutButton.setTitle("Sign In", for: .normal)
            userNameTextField.text = "Guest"
            // Optional: Notify other screens (like HomeVC) if needed
            if let homeVC = self.navigationController?.viewControllers.first(where: { $0 is HomeViewController }) as? HomeViewController {
                homeVC.updateUserName()
            }
        } catch let error as NSError {
            print("Error signing out: \(error.localizedDescription)")
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
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            // User is signed in, so sign them out.
            signOut()
        } else {
            // User is not signed in, so present the login screen.
            presentLoginScreen()
        }
    }
}
