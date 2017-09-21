//
//  UniversalRefreshControl.swift
//  CustomSolutions
//
//  Created by Slava Zubrin on 9/20/17.
//  Copyright © 2017 Slava Zubrin. All rights reserved.
//

import UIKit

protocol UniversalRefreshControlDelegate: class {
    func startedLoading(_ sender: UniversalRefreshControl)
}

/// Universal refresh control that can be used even with simple UIView. The component tested with UIScrollView only for now 😉
class UniversalRefreshControl: UIView {

    weak var delegate: UniversalRefreshControlDelegate? = nil

    // views
    fileprivate weak var pan: UIPanGestureRecognizer! = nil
    fileprivate weak var refresh: FRYMoonActivityIndicator! = nil
    fileprivate weak var contentView: UIView! = nil

    private var _content: UIView? = nil
    var content: UIView? {
        get {
            return _content
        }
        set {
            guard let newContent = newValue else {
                _content?.removeFromSuperview()
                _content = nil
                return
            }

            _content?.removeFromSuperview()

            newContent.frame = contentView.bounds
            newContent.translatesAutoresizingMaskIntoConstraints = true
            newContent.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            contentView.addSubview(newContent)
            _content = newContent
        }
    }


    // internal helpers
    private var gestureShift: CGFloat = 0
    private var contentOffsetAtGestureStart: CGFloat = 0

    // refresh logic
    private let moonSize: CGFloat = 50
    private let limitToTriggerRefresh: CGFloat = 90;
    private let topMarginAtLoadingTime: CGFloat = 70

    private enum RefreshState {
        case normal
        case pullingBeforeLimitReached
        case pullingAfterLimitReached
        case droppedBeforeLimitReached
        case droppedAfterLimitReached
        case loading
        case loadingAndScrolled
        
