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
//    @IBOutlet weak var destinationDistanceLbl: UILabel!
    @IBOutlet weak var splitLbl: UILabel!

    @IBOutlet weak var speedDeltaLbl: UILabel!
    @IBOutlet weak var omStepper: UIStepper!
    
    var speed: Int?
    var speedd: Double?
    var ctc: Double?
    var ctcDate: NSDate?
    var startDistance: Double?
    var controlNumber: Int?
    var startTime: NSDate?
    var todTimer = NSTimer()
    var timeUnit = "seconds"
    var distanceType = "miles"
    var controlZones = [NSManagedObject]()
    var selectedStartDistance = 0.00
    var factor = 1.0000
    var locationTimestamp = NSDate()
    var locationLatitude = ""
    var locationLongitude = ""
    var course: Double?
    var splits = [String]()
    var controlSplits = [NSManagedObject]()
    var carNumber = 0
    var delta = 0.0
    var oldStepper = 0.0


    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        controlNumber = 0
//        speed = 7
        omStepper.maximumValue = 999.99
        omStepper.minimumValue = -999.99
        speedd = 36.0
        self.speedLbl.text = String(format: "%.1f",speedd! as Float64)

        startTime = NSDate()
        startDistance = 0.00
        self.distanceLbl.text = "0.00"
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self,
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


    @IBAction func nextMinuteBtn(sender: AnyObject) {
        self.setStartTimeToCTCPlusOne()
    }
    @IBAction func zeroOdoBtn(sender: AnyObject) {
        let userInfo = ["action":"reset"]
        NSNotificationCenter.defaultCenter().postNotificationName("Reset", object: nil, userInfo: userInfo)
        self.selectedStartDistance = 0.00
        self.distanceLbl.text = "0.00"
    }
    @IBAction func omStepper(sender: UIStepper) {
        if sender.value < oldStepper{
            let userInfo = [
                "action":"minusOne"]
            NSNotificationCenter.defaultCenter().postNotificationName("MinusOne", object: nil, userInfo: userInfo)
            
        }
        else{
            let userInfo = [
                "action":"plusOne"]
            NSNotificationCenter.defaultCenter().postNotificationName("PlusOne", object: nil, userInfo: userInfo)
        }
        oldStepper = sender.value
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

    @IBAction func plusOneBtn(sender: AnyObject) {
        let userInfo = [
            "action":"plusOne"]
        NSNotificationCenter.defaultCenter().postNotificationName("PlusOne", object: nil, userInfo: userInfo)
    }

//    @IBAction func toggleSpeedBtn(sender: AnyObject) {
//        self.speedShortcut()
//    }
//
//    @IBAction func aBtn(sender: AnyObject) {
//        self.nextMinuteShortcut()
//    }
//    
//    @IBAction func bBtn(sender: AnyObject) {
//        self.add10ToStartMinute()
//    }
//
//    @IBAction func xBtn(sender: AnyObject) {
//        self.setStartTimeToCTC()
//    }
//    
//    @IBAction func yBtn(sender: AnyObject) {
//        self.setStartToCurrentMinute()
//    }
    func setStartTimeToCTC() {
        print(self.ctcDate!)
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.ctcDate!)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startDistance = Double(self.distanceLbl.text!)
        self.selectedStartDistance =  self.startDistance!
        self.startTime = self.ctcDate!
        self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"

        print(self.startTime!)
        print(self.startDistance!)
    }
    
    func setStartToCurrentMinute() {
        // set start mileage to /0.00
        let userInfo = ["action":"reset"]
        NSNotificationCenter.defaultCenter().postNotificationName("Reset", object: nil, userInfo: userInfo)
        self.selectedStartDistance = 0.00
        // get current time

        let calendar = NSCalendar.currentCalendar()
        var dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())
        let secondsToSubtract = Double(dateComponents.second * -1)
        
        let dateForCurrentMinute = NSDate().dateByAddingTimeInterval(Double(secondsToSubtract))
        dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: dateForCurrentMinute)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = "00"
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        
        self.startTime = dateForCurrentMinute
        print(self.startTime!)
    }
    
    func setStartTimeToCTCPlusOne() {
        print(self.ctcDate!)
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.ctcDate!)
        let secondsToAdd = 60 - dateComponents.second
        let timePlusOneMinute = self.ctcDate!.dateByAddingTimeInterval(Double(secondsToAdd))
        self.ctcDate = timePlusOneMinute
        self.startTime = self.ctcDate!

//        let minStr = String(format: "%02d", dateComponents.minute)
//        let secStr = "00"
//        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startTimeLbl.text = "\(self.strippedNSDate(ctcDate!))"
        
        self.startDistance = Double(self.distanceLbl.text!)
        self.selectedStartDistance =  self.startDistance!
        self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
        print(self.startTime!)
        print(self.startDistance!)
    }
    
    func nextMinuteShortcut() {
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
    
    func speedShortcut(){
        //        let controllerSpeedChoices = [60.0,75.0,85.0]
        let controllerSpeedChoices = [24.0,30.0,36.0,40.0,45.0,50.0,60.0]
//        let controllerSpeedChoices = [20.0,25.0,30.0,35.0,40.0,45.0,50.0,60.0]
//        let controllerSpeedChoices = [30.0,32.6,36.0]
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
//                self.nextMinuteShortcut()
                self.performSegueWithIdentifier("czsegue", sender: nil)
            }
        }
        controller.gamepad?.buttonB.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonB")
