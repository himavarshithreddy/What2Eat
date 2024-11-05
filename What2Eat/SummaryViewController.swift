//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit

class SummaryViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var SummaryTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        SummaryTableView.dataSource = self
        SummaryTableView.delegate = self

        // Do any additional setup after loading the view.
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return NutritionFacts.count

       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsCell", for: indexPath) as! HighlightsCell
            let highlights = NutritionFacts[indexPath.row]
            cell.HighlightText.text = highlights.text
            cell.iconImage.image = highlights.icon
            cell.iconImage.tintColor = highlights.iconColor
        if highlights.iconColor == .systemRed {
            cell.HighlightText.textColor = highlights.iconColor
        }

        
            return cell
           
            
        
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

            return 40
     
        
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
