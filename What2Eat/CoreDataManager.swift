import CoreData
import UIKit
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "What2Eat") // Ensure this matches your Core Data model file name
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    func countProducts() -> Int {
            let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
            do {
                let count = try context.count(for: fetchRequest)
                return count
            } catch {
                print("Error counting products: \(error)")
                return 0
            }
        }
    
    // MARK: - Save Scan
    func saveScanWithLabelProduct(_ product: ProductResponse, image: UIImage?, healthScore: Int?, id: String? = nil) -> String {
        let initialCount = countProducts()
            // Check for an existing match
            if let existingScan = findMatchingProduct(product, image: image, healthScore: healthScore) {
                // Update existing scan to mark as recent
                existingScan.isRecent = true
                do {
                    try context.save()
                    let updatedCount = countProducts()
                                    print("Updated existing product with id: \(existingScan.id ?? ""), name: \(product.name ?? ""), new image. Products now: \(updatedCount)")
                    cleanupIfNeeded()
                    return existingScan.id ?? UUID().uuidString // Return existing ID
                } catch {
                    print("Failed to update existing product: \(error)")
                    return existingScan.id ?? UUID().uuidString
                }
            }
            
            // No match found, save as new entry
            let scanId = id ?? UUID().uuidString
            let scan = ScanWithLabelProduct(context: context)
            scan.id = scanId
            scan.name = product.name
            scan.healthScore = Int32(healthScore ?? 0)
            scan.isRecent = true
            scan.isSaved = false
            
            if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
                scan.imageData = imageData
            }
            
            let encoder = JSONEncoder()
            scan.ingredients = try? encoder.encode(product.ingredients)
            scan.nutrition = try? encoder.encode(product.nutrition)
            
            do {
                try context.save()
                let newCount = countProducts()
                            print("New product saved with id: \(scanId). Products now: \(newCount)")
                cleanupIfNeeded()
                return scanId
            } catch {
                print("Failed to save new product: \(error)")
                return scanId
            }
        }
    
    // MARK: - Check Status
    func isProductSaved(withId id: String) -> Bool {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND isSaved == YES", id)
        
        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Error checking if product is saved: \(error)")
            return false
        }
    }
    
    func isProductRecent(withId id: String) -> Bool {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND isRecent == YES", id)
        
        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Error checking if product is recent: \(error)")
            return false
        }
    }
    
    // MARK: - Update Status
    func updateScanStatus(id: String, isRecent: Bool? = nil, isSaved: Bool? = nil) {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            if let scan = try context.fetch(fetchRequest).first {
                if let isRecent = isRecent {
                    scan.isRecent = isRecent
                }
                if let isSaved = isSaved {
                    scan.isSaved = isSaved
                }
                try context.save()
                
                // Delete if no longer referenced
                if !scan.isRecent && !scan.isSaved {
                    context.delete(scan)
                    try context.save()
                    print("Deleted scan with ID: \(id) as it’s no longer recent or saved")
                }
            } else {
                print("No product found with ID: \(id) to update")
            }
        } catch {
            print("Error updating scan status: \(error)")
        }
    }
    
    // MARK: - Delete Recent Scan
    func deleteRecentScan(withId id: String) {
        updateScanStatus(id: id, isRecent: false)
    }
    
    // MARK: - Fetch Products
    func fetchScanWithLabelProducts() -> [ScanWithLabelProduct] {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch products: \(error)")
            return []
        }
    }
    
    func fetchRecentScans() -> [ScanWithLabelProduct] {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isRecent == YES")
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch recent scans: \(error)")
            return []
        }
    }
    
    func fetchSavedScans() -> [ScanWithLabelProduct] {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSaved == YES")
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch saved scans: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup
    func cleanupOrphanedScans() {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isRecent == NO AND isSaved == NO")
        
        do {
            let orphanedScans = try context.fetch(fetchRequest)
            for scan in orphanedScans {
                context.delete(scan)
            }
            try context.save()
            print("Cleaned up \(orphanedScans.count) orphaned scans")
        } catch {
            print("Error cleaning up orphaned scans: \(error)")
        }
    }
    
    // MARK: - Storage Management
    func getCoreDataSize() -> Int64 {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        do {
            let scans = try context.fetch(fetchRequest)
            return scans.reduce(0) { $0 + (Int64($1.imageData?.count ?? 0)) }
        } catch {
            print("Error calculating Core Data size: \(error)")
            return 0
        }
    }
    
    func cleanupIfNeeded(maxSizeMB: Int = 100) {
        let maxSizeBytes = maxSizeMB * 1024 * 1024 // Convert MB to bytes
        let currentSize = getCoreDataSize()
        
        if currentSize > maxSizeBytes {
            cleanupOrphanedScans()
            print("Performed cleanup due to size limit: \(currentSize) bytes exceeded \(maxSizeBytes) bytes")
        }
    }
    private func findMatchingProduct(_ product: ProductResponse, image: UIImage?, healthScore: Int?) -> ScanWithLabelProduct? {
            let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", product.name)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let scans = try context.fetch(fetchRequest)
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                
                for scan in scans {
                    // Decode stored data for comparison
                    guard let storedIngredientsData = scan.ingredients,
                          let storedNutritionData = scan.nutrition,
                          let storedIngredients = try? decoder.decode([String].self, from: storedIngredientsData),
                          let storedNutrition = try? decoder.decode([Nutrition].self, from: storedNutritionData) else {
                        continue
                    }
                    
                    _ = scan.analysis != nil ? try? decoder.decode(ProductAnalysis.self, from: scan.analysis!) : nil
                    _ = try? encoder.encode(product.ingredients)
                    _ = try? encoder.encode(product.nutrition)
                  
                    
                    // Compare all fields
                    let isMatch =
                                  scan.healthScore == Int32(healthScore ?? 0) &&
                                  storedIngredients == product.ingredients &&
                                  storedNutrition.elementsEqual(product.nutrition, by: { $0.name == $1.name && $0.value == $1.value && $0.unit == $1.unit }) 
                    
                    if isMatch {
                        return scan
                    }
                }
                return nil
            } catch {
                print("Error checking for matching product: \(error)")
                return nil
            }
        }
    
}
