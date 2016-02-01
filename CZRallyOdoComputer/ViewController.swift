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
import GameController


class ViewController: UIViewController {

    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var todLbl: UILabel!
    @IBOutlet weak var ctcLbl: UILabel!
    @IBOutlet weak var speedLbl: UILabel!
    @IBOutlet weak var startTimeLbl: UILabel!
    @IBOutlet weak var deltaLbl: UILabel!
    @IBOutlet weak var startDistanceLbl: UILabel!
    @IBOutlet weak var destinationDistanceLbl: UILabel!
    @IBOutlet weak var splitLbl: UILabel!
    
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
    var lateness = 0.0
    var latenessInCents = 0.0
    var carNumber = 0
    var delta = 0.0
    var ocFound = false
    var ocTime = 0.0
//    var testSpeeds = [33.0,40.0,30.0,30.0,30.0,30.0,35.0,35.0,30.0,30.0]
    var testSpeeds = [Double]()
    var incrementWhenFound = false
    var tpStatus = "odoCheck"


    
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controllerDidConnect:", name: "GCControllerDidConnectNotification", object: nil)
        
//        self.loadTestData()
//        self.loadMileages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func add10ToStartMinute(){
        let calendar = NSCalendar.currentCalendar()
        var dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.startTime!)
        let secondsToAdd = 10
        let timePlus10 = self.startTime!.dateByAddingTimeInterval(Double(secondsToAdd))
        dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: timePlus10)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        
        self.startTime = timePlus10
    }
    
    func roundStartDateToNextMinute(){
        let calendar = NSCalendar.currentCalendar()
        var dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.startTime!)
        let secondsToAdd = 60 - dateComponents.second
        let timePlusOneMinute = self.startTime!.dateByAddingTimeInterval(Double(secondsToAdd))
        dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: timePlusOneMinute)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = "00"
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startTime = timePlusOneMinute
    }
//    Shortcuts

    @IBAction func aBtn(sender: AnyObject) {
        self.aShortcut()
    }
    
    @IBAction func bBtn(sender: AnyObject) {
        self.add10ToStartMinute()
    }

    @IBAction func xBtn(sender: AnyObject) {
        self.xShortcut()
    }
    
    func aShortcut() {
        print("buttonA")
        // set start mileage to /0.00
        let userInfo = ["action":"reset"]
        NSNotificationCenter.defaultCenter().postNotificationName("Reset", object: nil, userInfo: userInfo)
        self.selectedStartDistance = 0.00
        // get current time
        // add one minute
        // make it start time
        let calendar = NSCalendar.currentCalendar()
        var dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())
        let secondsToAdd = 60 - dateComponents.second
        
        let timePlusOneMinute = NSDate().dateByAddingTimeInterval(Double(secondsToAdd))
        dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: timePlusOneMinute)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = "00"
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        
        self.startTime = timePlusOneMinute
        print(self.startTime!)
    }
    
    func xShortcut(){
        //        let controllerSpeedChoices = [60.0,75.0,85.0]
        //        let controllerSpeedChoices = [24.0,30.0.32.6,36.0,40.0,45.0]
        let controllerSpeedChoices = [30.0,32.6,36.0]
        var speedIndex = controllerSpeedChoices.indexOf(self.speedd!)
        if speedIndex == nil {
            speedIndex = 0
        }
        print(speedIndex!)
        if speedIndex == controllerSpeedChoices.count - 1 {
            speedIndex = 0
        }
        else {
            speedIndex = speedIndex! + 1
        }
        print(controllerSpeedChoices[speedIndex!])
        self.speedd = controllerSpeedChoices[speedIndex!]
        self.speedLbl.text = String(format: "%.1f",self.speedd! as Float64)
    }
//    Game Conroller
    func controllerDidConnect(notification: NSNotification) {
        
        let controller = notification.object as! GCController
        print("controller is \(controller)")
        print("game on ")
        print("\(controller.gamepad!.buttonA.pressed)")

        controller.gamepad?.buttonA.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonA \(value)")
                self.aShortcut()
            }
        }
        controller.gamepad?.buttonB.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonB")
                self.add10ToStartMinute()
            }
        }
        controller.gamepad?.buttonX.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonX")
                self.xShortcut()
            }

        }
        controller.gamepad?.buttonY.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonY")
                // add one minute
                // make it start time
            }
        }
        controller.gamepad?.rightShoulder.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("rightShoulder")
                self.splitBtn("now")
            }
        }
    }


