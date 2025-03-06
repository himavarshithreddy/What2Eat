import UIKit
import SDWebImage
import Firebase
import FirebaseAuth

class EditProfileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    // We'll update this array after fetching the local saved user data.
    var profileItems: [(title: String, value: String)] = [
        ("Name", "N/A"),
        ("Gender", "N/A"),
        ("Age", "N/A"),
        ("Height", "N/A"),
        ("Weight", "N/A"),
        ("Activity Level", "N/A")
    ]
    
    // This holds data to pass to the other controllers
    var userProfileData = UserProfileData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit Profile"
        
        tableView.delegate = self
        tableView.dataSource = self
        loadUserProfileImage()
        // Load user data from local storage (UserDefaults) and update UI
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        if let encodedUser = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                let user = try JSONDecoder().decode(Users.self, from: encodedUser)
                
                // Convert height from cm to feet (if desired)
                let feet = user.height / 30.48
                let heightString = String(format: "%.1f ft", feet)
                
                // Update table view data source
                profileItems = [
                    ("Name", user.name),
                    ("Gender", user.gender),
                    ("Age", "\(user.age) yr"),
                    ("Height", heightString),
                    ("Weight", "\(user.weight) kg"),
                    ("Activity Level", user.activityLevel)
                ]
                
                // Update userProfileData
                userProfileData.name = user.name
                userProfileData.gender = user.gender
                userProfileData.age = user.age
                userProfileData.height = user.height
                userProfileData.weight = user.weight
                userProfileData.activityLevel = user.activityLevel
                
                tableView.reloadData()
              
                
            } catch {
                print("Error decoding user: \(error)")
            }
        } else {
            print("No saved user data found in UserDefaults.")
        }
    }
    
  

    private func loadUserProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return
        }

        // First, check cache
        if let cachedProfileImageUrl = UserDefaults.standard.string(forKey: "cachedProfileImageUrl_\(userId)"),
           let url = URL(string: cachedProfileImageUrl) {
            print("Loading cached profile image from URL: \(cachedProfileImageUrl)")
            profileImageView.sd_setImage(with: url, placeholderImage: nil)
            return
        }

        // Fetch from Firestore
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
        let initial = name.first.map { String($0) } ?? "U" // Default to "U"
        let size = profileImageView.frame.size
        let image = UIImage.imageWithInitial(initial, size: size, backgroundColor: .systemGray, textColor: .white)
        profileImageView.image = image
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.masksToBounds = true
      
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
        
        // Remove any disclosure indicator
        cell.accessoryType = .none
        
        // Show the same edit icon
        cell.iconImage.image = UIImage(systemName: "square.and.pencil")
        cell.iconImage.tintColor = .gray
        
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
            print("Tapped on \(tappedItem.title), but no navigation set.")
        }
    }
    

}
