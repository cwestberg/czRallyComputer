//
//  SplitsSequeViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 1/6/16.
//  Copyright © 2016 Clarence Westberg. All rights reserved.
//
import Foundation

import UIKit
import CloudKit

class SplitsSegueViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    let container = CKContainer.defaultContainer()

    var publicDatabase: CKDatabase?
//    var currentRecord: CKRecord?
    
    var splits = [String]()
//    override func viewDidLoad() {
//        print("view did load")
//        super.viewDidLoad()
//                NSNotificationCenter.defaultCenter().addObserver(self, selector: "split:", name: "Split", object: nil)
//        self.tableView.registerClass(UITableViewCell.self,forCellReuseIdentifier:"Cell")
//
//    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        publicDatabase = container.publicCloudDatabase
        tableView.reloadData()

        self.tableView.registerClass(UITableViewCell.self,forCellReuseIdentifier:"Cell")
        
    }
    
    @IBAction func toCloud(sender: AnyObject) {
        //Create the AlertController
        let importSheetController: UIAlertController = UIAlertController(title: "Save In Cloud", message: "Enter Rally name", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        importSheetController.addAction(cancelAction)
        
        //Create and add the Set action
        let setAction: UIAlertAction = UIAlertAction(title: "Set", style: .Default) { action -> Void in
            self.saveRallyLocations(importSheetController.textFields![0].text!)

//            self.loadLocations(importSheetController.textFields![0].text!)
        }
        importSheetController.addAction(setAction)
        
        //Add a text field
        importSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.textColor = UIColor.blueColor()
            textField.keyboardType = UIKeyboardType.DecimalPad
            
        }
        
        //Present the AlertController
        self.presentViewController(importSheetController, animated: true, completion: nil)
        
//        saveRallyLocations("yucatan16")
    }
    @IBAction func shareBtn(sender: AnyObject) {
        
        print("\(self.splits)")
        var firstActivityItem = [String]()
        _ = self.splits
        for split in splits {
            firstActivityItem.append(split)
        }
        
//        let firstActivityItem = "\(self.splits)"
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: firstActivityItem, applicationActivities: nil)
        presentViewController(activityViewController, animated:true, completion: nil)
        
    }

    
    //    Table Stuff
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.splits.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!

            cell.textLabel!.text = self.splits[indexPath.row]
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
 
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
 
            splits.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }

    func saveRallyLocations(rallyName: String) {
        let delimiter = ","

        for location in splits {
            let values = location.componentsSeparatedByString(delimiter)
            let item = (time: values[0], om: values[1], latitude: values[2],longitude:values[3],course:values[4],speed:values[5])
            
            print(item.latitude)
            print(item.longitude)
            print(item.speed)
            print(item.om)
            let myRecord = CKRecord(recordType: "RallyLocation")
            myRecord.setObject(rallyName, forKey: "rallyName")
            myRecord.setObject(Double(item.latitude), forKey: "latitude")
            myRecord.setObject(Double(item.longitude), forKey: "longitude")
            myRecord.setObject(Double(item.om), forKey: "distance")
            myRecord.setObject(Double(item.speed), forKey: "speed")
            
            publicDatabase!.saveRecord(myRecord, completionHandler:
                ({returnRecord, error in
                    if let err = error {
                        self.notifyUser("Save Error", message:
                            err.localizedDescription)
                    } else {
                        dispatch_async(dispatch_get_main_queue()){
                            self.notifyUser("Success",
                                message: "Record saved successfully")
                        }
                    }
                    }
                )
            )
        }
        
            
    }
        
    func notifyUser(title: String, message: String) -> Void
    {
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        let cancelAction = UIAlertAction(title: "OK",
            style: .Cancel, handler: nil)
        
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true,
            completion: nil)
    }
    
}