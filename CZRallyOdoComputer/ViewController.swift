//
//  ViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var todLbl: UILabel!
    @IBOutlet weak var ctcLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var speedLbl: UILabel!
    @IBOutlet weak var startTimeLbl: UILabel!
    @IBOutlet weak var deltaLbl: UILabel!
    @IBOutlet weak var startDistanceLbl: UILabel!
    
    var speed: Int?
    var speedd: Double?
    var ctc: Double?
    var startDistance: Double?
    var controlNumber: Int?
    var startTime: NSDate?
    var todTimer = NSTimer()
    var timeUnit = "seconds"
    var distanceType = "miles"
    var controlZones = [NSManagedObject]()
    var selectedStartDistance = 0.00
    var factor = 1.0000

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        controlNumber = 0
        speed = 36
        startTime = NSDate()
        startDistance = 0.00
        self.distanceLbl.text = "0.00"
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self,
            selector: "updateTimeLabel", userInfo: nil, repeats: true)
        
        self.tableView.registerClass(UITableViewCell.self,forCellReuseIdentifier:"Cell")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationAvailable:", name: "LOCATION_AVAILABLE", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "factorChanged:", name: "FACTOR_CHANGED", object: nil)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    Actions
    func factorChanged(notification:NSNotification) -> Void{
        let userInfo = notification.userInfo
        let newFactor = userInfo!["factor"]!
        self.factor = Double(newFactor as! NSNumber)
    }
    @IBAction func startBtn(sender: AnyObject) {
        let nm = selectedStartDistance
        let userInfo = [
            "newMileage":nm]
        NSNotificationCenter.defaultCenter().postNotificationName("SetMileage", object: nil, userInfo: userInfo)
    }
    
//    Table Stuff
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("count \(controlZones.count)")
        return controlZones.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            print("index \(indexPath.row)")
            let selectedCZ = controlZones[indexPath.row]
            print("selectedCZ \(selectedCZ)")
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
            print("\(cell)")
            print("\(indexPath.row)")
            
            let cz = controlZones[indexPath.row]
            print("cz \(cz)")
            let sm = cz.valueForKey("startDistance")
            let smStr = String(format: "%.2f", sm as! Float64)
            
            let cn = cz.valueForKey("controlNumber")
            print("cn \(cn!)")
            let spd = cz.valueForKey("speed")
            print("spd \(spd!)")
            let st = self.strippedNSDate(cz.valueForKey("startTime") as! NSDate)
            print("st \(st)")
            cell.textLabel!.text = "\(cn!) \(spd!) \(st) \(smStr)"
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
        let selectedCZ = controlZones[indexPath.row]
        print("selectedCZ \(selectedCZ)")
        print("cn \(selectedCZ.valueForKey("controlNumber")!)")
//        var cn = "Control \(selectedCZ.valueForKey("controlNumber")!)"
//        self.controlNumberLbl.text = cn
        self.speed = selectedCZ.valueForKey("speed")! as? Int
        self.speedLbl.text = "\(selectedCZ.valueForKey("speed")!)"
        
        let sm = selectedCZ.valueForKey("startDistance")!
        let smStr = String(format: "%.2f", sm as! Float64)
        self.startDistanceLbl.text = "\(smStr)"
//        self.startDistanceLbl.text = "\(selectedCZ.valueForKey("startDistance")!)"
        

        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: (selectedCZ.valueForKey("startTime") as? NSDate)!)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startTime = selectedCZ.valueForKey("startTime") as? NSDate
        self.selectedStartDistance = (selectedCZ.valueForKey("startDistance")! as? Double)!
        self.deltaLbl.text = "--"
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // 1
        if editingStyle == .Delete {
            
            // 2
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let moc = appDelegate.managedObjectContext
            
            // 3
            moc.deleteObject(controlZones[indexPath.row])
            appDelegate.saveContext()
            
            // 4
            controlZones.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }
