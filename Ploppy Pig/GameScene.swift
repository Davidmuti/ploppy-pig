


import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum AppleCoreLane {
        case low
        case middle
        case high
    }

    private let ploppy = SKSpriteNode(imageNamed: "ploppy")

    private let grassTexture = SKTexture(imageNamed: "grassStrip")
    private let appleCoreTexture = SKTexture(imageNamed: "appleCore")

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
    private var groundFillNode: SKSpriteNode?
    private var skyCloudNodes: [SKShapeNode] = []
    private var rearDistantHillNodes: [SKSpriteNode] = []
    private var distantHillNodes: [SKSpriteNode] = []

    private var scrollSpeed: CGFloat = 0
    private var previousUpdateTime: TimeInterval = 0
    private var terrainRiseTestElapsedTime: TimeInterval = 0
    private var terrainRiseOffset: CGFloat = 0
    private var terrainRiseTargetOffset: CGFloat = 0
    private var hasTriggeredTerrainRiseTest = false
    private var isWitchEncounterActive = false

    private var isGameOver = false
    private var pendingBlondieFlightHeights: [CGFloat] = []

    private let ploppyCategory: UInt32 = 1 << 0
    private let terrainCategory: UInt32 = 1 << 1
    private let foodCategory: UInt32 = 1 << 2

    private let blondieAppearanceHillNumbers:
        Set<Int> = [19]
    private let blondieSpeedMultiplier: CGFloat = 1.25
    private let blondieWidthFraction: CGFloat = 0.14
    private let blondieClearanceWait: TimeInterval = 2.1
    private let blondiePassWait: TimeInterval = 1.5
    private let witchWarningDuration: TimeInterval = 0.75
    private let witchNightFadeDuration: TimeInterval = 2.1
    private let witchWarningHeightFraction: CGFloat = 0.18
    private let witchWarningRightMarginFraction: CGFloat = 0.02

    private let grassSinkBelowScreen: CGFloat = 16
    private let hillSinkBelowScreenFraction: CGFloat = 0.21
    private let grassOverlap: CGFloat = 4
    private let grassGroundOverlapFraction: CGFloat = 0.40
    private let appleCoreHeightFractionOfPloppy: CGFloat = 1.50
    private let maximumAppleCoresOnScreen = 2
    private let appleCoreSpawnDelayAfterHill: TimeInterval = 0.8

    private let plannedAppleCoreLanes:
        [Int: AppleCoreLane] = [
            1: .low,
            3: .middle,
            8: .middle,
            10: .low,
            13: .high,
            21: .low,
            26: .high,
            28: .middle,
            32: .low,
            37: .middle,
            39: .low
        ]
    private let terrainRiseTestDelay: TimeInterval = 3.0
    private let terrainRiseMaximumFraction: CGFloat = 0.12
    private let terrainRiseSpeedFractionPerSecond: CGFloat = 0.008
    private let maximumHillTopFraction: CGFloat = 0.72
    private let minimumDoubleWitchCorridorFraction: CGFloat = 0.22

    private let hillStartingTopFractions:
        [String: CGFloat] = [
            "hill1": 0.2378,
            "hill2": 0.2378,
            "hill3": 0.6400,
            "hill4": 0.6400,
            "hill5": 0.3598,
            "hill6": 0.4683,
            "hill7": 0.6400,
            "hill8": 0.6400,
            "hill9": 0.3895,
            "hill10": 0.3693,
            "hill11": 0.3693,
            "hill12": 0.6193
        ]

    private lazy var hillShadingShader: SKShader = {

        let shaderSource = """
        void main() {
            vec4 originalColour = texture2D(
                u_texture,
                v_tex_coord
            );

            if (originalColour.a < 0.001) {
                discard;
            }

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

            float originalBrightness = dot(
                originalColour.rgb,
                vec3(0.299, 0.587, 0.114)
            );

            vec3 barrenTint = vec3(
                0.44,
                0.41,
                0.37
            );

            vec3 barrenColour =
                barrenTint *
                mix(
                    0.58,
                    1.08,
                    originalBrightness
                );

            vec3 shadedColour =
                barrenColour *
                combinedLight *
                originalColour.a;

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
        groundFillNode = nil
        skyCloudNodes.removeAll()
        rearDistantHillNodes.removeAll()
        distantHillNodes.removeAll()
        hillPhysicsBodyTemplates.removeAll()

        isGameOver = false
        previousUpdateTime = 0
        terrainRiseTestElapsedTime = 0
        terrainRiseOffset = 0
        terrainRiseTargetOffset = 0
        hasTriggeredTerrainRiseTest = false
        isWitchEncounterActive = false
        pendingBlondieFlightHeights.removeAll()

        backgroundColor = .clear
        createSkyGradient()
        createSparseSkyClouds()
        createDistantHillLayers()

        physicsWorld.gravity = CGVector(
            dx: 0,
            dy: -3.616160625
        )

        physicsWorld.contactDelegate = self

        prepareTerrain()
        createGroundFill()
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
            colour: UIColor(red: 0.30, green: 0.30, blue: 0.29, alpha: 0.32),
            zPosition: -97,
            rearLayer: true
        )

        createDistantHillLayer(
            name: "distantHills",
            height: frame.height * 0.34,
            colour: UIColor(red: 0.42, green: 0.40, blue: 0.37, alpha: 1.0),
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

    private func createGroundFill() {

        let groundFill = SKSpriteNode(
            color: UIColor(
                red: 0.34,
                green: 0.32,
                blue: 0.29,
                alpha: 1
            ),
            size: CGSize(
                width: frame.width + 8,
                height:
                    groundFillHeight(
                        for:
                            terrainRiseOffset
                    )
            )
        )

        groundFill.name = "groundFill"
        groundFill.anchorPoint = CGPoint(
            x: 0.5,
            y: 0
        )
        groundFill.position = CGPoint(
            x: frame.midX,
            y: frame.minY
        )
        groundFill.zPosition = 0

        addChild(groundFill)
        groundFillNode = groundFill
    }

    private func groundFillHeight(
        for riseOffset: CGFloat
    ) -> CGFloat {

        let grassBottomY =
            frame.minY -
            grassSinkBelowScreen +
            riseOffset

        let visibleGrassBaseY =
            grassBottomY +
            grassSize.height *
            grassGroundOverlapFraction

        return max(
            1,
            visibleGrassBaseY -
                frame.minY
        )
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
            grassNode.shader = hillShadingShader

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

        updateTerrainRiseTest(
            by: timeSinceLastUpdate
        )

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

    private func updateTerrainRiseTest(
        by elapsedTime: TimeInterval
    ) {

        terrainRiseTestElapsedTime +=
            elapsedTime

        if !hasTriggeredTerrainRiseTest,
           terrainRiseTestElapsedTime >=
            terrainRiseTestDelay {

            hasTriggeredTerrainRiseTest = true

            terrainRiseTargetOffset =
                maximumSafeTerrainRise()
        }

        guard !isWitchEncounterActive else {
            return
        }

        guard terrainRiseOffset <
            terrainRiseTargetOffset else {
            return
        }

        let riseThisFrame =
            frame.height *
            terrainRiseSpeedFractionPerSecond *
            CGFloat(elapsedTime)

        terrainRiseOffset =
            min(
                terrainRiseTargetOffset,
                terrainRiseOffset +
                    riseThisFrame
            )

        applyCurrentTerrainRise()
    }

    private func maximumSafeTerrainRise()
        -> CGFloat {

        let requestedMaximumRise =
            frame.height *
            terrainRiseMaximumFraction

        let blondieHeight =
            currentBlondieHeight()

        let doubleWitchMargin =
            frame.height * 0.02

        let grassTopAtBaseLevel =
            frame.minY -
            grassSinkBelowScreen +
            grassSize.height

        let topWitchBottomEdge =
            frame.maxY -
            doubleWitchMargin -
            blondieHeight

        let bottomWitchTopEdgeAtBaseLevel =
            grassTopAtBaseLevel +
            doubleWitchMargin +
            blondieHeight

        let baseDoubleWitchCorridor =
            topWitchBottomEdge -
            bottomWitchTopEdgeAtBaseLevel

        let minimumSafeCorridor =
            frame.height *
            minimumDoubleWitchCorridorFraction

        let riseAllowedByWitches =
            max(
                0,
                baseDoubleWitchCorridor -
                    minimumSafeCorridor
            )

        return min(
            requestedMaximumRise,
            riseAllowedByWitches
        )
    }

    private func applyCurrentTerrainRise() {

        let raisedGrassY =
            frame.minY -
            grassSinkBelowScreen +
            terrainRiseOffset

        for grassNode in grassNodes {
            grassNode.position.y =
                raisedGrassY
        }

        groundFillNode?.size.height =
            groundFillHeight(
                for:
                    terrainRiseOffset
            )

        enumerateChildNodes(
            withName: "hill"
        ) { hillNode, _ in

            guard let baseYNumber =
                hillNode.userData?[
                    "terrainBaseY"
                ] as? NSNumber,
                  let maximumRiseNumber =
                hillNode.userData?[
                    "maximumTerrainRise"
                ] as? NSNumber else {
                return
            }

            let baseY =
                CGFloat(
                    baseYNumber.doubleValue
                )

            let maximumRise =
                CGFloat(
                    maximumRiseNumber
                        .doubleValue
                )

            hillNode.position.y =
                baseY +
                min(
                    self.terrainRiseOffset,
                    maximumRise
                )
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

        ploppy.setScale(1)

        let ploppyAspectRatio =
            ploppy.size.width /
            ploppy.size.height

        let ploppyHeight =
            frame.height * 0.10

        ploppy.size = CGSize(
            width:
                ploppyHeight *
                ploppyAspectRatio,
            height:
                ploppyHeight
        )

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
            terrainCategory |
            foodCategory

        addChild(ploppy)
    }

    private func createAppleCoreIfSafe(
        in lane: AppleCoreLane
    ) {

        guard !isGameOver else {
            return
        }

        guard !isWitchEncounterActive else {
            return
        }

        var currentAppleCoreCount = 0

        enumerateChildNodes(
            withName: "appleCore"
        ) { _, _ in

            currentAppleCoreCount += 1
        }

        guard currentAppleCoreCount <
            maximumAppleCoresOnScreen else {
            return
        }

        let appleCore = SKSpriteNode(
            texture: appleCoreTexture
        )

        appleCore.name = "appleCore"

        let appleCoreHeight =
            ploppy.size.height *
            appleCoreHeightFractionOfPloppy

        let appleCoreAspectRatio =
            appleCoreTexture.size().width /
            appleCoreTexture.size().height

        appleCore.size = CGSize(
            width:
                appleCoreHeight *
                appleCoreAspectRatio,
            height:
                appleCoreHeight
        )

        let safeMargin =
            frame.height * 0.02

        let currentGrassTop =
            frame.minY -
            grassSinkBelowScreen +
            terrainRiseOffset +
            grassSize.height

        let minimumSafeY =
            currentGrassTop +
            appleCore.size.height / 2 +
            safeMargin

        let maximumSafeY =
            frame.maxY -
            appleCore.size.height / 2 -
            safeMargin

        guard minimumSafeY <
            maximumSafeY else {
            return
        }

        let availableHeight =
            maximumSafeY -
            minimumSafeY

        let appleCoreY: CGFloat

        switch lane {

        case .low:
            appleCoreY =
                minimumSafeY

        case .middle:
            appleCoreY =
                minimumSafeY +
                availableHeight * 0.45

        case .high:
            appleCoreY =
                minimumSafeY +
                availableHeight * 0.82
        }

        appleCore.position = CGPoint(
            x: frame.maxX +
                appleCore.size.width / 2,
            y: appleCoreY
        )

        appleCore.zPosition = 8

        let physicsBody = SKPhysicsBody(
            texture: appleCoreTexture,
            size: appleCore.size
        )

        physicsBody.isDynamic = false
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask =
            foodCategory
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask =
            ploppyCategory

        appleCore.physicsBody = physicsBody

        addChild(appleCore)

        let finalX =
            frame.minX -
            appleCore.size.width / 2

        let travelDistance =
            frame.width +
            appleCore.size.width

        let travelDuration =
            TimeInterval(
                travelDistance /
                scrollSpeed
            )

        let moveAppleCore =
            SKAction.moveTo(
                x: finalX,
                duration: travelDuration
            )

        moveAppleCore.timingMode = .linear

        appleCore.run(
            SKAction.sequence([
                moveAppleCore,
                SKAction.removeFromParent()
            ])
        )
    }

    private func startCountrysideLoop() {

        var countrysideActions: [SKAction] = []

        let numberOfWitches =
            Int.random(in: 5...7)

        let doubleWitchEventNumbers =
            Set(
                (0..<numberOfWitches)
                    .shuffled()
                    .prefix(2)
            )

        for hillNumber in 0..<hillSequence.count {

            let hillName =
                hillSequence[hillNumber]

            let hillInterval =
                hillIntervals[hillNumber]

            if blondieAppearanceHillNumbers
                .contains(hillNumber) {

                let beginWitchNight =
                    SKAction.run { [weak self] in

                        guard let self = self else {
                            return
                        }

                        guard !self.isGameOver else {
                            return
                        }

                        self.transitionToWitchNight()
                    }

                let waitForClearGrass =
                    SKAction.wait(
                        forDuration:
                            blondieClearanceWait
                    )

                countrysideActions.append(
                    beginWitchNight
                )

                countrysideActions.append(
                    waitForClearGrass
                )

                let warningDurations =
                    Array(
                        repeating:
                            witchWarningDuration,
                        count:
                            numberOfWitches
                    )

                for (
                    witchNumber,
                    warningDuration
                ) in warningDurations.enumerated() {

                    let isDoubleWitchEvent =
                        doubleWitchEventNumbers
                            .contains(witchNumber)

                    let createWitchWarning =
                        SKAction.run { [weak self] in

                            guard let self = self else {
                                return
                            }

                            guard !self.isGameOver else {
                                return
                            }

                            self.prepareNextWitchWarning(
                                duration: warningDuration,
                                isDoubleWitchEvent:
                                    isDoubleWitchEvent
                            )
                        }

                    let waitForWitchWarning =
                        SKAction.wait(
                            forDuration:
                                warningDuration
                        )

                    let createBlondie =
                        SKAction.run { [weak self] in

                            guard let self = self else {
                                return
                            }

                            guard !self.isGameOver else {
                                return
                            }

                            self.createAndScrollBlondies()
                        }

                    let isFinalWitch =
                        witchNumber ==
                        warningDurations.count - 1

                    let timeBeforeNextWarning =
                        isFinalWitch
                        ? blondiePassWait
                        : blondieTimeToReachPloppyNose()

                    let waitAfterBlondieEnters =
                        SKAction.wait(
                            forDuration:
                                timeBeforeNextWarning
                        )

                    countrysideActions.append(
                        createWitchWarning
                    )

                    countrysideActions.append(
                        waitForWitchWarning
                    )

                    countrysideActions.append(
                        createBlondie
                    )

                    countrysideActions.append(
                        waitAfterBlondieEnters
                    )
                }

                let endWitchNight =
                    SKAction.run { [weak self] in

                        guard let self = self else {
                            return
                        }

                        guard !self.isGameOver else {
                            return
                        }

                        self.transitionBackToDaylight()
                    }

                countrysideActions.append(
                    endWitchNight
                )
            }

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

            countrysideActions.append(
                createHill
            )

            if let appleCoreLane =
                plannedAppleCoreLanes[
                    hillNumber
                ],
               hillInterval >
                appleCoreSpawnDelayAfterHill {

                let waitBeforeAppleCore =
                    SKAction.wait(
                        forDuration:
                            appleCoreSpawnDelayAfterHill
                    )

                let createPlannedAppleCore =
                    SKAction.run { [weak self] in

                        guard let self = self else {
                            return
                        }

                        self.createAppleCoreIfSafe(
                            in: appleCoreLane
                        )
                    }

                let waitAfterAppleCore =
                    SKAction.wait(
                        forDuration:
                            hillInterval -
                            appleCoreSpawnDelayAfterHill
                    )

                countrysideActions.append(
                    waitBeforeAppleCore
                )

                countrysideActions.append(
                    createPlannedAppleCore
                )

                countrysideActions.append(
                    waitAfterAppleCore
                )
            } else {

                let waitForNextHill =
                    SKAction.wait(
                        forDuration:
                            hillInterval
                    )

                countrysideActions.append(
                    waitForNextHill
                )
            }
        }

        let startNextCountrysideCycle =
            SKAction.run { [weak self] in

                guard let self = self else {
                    return
                }

                guard !self.isGameOver else {
                    return
                }

                self.startCountrysideLoop()
            }

        countrysideActions.append(
            startNextCountrysideCycle
        )

        run(
            SKAction.sequence(
                countrysideActions
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

        let hillBaseY =
            frame.minY +
            hillNode.size.height / 2 -
            hillSinkDistance

        let startingTopFraction =
            hillStartingTopFractions[
                hillName
            ] ?? maximumHillTopFraction

        let startingTopY =
            frame.minY +
            frame.height *
            startingTopFraction

        let maximumTopY =
            frame.minY +
            frame.height *
            maximumHillTopFraction

        let maximumRiseForThisHill =
            max(
                0,
                maximumTopY -
                    startingTopY
            )

        let appliedRise =
            min(
                terrainRiseOffset,
                maximumRiseForThisHill
            )

        hillNode.position = CGPoint(
            x: frame.maxX +
                hillNode.size.width / 2,
            y: hillBaseY +
                appliedRise
        )

        hillNode.userData =
            NSMutableDictionary()

        hillNode.userData?[
            "terrainBaseY"
        ] = NSNumber(
            value: Double(hillBaseY)
        )

        hillNode.userData?[
            "maximumTerrainRise"
        ] = NSNumber(
            value:
                Double(
                    maximumRiseForThisHill
                )
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

    private func transitionToWitchNight() {

        isWitchEncounterActive = true

        enumerateChildNodes(
            withName: "appleCore"
        ) { appleCore, _ in

            appleCore.removeAllActions()
            appleCore.removeFromParent()
        }

        childNode(
            withName: "witchNightSky"
        )?.removeFromParent()

        childNode(
            withName: "witchMoon"
        )?.removeFromParent()

        let nightColour = UIColor(
            red: 0.025,
            green: 0.045,
            blue: 0.12,
            alpha: 1
        )

        let nightSky = SKSpriteNode(
            color: nightColour,
            size: frame.size
        )

        nightSky.name = "witchNightSky"
        nightSky.position = CGPoint(
            x: frame.midX,
            y: frame.midY
        )
        nightSky.alpha = 0
        nightSky.zPosition = -99.5
        addChild(nightSky)

        nightSky.run(
            SKAction.fadeIn(
                withDuration:
                    witchNightFadeDuration
            )
        )

        createWitchMoon()

        for cloud in skyCloudNodes {

            let changeToNightCloud =
                SKAction.run {

                    cloud.fillColor = UIColor(
                        red: 0.20,
                        green: 0.22,
                        blue: 0.27,
                        alpha: 0.58
                    )
                }

            cloud.run(
                SKAction.sequence([
                    SKAction.fadeOut(
                        withDuration: 0.55
                    ),
                    changeToNightCloud,
                    SKAction.fadeIn(
                        withDuration: 0.75
                    )
                ])
            )
        }
    }

    private func createWitchMoon() {

        let moon = SKNode()
        moon.name = "witchMoon"
        moon.position = CGPoint(
            x: frame.minX +
                frame.width * 0.20,
            y: frame.minY +
                frame.height * 0.80
        )
        moon.alpha = 0
        moon.zPosition = -98.5

        let moonRadius =
            frame.height * 0.075

        let crescentPath = CGMutablePath()

        crescentPath.move(
            to: CGPoint(
                x: 0,
                y: moonRadius
            )
        )

        crescentPath.addArc(
            center: .zero,
            radius: moonRadius,
            startAngle: .pi / 2,
            endAngle: .pi * 1.5,
            clockwise: false
        )

        crescentPath.addCurve(
            to: CGPoint(
                x: 0,
                y: moonRadius
            ),
            control1: CGPoint(
                x: -moonRadius * 0.48,
                y: -moonRadius * 0.48
            ),
            control2: CGPoint(
                x: -moonRadius * 0.48,
                y: moonRadius * 0.48
            )
        )

        crescentPath.closeSubpath()

        let moonCrescent = SKShapeNode(
            path: crescentPath
        )

        moonCrescent.fillColor = UIColor(
            red: 0.82,
            green: 0.86,
            blue: 0.90,
            alpha: 1
        )
        moonCrescent.strokeColor = .clear
        moon.addChild(moonCrescent)

        addChild(moon)

        moon.run(
            SKAction.fadeIn(
                withDuration:
                    witchNightFadeDuration
            )
        )
    }

    private func transitionBackToDaylight() {

        isWitchEncounterActive = false

        if let nightSky = childNode(
            withName: "witchNightSky"
        ) {

            nightSky.run(
                SKAction.sequence([
                    SKAction.fadeOut(
                        withDuration:
                            witchNightFadeDuration
                    ),
                    SKAction.removeFromParent()
                ])
            )
        }

        if let moon = childNode(
            withName: "witchMoon"
        ) {

            moon.run(
                SKAction.sequence([
                    SKAction.fadeOut(
                        withDuration:
                            witchNightFadeDuration
                    ),
                    SKAction.removeFromParent()
                ])
            )
        }

        for cloud in skyCloudNodes {

            let changeToDayCloud =
                SKAction.run {

                    cloud.fillColor = UIColor(
                        red: 0.94,
                        green: 0.97,
                        blue: 1.0,
                        alpha: 0.15
                    )
                }

            cloud.run(
                SKAction.sequence([
                    SKAction.fadeOut(
                        withDuration: 0.55
                    ),
                    changeToDayCloud,
                    SKAction.fadeIn(
                        withDuration: 0.75
                    )
                ])
            )
        }
    }

    private func prepareNextWitchWarning(
        duration: TimeInterval,
        isDoubleWitchEvent: Bool
    ) {

        let flightHeights: [CGFloat]

        if isDoubleWitchEvent,
           canSafelyCreateDoubleWitchEvent() {

            let safeHeightRange =
                blondieFlightHeightRange(
                    safetyMarginFraction:
                        0.02
                )

            flightHeights = [
                safeHeightRange.upperBound,
                safeHeightRange.lowerBound
            ]
        } else {

            flightHeights = [
                randomBlondieFlightHeight()
            ]
        }

        pendingBlondieFlightHeights =
            flightHeights

        for flightHeight in flightHeights {

            createFlashingWitchWarning(
                at: flightHeight,
                duration: duration
            )
        }
    }

    private func randomBlondieFlightHeight()
        -> CGFloat {

        let safeHeightRange =
            blondieFlightHeightRange()

        return CGFloat.random(
            in: safeHeightRange
        )
    }

    private func blondieFlightHeightRange(
        safetyMarginFraction: CGFloat = 0.06
    )
        -> ClosedRange<CGFloat> {

        let blondieHeight =
            currentBlondieHeight()

        let grassTop =
            frame.minY -
            grassSinkBelowScreen +
            grassSize.height +
            terrainRiseOffset

        let safetyMargin =
            frame.height *
            safetyMarginFraction

        let minimumHeight =
            grassTop +
            blondieHeight / 2 +
            safetyMargin

        let maximumHeight =
            frame.maxY -
            blondieHeight / 2 -
            safetyMargin

        guard minimumHeight < maximumHeight else {
            return frame.midY...frame.midY
        }

        return minimumHeight...maximumHeight
    }

    private func currentBlondieHeight()
        -> CGFloat {

        let blondieTexture = SKTexture(
            imageNamed: "blondieWitch"
        )

        let blondieWidth =
            frame.width *
            blondieWidthFraction

        let blondieAspectRatio =
            blondieTexture.size().width /
            blondieTexture.size().height

        return
            blondieWidth /
            blondieAspectRatio
    }

    private func canSafelyCreateDoubleWitchEvent()
        -> Bool {

        let safeHeightRange =
            blondieFlightHeightRange(
                safetyMarginFraction:
                    0.02
            )

        let corridorHeight =
            safeHeightRange.upperBound -
            safeHeightRange.lowerBound -
            currentBlondieHeight()

        let minimumSafeCorridor =
            frame.height *
            minimumDoubleWitchCorridorFraction

        return corridorHeight >=
            minimumSafeCorridor
    }

    private func blondieTimeToReachPloppyNose()
        -> TimeInterval {

        let blondieWidth =
            frame.width *
            blondieWidthFraction

        let blondieStartingX =
            frame.maxX +
            blondieWidth / 2

        let ploppyNoseX =
            ploppy.frame.maxX

        let distanceToPloppyNose =
            max(
                0,
                blondieStartingX -
                ploppyNoseX
            )

        let blondieSpeed =
            scrollSpeed *
            blondieSpeedMultiplier

        guard blondieSpeed > 0 else {
            return blondiePassWait
        }

        return TimeInterval(
            distanceToPloppyNose /
            blondieSpeed
        )
    }

    private func createAndScrollBlondies() {

        guard !pendingBlondieFlightHeights
            .isEmpty else {
            return
        }

        let flightHeights =
            pendingBlondieFlightHeights

        pendingBlondieFlightHeights
            .removeAll()

        for flightHeight in flightHeights {

            createAndScrollBlondie(
                at: flightHeight
            )
        }
    }

    private func createAndScrollBlondie(
        at flightHeight: CGFloat
    ) {

        let blondieTexture = SKTexture(
            imageNamed: "blondieWitch"
        )

        let blondie = SKSpriteNode(
            texture: blondieTexture
        )

        blondie.name = "blondieWitch"

        let blondieWidth =
            frame.width *
            blondieWidthFraction

        let textureAspectRatio =
            blondieTexture.size().width /
            blondieTexture.size().height

        blondie.size = CGSize(
            width: blondieWidth,
            height: blondieWidth /
                textureAspectRatio
        )

        blondie.position = CGPoint(
            x: frame.maxX +
                blondie.size.width / 2,
            y: flightHeight
        )

        blondie.zPosition = 9

        let physicsBody = SKPhysicsBody(
            texture: blondieTexture,
            size: blondie.size
        )

        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.allowsRotation = false
        physicsBody.usesPreciseCollisionDetection = true

        physicsBody.categoryBitMask =
            terrainCategory

        physicsBody.collisionBitMask =
            ploppyCategory

        physicsBody.contactTestBitMask =
            ploppyCategory

        blondie.physicsBody = physicsBody

        addChild(blondie)

        let finalX =
            frame.minX -
            blondie.size.width / 2

        let travelDistance =
            frame.width +
            blondie.size.width

        let blondieSpeed =
            scrollSpeed *
            blondieSpeedMultiplier

        let travelDuration =
            TimeInterval(
                travelDistance /
                blondieSpeed
            )

        let moveBlondie =
            SKAction.moveTo(
                x: finalX,
                duration: travelDuration
            )

        moveBlondie.timingMode = .linear

        blondie.run(
            SKAction.sequence([
                moveBlondie,
                SKAction.removeFromParent()
            ])
        )
    }

    private func createFlashingWitchWarning(
        at flightHeight: CGFloat,
        duration: TimeInterval
    ) {

        let warningTexture = SKTexture(
            imageNamed: "witchWarning"
        )

        let warning = SKSpriteNode(
            texture: warningTexture
        )

        warning.name = "witchWarning"

        let warningHeight =
            frame.height *
            witchWarningHeightFraction

        let warningAspectRatio =
            warningTexture.size().width /
            warningTexture.size().height

        warning.size = CGSize(
            width: warningHeight *
                warningAspectRatio,
            height: warningHeight
        )

        let rightMargin =
            frame.width *
            witchWarningRightMarginFraction

        warning.position = CGPoint(
            x: frame.maxX -
                rightMargin -
                warning.size.width / 2,
            y: flightHeight
        )

        warning.zPosition = 30

        addChild(warning)

        let flashCount = 3

        let halfFlashDuration =
            duration /
            TimeInterval(flashCount * 2)

        let fadeOut = SKAction.fadeOut(
            withDuration:
                halfFlashDuration
        )

        let fadeIn = SKAction.fadeIn(
            withDuration:
                halfFlashDuration
        )

        let singleFlash = SKAction.sequence([
            fadeOut,
            fadeIn
        ])

        warning.run(
            SKAction.sequence([
                SKAction.repeat(
                    singleFlash,
                    count: flashCount
                ),
                SKAction.removeFromParent()
            ])
        )
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        guard let touch = touches.first else {
            return
        }

        let touchPosition =
            touch.location(in: self)

        if touchPosition.x < frame.midX {
            performFart()
        } else if touchPosition.y >=
            frame.midY {
            performUpperRightPooAction()
        } else {
            performLowerRightPooAction()
        }
    }

    func handleFartInput() {
        performFart()
    }

    func handleUpperRightPooInput() {
        performUpperRightPooAction()
    }

    func handleLowerRightPooInput() {
        performLowerRightPooAction()
    }

    private func performFart() {

        guard !isGameOver else {
            return
        }

        if let physicsBody = ploppy.physicsBody {

            if physicsBody.velocity.dy < 0 {

                physicsBody.velocity = CGVector(
                    dx: physicsBody.velocity.dx,
                    dy: 0
                )
            }

            physicsBody.applyImpulse(
                CGVector(
                    dx: 0,
                    dy: 232.836733903935
                )
            )

            if physicsBody.velocity.dy > 331.2 {

                physicsBody.velocity = CGVector(
                    dx: physicsBody.velocity.dx,
                    dy: 331.2
                )
            }
        }

        createCloudTrail()
    }

    private func performUpperRightPooAction() {

        guard !isGameOver else {
            return
        }

        // The first poo colour will be added later.
    }

    private func performLowerRightPooAction() {

        guard !isGameOver else {
            return
        }

        // The second poo colour will be added later.
    }

    func didBegin(
        _ contact: SKPhysicsContact
    ) {

        let contactedCategories =
            contact.bodyA.categoryBitMask |
            contact.bodyB.categoryBitMask

        let foodContactCategories =
            ploppyCategory |
            foodCategory

        if contactedCategories ==
            foodContactCategories {

            let foodBody =
                contact.bodyA.categoryBitMask ==
                    foodCategory
                ? contact.bodyA
                : contact.bodyB

            foodBody.node?.removeAllActions()
            foodBody.node?.removeFromParent()
            return
        }

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

        enumerateChildNodes(
            withName: "blondieWitch"
        ) { blondieNode, _ in

            blondieNode.removeAllActions()
            blondieNode.physicsBody = nil
        }

        enumerateChildNodes(
            withName: "witchWarning"
        ) { warningNode, _ in

            warningNode.removeAllActions()
            warningNode.removeFromParent()
        }

        enumerateChildNodes(
            withName: "appleCore"
        ) { appleCore, _ in

            appleCore.removeAllActions()
            appleCore.physicsBody = nil
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

