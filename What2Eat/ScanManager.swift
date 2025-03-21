import Foundation

class ScanManager {
    // Save a scan to recent scans in UserDefaults and update Core Data
    static func saveToRecentScans(type: String, id: String) {
        let defaults = UserDefaults.standard
        var localScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
        
        // Remove existing scan with the same ID to avoid duplicates and move it to the top
        if let index = localScans.firstIndex(where: { $0["id"] as? String == id }) {
            localScans.remove(at: index)
        }
        
        // Add the new scan at the beginning with a timestamp
        let newScan = ["type": type, "id": id, "index": Date().timeIntervalSince1970] as [String: Any]
        localScans.insert(newScan, at: 0)
        
        // Limit to 50 recent scans
        if localScans.count > 50 {
            if let oldestScan = localScans.last, let oldestId = oldestScan["id"] as? String {
                localScans.removeLast()
                // Update Core Data: remove from recent scans if not saved
                CoreDataManager.shared.deleteRecentScan(withId: oldestId)
            }
        }
        
        // Save back to UserDefaults
        defaults.set(localScans, forKey: "localRecentScans")
        print("Saved scan to recentScans: type=\(type), id=\(id)")
        
        // Ensure the scan is marked as recent in Core Data
        CoreDataManager.shared.updateScanStatus(id: id, isRecent: true)
    }
    
    // Remove a scan from recent scans in UserDefaults and update Core Data
    static func deleteFromRecentScans(id: String) {
        let defaults = UserDefaults.standard
        var localScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
        
        // Remove the scan with the given ID
        if let index = localScans.firstIndex(where: { $0["id"] as? String == id }) {
            localScans.remove(at: index)
            defaults.set(localScans, forKey: "localRecentScans")
            print("Removed scan with id=\(id) from recentScans")
            
            // Update Core Data: set isRecent to false, which may delete if not saved
            CoreDataManager.shared.deleteRecentScan(withId: id)
        }
    }
    
    // Fetch all recent scans from UserDefaults
    static func getRecentScans() -> [[String: Any]] {
        let defaults = UserDefaults.standard
        return defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
    }
    
    // Clear all recent scans from UserDefaults and update Core Data
    static func clearRecentScans() {
        let defaults = UserDefaults.standard
        let localScans = defaults.array(forKey: "localRecentScans") as? [[String: Any]] ?? []
        
        for scan in localScans {
            if let id = scan["id"] as? String {
                CoreDataManager.shared.deleteRecentScan(withId: id)
            }
        }
        
        defaults.removeObject(forKey: "localRecentScans")
        print("Cleared all recent scans")
    }
}
