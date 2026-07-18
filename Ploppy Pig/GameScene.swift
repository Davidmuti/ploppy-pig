import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private let ploppy = SKSpriteNode(imageNamed: "ploppy")

    private let hillTexture = SKTexture(imageNamed: "hill1")

    private var hillSize = CGSize.zero
    private var hillPhysicsBodyTemplate: SKPhysicsBody?

    private var isGameOver = false

    private let ploppyCategory: UInt32 = 1 << 0
    private let hillCategory: UInt32 = 1 << 1

    override func didMove(to view: SKView) {

        removeAllChildren()
        removeAllActions()

        backgroundColor = .cyan

        physicsWorld.gravity = CGVector(
            dx: 0,
            dy: -1.5
        )

        physicsWorld.contactDelegate = self

        /*
         Build the hill's collision shape now,
         before gameplay starts.

         This prevents SpriteKit from constructing
         it at the moment the hill appears.
        */

        prepareHill()

        createPloppy()
        startHillLoop()
    }

    private func prepareHill() {

        let hillHeight =
            frame.height * 0.85

        let aspectRatio =
            hillTexture.size().width /
            hillTexture.size().height

        hillSize = CGSize(
            width: hillHeight * aspectRatio,
            height: hillHeight
        )

        hillPhysicsBodyTemplate = SKPhysicsBody(
            texture: hillTexture,
            size: hillSize
        )

        hillPhysicsBodyTemplate?.isDynamic = true
        hillPhysicsBodyTemplate?.affectedByGravity = false
        hillPhysicsBodyTemplate?.allowsRotation = false
        hillPhysicsBodyTemplate?.usesPreciseCollisionDetection = true

        hillPhysicsBodyTemplate?.categoryBitMask =
            hillCategory

        hillPhysicsBodyTemplate?.collisionBitMask =
            ploppyCategory

        hillPhysicsBodyTemplate?.contactTestBitMask =
            ploppyCategory
    }

    private func createPloppy() {

        ploppy.position = CGPoint(
            x: frame.minX + 180,
            y: frame.midY + 100
        )

        ploppy.setScale(0.08)
        ploppy.zPosition = 10

        ploppy.physicsBody = SKPhysicsBody(
            rectangleOf: ploppy.size
        )

        ploppy.physicsBody?.allowsRotation = false
        ploppy.physicsBody?.restitution = 0
        ploppy.physicsBody?.usesPreciseCollisionDetection = true

        ploppy.physicsBody?.categoryBitMask =
            ploppyCategory

        ploppy.physicsBody?.collisionBitMask =
            hillCategory

        ploppy.physicsBody?.contactTestBitMask =
            hillCategory

        addChild(ploppy)
    }

    private func startHillLoop() {

        let emptySky = SKAction.wait(
            forDuration: 2.0
        )

        let createHill = SKAction.run { [weak self] in

            guard let self = self else {
                return
            }

            guard !self.isGameOver else {
                return
            }

            self.createAndScrollHill()
        }

        let waitWhileHillPasses = SKAction.wait(
            forDuration: 2.0
        )

        let completeCycle = SKAction.sequence([
            emptySky,
            createHill,
            waitWhileHillPasses
        ])

        run(
            SKAction.repeatForever(
                completeCycle
            ),
            withKey: "hillLoop"
        )
    }

    private func createAndScrollHill() {

        let hillNode = SKSpriteNode(
            texture: hillTexture
        )

        hillNode.name = "hill"

        hillNode.size = hillSize

        hillNode.anchorPoint = CGPoint(
            x: 0.5,
            y: 0.5
        )

        hillNode.position = CGPoint(
            x: frame.maxX + hillNode.size.width / 2,
            y: frame.minY + hillNode.size.height / 2
        )

        hillNode.zPosition = 1

        /*
         Reuse a copy of the collision body that
         was prepared before gameplay began.
        */

        if let preparedBody =
            hillPhysicsBodyTemplate?.copy()
                as? SKPhysicsBody {

            hillNode.physicsBody = preparedBody
        }

        addChild(hillNode)

        let finalX =
            frame.minX - hillNode.size.width / 2

        let moveHill = SKAction.moveTo(
            x: finalX,
            duration: 2.0
        )

        moveHill.timingMode = .linear

        hillNode.run(
            SKAction.sequence([
                moveHill,
                SKAction.removeFromParent()
            ])
        )
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        guard !isGameOver else {
            return
        }

        ploppy.physicsBody?.velocity = CGVector(
            dx: 0,
            dy: 0
        )

        ploppy.physicsBody?.applyImpulse(
            CGVector(dx: 0, dy: 110)
        )

        createCloudTrail()
    }

    func didBegin(
        _ contact: SKPhysicsContact
    ) {

        let contactedCategories =
            contact.bodyA.categoryBitMask |
            contact.bodyB.categoryBitMask

        let requiredCategories =
            ploppyCategory |
            hillCategory

        if contactedCategories == requiredCategories {
            killPloppy()
        }
    }

    private func killPloppy() {

        guard !isGameOver else {
            return
        }

        isGameOver = true

        let deathPosition =
            ploppy.position

        removeAction(
            forKey: "hillLoop"
        )

        enumerateChildNodes(
            withName: "hill"
        ) { hillNode, _ in

            hillNode.removeAllActions()
            hillNode.physicsBody = nil
        }

        ploppy.removeFromParent()

        let deathCloud = SKSpriteNode(
            imageNamed: "cloudPuff1"
        )

        deathCloud.position =
            deathPosition

        deathCloud.setScale(0.20)
        deathCloud.zPosition = 20

        addChild(deathCloud)
    }

    private func createCloudTrail() {

        let numberOfPuffs =
            Int.random(in: 25...30)

        var trailActions: [SKAction] = []

        for puffNumber in 0..<numberOfPuffs {

            if puffNumber > 0 {

                trailActions.append(
                    SKAction.wait(
                        forDuration: 0.06
                    )
                )
            }

            let createPuff =
                SKAction.run { [weak self] in

                    guard let self = self else {
                        return
                    }

                    guard !self.isGameOver else {
                        return
                    }

                    self.createSingleCloudPuff()
                }

            trailActions.append(createPuff)
        }

        run(
            SKAction.sequence(
                trailActions
            )
        )
    }

    private func createSingleCloudPuff() {

        guard !isGameOver else {
            return
        }

        let cloudNames = [
            "cloudPuff1",
            "cloudPuff2",
            "cloudPuff3"
        ]

        guard let randomName =
                cloudNames.randomElement() else {
            return
        }

        let puff = SKSpriteNode(
            imageNamed: randomName
        )

        puff.position = CGPoint(
            x: ploppy.position.x - 24,
            y: ploppy.position.y - 18
        )

        puff.setScale(0.015)
        puff.alpha = 0.9
        puff.zPosition = ploppy.zPosition - 1

        addChild(puff)

        let initialPushLeft =
            SKAction.moveBy(
                x: -12,
                y: 0,
                duration: 0.02
            )

        let slowDriftLeft =
            SKAction.moveBy(
                x: -138,
                y: -4,
                duration: 1.38
            )

        let movement =
            SKAction.sequence([
                initialPushLeft,
                slowDriftLeft
            ])

        let grow =
            SKAction.scale(
                to: 0.20,
                duration: 4.2
            )

        let fade =
            SKAction.fadeOut(
                withDuration: 4.2
            )

        puff.run(
            SKAction.sequence([
                SKAction.group([
                    movement,
                    grow,
                    fade
                ]),
                SKAction.removeFromParent()
            ])
        )
    }
}
