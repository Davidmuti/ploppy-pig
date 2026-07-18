//
//  GameViewController.swift
//  Ploppy Pig
//
//  Created by David Smith on 7/6/26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else {
            return
        }

        let scene = GameScene(
            size: skView.bounds.size
        )

        scene.scaleMode = .resizeFill

        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override var supportedInterfaceOrientations:
        UIInterfaceOrientationMask {

        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
