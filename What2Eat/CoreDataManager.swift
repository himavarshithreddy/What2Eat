import CoreData
import UIKit
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "What2Eat") // Change to your Core Data file name
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Save a scanned product using UUID-based id.
    func saveScanWithLabelProduct(_ product: ProductResponse, image: UIImage?, healthScore: Int?,analysis: ProductAnalysis?, id: String) {
        let newProduct = ScanWithLabelProduct(context: context)
        newProduct.id = id // Use the provided ID instead of generating a new one
        newProduct.name = product.name
        newProduct.healthScore = Int32(healthScore ?? 0)
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            newProduct.imageData = imageData
        }
        
        // Convert arrays to JSON Data for ingredients and nutrition
        let encoder = JSONEncoder()
        newProduct.ingredients = try? encoder.encode(product.ingredients)
        newProduct.nutrition = try? encoder.encode(product.nutrition)
        if let analysis = analysis {
                newProduct.analysis = try? encoder.encode(analysis)
            }
        do {
            try context.save()
            print("Product saved successfully with id: \(id)")
        } catch {
            print("Failed to save product: \(error)")
        }
    }
    
    // Check if product is saved (if you wish to compare, you'll need to store the generated id somewhere).
    // Since we're using UUID, every save is unique, so this method might not be applicable unless you have another unique field.
    // You might only use this method for deletion if you have stored a product's id already.
    func isProductSaved(withId id: String) -> Bool {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Error checking if product exists: \(error)")
            return false
        }
    }
    
    // Delete product with given id.
    func deleteScanWithLabelProduct(withId id: String) {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let productToDelete = results.first {
                context.delete(productToDelete)
                try context.save()
                print("Product deleted successfully!")
            }
        } catch {
            print("Failed to delete product: \(error)")
        }
    }
    
    // Fetch all saved products.
    func fetchScanWithLabelProducts() -> [ScanWithLabelProduct] {
        let fetchRequest: NSFetchRequest<ScanWithLabelProduct> = ScanWithLabelProduct.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch products: \(error)")
            return []
        }
    }
}
