//
//  NutritionViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit


class NutritionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Store nutrition data as (name, value) with value as String (including unit)
    var nutritionData: [(name: String, value: String, rdaPercentage: Int)] = []
    private var user: Users?
    var product: ProductData? {
        didSet {
            print("[DEBUG] Product set: \(product?.name ?? "Unknown")")
            print("[DEBUG] About to dispatch to main queue")
            DispatchQueue.main.async {
                print("[DEBUG] Starting extractNutritionData")
                self.extractNutritionData()
                print("[DEBUG] Finished extractNutritionData")
                print("[DEBUG] About to reload table view")
                print(self.nutritionData.count)
                self.NutritionTableView.reloadData()
                print("[DEBUG] Finished reloading table view")
            }
        }
    }
    
    @IBOutlet weak var NutritionTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NutritionTableView.delegate = self
        NutritionTableView.dataSource = self
        fetchUserData { user in
                    guard let user = user else {
                        print("[DEBUG] Failed to fetch user data")
                        return
                    }
                    self.user = user
                    print("[DEBUG] User data fetched: \(user)")
                    
                    // Trigger extraction once user data is available
                    self.extractNutritionData()
                }
    }
    
    func updateWithProduct(_ product: ProductData) {
        print("[DEBUG] updateWithProduct called for: \(product.name)")
        self.product = product
    }
    
    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nutritionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCell", for: indexPath) as! NutritionCell
        let nutrition = nutritionData[indexPath.row]
        
        print("[DEBUG] Configuring cell for \(nutrition.name) - Value: \(nutrition.value)")
        
        cell.NutrientLabel.text = nutrition.name
        cell.NutrientGrams.text = nutrition.value
        cell.RDAPercentage.text = String(format: "%d%%", nutrition.rdaPercentage)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 6
        let maskLayer = CALayer()
        maskLayer.cornerRadius = 8
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(
            x: cell.bounds.origin.x,
            y: cell.bounds.origin.y,
            width: cell.bounds.width,
            height: cell.bounds.height
        ).insetBy(dx: 0, dy: verticalPadding / 2)
        cell.layer.mask = maskLayer
    }
    
    // MARK: - Nutrition Data Extraction
    func extractNutritionData() {
     
        guard let nutritionInfo = product?.nutritionInfo, let product = product else {
            
            print("[DEBUG] No nutritionInfo found in product")
            nutritionData = []
            DispatchQueue.main.async {
                self.NutritionTableView.reloadData()
            }
            return
        }
        guard let user = user else {
                    print("[DEBUG] No user data available yet, waiting for fetchUserData")
                    nutritionData = []
                    DispatchQueue.main.async {
                        self.NutritionTableView.reloadData()
                    }
                    return
                }
        print("[DEBUG] Extracting nutrition data for product")
        nutritionData.removeAll()
        let rdaPercentages = getRDAPercentages(product: product, user: user)
        // Iterate over the nutritionInfo array
        for nutrition in nutritionInfo {
       
            let formattedName = formatNutritionName(nutrition.name)
            let numericValue = nutrition.value
            
            // Only add to nutrition data if the value is not zero
            if numericValue != 0 {
                let displayValue = formatDisplayValue(value: Double(numericValue), unit: nutrition.unit)
                let percentage = rdaPercentages[nutrition.name.lowercased()] ?? 0.0
                nutritionData.append((name: formattedName, value: displayValue, rdaPercentage: Int(percentage)))
                print("[DEBUG] Extracted \(formattedName): \(displayValue)")
            }
        }
        
        // Sort alphabetically by name
        nutritionData.sort { $0.name < $1.name }
        print("[DEBUG] Nutrition data sorted and updated")
        print(nutritionData)
        
        // Reload table view on the main thread
        DispatchQueue.main.async {
            self.NutritionTableView.reloadData()
        }
    }
    
    // Format the display value with unit (e.g., "200 kcal", "5 g")
    func formatDisplayValue(value: Double, unit: String) -> String {
        // Avoid displaying ".0" for whole numbers
        let formattedValue = value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
        return "\(formattedValue) \(unit)"
    }
    
    // Format nutrient name for display (e.g., "total fat" -> "Total Fat")
    func formatNutritionName(_ name: String) -> String {
        // Split by spaces and capitalize each word
        let words = name.split(separator: " ").map { $0.capitalized }
        return words.joined(separator: " ")
    }
}
