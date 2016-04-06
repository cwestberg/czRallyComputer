//
//  btPulseMileage.swift
//  CZRallyOdoComputer
//
//  Created by Clarence Westberg on 3/30/16.
//  Copyright © 2016 Clarence Westberg. All rights reserved.
//

import Foundation

class BTPulseMileage: NSObject {
    var factor = 5000
    var distance = 0
    
    func pulse() {
        distance = distance + factor
        
//        factor = Double(f) * 0.00000001
//        var pulses = 2000.0
//        pulses = 1.0/factor
//        var distance = Double(pulses) * factor
//        String(format: "%0.3f", distance)
    }
    
}
