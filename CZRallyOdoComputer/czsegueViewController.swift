//
//  czsegueViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit

class CZSegueViewController: UIViewController {

    @IBOutlet weak var controlNumberField: UITextField!
    
    @IBOutlet weak var speedField: UITextField!
    
    @IBOutlet weak var startDistanceField: UITextField!
    
    @IBOutlet weak var hourField: UITextField!
    
    
    @IBOutlet weak var minuteField: UITextField!
    
    @IBOutlet weak var timeUnitField: UITextField!
    
//    @IBOutlet weak var controlNumberField: UITextField!
//    @IBOutlet weak var speedField: UITextField!
//    
//    @IBOutlet weak var hourField: UITextField!
//    @IBOutlet weak var minuteField: UITextField!
//    @IBOutlet weak var timeUnitField: UITextField!
//    
//    @IBOutlet weak var startDistanceField: UITextField!
//    
    var controlNumber: Int!
    var speed: Int!
    var speedd: Double!
    var startDistance: Double!
    var hour: Int!
    var minute: Int!
    var second: Int!
    var startTime: NSDate?
    
    
    override func viewWillAppear(animated: Bool) {
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
//        controlNumberField.keyboardType = UIKeyboardType.DecimalPad
//        speedField.keyboardType = UIKeyboardType.DecimalPad
//        hourField.keyboardType = UIKeyboardType.DecimalPad
//        minuteField.keyboardType = UIKeyboardType.DecimalPad
//        timeUnitField.keyboardType = UIKeyboardType.DecimalPad
//        startDistanceField.keyboardType = UIKeyboardType.DecimalPad
        super.viewWillAppear(animated)
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        self.controlNumberField.text = "\(self.controlNumber)"
        self.startDistanceField.text = "\(self.startDistance)"
        self.speedField.text = "\(self.speed)"
        self.hourField.text = "\(dateComponents.hour)"
//        self.minuteField.text = "\(dateComponents.minute)"
        let minStr = String(format: "%02d", dateComponents.minute)
        self.minuteField.text = "\(minStr)"
        
        
        //        self.timeUnitsField.text = "\(dateComponents.second)"
        self.timeUnitField.text = "00"
        
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
        //        let dateString = "2015-12-21 18:51:00"
        //        let date: NSDate? = dateFormatter.dateFromString(dateString)
        //        print("date \(date)")
        
//        self.startTime = dateFormatter.dateFromString(dateString)
//        print("st \(self.startTime)")
        self.startTime = dateFormatter.dateFromString("\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day) \(self.hourField.text!):\(self.minuteField.text!):\(self.timeUnitField.text!)")!
        
        
        
        self.controlNumber = Int(self.controlNumberField.text!)
        self.speed = Int(self.speedField.text!)
        self.speedd = Double(self.speedField.text!)
        self.startDistance = Double(self.startDistanceField.text!)
        self.hour = Int(self.hourField.text!)
        self.minute = Int(self.minuteField.text!)
        self.second = Int(self.timeUnitField.text!)
    }
    
}
