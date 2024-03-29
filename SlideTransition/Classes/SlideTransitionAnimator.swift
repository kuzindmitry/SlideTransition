//
//  SlideTransitionAnimator.swift
//  Pods-SlideTransition_Example
//
//  Created by Dmitry Kuzin on 13/08/2019.
//

import UIKit

@available(iOS 10.0, *)
final class SlideTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum TransitionDirection {
        case presentation
        case dismissal
    }
    
    //    Init
    
    var direction: TransitionDirection
    var configuration: SlideTransitionConfigurator
    var isInteractive = false
    
    init(direction: TransitionDirection = .presentation, configuration: SlideTransitionConfigurator) {
        self.direction = direction
        self.configuration = configuration
        super.init()
    }
    
    //    Animators
    
    private(set) lazy var presentationAnimator: UIViewPropertyAnimator = setupAnimator(.presentation)
    private(set) lazy var dismissAnimator: UIViewPropertyAnimator = setupAnimator(.dismissal)
    
    private weak var transitionContext: UIViewControllerContextTransitioning?
    
    private var interactiveAnimator: UIViewPropertyAnimator {
        switch direction {
        case .presentation:
            return presentationAnimator
        case .dismissal:
            return dismissAnimator
        }
    }
    
    //    Local configuration
    
    private var verticalSpacing: CGFloat { return configuration.verticalSpacing }
    private var verticalInset: CGFloat { return configuration.verticalInset }
    private var horizontalInset: CGFloat { return configuration.horizontalInset }
    private var cornerRadius: CGFloat { return configuration.cornerRadius }
    private var backFadeAlpha: CGFloat  { return configuration.backFadeAlpha }
    private var initialTransitionFrame: CGRect? { return configuration.initialTransitionFrame }
    
    //    MARK:- UIViewControllerAnimatedTransitioning
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let interval: TimeInterval
        switch direction {
        case .presentation:
            interval = 3.65
        case .dismissal:
            interval = 0.55
        }
        return interval
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let pa = buildAnimator(for: transitionContext) else {
            return
        }
        pa.startAnimation()
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        isInteractive = false
    }
}

extension SlideTransitionAnimator: UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let _ = buildAnimator(for: transitionContext) else {
            return
        }
        self.transitionContext = transitionContext
    }
    
    var wantsInteractiveStart: Bool {
        return isInteractive
    }
    
    func updateInteractiveTransition(_ percentComplete: CGFloat) {
        let pa = interactiveAnimator
        
        pa.fractionComplete = percentComplete
        transitionContext?.updateInteractiveTransition(percentComplete)
    }
    
    func cancelInteractiveTransition(with velocity: CGVector = .zero) {
        guard isInteractive else {
            return
        }
        
        transitionContext?.cancelInteractiveTransition()
        
        interactiveAnimator.isReversed = true    //    animate back to starting position
        
        let pct = interactiveAnimator.fractionComplete
        endInteraction(from: pct,
                       withVelocity: velocity,
                       durationFactor: 1 - pct)
    }
    
    func finishInteractiveTransition(with velocity: CGVector = .zero) {
        guard isInteractive else {
            return
        }
        
        transitionContext?.finishInteractiveTransition()
        
        let pct = interactiveAnimator.fractionComplete
        endInteraction(from: pct,
                       withVelocity: velocity,
                       durationFactor: pct)
    }
}


//    UIViewPropertyAnimator

