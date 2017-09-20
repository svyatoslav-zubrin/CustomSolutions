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

    weak var owner: UIScrollView? = nil {
        didSet {
            reset()
            calibrate()
        }
    }

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
                currentValue = 0
                currentValueAtAnimationStart = 0
                stopAnimation()
                if let owner = owner {
                    // interrupt touch
                    isHackingWithPanGesture = true
                    owner.panGestureRecognizer.isEnabled = false
                    owner.panGestureRecognizer.isEnabled = true
                    isHackingWithPanGesture = false

                    // animate back
                    UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                        owner.contentInset = self.ownerContentInsets
                    })
                    owner.setContentOffset(ownerContentOffset, animated: true)
                }
            case .droppedAfterLimitReached:
                if let owner = owner {
                    //ownerContentInsets = owner.contentInset
                    let newContentInsets = UIEdgeInsets(top: ownerContentInsets.top + contentInsetShift,
                                                        left: ownerContentInsets.left,
                                                        bottom: ownerContentInsets.bottom,
                                                        right: ownerContentInsets.right)
                    owner.contentInset = newContentInsets
                }

            case .loading:
                startAnimation()

            default: break
            }

            print("state set to: \(refreshState.string), current: \(currentValue)")
        }
    }
    private var isLimitReached = false
    static let limitToTriggerRefresh: CGFloat = 80;

    private var rotationPeriod: TimeInterval = 1 // sec
    private var displayLink: CADisplayLink?
    private var firstTimeStamp: CFTimeInterval?


    var cycleLength: CGFloat = 30 { didSet { setNeedsDisplay() }}
    var currentValue: CGFloat = 0 { didSet { setNeedsDisplay() }}
    var currentValueAtAnimationStart: CGFloat = 0

    private var contentInsetShift: CGFloat = 100
    private var ownerContentInsets: UIEdgeInsets = .zero
    private var ownerContentOffset: CGPoint = .zero

    private var isHackingWithPanGesture = false

    // MARK: Lifecycle
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let halfSize: CGFloat = 10
        let alpha = 2 * CGFloat.pi * currentValue / cycleLength
        
        let start = CGPoint(x: rect.midX + cos(alpha) * halfSize,
                            y: rect.midY + sin(alpha) * halfSize)
        context?.move(to: start)
        let finish = CGPoint(x: rect.midX + cos(alpha + CGFloat.pi) * halfSize,
                             y: rect.midY + sin(alpha + CGFloat.pi) * halfSize)

        context?.addLine(to: finish)
        context?.setLineWidth(2)
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.strokePath()
    }
    
    // MARK: Public

    func calibrate() {
        if let owner = owner {
            ownerContentInsets = owner.contentInset
            ownerContentOffset = owner.contentOffset
        }

        refreshState = .normal
    }
    
    func containingScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isHackingWithPanGesture else {
            return
        }

        let yOffset = scrollView.contentOffset.y - ownerContentOffset.y

        print("containingScrollViewDidScroll \(yOffset)/\(currentValue), refreshState: \(refreshState)")

        if yOffset < 0 {
            //let notPulling = refreshState == .normal || refreshState == .loading
            if refreshState == .normal {
                if yOffset > -CustomRefreshControl.limitToTriggerRefresh {
                    refreshState = .pullingBeforeLimitReached
                } else {
                    refreshState = .pullingAfterLimitReached
                }

                currentValue = yOffset
            } else if refreshState == .pullingBeforeLimitReached {
                if yOffset <= -CustomRefreshControl.limitToTriggerRefresh {
                    refreshState = .pullingAfterLimitReached
                }
                currentValue = yOffset
            } else if refreshState == .pullingAfterLimitReached {
                if yOffset > -CustomRefreshControl.limitToTriggerRefresh {
                    refreshState = .pullingBeforeLimitReached
                }
                currentValue = yOffset
            } else if refreshState == .droppedBeforeLimitReached {
                currentValue = yOffset
            } else if refreshState == .droppedAfterLimitReached {
                currentValue = yOffset
            } else if refreshState == .loading {
                // repetitive pull, ignore for now
            }
        }
    }
    
    func containingScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !isHackingWithPanGesture else {
            return
        }

        print("containingScrollViewDidEndDragging \(scrollView.contentOffset.y - ownerContentOffset.y)")

        if refreshState == .pullingAfterLimitReached {
            refreshState = .droppedAfterLimitReached
            currentValueAtAnimationStart = currentValue
            sendActions(for: .valueChanged)
        } else if refreshState == .pullingBeforeLimitReached {
            refreshState = .droppedBeforeLimitReached
        } else if refreshState == .loading {
            // repetitive pull, ignore for now
        }
    }

    func containingScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("containingScrollViewDidEndDecelerating")

        if refreshState == .pullingAfterLimitReached || refreshState == .droppedAfterLimitReached {
            refreshState = .loading
        } else if refreshState == .pullingBeforeLimitReached || refreshState == .droppedBeforeLimitReached {
            refreshState = .normal
        }
    }
    
    func dataSourceFinishedLoading() {
        refreshState = .normal
    }

    // Animation

    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(displayLink:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }

    private func stopAnimation() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    func handleDisplayLink(displayLink: CADisplayLink) {
        if firstTimeStamp == nil {
            firstTimeStamp =  displayLink.timestamp
        }

        let elapse = displayLink.timestamp - firstTimeStamp!
        let rotationInterval = elapse.remainingAfterMultiple(multiple: rotationPeriod)
        currentValue = currentValueAtAnimationStart + CGFloat(rotationInterval * Double(cycleLength) / rotationPeriod)
    }

    // MARK: Private

    private func reset() {
        refreshState = .normal
    }
}

extension Double {

    func remainingAfterMultiple(multiple: TimeInterval) -> TimeInterval {
        return self - multiple * floor(self / multiple)
    }
}

