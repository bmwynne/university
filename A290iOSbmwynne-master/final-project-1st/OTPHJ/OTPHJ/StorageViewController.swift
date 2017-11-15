//
//  SecondViewController.swift
//  OTPHJ
//
//  Created by Brandon Wynne on 10/11/16.
//  Copyright © 2016 A290 Spring 2016 - bmwynne, jfbinzer. All rights reserved.
//

import UIKit
import CoreData

class StorageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var Greeting: UILabel!
    @IBOutlet weak var CoordTableView: UITableView!
    var names = [String]()
    
    @IBAction func addCoord(sender: AnyObject) {
        
        let alert = UIAlertController(title: "New Location",
                                      message: "Add your location",
                                      preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .Default,
                                       handler: { (action:UIAlertAction) -> Void in
                                        
                                        let textField = alert.textFields!.first
                                        self.names.append(textField!.text!)
                                        print(self.names)
                                        self.CoordTableView.reloadData()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert,
                              animated: true,
                              completion: nil)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CoordTableView.delegate = self
        CoordTableView.dataSource = self
        Greeting.text = "Hello \(mainVariables.name)"
        title = "\"The List\""
        CoordTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    func tableView(tableView: UITableView,numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = names[indexPath.row]
        
        
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

