//
//  FlashCardModel.swift
//  TabbedFlashCard
//
//  Created by Brandon Wynne on 9/19/16.
//  Copyright © 2016 A290 Spring 2016 - bmwynne, jfbinzer. All rights reserved.
//

import Foundation

class FlashCardModel {
    
    var question_array =
        [ 0: "What is your name?",
          1: "What is 42?",
          2: "What is the color of the sky?"]
    var answer_array   =
        [ 0: "My name is not important",
          1: "It's 6 times 7",
          2: "Kinda gray today."]
    
    var current_question_index = 0
    
    init () {
    }
    
    func get_next_question() -> String {
        current_question_index += 1
        if (current_question_index >= question_array.count) {
            current_question_index = 0
        }
        return question_array[current_question_index]!
    }
    
    func get_answer() -> String {
        return answer_array[current_question_index]!
    }
    
}
