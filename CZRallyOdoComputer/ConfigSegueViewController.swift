//
//  ConfigSegueViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/28/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
import CoreLocation
import CloudKit

class ConfigSegueViewController: UIViewController {
    
    @IBOutlet weak var factorField: UITextField!
        
    @IBOutlet weak var timeUnitControl: UISegmentedControl!
    
    @IBOutlet weak var carNumber: UITextField!

    @IBOutlet weak var factorStepper: UIStepper!
    let container = CKContainer.defaultContainer()
    var publicDatabase: CKDatabase?
    var currentRecord: CKRecord?
    
    var distanceType = "miles"
    var timeUnit = "seconds"
    var factor = 1.0000
    var gpsLocations = [CLLocation]()
    var omLocations = [Double]()
    var destinations = [CLLocation]()
    var distances = [Double]()
    var speeds = [Double]()
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        publicDatabase = container.publicCloudDatabase
//        factorStepper.maximumValue = 1.1000
//        factorStepper.minimumValue = 0.9000
        factorField.keyboardType = UIKeyboardType.DecimalPad
        self.factorField.text = "\(self.factor)"
        factorStepper.value = self.factor
        switch timeUnit
        {
        case "seconds":
            self.timeUnitControl.selectedSegmentIndex=0
        case "cents":
            self.timeUnitControl.selectedSegmentIndex=1
        default:
            break;
        }
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ConfigSegueViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)


    }
    
    @IBAction func factorStepper(sender: UIStepper) {
        self.factor = sender.value
        self.factorField.text = "\(self.factor)"
    }
    @IBAction func importBtn(sender: AnyObject) {
        
        //Create the AlertController
        let importSheetController: UIAlertController = UIAlertController(title: "Import", message: "Enter Rally name", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        importSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
            self.loadLocations(importSheetController.textFields![0].text!)
        }
        importSheetController.addAction(setAction)
        
        //Add a text field
        importSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            
        }
        
        //Present the AlertController
        self.presentViewController(importSheetController, animated: true, completion: nil)
    }
    
    @IBAction func exportBtn(sender: AnyObject) {
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
    
    func loadLocations(rallyName: String) {
        let predicate = NSPredicate(format: "rallyName = %@", rallyName)
        let sort = NSSortDescriptor(key: "sequence", ascending: true)
        let query = CKQuery(recordType: "RallyLocation", predicate: predicate)
        query.sortDescriptors = [sort]

        publicDatabase?.performQuery(query, inZoneWithID: nil,
            completionHandler: (
                {results, error in
                if (error != nil) {
                        print("Cloud Access Error \(error)")
                } else {
                    if results!.count > 0 {
                        print(results!.count)
                        print(results!)
                        for record in results!{
//                            print(record)
                            dispatch_async(dispatch_get_main_queue()) {
                            let latitude = record.objectForKey("latitude") as! Double
                            let longitude = record.objectForKey("longitude") as! Double
                            let distance = record.objectForKey("distance") as! Double
                            let speed = record.objectForKey("speed") as! Double
                            self.destinations.append(CLLocation.init(latitude: latitude,longitude: longitude))
                            self.distances.append(distance)
                            self.speeds.append(speed)
                            print(distance)
                            print(speed)
                            }
                        }
                    }
                    else {
                        print("No Match Found")
                    }
                }
            }
        )
    )
        print(self.destinations)
    }
   
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
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
    
    func parse(content: String) {
        print(content)

        let delimiter = ","
        //    var items:[(time:String, om:String, latitude: String,longitude: String,course: String,speed: String)]?
        let lines:[String] = content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) as [String]
        print("lines count \(lines.count)")
        print("lines  \(lines)")
        for line in lines {
            print("line \(line)")
            var values:[String] = []
            if line != "" {
                values = line.componentsSeparatedByString(delimiter)
                // Put the values into the tuple and add it to the items array
                let item = (time: values[0], om: values[1], latitude: values[2],longitude:values[3],course:values[4],speed:values[5])
                print("\(item)")
                let location = CLLocation.init(latitude: Double(item.latitude)!, longitude: Double(item.longitude)!)
                gpsLocations.insert(location, atIndex: 0)
                print(gpsLocations)
                omLocations.insert(Double(item.om)!, atIndex: 0)
                print(omLocations)
            }
        }
    }

    
}
