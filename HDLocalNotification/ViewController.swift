//
//  ViewController.swift
//  HDLocalNotification
//
//  Created by denglibing on 2016/12/22.
//  Copyright © 2016年 denglibing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    var goAwayTime : String!
    let localNotifiManager = LocalNotifManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goAwayTime = self.getStrTimeFormater(date: Date(), formater: "H:mm")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func LocalNotification(_ sender: Any) {
        localNotifiManager.setLocalNotification(with: goAwayTime, times: 10)
    }

    func getStrTimeFormater ( date : Date, formater : String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = formater
        return formatter.string(from: date)
    }
    
    @IBAction func dateSelect(_ sender: Any) {
        goAwayTime = self.getStrTimeFormater(date: datePicker.date, formater: "H:mm")
    }
}

