//
//  GameScene.swift
//  ZombieConga
//
//  Created by MacBook on 1/4/20.
//  Copyright © 2020 Popovic d.o.o. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    let zombieAnimation: SKAction
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    
    let playableRect: CGRect
    
    var lastTouchLocation: CGPoint?
    
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed( "hitCat.wav",
                                                                   waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed( "hitCatLady.wav",
                                                                     waitForCompletion: false)
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        
        self.playableRect = CGRect(x: 0,
                                   y: playableMargin,
                                   width: size.width,
                                   height: playableHeight)
        
        var textures: [SKTexture] = []
        
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // 6
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    override func didMove(to view: SKView) {
        
        backgroundColor = SKColor.black
        
        let background = SKSpriteNode(imageNamed: "background1")
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
        
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        
        // MARK: RUN ANIMATION FOR SPAWN
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run({
            self.spawnEnemy()
        }), SKAction.wait(forDuration: 2.0)])))
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run({
            self.spawnCat()
        }), SKAction.wait(forDuration: 1.0)])))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        // print("\(dt*1000) milliseconds since last update")
        
        if let lastTouchLocation = self.lastTouchLocation {
            let diff = lastTouchLocation - self.zombie.position
            if diff.lenght() <= zombieMovePointsPerSec * CGFloat(self.dt) {
                self.zombie.position = lastTouchLocation
                self.velocity = CGPoint.zero
                self.stopZombieAnimation()
            } else {
                self.move(sprite: self.zombie, velocity: self.velocity)
                self.rotate(sprite: self.zombie,
                            direction: self.velocity,
                            rotateRadiansPerSec: self.zombieRotateRadiansPerSec)
            }
            
        }
        
        self.boundsCheckZombie()
        
        //        self.checkColisions()
    }
    override func didEvaluateActions() {
        self.checkColisions()
    }
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        // print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        self.startZombieAnimation()
        
        let offset = location - self.zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        self.lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        self.sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        self.sceneTouched(touchLocation: touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: self.playableRect.minY)
        let topRight = CGPoint(x: size.width, y: self.playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
            
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
            
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    //MARK:spawnEnemy
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(x: size.width + enemy.size.width / 2,
                                 y: CGFloat.random(min: self.playableRect.minY + enemy.size.height / 2, max: self.playableRect.maxY - enemy.size.height / 2))
        enemy.name = "enemy"
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x:  -enemy.size.width / 2,
                                         duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove,actionRemove]))
    }
    //MARK: spawnCat
    func spawnCat() {
        
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.position = CGPoint(x: CGFloat.random(min: self.playableRect.minX, max: self.playableRect.maxX),
                               y: CGFloat.random(min: self.playableRect.minY, max: self.playableRect.maxY))
        cat.name = "cat"
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        // animate cat wigle
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        //        let wiggleWait = SKAction.repeat(fullWiggle, count: 10)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        
        cat.run(SKAction.sequence(actions))
        
    }
    
    //MARK:ACTION
    func startZombieAnimation() {
        if self.zombie.action(forKey: "animation") == nil {
            self.zombie.run(SKAction.repeatForever(self.zombieAnimation),
                            withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        self.zombie.removeAction(forKey: "animation")
    }
    
    //MARK: ZOMBIE HIT
    
    func zombieHit(cat: SKSpriteNode) {
        cat.removeFromParent()
        run(self.catCollisionSound)
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        run(self.enemyCollisionSound)
    }
    
    func checkColisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { (node, _) in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
            
        }
        for cat in hitCats {
            self.zombieHit(cat: cat)
        }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { (node, _) in
            let enemy = node as! SKSpriteNode
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                hitEnemies.append(enemy)
            }
            
        }
        for enemy in hitEnemies {
            zombieHit(enemy: enemy)
        }
        
    }
}
