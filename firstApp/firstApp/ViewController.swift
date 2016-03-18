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
    
    @IBOutlet weak var resultText: UILabel!
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var notificationText: UILabel!
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var lineChartView: LineChartView!
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    let store = NSUserDefaults.standardUserDefaults()
    
    var cellDescriptors: NSMutableArray!
    var visibleRowsPerSection = [[Int]]()
    
    // Set the types to read and write to from HK Store
    let weightQty = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
    let heightQty = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
    let bmiQty = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)
    
    //Declaring the table object
    var objects = [[String: String]]()
    
    //declaring the graph x and y axis
    var dateValue = [String]()
    var bmiValue = [Double]()
    
    var timeSelected: UITextField!
    var justOnce:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        self.revealViewController().rearViewRevealWidth = 190
        store.removeObjectForKey("jsonData")
        //Calling the function that makes HealthKit authorization request
        authorizeHealthKit()
        self.welcome()
        //Call the method that retrieves data
        self.chartData()
        
        //Call the method that draws the chart
        setChart(dateValue, values: bmiValue)
        
    }
    
    func chartData(){
        let plusButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "promptForMsg")
        let shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "shareTapped")
        self.navigationItem.setRightBarButtonItems([plusButtonItem,shareBarButtonItem], animated: true)
        
        //Retrieving the content of the mongo database via node.js
        let urlString = "http://nodeTrial.mybluemix.net/retrieve"
        
        
        if let url = NSURL(string: urlString){
            if let data = try? NSData(contentsOfURL: url, options: []){
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
        let ac = UIAlertController(title: "Enter Message", message: nil, preferredStyle: .Alert)
        ac.addTextFieldWithConfigurationHandler{(textField: UITextField) in
            let datePickerView  : UIDatePicker = UIDatePicker()
            datePickerView.datePickerMode = UIDatePickerMode.Date
            textField.inputView = datePickerView
            let currentDate = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            let strDate = dateFormatter.stringFromDate(currentDate)
            textField.text = strDate
            self.timeSelected = textField
            
            datePickerView.addTarget(self, action: Selector("handleDatePicker:"), forControlEvents: UIControlEvents.ValueChanged)
        }
        ac.addTextFieldWithConfigurationHandler { (textField: UITextField!) in
            textField.keyboardType = UIKeyboardType.DecimalPad
            textField.placeholder = "Mass (kg)"
        }
        ac.addTextFieldWithConfigurationHandler { (textField: UITextField!) in
            textField.keyboardType = UIKeyboardType.DecimalPad
            textField.placeholder = "Height (m)"
        }
        
        
        let submitAction = UIAlertAction(title: "Submit", style: .Default) {
            
            [unowned self, ac] (action: UIAlertAction) in
            let date = String(ac.textFields![0].text!)
            let weight = Float(ac.textFields![1].text!)
            let height = Float(ac.textFields![2].text!)
            
            
            
            if(weight == nil || height == nil || date.isEmpty)
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
            
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(weight, forKey: "Weight");
            defaults.setObject(height, forKey: "Height");
            defaults.setObject(date, forKey: "date");
            defaults.synchronize();
            let currentDate = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            dateFormatter.timeStyle = .ShortStyle
            let time = dateFormatter.stringFromDate(currentDate)
            let currentDay = NSDate()
            let dayFormatter = NSDateFormatter()
            dayFormatter.dateFormat = "EEE dd,HH:mm"
            let day = dayFormatter.stringFromDate(currentDay)
            let myWeight = defaults.doubleForKey("Weight")
            let myHeight = defaults.doubleForKey("Height")
            
            let bmi = myWeight / (myHeight * myHeight)
            
            
            //Insert into table
            
            let postString = "day=\(day)&date=\(date), \(time)&weight=\(String(format:"%.2f",myWeight))&height=\(String(format:"%.2f",myHeight))&bmi=\(String(format:"%.2f",bmi))";
            NSLog("PostData: %@",postString);
            
            
            
            let myURL:NSURL = NSURL(string: "http://nodeTrial.mybluemix.net/store")!
            let request = NSMutableURLRequest(URL: myURL);
            request.HTTPMethod = "POST"
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                data, response, error in
                if error != nil {
                    print("error=\(error)")
                    return
                }
                
                self.bmiValue.removeAll()
                self.dateValue.removeAll()
                self.lineChartView.data?.clearValues()
                self.viewDidLoad()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.view.reloadInputViews()
                    self.lineChartView.reloadInputViews()
                    self.lineChartView.animate(xAxisDuration: 0.69, yAxisDuration: 0.69, easingOption: .EaseInBounce)
                    
                })
                if response != nil{
                    print("Data inserted correctly")
                }
                
                
            }
            task.resume()
            
            self.resultText.hidden = false
            self.labelText.text = "Your BMI is \(String(format:"%.2f",bmi))"
            if(bmi > 18.5 && bmi < 24.9)
            {
                self.resultText.text = "It is in the normal range"
            }
            else if(bmi > 25.0 && bmi < 30)
            {
                self.resultText.text = "It is in the Over-weight range"
            }
            else if(bmi > 30.0 && bmi < 40)
            {
                self.resultText.text = "It is in the Obese range"
            }
            else if(bmi > 40.0)
            {
                self.resultText.text = "Your BMI is in the Morbidly Obese range"
            }
            else
            {
                self.resultText.text = "It is in the Under-weight range"
            }
            
            // Save BMI and other values with current value
                self.saveBMIValues(bmi, height: Double(height!), weight: Double(weight!), date: NSDate())
            }
            
        }
        
        ac.addAction(submitAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
        }
        ac.addAction(cancelAction)
        
        presentViewController(ac, animated: true, completion: nil)
        labelText.text = "You clicked the plus sign"
        self.notificationText.hidden = true
    }
    
    func shareTapped(){
        let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        vc.setInitialText("\(labelText.text!),  \(resultText.text!)")
        
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func parseJSON(json: JSON){
        if(json == []){
            self.notificationText.hidden = false
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
            store.setObject(objects, forKey: "jsonData");
            store.synchronize()
            
        }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func displayMyAlertMessage(userMessage: String)
    {
        let myAlert = UIAlertController(title: "Information", message: userMessage, preferredStyle: UIAlertControllerStyle.Alert);
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil);
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated: true, completion: nil);
        
    }
    
    //Table View
    
    
    //Date picker formatter
    func handleDatePicker(sender: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        let strDate = dateFormatter.stringFromDate(sender.date)
        timeSelected.text = strDate
    }
    
    //Chart View
    func setChart(dataPoints: [String], values: [Double]) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        
        let ll = ChartLimitLine(limit: 24.9, label: "Target")
        lineChartView.rightAxis.addLimitLine(ll)
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "BMI Value")
        let lineChartData = LineChartData(xVals: dataPoints, dataSet: lineChartDataSet)
        //lineChartView.backgroundColor = UIColor(red: 252/255, green: 242/255, blue: 222/255, alpha: 1)
        
        lineChartView.xAxis.labelPosition = .Bottom
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
            
            self.healthKitStore.requestAuthorizationToShareTypes((toShareTypes as! Set<HKSampleType>),
                readTypes: (readTypes as! Set<HKObjectType>),
                completion: {(success, error) -> Void in
                    if success && error == nil{
                        print("Successfully received authorization")
                    }
            })
        }
    }
    
    func saveBMIValues(bmi:Double, height:Double, weight:Double, date:NSDate ) {
        
        let weightValue = HKQuantity(unit: HKUnit.gramUnitWithMetricPrefix(.Kilo),
            doubleValue: weight)
        
        let heightValue = HKQuantity(unit: HKUnit.meterUnit(),
            doubleValue: height)
        let bmiVal = HKQuantity(unit: HKUnit.countUnit(), doubleValue: bmi)
        
        // Create BMI, Height and Weight Samples
        let weightSave = HKQuantitySample(type: self.weightQty!, quantity: weightValue, startDate: date, endDate: date)
        let heightSave = HKQuantitySample(type: self.heightQty!, quantity: heightValue, startDate: date, endDate: date)
        let bmiSave = HKQuantitySample(type: self.bmiQty!, quantity: bmiVal, startDate: date, endDate: date)
        
        // Save the sample in the store
        self.healthKitStore.saveObjects([weightSave, heightSave, bmiSave], withCompletion: { (success, error) -> Void in
            guard success else {
                // Perform proper error handling here...
                fatalError("*** An error occurred while saving the " +
                    "workout: \(error?.localizedDescription)")
            }
            if success{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notificationText.hidden = false
                self.notificationText.text = "BMI successfully saved in database and HealthKit"
                })
                }
        })
        
    }
    func welcome()
    {
        let AlertOnce = NSUserDefaults.standardUserDefaults()
        if(!AlertOnce.boolForKey("oneTimeAlert")){
            
            let message = "Hi, Welcome to your BMI App, Your default screen is your graph page. Click on the menu to see your table. Have fun!!!";
            let myAlert = UIAlertController(title: "Welcome", message: message, preferredStyle: UIAlertControllerStyle.Alert);
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil);
            myAlert.addAction(okAction);
            self.presentViewController(myAlert, animated: true, completion: nil);
            AlertOnce.setBool(true , forKey: "oneTimeAlert");
            AlertOnce.synchronize()}
        
    }
    
}

