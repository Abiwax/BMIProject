//
//  SuggestionViewController.swift
//  BMIProj
//
//  Created by Abisola Adeniran on 2017-03-17.
//  Copyright © 2017 Adeniran  Abisola. All rights reserved.
//

import UIKit
import Charts

class SuggestionViewController: UIViewController {
    
    @IBOutlet weak var resultText: UILabel!
    @IBOutlet var pieChartView: PieChartView!
    
    var dataSet: PieChartDataSet!
    let bmiDataSetUp = BMIDataSetup()
    var bmiDataSet: [BMIData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setupView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupView()
        
    }
    
    func setupView() {
        self.bmiDataSetUp.loadAllBMI()
        bmiDataSet = self.bmiDataSetUp.bmiDataSet
        if bmiDataSet.count > 0 {
            let length = bmiDataSet.count - 1
            let bmiData: BMIData! = bmiDataSet[length]
            let bmi: Double = Double(bmiData.bmi)!
            
            if(bmi > 18.5 && bmi < 24.9)
            {
                self.resultText.text = "Hi, Your BMI is in the normal range. You are doing well, Keep up the good work."
                self.includeChart(color: UIColor.green, bmiData: bmiData)
            }
            else if(bmi > 25.0 && bmi < 30)
            {
                self.resultText.text = "Hmmmm, your BMI seems to be in the Over-weight range, we need to work on that, take a step today."
                self.includeChart(color: UIColor.brown, bmiData: bmiData)
            }
            else if(bmi > 30.0 && bmi < 40)
            {
                self.resultText.text = "All i can say is, your BMI is in the Obese range, this doesn't seem good, lets work on it."
                self.includeChart(color: UIColor.orange, bmiData: bmiData)
            }
            else if(bmi > 40.0)
            {
                self.resultText.text = "Your BMI is in the Morbidly Obese range, you need to see a doctor for a advice."
                self.includeChart(color: UIColor.red, bmiData: bmiData)
            }
            else
            {
                self.resultText.text = "Hmmm, we need to get you eating, your BMI is in the Under-weight range."
                self.includeChart(color: UIColor.gray, bmiData: bmiData)
            }
        }
        else{
            self.resultText.text = "You currently have no BMI Data"
            self.pieChartView.clear()
            
        }
        
        
    }
    
    func includeChart(color: UIColor, bmiData: BMIData){
        var entries: [PieChartDataEntry] = Array()
        
        entries.append(PieChartDataEntry(value: Double(bmiData.bmi)!, label: bmiData.day))
        dataSet  = PieChartDataSet(values: entries, label: bmiData.date)
        
        
        pieChartView.backgroundColor = UIColor.clear
        dataSet.setColor(color)
        
        let paragraphStyle: NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        let centerText: NSMutableAttributedString = NSMutableAttributedString(string: "Your current BMI")
        centerText.setAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 15.0)!, NSParagraphStyleAttributeName: paragraphStyle], range: NSMakeRange(0, centerText.length))
        centerText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 18.0)!, NSForegroundColorAttributeName: UIColor.gray], range: NSMakeRange(6, centerText.length - 6))
        centerText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-LightItalic", size: 18.0)!, NSForegroundColorAttributeName: color], range: NSMakeRange(centerText.length - 11, 11))
        
        
        self.pieChartView.centerAttributedText = centerText
        
        pieChartView.data = PieChartData(dataSet: dataSet)
        
        pieChartView.isUserInteractionEnabled = true
        self.pieChartView.chartDescription?.text = "Recent BMI"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.pieChartView.animate(xAxisDuration: 0.0, yAxisDuration: 1.0)
    }
    
    
    
    
}
