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
    
    let store = UserDefaults.standard
    
    var cellDescriptors: NSMutableArray!
    var visibleRowsPerSection = [[Int]]()
    
    // Set the types to read and write to from HK Store
    let weightQty = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
    let heightQty = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
    let bmiQty = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)
    
    //Declaring the table object
    var objects = [[String: String]]()
    
    //declaring the graph x and y axis
    var dateValue = [String]()
    var bmiValue = [Double]()
    
    var timeSelected: UITextField!
    var justOnce:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        store.removeObject(forKey: "jsonData")
        store.synchronize()
        //Calling the function that makes HealthKit authorization request
        authorizeHealthKit()
        self.welcome()
        //Call the method that retrieves data
        self.chartData()
        
        //Call the method that draws the chart
        setChart(dateValue, values: bmiValue)
        
    }
    
    func chartData(){
        let plusButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewController.promptForMsg))
        
        //Retrieving the content of the mongo database via node.js
        let urlString = "http://127.0.0.1:4551/retrieve"
        
        
        if let url = URL(string: urlString){
            if let data = try? Data(contentsOf: url, options: []){
                let json = JSON(data: data)
                
                if json != nil{
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
        let ac = UIAlertController(title: "Enter Message", message: nil, preferredStyle: .alert)
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
                
                let defaults = UserDefaults.standard
                defaults.set(weight, forKey: "Weight");
                defaults.set(height, forKey: "Height");
                defaults.set(date, forKey: "date");
                defaults.synchronize();
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"
                dateFormatter.timeStyle = .short
                let time = dateFormatter.string(from: currentDate)
                let currentDay = Date()
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEE dd,HH:mm"
                let day = dayFormatter.string(from: currentDay)
                let myWeight = defaults.double(forKey: "Weight")
                let myHeight = defaults.double(forKey: "Height")
                
                let bmi = myWeight / (myHeight * myHeight)
                
                
                //Insert into table
                
                let postString = "day=\(day)&date=\(date), \(time)&weight=\(String(format:"%.2f",myWeight))&height=\(String(format:"%.2f",myHeight))&bmi=\(String(format:"%.2f",bmi))";
                NSLog("PostData: %@",postString);
                
                
                
                let myURL:URL = URL(string: "http://127.0.0.1:4551/store")!
                let request = NSMutableURLRequest(url: myURL);
                request.httpMethod = "POST"
                request.httpBody = postString.data(using: String.Encoding.utf8)!
                
                let session = URLSession.shared
                let task = session.dataTask(with: request){ (data, response, error) -> Void in
                    
                    if error != nil {
                        print("error=\(error)")
                        return
                    }
                    
                    self.bmiValue.removeAll()
                    self.dateValue.removeAll()
                    self.lineChartView.data?.clearValues()
                    self.viewDidLoad()
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        self.view.reloadInputViews()
                        self.lineChartView.reloadInputViews()
                        self.lineChartView.animate(xAxisDuration: 0.69, yAxisDuration: 0.69, easingOption: .easeInBounce)
                        
                    })
                    if response != nil{
                        print("Data inserted correctly")
                    }
                    
                    
                }
                task.resume()
                
                self.labelText.text = "Your BMI is \(String(format:"%.2f",bmi))"
                // Save BMI and other values with current value
                self.saveBMIValues(bmi, height: Double(height!), weight: Double(weight!), date: Date())
            }
            
        }
        
        ac.addAction(submitAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        ac.addAction(cancelAction)
        
        present(ac, animated: true, completion: nil)
        labelText.text = "You clicked the plus sign"
        self.notificationText.isHidden = true
    }
    
    
    func parseJSON(_ json: JSON){
        if(json == []){
            self.notificationText.isHidden = false
            self.notificationText.text = "Click on the plus sign to add your bmi data."
        }
        else{
            for result in json.arrayValue {
                let date = result["date"].stringValue
                let weight = result["weight"].stringValue
                let height = result["height"].stringValue
                let bmi =  result["bmi"].stringValue
                let obj = ["date": date,"weight": weight, "height": height, "bmi": bmi]
                let dateV = result["day"].stringValue
                objects.append(obj)
                bmiValue.append(result["bmi"].doubleValue)
                dateValue.append(dateV)
                store.set(objects, forKey: "jsonData");
                // store.synchronize()
                
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func displayMyAlertMessage(_ userMessage: String)
    {
        let myAlert = UIAlertController(title: "Information", message: userMessage, preferredStyle: UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
        myAlert.addAction(okAction);
        self.present(myAlert, animated: true, completion: nil);
        
    }
    
    //Table View
    
    
    //Date picker formatter
    func handleDatePicker(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        let strDate = dateFormatter.string(from: sender.date)
        timeSelected.text = strDate
    }
    
    //Chart View
    func setChart(_ dataPoints: [String], values: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(x: values[i], y: Double(i))
            dataEntries.append(dataEntry)
        }
        
        
        let ll = ChartLimitLine(limit: 24.9, label: "Target")
        lineChartView.rightAxis.addLimitLine(ll)
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "BMI Value")
        let lineChartData = LineChartData(xVals: dataPoints, dataSet: lineChartDataSet)
        //lineChartView.backgroundColor = UIColor(red: 252/255, green: 242/255, blue: 222/255, alpha: 1)
        
        lineChartView.xAxis.labelPosition = .bottom
        lineChartDataSet.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        lineChartDataSet.circleColors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        
        lineChartView.data = lineChartData
        
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
                fatalError("*** An error occurred while saving the " +
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
    func welcome()
    {
        let AlertOnce = UserDefaults.standard
        if(!AlertOnce.bool(forKey: "oneTimeAlert")){
            
            let message = "Hi, Welcome to your BMI App, Your default screen is your graph page. Click on the menu to see your table. Have fun!!!";
            let myAlert = UIAlertController(title: "Welcome", message: message, preferredStyle: UIAlertControllerStyle.alert);
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
            myAlert.addAction(okAction);
            self.present(myAlert, animated: true, completion: nil);
            AlertOnce.set(true , forKey: "oneTimeAlert");
            AlertOnce.synchronize()}
        
    }
    
}

