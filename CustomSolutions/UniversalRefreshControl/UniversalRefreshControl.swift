//
//  UniversalRefreshControl.swift
//  CustomSolutions
//
//  Created by Slava Zubrin on 9/20/17.
//  Copyright © 2017 Slava Zubrin. All rights reserved.
//

import UIKit

class UniversalRefreshControl: UIView {
    
    // views
    weak var pan: UIPanGestureRecognizer! = nil
    weak var contentView: UIView! = nil
    weak var refresh: FRYMoonActivityIndicator! = nil
    
    // internal helpers
    private var gestureShift: CGFloat = 0

    // refresh logic
    static let limitToTriggerRefresh: CGFloat = 70;
    private var topMarginAtLoadingTime: CGFloat = 50

    private enum RefreshState {
        case normal
        case pullingBeforeLimitReached
        case pullingAfterLimitReached
        case droppedBeforeLimitReached
        case droppedAfterLimitReached
        case loading
        
        var string: String {
            switch self {
            case .normal: return "normal"
            case .pullingBeforeLimitReached: return "pullingBefore"
            case .pullingAfterLimitReached: return "pullingAfter"
            case .droppedBeforeLimitReached: return "droppedBefore"
            case .droppedAfterLimitReached: return "droppedAfter"
            case .loading: return "loading"
            }
        }
    }
    private var refreshState: RefreshState = .normal {
        didSet {
            switch refreshState {
            case .normal:
                refresh.animating = false
                // animate back
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: 0)
                    self.contentView.frame = frame
                })
            case .droppedBeforeLimitReached:
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: 0)
                    self.contentView.frame = frame
                }, completion: { [unowned self] _ in
                    self.refreshState = .normal
                })

            case .droppedAfterLimitReached:
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: self.topMarginAtLoadingTime)
                    self.contentView.frame = frame
                }, completion: { [unowned self] _ in
                    self.refreshState = .loading
                })
                
            case .loading:
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: self.topMarginAtLoadingTime)
                    self.contentView.frame = frame
                }, completion: { [unowned self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now()+5, execute: {
                        self.refreshState = .normal
                    })
                })
                refresh.animating = true
                
            default: break
            }
            
            print("state set to: \(refreshState.string)")
        }
    }

    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    // MARK: User actions
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began, .changed:
            
            let shift = gesture.translation(in: self).y
            guard shift >= 0 else {
                break
            }
            
            let wShift = shiftForDelta(shift)
            let delta = wShift - gestureShift
            gestureShift = wShift
            var frame = contentView.frame
            frame.origin = CGPoint(x: frame.origin.x, y: frame.origin.y + delta)
            contentView.frame = frame
            
            if refreshState == .normal {
                if gestureShift < UniversalRefreshControl.limitToTriggerRefresh {
                    refreshState = .pullingBeforeLimitReached
                } else {
                    refreshState = .pullingAfterLimitReached
                }
                
                //currentValue = yOffset
            } else if refreshState == .pullingBeforeLimitReached {
                if gestureShift >= UniversalRefreshControl.limitToTriggerRefresh {
                    refreshState = .pullingAfterLimitReached
                }
                //currentValue = yOffset
            } else if refreshState == .pullingAfterLimitReached {
                if gestureShift < UniversalRefreshControl.limitToTriggerRefresh {
                    refreshState = .pullingBeforeLimitReached
                }
                //currentValue = yOffset
            } else if refreshState == .droppedBeforeLimitReached {
                //currentValue = yOffset
            } else if refreshState == .droppedAfterLimitReached {
                //currentValue = yOffset
            } else if refreshState == .loading {
                // repetitive pull, ignore for now
            }
            
        case .ended, .cancelled:
            if refreshState == .pullingAfterLimitReached {
                refreshState = .droppedAfterLimitReached
                //sendActions(for: .valueChanged)
            } else if refreshState == .pullingBeforeLimitReached {
                refreshState = .droppedBeforeLimitReached
            } else if refreshState == .loading {
                // repetitive pull, ignore for now
            }
            reset()
            
        case .failed:
            reset()
            
        default: break
        }
    }
    
    // MARK: Math
    
    private func shiftForDelta(_ delta: CGFloat) -> CGFloat {
        if delta <= 0 {
            return 0
        } else if delta > 160 {
            return 100
        } else {
            let c0: CGFloat =  1.3737447856830951e+000
            let c1: CGFloat =  7.6879472420430739e-001
            let c2: CGFloat =  2.8697969370004082e-003
            let c3: CGFloat = -3.5206414956983544e-005
            let c4: CGFloat =  7.0853953049069964e-008
            return c0
                 + c1 * pow(delta, 1)
                 + c2 * pow(delta, 2)
                 + c3 * pow(delta, 3)
                 + c4 * pow(delta, 4)
        }
    }
    
    // MARK: Private
    
    private func setup() {
        // self
        layer.borderColor = UIColor.blue.cgColor
        layer.borderWidth = 1
        
        // views
        let cv = UIView(frame: bounds)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.backgroundColor = .yellow
        addSubview(cv)
        contentView = cv
        
        var frame = CGRect(origin: .zero, size: CGSize(width: bounds.size.width, height: topMarginAtLoadingTime))
        let refreshContainer = UIView(frame: frame)
        refreshContainer.autoresizingMask = [.flexibleBottomMargin]
        addSubview(refreshContainer)
        sendSubview(toBack: refreshContainer)

        let moonSize: CGFloat = 30
        frame = CGRect(x: (bounds.size.width - moonSize) / 2,
                       y: (topMarginAtLoadingTime - moonSize) / 2,
                       width: moonSize,
                       height: moonSize)

        let mai = FRYMoonActivityIndicator(frame: frame)
        mai.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        refreshContainer.addSubview(mai)
        refresh = mai

        // gestures
        let p = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)));
        addGestureRecognizer(p)
    }
    
    private func reset() {
        gestureShift = 0
    }
}
