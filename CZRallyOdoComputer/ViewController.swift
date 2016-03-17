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

    @IBOutlet weak var splitBtn: UIButton!
    @IBOutlet weak var factorLbl: UILabel!
    @IBOutlet weak var addTenBtn: UIButton!
    @IBOutlet weak var subTenBtn: UIButton!
    @IBOutlet weak var createCZBtn: UIButton!
    @IBOutlet weak var startBtn: UIButton!
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
    
    @IBOutlet weak var factorStepper: UIStepper!
    
    @IBOutlet weak var speedStepper: UIStepper!
    
    @IBOutlet weak var timeUnitControl: UISegmentedControl!
    
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
    var locationTimestamp = NSDate?()
    var locationLatitude = ""
    var locationLongitude = ""
    var course: Double?
    var splits = [String]()
    var controlSplits = [NSManagedObject]()
    var carNumber = 0
    var delta = 0.0
    var oldStepper = 0.0
    var distance: Double?


    
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
        distance = 0.00
        self.distanceLbl.text = "0.00"
        self.factorLbl.text = "\(self.factor)"
        self.speedStepper.value = self.speedd!
        switch timeUnit
        {
        case "seconds":
            self.timeUnitControl.selectedSegmentIndex=0
        case "cents":
            self.timeUnitControl.selectedSegmentIndex=1
        default:
            break;
        }
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self,
            selector: "updateTimeLabel", userInfo: nil, repeats: true)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationAvailable:", name: "LOCATION_AVAILABLE", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "factorChanged:", name: "FACTOR_CHANGED", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controllerDidConnect:", name: "GCControllerDidConnectNotification", object: nil)
        
