//
//  HomeViewController.swift
//  What2Eat
//
//  Created by admin68 on 19/11/24.
//

import UIKit
import WebKit

class HomeViewController: UIViewController {

   
    @IBOutlet var HomeImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        HomeImage.transform = CGAffineTransform(rotationAngle: .pi*1.833)

        // Do any additional setup after loading the view.
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
