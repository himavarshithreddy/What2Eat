
import UIKit

class SavedViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet weak var SavedTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SavedTableView.dataSource = self
        SavedTableView.delegate = self
       
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        1
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
                  
            let alertController = UIAlertController(title: "Create New List", message: "Enter a name for your new list.", preferredStyle: .alert)
                   alertController.addTextField { textField in
                       textField.placeholder = "List Name"
                   }
            alertController.view.backgroundColor = UIColor(red: 221, green: 215, blue: 205, alpha: 1)
            alertController.view.tintColor = .orange
            alertController.view.layer.cornerRadius = 14
            alertController.view.layer.masksToBounds = true
                   alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                   alertController.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
                       if let listName = alertController.textFields?.first?.text, !listName.isEmpty {
                           self?.addNewList(with: listName)
                       }
                   })
                   
                   present(alertController, animated: true)
               }
        else{
            let selectedList = sampleLists[indexPath.row]
            performSegue(withIdentifier: "ShowProductsSegue", sender: selectedList)
        }
       
       
    }
    private func addNewList(with name: String) {
        let randomimage = randomlistImages.randomElement() ?? "leaf"
        let randomImageName = UIImage(systemName: randomimage)!
        sampleLists.append(SavedList( id: UUID(),name: name, products: [], iconName: randomImageName))
        SavedTableView.reloadData()
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