//        self.loadTestData()
//        self.loadMileages()
        startBtn.layer.borderColor = UIColor.blueColor().CGColor // Set border color
        startBtn.layer.borderWidth = 1 // Set border width
        startBtn.layer.cornerRadius = 20 // Set borer radius (Make it curved, increase this for a more rounded button
        createCZBtn.layer.borderColor = UIColor.blueColor().CGColor
        createCZBtn.layer.borderWidth = 1
        createCZBtn.layer.cornerRadius = 20
        
        addTenBtn.layer.borderColor = UIColor.blueColor().CGColor
        addTenBtn.layer.borderWidth = 1
        addTenBtn.layer.cornerRadius = 20
        subTenBtn.layer.borderColor = UIColor.blueColor().CGColor
        subTenBtn.layer.borderWidth = 1
        subTenBtn.layer.cornerRadius = 20
        splitBtn.layer.borderColor = UIColor.blueColor().CGColor
        splitBtn.layer.borderWidth = 1
        splitBtn.layer.cornerRadius = 20
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func casBtn(sender: AnyObject) {
        self.setStartTimeToCTC()
        self.splitActions()

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
    
    @IBAction func timeUnitSegmentedControl(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            timeUnit = "seconds"
        case 1:
            timeUnit = "cents"
        default:
            break;
        }

    }
    @IBAction func speedStepper(sender: UIStepper) {
        self.speedd = sender.value
        self.speedLbl.text = String(format: "%.1f",speedd! as Float64)

    }
    
    @IBAction func factorStepper(sender: UIStepper) {
        self.factor = sender.value
        self.factorLbl.text = String(format: "%.4f",self.factor)
        let userInfo = [
            "factor":factor]
        NSNotificationCenter.defaultCenter().postNotificationName("FACTOR_CHANGED", object: nil, userInfo: userInfo)
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

    @IBAction func addTenBtn(sender: AnyObject) {
        self.add10ToStartMinute()
        self.splitActions()
    }
    func add10ToStartMinute(){
        let calendar = NSCalendar.currentCalendar()
        var dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.startTime!)
        
        var secondsToAdd = 10
        if timeUnit == "cents" {
            secondsToAdd = 6
        }
        
        let timePlus10 = self.startTime!.dateByAddingTimeInterval(Double(secondsToAdd))
        dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: timePlus10)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        if timeUnit == "cents" {
            let centStr = String(format: "%02d", Int((Double(dateComponents.second) * 1.66667)))
            self.startTimeLbl.text = "\(dateComponents.hour):\(minStr).\(centStr)"
        } else {
            let secStr = String(format: "%02d", dateComponents.second)
            self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        }
        
        self.startTime = timePlus10
    }
    
    @IBAction func subTenBtn(sender: AnyObject) {
        self.sub10ToStartMinute()
        self.splitActions()
    }
    func sub10ToStartMinute(){
        let calendar = NSCalendar.currentCalendar()
        var dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.startTime!)
        
        var secondsToAdd = -10
        if timeUnit == "cents" {
            secondsToAdd = -6
        }
        
        let timePlus10 = self.startTime!.dateByAddingTimeInterval(Double(secondsToAdd))
        dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: timePlus10)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        if timeUnit == "cents" {
            let centStr = String(format: "%02d", Int((Double(dateComponents.second) * 1.66667)))
            self.startTimeLbl.text = "\(dateComponents.hour):\(minStr).\(centStr)"
        } else {
            let secStr = String(format: "%02d", dateComponents.second)
            self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        }
        
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
    
    func speedShortcut(direction: String){
        //        let controllerSpeedChoices = [60.0,75.0,85.0]
//        let controllerSpeedChoices = [24.0,30.0,36.0,40.0,45.0,50.0,60.0]
        let controllerSpeedChoices = [20.0,25.0,30.0,35.0,36.0,40.0,45.0,50.0,55.0,60.0]
//        let controllerSpeedChoices = [30.0,32.6,36.0]
        var speedIndex = controllerSpeedChoices.indexOf(self.speedd!)
        if speedIndex == nil {
            speedIndex = 0
        }
        print(speedIndex!)
        if direction ==  "plus" {
            speedIndex = speedIndex! + 1
        } else {
            speedIndex = speedIndex! - 1
        }
        if speedIndex == controllerSpeedChoices.count {
            speedIndex = 0
        } else if speedIndex < 0 {
            speedIndex = controllerSpeedChoices.count - 1
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
//                self.navigationController?.popViewControllerAnimated(true)
                self.sub10ToStartMinute()
            }

        }
        controller.gamepad?.buttonY.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed {
                print("buttonY")
                self.add10ToStartMinute()

//                self.nextMinuteShortcut()
//                self.setStartTimeToCTCPlusOne()
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
                self.speedShortcut("minus")
            }
        }
        
        controller.gamepad?.dpad.right.pressedChangedHandler = { (element: GCControllerElement, value: Float, pressed: Bool) in
            if pressed && value > 0.2 {
                print("dpad.right \(value)")
                self.speedShortcut("plus")
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
            self.factorStepper.value = 1.0000
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
        print("split btn")
        print(self.locationLatitude)
        print(self.locationLongitude)
        print(self.course)
        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.locationLatitude),\(self.locationLongitude),\(self.course),\(self.speedd!),\(self.deltaString())"
//        let splitString = "\(self.todLbl.text!),\(self.distanceLbl.text!),\(self.speedd!),\(self.deltaString())"
        self.splits.insert(splitString, atIndex: 0)
        self.splitLbl.text = "\(self.todLbl.text!)-\(self.distanceLbl.text!) \(self.deltaLbl.text!)"
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
        let alert: UIAlertController = UIAlertController(title: "BCZ", message: "Are You sure", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //Do some stuff
        }
        alert.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Do It", style: .Default, handler: { (action: UIAlertAction!) in
            self.startActions()
            self.splitActions()
        })
        alert.addAction(saveAction)
        
        //Present the AlertController
        self.presentViewController(alert, animated: true, completion: nil)
//        self.startActions()
//        self.splitActions()

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
            
            switch self.timeUnit {
            case "seconds":
                self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
            case "cents":
                let cents = Int(Double(dateComponents.second) * 1.66667)
                let centStr = String(format: "%02d",cents)
                self.startTimeLbl.text = "\(dateComponents.hour):\(minStr).\(centStr)"
            default:
                break;
            }
            
//            self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
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
                destinationVC.startDistance = self.distance
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
    
