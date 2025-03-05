import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import SDWebImage

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // Table view options and icons
    let options = ["Edit Health Info", "Edit Personal Info", "Scoring Methodology"]
    let icons = ["square.and.pencil", "person.crop.circle.badge", "questionmark.circle"]

    // Outlets for UI elements
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ProfileViewController: viewDidLoad called")
        configureUI()
        setupTableView()
        setupProfileListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ProfileViewController: viewWillAppear called")
        setupProfileListener() // Use real-time listener for updates
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("ProfileViewController: viewWillDisappear called")
        profileListener?.remove() // Stop listening when leaving the view
    }

    deinit {
        print("ProfileViewController: deinit called")
        profileListener?.remove() // Clean up listener
    }

    // MARK: - UI Setup Methods

    func configureUI() {
        print("ProfileViewController: Configuring UI")
        view.backgroundColor = .systemBackground
        signOutButton.layer.cornerRadius = 8
        signOutButton.clipsToBounds = true

        // Profile Image Styling
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.clipsToBounds = true
        print("ProfileViewController: profileImageView frame: \(profileImageView.frame)")
    }

    func setupTableView() {
        print("ProfileViewController: Setting up table view")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")
    }

    // MARK: - Profile Listener and Caching

    private var profileListener: ListenerRegistration?

    private func setupProfileListener() {
        print("ProfileViewController: Setting up profile listener")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("ProfileViewController: No authenticated user found, updating as guest")
            updateProfileAsGuest()
            return
        }
        print("ProfileViewController: Current user ID: \(userId)")

        // Try to load cached data first
        if let cachedName = UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
            let firstName = cachedName.components(separatedBy: " ").first ?? cachedName
            print("ProfileViewController: Using cached name: \(firstName)")
            userNameLabel.text = firstName
            updateProfileImageFromCache(userId: userId)
        } else {
            print("ProfileViewController: No cached name found, defaulting to 'User'")
            userNameLabel.text = "User"
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        profileListener = userRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else {
                print("ProfileViewController: Weak self is nil, listener callback aborted")
                return
            }

            if let error = error {
                print("ProfileViewController: Error listening to profile updates: \(error.localizedDescription)")
                self.updateProfileFromCache(userId: userId)
                return
            }

            guard let document = document, document.exists else {
                print("ProfileViewController: User document does not exist for userId: \(userId)")
                self.updateProfileAsGuest()
                return
            }

            let data = document.data() ?? [:]
            print("ProfileViewController: Fetched user data: \(data)")

            // Update name if available
            if let fullName = data["name"] as? String {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                print("ProfileViewController: Updating name to: \(firstName)")
                DispatchQueue.main.async {
                    print("ProfileViewController: Setting userNameLabel to: \(firstName)")
                    self.userNameLabel.text = firstName
                }
                // Cache the name
                UserDefaults.standard.set(fullName, forKey: "cachedUserName_\(userId)")
            } else {
                print("ProfileViewController: No name in Firestore data, keeping cached or default name")
            }

            // Update profile image if URL is available
            if let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                print("ProfileViewController: Loading profile image from URL: \(profileImageUrl)")
                UserDefaults.standard.set(profileImageUrl, forKey: "cachedProfileImageUrl_\(userId)")
                SDWebImageManager.shared.loadImage(with: url, options: [.refreshCached], progress: nil) { (image, _, error, _, _, _) in
                    if let error = error {
                        print("ProfileViewController: Error loading profile image: \(error.localizedDescription)")
                        self.setInitialImage(from: data)
                        return
                    }
                    if let image = image {
                        print("ProfileViewController: Profile image loaded successfully")
                        let size = CGSize(width: self.profileImageView.frame.width, height: self.profileImageView.frame.height)
                        let circularImage = image.circularImage(size: size)
                        DispatchQueue.main.async {
                            print("ProfileViewController: Setting profileImageView with loaded image")
                            self.profileImageView.image = circularImage
                        }
                    } else {
                        print("ProfileViewController: No image loaded, falling back to initial")
                        self.setInitialImage(from: data)
                    }
                }
            } else {
                print("ProfileViewController: Profile image URL missing or invalid")
                UserDefaults.standard.removeObject(forKey: "cachedProfileImageUrl_\(userId)")
                self.setInitialImage(from: data)
            }
        }
    }

    private func updateProfileFromCache(userId: String) {
        print("ProfileViewController: Updating profile from cache for userId: \(userId)")
        if let cachedName = UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
            let firstName = cachedName.components(separatedBy: " ").first ?? cachedName
            print("ProfileViewController: Using cached name: \(firstName)")
            userNameLabel.text = firstName
        } else {
            print("ProfileViewController: No cached name found, defaulting to 'User'")
            userNameLabel.text = "User"
        }
        updateProfileImageFromCache(userId: userId)
    }

    private func updateProfileImageFromCache(userId: String) {
        print("ProfileViewController: Updating profile image from cache for userId: \(userId)")
        if let cachedProfileImageUrl = UserDefaults.standard.string(forKey: "cachedProfileImageUrl_\(userId)"),
           let url = URL(string: cachedProfileImageUrl) {
            print("ProfileViewController: Loading cached profile image from URL: \(cachedProfileImageUrl)")
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { (image, _, _, _, _, _) in
                if let image = image {
                    print("ProfileViewController: Cached profile image loaded successfully")
                    let size = CGSize(width: self.profileImageView.frame.width, height: self.profileImageView.frame.height)
                    let circularImage = image.circularImage(size: size)
                    DispatchQueue.main.async {
                        print("ProfileViewController: Setting profileImageView with cached image")
                        self.profileImageView.image = circularImage
                    }
                } else {
                    print("ProfileViewController: Failed to load cached profile image, falling back to initial")
                    self.setInitialImage(from: [:])
                }
            }
        } else {
            print("ProfileViewController: No cached profile image URL found, falling back to initial")
            self.setInitialImage(from: [:])
        }
    }

    private func updateProfileAsGuest() {
        print("ProfileViewController: Updating profile as guest")
        userNameLabel.text = "Guest"
        let initial = "G"
        let size = CGSize(width: profileImageView.frame.width, height: profileImageView.frame.height)
        print("ProfileViewController: Creating guest initial image with size: \(size)")
        if let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white) {
            profileImageView.image = image
            print("ProfileViewController: Set guest initial image")
        } else {
            print("ProfileViewController: Failed to create guest initial image")
        }
    }

    private func setInitialImage(from data: [String: Any]) {
        print("ProfileViewController: Setting initial image from data: \(data)")
        var initial = "G"
        if let fullName = data["name"] as? String, !fullName.isEmpty {
            initial = String(fullName.prefix(1))
            print("ProfileViewController: Using initial '\(initial)' from fullName: \(fullName)")
        }
        let size = CGSize(width: profileImageView.frame.width, height: profileImageView.frame.height)
        print("ProfileViewController: Creating initial image with size: \(size)")
        if let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white) {
            profileImageView.image = image
            print("ProfileViewController: Set initial image with initial: \(initial)")
        } else {
            print("ProfileViewController: Failed to create initial image")
        }
    }

    // MARK: - UITableView DataSource & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("ProfileViewController: tableView numberOfRowsInSection called, returning \(options.count)")
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("ProfileViewController: tableView cellForRowAt called for indexPath: \(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textColor = .black
        cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        cell.imageView?.tintColor = .gray
        cell.accessoryType = .disclosureIndicator // Arrow for navigation
        print("ProfileViewController: Configured cell with option: \(options[indexPath.row])")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("ProfileViewController: tableView didSelectRowAt called for indexPath: \(indexPath)")
        tableView.deselectRow(at: indexPath, animated: true)
        
        if Auth.auth().currentUser == nil && indexPath.row == 0 {
            print("ProfileViewController: User not signed in, showing alert for 'Edit Health Info'")
            let alert = UIAlertController(title: "Sign In Required",
                                          message: "You need to be signed in to edit your health info.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        switch indexPath.row {
        case 0: // Edit Health Info
            print("ProfileViewController: Performing segue to EditHealthInfo")
            performSegue(withIdentifier: "EditHealthInfo", sender: nil)
        case 1: // Edit Personal Info
            print("ProfileViewController: Performing segue to EditPersonalInfo")
            performSegue(withIdentifier: "EditPersonalInfo", sender: nil)
        case 2: // Scoring Methodology
            print("ProfileViewController: Performing segue to ScoringMethodology")
            performSegue(withIdentifier: "ScoringMethodology", sender: nil)
        default:
            print("ProfileViewController: Unknown row selected: \(indexPath.row)")
            break
        }
    }

    // MARK: - Sign Out Methods

    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        print("ProfileViewController: signOutButtonTapped called")
        if Auth.auth().currentUser != nil {
            print("ProfileViewController: User is signed in, attempting to sign out")
            do {
                try Auth.auth().signOut()
                print("ProfileViewController: Successfully signed out")
                UserDefaults.standard.removeObject(forKey: "currentUser")
                signOutButton.setTitle("Sign In", for: .normal)
                updateProfileAsGuest()
            } catch let error as NSError {
                print("ProfileViewController: Error signing out: \(error.localizedDescription)")
            }
        } else {
            print("ProfileViewController: No user signed in, presenting login screen")
            // Present login screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? UIViewController {
                print("ProfileViewController: Presenting LoginViewController")
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = .fade
                view.window?.layer.add(transition, forKey: kCATransition)
                view.window?.rootViewController = loginVC
                view.window?.makeKeyAndVisible()
            } else {
                print("ProfileViewController: Failed to instantiate LoginViewController")
            }
        }
    }
}
