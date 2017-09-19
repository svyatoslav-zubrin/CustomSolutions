//
//  Pull2RefreshViewController.swift
//  CustomSolutions
//
//  Created by Slava Zubrin on 9/19/17.
//  Copyright © 2017 Slava Zubrin. All rights reserved.
//

import UIKit

class Pull2RefreshViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    var refreshControl: CustomRefreshControl = CustomRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.alwaysBounceVertical = true
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width,
                                        height: 2.0 * scrollView.bounds.size.height)
        
        setupRefreshControl()
    }
    
    // MARK: User actions
    
    func handlePullToRefresh(_ sender: CustomRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: { [weak self] in
            self?.refreshControl.dataSourceFinishedLoading()
        })
    }
    
    // MARK: Private
    
    private func setupRefreshControl() {
        refreshControl.backgroundColor = UIColor.yellow
        
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh(_:)), for: .valueChanged)
        
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(refreshControl)
        
        let bindings: [String: UIView] = ["refresh": refreshControl]
        NSLayoutConstraint
            .constraints(withVisualFormat: "H:|-0-[refresh(==100)]-0-|",
                                       options: [],
                                       metrics: nil,
                                       views: bindings)
            .forEach { constraint in
                constraint.isActive = true
            }
        NSLayoutConstraint
            .constraints(withVisualFormat: "V:|-(-100)-[refresh(==100)]",
                         options: [],
                         metrics: nil,
                         views: bindings)
            .forEach { constraint in
                constraint.isActive = true
            }
    }
}

extension Pull2RefreshViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        refreshControl.containingScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        refreshControl.containingScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
}
