//
//  VerticalScrollViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/3/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class VerticalScrollViewController: UIViewController, SnapContainerViewControllerDelegate {

    var topVc: UIViewController!
    var middleVc: UIViewController!
    var bottomVc: UIViewController!
    var scrollView: UIScrollView!
    
    var isGameOpened = false
    
    var portState : Bool!
    
    var config = GTStorage.sharedGTStorage
    
    class func verticalScrollVcWith(state: Bool!,
                                    middleVc: UIViewController!,
                                    topVc: UIViewController?=nil,
                                    bottomVc: UIViewController?=nil) -> VerticalScrollViewController {
        let middleScrollVc = VerticalScrollViewController()
        
        middleScrollVc.portState = state
        middleScrollVc.topVc = topVc
        middleScrollVc.middleVc = middleVc
        middleScrollVc.bottomVc = bottomVc
        
        return middleScrollVc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view:
        
        setupScrollView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.setContentOffset(CGPoint(x: 0, y: view.bounds.size.height), animated: true)
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        
        var view = (
            x: self.view.bounds.origin.x,
            y: self.view.bounds.origin.y,
            width: self.view.bounds.width,
            height: self.view.bounds.height
        )
        
        if portState == true {
            view = (
                x: self.view.bounds.origin.x,
                y: self.view.bounds.origin.y,
                width: self.view.bounds.height,
                height: self.view.bounds.width
            )
        }
        scrollView.frame = CGRect(x: view.x, y: view.y, width: view.width, height: view.height)
        self.view.addSubview(scrollView)
        
        let scrollWidth: CGFloat  = view.width
        var scrollHeight: CGFloat
        
        if topVc != nil && bottomVc != nil {
            scrollHeight  = 3 * view.height
            topVc.view.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
            middleVc.view.frame = CGRect(x: 0, y: view.height, width: view.width, height: view.height)
            bottomVc.view.frame = CGRect(x: 0, y: 2 * view.height, width: view.width, height: view.height)
            
            addChildViewController(topVc)
            addChildViewController(middleVc)
            addChildViewController(bottomVc)
            
            scrollView.addSubview(topVc.view)
            scrollView.addSubview(middleVc.view)
            scrollView.addSubview(bottomVc.view)
            
            topVc.didMove(toParentViewController: self)
            middleVc.didMove(toParentViewController: self)
            bottomVc.didMove(toParentViewController: self)
            
            scrollView.contentOffset.y = middleVc.view.frame.origin.y
            
        } else if topVc == nil {
            scrollHeight  = 2 * view.height
            middleVc.view.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
            bottomVc.view.frame = CGRect(x: 0, y: view.height, width: view.width, height: view.height)
            
            addChildViewController(middleVc)
            addChildViewController(bottomVc)
            
            scrollView.addSubview(middleVc.view)
            scrollView.addSubview(bottomVc.view)
            
            middleVc.didMove(toParentViewController: self)
            bottomVc.didMove(toParentViewController: self)
            
            scrollView.contentOffset.y = 0
            
        } else if bottomVc == nil {
            scrollHeight  = 2 * view.height
            topVc.view.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
            middleVc.view.frame = CGRect(x: 0, y: view.height, width: view.width, height: view.height)
            
            addChildViewController(topVc)
            addChildViewController(middleVc)
            
            scrollView.addSubview(topVc.view)
            scrollView.addSubview(middleVc.view)
            
            topVc.didMove(toParentViewController: self)
            middleVc.didMove(toParentViewController: self)
            
            scrollView.contentOffset.y = middleVc.view.frame.origin.y
            
        } else {
            scrollHeight  = view.height
            middleVc.view.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
            
            addChildViewController(middleVc)
            scrollView.addSubview(middleVc.view)
            middleVc.didMove(toParentViewController: self)
        }
        
        scrollView.contentSize = CGSize(width: scrollWidth, height: scrollHeight)
        scrollView.delegate = self
    }
    
    // MARK: - SnapContainerViewControllerDelegate Methods
    
    func outerScrollViewShouldScroll() -> Bool {
        if scrollView.contentOffset.y < middleVc.view.frame.origin.y || scrollView.contentOffset.y > 2*middleVc.view.frame.origin.y {
            return false
        } else {

            return true
        }
    }
}

extension VerticalScrollViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard let gameVC = topVc as? GamePlayViewController else { return }
        
        if scrollView.contentOffset.y == 0 {
            gameVC.pausedScene(false)
            isGameOpened = true
        }
        
        if scrollView.contentOffset.y == scrollView.frame.height, isGameOpened {
            isGameOpened = false
            guard let scoreValue = Int(gameVC.scene?.scoreLabelNode.text ?? "") else { return }
            AlamofireRequestAndResponse.sharedInstance.sendGamePoints(scoreValue) {
                print("Game is closed")
                AlamofireRequestAndResponse.sharedInstance.gameRefId = nil
            }
            gameVC.pausedScene(true)
        }
    }
}
