//
//  coreLocationController.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 12/26/15.
//  Copyright © 2015 Clarence Westberg. All rights reserved.
//

import Foundation
import CoreLocation

class CoreLocationController: NSObject, CLLocationManagerDelegate{
    var locationManager:CLLocationManager = CLLocationManager()
    var fromLocation = [CLLocation]()
    var currentLocations = [CLLocation]()
    var miles = 0.00
    var imMiles = 0.00
    var km = 0.00
    var meters = 0.00
    var imMeters = 0.00
    var imKM = 0.00
    var factor = 1.0000
    var direction = "forward"
    var selectedCounters = "om"
    
    var startTime = NSDate()
    override init() {
        self.miles = 0.0
        self.factor = 1.0
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestAlwaysAuthorization()
//        _ = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateLocation", userInfo: nil, repeats: true)

    
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.reset(_:)), name: "Reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.resetIM(_:)), name: "ResetIM", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.resetBoth(_:)), name: "ResetBoth", object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("zeroIntervalTime:"), name: "ZeroInterval", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.factorChanged(_:)), name: "FACTOR_CHANGED", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.plusOne(_:)), name: "PlusOne", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.minusOne(_:)), name: "MinusOne", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.directionChanged(_:)), name: "DirectionChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.selectedCountersChanged(_:)), name: "SelectedCountersChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.splitOM(_:)), name: "SplitOM", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.setMileage(_:)), name: "SetMileage", object: nil)
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CoreLocationController.milesFixForOc(_:)), name: "MilesFixForOc", object: nil)
        
        
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("didChangeAuthorizationStatus")
        
        switch status {
        case .NotDetermined:
            print(".NotDetermined")
            break
            
        case .Authorized:
            print(".Authorized")
            self.locationManager.startUpdatingLocation()
            break
            
        case .Denied:
            print(".Denied")
            break
            
        default:
            print("Unhandled authorization status")
            break
            
        }
    }
    
    func updateLocation() {
        self.locationManager.requestLocation()
        print("update location")
//        let location = self.locationManager.location
        guard let location = self.locationManager.location
            else {
                return
        }
        if self.fromLocation.count == 0 {self.fromLocation = [location]}

        var addDistance = true
        if location.speed < 1 {
            addDistance = false
        }
        //print("horizontalAccuracy: \(location.horizontalAccuracy)")
        if location.horizontalAccuracy > 40 || location.horizontalAccuracy < 0 {
            //print("return: \(location.horizontalAccuracy), \(location.speed)")
            addDistance = false
        }
        if abs(location.horizontalAccuracy - self.fromLocation.last!.horizontalAccuracy) > 20 {
            //print("abs > 20")
            addDistance = false
        }
        if self.fromLocation.last!.speed < 0 {
            //print("return: \(self.fromLocation.last!.speed)")
            addDistance = false
        }
        if addDistance == true {
            //let distance = location.distanceFromLocation(self.fromLocation.last!) * self.factor
            let distance = location.distanceFromLocation(self.fromLocation.last!)
//            print("meters = \(self.meters) distance moved =  \(distance)")
            
            let updateChoices = (self.direction, self.selectedCounters)
            switch updateChoices
            {
            case ("forward","both"):
                self.meters += distance // Actually meters
                self.imMeters += distance // Actually meters
            case ("forward","om"):
                self.meters += distance // Actually meters
            case ("forward","im"):
                self.imMeters += distance // Actually meters
            case ("reverse","both"):
                self.meters -= distance // Actually meters
                self.imMeters -= distance // Actually meters
            case ("reverse","om"):
                self.meters -= distance // Actually meters
            case ("reverse","im"):
                self.imMeters -= distance // Actually meters
            default:
                break;
            }
            if self.meters < 0.0 {
                self.meters = 0.0
            }
            if self.imMeters < 0.0 {
                self.imMeters = 0.0
            }
            self.km = (self.meters/1000) * self.factor
            let distanceInMiles:Float64 = ((self.meters * 0.000621371) * self.factor)
            self.miles = distanceInMiles
            let imDdistanceInMiles:Float64 = ((self.imMeters * 0.000621371) * self.factor)
            self.imMiles = imDdistanceInMiles
            self.imKM = (imMeters/1000) * self.factor
        }
        
        let elapsedTime = NSDate().timeIntervalSinceDate(self.startTime)
        var averageSpeed = 3600 * (miles/(elapsedTime))
        if averageSpeed > 100 {
            averageSpeed = 100
        }
        var locations = [CLLocation]()
        locations.append(location)
        let userInfo: [NSObject: AnyObject]? = [
            "locations":locations,
            "currentLocation":location,
            "course":location.course,
            "timestamp":location.timestamp,
            "miles":self.miles,
            "imMiles":self.imMiles,
            "imKM":self.imKM,
            "km":self.km,
            "speed":Int(location.speed * 2.23694),
            "latitude":location.coordinate.latitude,
            "longitude":location.coordinate.longitude,
            "horizontalAccuracy":location.horizontalAccuracy,
            "averageSpeed":averageSpeed,
            "et":elapsedTime]
        
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo! as [NSObject : AnyObject])
        self.currentLocations = locations
        self.fromLocation = locations

        print(self.miles)

    }
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var prevLocation: CLLocation
        if self.fromLocation.count == 0 {
            self.fromLocation = locations
            prevLocation = locations.first!
        }
        else {
            prevLocation = self.fromLocation.last!
        }
        
