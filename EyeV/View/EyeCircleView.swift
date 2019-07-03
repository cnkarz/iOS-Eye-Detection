//
//  EyeCircleView.swift
//  EyeV
//
//  Created by Cenk Arioz on 28.01.2019.
//  Copyright © 2019 Cenk Arioz. All rights reserved.
//

import UIKit

@IBDesignable class EyeCircleView: UIView {
    //MARK: Properties
    
    // Allows to manipulate circle diameter from Storyboard
    @IBInspectable var widthToDiameter: CGFloat = 6
    
    // Allows to set opacity of mask from storyboard
    @IBInspectable var opacity: CGFloat = 0.3
    
    var circleMargin: CGFloat = 0
    var distanceBetweenCircles: CGFloat = 0
    
    //MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        
        // Set circle diameter with respect to canvas width
        let diameter = self.frame.width / widthToDiameter
        
        let remaining = self.frame.width - 2 * diameter
        
        // Leading and trailing margin for circles
        circleMargin =  remaining / 4
        
        distanceBetweenCircles = remaining - 2 * circleMargin
        
        // Loop to draw two circles
        for i in 0..<2 {
            
            // Coordinates to start drawing circles
            let x = circleMargin + CGFloat(i) * (diameter + distanceBetweenCircles)
            let y = (self.frame.height - diameter) / 2
            
            // Draw circle
            let circle = CGRect(x: x, y: y, width: diameter, height: diameter)
            let circlePath = UIBezierPath(ovalIn: circle)
            
            // Second pass for circle in order to be able to fill outside
            circlePath.append(UIBezierPath(rect: self.bounds))
            
            // Create Shape Layer object
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = circlePath.cgPath
            
            // Change fill rule to be able to fill outside
            shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
            
            // Fill the area outside the circles with transparent white color
            shapeLayer.fillColor = UIColor(white: 1, alpha: opacity).cgColor
            
            // Add layer to view
            layer.addSublayer(shapeLayer)
        }
    }
    
}
