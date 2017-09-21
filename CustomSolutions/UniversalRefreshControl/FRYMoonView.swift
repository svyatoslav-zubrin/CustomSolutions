//
//  FRYMoonView.swift
//  EmoWork
//
//  Created by Slava Zubrin on 10/26/14.
//  Copyright (c) 2017 Peder Nordvaller. All rights reserved.
//

import UIKit

@IBDesignable
class FRYMoonView: UIView {

    //Parameters
    @IBInspectable var animationCycleDuration: Double = 0.7
    @IBInspectable var rotationCycleDuration: Double = 1
    @IBInspectable var fillColor: UIColor = .black
    @IBInspectable var fillBackgroundColor: UIColor = .clear {
        didSet{
            backgroundLayer?.fillColor = fillBackgroundColor.cgColor
        }
    }
    @IBInspectable var animating: Bool = false {
        didSet(oldValue) {
            if oldValue != animating {
                if animating {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
        }
    }
    @IBInspectable var angle: CGFloat = 0.0 {
        didSet {
            pathLayer?.setAffineTransform(CGAffineTransform(rotationAngle: angle))
        }
    }

    var colors: [UIColor]?
    private var previousCycleIndex: Int = 0

    //Layers
    private var pathLayer: CAShapeLayer?
    private var backgroundLayer: CAShapeLayer?

    //Display
    private var displayLink: CADisplayLink?
    private var firstTimeStamp: CFTimeInterval?


    override func didMoveToSuperview() {
        setUpLayer()
    }

    private func setUpLayer() {
        if backgroundLayer == nil {
            backgroundLayer = CAShapeLayer()
            backgroundLayer?.frame = layer.bounds
            backgroundLayer?.path = contourPath()
            backgroundLayer?.fillColor = fillBackgroundColor.cgColor
            layer.addSublayer(backgroundLayer!)
        }

        if pathLayer == nil {
            pathLayer = CAShapeLayer()
            pathLayer?.frame = layer.bounds
            pathLayer?.lineWidth = 0
            pathLayer?.setAffineTransform(CGAffineTransform(rotationAngle: angle))
            cleanLayers()
            layer.addSublayer(pathLayer!)
        }
    }

    private func cleanLayers() {
        pathLayer?.path = pathAtInterval(interval: 0)
        pathLayer?.fillColor = UIColor.clear.cgColor
    }

    // Color

    private func colorsWithInterval(interval: TimeInterval) -> (fill: CGColor, bg: CGColor) {
        if let colors = colors, !colors.isEmpty {
            let current_cycle_index = Int(interval / animationCycleDuration)
            let fill_color_index = current_cycle_index % colors.count
            var bg_color_index = fill_color_index - 1
            if bg_color_index < 0 {
                bg_color_index = colors.count - 1
            }
            return (colors[fill_color_index].cgColor, colors[bg_color_index].cgColor)
        }

        return (fillColor.cgColor, fillBackgroundColor.cgColor)
    }

    // Path

    private func contourPath() -> CGPath {
        return UIBezierPath(ovalIn: layer.bounds).cgPath
    }

    private func pathAtInterval(interval: TimeInterval) -> CGPath {
        var cycleInterval = CGFloat(interval.remainingAfterMultiple(multiple: animationCycleDuration))
        cycleInterval = LogisticCurve.calculateYWithX(x: cycleInterval,
                                                      upperX: CGFloat(animationCycleDuration),
                                                      upperY: CGFloat(animationCycleDuration))

        let aPath = UIBezierPath()

        let length = layer.bounds.width
        let halfLength = layer.bounds.width / 2.0
        let halfAnimationDuration = CGFloat(animationCycleDuration)

        aPath.move(to: CGPoint(x: length, y: halfLength))
        aPath.addArc(withCenter: CGPoint(x: halfLength, y: halfLength),
                     radius: halfLength,
                     startAngle: -CGFloat(Float.pi) / 2.0,
                     endAngle: CGFloat(Float.pi) / 2.0,
                     clockwise: true)

        let x: CGFloat = length * 0.6667
        let t: CGFloat = -(2.0 / halfAnimationDuration) * cycleInterval + 1
        let controlPointXDistance:CGFloat = halfLength + t * x

        aPath.addCurve(to: CGPoint(x: halfLength, y: 0),
                       controlPoint1: CGPoint(x: controlPointXDistance, y: length - 0.05 * length),
                       controlPoint2: CGPoint(x: controlPointXDistance, y: 0.05 * length))
        aPath.close()

        return aPath.cgPath
    }

    // Animation

    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(displayLink:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        isHidden = false
    }

    private func stopAnimation() {
        self.displayLink?.invalidate()
        self.displayLink = nil
        cleanLayers()
    }

    func handleDisplayLink(displayLink: CADisplayLink) {
        if firstTimeStamp == nil {
            firstTimeStamp =  displayLink.timestamp
        }

        let elapse = displayLink.timestamp - firstTimeStamp!
        updatePathLayer(interval: elapse)
    }

    private func updatePathLayer(interval: TimeInterval) {
        // path
        pathLayer?.path = pathAtInterval(interval: interval)

        // colors
        let colors = colorsWithInterval(interval: interval)
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        pathLayer?.fillColor = colors.fill
        backgroundLayer?.fillColor = colors.bg
        CATransaction.commit()

        // rotation
        let rotationInterval = interval.remainingAfterMultiple(multiple: rotationCycleDuration)
        let rotationAngle = angle + CGFloat(rotationInterval * 2 * Double.pi / rotationCycleDuration)
        pathLayer?.setAffineTransform(CGAffineTransform(rotationAngle: rotationAngle))
    }

    // Interface builder

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpLayer()
        updatePathLayer(interval: animationCycleDuration * 0.35)
    }
}

private extension CGRect {

    func center() -> CGPoint {
        return CGPoint(x: origin.x + size.width / 2.0, y: origin.y + size.height / 2.0)
    }
}

private class LogisticCurve {

    class func calculateYWithX(x: CGFloat,
                               lowerX: CGFloat = 0,
                               upperX: CGFloat,
                               lowerY: CGFloat = 0,
                               upperY: CGFloat) -> CGFloat {
        // X scaling
        let b = -6.0 * (upperX + lowerX) / (upperX - lowerX)
        let m = (6.0 - b) / upperX
        let scaledX = m * x + b

        // Logistics
        let y = 1.0 / (1.0 + pow(CGFloat(M_E), -scaledX))

        // Y scaling
        let yScaled = (upperY - lowerY) * y + lowerY

        return yScaled
    }
}
