//
//  ViewController.swift
//  test
//
//  Created by Binzer, John Francis on 10/3/16.
//  Copyright © 2016 Binzer, John Francis. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var teamLeaderLabel: UILabel!

    func refreshFields(){
        let myDefaults = NSUserDefaults.standardUserDefaults()
        teamLeaderLabel.text = myDefaults.stringForKey(teamLeaderKey)
        myDefaults.synchronize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshFields()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

