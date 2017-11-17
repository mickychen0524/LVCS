//
//  SnapContainerViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/13/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

protocol SnapContainerViewControllerDelegate {
    func outerScrollViewShouldScroll() -> Bool
}

class SnapContainerViewController: UIViewController, UIScrollViewDelegate, AKFViewControllerDelegate {
    
    var overLeftVc : UIViewController!
    var leftVc: UIViewController!
    var middleVc: UIViewController!
    var rightVc: UIViewController!
    var overRightVc: UIViewController!
    var nextOfOverRightVc: UIViewController!
    var tileMainRightVc: UIViewController!
    var ticketErrorRightVc: UIViewController!
    var topVc: UIViewController?
    var bottomVc: UIViewController?
    
    var directionLockDisabled: Bool!
    
    var horizontalViewControllers: [UIViewController] = []
    var veritcalViewControllers: [UIViewController] = []
    
    var initialContentOffset = CGPoint() // scrollView initial offset
    var middleVertScrollVc: VerticalScrollViewController!
    var scrollView: UIScrollView!
    var delegate: SnapContainerViewControllerDelegate?
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    var config = GTStorage.sharedGTStorage
    
    var rect: (x:CGFloat, y:CGFloat, width: CGFloat, height: CGFloat) = (x: 0, y: 0, width: 0, height: 0)
    
    var animated = false
    
    class func containerViewWith(_ overLeftVC : UIViewController,
                                 leftVC: UIViewController,
                                 middleVC: UIViewController,
                                 rightVC: UIViewController,
                                 overRightVC: UIViewController,
                                 nextOfOverRightVC: UIViewController,
                                 tileMainRightVC: UIViewController,
                                 ticketErrorRightVC: UIViewController,
                                 topVC: UIViewController?=nil,
                                 bottomVC: UIViewController?=nil,
                                 directionLockDisabled: Bool?=false) -> SnapContainerViewController {
        let container = SnapContainerViewController()
        
        container.directionLockDisabled = directionLockDisabled
        
        container.overLeftVc = overLeftVC
        container.leftVc = leftVC
        container.middleVc = middleVC
        container.rightVc = rightVC
        container.overRightVc = overRightVC
        container.nextOfOverRightVc = nextOfOverRightVC
        container.tileMainRightVc = tileMainRightVC
        container.ticketErrorRightVc = ticketErrorRightVC
        container.topVc = topVC
        container.bottomVc = bottomVC
        
        return container
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.overLeftVc = storyboard.instantiateViewController(withIdentifier: "settingViewController")
        self.leftVc = storyboard.instantiateViewController(withIdentifier: "giftCardListViewController")
        self.middleVc = storyboard.instantiateViewController(withIdentifier: "redeemViewController")
        self.rightVc = storyboard.instantiateViewController(withIdentifier: "homeViewController")
        self.overRightVc = storyboard.instantiateViewController(withIdentifier: "ticketListViewController")
        self.nextOfOverRightVc = storyboard.instantiateViewController(withIdentifier: "chatViewController")
        self.tileMainRightVc = storyboard.instantiateViewController(withIdentifier: "tileMainViewController")
        self.ticketErrorRightVc = storyboard.instantiateViewController(withIdentifier: "ticketErrorViewController")
        self.topVc = storyboard.instantiateViewController(withIdentifier: "gamePlayViewController")
        self.directionLockDisabled = false
        setupVerticalScrollView(false)
        setupHorizontalScrollView(false)
        
//        let directions: [UISwipeGestureRecognizerDirection] = [.up, .down, .right, .left]
//        for direction in directions {
//            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
//            gesture.direction = direction
//            self.view?.addGestureRecognizer(gesture)
//        }
        
    }
    
