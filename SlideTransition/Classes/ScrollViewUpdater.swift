//
//  ScrollViewUpdater.swift
//  SlideTransition
//
//  Created by Dmitry Kuzin on 13/08/2019.
//

import UIKit

final class ScrollViewUpdater {
    
    var isDismissEnabled = false
    
    private weak var rootView: UIView?
    private weak var scrollView: UIScrollView?
    private var observation: NSKeyValueObservation?
    
    init(with rootView: UIView, scrollView: UIScrollView) {
        self.rootView = rootView
        self.scrollView = scrollView
        self.observation = scrollView.observe(\.contentOffset, options: [.initial], changeHandler: { [weak self] _, _ in
            self?.scrollViewDidScroll()
        })
    }
    
    deinit {
        observation = nil
    }
    
    private func scrollViewDidScroll() {
        guard let rootView = rootView, let scrollView = scrollView else {
            return
        }
        
        let offset: CGFloat = {
            if #available(iOS 11.0, *) {
                return scrollView.contentOffset.y + scrollView.contentInset.top + scrollView.safeAreaInsets.top
            } else {
                return scrollView.contentOffset.y + scrollView.contentInset.top
            }
        }()
        
        if offset > 0 {
            scrollView.bounces = true
            isDismissEnabled = false
        } else {
            if scrollView.isDecelerating {
                rootView.transform = CGAffineTransform(translationX: 0, y: -offset)
                scrollView.subviews.forEach {
                    $0.transform = CGAffineTransform(translationX: 0, y: offset)
                }
            } else {
                scrollView.bounces = false
                isDismissEnabled = true
            }
        }
    }
    
}
