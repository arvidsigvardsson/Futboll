//
//  MyScene.m
//  BounceAgain
//
//  Created by Arvid on 2013-12-16.
//  Copyright (c) 2013 Arvid. All rights reserved.
//

#import "MyScene.h"

@interface MyScene ()

@property (nonatomic) SKSpriteNode *ball;
@property BOOL ballIsSelected;
//@property float ballOriginalX;
//@property float ballOriginalY;
@property CGPoint originalBallPosition;
@property CGPoint oldBallPosition;
@property (nonatomic) SKSpriteNode *goal;

@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
    
        self.backgroundColor = [SKColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1];
        
        
        // skapa spelyta, hela skärmen, ingen gravitation
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        SKPhysicsBody *borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody = borderBody;
        
        // friktion, ************  ska nog ändras ********************
        self.physicsBody.friction = 0.0f;
        
        // initiera en boll
        self.ball = [SKSpriteNode spriteNodeWithImageNamed:@"football"];
        self.ball.position = CGPointMake(50.0f, 50.0f);
        self.ball.xScale = 0.15f;
        self.ball.yScale = self.ball.xScale;
        [self.ball setName:@"Ball"];
        
        // ge bollen en physicsbody
        self.ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_ball.frame.size.height / 2];
        self.ball.physicsBody.dynamic = YES;
        self.ball.physicsBody.affectedByGravity = NO;
        
        // bollen är ej ännu selected
        self.ballIsSelected = NO;
        
        [self addChild:_ball];
        
        
        
//        self.goal = [SKSpriteNode spriteNodeWithImageNamed:@"goal"];
//        _goal.xScale = 0.75f;
//        _goal.yScale = _goal.xScale;
//        
//        _goal.position = CGPointMake(150.0f, 400.0f);
//        
//        [self addChild:_goal];
        
        // hållare för målet, skall inkludera en bild av målet, samt ett antal child nodes med physicsbodies för att simulera ett mål
        SKSpriteNode *goalContainer = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0 green:0 blue:1.0f alpha:0.1f] size:CGSizeMake(180, 50)];
        goalContainer.position = CGPointMake(160.0f, 300.0f);
        [self addChild:goalContainer];
        
        // målgrafiken
        SKSpriteNode *goalImageSprite = [SKSpriteNode spriteNodeWithImageNamed:@"goal"];
        goalImageSprite.xScale = 0.75f;
        goalImageSprite.yScale = goalImageSprite.xScale;
        [goalContainer addChild:goalImageSprite];
        
        
        
        
        
    }
    return self;
}

-(void)didMoveToView:(SKView *)view {
	UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[self view] addGestureRecognizer:gestureRecognizer];
	
	
}

//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInNode:self];
//
//    //    NSLog(@"x = %f y = %f", location.x, location.y);
//    
//    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:location];
//    NSLog(@"Noden är %@", touchedNode.name);
//    if ([touchedNode.name  isEqual: @"Ball"]) {
//        SKAction *moveAction = [SKAction moveTo:location duration:0];
//        [touchedNode runAction:moveAction];
//    }
//}
//
//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    /* Called when a touch begins */
//    
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInNode:self];
//
////    NSLog(@"x = %f y = %f", location.x, location.y);
//    
//    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:location];
////    NSLog(@"Noden är %@", touchedNode.name);
//    if ([touchedNode.name  isEqual: @"Ball"]) {
//        [touchedNode.physicsBody applyImpulse:CGVectorMake(50.0f, 100.0f)];
//    }
//    
//    
////    for (UITouch *touch in touches) {
////        CGPoint location = [touch locationInNode:self];
////        
////        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
////        
////        sprite.position = location;
////        
////        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
////        
////        [sprite runAction:[SKAction repeatActionForever:action]];
////        
////        [self addChild:sprite];
////    }
//}
//

-(void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        
        touchLocation = [self convertPointFromView:touchLocation];
        if ([self.ball containsPoint:touchLocation]) {
            NSLog(@"Ball is touched");
            self.ballIsSelected = YES;
            self.originalBallPosition = touchLocation;
            
        }
        
    }
//    else if (recognizer.state == UIGestureRecognizerStateChanged && self.ballIsSelected) {
//        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
//        touchLocation = CGPointMake(touchLocation.x, self.view.bounds.size.height-touchLocation.y);
//        NSLog(@"x = %f y = %f", touchLocation.x, touchLocation.y);
//        SKAction *moveAction = [SKAction moveTo:touchLocation duration:0];
//        [self.ball runAction:moveAction];
//        
//
//        
//        CGPoint translation = [recognizer translationInView:self.view];
//        translation = CGPointMake(translation.x, -translation.y);
//        NSLog(@"");
//        SKAction *moveAction = [SKAction moveByX:translation.x y:translation.y duration:0];
//        
//        CGPoint location = [recognizer.]
//        [self.ball runAction:moveAction];
//    
//    
////    
////
//    }

    else if (recognizer.state == UIGestureRecognizerStateEnded && self.ballIsSelected) {
        self.ballIsSelected = NO;
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGVector velocityVector = CGVectorMake(velocity.x * 0.05, -velocity.y * 0.05);
        [self.ball.physicsBody applyImpulse:velocityVector];
    }
}

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInNode:self];
//    if ([self.ball containsPoint:location]) {
////        NSLog(@"Bollen är rörd");
//        self.ballIsSelected = YES;
//    }
//
//}
//
//
//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInNode:self];
//    
//    if (self.ballIsSelected){
//        self.oldBallPosition = location;
//        
//        self.ball.physicsBody.velocity = CGVectorMake(0, 0);
//        
//        SKAction *moveAction = [SKAction moveTo:location duration:0];
//        [self.ball runAction:moveAction];
//    }
//}
//
//-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = [touches anyObject];
//    CGPoint location = [touch locationInNode:self];
//    
//    self.ballIsSelected = NO;
//    
//    CGVector ballImpulseVector = CGVectorMake(location.x - self.oldBallPosition.x, location.y - self.oldBallPosition.y);
//    NSLog(@"impulseVector = %f   %f", ballImpulseVector.dx, ballImpulseVector.dy);
//    [self.ball.physicsBody applyImpulse:ballImpulseVector];
//    
//}



-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
//    if ([self.ball intersectsNode:self.goal]) {
//        NSLog(@"Mål!");
//    }
    
}

@end
