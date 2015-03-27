//
//  SAHistoryNavigationViewController.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/03/26.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit

extension UINavigationController {
    public func showHistory() {}
    public func setHistoryBackgroundColor(color: UIColor) {}
    public func contentView() -> UIView? { return nil }
}

extension UIView {
    func screenshotImage(scale: CGFloat = 0.0) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
        drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public class SAHistoryNavigationViewController: UINavigationController {
    
    var historyViewController = SAHistoryViewController()
    
    public var historyContentView = UIView()
    
    private var coverView = UIView()
    private var screenshotImages = [UIImage]()
    
    private let kImageScale: CGFloat = 1.0
    
    override init() {
        super.init()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(navigationBarClass: AnyClass!, toolbarClass: AnyClass!) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    override public func viewDidLoad() {
        coverView.backgroundColor = .grayColor()
        coverView.hidden = true
        NSLayoutConstraint.applyAutoLayout(view, target: coverView, index: nil, top: 0.0, left: 0.0, right: 0.0, bottom: 0.0, height: nil, width: nil)
        
        historyContentView.backgroundColor = .clearColor()
        historyContentView.hidden = true
        NSLayoutConstraint.applyAutoLayout(view, target: historyContentView, index: nil, top: 0.0, left: 0.0, right: 0.0, bottom: 0.0, height: nil, width: nil)
        
        historyViewController.delegate = self
        historyViewController.view.alpha = 0.0
        let width = UIScreen.mainScreen().bounds.size.width
        NSLayoutConstraint.applyAutoLayout(view, target: historyViewController.view, index: nil, top: 0.0, left: Float(-width), right: Float(-width), bottom: 0.0, height: nil, width: Float(width * 3))
        
        
        let  longPressGesture = UILongPressGestureRecognizer(target: self, action: "detectLongTap:")
        longPressGesture.delegate = self
        navigationBar.addGestureRecognizer(longPressGesture)
    }
    
    override public func pushViewController(viewController: UIViewController, animated: Bool) {
        
        screenshotImages += [visibleViewController.view.screenshotImage(scale: kImageScale)]
        
        super.pushViewController(viewController, animated: animated)
    }
    
    override public func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        screenshotImages.removeLast()
        return super.popViewControllerAnimated(animated)
    }
    
    override public func popToRootViewControllerAnimated(animated: Bool) -> [AnyObject]? {
//        if let image = screenshotImages.first {
//            screenshotImages.removeAll(keepCapacity: false)
//            screenshotImages += [image]
//        }
        screenshotImages.removeAll(keepCapacity: false)
        return super.popToRootViewControllerAnimated(animated)
    }
    
    override public func popToViewController(viewController: UIViewController, animated: Bool) -> [AnyObject]? {
        
        var index: Int?
        for (currentIndex, currentViewController) in enumerate(viewControllers) {
            if currentViewController as? UIViewController == viewController {
                index = currentIndex
                break
            }
        }
        
        var removeList = [Bool]()
        for (currentIndex, image) in enumerate(screenshotImages) {
            if currentIndex >= index {
                removeList += [true]
            } else {
                removeList += [false]
            }
        }
        for (currentIndex, shouldRemove) in enumerate(removeList) {
            if shouldRemove {
                if let index = index {
                    screenshotImages.removeAtIndex(index)
                }
            }
        }
        return super.popToViewController(viewController, animated: animated)
    }
    
    override public func setViewControllers(viewControllers: [AnyObject]!, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        for (currentIndex, viewController) in enumerate(viewControllers) {
            if currentIndex == viewControllers.endIndex {
                break
            }
            
            if let viewController = viewController as? UIViewController {
                screenshotImages += [viewController.view.screenshotImage(scale: kImageScale)]
            }
        }
    }
    
    override public func showHistory() {
        
        super.showHistory()
        
        //screenshotImages.removeLast()
        screenshotImages += [visibleViewController.view.screenshotImage(scale: 1.0)]
        
        historyViewController.images = screenshotImages
        historyViewController.currentIndex = viewControllers.count - 1
        historyViewController.reload()
        historyViewController.view.alpha = 1.0
        
        coverView.hidden = false
        historyContentView.hidden = false
        
       setNavigationBarHidden(true, animated: false)
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: {
            self.historyViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7, 0.7)
        }) { (finished) in
                    
        }
    }
    
    override public func setHistoryBackgroundColor(color: UIColor) {
        coverView.backgroundColor = color
    }
    
    override public func contentView() -> UIView? {
        return historyContentView
    }
    
    func detectLongTap(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            showHistory()
        }
    }
}

extension SAHistoryNavigationViewController: SAHistoryViewControllerDelegate {
    func didSelectIndex(index: Int) {
        
        if let viewControllers = self.viewControllers as? [UIViewController] {
            var destinationViewController: UIViewController?
            for (currentIndex, viewController) in enumerate(viewControllers) {
                if currentIndex == index {
                    destinationViewController = viewController
                    break
                }
            }
        
            if let viewController = destinationViewController {
                popToViewController(viewController, animated: false)
            }
            
            
            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: {
                self.historyViewController.view.transform = CGAffineTransformIdentity
                self.historyViewController.scrollToIndex(index, animated: false)
            }) { (finished) in
                self.coverView.hidden = true
                self.historyContentView.hidden = true
                self.historyViewController.view.alpha = 0.0
                self.setNavigationBarHidden(false, animated: true)
            }
        }
    }
}

extension SAHistoryNavigationViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let backItem = visibleViewController.navigationController?.navigationBar.backItem {
            var height = 64.0
            if visibleViewController.navigationController?.navigationBarHidden == true {
                height = 44.0
            }
            let backButtonFrame = CGRect(x: 0.0, y :0.0,  width: 100.0, height: height)
            let touchPoint = gestureRecognizer.locationInView(gestureRecognizer.view)
            if CGRectContainsPoint(backButtonFrame, touchPoint) {
                return true
            }
        }
        
        return false
    }
}
