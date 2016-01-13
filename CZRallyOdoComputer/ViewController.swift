//
//  ViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation


class ViewController: UIViewController {

    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var todLbl: UILabel!
    @IBOutlet weak var ctcLbl: UILabel!
    @IBOutlet weak var speedLbl: UILabel!
    @IBOutlet weak var startTimeLbl: UILabel!
    @IBOutlet weak var deltaLbl: UILabel!
    @IBOutlet weak var startDistanceLbl: UILabel!
    
    @IBOutlet weak var splitBbl: UILabel!
    
    @IBOutlet weak var destinationDistanceLbl: UILabel!
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
    var destinations = [CLLocation]()
    var destinationsIndex = 0
    var czIndex = 0
    var selectedStartDistance = 0.00
    var factor = 1.0000
    var locationTimestamp = NSDate()
    var locationLatitude = ""
    var locationLongitude = ""
    var course: Double?
    var splits = [String]()
    var controlSplits = [NSManagedObject]()
    var approachState = "decreasing"
    var previousDestinationDistance = 0.0
    var previousDestinationDistanceGPS = CLLocation()
    var destinationMileages = [Double]()
    var offCourse = false
    var deltaFixup = 0.0
    
    let testSpeeds = [40.0,30.0,30.0,30.0,30.0,35.0,35.0,30.0,30.0]


    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        controlNumber = 0
//        speed = 7
        speedd = 36.0
        self.speedLbl.text = String(format: "%.1f",speedd! as Float64)

        startTime = NSDate()
        startDistance = 0.00
        self.distanceLbl.text = "0.00"
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
            selector: "updateTimeLabel", userInfo: nil, repeats: true)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationAvailable:", name: "LOCATION_AVAILABLE", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "factorChanged:", name: "FACTOR_CHANGED", object: nil)
        
        self.loadTestData()
        self.loadMileages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    Actions

    @IBAction func nextBtn(sender: AnyObject) {
        destinationsIndex += 1
    }
//    @IBAction func testBtn(sender: AnyObject) {
//        let userInfo = ["newMileage":self.destinationMileages[destinationsIndex] - 0.02]
//        NSNotificationCenter.defaultCenter().postNotificationName("SetMileage", object: nil, userInfo: userInfo)
//    }
    @IBAction func resetBtn(sender: AnyObject) {
        
        //print("Set Factor Btn pushed")
        //Create the AlertController
        let alert: UIAlertController = UIAlertController(title: "Reset", message: "Are You sure", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //Do some stuff
        }
        alert.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Do It", style: .Default, handler: { (action: UIAlertAction!) in
            self.splitBbl.text = "Reset"
            self.destinationsIndex = 0
            self.factor = 1.000
            self.deleteAllData("ControlZone")
            let userInfo = ["action":"reset"]
            self.splits = []
            NSNotificationCenter.defaultCenter().postNotificationName("Reset", object: nil, userInfo: userInfo)        })
        alert.addAction(saveAction)
        
        //Present the AlertController
        self.presentViewController(alert, animated: true, completion: nil)

    }
   

    @IBAction func splitBtn(sender: AnyObject) {
        print("split btn")
        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.locationLatitude),\(self.locationLongitude),\(self.course!),\(self.speedd!),\(self.deltaLbl.text!)"
        self.splits.insert(splitString, atIndex: 0)
        self.splitBbl.text = "\(self.todLbl.text!)"
        
    }
    
    func splitActions() {
        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.locationLatitude),\(self.locationLongitude),\(self.course!),\(self.speedd!),\(self.deltaLbl.text!)"
        self.splits.insert(splitString, atIndex: 0)
        self.splitBbl.text = "\(self.todLbl.text!)"
        print(splitString)

    }
    
    func factorChanged(notification:NSNotification) -> Void{
        let userInfo = notification.userInfo
        let newFactor = userInfo!["factor"]!
        self.factor = Double(newFactor as! NSNumber)
    }
    @IBAction func startBtn(sender: AnyObject) {
        let nm = selectedStartDistance
        let userInfo = ["newMileage":nm]
        NSNotificationCenter.defaultCenter().postNotificationName("SetMileage", object: nil, userInfo: userInfo)
    }
    