        var string: String {
            switch self {
            case .normal: return "normal"
            case .pullingBeforeLimitReached: return "pullingBefore"
            case .pullingAfterLimitReached: return "pullingAfter"
            case .droppedBeforeLimitReached: return "droppedBefore"
            case .droppedAfterLimitReached: return "droppedAfter"
            case .loading: return "loading"
            case .loadingAndScrolled: return "loadingAndScrolled"
            }
        }
    }
    private var refreshState: RefreshState = .normal {
        didSet {
            switch refreshState {
            case .normal:
                refresh.animating = false
                pan.isEnabled = false
                pan.isEnabled = true
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
                    self.delegate?.startedLoading(self)
                })
                refresh.animating = true

            case .loadingAndScrolled:
                guard isScrolledBelowRefresh else {
                    break
                }
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: self.topMarginAtLoadingTime)
                    self.contentView.frame = frame
                })

            default: break
            }
            
            //print("state set to: \(refreshState.string)")
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
        case .began:
            if let content = content as? UIScrollView {
                contentOffsetAtGestureStart = content.contentOffset.y
            }
            fallthrough

        case .changed:
            let shift = gesture.translation(in: self).y
            let delta = shift - gestureShift
            gestureShift = shift

            var topCellToContentViewDistance = contentView.frame.minY
            if let content = content as? UIScrollView {
                topCellToContentViewDistance -= content.contentOffset.y
            }

            // scroll up happend
            if delta < 0 {
                let shouldHandleScrollUp = topCellToContentViewDistance > 0
                if shouldHandleScrollUp {
                    if contentView.frame.minY > 0 {
                        if let content = content as? UIScrollView {
                            var frame = contentView.frame
                            frame.origin = CGPoint(x: frame.origin.x, y: max(0, frame.origin.y + delta))
                            contentView.frame = frame
                            content.contentOffset = .zero

                            refresh.alpha = contentView.frame.minY / limitToTriggerRefresh
                        }
                    }

                    break
                }
            }

            // scroll down happend
            let shouldHandleScrollDown = topCellToContentViewDistance >= 0
            if shouldHandleScrollDown {
                let expectedShift = contentView.frame.origin.y + delta
                let limitedShift = max(0, min(160, expectedShift))
                var frame = contentView.frame
                frame.origin = CGPoint(x: frame.origin.x, y: contentOffsetAtGestureStart + limitedShift)
                contentView.frame = frame

                refresh.alpha = contentView.frame.minY / limitToTriggerRefresh
            }

            if refreshState == .normal {
                if topCellToContentViewDistance > 0 {
                    if topCellToContentViewDistance < limitToTriggerRefresh {
                        refreshState = .pullingBeforeLimitReached
                    } else {
                        refreshState = .pullingAfterLimitReached
                    }
                }
            } else if refreshState == .pullingBeforeLimitReached {
                if topCellToContentViewDistance >= limitToTriggerRefresh {
                    refreshState = .pullingAfterLimitReached
                }
            } else if refreshState == .pullingAfterLimitReached {
                if topCellToContentViewDistance < limitToTriggerRefresh {
                    refreshState = .pullingBeforeLimitReached
                }
            }
            
        case .ended, .cancelled:
            if refreshState == .pullingAfterLimitReached {
                refreshState = .droppedAfterLimitReached
            } else if refreshState == .pullingBeforeLimitReached {
                refreshState = .droppedBeforeLimitReached
            } else if refreshState == .loading {

                if contentView.frame.minY != topMarginAtLoadingTime {
                    refreshState = .loadingAndScrolled
                }

                if let _ = content as? UIScrollView {
                    if isScrolledAboveRefresh {
                        reset()
                        break
                    }
                }
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: self.topMarginAtLoadingTime)
                    self.contentView.frame = frame
                })
            } else if refreshState == .loadingAndScrolled {
                if let _ = content as? UIScrollView {
                    if isScrolledAboveRefresh {
                        reset()
                        break
                    }
                }
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    var frame = self.contentView.frame
                    frame.origin = CGPoint(x: frame.origin.x, y: self.topMarginAtLoadingTime)
                    self.contentView.frame = frame
                })
            }
            reset()
            
        case .failed:
            reset()
            
        default: break
        }
    }

    // MARK: Public

    func finish() {
        guard refreshState == .loading || refreshState == .loadingAndScrolled else {
            return
        }

        refreshState = .normal
    }
    
    // MARK: Private
    
    private func setup() {
        // views
        let cv = UIView(frame: bounds)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.backgroundColor = .yellow
        addSubview(cv)
        contentView = cv

        var frame = CGRect(origin: .zero, size: CGSize(width: bounds.size.width, height: topMarginAtLoadingTime))
        let refreshContainer = UIView(frame: frame)
        refreshContainer.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        addSubview(refreshContainer)
        sendSubview(toBack: refreshContainer)

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
        p.delegate = self
        addGestureRecognizer(p)
        pan = p
    }
    
    private func reset() {
        gestureShift = 0
    }

    private var isScrolledAboveRefresh: Bool {
        guard refreshState == .loading || refreshState == .loadingAndScrolled else {
            return false
        }

        if let _ = content as? UIScrollView {
            // TODO: is that correct, shouldn't we take into account contentOffset of the scroll?
            return contentView.frame.minY < topMarginAtLoadingTime
        } else {
            return contentView.frame.minY < topMarginAtLoadingTime
        }
    }

    private var isScrolledBelowRefresh: Bool {
        guard refreshState == .loading || refreshState == .loadingAndScrolled else {
            return false
        }

        if let _ = content as? UIScrollView {
            // TODO: is that correct, shouldn't we take into account contentOffset of the scroll?s
            return contentView.frame.minY > topMarginAtLoadingTime
        } else {
            return contentView.frame.minY > topMarginAtLoadingTime
        }
    }

}

extension UniversalRefreshControl: UIGestureRecognizerDelegate {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard pan == gestureRecognizer else {
            return false
        }

        if let content = content as? UIScrollView, content.contentOffset.y > 0 {
            return false
        }

        let should = contentView.frame.minY > 0 || (contentView.frame.minY == 0 && pan.translation(in: self).y > 0)
        return should
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let content = content as? UIScrollView else {
            return false
        }

        return otherGestureRecognizer == content.panGestureRecognizer
    }
}
