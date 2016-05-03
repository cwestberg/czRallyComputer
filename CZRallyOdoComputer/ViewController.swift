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
    
    @IBOutlet weak var microStepper: UIStepper!
    @IBOutlet weak var factorStepper: UIStepper!
    
    @IBOutlet weak var speedStepper: UIStepper!
    
    @IBOutlet weak var hourStepper: UIStepper!
    @IBOutlet weak var minuteStepper: UIStepper!
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
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    


    var keys = [UIKeyCommand]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        delegate?.coreLocationController?.xgpsConnected = (delegate?.xgps160!.isConnected)!
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
        self.startDistanceLbl.text = "\(startDistance!)"

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
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self,
            selector: #selector(ViewController.updateTimeLabel), userInfo: nil, repeats: true)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.locationAvailable(_:)), name: "LOCATION_AVAILABLE", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.factorChanged(_:)), name: "FACTOR_CHANGED", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.controllerDidConnect(_:)), name: "GCControllerDidConnectNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.updateUIWithNewPositionData(_:)), name: "PositionDataUpdated", object: nil)
        
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
        
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.startTime = dateFormatter.dateFromString("\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day) \(dateComponents.hour):\(dateComponents.minute):00")!
        self.startTimeLbl.text = "\(dateComponents.hour):\(dateComponents.minute):00"

        self.ctcDate = self.startTime
        self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
        self.hourStepper.value = Double(dateComponents.hour)
        self.minuteStepper.value = Double(dateComponents.minute)
        
        keys.append(UIKeyCommand(input: "w", modifierFlags: [], action:  #selector(ViewController.keyPressed(_:))))
        
    }
    
//    xgps
    func xgp160Connected(notification:NSNotification) {
        print("xgp160Connected")
    }
    func deviceDataUpdated(notification:NSNotification) {
        //        print("deviceDataUpdated")
    }
    
    func updateUIWithNewPositionData(notification:NSNotification) {
        //        print("updateUIWithNewPositionData")
        //        print(delegate!.xgps160!.utc)
        //        print(delegate!.xgps160!.lat)
        //        print(delegate!.xgps160!.lon)
        let latitude: CLLocationDegrees = Double(delegate!.xgps160!.lat)
        let longitude: CLLocationDegrees = Double(delegate!.xgps160!.lon)
        
        let location: CLLocation = CLLocation(latitude: latitude,
                                              longitude: longitude)
        
        //            print(delegate?.xgps160!.hdop)
        guard let hdop = delegate?.xgps160!.hdop
            
            else {
                
                return
        }
//                let hdop = delegate?.xgps160!.hdop
//                print("hdop \(hdop)")
//        horrizontalAccuracy.text = String(hdop)
        if Double((hdop)) > 1.0 {
            print("hdop > 1 \(hdop)")
        }
        //        print(delegate!.xgps160!.waasInUse)
//        print(delegate?.xgps160!.speedAndCourseIsValid)
//        print(delegate?.xgps160!.fixType)
        if ((delegate?.xgps160!.speedAndCourseIsValid) != nil) && delegate?.xgps160!.fixType == 3
        {
//            print("updateLocation \(hdop)")
            if Double(hdop) > 2.0 {return}
            if Double(hdop) < 0.0 {return}
//            print("updateLocation speed \(delegate!.xgps160!.speedKph)")
//            print("location \(location)")
            if Double(delegate!.xgps160!.speedKph) < 1.5 {return}
            delegate?.coreLocationController?.updateLocation([location],xgps: true)
            
        }
        
    }

    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        get {
            return keys
        }
    }
    
    func keyPressed(command: UIKeyCommand) {

        print("user pressed \(command.input)")
        let userInfo = [
            "action":"plusOne"]
        NSNotificationCenter.defaultCenter().postNotificationName("PlusOne", object: nil, userInfo: userInfo)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func hourStepper(sender: UIStepper) {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())
        
        let hourStr = String(format: "%02d", Int(sender.value))
        self.startTimeLbl.text = "\(hourStr):\(dateComponents.minute):00"
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        self.startTime = dateFormatter.dateFromString("\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day) \(hourStr):\(dateComponents.minute):00")!
        
        self.ctcDate = self.startTime
        self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"

    }
    @IBAction func minuteStepper(sender: UIStepper) {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())
        
        let minStr = String(format: "%02d", Int(sender.value))
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):00"

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        self.startTime = dateFormatter.dateFromString("\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day) \(dateComponents.hour):\(minStr):00")!
        
        self.ctcDate = self.startTime
        self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"
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
//        print(self.ctcDate!)
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: self.ctcDate!)
        
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startDistance = Double(self.distanceLbl.text!)
        self.selectedStartDistance =  self.startDistance!
        self.startTime = self.ctcDate!
        self.ctcLbl.text = "\(self.strippedNSDate(ctcDate!))"

