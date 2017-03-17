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
    
    let store = UserDefaults.standard
    var tableObjects = [[String: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        store.synchronize()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableData()
            self.animateTable()
            
        })
        
    }
    
    func tableData(){
        //Retrieve data from Local Storage
        let json = store.array(forKey: "jsonData")
        if json != nil{
            let data = JSON(json!)
            for result in data.arrayValue {
                let date = result["date"].stringValue
                let weight = result["weight"].stringValue
                let height = result["height"].stringValue
                let bmi =  result["bmi"].stringValue
                let obj = ["date": date,"weight": weight, "height": height, "bmi": bmi]
                tableObjects.append(obj)
            }
            
        }else{
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
        return tableObjects.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath)
        let object = tableObjects[indexPath.row]
        cell.textLabel!.text = object["date"]
        cell.detailTextLabel!.text = "Weight: \(object["weight"]!), Height: \(object["height"]!), BMI: \(object["bmi"]!)"
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
    
    
    func animateTable() {
        tableView.reloadData()
        
        let cells = tableView.visibleCells
        let tableHeight: CGFloat = tableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }
        
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animate(withDuration: 1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0);
                }, completion: nil)
            
            index += 1
        }
        
    }
}