//    Actions

    @IBAction func goNowBtn(sender: AnyObject) {
        self.goNow()
    }
//    @IBAction func nextBtn(sender: AnyObject) {
//        self.nextTP()
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
            self.splitLbl.text = "Reset"
            self.destinationsIndex = 0
            self.factor = 1.000
            self.deleteAllData("ControlZone")
            let userInfo = ["action":"reset"]
            self.splits = []
            NSNotificationCenter.defaultCenter().postNotificationName("Reset", object: nil, userInfo: userInfo)
        })
        alert.addAction(saveAction)
        
        //Present the AlertController
        self.presentViewController(alert, animated: true, completion: nil)

    }
   
    @IBAction func splitBtn(sender: AnyObject) {
//        print("split btn")
        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.locationLatitude),\(self.locationLongitude),\(self.course!),\(self.speedd!),\(self.deltaString())"
        self.splits.insert(splitString, atIndex: 0)
        self.splitLbl.text = "\(self.todLbl.text!)"
    }
    
    func deltaString() -> String {
        return String(format: "%.0f",self.delta)
    }
    
    func splitActions() {
//        called when checkpoint found
        let courseString = String(format: "%.0f",self.course!)

        var score = self.deltaString()

        if offCourse {
//            print("sa oc \(lateness)")
            score = String(10)
        }
        else {
            if delta < 0.0 {
//                print(fabs(self.delta))
                lateness = lateness + fabs(self.delta * 0.01)
//                seconds, issue with cents!!
            }
            
        }
        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.locationLatitude),\(self.locationLongitude),\(courseString),\(self.speedd!),\(score)"
        self.splits.insert(splitString, atIndex: 0)

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
        self.tpStatus = "seek"
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
//        print("save  \(speedd) \(speed) \(controlNumber) \(startTime) \(startDistance)")
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
//            print("results \(results.count)")
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
            self.deltaLbl.text = "0.0"
            self.lateness = 0.00
        }
        if(sender.sourceViewController.isKindOfClass(ConfigSegueViewController))
        {
            let dvc = sender.sourceViewController as? ConfigSegueViewController
            print("\(dvc!.factor)")
            print("\(dvc!.distanceType)")
            print("\(dvc!.timeUnit)")
            print("\(dvc!.distances)")
            print("\(dvc!.destinations)")
            print("\(dvc!.speeds)")
            self.distanceType = dvc!.distanceType
            self.timeUnit = dvc!.timeUnit
//            if Import btn then set
            self.destinations = dvc!.destinations
            self.destinationMileages = dvc!.distances
            self.testSpeeds = dvc!.speeds
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
                destinationVC.timeUnit = self.timeUnit
            }
        case "configSegue":
