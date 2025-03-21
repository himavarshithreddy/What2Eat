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
    
    // MARK: - Save Scan
    func saveScanWithLabelProduct(_ product: ProductResponse, image: UIImage?, healthScore: Int?, analysis: ProductAnalysis?, id: String, isRecent: Bool = true, isSaved: Bool = false) {
        // Check if the product already exists to update it instead of duplicating
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try context.fetch(fetchRequest)
            let scan: ScanWithLabelProduct
            
            if let existingScan = results.first {
                // Update existing scan
                scan = existingScan
            } else {
                // Create new scan
                scan = ScanWithLabelProduct(context: context)
                scan.id = id
            }
            
            scan.name = product.name
            scan.healthScore = Int32(healthScore ?? 0)
            
            if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
                scan.imageData = imageData
            }
            
            let encoder = JSONEncoder()
            scan.ingredients = try? encoder.encode(product.ingredients)
            scan.nutrition = try? encoder.encode(product.nutrition)
            if let analysis = analysis {
                scan.analysis = try? encoder.encode(analysis)
            }
            
            // Set or update flags
            scan.isRecent = isRecent
            scan.isSaved = isSaved
            
            try context.save()
            print("Product saved/updated successfully with id: \(id), isRecent: \(isRecent), isSaved: \(isSaved)")
        } catch {
            print("Failed to save product: \(error)")
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
}
