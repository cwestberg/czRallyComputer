//
//  czsegueViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit

class CZSegueViewController: UIViewController {

    @IBOutlet weak var controlNumberLbl: UILabel!
    
    @IBOutlet weak var hourLbl: UILabel!
    @IBOutlet weak var minuteLbl: UILabel!
    @IBOutlet weak var timeUnitLbl: UILabel!
    @IBOutlet weak var speedLbl: UILabel!
   
    @IBOutlet weak var startDistanceLbl: UILabel!

    @IBOutlet weak var speedStepper: UIStepper!
   
    @IBOutlet weak var minuteStepper: UIStepper!
    
    @IBOutlet weak var hourStepper: UIStepper!
    
    var controlNumber: Int!
    var speed: Int!
    var speedd: Double!
    var startDistance: Double!
    var hour: Int!
    var minute: Int!
    var second: Int!
    var startTime: NSDate?
    var timeUnit: String?
    
    
    override func viewWillAppear(animated: Bool) {
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(CZSegueViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        super.viewWillAppear(animated)
        let currentDate = NSDate().dateByAddingTimeInterval(60)
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        speedStepper.maximumValue = 85
        speedStepper.minimumValue = 0
        speedStepper.value = self.speedd
//        self.controlNumberLbl.text = "\(self.controlNumber)"
        self.startDistanceLbl.text = String(format: "%0.2f", self.startDistance)
        self.speedLbl.text = "\(self.speedd)"
        self.hourLbl.text = "\(dateComponents.hour)"
        let minStr = String(format: "%02d", dateComponents.minute)
        self.minuteLbl.text = "\(minStr)"
        self.hourStepper.value = Double(dateComponents.hour)
        self.minuteStepper.value = Double(dateComponents.minute)
        
        
        //        self.timeUnitsField.text = "\(dateComponents.second)"
        self.timeUnitLbl.text = "00"
        print(self.timeUnit!)

        
    }
    
    @IBAction func hourStepper(sender: UIStepper) {
        self.hour = Int(sender.value)
        self.hourLbl.text = "\(self.hour)"
    }
    
    @IBAction func minuteStepper(sender: UIStepper) {
        self.minute = Int(sender.value)
        self.minuteLbl.text = "\(self.minute)"
    }

    @IBAction func speedStepper(sender: UIStepper) {
        self.speedLbl.text = String(format: "%0.0f",sender.value)
        self.speedd = sender.value
    }
    @IBAction func zeroStartDistance(sender: AnyObject) {
        self.startDistance = 0.00
        self.startDistanceLbl.text = "0.00"
    }
    @IBAction func hourButton(sender: AnyObject) {
        
        //Create the AlertController
        let hourSheetController: UIAlertController = UIAlertController(title: "Enter", message: "Hour", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        hourSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
//            self.hourLbl.text = hourSheetController.textFields![0].text!
            let hourString = hourSheetController.textFields![0].text!
            print(Int(hourString))
            if Int(hourString) > 23 {
                self.hourLbl.text! = "23"
            }
            else {
                self.hourLbl.text = hourString
            }
            self.hour = Int(self.hourLbl.text!)
        }
        hourSheetController.addAction(setAction)
        
        //Add a text field
        hourSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.NumberPad
        }
        
        //Present the AlertController
        self.presentViewController(hourSheetController, animated: true, completion: nil)
        
    }
    
    @IBAction func minuteButton(sender: AnyObject) {
        //Create the AlertController
        let minuteSheetController: UIAlertController = UIAlertController(title: "Enter", message: "Minute", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        minuteSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
//            self.minuteLbl.text = minuteSheetController.textFields![0].text!
            let minString = minuteSheetController.textFields![0].text!
            print(Int(minString))
            if Int(minString) > 59 {
                self.minuteLbl.text! = "59"
            }
            else {
                self.minuteLbl.text = minString
            }
            self.minute = Int(self.minuteLbl.text!)
            
        }
        minuteSheetController.addAction(setAction)
        
        //Add a text field
        minuteSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.NumberPad
        }
        