private extension SlideTransitionAnimator {
    func endInteraction(from percentComplete: CGFloat, withVelocity velocity: CGVector, durationFactor: CGFloat) {
        switch interactiveAnimator.state {
        case .inactive:
            interactiveAnimator.startAnimation()
        default:    //    case .active, .stopped, @unknown-futures
            interactiveAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
    }
    
    func setupAnimator(_ direction: TransitionDirection) -> UIViewPropertyAnimator {
        let params: SpringParameters
        
        switch direction {
        case .presentation:
            params = .tap
        case .dismissal:
            params = .momentum
        }
        
        //    entire spring animation should not last more than transitionDuration
        let damping = params.damping
        let response = params.response
        let timingParameters = UISpringTimingParameters(damping: damping, response: response)
        
        let pa = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
        
        return pa
    }
    
    func buildAnimator(for transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator? {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to),
            let fromView = fromVC.view,
            let toView = toVC.view
            else {
                return nil
        }
        let containerView = transitionContext.containerView
        
        switch direction {
        case .presentation:
            let sourceCardPresentationController = fromVC.presentationController as? SlideTransitionPresentationController
            
            let fromEndFrame: CGRect
            let toEndFrame: CGRect
            
            if let sourceCardPresentationController = sourceCardPresentationController {
                sourceCardPresentationController.fadeoutHandle()
                
                let fromBeginFrame = transitionContext.initialFrame(for: fromVC)
                
                fromEndFrame = fromBeginFrame.inset(by: UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset))
                toEndFrame = fromBeginFrame.inset(by: UIEdgeInsets(top: verticalSpacing, left: 0, bottom: 0, right: 0))
                
            } else {
                let fromBeginFrame = transitionContext.initialFrame(for: fromVC)
                fromEndFrame = fromBeginFrame.inset(by: UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: 0, right: horizontalInset))
                
                let toBaseFinalFrame = transitionContext.finalFrame(for: toVC)
                toEndFrame = toBaseFinalFrame.inset(by: UIEdgeInsets(top: verticalInset + verticalSpacing, left: 0, bottom: 0, right: 0))
            }
            let toStartFrame = offscreenFrame(inside: containerView)
            
            guard let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else { return nil }
            snapshot.frame = fromVC.view.bounds
            snapshot.layer.masksToBounds = true
            snapshot.tag = 12345
            fromVC.view.isHidden = true
            containerView.addSubview(snapshot)
            
            toView.clipsToBounds = true
            toView.frame = toStartFrame
            toView.layoutIfNeeded()
            containerView.addSubview(toView)
            
            let pa = presentationAnimator
            pa.addAnimations() {
                [weak self] in
                guard let self = self else { return }
                
                self.insetBackCards(of: sourceCardPresentationController)
                snapshot.frame = fromEndFrame
                toView.frame = toEndFrame
                snapshot.cardMaskTopCorners(using: self.cornerRadius)
                toView.cardMaskTopCorners(using: self.cornerRadius)
                
                snapshot.alpha = self.backFadeAlpha
            }
            
            pa.addCompletion() {
                [weak self] animatingPosition in
                
                switch animatingPosition {
                case .start:
                    self?.direction = .presentation
                    fromView.isUserInteractionEnabled = true
                    transitionContext.completeTransition(false)
                default:    //    case .end, .current (which should not be possible), @unknown-futures
                    self?.direction = .dismissal
                    fromView.isUserInteractionEnabled = false
                    transitionContext.completeTransition(true)
                }
            }
            
            return pa
            
            
        case .dismissal:
            let targetCardPresentationController = toVC.presentationController as? SlideTransitionPresentationController
            let isTargetAlreadyCard = (targetCardPresentationController != nil)
            
            let toBeginFrame = toView.frame
            let toEndFrame: CGRect
            
            if let _ = targetCardPresentationController {
                toEndFrame = toBeginFrame.inset(by: UIEdgeInsets(top: 0, left: -horizontalInset, bottom: 0, right: -horizontalInset))
            } else {
                toEndFrame = transitionContext.finalFrame(for: toVC)
            }
            
            let fromEndFrame = offscreenFrame(inside: containerView)
            
            guard let snapshot = containerView.viewWithTag(12345) else { return nil }
            
            let pa = dismissAnimator
            pa.addAnimations() {
                [weak self] in
                guard let self = self else { return }
                
                fromView.cardUnmask()
                if !isTargetAlreadyCard {
                    snapshot.cardUnmask()
                }
                self.outsetBackCards(of: targetCardPresentationController)
                
                fromView.frame = fromEndFrame
                snapshot.frame = toEndFrame
                snapshot.alpha = 1
                fromView.alpha = 1
            }
            
            pa.addCompletion() {
                [weak self] animatingPosition in
                guard let self = self else { return }
                
                switch animatingPosition {
                case .start:
                    self.direction = .dismissal
                    self.dismissAnimator = self.setupAnimator(.dismissal)
                    
                    toView.isUserInteractionEnabled = false
                    
                    transitionContext.completeTransition(false)
                    
                default: //    case .end, .current (which should not be possible), @unknown-futures
                    self.direction = .presentation
                    self.presentationAnimator = self.setupAnimator(.presentation)
                    
                    toView.isUserInteractionEnabled = true
                    toVC.view.isHidden = false
                    fromView.removeFromSuperview()
                    
                    if let targetCardPresentationController = targetCardPresentationController {
                        targetCardPresentationController.fadeinHandle()
                    }
                    
                    if self.configuration.hapticFeedbackWhenOpen {
                        UIImpactFeedbackGenerator().impactOccurred()
                    }
                    
                    transitionContext.completeTransition(true)
                }
            }
            
            return pa
        }
    }
}



