import UIKit
import SDWebImage
import Firebase
import FirebaseAuth
import FirebaseStorage

class EditProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    // Loading indicator for image upload
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // Edit icon container with visual enhancements
    private let editIconContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .systemOrange
        container.layer.cornerRadius = 15
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.white.cgColor
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.2
        container.isUserInteractionEnabled = true
        return container
    }()
    
    // Camera icon for editing profile picture
    private let editIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "square.and.pencil")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var profileItems: [(title: String, value: String)] = [
        ("Name", "N/A"),
        ("Gender", "N/A"),
        ("Age", "N/A"),
        ("Height", "N/A"),
        ("Weight", "N/A"),
        ("Activity Level", "N/A")
    ]
    
    var userProfileData = UserProfileData()
    private var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Profile"
        tableView.delegate = self
        tableView.dataSource = self
        
        // Set up image picker
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        // Make edit icon container tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        editIconContainer.addGestureRecognizer(tapGesture)
        
        // Set up the edit icon
        setupEditIconConstraints()
        
        // Set up loading indicator
        setupLoadingIndicator()
        
        print("EditProfileViewController did load.")
        loadUserProfileImage()
        loadUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("EditProfileViewController will appear. Reloading user profile data...")
        loadUserProfile()
        tableView.reloadData()
    }
    
    private func setupEditIconConstraints() {
        // Add the container to the view
        view.addSubview(editIconContainer)
        
        // Add the icon to the container
        editIconContainer.addSubview(editIconImageView)
        
        NSLayoutConstraint.activate([
            // Container constraints
            editIconContainer.widthAnchor.constraint(equalToConstant: 30),
            editIconContainer.heightAnchor.constraint(equalToConstant: 30),
            editIconContainer.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 0),
            editIconContainer.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 0),
            
            // Icon constraints inside container
            editIconImageView.centerXAnchor.constraint(equalTo: editIconContainer.centerXAnchor),
            editIconImageView.centerYAnchor.constraint(equalTo: editIconContainer.centerYAnchor),
            editIconImageView.widthAnchor.constraint(equalToConstant: 16),
            editIconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func setupLoadingIndicator() {
        profileImageView.addSubview(loadingIndicator)
        profileImageView.layoutIfNeeded()
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])
    }
    
    private func showLoadingIndicator() {
        // Add semi-transparent overlay to indicate loading state
        profileImageView.alpha = 0.7
        editIconContainer.isUserInteractionEnabled = false
        loadingIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.profileImageView.alpha = 1.0
            self.editIconContainer.isUserInteractionEnabled = true
            self.loadingIndicator.stopAnimating()
        }
    }
    
    private func loadUserProfile() {
        print("Attempting to load user profile from UserDefaults with key 'currentUser'")
        if let encodedUser = UserDefaults.standard.data(forKey: "currentUser") {
            print("Found encoded user data in UserDefaults: \(encodedUser)")
            do {
                let user = try JSONDecoder().decode(Users.self, from: encodedUser)
                print("Successfully decoded user: \(user)")
                
                let feet = user.height / 30.48
                let heightString = String(format: "%.1f ft", feet)
                
                profileItems = [
                    ("Name", user.name),
                    ("Gender", user.gender.capitalized),
                    ("Age", "\(user.age) yr"),
                    ("Height", heightString),
                    ("Weight", "\(user.weight) kg"),
                    ("Activity Level", user.activityLevel)
                ]
                
                userProfileData.name = user.name
                userProfileData.gender = user.gender.capitalized
                userProfileData.age = user.age
                userProfileData.height = user.height
                userProfileData.weight = user.weight
                userProfileData.activityLevel = user.activityLevel
                
                print("Updated profileItems: \(profileItems)")
                tableView.reloadData()
            } catch {
                print("Error decoding user from UserDefaults: \(error)")
            }
        } else {
            print("No saved user data found in UserDefaults with key 'currentUser'.")
        }
    }
    
    private func loadUserProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return
        }
        
        if let cachedProfileImageUrl = UserDefaults.standard.string(forKey: "cachedProfileImageUrl_\(userId)"),
           let url = URL(string: cachedProfileImageUrl) {
            print("Loading cached profile image from URL: \(cachedProfileImageUrl)")
            profileImageView.sd_setImage(with: url, placeholderImage: nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("No profile document found.")
                return
            }
            
            let data = document.data() ?? [:]
            if let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty,
               let url = URL(string: profileImageUrl) {
                print("Profile image found, loading from URL: \(profileImageUrl)")
                UserDefaults.standard.set(profileImageUrl, forKey: "cachedProfileImageUrl_\(userId)")
                self.profileImageView.sd_setImage(with: url, placeholderImage: nil)
            } else {
                print("No profile image found, setting initials.")
                self.setInitialProfileImage(with: self.userProfileData.name)
            }
        }
    }
    
    private func setInitialProfileImage(with name: String) {
        let initial = name.first.map { String($0) } ?? "U"
        let size = profileImageView.frame.size
        let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white)
        profileImageView.image = image
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.masksToBounds = true
        profileImageView.layoutIfNeeded()

            // Update loading indicator constraints (if needed)
            loadingIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
            loadingIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
    }
    
    // Animate edit icon when tapped for visual feedback
    private func animateEditIconTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.editIconContainer.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.editIconContainer.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.editIconContainer.transform = .identity
                self.editIconContainer.alpha = 1.0
            }
        }
    }
    
    @objc private func profileImageTapped() {
        print("Profile image edit icon tapped, presenting image picker.")
        animateEditIconTap()
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data.")
            return
        }
        
        // Show loading indicator
        showLoadingIndicator()
        
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists,
               let oldImageUrl = document.data()?["profileImageUrl"] as? String,
               !oldImageUrl.isEmpty {
                let oldImageRef = Storage.storage().reference(forURL: oldImageUrl)
                oldImageRef.delete { error in
                    if let error = error {
                        print("Error deleting old profile image: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted old profile image from Firebase Storage.")
                    }
                }
            }
            
            print("Uploading new profile image to Firebase Storage...")
            profileImageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading profile image: \(error.localizedDescription)")
                    self.hideLoadingIndicator()
                    return
                }
                
                profileImageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error retrieving download URL: \(error.localizedDescription)")
                        self.hideLoadingIndicator()
                        return
                    }
                    
                    guard let downloadURL = url else {
                        print("Download URL is nil.")
                        self.hideLoadingIndicator()
                        return
                    }
                    
                    print("Profile image uploaded successfully. Download URL: \(downloadURL.absoluteString)")
                    
                    db.collection("users").document(userId).updateData([
                        "profileImageUrl": downloadURL.absoluteString
                    ]) { error in
                        // Hide loading indicator
                        self.hideLoadingIndicator()
                        
                        if let error = error {
                            print("Error updating Firestore with profile image URL: \(error.localizedDescription)")
                        } else {
                            print("Firestore updated with new profile image URL.")
                            UserDefaults.standard.set(downloadURL.absoluteString, forKey: "cachedProfileImageUrl_\(userId)")
                            self.profileImageView.sd_setImage(with: downloadURL, placeholderImage: nil)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            print("User selected and edited an image.")
            uploadProfileImage(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            print("User selected an original image.")
            uploadProfileImage(originalImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Image picker cancelled.")
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension EditProfileViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EditPersonalInfoCell", for: indexPath)
                as? EditPersonalInfoTableViewCell else {
            return UITableViewCell()
        }
        
        let item = profileItems[indexPath.row]
        cell.titleLabel.text = item.title
        cell.valueLabel.text = item.value
        
        cell.accessoryType = .none
        cell.iconImage.image = UIImage(systemName: "square.and.pencil")
        cell.iconImage.tintColor = .systemOrange
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EditProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let tappedItem = profileItems[indexPath.row]
        print("Tapped on item: \(tappedItem.title) with value: \(tappedItem.value)")
        switch tappedItem.title {
        case "Name", "Gender":
            let nextVC = NameGenderViewController(profileData: userProfileData, isEditingProfile: true)
            nextVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(nextVC, animated: true)
            
        case "Age":
            let nextVC = AgeViewController(profileData: userProfileData, isEditingProfile: true)
            nextVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(nextVC, animated: true)
                
        case "Height":
            let nextVC = HeightViewController(profileData: userProfileData, isEditingProfile: true)
            nextVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(nextVC, animated: true)
                
        case "Weight":
            let nextVC = WeightViewController(profileData: userProfileData, isEditingProfile: true)
            nextVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(nextVC, animated: true)
                
        case "Activity Level":
            let nextVC = ActivityLevelViewController(profileData: userProfileData, isEditingProfile: true)
            nextVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(nextVC, animated: true)
                
        default:
            print("Tapped on \(tappedItem.title), but no navigation is set for this item.")
        }
    }
}
