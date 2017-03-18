//
//  ViewController.swift
//  firstApp
//
//  Created by Adeniran  Abisola & Mahnoush Mohammadi on 2016-02-26.
//  Copyright © 2016 Abisola & Mahnoush. All rights reserved.
//

import UIKit
import Social
import SwiftyJSON
import Charts
import HealthKit



class ViewController: UIViewController{
    
    
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var notificationText: UILabel!
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    var dataSet: LineChartDataSet!
    
    let bmiDataSetUp = BMIDataSetup()
    var bmiDataSet: [BMIData] = []
    
    var cellDescriptors: NSMutableArray!
    var visibleRowsPerSection = [[Int]]()
    
    // Set the types to read and write to from HK Store
    let weightQty = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
    let heightQty = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
    let bmiQty = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)
    
    //Declaring the table object
    var objects = [[String: String]]()
    
    var timeSelected: UITextField!
    var justOnce:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Calling the function that makes HealthKit authorization request
        authorizeHealthKit()
        self.welcome()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.chartData()
        
    }
    
    func chartData(){
        let plusButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewController.promptForMsg))
        self.navigationItem.setRightBarButtonItems([plusButtonItem], animated: true)
        
        processResult()
        
        
    }
    
    func processResult(){
        //Retrieving the content of the mongo database via node.js
        let urlString = "http://127.0.0.1:4551/retrieve"
        if let url = URL(string: urlString){
            if let data = try? Data(contentsOf: url, options: []){
                let json = JSON(data: data)
                
                if !(json.null != nil){
                    parseJSON(json)
                }else{
                    displayMyAlertMessage("Non 200 Status Code received")
                }
            }
            else{
                displayMyAlertMessage("Unable to get the URL content, your server is not running")
            }
        }
        else{
            displayMyAlertMessage("urlString was not valid URL")
        }
    }
    
    func promptForMsg()
    {
        let ac = UIAlertController(title: "Enter your height and weight:", message: nil, preferredStyle: .alert)
        ac.addTextField{(textField: UITextField) in
            let datePickerView  : UIDatePicker = UIDatePicker()
            datePickerView.datePickerMode = UIDatePickerMode.date
            textField.inputView = datePickerView
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.medium
            let strDate = dateFormatter.string(from: currentDate)
            textField.text = strDate
            self.timeSelected = textField
            
            datePickerView.addTarget(self, action: #selector(ViewController.handleDatePicker(_:)), for: UIControlEvents.valueChanged)
        }
        ac.addTextField { (textField: UITextField!) in
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.placeholder = "Mass (kg)"
        }
        ac.addTextField { (textField: UITextField!) in
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.placeholder = "Height (m)"
        }
        
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            
            [unowned self, ac] (action: UIAlertAction) in
            let date = String(ac.textFields![0].text!)
            let weight = Float(ac.textFields![1].text!)
            let height = Float(ac.textFields![2].text!)
            
            
            
            if(weight == nil || height == nil || (date?.isEmpty)!)
            {
                //Display alert Message
                self.displayMyAlertMessage("Enter a valid number");
                self.promptForMsg()
                //return;
            }
            else if(weight == 0 || height == 0)
            {
                //Display alert Message
                self.displayMyAlertMessage("Input the correct values");
                self.promptForMsg()
                // return;
            }
            else{
                
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"
                dateFormatter.timeStyle = .short
                let time = dateFormatter.string(from: currentDate)
                let currentDay = Date()
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEE"
                let day = dayFormatter.string(from: currentDay)
                
                let bmi = weight! / (height! * height!)
                
                
                //Insert into table
                
                let postString = "day=\(day)&date=\(date!), \(time)&weight=\(String(format:"%.2f",weight!))&height=\(String(format:"%.2f",height!))&bmi=\(String(format:"%.2f",bmi))";
                
                
                let myURL:URL = URL(string: "http://127.0.0.1:4551/store")!
                var request = URLRequest(url: myURL);
                request.httpMethod = "POST"
                request.httpBody = postString.data(using: String.Encoding.utf8)!
                
                let session = URLSession.shared
                let task = session.dataTask(with: request){ (data, response, error) -> Void in
                    
                    if error != nil {
                        print("error=\(error)")
                        return
                    }
                    
                    
                    if response != nil{
                        self.processResult()
                        
                    }
                }
                task.resume()
                
                self.labelText.text = "Your BMI is \(String(format:"%.2f",bmi))"
                // Save BMI and other values with current value
                self.saveBMIValues(Double(bmi), height: Double(height!), weight: Double(weight!), date: Date())
            }
            
        }
        
        ac.addAction(submitAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        ac.addAction(cancelAction)
        
        present(ac, animated: true, completion: nil)
        labelText.text = "Lets begin"
        self.notificationText.isHidden = true
    }
    
    func parseJSON(_ json: JSON){
        if(json == []){
            self.notificationText.isHidden = false
            self.notificationText.text = "Click on the plus sign to add your bmi data."
            lineChartView.clear()
            self.labelText.text = ""
        }
        else{
            self.bmiDataSetUp.bmiDataSet = []
            for result in json.arrayValue {
                let id = result["_id"].stringValue
                let date = result["date"].stringValue
                let weight = result["weight"].stringValue
                let height = result["height"].stringValue
                let bmi =  result["bmi"].stringValue
                let day = result["day"].stringValue
                let bmiValue = BMIData(id: id, day: day, date: date, weight: weight, height: height, bmi: bmi)
                self.bmiDataSetUp.addBMI(bmiData: bmiValue)
                
            }
            self.bmiDataSet = self.bmiDataSetUp.bmiDataSet
            self.bmiDataSetUp.saveBMI()
            if bmiDataSet.count > 0 {
                //Call the method that draws the chart
                setChart(bmiDataSet: bmiDataSet)
                
            }
            
        }
    }
    
    //Date picker formatter
    func handleDatePicker(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        let strDate = dateFormatter.string(from: sender.date)
        timeSelected.text = strDate
    }
    
    //Chart View
    func setChart(bmiDataSet: [BMIData]) {
        
        var entries: [ChartDataEntry] = Array()
        for bmiData in bmiDataSet
        {
            let index = bmiDataSet.index{$0 === bmiData}
            
            entries.append(ChartDataEntry(x: Double(index!), y: Double(bmiData.bmi)!, data: bmiData.date as AnyObject?))
        }
        
        dataSet = LineChartDataSet(values: entries, label: "BMI Value")
        
        lineChartView.backgroundColor = NSUIColor.clear
        lineChartView.leftAxis.axisMinimum = 0.0
        lineChartView.rightAxis.axisMinimum = 0.0
        lineChartView.data = LineChartData(dataSet: dataSet)
        self.lineChartView.animate(xAxisDuration: 0.69, yAxisDuration: 0.69, easingOption: .easeInBounce)
        
        
    }
    
    func saveBMIValues(_ bmi:Double, height:Double, weight:Double, date:Date ) {
        
        let weightValue = HKQuantity(unit: HKUnit.gramUnit(with: .kilo),
                                     doubleValue: weight)
        
        let heightValue = HKQuantity(unit: HKUnit.meter(),
                                     doubleValue: height)
        let bmiVal = HKQuantity(unit: HKUnit.count(), doubleValue: bmi)
        
        // Create BMI, Height and Weight Samples
        let weightSave = HKQuantitySample(type: self.weightQty!, quantity: weightValue, start: date, end: date)
        let heightSave = HKQuantitySample(type: self.heightQty!, quantity: heightValue, start: date, end: date)
        let bmiSave = HKQuantitySample(type: self.bmiQty!, quantity: bmiVal, start: date, end: date)
        
        // Save the sample in the store
        self.healthKitStore.save([weightSave, heightSave, bmiSave], withCompletion: { (success, error) -> Void in
            guard success else {
                // Perform proper error handling here...
                fatalError("An error occurred while saving the " +
                    "workout: \(error?.localizedDescription)")
            }
            if success{
                DispatchQueue.main.async(execute: { () -> Void in
                    self.notificationText.isHidden = false
                    self.notificationText.text = "BMI successfully saved in database and HealthKit"
                })
            }
        })
        
    }
    
    func authorizeHealthKit(){
        
        //To signal our interest in sharing weight,height and bmi quantity samples
        
        let toShareTypes: NSSet = {
            return NSSet(objects: weightQty!, heightQty!, bmiQty!)
        }()
        
        // To request read permissions for weight, height and bmi
        
        let readTypes: NSSet = {
            return NSSet(objects: weightQty!, heightQty!, bmiQty!)
        }()
        
        // if able to access health data from health kit, request authorization to share and read above samples
        
        if HKHealthStore.isHealthDataAvailable(){
            
            self.healthKitStore.requestAuthorization(toShare: (toShareTypes as! Set<HKSampleType>),
                                                     read: (readTypes as! Set<HKObjectType>),
                                                     completion: {(success, error) -> Void in
                                                        if success && error == nil{
                                                            print("Successfully received authorization")
                                                        }
            })
        }
    }
    
    
}

extension UIViewController {
    
    func welcome()
    {
        let AlertOnce = UserDefaults.standard
        if(!AlertOnce.bool(forKey: "oneTimeAlert")){
            
            let message = "Hi, Welcome to your BMI App, Your default screen is your graph page. Click on your tabs to other options. Have fun!!!";
            let myAlert = UIAlertController(title: "Welcome", message: message, preferredStyle: UIAlertControllerStyle.alert);
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
            myAlert.addAction(okAction);
            self.present(myAlert, animated: true, completion: nil);
            AlertOnce.set(true , forKey: "oneTimeAlert");
            AlertOnce.synchronize()}
        
    }
    
    func displayMyAlertMessage(_ userMessage: String)
    {
        let myAlert = UIAlertController(title: "Information", message: userMessage, preferredStyle: UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
        myAlert.addAction(okAction);
        self.present(myAlert, animated: true, completion: nil);
        
    }
}

