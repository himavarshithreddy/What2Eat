//
//  ProfileViewController.swift
//  What2Eat
//
//  Created by admin20 on 18/11/24.
//

import UIKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let options = ["Edit Health Info", "Edit Personal Info"]
        let icons = ["square.and.pencil", "person.text.rectangle"]
    

    @IBOutlet weak var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self
        // Do any additional setup after loading the view.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        
        // Configure text
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.textColor = UIColor.black // Set the text color to orange
        
        // Configure icon
        cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        cell.imageView?.tintColor = UIColor.gray // Set icon color (optional)
        
        

        return cell
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