//    Persistence
    func saveCZ(controlNumber: Int,speed: Int, startTime: NSDate, startDistance: Double) {
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let entity =  NSEntityDescription.entityForName("ControlZone",
            inManagedObjectContext:managedContext)
        
        let controlZone = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: managedContext)
        
        //3
        print("save  \(speed) \(controlNumber) \(startTime) \(startDistance)")
        controlZone.setValue(controlNumber, forKey: "controlNumber")
        controlZone.setValue(speed, forKey: "speed")
        controlZone.setValue(Double(speed), forKey: "speedd")
        controlZone.setValue(startTime, forKey: "startTime")
        controlZone.setValue(startDistance, forKey: "startDistance")
        
        //4
        do {
            try managedContext.save()
            //5
            controlZones.append(controlZone)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
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
            print("\(dvc!.startDistance)")
            self.saveCZ(dvc!.controlNumber,speed: dvc!.speed,startTime: dvc!.startTime!, startDistance: dvc!.startDistance)
            self.tableView.reloadData()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier!
        {
        case "czsegue":
            if let destinationVC = segue.destinationViewController as? CZSegueViewController{
                destinationVC.controlNumber = self.controlNumber
                destinationVC.speedd = self.speedd
                destinationVC.speed = self.speed
                destinationVC.second = 0
                destinationVC.startDistance = 0.0
            }
        case "configSegue":
            print("config segue")
        default:
            break;
        }
//        if segue.identifier == "czsegue"
//        {if let destinationVC = segue.destinationViewController as? CZSegueViewController{
//            destinationVC.controlNumber = self.controlNumber
//            destinationVC.speedd = self.speedd
//            destinationVC.speed = self.speed
//            destinationVC.second = 0
//            destinationVC.startDistance = 0.0
//            }
//        }
    }

//    Distance
    func locationAvailable(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo
//        print("Odometer UserInfo: \(userInfo)")
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
//                print("et \(elapsedTime)")
                let factor = 60.0/Double(speed!)
//                print("distance \(Double(distanceLbl.text!))")
                let dist = Double(distanceLbl.text!)
                
                let calcDistance = Double(distanceLbl.text!)! - selectedStartDistance
                print("calc dist \(calcDistance) \(selectedStartDistance)")
                ctc = calcDistance * factor
                let ctcSecs = (calcDistance * factor) * 60
                let ctcDate = calendar.dateByAddingUnit(.Second, value: Int(ctcSecs), toDate: startTime!, options: [])     // used to be `.CalendarUnitMinute`


//                print("ctcDate -> \(self.strippedNSDate(ctcDate!))")
//                print("ctc \(ctc!) for dist \(dist!) \(elapsedTime * 0.0166667)")
//                print("delta \(ctc! - (elapsedTime * 0.0166667))")
//                self.ctcLbl.text = "\(String(format: "%.2f", ctc!))"
                self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
//                let delta = ctc! - (elapsedTime * 0.0166667)
                let delta = ctcDate!.timeIntervalSinceDate(NSDate())
                self.deltaLbl.text = "\(String(format: "%.1f",(delta)))"
            }
            else {
//                self.mileageLbl.text = "NA"
            }
        }
        
    }
    func strippedNSDate(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: date)
        
        
        let unit = Double(dateComponents.second)
        let second = Int(unit)
        let secondString = String(format: "%02d", second)
        
        let cent = Int((unit * (1.6667)))
        let centString = String(format: "%02d", cent)
        let minuteString = String(format: "%02d", dateComponents.minute)
        var todLbl = ""
        switch timeUnit {
        case "seconds":
            todLbl = "\(dateComponents.hour):\(minuteString):\(secondString)"
        case "cents":
            todLbl = "\(dateComponents.hour):\(minuteString).\(centString)"
        default:
            break;
        }
        return todLbl
//        let calendar = NSCalendar.currentCalendar()
//        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: (date))
//        let minStr = String(format: "%02d", dateComponents.minute)
//
//        let secStr = String(format: "%02d", dateComponents.second)
//        let strippedDate = "\(dateComponents.hour):\(minStr):\(secStr)"
//        return strippedDate
    }
    
    func stringFromTimeInterval(interval:NSTimeInterval) -> NSString {
        
        let ti = NSInteger(interval)
        
        //        let ms = Int((interval % 1) * 1000)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%02d:%02d:%02d",hours,minutes,seconds)
        //        return NSString(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }

}

