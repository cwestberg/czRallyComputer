//
//  ViewController.swift
//  CZRallyComputer
//
//  Created by Clarence Westberg on 12/24/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    
    var speedd = 45.0
    var speed = 45
    var controlNumber = 1
    var controlZones = [NSManagedObject]()
    var startTime: NSDate?
    var todTimer = NSTimer()
    var timeUnit = "seconds"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
    

}

