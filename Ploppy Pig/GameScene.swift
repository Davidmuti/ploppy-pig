import SpriteKit

class GameScene: SKScene {

    private let ploppy = SKSpriteNode(imageNamed: "ploppy")

    override func didMove(to view: SKView) {

        removeAllChildren()

        backgroundColor = .cyan

        physicsWorld.gravity = CGVector(dx: 0, dy: -1.5)

        ploppy.position = CGPoint(
            x: frame.minX + 180,
            y: frame.midY + 100
        )

        ploppy.setScale(0.08)

        ploppy.physicsBody = SKPhysicsBody(
            rectangleOf: ploppy.size
        )

        ploppy.physicsBody?.allowsRotation = false
        ploppy.physicsBody?.restitution = 0.2

        addChild(ploppy)

        let ground = SKNode()

        ground.position = CGPoint(
            x: frame.midX,
            y: frame.minY + 40
        )

        ground.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(
                width: frame.width,
                height: 20
            )
        )

        ground.physicsBody?.isDynamic = false

        addChild(ground)
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        ploppy.physicsBody?.velocity = CGVector(
            dx: 0,
            dy: 0
        )

        ploppy.physicsBody?.applyImpulse(
            CGVector(dx: 0, dy: 110)
        )

        createCloudTrail()
    }

    private func createCloudTrail() {

        let numberOfPuffs = Int.random(in: 25...30)

        var trailActions: [SKAction] = []

        for puffNumber in 0..<numberOfPuffs {

            if puffNumber > 0 {
                trailActions.append(
                    SKAction.wait(forDuration: 0.06)
                )
            }

            let createPuff = SKAction.run { [weak self] in
                self?.createSingleCloudPuff()
            }

            trailActions.append(createPuff)
        }

        run(SKAction.sequence(trailActions))
    }

    private func createSingleCloudPuff() {

        let cloudNames = ["cloudPuff1", "cloudPuff2", "cloudPuff3"]
        let randomName = cloudNames.randomElement()!

        let puff = SKSpriteNode(imageNamed: randomName)

        puff.position = CGPoint(
            x: ploppy.position.x - 24,
            y: ploppy.position.y - 18
        )

        puff.setScale(0.015)
        puff.alpha = 0.9
        puff.zPosition = ploppy.zPosition - 1

        addChild(puff)

        let initialPushLeft = SKAction.moveBy(
            x: -12,
            y: 0,
            duration: 0.02
        )

        let slowDriftLeft = SKAction.moveBy(
            x: -138,
            y: -4,
            duration: 1.38
        )

        let completeMovement = SKAction.sequence([
            initialPushLeft,
            slowDriftLeft
        ])

        let grow = SKAction.scale(
            to: 0.20,
            duration: 4.2
        )

        let fade = SKAction.fadeOut(
            withDuration: 4.2
        )

        let moveGrowAndFade = SKAction.group([
            completeMovement,
            grow,
            fade
        ])

        puff.run(
            SKAction.sequence([
                moveGrowAndFade,
                SKAction.removeFromParent()
            ])
        )
    }
}
