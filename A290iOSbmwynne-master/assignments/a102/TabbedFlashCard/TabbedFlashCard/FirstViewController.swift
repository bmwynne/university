//
//  FirstViewController.swift
//  TabbedFlashCard
//
//  Created by Brandon Wynne on 9/19/16.
//  Copyright © 2016 A290 Spring 2016 - bmwynne, jfbinzer. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    
    var appDelegate: AppDelegate?
    var myFlashCardModel: FlashCardModel?
    
    @IBOutlet var answer_label  : UILabel!
    @IBOutlet var question_label: UILabel!
    
    
    var is_question_asked = false
    
    @IBAction func show_question(sender: AnyObject) {
        self.appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        self.myFlashCardModel = self.appDelegate?.myFlashCardModel
        let l_question : String = self.myFlashCardModel!.get_next_question()
        
        self.question_label.text = l_question
        self.answer_label.text = "Try Guessing..."
    }
    
    @IBAction func show_answer(sender: AnyObject) {
        self.appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        self.myFlashCardModel = self.appDelegate?.myFlashCardModel
        let l_answer : String = self.myFlashCardModel!.get_answer()
            
        self.answer_label.text = l_answer
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

