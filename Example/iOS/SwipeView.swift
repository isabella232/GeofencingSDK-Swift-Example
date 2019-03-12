//
//  SwipeView.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class SwipeView: UIScrollView {

	override var frame: CGRect {
		didSet {
			contentOffset = .zero
			delegate?.scrollViewDidScroll?(self)
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		for (index, view) in subviews.enumerated() {
			view.frame = bounds.offsetBy(dx: bounds.width*CGFloat(index) - contentOffset.x, dy: 0)
		}

		contentSize = CGSize(width: frame.width * CGFloat(subviews.count), height: frame.height)
	}
}
