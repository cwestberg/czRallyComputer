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
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)


    }
    
    @IBAction func setButton(sender: AnyObject) {
    }
    
    @IBAction func timeUnitsSegmentedControl(sender: AnyObject) {
    }
   
    @IBAction func distanceUbitsSegmentedControl(sender: AnyObject) {
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}