//        if self.fromLocation.count > 0 {
            for location in locations {
                
                var addDistance = true
//                let location:CLLocation = locations.last!
                if location.speed < 1 {
                    addDistance = false
                }
                //print("horizontalAccuracy: \(location.horizontalAccuracy)")
                if location.horizontalAccuracy > 40 || location.horizontalAccuracy < 0 {
                    //print("return: \(location.horizontalAccuracy), \(location.speed)")
                    addDistance = false
                }
                if abs(location.horizontalAccuracy - prevLocation.horizontalAccuracy) > 20 {
                    //print("abs > 20")
                    addDistance = false
                }
                if location.timestamp.timeIntervalSinceReferenceDate < prevLocation.timestamp.timeIntervalSinceReferenceDate {
                    addDistance = false
                }
                if location.verticalAccuracy < 0 {
                    print(location.verticalAccuracy)
    //                addDistance = false
                }
                if location.speed < 0 {
                    addDistance = false
                }
                if addDistance == true {
                    let distance = location.distanceFromLocation(prevLocation)
//                    print("meters = \(self.meters) distance moved =  \(distance) \(location.speed)")
    //                print(abs(location.course - prevLocation.course))
    //                if abs(location.course - prevLocation.course) > 100 {
    //                    return
    //                }
                    

                    let updateChoices = (self.direction, self.selectedCounters)
                    switch updateChoices
                    {
                    case ("forward","both"):
                        self.meters += distance // Actually meters
                        self.imMeters += distance // Actually meters
                    case ("forward","om"):
                        self.meters += distance // Actually meters
                    case ("forward","im"):
                        self.imMeters += distance // Actually meters
                    case ("reverse","both"):
                        self.meters -= distance // Actually meters
                        self.imMeters -= distance // Actually meters
                    case ("reverse","om"):
                        self.meters -= distance // Actually meters
                    case ("reverse","im"):
                        self.imMeters -= distance // Actually meters
                    default:
                        break;
                    }
                    if self.meters < 0.0 {
                        self.meters = 0.0
                    }
                    if self.imMeters < 0.0 {
                        self.imMeters = 0.0
                    }
                    self.km = (self.meters/1000) * self.factor
                    let distanceInMiles:Float64 = ((self.meters * 0.000621371) * self.factor)
                    self.miles = distanceInMiles
                    let imDdistanceInMiles:Float64 = ((self.imMeters * 0.000621371) * self.factor)
                    self.imMiles = imDdistanceInMiles
                    self.imKM = (imMeters/1000) * self.factor
                }

                let elapsedTime = NSDate().timeIntervalSinceDate(self.startTime)
                var averageSpeed = 3600 * (miles/(elapsedTime))
                if averageSpeed > 100 {
                    averageSpeed = 100
                }
                
                let course = location.course
                let userInfo = [
                    "locations":locations,
                    "currentLocation":location,
                    "course":course,
                    "timestamp":location.timestamp,
                    "miles":self.miles,
                    "imMiles":self.imMiles,
                    "imKM":self.imKM,
                    "km":self.km,
                    "speed":Int(location.speed * 2.23694),
                    "latitude":location.coordinate.latitude,
                    "longitude":location.coordinate.longitude,
                    "horizontalAccuracy":location.horizontalAccuracy,
                    "averageSpeed":averageSpeed,
                    "et":elapsedTime]
                
                NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo as [NSObject : AnyObject])