//                self.add10ToStartMinute()
                self.startActions()
            }
        }
        controller.gamepad?.buttonX.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonX")
//                self.setStartTimeToCTC()
                self.navigationController?.popViewControllerAnimated(true)
            }

        }
        controller.gamepad?.buttonY.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonY")
//                self.nextMinuteShortcut()
                self.setStartTimeToCTCPlusOne()
//                self.setStartToCurrentMinute()
//                self.performSegueWithIdentifier("czsegue", sender: self)
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
        controller.gamepad?.dpad.left.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed && value > 0.2 {
                print("dpad.left")
                self.speedShortcut()
            }
        }
        
        controller.gamepad?.dpad.right.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed && value > 0.2 {
                print("dpad.right \(value)")
                self.speedShortcut()
            }
        }
        
        controller.gamepad?.dpad.up.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed && value > 0.2 {
                print("dpad.up \(value)")
                let userInfo = [
                    "action":"plusOne"]
                NSNotificationCenter.defaultCenter().postNotificationName("PlusOne", object: nil, userInfo: userInfo)
            }
        }
        
        controller.gamepad?.dpad.down.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed && value > 0.2 {
                print("dpad.down")
                let userInfo = [
                    "action":"minusOne"]
                NSNotificationCenter.defaultCenter().postNotificationName("MinusOne", object: nil, userInfo: userInfo)
            }
        }

    }


//    Actions


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
//            self.destinationsIndex = 0
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
        self.splitLbl.text = "\(self.todLbl.text!)-\(self.distanceLbl.text!)"
    }
    
    func deltaString() -> String {
        return String(format: "%.0f",delta)
    }
    
    func splitActions() {
        let score = self.deltaString()
        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.locationLatitude),\(self.locationLongitude),\(self.speedd!),\(score)"
        self.splits.insert(splitString, atIndex: 0)
    }
    
    func factorChanged(notification:NSNotification) -> Void{
        let userInfo = notification.userInfo
        let newFactor = userInfo!["factor"]!
        self.factor = Double(newFactor as! NSNumber)
    }
    @IBAction func startBtn(sender: AnyObject) {
        self.startActions()
//        let nm = selectedStartDistance
//        let userInfo = ["newMileage":nm]
//        NSNotificationCenter.defaultCenter().postNotificationName("SetMileage", object: nil, userInfo: userInfo)
    }
    func startActions(){
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
            
            let selectedCZ = self.saveCZ(dvc!.controlNumber,speedd: dvc!.speedd,startTime: dvc!.startTime!, startDistance: dvc!.startDistance)
            self.controlZones.insert(selectedCZ, atIndex: 0)

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
            self.ctcDate = self.startTime
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
        let speedometer = userInfo!["speed"]! as? Double
        if speedometer > 0 {
            self.speedDeltaLbl.text = "\((self.speedd)! - speedometer!)"
        }
        
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
        self.updateDelta()
    }
    
    
    func updateDelta() {
        if startTime != nil {
            if startTime!.timeIntervalSince1970 > NSDate().timeIntervalSince1970 {
                self.ctcLbl.text = "\(self.strippedNSDate(startTime!))"
                delta = startTime!.timeIntervalSinceDate(NSDate())
                self.deltaLbl.textColor = UIColor.blackColor()
                self.deltaLbl.text = ">\(deltaString())"
            }
            if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {
                
                let factor = 60.0/Double(speedd!)
                
                let calcDistance = Double(distanceLbl.text!)! - selectedStartDistance
                
                //              Simple Accumulator
                ctc = calcDistance * factor
                
                
                let ctcSecs = (ctc)! * 60
                //                print("ctcSecs \(ctcSecs)")
                let calendar = NSCalendar.currentCalendar()
                
                ctcDate = calendar.dateByAddingUnit(.Second, value: Int(ctcSecs), toDate: startTime!, options: [])     // used to be `.CalendarUnitMinute`
                
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
                if delta > 600.0 {
                    self.deltaLbl.textColor = UIColor.blackColor()
                    self.deltaLbl.text = "EEEE"
                }
                else if delta < -600.0{
                    self.deltaLbl.textColor = UIColor.blackColor()
                    self.deltaLbl.text = "LLLL"
                }
                else if delta < 0.9 && delta > -0.9 {
                    self.deltaLbl.textColor = UIColor.blueColor()
                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
                    
                else if delta < 4.0 && delta > -4.0 {
                    if delta > 0.0 {self.deltaLbl.textColor = UIColor.redColor()}
                    else {self.deltaLbl.textColor = UIColor.greenColor()}
                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
                else {
                    //                    self.deltaLbl.textColor = UIColor.blackColor()
                    if delta > 0.0 {self.deltaLbl.textColor = UIColor.redColor()}
                    else {self.deltaLbl.textColor = UIColor.greenColor()}
                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
            }
            else {
                //                self.mileageLbl.text = "NA"
            }
        }
    }

//    ---------------------------------------

    
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


}

