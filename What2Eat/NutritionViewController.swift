//
//  NutritionViewController.swift
//  What2Eat
//
//  Created by admin68 on 02/11/24.
//

import UIKit

class NutritionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 
    
    // Store nutrition data as (name, value) with value as String
    var nutritionData: [(name: String, value: String)] = []
    
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
        extractNutritionData()
   
    }
    

    
    func updateWithProduct(_ product: ProductData) {
        print("[DEBUG] updateWithProduct called for: \(product.name)")
        self.product = product
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nutritionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCell", for: indexPath) as! NutritionCell
        let nutrition = nutritionData[indexPath.row]
        
        print("[DEBUG] Configuring cell for \(nutrition.name) - Value: \(nutrition.value)")
        
        cell.NutrientLabel.text = nutrition.name
        cell.NutrientGrams.text = nutrition.value
        let numericValue = extractNumericValue(from: nutrition.value)
            
           
        let progressValue = normalizedProgress(for: numericValue, with: nutrition.value)
        print(progressValue)
            
           
            cell.NutritionProgress.progress = Float(progressValue)
        
        return cell
    }
    func normalizedProgress(for numericValue: Double, with rawValue: String) -> Float {
        let lowercasedValue = rawValue.lowercased()
        var progress: Double = 0.0
        
        if lowercasedValue.contains("mg") {
            // Assume 1000 mg is the maximum value for full progress
            progress = numericValue / 1000.0
        } else if lowercasedValue.contains("kcal") {
            // Assume 2000 kcal is the maximum value for full progress
            progress = numericValue / 1000.0
        } else {
            // Default normalization
            progress = numericValue / 100.0
        }
        
        return Float(progress)
    }

    
    // MARK: - Nutrition Data Extraction
    func extractNutritionData() {
        guard let nutritionInfo = product?.nutritionInfo else {
            print("[DEBUG] No nutritionInfo found in product")
            return
        }
        
        print("[DEBUG] Extracting nutrition data for product")
        nutritionData.removeAll()
        
        let mirror = Mirror(reflecting: nutritionInfo)
        
        for child in mirror.children {
            if let pair = child.value as? (key: String, value: String) {
                let formattedName = formatNutritionName(pair.key)
                
                // Extract numeric value from the string
                let numericValue = extractNumericValue(from: pair.value)
                
                // Only add to nutrition data if the value is not zero
                if numericValue != 0 {
                    nutritionData.append((name: formattedName, value: pair.value))
                    print("[DEBUG] Extracted \(formattedName): \(pair.value)")
                }
            }
        }
        
        nutritionData.sort { $0.name < $1.name }
        print("[DEBUG] Nutrition data sorted and updated")
        
        // Reload table view in the main thread
        DispatchQueue.main.async {
            self.NutritionTableView.reloadData()
        }
    }
    
    func extractNumericValue(from value: String) -> Double {
        do {
            // This regex pattern captures numbers with optional decimals.
            let regex = try NSRegularExpression(pattern: "[0-9]+(?:\\.[0-9]+)?", options: [])
            let range = NSRange(location: 0, length: value.utf16.count)
            if let match = regex.firstMatch(in: value, options: [], range: range),
               let swiftRange = Range(match.range, in: value) {
                let numberString = String(value[swiftRange])
                return Double(numberString) ?? 0.0
            }
        } catch {
            print("[ERROR] Regex error: \(error)")
        }
        return 0.0
    }
    
    
    func formatNutritionName(_ name: String) -> String {
        // Convert camelCase to space-separated words for readability
        let formatted = name.replacingOccurrences(of: "([a-z])([A-Z])",
                                                  with: "$1 $2",
                                                  options: .regularExpression,
                                                  range: name.range(of: name))
        return formatted.capitalized
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
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
}