//        print(self.startTime!)
//        print(self.startDistance!)
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
//        print(self.startTime!)
    }
    
    func setStartTimeToCTCPlusOne() {
//        print(self.ctcDate!)
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
//        print(self.startTime!)
//        print(self.startDistance!)
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
//        print(self.startTime!)
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
//        print(speedIndex!)
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

//        print(controllerSpeedChoices[speedIndex!])
        self.speedd = controllerSpeedChoices[speedIndex!]
        self.speedLbl.text = String(format: "%.1f",self.speedd! as Float64)
    }
//    Game Conroller
    func controllerDidConnect(notification: NSNotification) {
        
        let controller = notification.object as! GCController
        print("controller is \(controller)")
//        print("game on ")
//        print("\(controller.gamepad!.buttonA.pressed)")

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
            let smStr = String(format: "%.3f", sm as! Float64)
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
        self.distanceLbl.text = (String(format: "%.3f", m as! Float64))
        let lat = String(format: "%.6f", userInfo!["latitude"]! as! Float64)
        let lon = String(format: "%.6f", userInfo!["longitude"]! as! Float64)
        locationTimestamp = userInfo!["timestamp"]! as? NSDate
        locationLatitude = lat
        locationLongitude = lon
        
//        self.course = userInfo!["course"]! as? Double
        var speedometer = userInfo!["speed"]! as? Double
        if (delegate?.xgps160!.isConnected)! == true {
            speedometer = Double(delegate!.xgps160!.speedKph) * 0.62
        }
        self.speedDeltaLbl.text = String(format: "%.1",speedometer!)

//        if speedometer > 0 {
//            if speedometer! > self.speedd! {
//                self.speedDeltaLbl.textColor = UIColor.redColor()
//            } else if speedometer! < self.speedd! {
//                self.speedDeltaLbl.textColor = UIColor.greenColor()
//            } else {
//                self.speedDeltaLbl.textColor = UIColor.blackColor()
//            }
//            self.speedDeltaLbl.text = "\((speedometer!))"
//        }
        
        switch distanceType
        {
        case "miles":
            let m = userInfo!["miles"]!
            self.distance = m as? Double
            self.distanceLbl.text = (String(format: "%.3f", m as! Float64))
            case "km":
            let d = userInfo!["km"]!
            self.distance = d as? Double
            self.distanceLbl.text = (String(format: "%.2f", d as! Float64))
        default:
            break;
        }
//        print("location availabe")
        self.updateDelta()
    }
    
    
    func updateDelta() {
//        print("update delta")
        let calendar = NSCalendar.currentCalendar()

//        let startDateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: startTime!)
        if startTime != nil {
//            if true == false //startTime!.timeIntervalSince1970 > NSDate().timeIntervalSince1970
//            {
//                self.ctcLbl.text = "\(self.strippedNSDate(startTime!))"
//                delta = startTime!.timeIntervalSinceDate(NSDate())
//                delta = delta + 1.0
//                self.deltaLbl.textColor = UIColor.blackColor()
//                
//                switch timeUnit {
//                case "seconds":
//                    let deltaMins = Int(delta / 60)
//                    let deltaUnits = Int(delta % 60)
//                    self.deltaLbl.text = ">\(deltaMins):\(String(format: "%02d", (deltaUnits)))"
//                case "cents":
//                    let deltaMins = Int(delta / 60)
//                    let ds = (delta % 60) * 100
//                    let deltaUnits = Int((ds * 1.66667) / 100)
//                    self.deltaLbl.text = ">\(deltaMins).\(String(format: "%02d",deltaUnits))"
//                default:
//                    break;
//                }
//
//            }
//            this If never called?
            if locationTimestamp == nil {
                print("locationTimestamp is nil \(delta)")

                delta = startTime!.timeIntervalSinceDate(NSDate())
                print("Delta \(delta)")
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
            else //if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 
            {
                let speedFactor = 60.0/Double(speedd!)
                let calcDistance = distance! - selectedStartDistance
                
                //              Simple Accumulator
                ctc = calcDistance * speedFactor

//                if timeUnit == "cents" {
//                    ctc = calcDistance * speedFactor + ((Double(startDateComponents.second) * 1.6667) / 100)
//                } else {
//                    ctc = calcDistance * speedFactor
//                }

                ctcDate = startTime!.dateByAddingTimeInterval(ctc! * 60)
                print("calcDistance \(calcDistance) ctc \(ctc!) ctcDate \(ctcDate!)")

                let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: ctcDate!)
                
//                let ctcCents = Double(dateComponents.second) + (ctc! % 1.0)
//                let ctcCents = (Double(dateComponents.second) * 1.6667) % 10.0
//                let ctcCents = ctc! % 1.0
//                let ctcCentsString = String(format: "%.3f", ctcCents)
//                let ctcCentsArray = ctcCentsString.componentsSeparatedByString(".")
//                let ctcCentString = ctcCentsArray[1]
                
                print("startTime \(startTime!) ctcDate \(ctcDate!)")

                // Make CTC label and display
                let minuteString = String(format: "%02d", dateComponents.minute)
                var unitsString = ""
                var unitSeparator = ":"
                switch timeUnit {
                case "seconds":
                    unitsString = String(format: "%02d",dateComponents.second)
                    delta = round(ctcDate!.timeIntervalSinceDate(locationTimestamp!))
                case "cents":
//                    unitsString = ctcCentString
                    print(Double(dateComponents.second) * 1.6667)
                    print(ctc! % 1.0)
                    print(startTime!)
                    let calendar = NSCalendar.currentCalendar()
                    let startCents = Double(calendar.component(.Second,fromDate: startTime!)) * 0.016667
                    
                    print(ctc!)
                    print(startCents)
                    print((ctc! + startCents) % 1.0)
                    
//                    unitsString = String(format: "%03d",Int(Double(dateComponents.second) * 16.667))
                    unitsString = String(format: "%03d",Int(((ctc! + startCents) % 1.0) * 1000))
                    unitSeparator = "."
                    delta = round((ctcDate!.timeIntervalSinceDate(locationTimestamp!)) * 1.66667)
                default:
                    break;
                }
                self.ctcLbl.text = "\(dateComponents.hour):\(minuteString)\(unitSeparator)\(unitsString)"

//                switch timeUnit {
//                case "seconds":
//                    delta = round(ctcDate!.timeIntervalSinceDate(locationTimestamp!))
//                case "cents":
//                    delta = round((ctcDate!.timeIntervalSinceDate(locationTimestamp!)) * 1.66667)
//                default:
//                    break;
//                }
//                locationTimestamp = nil
                
//                delta = round(ctcDate!.timeIntervalSinceDate(locationTimestamp!))

                print("delta in loc \(delta)")
                
                if delta > 600.0 {
                    self.deltaLbl.textColor = UIColor.blackColor()
                    self.deltaLbl.text = "EEEE"
                }
                else if delta < -600.0{
                    self.deltaLbl.textColor = UIColor.blackColor()
                    self.deltaLbl.text = "LLLL"
                }
//                else if delta < 60.0 && delta > -60.0 {
//                    if timeUnit == "seconds" {
//                        self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
//                    }
//                    else {
//                        self.deltaLbl.text = "\(String(format: "%.0f",(delta * 1.6667)))"
//                    }
//                }

                else if delta < 60.0 && delta > -60.0 && timeUnit == "seconds" {

                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
                else if delta < 100.0 && delta > -100.0 && timeUnit == "cents" {

                    self.deltaLbl.text = "\(String(format: "%.0f",(delta)))"
                }
                else {
                    print("else delta \(delta)")
                    switch timeUnit {
                    case "seconds":
                        let deltaMins = Int(delta / 60)
                        let deltaUnits = abs(Int(delta % 60))
                        self.deltaLbl.text = "\(deltaMins):\(String(format: "%02d", (deltaUnits)))"
                    case "cents":
//                        delta = delta * 1.66667
                        let deltaMins = Int(delta / 100)
                        let deltaUnits = abs(Int(delta % 100))
//                        self.deltaLbl.textAlignment = NSTextAlignment.Right
                        self.deltaLbl.text = "\(deltaMins).\(String(format: "%02d", (deltaUnits)))"
                    default:
                        break;
                    }
                }
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
        locationTimestamp = NSDate()
//        print("update time")
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

