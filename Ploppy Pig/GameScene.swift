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
    private var skyCloudNodes: [SKShapeNode] = []
    private var rearDistantHillNodes: [SKSpriteNode] = []
    private var distantHillNodes: [SKSpriteNode] = []

    private var scrollSpeed: CGFloat = 0
    private var previousUpdateTime: TimeInterval = 0

    private var isGameOver = false

    private let ploppyCategory: UInt32 = 1 << 0
    private let terrainCategory: UInt32 = 1 << 1

    private let grassSinkBelowScreen: CGFloat = 16
    private let hillSinkBelowScreenFraction: CGFloat = 0.21
    private let grassOverlap: CGFloat = 4

    private lazy var hillShadingShader: SKShader = {

        let shaderSource = """
        void main() {
            vec4 originalColour = texture2D(
                u_texture,
                v_tex_coord
            );

            float lightFromAbove = mix(
                0.78,
                1.10,
                v_tex_coord.y
            );

            float lightFromLeft = mix(
                1.06,
                0.90,
                v_tex_coord.x
            );

            vec2 highlightCentre = vec2(0.30, 0.76);
            float highlightDistance = distance(
                v_tex_coord,
                highlightCentre
            );

            float softHighlight = 1.0 +
                0.08 *
                (1.0 - smoothstep(
                    0.0,
                    0.72,
                    highlightDistance
                ));

            float combinedLight =
                lightFromAbove *
                lightFromLeft *
                softHighlight;

            vec3 shadedColour =
                originalColour.rgb *
                combinedLight;

            gl_FragColor = vec4(
                shadedColour,
                originalColour.a
            );
        }
        """

        return SKShader(source: shaderSource)
    }()

    override func didMove(to view: SKView) {

        removeAllChildren()
        removeAllActions()

        grassNodes.removeAll()
        skyCloudNodes.removeAll()
        rearDistantHillNodes.removeAll()
        distantHillNodes.removeAll()
        hillPhysicsBodyTemplates.removeAll()

        isGameOver = false
        previousUpdateTime = 0

        backgroundColor = .clear
        createSkyGradient()
        createSparseSkyClouds()
        createDistantHillLayers()

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

    private func createSkyGradient() {

        let renderer = UIGraphicsImageRenderer(size: frame.size)
        let image = renderer.image { context in
            let colours = [
                UIColor(red: 0.30, green: 0.65, blue: 0.88, alpha: 1).cgColor,
                UIColor(red: 0.73, green: 0.88, blue: 0.96, alpha: 1).cgColor
            ] as CFArray

            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colours,
                locations: [0, 1]
            ) else { return }

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: frame.height),
                options: []
            )
        }

        let sky = SKSpriteNode(texture: SKTexture(image: image))
        sky.name = "skyGradient"
        sky.size = frame.size
        sky.position = CGPoint(x: frame.midX, y: frame.midY)
        sky.zPosition = -100
        addChild(sky)
    }

    private func createSparseSkyClouds() {

        let cloudPositions: [CGPoint] = [
            CGPoint(
                x: frame.minX + frame.width * 0.22,
                y: frame.minY + frame.height * 0.72
            ),
            CGPoint(
                x: frame.minX + frame.width * 1.05,
                y: frame.minY + frame.height * 0.82
            ),
            CGPoint(
                x: frame.minX + frame.width * 1.88,
                y: frame.minY + frame.height * 0.66
            )
        ]

        let cloudScales: [CGFloat] = [
            1.0,
            0.78,
            1.15
        ]

        for cloudNumber in 0..<cloudPositions.count {

            let cloudPath = CGMutablePath()
            cloudPath.move(to: CGPoint(x: -165, y: -12))
            cloudPath.addCurve(
                to: CGPoint(x: -92, y: 3),
                control1: CGPoint(x: -155, y: 4),
                control2: CGPoint(x: -127, y: 8)
            )
            cloudPath.addCurve(
                to: CGPoint(x: -25, y: 26),
                control1: CGPoint(x: -78, y: 25),
                control2: CGPoint(x: -48, y: 31)
            )
            cloudPath.addCurve(
                to: CGPoint(x: 48, y: 10),
                control1: CGPoint(x: -1, y: 34),
                control2: CGPoint(x: 30, y: 28)
            )
            cloudPath.addCurve(
                to: CGPoint(x: 112, y: 3),
                control1: CGPoint(x: 68, y: 20),
                control2: CGPoint(x: 99, y: 16)
            )
            cloudPath.addCurve(
                to: CGPoint(x: 165, y: -12),
                control1: CGPoint(x: 139, y: 4),
                control2: CGPoint(x: 158, y: -2)
            )
            cloudPath.addCurve(
                to: CGPoint(x: -165, y: -12),
                control1: CGPoint(x: 88, y: -27),
                control2: CGPoint(x: -88, y: -27)
            )
            cloudPath.closeSubpath()

            let cloud = SKShapeNode(path: cloudPath)
            cloud.name = "skyCloud"
            cloud.position = cloudPositions[cloudNumber]
            cloud.setScale(cloudScales[cloudNumber])
            cloud.fillColor = UIColor(
                red: 0.94,
                green: 0.97,
                blue: 1.0,
                alpha: 0.15
            )
            cloud.strokeColor = .clear
            cloud.glowWidth = 10
            cloud.zPosition = -99

            addChild(cloud)
            skyCloudNodes.append(cloud)
        }
    }

    private func createDistantHillLayers() {

        createDistantHillLayer(
            name: "rearDistantHills",
            height: frame.height * 0.27,
            colour: UIColor(red: 0.38, green: 0.58, blue: 0.73, alpha: 0.25),
            zPosition: -97,
            rearLayer: true
        )

        createDistantHillLayer(
            name: "distantHills",
            height: frame.height * 0.34,
            colour: UIColor(red: 0.55, green: 0.69, blue: 0.79, alpha: 1.0),
            zPosition: -95,
            rearLayer: false
        )
    }

    private func createDistantHillLayer(
        name: String,
        height: CGFloat,
        colour: UIColor,
        zPosition: CGFloat,
        rearLayer: Bool
    ) {

        let width = frame.width
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { _ in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: 0, y: height * 0.70))

            if rearLayer {
                path.addCurve(
                    to: CGPoint(x: width * 0.34, y: height * 0.43),
                    controlPoint1: CGPoint(x: width * 0.11, y: height * 0.69),
                    controlPoint2: CGPoint(x: width * 0.22, y: height * 0.40)
                )
                path.addCurve(
                    to: CGPoint(x: width * 0.68, y: height * 0.50),
                    controlPoint1: CGPoint(x: width * 0.45, y: height * 0.31),
                    controlPoint2: CGPoint(x: width * 0.57, y: height * 0.48)
                )
                path.addCurve(
                    to: CGPoint(x: width, y: height * 0.70),
                    controlPoint1: CGPoint(x: width * 0.80, y: height * 0.52),
                    controlPoint2: CGPoint(x: width * 0.91, y: height * 0.69)
                )
            } else {
                path.addCurve(
                    to: CGPoint(x: width * 0.18, y: height * 0.42),
                    controlPoint1: CGPoint(x: width * 0.05, y: height * 0.67),
                    controlPoint2: CGPoint(x: width * 0.11, y: height * 0.43)
                )
                path.addCurve(
                    to: CGPoint(x: width * 0.36, y: height * 0.64),
                    controlPoint1: CGPoint(x: width * 0.24, y: height * 0.30),
                    controlPoint2: CGPoint(x: width * 0.31, y: height * 0.62)
                )
                path.addCurve(
                    to: CGPoint(x: width * 0.56, y: height * 0.36),
                    controlPoint1: CGPoint(x: width * 0.43, y: height * 0.66),
                    controlPoint2: CGPoint(x: width * 0.49, y: height * 0.38)
                )
                path.addCurve(
                    to: CGPoint(x: width * 0.76, y: height * 0.58),
                    controlPoint1: CGPoint(x: width * 0.63, y: height * 0.27),
                    controlPoint2: CGPoint(x: width * 0.69, y: height * 0.57)
                )
                path.addCurve(
                    to: CGPoint(x: width, y: height * 0.70),
                    controlPoint1: CGPoint(x: width * 0.84, y: height * 0.60),
                    controlPoint2: CGPoint(x: width * 0.93, y: height * 0.69)
                )
            }

            path.addLine(to: CGPoint(x: width, y: height))
            path.close()
            colour.setFill()
            path.fill()
        }

        let texture = SKTexture(image: image)
        for number in 0...1 {
            let hills = SKSpriteNode(texture: texture)
            hills.name = name
            hills.size = CGSize(width: width, height: height)
            hills.anchorPoint = CGPoint(x: 0, y: 0)
            hills.position = CGPoint(
                x: frame.minX + CGFloat(number) * (width - 2),
                y: frame.minY
            )
            hills.zPosition = zPosition
            addChild(hills)

            if rearLayer {
                rearDistantHillNodes.append(hills)
            } else {
                distantHillNodes.append(hills)
            }
        }
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

        scrollSkyClouds(
            by: movementDistance * 0.05
        )

        scrollBackgroundNodes(
            rearDistantHillNodes,
            by: movementDistance * 0.12
        )

        scrollBackgroundNodes(
            distantHillNodes,
            by: movementDistance * 0.25
        )

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

    private func scrollSkyClouds(
        by distance: CGFloat
    ) {

        for cloud in skyCloudNodes {
            cloud.position.x -= distance
        }

        for cloud in skyCloudNodes {
            if cloud.position.x + cloud.frame.width / 2 <= frame.minX {
                let rightmostCloudX = skyCloudNodes
                    .filter { $0 !== cloud }
                    .map { $0.position.x }
                    .max() ?? frame.maxX

                cloud.position.x =
                    rightmostCloudX + frame.width * 0.83
            }
        }
    }

    private func scrollBackgroundNodes(
        _ nodes: [SKSpriteNode],
        by distance: CGFloat
    ) {

        for node in nodes {
            node.position.x -= distance
        }

        for node in nodes {
            if node.position.x + node.size.width <= frame.minX {
                let rightmostEdge = nodes
                    .filter { $0 !== node }
                    .map { $0.position.x + $0.size.width }
                    .max() ?? frame.maxX

                node.position.x = rightmostEdge - 2
            }
        }
    }

    /*
     Keep Ploppy inside the top of the visible screen.

     This is not lethal. If Ploppy reaches the limit,
     only his upward movement is stopped.
    */

    override func didSimulatePhysics() {

        guard !isGameOver else {
            return
        }

        guard ploppy.parent != nil else {
            return
        }

        let maximumPloppyY =
            frame.maxY -
            ploppy.size.height / 2

        if ploppy.position.y > maximumPloppyY {

            ploppy.position.y =
                maximumPloppyY

            if let physicsBody =
                ploppy.physicsBody,
               physicsBody.velocity.dy > 0 {

                physicsBody.velocity = CGVector(
                    dx: physicsBody.velocity.dx,
                    dy: 0
                )
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
        hillNode.shader = hillShadingShader

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

