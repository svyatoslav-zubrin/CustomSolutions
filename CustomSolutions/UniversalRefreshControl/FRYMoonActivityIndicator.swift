//
//  FRYMoonLoadingIndicator.swift
//  EmoWork
//
//  Created by Slava Zubrin on 5/18/17.
//  Copyright © 2017 Peder Nordvaller. All rights reserved.
//

import UIKit

class FRYMoonActivityIndicator: UIView {

    // Public
    var colors: [UIColor] = [.red,
                             .orange,
                             .yellow,
                             .green,
                             .blue]
    {
        didSet {
            moonView.colors = colors
        }
    }

    var animating: Bool = false {
        didSet {
            moonView.animating = animating
        }
    }

    // Private
    fileprivate var moonView: FRYMoonView!
    fileprivate var imageView: UIImageView!

    // Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        // animated moon view
        moonView = FRYMoonView(frame: bounds)
        moonView.colors = colors
        if let fillColor = colors.last {
            moonView.fillBackgroundColor = fillColor
        }
        moonView.autoresizingMask = [.flexibleBottomMargin,
                                     .flexibleTopMargin,
                                     .flexibleLeftMargin,
                                     .flexibleRightMargin]
        moonView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(moonView)

        // image view
        imageView = UIImageView()
        imageView.image = UIImage(named: "and")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint(item: imageView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: self,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: imageView,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: self,
                           attribute: .centerY,
                           multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: imageView,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: self,
                           attribute: .width,
                           multiplier: 0.6,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: imageView,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: self,
                           attribute: .height,
                           multiplier: 0.6,
                           constant: 0).isActive = true
    }
}
