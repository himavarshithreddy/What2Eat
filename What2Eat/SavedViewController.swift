//
//  SavedViewController.swift
//  What2Eat
//
//  Created by admin68 on 04/11/24.
//

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
        Savedlists.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCell", for: indexPath) as! SavedCell
       
        if indexPath.row == Savedlists.count {
            cell.SavedLabel.text = "Create new List"
            cell.SavedIcon.image = UIImage(systemName: "plus")
            cell.accessoryType = .none
        }else{
            let saved = Savedlists[indexPath.row]
            cell.SavedLabel.text = saved.name
            cell.SavedIcon.image = saved.icon
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
        if indexPath.row == Savedlists.count {
                  
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
    }
    private func addNewList(with name: String) {
        let randomimage = randomlistImages.randomElement() ?? "leaf"
        let randomImageName = UIImage(systemName: randomimage)!
        Savedlists.append(Saved(name: name, icon: randomImageName))
        SavedTableView.reloadData()
       }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showSavedProduct",
               let destinationVC = segue.destination as? SavedProductsViewController,
               let indexPath = SavedTableView.indexPathForSelectedRow {
                
                // Get the title of the selected item from your data source (e.g., savedItems array)
                let selectedTitle = Savedlists[indexPath.row].name // Replace savedItems with your actual data source
                destinationVC.titleText = selectedTitle
            }
        }
}
