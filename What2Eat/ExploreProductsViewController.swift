//
//  ExploreProductsViewController.swift
//  What2Eat
//
//  Created by admin20 on 05/11/24.
//

import UIKit

class ExploreProductsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var titletext: String?
    var ExploreProductslist: [Product] = []
    
    @IBOutlet weak var ExploreProductsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
     ExploreProductsTableView.delegate = self
     ExploreProductsTableView.dataSource = self
        self.navigationItem.title = titletext
        ExploreProductslist = sampleProducts
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ExploreProductslist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExploreProductsCell", for: indexPath) as! ExploreProductsCell
        let product = ExploreProductslist[indexPath.row]
        if product.healthScore < 40 {
                   cell.ExploreScoreCircle.layer.backgroundColor = UIColor.systemRed.cgColor
                }
                else if product.healthScore < 75 {
                
                    cell.ExploreScoreCircle.layer.backgroundColor = UIColor(red: 255/255, green: 170/255, blue: 0/255, alpha: 1).cgColor
                }
                else if product.healthScore < 100 {
                    cell.ExploreScoreCircle.layer.backgroundColor = UIColor.systemGreen.cgColor
                }
        
        cell.ExploreProductsName.text = product.name
        cell.ExploreProductsImage.image = UIImage(named: product.imageURL)
        cell.ExploreScoreCircle.layer.cornerRadius = 20
        cell.ExploreScoretext.text = String(product.healthScore)
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