//    Never called!
//    func updateMiles(miles: Double) {
//        
//        self.distanceLbl.text = String(format: "%.2f", miles)
//        
//        switch distanceType
//        {
//        case "miles":
//            let m = miles
//            self.distanceLbl.text = (String(format: "%.2f", m))
//        case "km":
//            let d = miles * 1.66667
//            self.distanceLbl.text = (String(format: "%.2f", d))
//        default:
//            break;
//        }
//        let userInfo = ["newMileage":miles]
//        NSNotificationCenter.defaultCenter().postNotificationName("MilesFixForOc", object: nil, userInfo: userInfo)
//    }
    
    func locationAvailable(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo
        let m = userInfo!["miles"]!
        self.distanceLbl.text = (String(format: "%.2f", m as! Float64))
        let lat = String(format: "%.6f", userInfo!["latitude"]! as! Float64)
        let lon = String(format: "%.6f", userInfo!["longitude"]! as! Float64)
        locationTimestamp = userInfo!["timestamp"]! as? NSDate
        locationLatitude = lat
        locationLongitude = lon
        
//        self.course = userInfo!["course"]! as? Double
        let speedometer = userInfo!["speed"]! as? Double
        if speedometer > 0 {
            if speedometer! > self.speedd! {
                self.speedDeltaLbl.textColor = UIColor.redColor()
            } else if speedometer! < self.speedd! {
                self.speedDeltaLbl.textColor = UIColor.greenColor()
            } else {
                self.speedDeltaLbl.textColor = UIColor.blackColor()
            }
            self.speedDeltaLbl.text = "\((speedometer! - self.speedd!))"
        }
        
        switch distanceType
        {
        case "miles":
            let m = userInfo!["miles"]!
            self.distance = m as? Double
            self.distanceLbl.text = (String(format: "%.2f", m as! Float64))
            case "km":
            let d = userInfo!["km"]!
            self.distance = d as? Double
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
//                delta = startTime!.timeIntervalSinceDate(locationTimestamp!)
                delta = delta + 1.0
                print("\(startTime)  \(NSDate()) \(round(delta)) \(startTime!.timeIntervalSinceNow)")

                let ds = (delta % 60) * 100
                let dc = (ds * 1.66667) / 100
                print("dc \(Int(dc))")
                print("Delta \(delta)")
                self.deltaLbl.textColor = UIColor.blackColor()
                
                switch timeUnit {
                case "seconds":
                    let deltaMins = Int(delta / 60)
                    let deltaUnits = Int(delta % 60)
                    self.deltaLbl.text = ">\(deltaMins):\(String(format: "%02d", (deltaUnits)))"
                case "cents":
                    let deltaMins = Int(delta / 60)
//                    let deltaUnits = Int(delta % 100)
                    let ds = (delta % 60) * 100
                    let deltaUnits = Int((ds * 1.66667) / 100)
                    self.deltaLbl.text = ">\(deltaMins).\(String(format: "%02d",deltaUnits))"
                default:
                    break;
                }
//                else {self.deltaLbl.textColor = UIColor.greenColor()}
//                let deltaMins = Int(delta / 60)
//                let deltaSecs = Int(delta % 60)
//                self.deltaLbl.text = ">\(deltaMins):\(String(format: "%02d", (deltaSecs)))"
//                self.deltaLbl.text = ">\(deltaString())"
            }
            else if locationTimestamp == nil {
                delta = startTime!.timeIntervalSinceDate(NSDate())
                let ds = (delta % 60) * 100
                let dc = (ds * 1.66667) / 100
                print("dc \(Int(dc))")
                print("nil Delta \(delta)")
                self.deltaLbl.textColor = UIColor.blackColor()
                
                switch timeUnit {
                case "seconds":
                    let deltaMins = Int(delta / 60)
                    let deltaUnits = abs(Int(delta % 60))
                    self.deltaLbl.text = "\(deltaMins):\(String(format: "%02d", (deltaUnits)))"
                case "cents":
                    let deltaMins = Int(delta / 60)
                    let ds = (delta % 60) * 100
                    let deltaUnits = abs(Int((ds * 1.66667) / 100))
                    self.deltaLbl.text = "\(deltaMins).\(String(format: "%02d",deltaUnits))"
                default:
                    break;
                }
            }
            else if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {
//                if locationTimestamp == nil {
//                    locationTimestamp = NSDate()
//                }
                let speedFactor = 60.0/Double(speedd!)
                
//                let calcDistance = Double(distanceLbl.text!)! - selectedStartDistance
                let calcDistance = distance! - selectedStartDistance
                
                //              Simple Accumulator
                ctc = calcDistance * speedFactor
                
                
                let ctcSecs = (ctc)! * 60
                //                print("ctcSecs \(ctcSecs)")
                let calendar = NSCalendar.currentCalendar()
                
                ctcDate = calendar.dateByAddingUnit(.Second, value: Int(ctcSecs), toDate: startTime!, options: [])     // used to be `.CalendarUnitMinute`
                
                self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
                //                var delta = 0.0
                switch timeUnit {
                case "seconds":
//                    delta = ctcDate!.timeIntervalSinceDate(NSDate())
                    delta = round(ctcDate!.timeIntervalSinceDate(locationTimestamp!))
                case "cents":
//                    delta = (ctcDate!.timeIntervalSinceDate(NSDate())) * 1.66667
                    delta = round((ctcDate!.timeIntervalSinceDate(locationTimestamp!)) * 1.66667)
                default:
                    break;
                }
//                locationTimestamp = nil
//                print("delta in loc \(delta)")
                if delta > 1200.0 {
                    self.deltaLbl.textColor = UIColor.blackColor()
                    self.deltaLbl.text = "EEEE"
                }
                else if delta < -1200.0{
                    self.deltaLbl.textColor = UIColor.blackColor()
                    self.deltaLbl.text = "LLLL"
                }
//                else if delta < 0.9 && delta > -0.9 {
//                    self.deltaLbl.textColor = UIColor.blueColor()
//                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
//                }
//                else if delta < 4.0 && delta > -4.0 {
//                    if delta > 0.0 {self.deltaLbl.textColor = UIColor.redColor()}
//                    else {self.deltaLbl.textColor = UIColor.greenColor()}
//                    var deltaUnits = delta
//                    if timeUnit == "cents" {
//                        deltaUnits = delta * 1.66667
//                    }
//                    self.deltaLbl.text = "\(String(format: "%.0f",(deltaUnits)))"
//                }
                else if delta < 60.0 && delta > -60.0 && timeUnit == "seconds" {
//                    if delta < 60.0 {self.deltaLbl.textColor = UIColor.redColor()}
//                    else {self.deltaLbl.textColor = UIColor.greenColor()}
//                    var deltaUnits = delta
//                    if timeUnit == "cents" {
////                        deltaUnits = delta * 1.66667
//                        deltaUnits = delta
//                    }
                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
                else if delta < 100.0 && delta > -100.0 && timeUnit == "cents" {
                    //                    if delta < 60.0 {self.deltaLbl.textColor = UIColor.redColor()}
                    //                    else {self.deltaLbl.textColor = UIColor.greenColor()}
//                    var deltaUnits = delta
//                    if timeUnit == "cents" {
//                        //                        deltaUnits = delta * 1.66667
//                        deltaUnits = delta
//                    }
                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
                else {
                    //                    self.deltaLbl.textColor = UIColor.blackColor()
//                    if delta > 0.0 {self.deltaLbl.textColor = UIColor.redColor()}
//                    else {self.deltaLbl.textColor = UIColor.greenColor()}
                    
                    switch timeUnit {
                    case "seconds":
                        let deltaMins = Int(delta / 60)
                        let deltaUnits = abs(Int(delta % 60))
                        self.deltaLbl.text = "\(deltaMins):\(String(format: "%02d", (deltaUnits)))"
                    case "cents":
                        let deltaMins = Int(delta / 100)
                        let deltaUnits = abs(Int(delta % 100))
//                        self.deltaLbl.textAlignment = NSTextAlignment.Right
                        self.deltaLbl.text = "\(deltaMins).\(String(format: "%02d", (deltaUnits)))"
                    default:
                        break;
                    }

                }
            }
            else {
//                                self.distanceLbl.text = "NA"
            }
        }
    }

//    ---------------------------------------
    func secondsToCents(seconds: Int, nano: Int) -> Int {
        let hund = Double((seconds * 10) + nano/100000000) * 1.66667
        return Int(hund)/10
    }
    
    func updateTimeLabel() {
//        self.factorLbl.text = "\(self.factor)"
        self.factorLbl.text = String(format: "%.4f",self.factor)


        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        let unit = Double(dateComponents.second)
        let second = Int(unit)
        let secondString = String(format: "%02d", second)
//        let nanoString = String(format: "%01ld", dateComponents.nanosecond/100000000)

//        let cent = Int((unit * (1.6667)))
        let cent = secondsToCents(second, nano: dateComponents.nanosecond)
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
//        if delta called w/o location
//        locationTimestamp = NSDate()

        self.updateDelta()
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

