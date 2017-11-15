// Created by: Brandon Wynne
// Created on: September 11, 2016
// Last modified by: Brandon Wynne
// Last modified on: September 12, 2016


// -------------------------------------------------------------------------------------------------------
// Part A

let glasses_status = "new"

switch glasses_status {
    case "scratched":
        let glasses_order = "add scratch resistant coating"
    case "cant read":
        let glasses_order = "take a vision test"
    default:
        let glasses_order = "enjoy your new glasses"
}
// The error details that the switch must be ehaustive and that it needs the default case. This is expected
// for switch cases.

// -------------------------------------------------------------------------------------------------------
// Part B

func two_things(number_1:Float, number_2:Float) -> (sum: Float, prod: Float) {
    let sum  = number_1 + number_2
    let prod = number_1 * number_2
    return (sum, prod)
}

two_things(2.0, number_2: 2.0) // 4, 4
two_things(3.0, number_2: 2.0) // 5, 6
// Values check out

// -------------------------------------------------------------------------------------------------------
// Part C

let interesting_numbers = [
    "prime"    : [2, 3, 5, 7, 11, 13],
    "fibonacci": [1, 1, 2, 3, 5, 8],
    "square"   : [1, 4, 9, 16, 25],
]

var largest = 0
var key     = "null"

for (kind,  numbers) in interesting_numbers {
    for number in numbers {
        if number > largest {
            largest = number
            key = kind
        }
    }
}
print("the largest number is \(largest)")
print("the kind is \(key)")



// -------------------------------------------------------------------------------------------------------
// Part D

class Homework_102 {
    
    func glasses_type()-> String {
        let glasses_status = "new"
        var glasses_return = "null"
        switch glasses_status {
        case "scratched":
            let glasses_order = "add scratch resistant coating"
        case "cant read":
            let glasses_order = "take a vision test"
        default:
            let glasses_order = "enjoy your new glasses"
            
        glasses_return = glasses_order
        }
        return glasses_return
    }
    
    func two_things(number_1:Float, number_2:Float) -> (sum: Float, prod: Float) {
        let sum  = number_1 + number_2
        let prod = number_1 * number_2
        return (sum, prod)
    }
    
    func interesting_numbers() -> (key: String, value: Int) {
        let interesting_numbers = [
            "prime"    : [2, 3, 5, 7, 11, 13],
            "fibonacci": [1, 1, 2, 3, 5, 8],
            "square"   : [1, 4, 9, 16, 25],
            ]
        
        var largest = 0
        var key     = "null"
        
        for (kind,  numbers) in interesting_numbers {
            for number in numbers {
                if number > largest {
                    largest = number
                    key = kind
                }
            }
        }
        return (key, largest)
    }
}


let homework_102_object = Homework_102()
homework_102_object.glasses_type()
homework_102_object.two_things(2.0, number_2: 2.0)
homework_102_object.two_things(2.0, number_2: 3.0)
homework_102_object.interesting_numbers()












