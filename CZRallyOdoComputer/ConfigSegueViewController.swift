//
//  ConfigSegueViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/28/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit

class ConfigSegueViewController: UIViewController {
    
    @IBOutlet weak var factorField: UITextField!
    
    @IBOutlet weak var clearAllSwitch: UISwitch!
    
    @IBOutlet weak var timeUnitControl: UISegmentedControl!
    var distanceType = "miles"
    var timeUnit = "seconds"
    var factor = 1.0000
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        factorField.keyboardType = UIKeyboardType.DecimalPad
        self.factorField.text = "\(self.factor)"
        switch timeUnit
        {
        case "seconds":
            self.timeUnitControl.selectedSegmentIndex=0
        case "cents":
            self.timeUnitControl.selectedSegmentIndex=1
        default:
            break;
        }
        self.clearAllSwitch.on = false
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)


    }
    
   
    @IBAction func clearCZSwitchValueChanged(sender: AnyObject) {
//        print("sender \(sender)")
//        print("state \(clearAllSwitch.on)")
    }
    
    @IBAction func setButton(sender: AnyObject) {
        self.factor = Double(self.factorField.text!)!

        let userInfo = [
            "factor":factor]
        NSNotificationCenter.defaultCenter().postNotificationName("FACTOR_CHANGED", object: nil, userInfo: userInfo)
        
    }
    
    @IBAction func timeUnitsSegmentedControl(sender: AnyObject) {
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
   
    @IBAction func distanceUnitsSegmentedController(sender: AnyObject) {
        
        switch sender.selectedSegmentIndex
        {
        case 0:
            distanceType = "miles"
        case 1:
            distanceType = "km"
        default:
            break;
        }
    }
   
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}