//    Helper methods

@available(iOS 10.0, *)
private extension SlideTransitionAnimator {
    private func insetBackCards(of pc: SlideTransitionPresentationController?) {
        guard
            let pc = pc,
            let pcView = pc.presentingViewController.view
            else { return }
        let frame = pcView.frame
        pcView.frame = CGRect(x: 20, y: frame.origin.y, width: frame.width - 40, height: frame.height)
        pcView.frame = frame.inset(by: UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset))
        pcView.alpha *= backFadeAlpha
        
        insetBackCards(of: pc.presentingViewController.presentationController as? SlideTransitionPresentationController)
    }
    
    private func outsetBackCards(of pc: SlideTransitionPresentationController?) {
        guard
            let pc = pc,
            let pcView = pc.presentingViewController.view
            else { return }
        
        let frame = pcView.frame
        pcView.frame = frame.inset(by: UIEdgeInsets(top: 0, left: -horizontalInset, bottom: 0, right: -horizontalInset))
        pcView.alpha /= backFadeAlpha
        
        outsetBackCards(of: pc.presentingViewController.presentationController as? SlideTransitionPresentationController)
    }
    
    func offscreenFrame(inside containerView: UIView) -> CGRect {
        if let initialTransitionFrame = initialTransitionFrame {
            return initialTransitionFrame
        } else {
            var f = containerView.frame
            f.origin.y = f.height
            return f
        }
    }
    
    struct SpringParameters {
        let damping: CGFloat
        let response: CGFloat
        
        //    From amazing session 803 at WWDC 2018: https://developer.apple.com/videos/play/wwdc2018-803/?time=2238
        //    > Because the tap doesn't have any momentum in the direction of the presentation of Now Playing,
        //    > we use 100% damping to make sure it doesn't overshoot.
        //
        static let tap = SpringParameters(damping: 1, response: 0.44)
        
        //    > But, if you swipe to dismiss Now Playing,
        //    > there is momentum in the direction of the dismissal,
        //    > and so we use 80% damping to have a little bit of bounce and squish,
        //    > making the gesture a lot more satisfying.
        //
        //    (note that they use momentum even when tapping to dismiss)
        static let momentum = SpringParameters(damping: 0.8, response: 0.44)
    }
}


@available(iOS 10.0, *)
private extension UISpringTimingParameters {
    /// A design-friendly way to create a spring timing curve.
    ///    See: https://medium.com/@nathangitter/building-fluid-interfaces-ios-swift-9732bb934bf5
    ///
    /// - Parameters:
    ///   - damping: The 'bounciness' of the animation. Value must be between 0 and 1.
    ///   - response: The 'speed' of the animation.
    ///   - initialVelocity: The vector describing the starting motion of the property. Optional, default is `.zero`.
    convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
}


