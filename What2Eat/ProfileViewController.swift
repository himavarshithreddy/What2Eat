import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import SDWebImage

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // Table view options and icons
    let options = ["Edit Health Info", "Edit Personal Info", "Scoring Methodology", "Privacy Policy", "Terms & Conditions"]
    let icons = ["square.and.pencil", "person.crop.circle.badge", "questionmark.circle", "lock.shield", "doc.text"]

    // Outlets for UI elements
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
      
        configureUI()
        setupTableView()
        setupProfileListener()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        setupProfileListener() // Use real-time listener for updates
        tableView.reloadData()
        let defaults = UserDefaults.standard
        let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String]
        let localAllergens = defaults.object(forKey: "localAllergies") as? [String]
        print(localRestrictions)
        print(localAllergens)
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
        print("ProfileViewController: Current user ID: \(userId)")

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
            guard let self = self else {
              
                return
            }

            if let error = error {
               
                self.updateProfileFromCache(userId: userId)
                return
            }

            guard let document = document, document.exists else {
               
                self.updateProfileAsGuest()
                return
            }

            let data = document.data() ?? [:]
       
        

            // Update name if available
            if let fullName = data["name"] as? String {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
             
                DispatchQueue.main.async {
                  
                    self.userNameLabel.text = firstName
                }
                // Cache the name
                UserDefaults.standard.set(fullName, forKey: "cachedUserName_\(userId)")
            } else {
                print("ProfileViewController: No name in Firestore data, keeping cached or default name")
            }

            // Update profile image if URL is available
            if let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
             
                UserDefaults.standard.set(profileImageUrl, forKey: "cachedProfileImageUrl_\(userId)")
                SDWebImageManager.shared.loadImage(with: url, options: [.refreshCached], progress: nil) { (image, _, error, _, _, _) in
                    if let error = error {
                       
                        self.setInitialImage(from: data)
                        return
                    }
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
              
                UserDefaults.standard.removeObject(forKey: "cachedProfileImageUrl_\(userId)")
                self.setInitialImage(from: data)
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
                    
                    self.setInitialImage(from: [:])
                }
            }
        } else {
           
            self.setInitialImage(from: [:])
        }
    }

    private func updateProfileAsGuest() {
   
        userNameLabel.text = "Guest"
        let initial = "G"
        let size = CGSize(width: profileImageView.frame.width, height: profileImageView.frame.height)
       
        if let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white) {
            profileImageView.image = image
        
        } else {
            print("ProfileViewController: Failed to create guest initial image")
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
           
        } else {
            print("ProfileViewController: Failed to create initial image")
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
        case 3: // Privacy Policy
            openLegalPage(type: "privacy")
        case 4: // Terms & Conditions
            openLegalPage(type: "terms")
        default:
            print("ProfileViewController: Unknown row selected: \(indexPath.row)")
            break
        }
    }

    // MARK: - Sign Out Methods

    @IBAction func signOutButtonTapped(_ sender: UIButton) {
            if Auth.auth().currentUser != nil {
                do {
                    try Auth.auth().signOut()
                    // Clear cached user data if needed
                    let defaults = UserDefaults.standard
                    if let domain = Bundle.main.bundleIdentifier {
                        defaults.removePersistentDomain(forName: domain)
                    }
                    defaults.synchronize()
                    
                    // Instantiate and navigate to LoginViewController
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? UIViewController {
                        let transition = CATransition()
                        transition.duration = 0.5
                        transition.type = .fade
                        view.window?.layer.add(transition, forKey: kCATransition)
                        view.window?.rootViewController = loginVC
                        view.window?.makeKeyAndVisible()
                    } else {
                        print("ProfileViewController: Failed to instantiate LoginViewController")
                    }
                } catch let error as NSError {
                    print("ProfileViewController: Error signing out: \(error.localizedDescription)")
                }
            } else {
                // If no user is signed in, present the login screen.
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? UIViewController {
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func openLegalPage(type: String) {
        let legalVC = LegalViewController()
        
        if type == "privacy" {
            legalVC.urlString = "https://what2eat-cb440.web.app/privacy-policy"
            legalVC.title = "Privacy Policy"
        } else if type == "terms" {
            legalVC.urlString = "https://what2eat-cb440.web.app/terms-conditions"
            legalVC.title = "Terms & Conditions"
        }
        
        navigationController?.pushViewController(legalVC, animated: true)
    }

}
