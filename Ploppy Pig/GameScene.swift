import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private let ploppy = SKSpriteNode(imageNamed: "ploppy")

    private let grassTexture = SKTexture(imageNamed: "grassStrip")

    private let hillTextures: [String: SKTexture] = [
        "hill1": SKTexture(imageNamed: "hill1"),
        "hill2": SKTexture(imageNamed: "hill2"),
        "hill3": SKTexture(imageNamed: "hill3"),
        "hill4": SKTexture(imageNamed: "hill4"),
        "hill5": SKTexture(imageNamed: "hill5"),
        "hill6": SKTexture(imageNamed: "hill6"),
        "hill7": SKTexture(imageNamed: "hill7"),
        "hill8": SKTexture(imageNamed: "hill8"),
        "hill9": SKTexture(imageNamed: "hill9"),
        "hill10": SKTexture(imageNamed: "hill10"),
        "hill11": SKTexture(imageNamed: "hill11"),
        "hill12": SKTexture(imageNamed: "hill12")
    ]

    private let hillSequence = [
        "hill1",
        "hill2",
        "hill3",
        "hill4",
        "hill5",
        "hill6",
        "hill7",
        "hill8",
        "hill9",
        "hill10",
        "hill11",
        "hill12",

        "hill2",
        "hill4",
        "hill6",
        "hill8",
        "hill10",
        "hill12",
        "hill1",
        "hill3",
        "hill5",
        "hill7",
        "hill9",
        "hill11",

        "hill4",
        "hill5",
        "hill8",
        "hill11",
        "hill12",
        "hill7",

        "hill3",
        "hill9",
        "hill1",
        "hill6",
        "hill12",
        "hill5",
        "hill10",
        "hill2",
        "hill8",
        "hill11"
    ]

    /*
     A new hill begins after each fixed interval.

     Every interval is between 0.5 and 1.5 seconds.
     Because a hill takes approximately two seconds
     to cross the screen, some hills will overlap.
    */

    private let hillIntervals: [TimeInterval] = [
        0.5, 1.5, 0.75, 1.25,
        1.0, 0.5, 1.5, 1.0,
        1.25, 0.75, 1.5, 0.5,
        0.75, 1.25, 1.0, 1.0,
        1.5, 0.5, 1.25, 0.75,
        1.0, 1.5, 0.5, 1.0,
        0.75, 1.0, 1.5, 0.75,
        1.25, 0.5, 1.0, 1.25,
        1.5, 1.0, 0.5, 1.0,
        0.5, 1.25, 0.75, 1.5
    ]

    private var hillSize = CGSize.zero
    private var grassSize = CGSize.zero

    private var hillPhysicsBodyTemplates:
        [String: SKPhysicsBody] = [:]

    private var grassPhysicsBodyTemplate:
        SKPhysicsBody?

    private var grassNodes: [SKSpriteNode] = []

    private var scrollSpeed: CGFloat = 0
    private var previousUpdateTime: TimeInterval = 0

    private var isGameOver = false

    private let ploppyCategory: UInt32 = 1 << 0
    private let terrainCategory: UInt32 = 1 << 1

    private let grassSinkBelowScreen: CGFloat = 16

    private let hillSinkBelowScreenFraction: CGFloat = 0.21

    private let grassOverlap: CGFloat = 4

    override func didMove(to view: SKView) {

        removeAllChildren()
        removeAllActions()

        grassNodes.removeAll()
        hillPhysicsBodyTemplates.removeAll()

        isGameOver = false
        previousUpdateTime = 0

        backgroundColor = .cyan

        physicsWorld.gravity = CGVector(
            dx: 0,
            dy: -1.5
        )

        physicsWorld.contactDelegate = self

        prepareTerrain()
        createContinuousGrass()
        createPloppy()
        startCountrysideLoop()
    }

    private func prepareTerrain() {

        guard let firstHillTexture =
            hillTextures["hill1"] else {
            return
        }

        let hillHeight =
            frame.height * 0.85

        let hillAspectRatio =
            firstHillTexture.size().width /
            firstHillTexture.size().height

        hillSize = CGSize(
            width: hillHeight * hillAspectRatio,
            height: hillHeight
        )

        for hillName in hillTextures.keys {

            guard let texture =
                hillTextures[hillName] else {
                continue
            }

            let physicsBody = SKPhysicsBody(
                texture: texture,
                size: hillSize
            )

            configureTerrainPhysicsBody(
                physicsBody
            )

            hillPhysicsBodyTemplates[hillName] =
                physicsBody
        }

        /*
         Preserve the approved scrolling speed.

         Each hill travels completely across the screen
         in approximately two seconds.
        */

        let hillTravelDistance =
            frame.width + hillSize.width

        scrollSpeed =
            hillTravelDistance / 2.0

        let grassAspectRatio =
            grassTexture.size().width /
            grassTexture.size().height

        let naturalGrassHeight =
            hillSize.width / grassAspectRatio

        grassSize = CGSize(
            width: hillSize.width,
            height: max(naturalGrassHeight, 44)
        )

        grassPhysicsBodyTemplate = SKPhysicsBody(
            rectangleOf: grassSize,
            center: CGPoint(
                x: grassSize.width / 2,
                y: grassSize.height / 2
            )
        )

        configureTerrainPhysicsBody(
            grassPhysicsBodyTemplate
        )
    }

    private func configureTerrainPhysicsBody(
        _ physicsBody: SKPhysicsBody?
    ) {

        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.usesPreciseCollisionDetection = true

        physicsBody?.categoryBitMask =
            terrainCategory

        physicsBody?.collisionBitMask =
            ploppyCategory

        physicsBody?.contactTestBitMask =
            ploppyCategory
    }

    private func createContinuousGrass() {

        let grassSpacing =
            grassSize.width - grassOverlap

        let numberOfGrassPieces =
            Int(ceil(frame.width / grassSpacing)) + 3

        for pieceNumber in 0..<numberOfGrassPieces {

            let grassNode = SKSpriteNode(
                texture: grassTexture
            )

            grassNode.name = "grass"
            grassNode.size = grassSize

            grassNode.anchorPoint = CGPoint(
                x: 0,
                y: 0
            )

            grassNode.position = CGPoint(
                x: frame.minX +
                    CGFloat(pieceNumber) *
                    grassSpacing,
                y: frame.minY -
                    grassSinkBelowScreen
            )

            grassNode.zPosition = 1

            if let preparedBody =
                grassPhysicsBodyTemplate?.copy()
                    as? SKPhysicsBody {

                grassNode.physicsBody = preparedBody
            }

            addChild(grassNode)
            grassNodes.append(grassNode)
        }
    }

    override func update(
        _ currentTime: TimeInterval
    ) {

        guard !isGameOver else {
            return
        }

        if previousUpdateTime == 0 {

            previousUpdateTime = currentTime
            return
        }

        var timeSinceLastUpdate =
            currentTime - previousUpdateTime

        timeSinceLastUpdate =
            min(timeSinceLastUpdate, 1.0 / 20.0)

        previousUpdateTime = currentTime

        let movementDistance =
            scrollSpeed *
            CGFloat(timeSinceLastUpdate)

        for grassNode in grassNodes {

            grassNode.position.x -=
                movementDistance
        }

        for grassNode in grassNodes {

            let grassRightEdge =
                grassNode.position.x +
                grassNode.size.width

            if grassRightEdge <= frame.minX {

                let rightmostEdge =
                    grassNodes
                        .filter { $0 !== grassNode }
                        .map {
                            $0.position.x +
                            $0.size.width
                        }
                        .max() ?? frame.maxX

                grassNode.position.x =
                    rightmostEdge -
                    grassOverlap
            }
        }
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
            terrainCategory

        ploppy.physicsBody?.contactTestBitMask =
            terrainCategory

        addChild(ploppy)
    }

    private func startCountrysideLoop() {

        var countrysideActions: [SKAction] = []

        for hillNumber in 0..<hillSequence.count {

            let hillName =
                hillSequence[hillNumber]

            let hillInterval =
                hillIntervals[hillNumber]

            let createHill =
                SKAction.run { [weak self] in

                    guard let self = self else {
                        return
                    }

                    guard !self.isGameOver else {
                        return
                    }

                    self.createAndScrollHill(
                        named: hillName
                    )
                }

            let waitForNextHill =
                SKAction.wait(
                    forDuration: hillInterval
                )

            countrysideActions.append(
                createHill
            )

            countrysideActions.append(
                waitForNextHill
            )
        }

        let countrysideCycle =
            SKAction.sequence(
                countrysideActions
            )

        run(
            SKAction.repeatForever(
                countrysideCycle
            ),
            withKey: "countrysideLoop"
        )
    }

    private func createAndScrollHill(
        named hillName: String
    ) {

        guard let hillTexture =
            hillTextures[hillName] else {
            return
        }

        let hillNode = SKSpriteNode(
            texture: hillTexture
        )

        hillNode.name = "hill"
        hillNode.size = hillSize

        hillNode.anchorPoint = CGPoint(
            x: 0.5,
            y: 0.5
        )

        let hillSinkDistance =
            frame.height *
            hillSinkBelowScreenFraction

        hillNode.position = CGPoint(
            x: frame.maxX +
                hillNode.size.width / 2,
            y: frame.minY +
                hillNode.size.height / 2 -
                hillSinkDistance
        )

        hillNode.zPosition = 2

        if let preparedBody =
            hillPhysicsBodyTemplates[hillName]?
                .copy() as? SKPhysicsBody {

            hillNode.physicsBody = preparedBody
        }

        addChild(hillNode)

        let finalX =
            frame.minX -
            hillNode.size.width / 2

        let travelDistance =
            frame.width +
            hillNode.size.width

        let travelDuration =
            TimeInterval(
                travelDistance / scrollSpeed
            )

        let moveHill =
            SKAction.moveTo(
                x: finalX,
                duration: travelDuration
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
            CGVector(
                dx: 0,
                dy: 110
            )
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
            terrainCategory

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
            forKey: "countrysideLoop"
        )

        for grassNode in grassNodes {

            grassNode.physicsBody = nil
        }

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
