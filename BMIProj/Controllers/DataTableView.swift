//
//  DataTableView.swift
//  firstApp
//
//  Created by Mahnoush Mohammadi on 2016-03-12.
//  Copyright © 2016 Mahnoush Mohammadi. All rights reserved.
//

import UIKit
import SwiftyJSON

//<div>Icons made by <a href="http://www.flaticon.com/authors/roundicons" title="Roundicons">Roundicons</a> from <a href="http://www.flaticon.com" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>

class DataTableView: UITableViewController{
    
    let bmiDataSetUp = BMIDataSetup()
    var bmiDataSet: [BMIData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableData()
            
        })
        
    }
    
    func tableData(){
        //Retrieve data from Local Storage
        
        self.bmiDataSetUp.loadAllBMI()
        bmiDataSet = self.bmiDataSetUp.bmiDataSet
        
        if bmiDataSet.isEmpty{
            displayMyAlertMessage("There is no data to display")
        }
        tableView.reloadData()
        
    }
    
    func displayMyAlertMessage(_ userMessage: String)
    {
        let myAlert = UIAlertController(title: "Information", message: userMessage, preferredStyle: UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
        myAlert.addAction(okAction);
        self.present(myAlert, animated: true, completion: nil);
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bmiDataSet.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! BMIViewCell
        let object = bmiDataSet[indexPath.row]
        cell.dateLabel.text = "\(object.day): (\(object.date))"
        
        cell.weightLabel!.text = "\(object.weight)kg"
        cell.heightLabel!.text = "\(object.height)m"
        cell.bmiLabel!.text = "\(object.bmi)"
        return cell
    }
    override
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You have selected cell \(indexPath.row)!")
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "labelCell")! as UITableViewCell
        headerCell.backgroundColor = UIColor.blue
        headerCell.textLabel!.textColor = UIColor.white
        headerCell.textLabel!.text = ""
        headerCell.detailTextLabel!.text = ""
        return headerCell
    }
    
    

}
