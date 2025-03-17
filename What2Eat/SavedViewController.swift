import UIKit
import FirebaseFirestore
import FirebaseAuth


class SavedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var SavedTableView: UITableView!

    var savedLists: [SavedList] = []
    let db = Firestore.firestore()
    var userId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        SavedTableView.dataSource = self
        SavedTableView.delegate = self
        
        // Get logged-in user ID
        if let currentUser = Auth.auth().currentUser {
            userId = currentUser.uid
            fetchSavedLists()
        } else {
            print("User not logged in")
        }
        navigationController?.navigationBar.prefersLargeTitles = true
        

        // Listen for new list creation
        NotificationCenter.default.addObserver(self, selector: #selector(newListCreated(_:)), name: Notification.Name("NewListCreated"), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSavedLists()
    }

    @objc func newListCreated(_ notification: Notification) {
        fetchSavedLists()
    }

    // Fetch saved lists from Firestore
    func fetchSavedLists() {
        guard let userId = userId else { return }
        
        db.collection("users").document(userId).getDocument(source: .default) { snapshot, error in
            guard let data = snapshot?.data(), let lists = data["savedLists"] as? [[String: Any]] else { return }
            
            self.savedLists = lists.compactMap { dict in
                            guard let listId = dict["listId"] as? String,
                                  let name = dict["name"] as? String,
                                  let iconName = dict["iconName"] as? String,
                                  let products = dict["products"] as? [String] else { return nil }
                            return SavedList(listId: listId, name: name, iconName: iconName, products: products)
                        }

            DispatchQueue.main.async {
                self.SavedTableView.reloadData()
            }
        }
    }

    // Delete a saved list from Firestore
    func confirmDelete(at indexPath: IndexPath) {
            guard let userId = userId else { return }
            
            let listToDelete = savedLists[indexPath.row]

            let listDict: [String: Any] = [
                    "listId": listToDelete.listId,
                    "name": listToDelete.name,
                    "iconName": listToDelete.iconName,
                    "products": listToDelete.products  // Ensure this matches what’s stored in Firestore
                ]
                
                db.collection("users").document(userId).updateData([
                    "savedLists": FieldValue.arrayRemove([listDict])
                ]) { error in
                    if let error = error {
                        print("Error deleting list: \(error)")
                    } else {
                        self.fetchSavedLists()
                    }
                }
            }

    // TableView: Number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // TableView: Number of rows (lists + "Create new List" row)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedLists.count + 1
    }

    // TableView: Display saved lists
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCell", for: indexPath) as! SavedCell

        if indexPath.row == savedLists.count {
            // Last row -> "Create new List"
            cell.SavedLabel.text = "Create new List"
            cell.SavedIcon.image = UIImage(systemName: "plus")
            cell.accessoryType = .none
        } else {
            // Show saved lists
            let saved = savedLists[indexPath.row]
            cell.SavedLabel.text = saved.name
            cell.SavedIcon.image = UIImage(systemName: saved.iconName)  // Load icon
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    // TableView: Delete row with confirmation
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.row < savedLists.count {
            showDeleteConfirmation(for: indexPath)
        }
    }

    // Show confirmation alert before deleting
    func showDeleteConfirmation(for indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: "Delete List",
                                            message: "Are you sure you want to delete this list?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.confirmDelete(at: indexPath)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = SavedTableView.rectForRow(at: indexPath)
        }
        
        present(actionSheet, animated: true, completion: nil)
    }

    // TableView: Row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    // TableView: Select a list or create a new one
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == savedLists.count {
            performSegue(withIdentifier: "NewList", sender: nil)
        } else {
            let selectedList = savedLists[indexPath.row]
            performSegue(withIdentifier: "ShowProductsSegue", sender: selectedList)
        }
    }

    // Pass data to the next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowProductsSegue" {
            if let savedProductsVC = segue.destination as? SavedProductsViewController,
               let selectedList = sender as? SavedList {
                savedProductsVC.listId = selectedList.listId // 🔥 Pass listId
            }
        }
    }
}