        //Present the AlertController
        self.presentViewController(minuteSheetController, animated: true, completion: nil)
    }
    @IBAction func speedButton(sender: AnyObject) {
        
        //Create the AlertController
        let speedSheetController: UIAlertController = UIAlertController(title: "Enter", message: "Speed", preferredStyle: .Alert)

        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        speedSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
            let scanner = NSScanner(string: speedSheetController.textFields![0].text!)
            scanner.locale = NSLocale.currentLocale()
            if scanner.scanDecimal(nil) && scanner.atEnd{
                self.speedLbl.text = speedSheetController.textFields![0].text!
                self.speedd = Double(self.speedLbl.text!)
            }
            else {
                self.speedLbl.text = "invalid entry"
            }
        }
        speedSheetController.addAction(setAction)
        
        //Add a text field
        speedSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.DecimalPad

        }
        
        //Present the AlertController
        self.presentViewController(speedSheetController, animated: true, completion: nil)
    }
    
    @IBAction func timeUnitsButton(sender: AnyObject) {
        
        //Create the AlertController
        let timeUnitsSheetController: UIAlertController = UIAlertController(title: "Enter", message: "Cent or Second", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        timeUnitsSheetController.addAction(cancelAction)

        //        Need to test for cents or seconds then limt to 59 or 99
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
            self.timeUnitLbl.text = timeUnitsSheetController.textFields![0].text!
//            self.unit = Int(self.timeUnitLbl.text!)
            
            var unitString = timeUnitsSheetController.textFields![0].text!
            print(Int(unitString))
            if self.timeUnit == "seconds"{
                if Int(unitString) > 59 {
                    unitString = "59"
                }
            }
            else {
                if Int(unitString) > 99 {
                    unitString = "99"
                }
            }
            self.timeUnitLbl.text = unitString
 
            self.second = Int(unitString)


        }
        timeUnitsSheetController.addAction(setAction)
        
        //Add a text field
        timeUnitsSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.NumberPad

        }
        
        //Present the AlertController
        self.presentViewController(timeUnitsSheetController, animated: true, completion: nil)
        
    }
    @IBAction func distanceButton(sender: AnyObject) {
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Enter", message: "Distance", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
            self.startDistanceLbl.text = actionSheetController.textFields![0].text!
            
            let scanner = NSScanner(string: actionSheetController.textFields![0].text!)
            scanner.locale = NSLocale.currentLocale()
            if scanner.scanDecimal(nil) && scanner.atEnd{
                print("scan")
                self.startDistanceLbl.text = actionSheetController.textFields![0].text!
                self.startDistance = Double(self.startDistanceLbl.text!)
            }
            else {
                self.startDistanceLbl.text = "invalid entry"
            }

        }
        actionSheetController.addAction(setAction)
        
        //Add a text field
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.DecimalPad
        }
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    @IBAction func controlButton(sender: AnyObject) {
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Enter", message: "Control Number", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
            self.controlNumberLbl.text = actionSheetController.textFields![0].text!
            self.controlNumber = Int(self.controlNumberLbl.text!)

        }
        actionSheetController.addAction(setAction)
        
        //Add a text field
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.NumberPad

        }
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func doneBtn(sender: AnyObject) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        //        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: NSDate())

        if timeUnit == "cents" {
            self.timeUnitLbl.text = "\(Int(Double(self.second) * 0.6))"
        }
        
        self.startTime = dateFormatter.dateFromString("\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day) \(self.hourLbl.text!):\(self.minuteLbl.text!):\(self.timeUnitLbl.text!)")!
    }
    
    func validatNumericInput(text: String) -> String {
        let scanner = NSScanner(string: text)
        scanner.locale = NSLocale.currentLocale()
        if scanner.scanDecimal(nil) && scanner.atEnd{
            return text
        }
        else {
            return "invalid entry"
        }
    }
    
}
