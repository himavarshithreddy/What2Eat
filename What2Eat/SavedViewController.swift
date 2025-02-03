
import UIKit

class SavedViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet weak var SavedTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SavedTableView.dataSource = self
        SavedTableView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(newListCreated(_:)), name: Notification.Name("NewListCreated"), object: nil)
    }
    
    @objc func newListCreated(_ notification: Notification) {
       
            SavedTableView.reloadData()
        
    }

       
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                if indexPath.row < sampleLists.count { // Prevent deletion of "Create new List" row
                    showDeleteConfirmation(for: indexPath)
                }
            }
        }
        
        // Function to show Action Sheet for delete confirmation
        func showDeleteConfirmation(for indexPath: IndexPath) {
            let actionSheet = UIAlertController(title: "Delete List",
                                                message: "Are you sure you want to delete this list?",
                                                preferredStyle: .actionSheet)
            
            // Confirm Deletion Action
            actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.confirmDelete(at: indexPath)
            }))
            
            // Cancel Action
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            // Present the Action Sheet
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = SavedTableView.rectForRow(at: indexPath)
            }
            present(actionSheet, animated: true, completion: nil)
        }
        
        // Function to handle the deletion after confirmation
        func confirmDelete(at indexPath: IndexPath) {
          
            
            // Remove the item from the data source
            sampleLists.remove(at: indexPath.row)
            // Remove the corresponding row from the table
            SavedTableView.deleteRows(at: [indexPath], with: .fade)
            
            
        }
  
        
       
        

        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sampleLists.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCell", for: indexPath) as! SavedCell
       
        if indexPath.row == sampleLists.count {
            cell.SavedLabel.text = "Create new List"
            cell.SavedIcon.image = UIImage(systemName: "plus")
            cell.accessoryType = .none
        }else{
            let saved = sampleLists[indexPath.row]
            cell.SavedLabel.text = saved.name
            cell.SavedIcon.image = saved.iconName
            cell.accessoryType = .disclosureIndicator
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Lists"
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == sampleLists.count {
            performSegue(withIdentifier: "NewList", sender: nil)

               }
        else{
            let selectedList = sampleLists[indexPath.row]
            performSegue(withIdentifier: "ShowProductsSegue", sender: selectedList)
        }
       
       
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ShowProductsSegue" {
                if let savedProductsVC = segue.destination as? SavedProductsViewController,
                   let selectedList = sender as? SavedList {
                    savedProductsVC.selectedList = selectedList
                }
            }
        }
}
