import UIKit
import FirebaseAuth
import FirebaseFirestore



class AllergyViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet weak var allergyLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Store selected allergens as the canonical Allergen enum.
    var selectedAllergens: [Allergen] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchUserAllergies()
    }
    
    private func setupCollectionView() {
        collectionView.collectionViewLayout = createCompositionalLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func fetchUserAllergies() {
            let defaults = UserDefaults.standard
            if let localAllergies = defaults.array(forKey: "localAllergies") as? [String], !localAllergies.isEmpty {
                // Load from UserDefaults if available and non-empty
                print(localAllergies)
                selectedAllergens = localAllergies.compactMap { Allergen(rawValue: $0) }
                collectionView.reloadData()
            } else if let uid = Auth.auth().currentUser?.uid {
                // Fallback to Firebase if local data is missing
                let db = Firestore.firestore()
                let userDocument = db.collection("users").document(uid)
                
                userDocument.getDocument { [weak self] (document, error) in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error fetching allergies: \(error.localizedDescription)")
                        self.showAlert(message: "Error fetching allergies: \(error.localizedDescription)")
                    } else if let document = document, document.exists,
                              let allergiesFromDB = document.get("allergies") as? [String] {
                        self.selectedAllergens = allergiesFromDB.compactMap { Allergen(rawValue: $0) }
                        defaults.set(allergiesFromDB, forKey: "localAllergies") // Cache to UserDefaults
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    
    // MARK: - UICollectionView DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allergies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AllergyCell", for: indexPath) as! AllergyCell
        let allergy = allergies[indexPath.row]
        cell.allergyButton.setTitle(allergy, for: .normal)
        cell.allergyButton.titleLabel?.textAlignment = .center
        cell.allergyButton.tag = indexPath.row
        cell.allergyButton.addTarget(self, action: #selector(allergyButtonTapped(_:)), for: .touchUpInside)
        
        // For UI selection, use the canonical allergen
        if let canonicalAllergen = Allergen(rawValue: allergy), selectedAllergens.contains(canonicalAllergen) {
            cell.setSelectedState(isSelected: true)
        } else {
            cell.setSelectedState(isSelected: false)
        }
        
        return cell
    }
    
    // MARK: - Button Action
    
    @objc private func allergyButtonTapped(_ sender: UIButton) {
        let allergy = allergies[sender.tag]
        guard let canonicalAllergen = Allergen(rawValue: allergy) else { return }
        
        if let index = selectedAllergens.firstIndex(of: canonicalAllergen) {
            selectedAllergens.remove(at: index)
            sender.isSelected = false
            sender.backgroundColor = .clear
        } else {
            selectedAllergens.append(canonicalAllergen)
            sender.isSelected = true
            sender.backgroundColor = orangeColor
        }
    }
    
    // MARK: - UICollectionView Delegate FlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = allergies[indexPath.item]
        let font = UIFont.systemFont(ofSize: 17)
        let size = (title as NSString).size(withAttributes: [.font: font])

        let height: CGFloat = 50
        let minWidth: CGFloat = 50
        let width = max(size.width + 98, minWidth)
        return CGSize(width: width, height: height)
    }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(50))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Create a few row groups for layout (adjust as needed)
            let firstRowGroup = self.createRowGroup(withCount: 2, item: item)
            let secondRowGroup = self.createRowGroup(withCount: 3, item: item)
            let thirdRowGroup = self.createRowGroup(withCount: 2, item: item)
            let fourthRowGroup = self.createRowGroup(withCount: 3, item: item)
            let fifthRowGroup = self.createRowGroup(withCount: 3, item: item)
            
            let nestedGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(240)),
                subitems: [firstRowGroup, secondRowGroup, thirdRowGroup, fourthRowGroup, fifthRowGroup]
            )
            nestedGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(15)
            let section = NSCollectionLayoutSection(group: nestedGroup)
            section.interGroupSpacing = 25
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
            
            return section
        }
    }
    
    private func createRowGroup(withCount count: Int, item: NSCollectionLayoutItem) -> NSCollectionLayoutGroup {
        let items = Array(repeating: item, count: count)
        let rowGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44)),
            subitems: items
        )
        rowGroup.interItemSpacing = .fixed(12)
        rowGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        return rowGroup
    }
    
    // MARK: - Continue Button Action
    
    @IBAction func ContinueButton(_ sender: Any) {
            let selectedAllergenNames = selectedAllergens.map { $0.rawValue }
            let defaults = UserDefaults.standard
            
            // Always save to UserDefaults
            defaults.set(selectedAllergenNames, forKey: "localAllergies")
            
            // Save to Firebase if user is authenticated
            if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                let userDocument = db.collection("users").document(uid)
                
                userDocument.updateData(["allergies": selectedAllergenNames]) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        self.showAlert(message: "Error updating allergies in Firebase: \(error.localizedDescription)")
                    } else {
                        self.progressView.setProgress(0.5, animated: true)
                        print("Allergies saved to Firebase successfully")
                    }
                }
            } else {
                // If no user is authenticated, still update progress (local save succeeded)
                progressView.setProgress(0.5, animated: true)
                print("Allergies saved locally (no Firebase sync due to no authenticated user)")
            }
       
        }
    // MARK: - Utility
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: "Update Status", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
