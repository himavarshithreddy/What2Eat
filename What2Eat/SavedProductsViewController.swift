//
//  SavedProductsViewController.swift
//  What2Eat
//
//  Created by sumanaswi on 05/11/24.
//

import UIKit

class SavedProductsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var SavedProductsTableView: UITableView!
    var titleText: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = titleText
        SavedProductsTableView.delegate = self
        SavedProductsTableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sampleLists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedProductsCell", for: indexPath) as! SavedProductsCell
        let product = sampleLists[indexPath.row]
        if product.score < 40 {
           
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
        }
        else if product.score < 75 {
        
            cell.ScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
        }
        else if product.score < 100 {
            cell.ScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
        }
        cell.SavedProductsName.text = product.name
        cell.SavedProductsImage.image = UIImage(named: product.image)
        cell.Scoretext.text = String(product.score)
        cell.ScoreCircle.layer.cornerRadius = 20
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
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