//    Persistence
    func saveCZ(controlNumber: Int, speedd: Double, startTime: NSDate, startDistance: Double) -> NSManagedObject {
        
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
        print("save  \(speedd) \(speed) \(controlNumber) \(startTime) \(startDistance)")
        controlZone.setValue(controlNumber, forKey: "controlNumber")
//        controlZone.setValue(speed, forKey: "speed")
        controlZone.setValue(speedd, forKey: "speedd")
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
        return controlZone

    }
    
    func saveControlSplit() -> NSManagedObject {
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let entity =  NSEntityDescription.entityForName("ControlSplit",
            inManagedObjectContext:managedContext)
        
        let controlSplit = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: managedContext)
        
        //3
        controlSplit.setValue(self.speedLbl.text!, forKey: "speed")
        controlSplit.setValue(self.locationTimestamp, forKey: "tod")
        controlSplit.setValue(self.locationLatitude, forKey: "latitude")
        controlSplit.setValue(self.locationLongitude, forKey: "longitude")
        controlSplit.setValue(self.distanceLbl.text, forKey: "odo")
        controlSplit.setValue(self.deltaLbl.text!, forKey: "delta")
        
        //4
        do {
            try managedContext.save()
            //5
            controlSplits.append(controlSplit)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        return controlSplit
        
    }
    
    func deleteAllData(entity: String)
    {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            print("results \(results.count)")
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedContext.deleteObject(managedObjectData)
                appDelegate.saveContext()

            }
            controlZones = []
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }

    
//    Segue Stuff
    @IBAction func unwindToViewController(sender: UIStoryboardSegue){
//        print("unwindSegue \(sender)")
        
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
            
            let selectedCZ = self.saveCZ(dvc!.controlNumber,speedd: dvc!.speedd,startTime: dvc!.startTime!, startDistance: dvc!.startDistance)
            self.controlZones.insert(selectedCZ, atIndex: 0)
//            self.speedd = selectedCZ.valueForKey("speedd")! as? Double
            //            let selectedSpeed = selectedCZ.valueForKey("speedd")!
            self.speedd = dvc!.speedd
            let selectedSpeed = selectedCZ.valueForKey("speedd")!
            
            self.speedLbl.text = String(format: "%.1f",selectedSpeed as! Float64)
            
            let sm = selectedCZ.valueForKey("startDistance")!
            let smStr = String(format: "%.2f", sm as! Float64)
            self.startDistanceLbl.text = "\(smStr)"
            
            
            let calendar = NSCalendar.currentCalendar()
            let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: (selectedCZ.valueForKey("startTime") as? NSDate)!)
            
            let minStr = String(format: "%02d", dateComponents.minute)
            let secStr = String(format: "%02d", dateComponents.second)
            self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
            self.startTime = selectedCZ.valueForKey("startTime") as? NSDate
            self.selectedStartDistance = (selectedCZ.valueForKey("startDistance")! as? Double)!
            self.deltaLbl.text = "--"
            
        }
        if(sender.sourceViewController.isKindOfClass(ConfigSegueViewController))
        {
            let dvc = sender.sourceViewController as? ConfigSegueViewController
            print("\(dvc!.factor)")
            print("\(dvc!.distanceType)")
            print("\(dvc!.timeUnit)")
            self.distanceType = dvc!.distanceType
            self.timeUnit = dvc!.timeUnit

//            if dvc!.clearAllSwitch.on == true {
//                print("Delete!")
//                self.deleteAllData("ControlZone")
//                self.tableView.reloadData()

//            }
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
            if let configVC = segue.destinationViewController as? ConfigSegueViewController{
                configVC.factor = self.factor
                configVC.timeUnit = self.timeUnit
                configVC.distanceType = self.distanceType
            }
        case "SplitsSegue":
            print("SplitsSegue")
            if let splitsVC = segue.destinationViewController as? SplitsSegueViewController{
                splitsVC.splits = self.splits
            }
        default:
            break;
        }

    }

