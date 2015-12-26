//
//  ViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import UIKit
//,UITableViewDelegate, UITableViewDataSource
class ViewController: UIViewController {

    
    var speed: Int?
    var speedd: Double?
    var controlNumber: Int?
    
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
//            self.saveCZ(dvc!.controlNumber,speed: dvc!.speed,startTime: dvc!.startTime!)
//            self.tableView.reloadData()
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DataSegue"
        {if let destinationVC = segue.destinationViewController as? CZSegueViewController{
            destinationVC.controlNumber = self.controlNumber
            destinationVC.speedd = self.speedd
            destinationVC.speed = self.speed
            destinationVC.second = 0
            }
        }
    }



}