//            print("config segue")
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
    
    func nextTP() {
        destinationsIndex += 1
    }
    
    func updateMiles(miles: Double) {
        
        self.distanceLbl.text = String(format: "%.2f", miles)
        
        switch distanceType
        {
        case "miles":
            let m = miles
            self.distanceLbl.text = (String(format: "%.2f", m))
        case "km":
            let d = miles * 1.66667
            self.distanceLbl.text = (String(format: "%.2f", d))
        default:
            break;
        }
        let userInfo = ["newMileage":miles]
        NSNotificationCenter.defaultCenter().postNotificationName("MilesFixForOc", object: nil, userInfo: userInfo)
    }
    
    func locationAvailable(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo
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
        if destinations.count == 0 {
            return
        }
        
        if destinationsIndex >= destinations.count && destinations.count != 0 {
            let total = parseForTotal(self.splits)
//            Done
            self.splitLbl.text = "\(destinations.count) CPs \(total)"
        }
        else if self.tpStatus == "seek"
        {
            let curentLocation = userInfo!["currentLocation"]! as! CLLocation
            let destinationGPS = destinations[destinationsIndex]
            var destinationDistance = Double?()
        
            destinationDistance = destinationGPS.distanceFromLocation(curentLocation)

            let destinationDistanceString = String(format: "%.2f", destinationDistance!)

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
//Force finding
//            speedd = 100.0
//            if currentOM >= 1.00 {
//                destinationDistance = 10.0
//            }
            if currentOM > destOM && destinationDistance < 80.0 && offCourse == true {
                // Found TP after OC
                print("Found TP after OC")
                ocFound = true
                self.tpStatus = "found"
                self.splitLbl.text = "Found \(destinationsIndex)"
//                correct using correct mileage - 80m for early find (.02-05?)
                let correctedOM = destinationMileages[destinationsIndex] - 0.04
                self.updateMiles(correctedOM)
                self.splitActions()
                offCourse = false
//                destinationsIndex += 1
                if incrementWhenFound == true {
                    self.nextTP()
                    self.tpStatus = "seek"
                } else {
                    self.tpStatus = "found"
                }
            }
            else if currentOM >= destOM && destinationDistance < 80.0 {
                // Normal on course
                self.splitActions()
                self.splitLbl.text = "OM \(destinationsIndex) \(self.distanceLbl.text!) \(self.deltaString())"
//            NSNotificationCenter.defaultCenter().postNotificationName("SetMileage", object: nil, userInfo: userInfo)
                approachState = "increasing"
                
//                destinationsIndex += 1
                if incrementWhenFound == true {
                    self.nextTP()
                    self.tpStatus = "seek"
                } else {
                    self.tpStatus = "found"
                    self.destinationDistanceLbl.text = tpStatus

                }
            }
            else if currentOM > destOM && destinationDistance > 160.0 && incrementWhenFound == true && self.tpStatus == "seek"
            {
                // we are off course
                self.offCourse = true
                self.splitLbl.text = "Off Course!"
            }
            else if destinationDistance < zone && approachState == "decreasing" {
//                Found control via GPS proximity and decreasing
                if currentOM < destOM {
//                    ignore, wait for mileage to come up
                }
                else if currentOM >= destOM {
                    self.splitActions()
                    self.splitLbl.text = "GPS \(destinationsIndex) \(self.distanceLbl.text!) \(destinationDistance)"
                    approachState = "increasing"
//                    destinationsIndex += 1
                    if incrementWhenFound == true {
                        self.nextTP()
                    }
                    self.splitLbl.text = "Found by GPS"

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
            previousDestinationDistance = destinationDistance!
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
            todLbl.text = "\(dateComponents.hour):\(minuteString):\(secondString).\(nanoString)"

        case "cents":
            todLbl.text = "\(dateComponents.hour):\(minuteString).\(centString)"
        default:
            break;
        }
        
        if startTime != nil {
            if startTime!.timeIntervalSince1970 > NSDate().timeIntervalSince1970 {
                self.ctcLbl.text = "\(self.strippedNSDate(startTime!))"
                delta = startTime!.timeIntervalSinceDate(NSDate())
                self.deltaLbl.text = ">\(deltaString())"
            }
            if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {

                let factor = 60.0/Double(speedd!)
                
                let calcDistance = Double(distanceLbl.text!)! - selectedStartDistance

                //              Simple Accumulator
                ctc = calcDistance * factor
                
                if destinationsIndex < destinationMileages.count  {
                    if calcDistance > destinationMileages[destinationsIndex] + 0.05 {
                        // ocTime it the calculated time to be where you are given you were off course
                        // would need to compare with actual time to see how late you are in order to adjust lateness fully
                        let ocDist = calcDistance - destinationMileages[destinationsIndex]
                            ocTime = ocDist * factor
//                        print("calc thinks you are off course \(ocTime)")
                    }
                    
                }
                if ocFound == true {
//                    print("oc found in calc \(ocTime) \(calcDistance)")
                    let actualTimeInterval = NSDate().timeIntervalSinceDate(startTime!)
                    //If off course and late
                    if actualTimeInterval > ((ctc)! * 60) {
//                        print(actualTimeInterval)
//                        print(ctc)
//                        print((ctc)! * 60)
                        ocTime = (actualTimeInterval - ((ctc)! * 60))
//                        print(ocTime)
                    }
                    ocFound = false
                    lateness = lateness + ocTime/100.0
                    
                    ocTime = 0.0
//                    print(lateness)
//                    print(ctc)
                }
                if lateness > 0.00 {
//                    latenessInCents = lateness * 0.0166667
                    latenessInCents = lateness * 1.66667
                    ctc = ctc! + latenessInCents
//                    print("lateness \(lateness) \(latenessInCents)")
                }
//                print(ctc)
                let ctcSecs = (ctc)! * 60
//                print("ctcSecs \(ctcSecs)")

                let ctcDate = calendar.dateByAddingUnit(.Second, value: Int(ctcSecs), toDate: startTime!, options: [])     // used to be `.CalendarUnitMinute`

                self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
//                var delta = 0.0
                switch timeUnit {
                case "seconds":
                    delta = ctcDate!.timeIntervalSinceDate(NSDate())
                case "cents":
                    delta = (ctcDate!.timeIntervalSinceDate(NSDate())) * 1.66667
                default:
                    break;
                }
                if delta < 4.0 {
                    self.deltaLbl.text = "\(String(format: "%.1f",(self.delta)))"
                }
                else {
                    self.deltaLbl.text = "\(String(format: "%.0f",(self.delta)))"
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
    
    func goNow() {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startTime = NSDate()
        self.deltaLbl.text = "0.0"
        let userInfo = ["action":"reset"]
        NSNotificationCenter.defaultCenter().postNotificationName("Reset", object: nil, userInfo: userInfo)
//        self.speedd = testSpeeds[destinationsIndex]
//        self.speedd = self.testSpeeds[destinationsIndex]
//        self.speedLbl.text = String(format: "%.1f",speedd! as Float64)
        let smStr = String(format: "%.2f", 0.00)
        self.startDistanceLbl.text = "\(smStr)"
//        self.splitLbl.text = "GoNow"
        self.lateness = 0.00
        
        switch tpStatus
        {
        case "odoCheck":
            break
        case "found":
            self.nextTP()
        case "seek":
            break
        default:
            break;
        }
        self.tpStatus = "seek"
        self.splitLbl.text = "GoNow \(tpStatus) \(destinationsIndex)"
        if testSpeeds.count > 0 {
            self.speedd = self.testSpeeds[destinationsIndex]
            self.speedLbl.text = String(format: "%.1f",speedd! as Float64)
        }
        // otherwise stay at current speed
     
        
    }
    
    func parseForTotal(content: [String]) -> Int{
        var totalScore = 0
        let delimiter = ","
        for line in content {
//            print("line \(line)")
            var values:[String] = []
            if line != "" {
                values = line.componentsSeparatedByString(delimiter)
                // Put the values into the tuple and add it to the items array
                let item = (time: values[0], om: values[1], latitude: values[2],longitude:values[3],course:values[4],speed:values[5],score:values[6])
//                print("\(item)")
//                print("Score: \(item.score)")
                totalScore = totalScore + abs(Int(item.score)!)
            }
        }
//        print(totalScore)
        return totalScore
    }

//    
//    func httpGet(request: NSURLRequest!, callback: (String, String?) -> Void) {
//        let session = NSURLSession.sharedSession()
//        let task = session.dataTaskWithRequest(request){
//            (data, response, error) -> Void in
//            if error != nil {
//                callback("", error!.localizedDescription)
//            }
//            else {
//                let result = NSString(data: data!, encoding:
//                    NSASCIIStringEncoding)!
//                callback(result as String, nil)
//            }
//        }
//        task.resume()
//    }
//    
//    func loadSinatra(){
//        let request = NSMutableURLRequest(URL: NSURL(string: "http://localhost:4567/")!)
//        httpGet(request){
//            (data, error) -> Void in
//            if error != nil {
//                print(error)
//            } else {
//                self.parse(data)
//            }
//        }
//
//    }
//    
//    func parse(content: String) {
//        var score = 0
//        print(content)
//        var gpsLocations = [CLLocation]()
//        var omLocations = [Double]()
//        let delimiter = ","
////        var items:[(time:String, om:String, latitude: String,longitude: String,course: String,speed: String,score:String)]?
//        let lines:[String] = content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) as [String]
//        print("lines count \(lines.count)")
//        print("lines  \(lines)")
//        for line in lines {
//            print("line \(line)")
//            var values:[String] = []
//            if line != "" {
//                values = line.componentsSeparatedByString(delimiter)
//                // Put the values into the tuple and add it to the items array
//                let item = (time: values[0], om: values[1], latitude: values[2],longitude:values[3],course:values[4],speed:values[5],score:values[6])
//                print("\(item)")
//                let location = CLLocation.init(latitude: Double(item.latitude)!, longitude: Double(item.longitude)!)
//                gpsLocations.insert(location, atIndex: 0)
//                print(gpsLocations)
//                omLocations.insert(Double(item.om)!, atIndex: 0)
//                print(omLocations)
//                print("Score: \(item.score) \(score += score)")
//                
//                
//            }
//        }
//    }
//    

}

