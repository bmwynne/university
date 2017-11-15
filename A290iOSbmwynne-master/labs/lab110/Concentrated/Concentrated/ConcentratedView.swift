//
//  ConcentratedView.swift
//  Concentrated
//
//  Created by Binzer, John Francis on 9/26/16.
//  Copyright © 2016 A290 jfbinzer. All rights reserved.
//

import UIKit

class ConcentratedView: UIView {
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath()
        for i in 1...5{
            path.addArcWithCenter(CGPoint(x: 100, y: 100),
                                  radius: 50 + 4*CGFloat(i),
                                  startAngle: 0,
                                  endAngle: 6.28,
                                  clockwise: true)
            path.stroke()
        }
    }
}
