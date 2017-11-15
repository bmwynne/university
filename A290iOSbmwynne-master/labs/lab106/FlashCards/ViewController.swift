//
//  ViewController.swift
//  FlashCards
//
//  Created by Brandon Wynne on 9/1/16.
//  Copyright © 2016 Brandon Wynne. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var answer_label  : UILabel!
    @IBOutlet var question_label: UILabel!
    
    let my_FlashCardModel = FlashCardModel()
    
    var is_question_asked = false
    
    @IBAction func show_question(sender: AnyObject) {
        let l_question: String =
            my_FlashCardModel.get_next_question()
        self.question_label.text = l_question
        self.answer_label.text = "Try Guessing..."
        
    }
    
    @IBAction func show_answer(sender: AnyObject) {
        let l_answer : String =
            my_FlashCardModel.get_answer()
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

