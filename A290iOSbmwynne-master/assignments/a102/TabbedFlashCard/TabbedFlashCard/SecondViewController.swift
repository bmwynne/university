//
//  SecondViewController.swift
//  TabbedFlashCard
//
//  Created by Brandon Wynne on 9/19/16.
//  Copyright © 2016 A290 Spring 2016 - bmwynne, jfbinzer. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    
    var appDelegate: AppDelegate?
    var myFlashCardModel: FlashCardModel?
    
    @IBOutlet weak var question_text_field: UITextField!
    @IBOutlet weak var answer_text_field: UITextField!
    
    
    @IBAction func button_ok_action(sender: AnyObject) {
        self.appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        self.myFlashCardModel = self.appDelegate?.myFlashCardModel
        
        self.myFlashCardModel?.question_array[(myFlashCardModel?.current_question_index)! + 1] = question_text_field.text
        
        self.myFlashCardModel?.answer_array[(myFlashCardModel?.current_question_index)! + 1] =
            answer_text_field.text
        
        print ("self.question_text_field.text = \(self.question_text_field.text)")
        print ("self.answer_text_field.text = \(self.answer_text_field.text)")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.question_text_field.text = "this is where the question will appear"
        self.answer_text_field.text = "this is where the answer will appear"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

