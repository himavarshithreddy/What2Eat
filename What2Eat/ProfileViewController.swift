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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupTableView()
        setupProfileListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupProfileListener() // Use real-time listener for updates
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        profileListener?.remove() // Stop listening when leaving the view
    }

    deinit {
        profileListener?.remove() // Clean up listener
    }

    // MARK: - UI Setup Methods

    func configureUI() {
        view.backgroundColor = .systemBackground
        signOutButton.layer.cornerRadius = 8
        signOutButton.clipsToBounds = true

        // Profile Image Styling
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.clipsToBounds = true
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")
    }

    // MARK: - Profile Listener and Caching

    private var profileListener: ListenerRegistration?

    private func setupProfileListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            updateProfileAsGuest()
            return
        }

        // Try to load cached data first
        if let cachedName = UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
            let firstName = cachedName.components(separatedBy: " ").first ?? cachedName
            userNameLabel.text = firstName
            updateProfileImageFromCache(userId: userId)
        } else {
            userNameLabel.text = "User"
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        profileListener = userRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error listening to profile updates: \(error.localizedDescription)")
                self.updateProfileFromCache(userId: userId)
                return
            }

            guard let document = document, document.exists else {
                print("User document does not exist")
                self.updateProfileAsGuest()
                return
            }

            let data = document.data() ?? [:]
            if let fullName = data["name"] as? String, let profileImageUrl = data["profileImageUrl"] as? String {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                DispatchQueue.main.async {
                    self.userNameLabel.text = firstName
                }
                // Cache the data
                UserDefaults.standard.set(fullName, forKey: "cachedUserName_\(userId)")
                UserDefaults.standard.set(profileImageUrl, forKey: "cachedProfileImageUrl_\(userId)")

                // Update profile image
                if !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                    SDWebImageManager.shared.loadImage(with: url, options: [.refreshCached], progress: nil) { (image, _, error, _, _, _) in
                        if let image = image {
                            let size = CGSize(width: self.profileImageView.frame.width, height: self.profileImageView.frame.height)
                            let circularImage = image.circularImage(size: size)
                            DispatchQueue.main.async {
                                self.profileImageView.image = circularImage
                            }
                        } else {
                            self.setInitialImage(from: data)
                        }
                    }
                } else {
                    self.setInitialImage(from: data)
                }
            }
        }
    }

    private func updateProfileFromCache(userId: String) {
        if let cachedName = UserDefaults.standard.string(forKey: "cachedUserName_\(userId)") {
            let firstName = cachedName.components(separatedBy: " ").first ?? cachedName
            userNameLabel.text = firstName
        } else {
            userNameLabel.text = "User"
        }
        updateProfileImageFromCache(userId: userId)
    }

    private func updateProfileImageFromCache(userId: String) {
        if let cachedProfileImageUrl = UserDefaults.standard.string(forKey: "cachedProfileImageUrl_\(userId)"),
           let url = URL(string: cachedProfileImageUrl) {
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { (image, _, _, _, _, _) in
                if let image = image {
                    let size = CGSize(width: self.profileImageView.frame.width, height: self.profileImageView.frame.height)
                    let circularImage = image.circularImage(size: size)
                    DispatchQueue.main.async {
                        self.profileImageView.image = circularImage
                    }
                } else {
                    self.updateProfileAsGuest()
                }
            }
        } else {
            updateProfileAsGuest()
        }
    }

    private func updateProfileAsGuest() {
        userNameLabel.text = "Guest"
        let initial = "G"
        let size = CGSize(width: profileImageView.frame.width, height: profileImageView.frame.height)
        if let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white) {
            profileImageView.image = image
        }
    }

    private func setInitialImage(from data: [String: Any]) {
        var initial = "G"
        if let fullName = data["name"] as? String, !fullName.isEmpty {
            initial = String(fullName.prefix(1))
        }
        let size = CGSize(width: profileImageView.frame.width, height: profileImageView.frame.height)
        if let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white) {
            profileImageView.image = image
        }
    }

    // MARK: - UITableView DataSource & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textColor = .black
        cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        cell.imageView?.tintColor = .gray
        cell.accessoryType = .disclosureIndicator // Arrow for navigation
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if Auth.auth().currentUser == nil && indexPath.row == 0 {
            let alert = UIAlertController(title: "Sign In Required",
                                          message: "You need to be signed in to edit your health info.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        switch indexPath.row {
        case 0: // Edit Health Info
            performSegue(withIdentifier: "EditHealthInfo", sender: nil)
        case 1: // Edit Personal Info
            performSegue(withIdentifier: "EditPersonalInfo", sender: nil)
        case 2: // Scoring Methodology
            performSegue(withIdentifier: "ScoringMethodology", sender: nil)
        default:
            break
        }
    }

    // MARK: - Sign Out Methods

    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                UserDefaults.standard.removeObject(forKey: "currentUser")
                signOutButton.setTitle("Sign In", for: .normal)
                updateProfileAsGuest()
            } catch let error as NSError {
                print("Error signing out: \(error.localizedDescription)")
            }
        } else {
            // Present login screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? UIViewController {
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = .fade
                view.window?.layer.add(transition, forKey: kCATransition)
                view.window?.rootViewController = loginVC
                view.window?.makeKeyAndVisible()
            }
        }
    }
}
