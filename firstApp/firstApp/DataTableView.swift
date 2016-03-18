//
//  DataTableView.swift
//  firstApp
//
//  Created by Adeniran  Abisola on 2016-03-12.
//  Copyright © 2016 Adeniran  Abisola. All rights reserved.
//

import UIKit
import SwiftyJSON



class DataTableView: UITableViewController{
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var tableObjects = [[String: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
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
        
        return cell
    }
    override
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
    }
    
    
    func animateTable() {
        
    }
    
    
    
}
