//
//  SongCellBackground.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 Joseph Pecoraro. All rights reserved.
//

// TODO: Change customization for this project

import UIKit

class SongCellBackground: UIView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    func configure() {
        layer.borderColor = blue1.CGColor;
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5);
    }
    
    func setSelectingState(isSelected: Bool) {
        if (isSelected) {
            layer.shadowColor = blue1.CGColor;
            layer.shadowRadius = 5;
            layer.borderWidth = 0.5;
        }
        else {
            layer.shadowColor = UIColor.grayColor().CGColor;
            layer.shadowRadius = 3;
            layer.borderWidth = 0;
        }
    }
}