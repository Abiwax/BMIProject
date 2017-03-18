//
//  BMIData.swift
//  BMIProj
//
//  Created by Abisola Adeniran on 2017-03-16.
//  Copyright © 2017 Adeniran  Abisola. All rights reserved.
//

import UIKit

struct BMIDataKeys {
    static let id = "id"
    static let day = "day"
    static let date = "date"
    static let weight = "weight"
    static let height = "height"
    static let bmi = "bmi"
}


class BMIData: NSObject, NSCoding {
    
    var id: String
    var day: String
    var date: String
    var weight: String
    var height: String
    var bmi: String
    
    
    init(id: String, day: String, date: String, weight: String, height: String, bmi: String) {
        self.id = id
        self.day = day
        self.date = date
        self.weight = weight
        self.height = height
        self.bmi = bmi
    }
    
    
    //required for NSCoding
    required init?(coder decoder: NSCoder) {
        id = decoder.decodeObject(forKey: BMIDataKeys.id) as! String
        day = decoder.decodeObject(forKey: BMIDataKeys.day) as! String
        date = decoder.decodeObject(forKey: BMIDataKeys.date) as! String
        weight = decoder.decodeObject(forKey: BMIDataKeys.weight) as! String
        height = decoder.decodeObject(forKey: BMIDataKeys.height) as! String
        bmi = decoder.decodeObject(forKey: BMIDataKeys.bmi) as! String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: BMIDataKeys.id)
        coder.encode(day, forKey: BMIDataKeys.day)
        coder.encode(date, forKey: BMIDataKeys.date)
        coder.encode(weight, forKey: BMIDataKeys.weight)
        coder.encode(height, forKey: BMIDataKeys.height)
        coder.encode(bmi, forKey: BMIDataKeys.bmi)
    }
}

