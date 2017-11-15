//
//  ViewController.swift
//  Hello Touch bmwynne
//
//  Created by Brandon Wynne on 9/18/16.
//  Copyright © 2016 Brandon Wynne. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var tapsLabel:UILabel!
    @IBOutlet var touchesLabel:UILabel!
    
    func updateLabelsFromTouches(touches: NSSet) {
        let theTouchObject = touches.anyObject() as! UITouch
        let theNumOfTaps = theTouchObject.tapCount
        let theTapsMessage = "\(theNumOfTaps) taps detected in sequence"
        self.tapsLabel.text = theTapsMessage
        let theNumOfTouches = touches.count
        let theTouchesMessage = "\(theNumOfTouches) touches detected at once"
        self.touchesLabel.text = theTouchesMessage
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        let start = touches.first!.locationInView(self.view)
        self.messageLabel.text = "Touches Began at \(start.x) \(start.y)"
        updateLabelsFromTouches(event!.allTouches()!)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let current = touches.first!.locationInView(self.view)
        self.messageLabel.text = "Touches Moved to \(current.x) \(current.y)"
        updateLabelsFromTouches(event!.allTouches()!)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let end = touches.first!.locationInView(self.view)
        self.messageLabel.text = "Touches Ended at \(end.x) \(end.y)"
        updateLabelsFromTouches(event!.allTouches()!)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        let end = touches?.first!.locationInView(self.view)
        self.messageLabel.text = "Touch Cancelled  at \(end!.x) \(end!.y)"
        updateLabelsFromTouches(event!.allTouches()!)
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

