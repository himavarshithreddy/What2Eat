import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class SummaryLabelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var productAnalysis: ProductAnalysis?
    var productdetails:ProductResponse?{
        didSet {
            if !userDietaryRestrictions.isEmpty{
                compareDietaryRestrictions()
            }
        }
    }
    var productAllergenAlerts: [Allergen] = []
    var ingredients: [String]? {
            didSet {
                if !userAllergens.isEmpty { // Only compare if allergens are loaded
                    compareAllergens()
                }
            }
        }
    var userDietaryRestrictions: [DietaryRestriction] = []
        var dietaryRestrictionAlerts: [DietaryRestriction] = []
    var userAllergens: [Allergen] = []
    var expandedIndexPaths: [IndexPath: Bool] = [:] // Tracks expanded state for each cell
    
    @IBOutlet var AlertView: UIView!
    @IBOutlet var AlertTableView: UITableView!
    @IBOutlet var AlertViewHeight: NSLayoutConstraint!
    @IBOutlet var SummaryTableView: UITableView!
    @IBOutlet var SummaryTableHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SummaryTableView.dataSource = self
        SummaryTableView.delegate = self
        AlertTableView.dataSource = self
        AlertTableView.delegate = self
        
        // Keep original height settings
        AlertView.isHidden = true
        SummaryTableView.estimatedRowHeight = 30
        SummaryTableView.rowHeight = UITableView.automaticDimension
        AlertTableView.sectionHeaderHeight = 0
        fetchUserAllergensForSummary()
        fetchUserDietaryRestrictions()
        updateUI() // Initial setup
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 1 {
            var sections = 0
            if let product = productAnalysis {
                if !product.pros.isEmpty { sections += 1 }
                if !product.cons.isEmpty { sections += 1 }
            }
            return sections
        } else if tableView.tag == 2 {
            return (productAllergenAlerts.isEmpty && dietaryRestrictionAlerts.isEmpty) ? 0 : 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            if let product = productAnalysis {
                if !product.pros.isEmpty && section == 0 {
                    return product.pros.count
                } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                    return product.cons.count
                }
            }
        } else if tableView.tag == 2 {
            return productAllergenAlerts.count + dietaryRestrictionAlerts.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsLabelCell", for: indexPath) as! HighlightsLabelCell
            
            // Check if the cell is expanded
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            
            if let product = productAnalysis {
                if !product.pros.isEmpty && indexPath.section == 0 {
                    let pro = product.pros[indexPath.row]
                    cell.HighlightText.text = pro.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "checkmark.square.fill")
                    cell.iconImage.tintColor = .systemGreen
                    
                    if pro.summaryPoint != "Contains some nutrients" {
                        let proValueText = pro.value < 0.1 ? "<0.1" : String(format: "%.1f", pro.value)
                        cell.DescriptionText.text = pro.value >= 85 ? ">85% of your RDA, check serving size, may exceed your needs" : "\(proValueText)% of your recommended daily Intake."
                        cell.ProgressBar.progress = Float(pro.value) / 100.0
                        cell.ProgressBar.progressTintColor = .systemGreen
                        cell.ProgressBar.alpha = 1
                    } else {
                        cell.DescriptionText.text = "Check Nutrition tab for more Details"
                        cell.ProgressBar.progress = 0.0
                        cell.ProgressBar.alpha = 0.0
                    }
                    
                } else if !product.cons.isEmpty && indexPath.section == (product.pros.isEmpty ? 0 : 1) {
                    let con = product.cons[indexPath.row]
                    cell.HighlightText.text = con.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    cell.iconImage.tintColor = .systemRed
                    if con.summaryPoint != "No major concerns detected" {
                        let conValueText = con.value < 0.1 ? "<0.1" : String(format: "%.1f", con.value)
                        cell.DescriptionText.text = con.value >= 100 ? ">100% of your RDA, check serving size" : "\(conValueText)% of your recommended daily Intake."
                        cell.ProgressBar.progress = Float(con.value) / 100.0
                        cell.ProgressBar.progressTintColor = .systemRed
                        cell.ProgressBar.alpha = 1
                    } else {
                        cell.DescriptionText.text = "Check Nutrition tab for more Details"
                        cell.ProgressBar.progress = 0.0
                        cell.ProgressBar.alpha = 0.0
                    }
                }
            }

            cell.configureExpandButton(isExpanded: isExpanded)
                    cell.onExpandButtonTapped = { [weak self] in
                        guard let self = self else { return }
                        // Toggle the expanded state
                        self.expandedIndexPaths[indexPath] = !isExpanded
                        // Reload the row to reflect the new state
                        tableView.beginUpdates()
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        tableView.endUpdates()
                        // Update the table height
                        self.updateSummaryTableHeight()
                    }
            // Show/Hide elements based on expanded state
            cell.DescriptionText.isHidden = !isExpanded
            cell.ProgressBar.isHidden = !isExpanded
            
            // Enable wrapping for longer text
            cell.HighlightText.numberOfLines = 0
            cell.DescriptionText.numberOfLines = 0
            return cell
        } else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertLabelCell", for: indexPath) as! AlertLabelCell
            let totalAllergens = productAllergenAlerts.count
            if indexPath.row < totalAllergens {
                let allergen = productAllergenAlerts[indexPath.row]
                cell.AlertText.text = "Contains \(allergen.rawValue)"
            } else {
                let dietaryIndex = indexPath.row - totalAllergens
                let restriction = dietaryRestrictionAlerts[dietaryIndex]
                cell.AlertText.text = "Violates \(restriction.rawValue)"
            }
            return cell
        }
        return UITableViewCell()
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView.tag == 1 {
            return 30 // Original height
        } else if tableView.tag == 2 {
            return 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard tableView.tag == 1 else { return nil }
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 0, y: -10, width: tableView.frame.size.width, height: 25)
        
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .left
        
        if let product = productAnalysis {
            if !product.pros.isEmpty && section == 0 {
                titleLabel.text = "What’s Good 🙂"
            } else if !product.cons.isEmpty && section == (product.pros.isEmpty ? 0 : 1) {
                titleLabel.text = "What’s Concerning ❗"
            }
        }
        
        headerView.addSubview(titleLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 1 {
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            return isExpanded ? 100 : 50 // Collapsed height: 60, Expanded height: 120
        } else if tableView.tag == 2 {
            return 25 // Original height for AlertTableView
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 1 {
            // Toggle the expanded state
            let isExpanded = expandedIndexPaths[indexPath] ?? false
            expandedIndexPaths[indexPath] = !isExpanded
            
            // Reload the row to reflect the new state
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            // Update the table height
            updateSummaryTableHeight()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UI Updates
    private func updateSummaryTableHeight() {
        guard let product = productAnalysis else { return }
        
        var totalHeight: CGFloat = 0
        var headerHeight: CGFloat = 0
        
        // Calculate number of sections and headers
        if !product.pros.isEmpty {
            headerHeight += 50 // Header height for "What’s Good"
            for row in 0..<product.pros.count {
                let indexPath = IndexPath(row: row, section: 0)
                let isExpanded = expandedIndexPaths[indexPath] ?? false
                totalHeight += isExpanded ? 100 : 50
            }
        }
        if !product.cons.isEmpty {
            headerHeight += 50 // Header height for "What’s Concerning"
            let section = product.pros.isEmpty ? 0 : 1
            for row in 0..<product.cons.count {
                let indexPath = IndexPath(row: row, section: section)
                let isExpanded = expandedIndexPaths[indexPath] ?? false
                totalHeight += isExpanded ? 100 : 50
            }
        }
        
        let newHeight = totalHeight + headerHeight
        SummaryTableHeight.constant = newHeight
        self.view.layoutIfNeeded()
    }
    
    func updateAlertView() {
        let totalAlerts = productAllergenAlerts.count + dietaryRestrictionAlerts.count
        if totalAlerts == 0 {
            AlertView.isHidden = true
        } else {
            AlertView.isHidden = false
            AlertViewHeight.constant = CGFloat(30 * totalAlerts + 35)
        }
        AlertTableView.reloadData()
    }
    
    func updateWithProduct(_ product: ProductAnalysis) {
        self.productAnalysis = product
        DispatchQueue.main.async {
            self.updateSummaryTableHeight()
            self.SummaryTableView.reloadData()
            self.updateAlertView()
            if self.ingredients != nil {
                            self.compareAllergens()
                        }
            if self.productdetails != nil {
                self.compareDietaryRestrictions()
            }
        }
    }
    
    private func updateUI() {
        updateSummaryTableHeight()
        updateAlertView()
        SummaryTableView.reloadData()
        AlertTableView.reloadData()
    }
    
    func compareAllergens() {
        guard let productIngredients = ingredients else {
            self.productAllergenAlerts = []
            updateAlertView()
            return
        }
        
        var alerts: [Allergen] = []
        
        // For each user-selected allergen, check its mapped synonyms
        for allergen in userAllergens {
            if let synonyms = allergenMapping[allergen.rawValue] {
                for synonym in synonyms {
                    for ingredient in productIngredients {
                        if ingredient.lowercased().contains(synonym.lowercased()) {
                            if !alerts.contains(allergen) {
                                alerts.append(allergen)
                            }
                            // Once a synonym matches for this allergen, break out
                            break
                        }
                    }
                }
            }
        }
        
        productAllergenAlerts = alerts
        updateAlertView()
    }
    
    func fetchUserAllergensForSummary() {
        let defaults = UserDefaults.standard
        if let localAllergies = defaults.array(forKey: "localAllergies") as? [String], !localAllergies.isEmpty {
            userAllergens = localAllergies.compactMap { Allergen(rawValue: $0) }
            
        } else if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            userDocument.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching user allergens: \(error.localizedDescription)")
                    return
                }
                if let document = document, document.exists,
                   let allergiesFromDB = document.get("allergies") as? [String] {
                    self.userAllergens = allergiesFromDB.compactMap { Allergen(rawValue: $0) }
                    defaults.set(allergiesFromDB, forKey: "localAllergies") // Cache to UserDefaults
                    if self.ingredients != nil {
                                            self.compareAllergens()
                                        }
                }
            }
        }
    }
    
    func compareDietaryRestrictions() {
        guard let productdetails = productdetails else {
            dietaryRestrictionAlerts = []
            updateAlertView()
            return
        }
        let productData = ProductData(
                    id: productdetails.id ?? "",
                    barcode: [],
                    name: productdetails.name,
                    imageURL: "",
                    ingredients: productdetails.ingredients,
                    artificialIngredients: [],
                    nutritionInfo: productdetails.nutrition,
                    userRating: 0,
                    numberOfRatings: 0,
                    categoryId: "",
                    allergens: nil,
                    pros: [],
                    cons: [],
                    healthScore: 0
                )
        var alerts: [DietaryRestriction] = []
        for restriction in userDietaryRestrictions {
            if let rule = dietaryRestrictionRules[restriction], !rule(productData) {
                alerts.append(restriction)
            }
        }
        dietaryRestrictionAlerts = alerts
        updateAlertView()
    }
    func fetchUserDietaryRestrictions() {
        let defaults = UserDefaults.standard
        if let localRestrictions = defaults.array(forKey: "localDietaryRestrictions") as? [String], !localRestrictions.isEmpty {
            userDietaryRestrictions = localRestrictions.compactMap { dietaryRestrictionMapping[$0] }
            
        } else if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            userDocument.getDocument { [weak self] (document, error) in
                if let document = document, document.exists,
                   let restrictionsFromDB = document.get("dietaryRestrictions") as? [String] {
                    self?.userDietaryRestrictions = restrictionsFromDB.compactMap { dietaryRestrictionMapping[$0] }
                    defaults.set(restrictionsFromDB, forKey: "localDietaryRestrictions") // Cache to UserDefaults
                    if self?.productdetails != nil {
                        self!.compareDietaryRestrictions()
                                        }
                }
                
            }
        }
    }
}