    public func doAnimation() {
        if !animated {
            UIView.animate(withDuration: 0.5, animations: {
                self.middleVertScrollVc.scrollView.contentOffset = CGPoint.init(x: self.middleVertScrollVc.scrollView.contentOffset.x, y: self.middleVertScrollVc.scrollView.contentOffset.y - 150)
            }) { (completed) in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    self.middleVertScrollVc.scrollView.contentOffset = CGPoint.init(x: self.middleVertScrollVc.scrollView.contentOffset.x, y: self.middleVertScrollVc.scrollView.contentOffset.y + 150)
                }, completion: { (completed) in
                    UIView.animate(withDuration: 0.5, delay: 1, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.contentOffset.x - 150, y: self.scrollView.contentOffset.y)
                    }, completion: { (completed) in
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                            self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.contentOffset.x + 150, y: self.scrollView.contentOffset.y)
                        }, completion: { (completed ) in
                            UIView.animate(withDuration: 0.5, delay: 1, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                                self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.contentOffset.x + 150, y: self.scrollView.contentOffset.y)
                            }, completion: { (completed) in
                                UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                                    self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.contentOffset.x - 150, y: self.scrollView.contentOffset.y)
                                }, completion: nil)
                            })
                        })
                    })
                })
            }
            animated = true
        }
    }
    
    func setupVerticalScrollView(_ status : Bool) {
        middleVertScrollVc = VerticalScrollViewController.verticalScrollVcWith(state: status, middleVc: rightVc, topVc: topVc)
        delegate = middleVertScrollVc
    }
    
    func setupHorizontalScrollView(_ status : Bool) {
        scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        
        rect = (
            x: self.view.bounds.origin.x,
            y: self.view.bounds.origin.y,
            width: status ? self.view.bounds.height : self.view.bounds.width,
            height: status ? self.view.bounds.width : self.view.bounds.height
        )
        
        scrollView.frame = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        
        self.view.addSubview(scrollView)
        
        if appDelegate.getRedeemCardJSONDataFromLocal().count == 0 && appDelegate.getTicketJSONDataFromLocal().count == 0 {
            horizontalViewControllers = [overLeftVc, leftVc, middleVertScrollVc, nextOfOverRightVc, tileMainRightVc]
        } else if appDelegate.getRedeemCardJSONDataFromLocal().count == 0 {
            horizontalViewControllers = [overLeftVc, leftVc, middleVertScrollVc, overRightVc, nextOfOverRightVc, tileMainRightVc]
        } else if appDelegate.getTicketJSONDataFromLocal().count == 0 {
            horizontalViewControllers = [overLeftVc, leftVc, middleVc, middleVertScrollVc, nextOfOverRightVc, tileMainRightVc]
        } else {
            horizontalViewControllers = [overLeftVc, leftVc, middleVc, middleVertScrollVc, overRightVc, nextOfOverRightVc, tileMainRightVc]
        }
        
        let showBot = config.getValue("showBot", fromStore: "settings") as! Bool
        if showBot == false, let index = horizontalViewControllers.index(of: nextOfOverRightVc) {
            horizontalViewControllers.remove(at: index)
        }
        
        let scrollWidth  = rect.width * CGFloat(horizontalViewControllers.count)
        let scrollHeight  = rect.height
        scrollView.contentSize = CGSize(width: scrollWidth, height: scrollHeight)
        
        for (index, vc) in horizontalViewControllers.enumerated() {
            vc.view.frame = CGRect(x: CGFloat(index) * rect.width, y: 0, width: rect.width, height: rect.height)
            addChildViewController(vc)
            scrollView.addSubview(vc.view)
            vc.didMove(toParentViewController: self)
        }
        
        scrollView.contentOffset.x = middleVertScrollVc.view.frame.origin.x
        scrollView.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let homeOverlayTimes = self.config.getValue("homeOverlayTimes", fromStore: "settings") as! Int
            let homeAnimationTimes = self.config.getValue("homeAnimationTimes", fromStore: "settings") as! Int
            
            if self.appDelegate.globalStartCount >= homeOverlayTimes && self.appDelegate.globalStartCount < homeOverlayTimes + homeAnimationTimes && !self.animated {
                self.doAnimation()
            }
        }
    }
    
    func addOrRemoveChatViewController(_ add: Bool) {
        guard let index = horizontalViewControllers.index(of: tileMainRightVc) else { return }
        
        if add == true {
            nextOfOverRightVc.view.frame = tileMainRightVc.view.frame
            addChildViewController(nextOfOverRightVc)
            scrollView.addSubview(nextOfOverRightVc.view)
            nextOfOverRightVc.didMove(toParentViewController: self)
            
            var frame = tileMainRightVc.view.frame
            frame.origin.x += rect.width
            tileMainRightVc.view.frame = frame
            
            scrollView.contentSize = CGSize(width: scrollView.contentSize.width + rect.width, height: scrollView.contentSize.height)
            
            horizontalViewControllers.insert(nextOfOverRightVc, at: index)
            
        } else {
            if horizontalViewControllers[index - 1] == nextOfOverRightVc {
                nextOfOverRightVc.willMove(toParentViewController: nil)
                nextOfOverRightVc.view.removeFromSuperview()
                nextOfOverRightVc.removeFromParentViewController()
                
                var frame = tileMainRightVc.view.frame
                frame.origin.x -= rect.width
                tileMainRightVc.view.frame = frame
                
                scrollView.contentSize = CGSize(width: scrollView.contentSize.width - rect.width, height: scrollView.contentSize.height)
                
                horizontalViewControllers.remove(at: index - 1)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.initialContentOffset = scrollView.contentOffset
        view.endEditing(true)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate != nil && !delegate!.outerScrollViewShouldScroll() && !directionLockDisabled {
            let newOffset = CGPoint(x: self.initialContentOffset.x, y: self.initialContentOffset.y)

            // Setting the new offset to the scrollView makes it behave like a proper
            // directional lock, that allows you to scroll in only one direction at any given time
            self.scrollView!.setContentOffset(newOffset, animated:  false)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight {
            print("landscape state")
        } else {
            print("portrait state")
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.setupVerticalScrollView(false)
            self.setupHorizontalScrollView(false)
        }
        
    }
    
    
    @objc func respondToSwipeGesture(gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.right:
            print("right")
            config.writeValue(true as AnyObject!, forKey: "rightViewHasShown", toStore: "settings")
        case UISwipeGestureRecognizerDirection.down:
            print("down")
            config.writeValue(true as AnyObject!, forKey: "topViewHasShown", toStore: "settings")
        case UISwipeGestureRecognizerDirection.left:
            print("left")
            config.writeValue(true as AnyObject!, forKey: "leftViewHasShown", toStore: "settings")
        case UISwipeGestureRecognizerDirection.up:
            print("up")
        default:
            break
        }
    }
    
    
    // shake motion detection part
    override var canBecomeFirstResponder: Bool { return true }
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake
        {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc : ShowSocialImageViewController = mainStoryboard.instantiateViewController(withIdentifier: "showSocialImageViewController") as? ShowSocialImageViewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
    }
}
