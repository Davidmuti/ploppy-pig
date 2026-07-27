


import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum AppleCoreLane {
        case low
        case middle
        case high
    }

    private enum FoodKind: String {
        case apple
        case cucumber
        case corn
    }

    private struct TerrainLoweringEffect {
        var amountRemaining: CGFloat
        var timeRemaining: TimeInterval
    }

    private final class RestorationPatchState {
        weak var terrainNode: SKSpriteNode?
        let localPosition: CGPoint
        var level: Int
        let cropNode: SKCropNode
        let gradientNode: SKSpriteNode

        init(
            terrainNode: SKSpriteNode,
            localPosition: CGPoint,
            cropNode: SKCropNode,
            gradientNode: SKSpriteNode
        ) {
            self.terrainNode = terrainNode
            self.localPosition = localPosition
            self.level = 1
            self.cropNode = cropNode
            self.gradientNode = gradientNode
        }
    }

    private let ploppy = SKSpriteNode(imageNamed: "ploppy")

    private let grassTexture = SKTexture(imageNamed: "grassStrip")
    private let appleCoreTexture = SKTexture(imageNamed: "appleCore")
    private let halfEatenCucumberTexture =
        SKTexture(imageNamed: "halfEatenCucumber")
    private let eatenCornCobTexture =
        SKTexture(imageNamed: "eatenCornCob")
    private let appleSeedTexture =
        SKTexture(imageNamed: "appleSeed")
    private let cucumberSeedTexture =
        SKTexture(imageNamed: "cucumberSeed")
    private let cornSeedTexture =
        SKTexture(imageNamed: "cornSeed")

    private let corruptedSkyTopColour =
        UIColor(
            red: 0.38,
            green: 0.40,
            blue: 0.42,
            alpha: 1
        )

    private let corruptedSkyHorizonColour =
        UIColor(
            red: 0.68,
            green: 0.69,
            blue: 0.70,
            alpha: 1
        )

    private let healthySkyTopColour =
        UIColor(
            red: 0.30,
            green: 0.65,
            blue: 0.88,
            alpha: 1
        )

    private let healthySkyHorizonColour =
        UIColor(
            red: 0.73,
            green: 0.88,
            blue: 0.96,
            alpha: 1
        )

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
    private var terrainRiseBeforeLake: CGFloat = 0
    private var isPloppySkiddingOnLake = false
    private var lakeWakeElapsedTime: TimeInterval = 0
    private var terrainLoweringEffects:
        [TerrainLoweringEffect] = []
    private var restorationPatches:
        [RestorationPatchState] = []

    private var isGameOver = false
    private var pendingBlondieFlightHeights: [CGFloat] = []
    private var stomachSlots:
        [FoodKind?] = [nil, nil]
    private var stomachSeedNodes:
        [SKSpriteNode?] = [nil, nil]

    private let ploppyCategory: UInt32 = 1 << 0
    private let terrainCategory: UInt32 = 1 << 1
    private let foodCategory: UInt32 = 1 << 2
    private let droppedSeedCategory: UInt32 = 1 << 3

    private let blondieAppearanceHillNumbers:
        Set<Int> = [19]
    private let blondieSpeedMultiplier: CGFloat = 1.25
    private let blondieWidthFraction: CGFloat = 0.14
    private let blondieClearanceWait: TimeInterval = 2.1
    private let blondiePassWait: TimeInterval = 1.5
    private let additionalWitchGap: TimeInterval = 0.35
    private let witchWarningDuration: TimeInterval = 0.75
    private let witchNightFadeDuration: TimeInterval = 2.1
    private let lakeBankTransitionDuration: TimeInterval = 2.1
    private let witchWarningHeightFraction: CGFloat = 0.18
    private let witchWarningRightMarginFraction: CGFloat = 0.02

    private let grassSinkBelowScreen: CGFloat = 16
    private let hillSinkBelowScreenFraction: CGFloat = 0.21
    private let grassOverlap: CGFloat = 4
    private let grassGroundOverlapFraction: CGFloat = 0.40
    private let appleCoreHeightFractionOfPloppy: CGFloat = 1.50
    private let cucumberHeightFractionOfPloppy: CGFloat = 0.70
    private let cornCobHeightFractionOfPloppy: CGFloat = 0.42
    private let droppedSeedLongDimensionFractionOfPloppy:
        CGFloat = 0.64
    private let maximumAppleCoresOnScreen = 3
    private let appleCoreSpawnDelayAfterHill: TimeInterval = 0.8

    private let plannedAppleCoreLanes:
        [Int: AppleCoreLane] = [
            1: .low,
            3: .middle,
            4: .high,
            6: .middle,
            7: .low,
            8: .middle,
            10: .low,
            13: .high,
            14: .high,
            16: .middle,
            18: .high,
            21: .low,
            23: .middle,
            25: .high,
            26: .high,
            28: .middle,
            30: .low,
            32: .low,
            35: .middle,
            37: .middle,
            39: .low
        ]
    private let plannedCornCobLanes:
        [Int: AppleCoreLane] = [
            3: .high,
            10: .middle,
            15: .middle,
            20: .high,
            21: .middle,
            28: .high,
            31: .middle,
            32: .middle,
            33: .high,
            37: .high
        ]
    private let terrainRiseTestDelay: TimeInterval = 3.0
    private let terrainRiseMaximumFraction: CGFloat = 0.75
    private let terrainRiseSpeedFractionPerSecond: CGFloat = 0.012
    private let seedTerrainLoweringFraction: CGFloat = 0.016
    private let seedTerrainLoweringDuration:
        TimeInterval = 4.0 / 3.0
    private let restorationCentimetreFraction:
        CGFloat = 0.275
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
        terrainRiseBeforeLake = 0
        isPloppySkiddingOnLake = false
        lakeWakeElapsedTime = 0
        terrainLoweringEffects.removeAll()
        restorationPatches.removeAll()
        pendingBlondieFlightHeights.removeAll()
        stomachSlots = [nil, nil]
        stomachSeedNodes = [nil, nil]

        backgroundColor = .clear
        createSkyGradient()
        createSparseSkyClouds()
        createDistantHillLayers()

        physicsWorld.gravity = CGVector(
            dx: 0,
            dy: -3.9777766875
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
                corruptedSkyTopColour.cgColor,
                corruptedSkyHorizonColour.cgColor
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

        updateLakeSkid(
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

        if !terrainLoweringEffects.isEmpty {

            updateTerrainLowering(
                by: elapsedTime
            )

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

    private func updateTerrainLowering(
        by elapsedTime: TimeInterval
    ) {

        var totalLoweringThisFrame:
            CGFloat = 0

        for effectIndex in
            terrainLoweringEffects.indices {

            let effectTime =
                terrainLoweringEffects[
                    effectIndex
                ].timeRemaining

            guard effectTime > 0 else {
                continue
            }

            let timeUsed =
                min(
                    elapsedTime,
                    effectTime
                )

            let amountRemaining =
                terrainLoweringEffects[
                    effectIndex
                ].amountRemaining

            let amountThisFrame =
                amountRemaining *
                CGFloat(
                    timeUsed /
                    effectTime
                )

            totalLoweringThisFrame +=
                amountThisFrame

            terrainLoweringEffects[
                effectIndex
            ].amountRemaining =
                max(
                    0,
                    amountRemaining -
                        amountThisFrame
                )

            terrainLoweringEffects[
                effectIndex
            ].timeRemaining =
                max(
                    0,
                    effectTime -
                        timeUsed
                )
        }

        terrainLoweringEffects.removeAll {
            $0.timeRemaining <= 0
        }

        terrainRiseOffset =
            max(
                0,
                terrainRiseOffset -
                    totalLoweringThisFrame
            )

        applyCurrentTerrainRise()
    }

    private func beginSeedTerrainLowering() {

        guard !isWitchEncounterActive else {
            return
        }

        terrainLoweringEffects.append(
            TerrainLoweringEffect(
                amountRemaining:
                    frame.height *
                    seedTerrainLoweringFraction,
                timeRemaining:
                    seedTerrainLoweringDuration
            )
        )
    }

    private func maximumSafeTerrainRise()
        -> CGFloat {

        return frame.height *
            terrainRiseMaximumFraction
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

        ploppy.position.x =
            frame.minX + 180

        if let physicsBody =
            ploppy.physicsBody,
           physicsBody.velocity.dx != 0 {

            physicsBody.velocity =
                CGVector(
                    dx: 0,
                    dy:
                        physicsBody.velocity.dy
                )
        }

        removeFoodOverlappingTerrain()
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
        in lane: AppleCoreLane,
        horizontalOffset: CGFloat = 0,
        forcedFoodKind: FoodKind? = nil
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

        let foodKind: FoodKind

        if let forcedFoodKind =
            forcedFoodKind {

            foodKind =
                forcedFoodKind
        } else {

            foodKind =
                Bool.random()
                ? .cucumber
                : .apple
        }

        let foodTexture: SKTexture
        let foodHeightFraction:
            CGFloat

        switch foodKind {

        case .apple:
            foodTexture =
                appleCoreTexture
            foodHeightFraction =
                appleCoreHeightFractionOfPloppy

        case .cucumber:
            foodTexture =
                halfEatenCucumberTexture
            foodHeightFraction =
                cucumberHeightFractionOfPloppy

        case .corn:
            foodTexture =
                eatenCornCobTexture
            foodHeightFraction =
                cornCobHeightFractionOfPloppy
        }

        let appleCore = SKSpriteNode(
            texture: foodTexture
        )

        appleCore.name = "appleCore"
        appleCore.userData = NSMutableDictionary()
        appleCore.userData?["foodKind"] =
            foodKind.rawValue

        let appleCoreHeight =
            ploppy.size.height *
            foodHeightFraction

        let appleCoreAspectRatio =
            foodTexture.size().width /
            foodTexture.size().height

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
                appleCore.size.width / 2 +
                horizontalOffset,
            y: appleCoreY
        )

        guard !foodIntersectsTerrain(
            appleCore,
            safetyMargin:
                safeMargin
        ) else {
            return
        }

        appleCore.zPosition = 8

        let physicsBody = SKPhysicsBody(
            texture: foodTexture,
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
            appleCore.position.x -
            finalX

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

    private func foodIntersectsTerrain(
        _ foodNode: SKSpriteNode,
        safetyMargin: CGFloat
    ) -> Bool {

        let safetyFrame =
            foodNode.frame.insetBy(
                dx: -safetyMargin,
                dy: -safetyMargin
            )

        var intersectsTerrain =
            false

        physicsWorld.enumerateBodies(
            in: safetyFrame
        ) { physicsBody, stop in

            if physicsBody.categoryBitMask &
                self.terrainCategory != 0 {

                intersectsTerrain = true
                stop.pointee = true
            }
        }

        return intersectsTerrain
    }

    private func removeFoodOverlappingTerrain() {

        let safeMargin =
            frame.height * 0.02

        enumerateChildNodes(
            withName: "appleCore"
        ) { foodNode, _ in

            guard let foodSprite =
                foodNode as? SKSpriteNode else {
                return
            }

            if self.foodIntersectsTerrain(
                foodSprite,
                safetyMargin:
                    safeMargin
            ) {

                foodSprite.removeAllActions()
                foodSprite.removeFromParent()
            }
        }
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
                        : blondieTimeToReachPloppyNose() +
                            additionalWitchGap

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

                countrysideActions.append(
                    SKAction.wait(
                        forDuration:
                            lakeBankTransitionDuration
                    )
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

            let plannedAppleOrCucumberLane =
                plannedAppleCoreLanes[
                    hillNumber
                ]

            let plannedCornLane =
                plannedCornCobLanes[
                    hillNumber
                ]

            if plannedAppleOrCucumberLane != nil ||
                plannedCornLane != nil,
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

                        if let appleOrCucumberLane =
                            plannedAppleOrCucumberLane {

                            self.createAppleCoreIfSafe(
                                in:
                                    appleOrCucumberLane
                            )
                        }

                        if let cornLane =
                            plannedCornLane {

                            let cornHorizontalOffset:
                                CGFloat =
                                plannedAppleOrCucumberLane == nil
                                ? 0
                                : self.frame.width * 0.22

                            self.createAppleCoreIfSafe(
                                in: cornLane,
                                horizontalOffset:
                                    cornHorizontalOffset,
                                forcedFoodKind:
                                    .corn
                            )
                        }
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
        terrainRiseBeforeLake =
            terrainRiseOffset
        terrainRiseOffset = 0
        applyCurrentTerrainRise()
        createSmoothWitchLake()

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

        isPloppySkiddingOnLake = false
        lakeWakeElapsedTime = 0
        createLakeBank(
            descendingIntoLake: false
        )
        liftPloppyWithReturningBank()

        run(
            SKAction.sequence([
                SKAction.wait(
                    forDuration:
                        lakeBankTransitionDuration
                ),
                SKAction.run { [weak self] in

                    guard let self = self else {
                        return
                    }

                    guard !self.isGameOver else {
                        return
                    }

                    self.completeLakeExitTransition()
                }
            ]),
            withKey: "lakeExitTransition"
        )

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

    private func lakeSurfaceY()
        -> CGFloat {

        return frame.minY -
            grassSinkBelowScreen +
            grassSize.height
    }

    private func createSmoothWitchLake() {

        childNode(
            withName: "witchLake"
        )?.removeFromParent()

        for grassNode in grassNodes {
            grassNode.alpha = 0
            grassNode.physicsBody = nil
        }

        enumerateChildNodes(
            withName: "hill"
        ) { hillNode, _ in

            hillNode.physicsBody = nil
        }

        groundFillNode?.alpha = 0

        let surfaceY =
            lakeSurfaceY()

        let waterHeight =
            max(
                1,
                surfaceY -
                frame.minY
            )

        let lake = SKSpriteNode(
            color:
                UIColor(
                    red: 0.16,
                    green: 0.53,
                    blue: 0.72,
                    alpha: 1
                ),
            size:
                CGSize(
                    width: frame.width * 1.06,
                    height: waterHeight
                )
        )

        lake.name = "witchLake"
        lake.position = CGPoint(
            x: frame.midX,
            y:
                frame.minY +
                waterHeight / 2
        )
        lake.zPosition = 3

        let lakeBody =
            SKPhysicsBody(
                rectangleOf:
                    lake.size
            )

        lakeBody.isDynamic = false
        lakeBody.categoryBitMask =
            terrainCategory
        lakeBody.collisionBitMask =
            ploppyCategory |
            droppedSeedCategory
        lakeBody.contactTestBitMask =
            ploppyCategory

        lake.physicsBody = lakeBody

        let smoothSurface = SKSpriteNode(
            color:
                UIColor(
                    red: 0.72,
                    green: 0.92,
                    blue: 0.98,
                    alpha: 0.92
                ),
            size:
                CGSize(
                    width: lake.size.width,
                    height:
                        max(
                            2,
                            frame.height * 0.006
                        )
                )
        )

        smoothSurface.position = CGPoint(
            x: 0,
            y:
                lake.size.height / 2 -
                smoothSurface.size.height / 2
        )
        smoothSurface.zPosition = 1
        lake.addChild(smoothSurface)

        addChild(lake)

        createLakeBank(
            descendingIntoLake: true
        )
    }

    private func createLakeBank(
        descendingIntoLake: Bool
    ) {

        let bankName =
            descendingIntoLake
            ? "lakeEntranceBank"
            : "lakeExitBank"

        childNode(
            withName: bankName
        )?.removeFromParent()

        let bankWidth =
            frame.width * 2

        let lowSurface =
            lakeSurfaceY() -
            frame.minY

        let highSurface =
            lowSurface +
            terrainRiseBeforeLake

        let path = CGMutablePath()
        path.move(
            to: CGPoint(
                x: 0,
                y: 0
            )
        )

        if descendingIntoLake {

            path.addLine(
                to: CGPoint(
                    x: 0,
                    y: highSurface
                )
            )
            path.addLine(
                to: CGPoint(
                    x: frame.width,
                    y: highSurface
                )
            )
            path.addLine(
                to: CGPoint(
                    x: bankWidth,
                    y: lowSurface
                )
            )
        } else {

            path.addLine(
                to: CGPoint(
                    x: 0,
                    y: lowSurface
                )
            )
            path.addLine(
                to: CGPoint(
                    x: frame.width,
                    y: highSurface
                )
            )
            path.addLine(
                to: CGPoint(
                    x: bankWidth,
                    y: highSurface
                )
            )
        }

        path.addLine(
            to: CGPoint(
                x: bankWidth,
                y: 0
            )
        )
        path.closeSubpath()

        let bank = SKShapeNode(
            path: path
        )

        bank.name = bankName
        bank.fillColor = UIColor(
            red: 0.34,
            green: 0.32,
            blue: 0.28,
            alpha: 1
        )
        bank.strokeColor = UIColor(
            red: 0.36,
            green: 0.48,
            blue: 0.25,
            alpha: 1
        )
        bank.lineWidth =
            max(
                3,
                frame.height * 0.012
            )
        bank.zPosition = 4

        if descendingIntoLake {

            bank.position = CGPoint(
                x: frame.minX,
                y: frame.minY
            )
        } else {

            bank.position = CGPoint(
                x: frame.maxX,
                y: frame.minY
            )
        }

        addChild(bank)

        let finalBankX =
            descendingIntoLake
            ? frame.minX - bankWidth
            : frame.minX - frame.width

        let moveBank =
            SKAction.moveTo(
                x: finalBankX,
                duration:
                    lakeBankTransitionDuration
            )

        moveBank.timingMode = .linear

        bank.run(
            SKAction.sequence([
                moveBank,
                SKAction.removeFromParent()
            ])
        )
    }

    private func liftPloppyWithReturningBank() {

        guard let ploppyBody =
            ploppy.physicsBody else {
            return
        }

        let targetY =
            frame.minY -
            grassSinkBelowScreen +
            grassSize.height +
            terrainRiseBeforeLake +
            ploppy.size.height / 2 +
            frame.height * 0.012

        guard ploppy.position.y <
            targetY else {
            return
        }

        let startingY =
            ploppy.position.y

        ploppyBody.velocity = .zero
        ploppyBody.affectedByGravity =
            false

        let liftAction =
            SKAction.customAction(
                withDuration:
                    lakeBankTransitionDuration
            ) { node, elapsedTime in

                let rawProgress =
                    CGFloat(elapsedTime) /
                    CGFloat(
                        self.lakeBankTransitionDuration
                    )

                let progress =
                    rawProgress *
                    rawProgress *
                    (3 - 2 * rawProgress)

                node.position.y =
                    startingY +
                    (targetY - startingY) *
                    progress
            }

        ploppy.run(
            liftAction,
            withKey: "lakeBankLift"
        )
    }

    private func completeLakeExitTransition() {

        isWitchEncounterActive = false
        removeSmoothWitchLake()
        terrainRiseOffset =
            terrainRiseBeforeLake
        applyCurrentTerrainRise()

        if let ploppyBody =
            ploppy.physicsBody {

            ploppyBody.affectedByGravity =
                true
            ploppyBody.velocity =
                CGVector(
                    dx: 0,
                    dy:
                        max(
                            ploppyBody.velocity.dy,
                            25
                        )
                )
        }
    }

    private func removeSmoothWitchLake() {

        childNode(
            withName: "witchLake"
        )?.removeFromParent()

        childNode(
            withName: "lakeEntranceBank"
        )?.removeFromParent()

        childNode(
            withName: "lakeExitBank"
        )?.removeFromParent()

        for grassNode in grassNodes {

            grassNode.alpha = 1

            if let preparedBody =
                grassPhysicsBodyTemplate?.copy()
                    as? SKPhysicsBody {

                grassNode.physicsBody =
                    preparedBody
            }
        }

        groundFillNode?.alpha = 1
    }

    private func beginLakeSkid() {

        guard isWitchEncounterActive else {
            return
        }

        isPloppySkiddingOnLake = true
        lakeWakeElapsedTime = 0

        if let ploppyBody =
            ploppy.physicsBody {

            ploppyBody.velocity =
                CGVector(
                    dx:
                        ploppyBody.velocity.dx,
                    dy: 0
                )
        }

        ploppy.position.y =
            lakeSurfaceY() +
            ploppy.size.height / 2

        createLakeWake(
            particleCount: 10
        )
    }

    private func updateLakeSkid(
        by elapsedTime: TimeInterval
    ) {

        guard isWitchEncounterActive,
              isPloppySkiddingOnLake,
              let ploppyBody =
            ploppy.physicsBody else {
            return
        }

        if ploppyBody.velocity.dy > 12 {
            isPloppySkiddingOnLake = false
            return
        }

        let minimumPloppyY =
            lakeSurfaceY() +
            ploppy.size.height / 2

        ploppy.position.y =
            max(
                ploppy.position.y,
                minimumPloppyY
            )

        if ploppy.position.y >
            minimumPloppyY +
            frame.height * 0.025 {

            isPloppySkiddingOnLake = false
            return
        }

        ploppyBody.velocity =
            CGVector(
                dx:
                    ploppyBody.velocity.dx,
                dy: 0
            )

        lakeWakeElapsedTime +=
            elapsedTime

        if lakeWakeElapsedTime >= 0.075 {

            lakeWakeElapsedTime = 0

            createLakeWake(
                particleCount: 3
            )
        }
    }

    private func createLakeWake(
        particleCount: Int
    ) {

        for particleNumber in
            0..<particleCount {

            let particleWidth =
                CGFloat.random(
                    in:
                        (frame.height * 0.020)...(frame.height * 0.055)
                )

            let particleHeight =
                CGFloat.random(
                    in:
                        (frame.height * 0.007)...(frame.height * 0.018)
                )

            let particleSize = CGSize(
                width: particleWidth,
                height: particleHeight
            )

            let spray = SKShapeNode(
                ellipseOf:
                    particleSize
            )

            spray.name = "lakeWake"
            spray.fillColor =
                particleNumber.isMultiple(of: 2)
                ? UIColor(
                    red: 0.92,
                    green: 0.98,
                    blue: 1.0,
                    alpha: 0.92
                )
                : UIColor(
                    red: 0.62,
                    green: 0.86,
                    blue: 0.96,
                    alpha: 0.82
                )
            spray.strokeColor =
                UIColor.clear
            spray.position = CGPoint(
                x:
                    ploppy.frame.minX -
                    CGFloat.random(
                        in: 0...frame.height * 0.04
                    ),
                y:
                    lakeSurfaceY() +
                    CGFloat.random(
                        in: 0...frame.height * 0.025
                    )
            )
            spray.zPosition = 9

            addChild(spray)

            let travelDuration =
                Double.random(
                    in: 0.42...0.68
                )

            let wakeTravelX =
                CGFloat.random(
                    in:
                        (frame.width * 0.07)...(frame.width * 0.16)
                )

            let wakeTravelY =
                CGFloat.random(
                    in:
                        (frame.height * 0.015)...(frame.height * 0.065)
                )

            let sprayMovement =
                SKAction.moveBy(
                    x: -wakeTravelX,
                    y: wakeTravelY,
                    duration:
                        travelDuration
                )

            sprayMovement.timingMode =
                SKActionTimingMode.easeOut

            spray.run(
                SKAction.sequence([
                    SKAction.group([
                        sprayMovement,
                        SKAction.fadeOut(
                            withDuration:
                                travelDuration
                        ),
                        SKAction.scale(
                            to: 0.35,
                            duration:
                                travelDuration
                        )
                    ]),
                    SKAction.removeFromParent()
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
                    dy: 307.926580587954
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

        dropSeed(
            from: 0
        )
    }

    private func performLowerRightPooAction() {

        guard !isGameOver else {
            return
        }

        dropSeed(
            from: 1
        )
    }

    private func dropSeed(
        from slot: Int
    ) {

        guard let foodKind =
            stomachSlots[slot] else {
            return
        }

        stomachSlots[slot] = nil
        beginSeedTerrainLowering()

        stomachSeedNodes[slot]?
            .removeFromParent()

        stomachSeedNodes[slot] = nil

        let seedTexture: SKTexture

        switch foodKind {

        case .apple:
            seedTexture =
                appleSeedTexture

        case .cucumber:
            seedTexture =
                cucumberSeedTexture

        case .corn:
            seedTexture =
                cornSeedTexture
        }

        let droppedSeed = SKSpriteNode(
            texture: seedTexture
        )

        let seedLongDimension =
            ploppy.size.height *
            droppedSeedLongDimensionFractionOfPloppy

        let seedAspectRatio =
            seedTexture.size().width /
            seedTexture.size().height

        droppedSeed.size = CGSize(
            width:
                seedLongDimension,
            height:
                seedLongDimension /
                seedAspectRatio
        )

        droppedSeed.position = CGPoint(
            x: ploppy.position.x,
            y:
                ploppy.frame.minY -
                droppedSeed.size.height / 2 -
                frame.height * 0.01
        )

        droppedSeed.name = "droppedSeed"
        droppedSeed.alpha = 1
        droppedSeed.zPosition = 12

        let seedPhysicsBody =
            SKPhysicsBody(
                texture:
                    seedTexture,
                size:
                    droppedSeed.size
            )

        seedPhysicsBody.isDynamic = true
        seedPhysicsBody.affectedByGravity = true
        seedPhysicsBody.allowsRotation = false
        seedPhysicsBody.categoryBitMask =
            droppedSeedCategory
        seedPhysicsBody.collisionBitMask =
            terrainCategory
        seedPhysicsBody.contactTestBitMask =
            terrainCategory
        seedPhysicsBody.restitution = 0
        seedPhysicsBody.friction = 0.85
        seedPhysicsBody.linearDamping = 0.25
        seedPhysicsBody.usesPreciseCollisionDetection =
            true

        seedPhysicsBody.velocity =
            CGVector(
                dx: 0,
                dy: -55
            )

        droppedSeed.physicsBody =
            seedPhysicsBody

        addChild(droppedSeed)

        let turnVertical =
            SKAction.rotate(
                toAngle: .pi / 2,
                duration: 0.65,
                shortestUnitArc: true
            )

        turnVertical.timingMode =
            .easeInEaseOut

        droppedSeed.run(
            turnVertical
        )
    }

    private func storeFood(
        from foodNode: SKNode
    ) -> Bool {

        guard let emptySlot =
            stomachSlots.firstIndex(
                where: { $0 == nil }
            ) else {
            return false
        }

        guard let foodKindName =
            foodNode.userData?["foodKind"]
                as? String,
              let foodKind =
            FoodKind(rawValue: foodKindName) else {
            return false
        }

        stomachSlots[emptySlot] =
            foodKind

        showStoredSeed(
            foodKind,
            in: emptySlot
        )

        return true
    }

    private func showStoredSeed(
        _ foodKind: FoodKind,
        in slot: Int
    ) {

        stomachSeedNodes[slot]?
            .removeFromParent()

        let seedTexture: SKTexture

        switch foodKind {

        case .apple:
            seedTexture =
                appleSeedTexture

        case .cucumber:
            seedTexture =
                cucumberSeedTexture

        case .corn:
            seedTexture =
                cornSeedTexture
        }

        let seedNode = SKSpriteNode(
            texture: seedTexture
        )

        let seedHeight =
            frame.height * 0.12

        let seedAspectRatio =
            seedTexture.size().width /
            seedTexture.size().height

        seedNode.size = CGSize(
            width:
                seedHeight *
                seedAspectRatio,
            height:
                seedHeight
        )

        let edgeMargin =
            frame.height * 0.035

        seedNode.position.x =
            frame.maxX -
            edgeMargin -
            seedNode.size.width / 2

        if slot == 0 {

            seedNode.position.y =
                frame.maxY -
                edgeMargin -
                seedNode.size.height / 2
        } else {

            seedNode.position.y =
                frame.minY +
                edgeMargin +
                seedNode.size.height / 2
        }

        seedNode.name =
            slot == 0
            ? "topStomachSeed"
            : "bottomStomachSeed"

        seedNode.alpha = 0.5
        seedNode.zPosition = 40

        addChild(seedNode)
        stomachSeedNodes[slot] =
            seedNode
    }

    private func handleDroppedSeedImpact(
        seedNode: SKNode,
        terrainNode: SKNode?,
        contactPoint: CGPoint
    ) {

        seedNode.removeAllActions()
        seedNode.physicsBody = nil
        seedNode.removeFromParent()

        guard let terrainSprite =
            terrainNode as? SKSpriteNode else {
            return
        }

        guard terrainSprite.name == "grass" ||
            terrainSprite.name == "hill" else {
            return
        }

        restorationPatches.removeAll {
            $0.terrainNode == nil ||
            $0.cropNode.parent == nil
        }

        let localImpactPoint =
            terrainSprite.convert(
                contactPoint,
                from: self
            )

        if let existingPatch =
            restorationPatches.first(
                where: { patch in

                    guard patch.terrainNode ===
                        terrainSprite else {
                        return false
                    }

                    let horizontalDistance =
                        localImpactPoint.x -
                        patch.localPosition.x

                    let verticalDistance =
                        localImpactPoint.y -
                        patch.localPosition.y

                    let distance =
                        hypot(
                            horizontalDistance,
                            verticalDistance
                        )

                    return distance <=
                        restorationCoreRadius(
                            for:
                                patch.level
                        )
                }
            ) {

            existingPatch.level += 1

            updateRestorationPatch(
                existingPatch
            )

            return
        }

        createRestorationPatch(
            on: terrainSprite,
            at: localImpactPoint
        )
    }

    private func restorationCoreRadius(
        for level: Int
    ) -> CGFloat {

        let centimetre =
            frame.height *
            restorationCentimetreFraction

        return (
            CGFloat(level) - 0.5
        ) * centimetre
    }

    private func restorationOuterRadius(
        for level: Int
    ) -> CGFloat {

        return restorationCoreRadius(
            for: level
        ) +
            frame.height *
            restorationCentimetreFraction
    }

    private func createRestorationPatch(
        on terrainSprite: SKSpriteNode,
        at localPosition: CGPoint
    ) {

        let cropNode = SKCropNode()
        cropNode.position = .zero
        cropNode.zPosition = 0.7

        let terrainMask = SKSpriteNode(
            texture:
                terrainSprite.texture
        )

        terrainMask.size =
            terrainSprite.size
        terrainMask.anchorPoint =
            terrainSprite.anchorPoint
        terrainMask.position = .zero

        cropNode.maskNode =
            terrainMask

        let gradientNode =
            SKSpriteNode()

        gradientNode.position =
            localPosition
        gradientNode.zPosition = 1

        cropNode.addChild(
            gradientNode
        )

        terrainSprite.addChild(
            cropNode
        )

        let patch =
            RestorationPatchState(
                terrainNode:
                    terrainSprite,
                localPosition:
                    localPosition,
                cropNode:
                    cropNode,
                gradientNode:
                    gradientNode
            )

        restorationPatches.append(
            patch
        )

        updateRestorationPatch(
            patch
        )
    }

    private func updateRestorationPatch(
        _ patch: RestorationPatchState
    ) {

        let coreRadius =
            restorationCoreRadius(
                for: patch.level
            )

        let outerRadius =
            restorationOuterRadius(
                for: patch.level
            )

        let coreFraction =
            coreRadius /
            outerRadius

        patch.gradientNode.texture =
            createRestorationGradientTexture(
                coreFraction:
                    coreFraction
            )

        patch.gradientNode.size =
            CGSize(
                width:
                    outerRadius * 2,
                height:
                    outerRadius * 2
            )
    }

    private func createRestorationGradientTexture(
        coreFraction: CGFloat
    ) -> SKTexture {

        let textureSize = CGSize(
            width: 256,
            height: 256
        )

        let renderer =
            UIGraphicsImageRenderer(
                size: textureSize
            )

        let image = renderer.image {
            context in

            let green = UIColor(
                red: 0.24,
                green: 0.78,
                blue: 0.31,
                alpha: 1
            )

            let transparentGreen =
                UIColor(
                    red: 0.24,
                    green: 0.78,
                    blue: 0.31,
                    alpha: 0
                )

            let colours = [
                green.cgColor,
                green.cgColor,
                transparentGreen.cgColor
            ] as CFArray

            let locations: [CGFloat] = [
                0,
                coreFraction,
                1
            ]

            guard let gradient =
                CGGradient(
                    colorsSpace:
                        CGColorSpaceCreateDeviceRGB(),
                    colors:
                        colours,
                    locations:
                        locations
                ) else {
                return
            }

            let centre = CGPoint(
                x: textureSize.width / 2,
                y: textureSize.height / 2
            )

            context.cgContext
                .drawRadialGradient(
                    gradient,
                    startCenter:
                        centre,
                    startRadius: 0,
                    endCenter:
                        centre,
                    endRadius:
                        textureSize.width / 2,
                    options: []
                )
        }

        let texture =
            SKTexture(
                image: image
            )

        texture.filteringMode =
            .linear

        return texture
    }

    func didBegin(
        _ contact: SKPhysicsContact
    ) {

        let contactedCategories =
            contact.bodyA.categoryBitMask |
            contact.bodyB.categoryBitMask

        let droppedSeedTerrainCategories =
            droppedSeedCategory |
            terrainCategory

        if contactedCategories ==
            droppedSeedTerrainCategories {

            let seedBody =
                contact.bodyA.categoryBitMask ==
                    droppedSeedCategory
                ? contact.bodyA
                : contact.bodyB

            let terrainBody =
                contact.bodyA.categoryBitMask ==
                    terrainCategory
                ? contact.bodyA
                : contact.bodyB

            if let seedNode =
                seedBody.node {

                handleDroppedSeedImpact(
                    seedNode:
                        seedNode,
                    terrainNode:
                        terrainBody.node,
                    contactPoint:
                        contact.contactPoint
                )
            }

            return
        }

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

            guard let foodNode =
                foodBody.node else {
                return
            }

            guard storeFood(
                from: foodNode
            ) else {
                return
            }

            foodNode.removeAllActions()
            foodNode.removeFromParent()
            return
        }

        let requiredCategories =
            ploppyCategory |
            terrainCategory

        if contactedCategories == requiredCategories {

            if isWitchEncounterActive {

                let touchedWitch =
                    contact.bodyA.node?.name ==
                        "blondieWitch" ||
                    contact.bodyB.node?.name ==
                        "blondieWitch"

                if touchedWitch {
                    killPloppy()
                    return
                }

                let touchedLake =
                    contact.bodyA.node?.name ==
                        "witchLake" ||
                    contact.bodyB.node?.name ==
                        "witchLake"

                if touchedLake {
                    beginLakeSkid()
                }

                return
            }

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

