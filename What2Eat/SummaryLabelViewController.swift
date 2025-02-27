import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class SummaryLabelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var productAnalysis: ProductAnalysis?
    var productAllergenAlerts: [Allergen] = []
    var ingredients: [String]?
    var userAllergens: [Allergen] = []
    
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
        SummaryTableView.rowHeight = 40
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
            
            if let product = productAnalysis {
                if !product.pros.isEmpty && indexPath.section == 0 {
                    let pro = product.pros[indexPath.row]
                    cell.HighlightText.text = pro.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "checkmark.square.fill")
                    cell.iconImage.tintColor = .systemGreen
                } else if !product.cons.isEmpty && indexPath.section == (product.pros.isEmpty ? 0 : 1) {
                    let con = product.cons[indexPath.row]
                    cell.HighlightText.text = con.summaryPoint
                    cell.iconImage.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    cell.iconImage.tintColor = .systemRed
                }
            }
            
            // Enable wrapping for longer text
            cell.HighlightText.numberOfLines = 0
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
            return 20 // Original height
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
            return 50 // Original height
        } else if tableView.tag == 2 {
            return 25 // Original height
        }
        return 0
    }
    
    // MARK: - UI Updates
    private func updateSummaryTableHeight() {
        guard let product = productAnalysis else { return }
        
        var numberOfRows = 0
        var headerHeight: CGFloat = 0
        if !product.pros.isEmpty {
            numberOfRows += product.pros.count
            headerHeight += 40 // Original header height
        }
        if !product.cons.isEmpty {
            numberOfRows += product.cons.count
            headerHeight += 40 // Original header height
        }
        
        let rowHeight: CGFloat = 42 // Original calculation value
        let newHeight = (CGFloat(numberOfRows) * rowHeight) + headerHeight
        
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
