//
//  CZDataViewController.swift
//  CZRallyComputer
//
//  Created by Clarence Westberg on 12/24/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit

class CZDataViewController: UIViewController {

    @IBOutlet weak var controlNumberField: UITextField!
    @IBOutlet weak var speedTextField: UITextField!
    @IBOutlet weak var hourField: UITextField!

    @IBOutlet weak var minuteField: UITextField!

    @IBOutlet weak var timeUnitsField: UITextField!

    var controlNumber: Int!
    var speed: Int!
    var speedd: Double!
    var hour: Int!
    var minute: Int!
    var second: Int!
    var startTime: NSDate?
    
    
    override func viewWillAppear(animated: Bool) {
        controlNumberField.keyboardType = UIKeyboardType.NumberPad
        speedTextField.keyboardType = UIKeyboardType.NumberPad
        hourField.keyboardType = UIKeyboardType.NumberPad
        minuteField.keyboardType = UIKeyboardType.NumberPad
        super.viewWillAppear(animated)
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        controlNumberField.text = "\(self.controlNumber)"
        self.speedTextField.text = "\(self.speed)"
        self.hourField.text = "\(dateComponents.hour)"
//        self.minuteField.text = "\(dateComponents.minute)"
        let minStr = String(format: "%02d", dateComponents.minute)
        self.minuteField.text = "\(minStr)"


        //        self.secondField.text = "\(dateComponents.second)"
        self.timeUnitsField.text = "00"
        
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
        print("st \(self.startTime)")
        self.startTime = dateFormatter.dateFromString("\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day) \(self.hourField.text!):\(self.minuteField.text!):00")!
        
        
        
        self.controlNumber = Int(self.controlNumberField.text!)
        self.speed = Int(self.speedTextField.text!)
        self.speedd = Double(self.speedTextField.text!)
        self.hour = Int(self.hourField.text!)
        self.minute = Int(self.minuteField.text!)
        self.second = Int(self.timeUnitsField.text!)
    }

}
