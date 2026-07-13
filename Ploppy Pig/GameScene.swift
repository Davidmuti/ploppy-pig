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

        createSingleCloudPuff()
    }

    private func createSingleCloudPuff() {

        let puff = SKSpriteNode(imageNamed: "cloudPuff")

        puff.position = CGPoint(
            x: ploppy.position.x - (ploppy.frame.width * 0.42),
            y: ploppy.position.y - 8
        )

        puff.setScale(0.025)

        puff.alpha = 0.9

        puff.zPosition = ploppy.zPosition - 1

        addChild(puff)

        let moveLeft = SKAction.moveBy(
            x: -150,
            y: -4,
            duration: 1.4
        )

        let grow = SKAction.scale(
            to: 0.11,
            duration: 1.4
        )

        let fade = SKAction.fadeOut(
            withDuration: 1.4
        )

        let moveGrowAndFade = SKAction.group([
            moveLeft,
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