//    Updating Distance & Time
    
    func locationAvailable(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo
//        print("Odometer UserInfo: \(userInfo)")
//        print(userInfo!)
        let m = userInfo!["miles"]!
        self.distanceLbl.text = (String(format: "%.2f", m as! Float64))
        let lat = String(format: "%.6f", userInfo!["latitude"]! as! Float64)
        let lon = String(format: "%.6f", userInfo!["longitude"]! as! Float64)
        locationTimestamp = userInfo!["timestamp"]! as! NSDate
        locationLatitude = lat
        locationLongitude = lon
        
        self.course = userInfo!["course"]! as? Double
        
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
        
        self.workerlessControl(notification)
//        horrizontalAccuracy.text = String(userInfo!["horizontalAccuracy"]!)
    }
//    ---------------------------------------
    func workerlessControl(notification:NSNotification) {
        let userInfo = notification.userInfo
//        if let locs = userInfo?["locations"] {
//            print("locations: \(locs)")
//        }
        
        if destinationsIndex >= destinations.count {
//            Done
            self.splitBbl.text = "\(destinations.count) CPs"
        }
        else {
            let curentLocation = userInfo!["currentLocation"]! as! CLLocation
            let destinationGPS = destinations[destinationsIndex]
            let destinationDistance = destinationGPS.distanceFromLocation(curentLocation)
            
            let destinationDistanceString = String(format: "%.2f", destinationDistance)
            self.destinationDistanceLbl.text = destinationDistanceString
            
            let zone = 20.0
//            if curentLocation.speed > 40.0 {
//                zone = 30.0
//            }
            
            let currentOM = userInfo!["miles"]! as! Double
            let destOM = destinationMileages[destinationsIndex] - 0.005
            
            if currentOM < destOM {
                approachState = "decreasing"
            }
//            && destinationDistance < 200.0
            if currentOM >= destOM && destinationDistance < 80.0 {
                self.splitActions()
                self.splitBbl.text = "OM \(destinationsIndex) \(self.distanceLbl.text!) \(destinationDistance)"
                approachState = "increasing"
//                
//                self.speedd = testSpeeds[destinationsIndex]
//                self.speedLbl.text = String(format: "%0.1f", self.speedd!)
                print("\(self.speedd) \(testSpeeds[destinationsIndex])")
                    
//                off course
                if currentOM + 0.20 > destOM && offCourse == true {
                    let nm = self.destinationMileages[destinationsIndex]
                    let userInfo = ["newMileage":nm]
                    NSNotificationCenter.defaultCenter().postNotificationName("SetMileage", object: nil, userInfo: userInfo)
                    deltaFixup = Double(deltaLbl.text!)!
                }
                destinationsIndex += 1
            }
            else if destinationDistance < zone && approachState == "decreasing" {
//                Found control via GPS proximity and decreasing
                if currentOM < destOM {
//                    ignore, wait for mileage to come up
                }
                else if currentOM >= destOM {
                    self.splitActions()
                    self.splitBbl.text = "GPS \(destinationsIndex) \(self.distanceLbl.text!) \(destinationDistance)"
                    approachState = "increasing"
                    destinationsIndex += 1
                }
            }
            else if currentOM < destOM {
                approachState = "decreasing"
            }

            else if previousDestinationDistance > destinationDistance {
                approachState = "decreasing"
//                previousDestinationDistanceGPS = curentLocation
            }
            else if previousDestinationDistance < destinationDistance {
                if approachState == "decreasing" {
                    if destinationDistance < 60.0 {
                        //                    let pTS = previousDestinationDistanceGPS.timestamp
                        //                    let pTSS = strippedNSDate(pTS)
                        //                    self.splits.insert("prev \(pTSS)", atIndex:0)
                        //                    self.splits.insert("clock \(self.todLbl.text!)", atIndex: 0)
                        //                    self.splitTable.reloadData()
                    }
                }
                approachState = "increasing"
            }
            else {
                
            }
            previousDestinationDistance = destinationDistance
            previousDestinationDistanceGPS = curentLocation
        }
    }

    
    func updateTimeLabel() {
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        
        let unit = Double(dateComponents.second)
        let second = Int(unit)
        let secondString = String(format: "%02d", second)
        let nanoString = String(format: "%01ld", dateComponents.nanosecond/100000000)

        let cent = Int((unit * (1.6667)))
        let centString = String(format: "%02d", cent)
        let minuteString = String(format: "%02d", dateComponents.minute)
        
        switch timeUnit {
        case "seconds":
//            todLbl.text = "\(dateComponents.hour):\(minuteString):\(secondString)"
            todLbl.text = "\(dateComponents.hour):\(minuteString):\(secondString).\(nanoString)"

        case "cents":
            todLbl.text = "\(dateComponents.hour):\(minuteString).\(centString)"
        default:
            break;
        }
        
        if startTime != nil {
            if startTime!.timeIntervalSince1970 > NSDate().timeIntervalSince1970 {
                self.ctcLbl.text = "\(self.strippedNSDate(startTime!))"
//                delta = startTime!.timeIntervalSinceDate(NSDate())
                self.deltaLbl.text = ">\(String(format: "%.0f",(startTime!.timeIntervalSinceDate(NSDate()))))"
            }
            if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {

                let factor = 60.0/Double(speedd!)
                
                let calcDistance = Double(distanceLbl.text!)! - selectedStartDistance

                //              Simple Accumulator
                ctc = calcDistance * factor
                
                let ctcSecs = (calcDistance * factor) * 60
                let ctcDate = calendar.dateByAddingUnit(.Second, value: Int(ctcSecs), toDate: startTime!, options: [])     // used to be `.CalendarUnitMinute`

                self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
                var delta = 0.0
                switch timeUnit {
                case "seconds":
                    delta = ctcDate!.timeIntervalSinceDate(NSDate())
                case "cents":
                    delta = (ctcDate!.timeIntervalSinceDate(NSDate())) * 1.66667
                default:
                    break;
                }
                delta += deltaFixup
                if delta < 4.0 {
                    self.deltaLbl.text = "\(String(format: "%.1f",(delta)))"
                }
                else {
                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
            }
            else {
//                self.mileageLbl.text = "NA"
            }
        }
        
    }
    //    utilities

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
    
    func loadTestData() {
        destinations.append(CLLocation.init(latitude: 44.850577,longitude: -93.373782))
        destinations.append(CLLocation.init(latitude: 44.828991,longitude: -93.383468))
        destinations.append(CLLocation.init(latitude: 44.834211,longitude: -93.385792))
//        destinations.append(CLLocation.init(latitude: 44.837996,longitude: -93.388539))
        destinations.append(CLLocation.init(latitude: 44.837922,longitude: -93.388561))
        destinations.append(CLLocation.init(latitude: 44.843490,longitude: -93.389915))
        destinations.append(CLLocation.init(latitude: 44.853218,longitude: -93.388265))
        destinations.append(CLLocation.init(latitude: 44.854725,longitude: -93.381925))
        destinations.append(CLLocation.init(latitude: 44.850304,longitude: -93.375656))
        destinations.append(CLLocation.init(latitude: 44.851665,longitude: -93.379417))
//44.837922, -93.388561
//        44.843546,-93.389845 google 4
//        44.834211,-93.385792
//        44.851665,-93.379417
//        44.849608,-93.376230
//        44.854725,-93.381925
//        44.853218,-93.388265
//        44.843490,-93.389915
//        44.837996,-93.388539
//        44.834268,-93.385819
//        44.828991,-93.383468
//        44.850577,-93.373782
//        dest = CLLocation.init(latitude: latitude!,longitude: longitude!)
    }
    
    func loadMileages() {
//        self.destinationMileages = [0.74,2.74,3.12,3.43,3.90,4.61,4.98,6.09]
        self.destinationMileages = [0.74,2.74,3.12,3.43,3.90,4.61,4.98,5.79,6.09]
//        10:00:04,6.09,44.851665,-93.379417,355.78125,30.0
//        9:59:30,5.84,44.849608,-93.376230,230.9765625,30.0
//        9:57:51,4.98,44.854725,-93.381925,86.1328125,30.0
//        9:57:05,4.61,44.853218,-93.388265,27.7734375,30.0
//        9:55:47,3.90,44.843490,-93.389915,25.3125,30.0
//        9:54:46,3.43,44.837996,-93.388539,0.3515625,30.0
//        9:54:04,3.12,44.834268,-93.385819,346.2890625,30.0
//        9:53:16,2.74,44.828991,-93.383468,329.765625,30.0
//        9:50:00,0.74,44.850577,-93.373782,91.0546875,30.0
    }
    

}