//            }
        }
        
        self.currentLocations = locations
        self.fromLocation = locations
    }
    
    func splitOM(notification:NSNotification) -> Void {
        guard let _ = self.fromLocation.last
            else {
                return
        }
//        print("splitOM")
        let userInfo = [
            "miles": self.miles,
            "imMiles":self.imMiles,
            "imKM":self.imKM,
            "km":self.km,
            "speed":Int(self.fromLocation.last!.speed * 2.23694),
            "latitude":self.fromLocation.last!.coordinate.latitude,
            "longitude":self.fromLocation.last!.coordinate.longitude,
            "horizontalAccuracy":self.fromLocation.last!.horizontalAccuracy]
        NSNotificationCenter.defaultCenter().postNotificationName("Split", object: nil, userInfo: userInfo as [NSObject : AnyObject])
    }
    
    
    func selectedCountersChanged(notification:NSNotification) -> Void {
//        print("selectedCountersChanged")
        let userInfo = notification.userInfo
        let ctrs = userInfo!["action"]!
        self.selectedCounters = ctrs as! String
    }
    
    func directionChanged(notification:NSNotification) -> Void {
//        print("change direction")
        let userInfo = notification.userInfo
        let newDirection = userInfo!["action"]!
        self.direction = newDirection as! String
    }
    
    func reset(notification:NSNotification) -> Void {
        //let userInfo = notification.userInfo
        //print("reset notification: \(userInfo))")
        self.meters = 0.00
        self.km = 0.00
        self.miles = 0.000
    }
    
    func resetIM(notification:NSNotification) -> Void {
        self.imMeters = 0.00
        self.imMiles = 0.000
        self.imKM = 0.0
    }
    
    func resetBoth(notification:NSNotification) -> Void {
        self.meters = 0.00
        self.miles = 0.000
        self.imMeters = 0.00
        self.imMiles = 0.000
        self.imKM = 0.0
        self.km = 0.0
    }
    
    
    func factorChanged(notification:NSNotification) -> Void {
        let userInfo = notification.userInfo
        let newFactor = userInfo!["factor"]!
//        print("ChangeFactor Notification: \(newFactor) \(self.meters)")
        self.factor = newFactor as! Float64
        let distanceInMiles:Float64 = ((self.meters * 0.000621371) * self.factor)
        self.miles = distanceInMiles
        let distanceInMeters:Float64 = ((self.imMeters * 0.000621371))
        self.imMiles = distanceInMeters
        self.km = (self.meters/1000) * self.factor
        self.makeLocationNotification()
    }
    
    func dummyLocationNotification() {
        print("dummy")
//        let updateChoices = self.selectedCounters
//
//        switch updateChoices
//        {
//        case "both":
//            self.meters += (0.01/0.00062137)
//            self.imMeters += (0.01/0.00062137)
//        case "om":
//            self.meters += (0.01/0.00062137)
//        case "im":
//            self.imMeters += (0.01/0.00062137)
//        default:
//            break;
//        }
        
        let distanceInMiles:Float64 = ((self.meters * 0.000621371))
        self.miles = distanceInMiles * self.factor
        let distanceInMeters:Float64 = ((self.imMeters * 0.000621371))
        self.imMiles = distanceInMeters
        self.km = (self.meters/1000)
        self.imKM = (self.imMeters/1000)
        
        let userInfo = [
            "timestamp":NSDate(),
            "course":0.0,
            "miles":miles,
            "imMiles":self.imMiles,
            "km":self.km,
            "imKM": self.imKM,
            "speed":0,
            "latitude":44.875328,
            "longitude": -91.939003,
            "horizontalAccuracy":5]
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo as [NSObject : AnyObject])

    }
    func plusOne(notification:NSNotification) -> Void {
        let updateChoices = self.selectedCounters
        
        switch updateChoices
        {
        case "both":
            self.meters += (0.01/0.00062137)
            self.imMeters += (0.01/0.00062137)
        case "om":
            self.meters += (0.01/0.00062137)
        case "im":
            self.imMeters += (0.01/0.00062137)
        default:
            break;
        }
        guard let _ = self.fromLocation.last
            else {
                dummyLocationNotification()
                return
        }

        
        let distanceInMiles:Float64 = ((self.meters * 0.000621371))
        self.miles = distanceInMiles * self.factor
        let distanceInMeters:Float64 = ((self.imMeters * 0.000621371))
        self.imMiles = distanceInMeters
        self.km = (self.meters/1000)
        self.imKM = (self.imMeters/1000)
        
        let userInfo = [
            "timestamp":NSDate(),
            "course":0.0,
            "miles":miles,
            "imMiles":self.imMiles,
            "km":self.km,
            "imKM": self.imKM,
            "speed":Int(self.fromLocation.last!.speed * 2.23694),
            "latitude":self.fromLocation.last!.coordinate.latitude,
            "longitude":self.fromLocation.last!.coordinate.longitude,
            "horizontalAccuracy":self.fromLocation.last!.horizontalAccuracy]
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo as [NSObject : AnyObject])
    }
    
    func minusOne(notification:NSNotification) -> Void {
        let updateChoices = self.selectedCounters
        
        switch updateChoices
        {
        case "both":
            self.meters -= (0.01/0.00062137)
            self.imMeters -= (0.01/0.00062137)
        case "om":
            self.meters -= (0.01/0.00062137)
        case "im":
            self.imMeters -= (0.01/0.00062137)
        default:
            break;
        }
        
        if self.meters < 0.0 {
            self.meters = 0.0
        }
        if self.imMeters < 0.0 {
            self.imMeters = 0.0
        }
        guard let _ = self.fromLocation.last
            else {
                dummyLocationNotification()
                return
        }
        
        let distanceInMiles:Float64 = ((self.meters * 0.000621371))
        self.miles = distanceInMiles  * self.factor
        let distanceInMeters:Float64 = ((self.imMeters * 0.000621371))
        self.imMiles = distanceInMeters
        self.imKM = (self.imMeters/1000)
        
        let userInfo = [
            "timestamp":NSDate(),
            "course":0.0,
            "miles":miles,
            "imMiles":self.imMiles,
            "km":self.km,
            "imKM": self.imKM,
            "speed":Int(self.fromLocation.last!.speed * 2.23694),
            "latitude":self.fromLocation.last!.coordinate.latitude,
            "longitude":self.fromLocation.last!.coordinate.longitude,
            "horizontalAccuracy":self.fromLocation.last!.horizontalAccuracy]
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo as [NSObject : AnyObject])
    }
    
    func milesFixForOc(notification:NSNotification) {
        var userInfo = notification.userInfo
        
        let newMileage = userInfo!["newMileage"] as! Float64
        let newMilesAsKM = newMileage * 1.60934
        self.meters = newMilesAsKM * 1000
        let distanceInMiles:Float64 = ((self.meters * 0.000621371))
        self.miles = distanceInMiles
        let distanceInMeters:Float64 = ((self.imMeters * 0.000621371))
        self.imMiles = distanceInMeters
        self.imKM = (self.imMeters/1000)
    }
    
    func setMileage(notification:NSNotification) -> Void {
        var userInfo = notification.userInfo
//        print("setMileage notification: \(userInfo!)")
        
        guard let newMileageString = userInfo!["newMileage"]
            else {
                print("nil value, guard used")
                return
        }
        let newMileage = newMileageString as! Double
//        let newMileage = userInfo!["newMileage"] as! Float64
        let newMilesAsKM = newMileage * 1.60934
        self.meters = newMilesAsKM * 1000
        let distanceInMiles:Float64 = ((self.meters * 0.000621371))
        self.miles = distanceInMiles
        let distanceInMeters:Float64 = ((self.imMeters * 0.000621371))
        self.imMiles = distanceInMeters
        self.imKM = (self.imMeters/1000)
        
//        userInfo!["currentLocation"] = self.currentLocations.last!

        userInfo!["course"] = 180.0 // Fake
        userInfo!["timestamp"] = NSDate()
        userInfo!["latitude"] = 45.0
        userInfo!["longitude"] = 93.0
        userInfo!["speed"] = 0.0
        userInfo!["km"] = self.meters
        userInfo!["miles"] = self.miles
        userInfo!["imMiles"] = self.imMiles
        userInfo!["imKM"] = self.imKM
        userInfo!["horizontalAccuracy"] = 5  //Fake
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo! as [NSObject : AnyObject])
    }
    
    func makeLocationNotification() -> Void {
        guard let _ = self.fromLocation.last
            else {
                self.dummyLocationNotification()
                return
        }
        let userInfo = [
//            "currentLocation":self.currentLocations.last!,
            "course":180.0, // Fake
            "timestamp":self.currentLocations.last!.timestamp,
            "km":self.meters,
            "miles":self.miles,
            "imMiles":self.imMiles,
            "imKM": self.imKM,
            "speed":Int(self.currentLocations.last!.speed * 2.23694),
            "latitude":self.currentLocations.last!.coordinate.latitude,
            "longitude":self.currentLocations.last!.coordinate.longitude,
            "horizontalAccuracy":self.currentLocations.last!.horizontalAccuracy]
//        print("makeLocationNotification \(userInfo))")
        
        NSNotificationCenter.defaultCenter().postNotificationName("LOCATION_AVAILABLE", object: nil, userInfo: userInfo as [NSObject : AnyObject])
    }
    
}