import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class SummaryLabelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var productAnalysis: ProductAnalysis?
    var productAllergenAlerts: [Allergen] = []
    var ingredients: [String]?
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
            return productAllergenAlerts.isEmpty ? 0 : 1
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
            return productAllergenAlerts.count
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
                    cell.DescriptionText.text = "\(pro.value)% of your recommended daily Intake."
                    cell.ProgressBar.progress = Float(pro.value) / 100.0
                    cell.ProgressBar.progressTintColor = .systemGreen
                    cell.iconImage.image = UIImage(systemName: "checkmark.square.fill")
                    cell.iconImage.tintColor = .systemGreen
                } else if !product.cons.isEmpty && indexPath.section == (product.pros.isEmpty ? 0 : 1) {
                    let con = product.cons[indexPath.row]
                    cell.HighlightText.text = con.summaryPoint
                    cell.DescriptionText.text = "\(con.value)% of your recommended daily Intake."
                    cell.ProgressBar.progress = Float(con.value) / 100.0
                    cell.ProgressBar.progressTintColor = .systemRed
                    cell.iconImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    cell.iconImage.tintColor = .systemRed
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
            let allergen = productAllergenAlerts[indexPath.row]
            cell.AlertText.text = "Contains \(allergen.rawValue)"
            cell.AlertText.numberOfLines = 0
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
        if productAllergenAlerts.isEmpty {
            AlertView.isHidden = true
        } else {
            AlertView.isHidden = false
            AlertViewHeight.constant = CGFloat(30 * productAllergenAlerts.count + 35) // Original calculation
        }
        AlertTableView.reloadData()
    }
    
    func updateWithProduct(_ product: ProductAnalysis) {
        self.productAnalysis = product
        DispatchQueue.main.async {
            self.updateSummaryTableHeight()
            self.SummaryTableView.reloadData()
            self.updateAlertView()
            self.compareAllergens()
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
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userDocument = db.collection("users").document(uid)
            userDocument.getDocument { [weak self] (document, error) in
                if let error = error {
                    print("Error fetching user allergens: \(error.localizedDescription)")
                } else if let document = document, document.exists,
                          let allergiesFromDB = document.get("allergies") as? [String] {
                    self?.userAllergens = allergiesFromDB.compactMap { Allergen(rawValue: $0) }
                    // Once fetched, compare with product ingredients
                    self?.compareAllergens()
                }
            }
        } else {
            let defaults = UserDefaults.standard
            if let localAllergies = defaults.array(forKey: "localAllergies") as? [String] {
                userAllergens = localAllergies.compactMap { Allergen(rawValue: $0) }
                compareAllergens()
            }
        }
    }
    
    
    
   
    
}
