//
//  CustomRefreshControl.swift
//  CustomSolutions
//
//  Created by Slava Zubrin on 9/19/17.
//  Copyright © 2017 Slava Zubrin. All rights reserved.
//

import UIKit

/*
    - track states
    - animated switching between states
    - interrupt scrolling programmatically
    - add artificial shift at loading state
    - add one more public method to force switching state from loading to normal after data source finished loading of data
    - ...
 */

class CustomRefreshControl: UIControl {
    
    private enum RefreshState {
        case pulling, normal, loading
        
        var string: String {
            switch self {
            case .pulling: return "pulling"
            case .normal: return "normal"
            case .loading: return "loading"
            }
        }
    }
    private var refreshState: RefreshState = .normal {
        didSet {
            print("state set to: \(refreshState.string)")
        }
    }
    
    static let minOffsetToTriggerRefresh: CGFloat = 80;
    
    var cycleLength: Float = 30 { didSet { setNeedsDisplay() }}
    var currentValue: Float = 0 { didSet { setNeedsDisplay() }}
    
    // MARK: Lifecycle
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let halfSize: Float = 10
        let alpha = 2 * Float.pi * currentValue / cycleLength
        
        let start = CGPoint(x: rect.midX + CGFloat(cos(alpha) * halfSize),
                            y: rect.midY + CGFloat(sin(alpha) * halfSize))
        context?.move(to: start)
        let finish = CGPoint(x: rect.midX + CGFloat(cos(alpha + Float.pi) * halfSize),
                            y: rect.midY + CGFloat(sin(alpha + Float.pi) * halfSize))

        context?.addLine(to: finish)
        context?.setLineWidth(2)
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.strokePath()
    }
    
    // MARK: Public
    
    func containingScrollViewDidScroll(_ scrollView: UIScrollView) {
        currentValue = Float(scrollView.contentOffset.y)
        
        if currentValue < 0 && refreshState != .pulling {
            refreshState = .pulling
        }
    }
    
    func containingScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= -CustomRefreshControl.minOffsetToTriggerRefresh {
            refreshState = .loading
            sendActions(for: .valueChanged)
        }
    }
    
    func dataSourceFinishedLoading() {
        refreshState = .normal
    }
}
