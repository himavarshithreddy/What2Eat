import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import SDWebImage

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Table view options and icons
    let options = ["Edit Health Info", "Edit Personal Info", "Scoring Methodology", "Privacy Policy", "Terms & Conditions"]
    @IBOutlet var RDAView: UIView!
    let icons = ["square.and.pencil", "person.crop.circle.badge", "questionmark.circle", "lock.shield", "doc.text"]
    
    // Outlets for UI elements
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var rdaViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var ScreenHeight: NSLayoutConstraint!
    // RDA-specific properties
    private var rdaData: [String: (value: Double, unit: String)] = [:]
    private var isExpanded = false
    private var collectionView: UICollectionView!
    private let mainNutrients = ["energy", "protein", "total fat", "saturated fat", "carbohydrates", "fiber", "sugars", "sodium"]
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setupTableView()
        setupProfileListener()
        setupRDAView()
        fetchRDAData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupProfileListener()
        tableView.reloadData()
        let defaults = UserDefaults.standard
        let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String]
        let localAllergens = defaults.object(forKey: "localAllergies") as? [String]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        profileListener?.remove()
    }
    
    deinit {
        profileListener?.remove()
    }
    
    // MARK: - UI Setup Methods
    
    func configureUI() {
        view.backgroundColor = .systemBackground
        signOutButton.layer.cornerRadius = 8
        signOutButton.clipsToBounds = true
        
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
    
    private func setupRDAView() {
        // Container styling (no border)
        RDAView.backgroundColor = .systemBackground
        
        // Collection view setup
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 8
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(NutrientCell.self, forCellWithReuseIdentifier: "NutrientCell")
        collectionView.register(ToggleCell.self, forCellWithReuseIdentifier: "ToggleCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        RDAView.addSubview(collectionView)
        
        // Constraints
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: RDAView.topAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: RDAView.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: RDAView.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: RDAView.bottomAnchor, constant: -12)
        ])
        
        // Initial height
        rdaViewHeightConstraint.constant = 204
        ScreenHeight.constant = 700// 3 rows × (60 height + 8 spacing) + 12 padding
    }
    
    private func fetchRDAData() {
        fetchAndComputeRDAWithUnits { [weak self] rdaData in
            guard let self = self, let rdaData = rdaData else { return }
            self.rdaData = rdaData
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.updateRDAViewHeight()
            }
        }
    }
    
    private func updateRDAViewHeight() {
        let totalItems = isExpanded ? rdaData.count + 1 : 9
        let rows = (totalItems + 2) / 3 // Ceiling division
        let height = CGFloat(rows) * (60 + 8) - 8 + 24 // Height + spacing + padding
        rdaViewHeightConstraint.constant = height
        ScreenHeight.constant = height + 650
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isExpanded ? rdaData.count + 1 : 9 // 8 nutrients + 1 toggle button
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 8 && !isExpanded {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToggleCell", for: indexPath) as! ToggleCell
            cell.configure(with: "See All", isExpanded: false)
            return cell
        } else if isExpanded && indexPath.item == rdaData.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToggleCell", for: indexPath) as! ToggleCell
            cell.configure(with: "See Less", isExpanded: true)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NutrientCell", for: indexPath) as! NutrientCell
            
            // Determine the nutrient to display
            let nutrient: String
            if isExpanded {
                // Create a list with main nutrients first, followed by others in alphabetical order
                let otherNutrients = rdaData.keys.filter { !mainNutrients.contains($0) }.sorted()
                let allNutrients = mainNutrients + otherNutrients
                nutrient = allNutrients[indexPath.item]
            } else {
                nutrient = mainNutrients[indexPath.item]
            }
            
            if let data = rdaData[nutrient] {
                let displayName = nutrient.lowercased() == "carbohydrates" ? "Carbs" : nutrient.capitalized
                            cell.configure(with: displayName, value: String(format: "%.1f", data.value), unit: data.unit)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Get the screen width
        let screenWidth = view.safeAreaLayoutGuide.layoutFrame.width
        
        // Total padding on both sides of the collection view (12 leading + 12 trailing)
        let totalPadding: CGFloat = 40
        
        // Total spacing between 3 capsules (2 gaps × 8 points)
        let totalSpacing: CGFloat = 12
        
        // Calculate the width for each capsule: (screen width - padding - spacing) / 3
        let width = (screenWidth - totalPadding - totalSpacing) / 3.1
        
        // Default height
        var height: CGFloat = 60
        
        // For nutrient cells, calculate the required height based on text
        if !(indexPath.item == 8 && !isExpanded) && !(isExpanded && indexPath.item == rdaData.count) {
            let nutrient: String
            if isExpanded {
                let otherNutrients = rdaData.keys.filter { !mainNutrients.contains($0) }.sorted()
                let allNutrients = mainNutrients + otherNutrients
                nutrient = allNutrients[indexPath.item]
            } else {
                nutrient = mainNutrients[indexPath.item]
            }
            
            if let data = rdaData[nutrient] {
                // Text to display
                let nameText = nutrient.lowercased() == "carbohydrates" ? "Carbs" : nutrient.capitalized
                let valueText = "\(String(format: "%.1f", data.value)) \(data.unit)"
                
                // Fonts (match NutrientCell)
                let nameFont = UIFont.systemFont(ofSize: 14, weight: .medium)
                let valueFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
                
                // Calculate text widths (account for 8-point padding on each side)
                let textWidth = width - 16 // 8 leading + 8 trailing padding in NutrientCell
                
                // Calculate heights
                let nameHeight = heightForText(nameText, font: nameFont, width: textWidth)
                let valueHeight = heightForText(valueText, font: valueFont, width: textWidth)
                
                // Total required height: name + value + 10 (spacing between them) + 8 (top padding) + 8 (bottom padding)
                let requiredHeight = nameHeight + 10 + valueHeight + 16
                
                // Update height if required height is greater
                height = max(height, requiredHeight)
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath.item == 8 && !isExpanded) || (isExpanded && indexPath.item == rdaData.count) {
            isExpanded.toggle()
            collectionView.reloadData()
            updateRDAViewHeight()
        }
    }
    private func heightForText(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
    // MARK: - Profile Listener and Caching
    
    private var profileListener: ListenerRegistration?
    
    private func setupProfileListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            updateProfileAsGuest()
            return
        }
        print("ProfileViewController: Current user ID: \(userId)")
        
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
                self.updateProfileFromCache(userId: userId)
                return
            }
            
            guard let document = document, document.exists else {
                self.updateProfileAsGuest()
                return
            }
            
            let data = document.data() ?? [:]
            
            if let fullName = data["name"] as? String {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                DispatchQueue.main.async {
                    self.userNameLabel.text = firstName
                }
                UserDefaults.standard.set(fullName, forKey: "cachedUserName_\(userId)")
            } else {
                print("ProfileViewController: No name in Firestore data, keeping cached or default name")
            }
            
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
        let size = CGSize(width: profileImageView.frame.width, height: self.profileImageView.frame.height)
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
        cell.accessoryType = .disclosureIndicator
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
        case 0: performSegue(withIdentifier: "EditHealthInfo", sender: nil)
        case 1: performSegue(withIdentifier: "EditPersonalInfo", sender: nil)
        case 2: performSegue(withIdentifier: "ScoringMethodology", sender: nil)
        case 3: openLegalPage(type: "privacy")
        case 4: openLegalPage(type: "terms")
        default:
            print("ProfileViewController: Unknown row selected: \(indexPath.row)")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    // MARK: - Sign Out Methods
    
    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                let defaults = UserDefaults.standard
                if let domain = Bundle.main.bundleIdentifier {
                    defaults.removePersistentDomain(forName: domain)
                }
                defaults.synchronize()
                
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

// MARK: - Nutrient Cell

class NutrientCell: UICollectionViewCell {
    private let nameLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray5.cgColor
        
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .black // Replace with UIColor(named: "CustomOrange") if defined
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.font = .systemFont(ofSize: 14, weight: .semibold) // Increased size and weight
        valueLabel.textColor = orangeColor // Better contrast
        valueLabel.numberOfLines = 1
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            valueLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with name: String, value: String, unit: String) {
        nameLabel.text = name
        valueLabel.text = "\(value) \(unit)"
    }
}

// MARK: - Toggle Cell

class ToggleCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray5.cgColor
        
        label.textColor = orangeColor
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with text: String, isExpanded: Bool) {
        label.text = text
    }
}
