//
//  DataTableView.swift
//  firstApp
//
//  Created by Mahnoush Mohammadi on 2016-03-12.
//  Copyright © 2016 Mahnoush Mohammadi. All rights reserved.
//

import UIKit
import SwiftyJSON



class DataTableView: UITableViewController{
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    let store = NSUserDefaults.standardUserDefaults()
    var tableObjects = [[String: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        store.synchronize()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableData()
            self.animateTable()
            
        })
        
    }
    
    func tableData(){
        //Retrieve data from Local Storage
        let json = store.arrayForKey("jsonData")
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
    
    func displayMyAlertMessage(userMessage: String)
    {
        let myAlert = UIAlertController(title: "Information", message: userMessage, preferredStyle: UIAlertControllerStyle.Alert);
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil);
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated: true, completion: nil);
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableObjects.count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("labelCell", forIndexPath: indexPath)
        let object = tableObjects[indexPath.row]
        cell.textLabel!.text = object["date"]
        cell.detailTextLabel!.text = "Weight: \(object["weight"]!), Height: \(object["height"]!), BMI: \(object["bmi"]!)"
        return cell
    }
    override
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You have selected cell \(indexPath.row)!")
        
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("labelCell")! as UITableViewCell
        headerCell.backgroundColor = UIColor.blueColor()
        headerCell.textLabel!.textColor = UIColor.whiteColor()
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
            cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
        }
        
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animateWithDuration(1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                cell.transform = CGAffineTransformMakeTranslation(0, 0);
                }, completion: nil)
            
            index += 1
        }
        
    }
}
