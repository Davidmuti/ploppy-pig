//
//  GameViewController.swift
//  Ploppy Pig
//
//  Created by David Smith on 7/6/26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {

        return [
            createGameKeyCommand(
                input:
                    UIKeyCommand.inputLeftArrow,
                action:
                    #selector(handleLeftArrow)
            ),
            createGameKeyCommand(
                input:
                    UIKeyCommand.inputUpArrow,
                action:
                    #selector(handleUpArrow)
            ),
            createGameKeyCommand(
                input:
                    UIKeyCommand.inputDownArrow,
                action:
                    #selector(handleDownArrow)
            )
        ]
    }

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

    override func viewDidAppear(
        _ animated: Bool
    ) {

        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    private func createGameKeyCommand(
        input: String,
        action: Selector
    ) -> UIKeyCommand {

        let command = UIKeyCommand(
            input: input,
            modifierFlags: [],
            action: action
        )

        command.wantsPriorityOverSystemBehavior =
            true

        return command
    }

    private var gameScene: GameScene? {

        guard let skView =
            view as? SKView else {
            return nil
        }

        return skView.scene as? GameScene
    }

    @objc private func handleLeftArrow() {
        gameScene?.handleFartInput()
    }

    @objc private func handleUpArrow() {
        gameScene?.handleUpperRightPooInput()
    }

    @objc private func handleDownArrow() {
        gameScene?.handleLowerRightPooInput()
    }

    override var supportedInterfaceOrientations:
        UIInterfaceOrientationMask {

        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

