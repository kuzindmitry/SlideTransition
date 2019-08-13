//
//  ScrollViewDetector.swift
//  SlideTransition
//
//  Created by Dmitry Kuzin on 13/08/2019.
//

import UIKit

class ScrollViewDetector {
    
    weak var scrollView: UIScrollView?
    
    init(with viewController: UIViewController) {
        self.scrollView = getScrollView(from: viewController)
    }
    
    private func getScrollView(from viewController: UIViewController) -> UIScrollView? {
        if let scrollView = viewController.view as? UIScrollView {
            return scrollView
        }
        
        for subview in viewController.view.subviews {
            if let scrollView = subview as? UIScrollView {
                return scrollView
            }
        }
        
        return nil
        
    }
    
}
