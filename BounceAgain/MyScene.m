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
@property (nonatomic) SKShapeNode *goalRegistrationNode;

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
        self.ball.xScale = 0.75f;
        self.ball.yScale = self.ball.xScale;
        [self.ball setName:@"Ball"];
        
        // ge bollen en physicsbody
        self.ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_ball.frame.size.height / 2];
        self.ball.physicsBody.dynamic = YES;
        self.ball.physicsBody.affectedByGravity = NO;
        
        // bollen är ej ännu selected
        self.ballIsSelected = NO;
        
        [self addChild:_ball];
        
        

        
        // hållare för målet, skall inkludera en bild av målet, samt ett antal child nodes med physicsbodies för att simulera ett mål
        
        float alphaOfGoalNodes = 0.0f; // testing
        
        SKSpriteNode *goalContainer = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0 green:0 blue:1.0f alpha:0.0f] size:CGSizeMake(150, 50)];
        goalContainer.position = CGPointMake(160.0f, 400.0f);
        [self addChild:goalContainer];
        
        // målgrafiken
        
        SKSpriteNode *goalImageSprite = [SKSpriteNode spriteNodeWithImageNamed:@"goal"];
        goalImageSprite.xScale = 0.65f;
        goalImageSprite.yScale = goalImageSprite.xScale;
        [goalContainer addChild:goalImageSprite];
        
        // noder för stolpar
        SKShapeNode *leftGoalPost = [[SKShapeNode alloc] init];
        leftGoalPost.path = CGPathCreateWithRoundedRect(CGRectMake(-75.0f, -25.0f, 30.0f, 50.0f), 5.0, 5.0, nil);
        leftGoalPost.fillColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alphaOfGoalNodes];
        leftGoalPost.lineWidth = 0.0f;
//        leftGoalPost.position = CGPointMake(-75.0, -25.0);
        leftGoalPost.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:leftGoalPost.path];
        [goalContainer addChild:leftGoalPost];
        
        SKShapeNode *rightGoalPost = [[SKShapeNode alloc] init];
        rightGoalPost.path = CGPathCreateWithRoundedRect(CGRectMake(75.0-30.0f, -25.0f, 30.0f, 50.0f), 5.0, 5.0, nil);
        rightGoalPost.fillColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alphaOfGoalNodes];
        rightGoalPost.lineWidth = 0.0f;
//        rightGoalPost.position = CGPointMake(75.0-30.0, -25.0);
        rightGoalPost.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:rightGoalPost.path];
        [goalContainer addChild:rightGoalPost];
        
        // bakdelen av målet
        SKShapeNode *backOfGoal = [[SKShapeNode alloc] init];
        backOfGoal.path = CGPathCreateWithRoundedRect(CGRectMake(-75.0f, 25.0f - 10.0f, 150.0f, 10.0f), 5.0f, 5.0f, nil);
        backOfGoal.fillColor = [SKColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:alphaOfGoalNodes];
        backOfGoal.lineWidth = 0.0f;
        backOfGoal.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:backOfGoal.path];
        [goalContainer addChild:backOfGoal];
        
        // node som registrerar att bollen gått i mål, är en property då den används i updatemetoden
        self.goalRegistrationNode = [[SKShapeNode alloc] init];
        self.goalRegistrationNode.path = CGPathCreateWithRect(CGRectMake(-45.0f, 13.0f, 90.0f, 2.0f), nil);
        self.goalRegistrationNode.fillColor = [SKColor colorWithRed:1.0f green:1.0f blue:0.0f alpha:alphaOfGoalNodes];
        self.goalRegistrationNode.lineWidth = 0.0f;
        [goalContainer addChild:self.goalRegistrationNode];
        
        
    }
    return self;
}

-(void)didMoveToView:(SKView *)view {
	UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[self view] addGestureRecognizer:gestureRecognizer];
	
	
}


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

    else if (recognizer.state == UIGestureRecognizerStateEnded && self.ballIsSelected) {
        self.ballIsSelected = NO;
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGVector velocityVector = CGVectorMake(velocity.x * 0.05, -velocity.y * 0.05);
        [self.ball.physicsBody applyImpulse:velocityVector];
    }
}




-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if ([self.ball intersectsNode:self.goalRegistrationNode]) {
//        NSLog(@"Mål!");
        self.ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
    }
    
}

@end
