//
//  SplitsSequeViewController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 1/6/16.
//  Copyright © 2016 Clarence Westberg. All rights reserved.
//
import Foundation

import UIKit

class SplitsSegueViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    
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
        print("viewWillAppear")
        tableView.reloadData()

        
        self.tableView.registerClass(UITableViewCell.self,forCellReuseIdentifier:"Cell")
        

        
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

    
}