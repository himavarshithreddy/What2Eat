//
//  SummaryViewController.swift
//  What2Eat
//
//  Created by admin68 on 03/11/24.
//

import UIKit

class SummaryViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var AlertView: UIView!
    @IBOutlet weak var AlertTableView: UITableView!
    @IBOutlet weak var SummaryTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        SummaryTableView.dataSource = self
        SummaryTableView.delegate = self
        AlertTableView.dataSource = self
        AlertTableView.delegate = self
        
        let AlertViewHeight = CGFloat(alerts.count*25+38)
        var redViewFrame = AlertView.frame
        redViewFrame.size.height = AlertViewHeight
        AlertView.frame = redViewFrame
        

        
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            return NutritionFacts.count
               } else if tableView.tag == 2 {
                  
                   return alerts.count
               }
               return 0

       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HighlightsCell", for: indexPath) as! HighlightsCell
            let highlights = NutritionFacts[indexPath.row]
            cell.HighlightText.text = highlights.text
            cell.iconImage.image = highlights.icon
            cell.iconImage.tintColor = highlights.iconColor
            if highlights.iconColor == .systemRed {
                cell.HighlightText.textColor = .red
            }
            
            
            return cell
        }else if tableView.tag == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell", for: indexPath) as! AlertCell
            let alert = alerts[indexPath.row]
            cell.AlertText.text = alert.text
            return cell
        }else {return UITableViewCell()}
            
        
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 1 {
            return 40
        }
        else if tableView.tag == 2 {
            return 25
        }
        else {return 0}
        
    }
    
    

}
