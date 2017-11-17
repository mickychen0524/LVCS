//
//  GamePlayViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/3/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SpriteKit

class GamePlayViewController: UIViewController {
    
    @IBOutlet weak var gameScene: SKView!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    var scene: GameScene? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene.unarchiveFromFile("GameScene")
        if (scene != nil) {
            // Configure the view.
            self.gameScene.showsFPS = true
            self.gameScene.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            self.gameScene.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene?.scaleMode = .aspectFill
            startScene()
        }
    }
    
    func startScene() {
        self.gameScene.presentScene(scene)
    }
    
    func pausedScene(_ isPaused: Bool) {
        scene?.isPaused = isPaused
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
