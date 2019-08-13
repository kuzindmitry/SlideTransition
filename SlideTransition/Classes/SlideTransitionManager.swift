//
//  SlideTransitionManager.swift
//  SlideTransition
//
//  Created by Dmitry Kuzin on 13/08/2019.
//

import UIKit

@available(iOS 10.0, *)
final class SlideTransitionManager: NSObject, UIViewControllerTransitioningDelegate {
    private(set) var configuration: SlideTransitionConfigurator
    
    init(configuration: SlideTransitionConfigurator) {
        self.configuration = configuration
        super.init()
    }
    
    private lazy var cardAnimator = SlideTransitionAnimator(configuration: configuration)
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = SlideTransitionPresentationController(configuration: configuration, presentedViewController: presented, presenting: presenting)
        pc.sourceController = source
        pc.cardAnimator = cardAnimator
        pc.dismissAreaHeight = configuration.dismissAreaHeight
        return pc
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        cardAnimator.direction = .presentation
        return cardAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        cardAnimator.direction = .dismissal
        return cardAnimator
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if cardAnimator.isInteractive { return cardAnimator }
        return nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if cardAnimator.isInteractive { return cardAnimator }
        return nil
    }
}
