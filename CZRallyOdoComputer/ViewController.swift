//
//  ViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
//,UITableViewDelegate, UITableViewDataSource
class ViewController: UIViewController {

    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var todLbl: UILabel!
    @IBOutlet weak var ctcLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var speed: Int?
    var speedd: Double?
    var controlNumber: Int?
    var startTime: NSDate?
    var todTimer = NSTimer()
    var timeUnit = "seconds"
    var distanceType = "miles"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
            selector: "updateTimeLabel", userInfo: nil, repeats: true)
        self.tableView.registerClass(UITableViewCell.self,forCellReuseIdentifier:"cell")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationAvailable:", name: "LOCATION_AVAILABLE", object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    Segue Stuff
    @IBAction func unwindToViewController(sender: UIStoryboardSegue){
        print("unwindSegue \(sender)")
        
        if(sender.sourceViewController.isKindOfClass(CZSegueViewController))
        {
            let dvc = sender.sourceViewController as? CZSegueViewController
            print("\(dvc!.controlNumber)")
            print("\(dvc!.speed)")
            print("\(dvc!.speedd)")
            print("\(dvc!.hour)")
            print("\(dvc!.minute)")
            print("\(dvc!.second)")
            print("\(dvc!.startTime)")
//            self.saveCZ(dvc!.controlNumber,speed: dvc!.speed,startTime: dvc!.startTime!)
//            self.tableView.reloadData()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "czsegue"
        {if let destinationVC = segue.destinationViewController as? CZSegueViewController{
            destinationVC.controlNumber = self.controlNumber
            destinationVC.speedd = self.speedd
            destinationVC.speed = self.speed
            destinationVC.second = 0
            }
        }
    }

//    Distance
    func locationAvailable(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo
        print("Odometer UserInfo: \(userInfo)")
        //print(userInfo!["miles"]!)
        let m = userInfo!["miles"]!
        self.distanceLbl.text = (String(format: "%.2f", m as! Float64))
        
        switch distanceType
        {
        case "miles":
            let m = userInfo!["miles"]!
            self.distanceLbl.text = (String(format: "%.2f", m as! Float64))
            case "km":
            let d = userInfo!["km"]!
            self.distanceLbl.text = (String(format: "%.2f", d as! Float64))
        default:
            break;
        }
//        horrizontalAccuracy.text = String(userInfo!["horizontalAccuracy"]!)
    }

    //    utilities
    
    func updateTimeLabel() {
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        
        let unit = Double(dateComponents.second)
        let second = Int(unit)
        let secondString = String(format: "%02d", second)
        
        let cent = Int((unit * (1.6667)))
        let centString = String(format: "%02d", cent)
        let minuteString = String(format: "%02d", dateComponents.minute)
        switch timeUnit {
        case "seconds":
            todLbl.text = "\(dateComponents.hour):\(minuteString):\(secondString)"
        case "cents":
            todLbl.text = "\(dateComponents.hour):\(minuteString).\(centString)"
        default:
            break;
        }
        if startTime != nil {
            if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {
                let elapsedTime = NSDate().timeIntervalSinceDate(startTime!)
                
                let milesPerMinute = Double(self.speed!)/60.0
                let et = elapsedTime * 1.66667
                let distance = (milesPerMinute * et)/100
                let ss = String(format: "%.2f",distance)
                //                print("dist = \(ss) for \(distance)")
//                self.mileageLbl.text = ss
                
            }
            else {
//                self.mileageLbl.text = "NA"
            }
        }
        
    }
    func strippedNSDate(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: (date))
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        let strippedDate = "\(dateComponents.hour):\(minStr):\(secStr)"
        return strippedDate
    }
    
    func stringFromTimeInterval(interval:NSTimeInterval) -> NSString {
        
        let ti = NSInteger(interval)
        
        //        let ms = Int((interval % 1) * 1000)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
        //        return NSString(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }

}

