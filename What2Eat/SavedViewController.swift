
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
