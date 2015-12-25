//
//  ViewController.swift
//  CZRallyComputer
//
//  Created by Clarence Westberg on 12/24/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var mileageLbl: UILabel!
    @IBOutlet weak var controlNumberLbl: UILabel!
    
    @IBOutlet weak var currentSpeed: UILabel!
    
    @IBOutlet weak var startTimeLbl: UILabel!
    
    @IBOutlet weak var todLbl: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var speedd = 36.0
    var speed = 36
    var controlNumber = 1
    var controlZones = [NSManagedObject]()
    var startTime: NSDate?
    var todTimer = NSTimer()
    var timeUnit = "seconds"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        
        self.todTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
            selector: "updateTimeLabel", userInfo: nil, repeats: true)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    Segue Stuff
    @IBAction func unwindToViewController(sender: UIStoryboardSegue){
        print("unwindSegue \(sender)")
        
        if(sender.sourceViewController.isKindOfClass(CZDataViewController))
        {
            let dvc = sender.sourceViewController as? CZDataViewController
            print("\(dvc!.controlNumber)")
            print("\(dvc!.speed)")
            print("\(dvc!.speedd)")
            print("\(dvc!.hour)")
            print("\(dvc!.minute)")
            print("\(dvc!.second)")
            print("\(dvc!.startTime)")
//            self.saveCZ(dvc!.controlNumber,speed: dvc!.speed,startTime: dvc!.startTime!)
//            self.tableView.reloadData()
        }
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DataSegue"
        {if let destinationVC = segue.destinationViewController as? CZDataViewController{
            destinationVC.controlNumber = self.controlNumber
            destinationVC.speedd = self.speedd
            destinationVC.speed = self.speed
            }
        }
    }
    
//    Table Stuff
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("count \(controlZones.count)")
        return controlZones.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
            print("\(cell)")
            print("\(indexPath.row)")
            
            let cz = controlZones[indexPath.row]
            print("cz \(cz)")
            
            let cn = cz.valueForKey("controlNumber")
            print("cn \(cn!)")
            let spd = cz.valueForKey("speed")
            print("spd \(spd!)")
            //            let st = cz.valueForKey("startTime")
            //            print("st \(st!)")
            //            print("\(cn) \(spd) \(st)")
            let st = self.strippedNSDate(cz.valueForKey("startTime") as! NSDate)
            
            cell.textLabel!.text = "\(cn!) \(spd!) \(st)"
            
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
        let selectedCZ = controlZones[indexPath.row]
        print("selectedCZ \(selectedCZ)")
        
        self.controlNumberLbl.text = "Control Number \(selectedCZ.valueForKey("controlNumber")!)"
        self.speed = selectedCZ.valueForKey("speed") as! Int
        self.currentSpeed.text = String(self.speed)
        
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: (selectedCZ.valueForKey("startTime") as? NSDate)!)
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        self.startTimeLbl.text = "\(dateComponents.hour):\(minStr):\(secStr)"
        self.startTime = selectedCZ.valueForKey("startTime") as? NSDate
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // 1
        if editingStyle == .Delete {
            
            // 2
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let moc = appDelegate.managedObjectContext
            
            // 3
            moc.deleteObject(controlZones[indexPath.row])
            appDelegate.saveContext()
            
            // 4
            controlZones.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }
    
//    Persistence
    //    Persistence
    func saveCZ(controlNumber: Int,speed: Int, startTime: NSDate) {
        
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
        controlZone.setValue(controlNumber, forKey: "controlNumber")
        controlZone.setValue(speed, forKey: "speed")
        controlZone.setValue(startTime, forKey: "startTime")
        
        //4
        do {
            try managedContext.save()
            //5
            controlZones.append(controlZone)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "ControlZone")
        
        //3
        do {
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            controlZones = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }


    
//    utilities
    
    func updateTimeLabel() {
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
        
        
        let unit = Double(dateComponents.second)
        let second = Int(unit)
        let secondString = String(format: "%02d", second)
        
        let cent = Int((unit * (1.6667)))
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
        if startTime != nil {
            if startTime!.timeIntervalSince1970 < NSDate().timeIntervalSince1970 {
                let elapsedTime = NSDate().timeIntervalSinceDate(startTime!)
                
                let milesPerMinute = Double(self.speed)/60.0
                let et = elapsedTime * 1.66667
                let distance = (milesPerMinute * et)/100
                let ss = String(format: "%.2f",distance)
                //                print("dist = \(ss) for \(distance)")
                self.mileageLbl.text = ss
                
            }
            else {
                self.mileageLbl.text = "NA"
            }
        }
        
    }
    func strippedNSDate(date: NSDate) -> String {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: (date))
        let minStr = String(format: "%02d", dateComponents.minute)
        let secStr = String(format: "%02d", dateComponents.second)
        let strippedDate = "\(dateComponents.hour):\(minStr):\(secStr)"
        return strippedDate
    }

}

