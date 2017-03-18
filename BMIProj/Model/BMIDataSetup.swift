//
//  BMIDataSetup.swift
//  BMIProj
//
//  Created by Abisola Adeniran on 2017-03-16.
//  Copyright © 2017 Adeniran  Abisola. All rights reserved.
//

import UIKit

class BMIDataSetup {
    
    var bmiDataSet: [BMIData] = []
    
    // add BMI to a list of BMIData
    func addBMI(bmiData: BMIData){
        bmiDataSet.append(bmiData)
    }
    
    //save all BMI data into local storage
    func saveBMI(){
        var items: [Data] = []
        for bmiData in bmiDataSet {
            let item = NSKeyedArchiver.archivedData(withRootObject: bmiData)
            items.append(item)
            
        }
        UserDefaults.standard.set(items, forKey: LocalDBKeys.bmiData)
    }
    
    //get all data from 
    func loadAllBMI(){
        bmiDataSet = []
        guard let savedBMI = UserDefaults.standard.array(forKey: LocalDBKeys.bmiData) else { return }
        for savedData in savedBMI {
            guard let bmiData = NSKeyedUnarchiver.unarchiveObject(with: savedData as! Data) as? BMIData else { continue }
            addBMI(bmiData: bmiData)
        }
    }
    
    func removeBMI(indexInArray: Int){
        bmiDataSet.remove(at: indexInArray)
        saveBMI()
    }
    
    func removeAllBMI(){
        bmiDataSet.removeAll()
        saveBMI()
    }
}

struct LocalDBKeys {
    static let bmiData = "bmiData"
}
