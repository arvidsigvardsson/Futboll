//
//  MyScene.m
//  BounceAgain
//
//  Created by Arvid on 2013-12-16.
//  Copyright (c) 2013 Arvid. All rights reserved.
//

//  MyScene is where all game logic and graphics setup reside



#import "MyScene.h"

@interface MyScene ()

// properties to control gameplay and scores etc.
@property BOOL ballIsSelected;
@property CGPoint originalBallPosition;
@property BOOL hasMadeShot;
@property int score;
@property int round;
@property int timeOfRound;
@property bool timerIsPaused;
@property int durationOfShot;

@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        //      initializes graphics and physics
        
        [self generatePlayingField];
        
        [self generateTextGraphics];
        
        [self setUpPhysics];
        
        [self generateGoalGraphics];
        
        [self generateMessageNode];
        
        [self generateFirstDefender];

        
        // initializes timer, but pauses the game before start to give player time to get bearings
        self.timerIsPaused = YES;
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerCountdown) userInfo:nil repeats:YES];
        
    }
    return self;
}



- (void)generatePlayingField {
    
    self.backgroundColor = [SKColor colorWithRed:255.0/255.0f green:134.0/255.0f blue:25.0/255.0f alpha:1];
    
    // goalareas
    CGMutablePathRef lowerGoalAreaPath = CGPathCreateMutable();
    CGPathMoveToPoint(lowerGoalAreaPath, nil, 3.0f, 3.0f);
    CGPathAddArc(lowerGoalAreaPath, nil, self.frame.size.width / 2.0f, 3.0f, self.frame.size.width / 2.0f - 6, 0, M_PI, 0);
    
    SKShapeNode *lowerGoalAreaNode = [[SKShapeNode alloc] init];
    lowerGoalAreaNode.path = lowerGoalAreaPath;
    lowerGoalAreaNode.lineWidth = 5;
    lowerGoalAreaNode.fillColor = [UIColor colorWithRed:0.0f green:145.0 / 255.0f blue:178.0 / 255.0 alpha:1.0f];
    lowerGoalAreaNode.name = @"lowerGoalAreaNode";
    [self addChild:lowerGoalAreaNode];
    
    CGMutablePathRef upperGoalAreaPath = CGPathCreateMutable();
    CGPathMoveToPoint(upperGoalAreaPath, nil, 3.0f, self.frame.size.height - 3.0f);
    CGPathAddArc(upperGoalAreaPath, nil, self.frame.size.width / 2.0f, self.frame.size.height - 3.0f, self.frame.size.width / 2.0f - 6, 0, M_PI, 1);
    
    SKShapeNode *upperGoalAreaNode = [[SKShapeNode alloc] init];
    upperGoalAreaNode.path = upperGoalAreaPath;
    upperGoalAreaNode.lineWidth = 5;
    upperGoalAreaNode.fillColor = [UIColor colorWithRed:0.0f green:145.0 / 255.0f blue:178.0 / 255.0 alpha:1.0f];
    [self addChild:upperGoalAreaNode];
    
    // midline
    CGMutablePathRef midlinePath = CGPathCreateMutable();
    CGPathMoveToPoint(midlinePath, nil, 0.0f, self.frame.size.height / 2.0f);
    CGPathAddLineToPoint(midlinePath, nil, self.frame.size.width, self.frame.size.height / 2.0f);
    
    SKShapeNode *midlineNode = [[SKShapeNode alloc] init];
    midlineNode.path = midlinePath;
    midlineNode.lineWidth = 5.0f;
    [self addChild:midlineNode];
    
    // sidelines
    SKShapeNode *sidelines = [[SKShapeNode alloc] init];
    sidelines.path = CGPathCreateWithRect(self.frame, nil);
    sidelines.lineWidth = 10.0f;
    [self addChild:sidelines];

}

- (void)generateTextGraphics {
    // nodes for score display
    SKSpriteNode *scoreHolderNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.0] size:CGSizeMake(75, 75)];
    scoreHolderNode.position = CGPointMake(self.frame.size.width - 50, self.frame.size.height - 33);
    scoreHolderNode.name = @"scoreHolderNode";
    
    SKLabelNode *scoreTitleNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    scoreTitleNode.fontSize = 15;
    scoreTitleNode.text = @"SCORE";
    scoreTitleNode.position = CGPointMake(0, 10);
    
    SKLabelNode *scoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    scoreNode.position = CGPointMake(0, -20);
    scoreNode.fontSize = 30;
    scoreNode.name = @"scoreNode";
    
    [scoreHolderNode addChild:scoreTitleNode];
    [scoreHolderNode addChild:scoreNode];
    [self addChild:scoreHolderNode];
    
    // timer that counts down time in round
    SKSpriteNode *roundHolderNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.0] size:CGSizeMake(75, 75)];
    roundHolderNode.position = CGPointMake(50, self.frame.size.height - 33);
    roundHolderNode.name = @"roundHolderNode";
    
    SKLabelNode *roundTitleNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    roundTitleNode.fontSize = 15;
    roundTitleNode.text = @"TIME";
    roundTitleNode.position = CGPointMake(0, 10);
    
    SKLabelNode *roundNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    roundNode.position = CGPointMake(-30, -20);
    roundNode.fontSize = 30;
    roundNode.horizontalAlignmentMode = 1;
    roundNode.text = @"0.0";
    roundNode.name = @"roundNode";
    
    [roundHolderNode addChild:roundTitleNode];
    [roundHolderNode addChild:roundNode];
    [self addChild:roundHolderNode];
}

- (void)setUpPhysics {
    // sets up the physicsworld
    
    self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
    
   // creates a borderbody for the ball to bounce off of. It extends beyond the screen at the goal line so that the ball can slide outside the screen. This helps with goal registration and prevents the ball from bouncing out of the goal
    CGMutablePathRef borderPath = CGPathCreateMutable();
    
    CGPoint addLines[] =
    {
        CGPointMake(0.0, 0.0),
        CGPointMake(0.0, self.frame.size.height),
        CGPointMake(self.frame.size.width / 2.0f - 75, self.frame.size.height),
        CGPointMake(self.frame.size.width / 2.0f - 75, self.frame.size.height + 200.0),
        CGPointMake(self.frame.size.width / 2.0f + 75, self.frame.size.height + 200.0),
        CGPointMake(self.frame.size.width / 2.0f + 75, self.frame.size.height),
        CGPointMake(self.frame.size.width, self.frame.size.height),
        CGPointMake(self.frame.size.width, 0.0f),
        CGPointMake(0.0f, 0.0f)
    };
    
    CGPathAddLines(borderPath, nil, addLines, 10);
    SKPhysicsBody *borderBody = [SKPhysicsBody bodyWithEdgeChainFromPath:borderPath];
    
    self.physicsBody = borderBody;
    
    
    // friction
    self.physicsBody.friction = 1.0f;
}

- (void)generateFirstDefender {
    // en defender skapas här, de två andra i end OfRound-metoden, då de inte ska vara med i första leveln
    SKSpriteNode *defender1 = [SKSpriteNode spriteNodeWithImageNamed:@"redDefender"];
    defender1.xScale = 0.75f;
    defender1.yScale = defender1.xScale;
    defender1.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:defender1.frame.size.height / 2.0f + 7.0f];
    defender1.position = CGPointMake(200, self.frame.size.height * 3.0 / 5.0 - 15);
    defender1.physicsBody.dynamic = NO;
    defender1.name = @"defender1";
    [self addChild:defender1];
}

- (void)generateGoalGraphics {
    
    float alphaOfGoalNodes = 0.0f; // used for testing, to visualize all invisible nodes of the goal
    
    // a holder node for both graphics and physics of the goal
    SKSpriteNode *goalContainer = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0 green:0 blue:1.0f alpha:0.0f] size:CGSizeMake(150, 100)];
    goalContainer.position = CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height - 30);
    [self addChild:goalContainer];
    
    // goal graphics
    SKSpriteNode *goalImageSprite = [SKSpriteNode spriteNodeWithImageNamed:@"goalBW"];
    goalImageSprite.xScale = 0.65f;
    goalImageSprite.yScale = goalImageSprite.xScale;
    goalImageSprite.zPosition = 0.5;
    [goalContainer addChild:goalImageSprite];
    
    // invisible nodes for goal posts
    SKShapeNode *leftGoalPost = [[SKShapeNode alloc] init];
    leftGoalPost.path = CGPathCreateWithRoundedRect(CGRectMake(-70.0f, -25.0f, 15.0f, 50.0f), 5.0, 5.0, nil);
    leftGoalPost.fillColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alphaOfGoalNodes];
    leftGoalPost.lineWidth = 0.0f;
    leftGoalPost.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:leftGoalPost.path];
    [goalContainer addChild:leftGoalPost];
    
    SKShapeNode *rightGoalPost = [[SKShapeNode alloc] init];
    rightGoalPost.path = CGPathCreateWithRoundedRect(CGRectMake(75.0 - 20.0f, -25.0f, 15.0f, 50.0f), 5.0, 5.0, nil);
    rightGoalPost.fillColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alphaOfGoalNodes];
    rightGoalPost.lineWidth = 0.0f;
    rightGoalPost.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:rightGoalPost.path];
    [goalContainer addChild:rightGoalPost];

}

- (void)generateMessageNode {
    // node for messages like "Goal!" and "Round 2"
    SKLabelNode *messageNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    messageNode.name = @"messageNode";
    messageNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    messageNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    messageNode.position = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0 + 75.0);
    messageNode.fontSize = 50;
    messageNode.alpha = 0.0;
    [self addChild:messageNode];
}


-(void)createBall {
    // ball graphics
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ballWithHolder"];
    ball.xScale = 0.75f;
    ball.yScale = ball.xScale;
    [ball setName:@"ball"];
    
    // ball physicsbody
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:23.0f];
    ball.physicsBody.dynamic = YES;
    ball.physicsBody.affectedByGravity = NO;
    ball.physicsBody.restitution = 0.17;
    ball.physicsBody.friction = 1.0;
    
    // ball is not selected by default
    self.ballIsSelected = NO;
    
    [self addChild:ball];

}


-(void)timerCountdown {
    
    // this method responds to the timer firing
    
    if (!self.timerIsPaused) {
        SKNode *roundHolderNode = [self childNodeWithName:@"roundHolderNode"];
        SKLabelNode *roundNode = (SKLabelNode *)[roundHolderNode childNodeWithName:@"roundNode"];
    //
        self.timeOfRound -= 1;
        NSString *displayTime;
        
        if (self.timeOfRound / 10 == 0) {
            displayTime = [NSString stringWithFormat:@"                %i.%i", self.timeOfRound / 10, self.timeOfRound % 10];
        } else {
            displayTime = [NSString stringWithFormat:@"%i.%i", self.timeOfRound / 10, self.timeOfRound % 10];
        }
   
        roundNode.text = displayTime;
        
        // durationOfShot only increments when the ball is outside the lower goal area
        SKSpriteNode *ball = (SKSpriteNode *)[self childNodeWithName:@"ball"];
        SKNode *lowerGoalAreaNode = [self childNodeWithName:@"lowerGoalAreaNode"];
        if ([lowerGoalAreaNode containsPoint:ball.position]) {
            self.durationOfShot = 0;
        } else {
            self.durationOfShot += 1;
        }
        
        
        if(self.hasMadeShot) {
            self.durationOfShot += 1;
        }
        
        // ends the round
        if (self.timeOfRound == 0) {
            self.timerIsPaused = YES;
            [self endOfRound];
        }
    }
}



-(void)resetBall {
   
    // resets the ball to a random point in the lower goal area when timeOfShot is up
    
    
    SKSpriteNode *ball = (SKSpriteNode *)[self childNodeWithName:@"ball"];
    self.hasMadeShot = NO;
    self.durationOfShot = 0;
    
    // random point
    float startX = arc4random_uniform(self.frame.size.width - 50.0) + 25.0;
    float startY = arc4random_uniform(25.0) + 50.0;
    // initera bollen i nedre målområdet
    
    
    ball.position = CGPointMake(startX, startY);
    ball.alpha = 1.0f;
    ball.physicsBody.angularVelocity = 0.0f;
    ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);

}


-(void)didMoveToView:(SKView *)view {
    
	// sets up gesture for making shot
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[self view] addGestureRecognizer:panGestureRecognizer];
    
    
	// starts game only after the gesture is registred
    [self gameStart];

}


-(void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {

    // handles gesture for making the shot
    
    SKSpriteNode *ball = (SKSpriteNode *)[self childNodeWithName:@"ball"];
    SKNode *lowerGoalAreaNode = [self childNodeWithName:@"lowerGoalAreaNode"];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchLocation = [recognizer locationInView:self.view];
        
        touchLocation = [self convertPointFromView:touchLocation];
        if ([ball containsPoint:touchLocation] && [lowerGoalAreaNode containsPoint:touchLocation]) {
            NSLog(@"Ball is touched");
            self.ballIsSelected = YES;
            self.originalBallPosition = touchLocation;
            self.durationOfShot = 0;
        }
        
    }

    else if (recognizer.state == UIGestureRecognizerStateEnded && self.ballIsSelected) {
        self.ballIsSelected = NO;
        self.hasMadeShot = YES;
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGVector velocityVector = CGVectorMake(velocity.x * 0.05, -velocity.y * 0.05);
        [ball.physicsBody applyImpulse:velocityVector];
    }
}


-(void)updateScoreTo:(int)newScore {
    // updates score graphics
    
    SKNode *scoreHolderNode = [self childNodeWithName:@"scoreHolderNode"];
    SKLabelNode *scoreNode = (SKLabelNode *)[scoreHolderNode childNodeWithName:@"scoreNode"];
    NSString *scoreString;
    
    if (newScore / 10 == 0) {
        scoreString = [NSString stringWithFormat:@"0%i", newScore];
    } else {
        scoreString = [NSString stringWithFormat:@"%i", newScore];
    }
    
    scoreNode.text = scoreString;
}


-(void)goalWasScored {
    
    //      handles when a goal is scored
    
    self.score += 1;
    if (self.round == 5) {
        self.timeOfRound += 20;
    }
    
    [self updateScoreTo:self.score];
}


-(void)displayMessage:(NSString *)message forDuration:(NSTimeInterval)duration {
    
    // displays messages as an overlay
    
    SKLabelNode *messageNode = (SKLabelNode *)[self childNodeWithName:@"messageNode"];
    messageNode.text = message;
    
    SKAction *fadeAction = [SKAction sequence:@[
                                          [SKAction fadeInWithDuration:0.1],
                                          [SKAction fadeOutWithDuration:duration]]];
    
    [messageNode runAction:fadeAction];
}


-(void)startNewRound {
    
    //  starts a new round
    self.timerIsPaused = NO;
    [self createBall];
    [self resetBall];
}


-(void)endOfRound {
    // ends the round, adds new defenders, pauses the game briefly

    self.round += 1;
    self.timeOfRound = 300;
    
    // removes the ball between rounds
    SKSpriteNode *ball = (SKSpriteNode *)[self childNodeWithName:@"ball"];
    [ball removeFromParent];
    
    if (self.round == 6) {
        [self gameOver];
    } else if (self.round == 5) {
        [self displayMessage:[NSString stringWithFormat:@"Final Round"] forDuration:1.5];
    } else if (self.round == 2) {
        SKSpriteNode *defender2 = [SKSpriteNode spriteNodeWithImageNamed:@"redDefender"];
        defender2.xScale = 0.75f;
        defender2.yScale = defender2.xScale;
        defender2.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:defender2.frame.size.height / 2.0f + 7.0f];
        defender2.position = CGPointMake(100, self.frame.size.height * 4.0 / 5.0 - 15);
        defender2.physicsBody.dynamic = NO;
        defender2.name = @"defender2";
        [self addChild:defender2];
        
        [self displayMessage:[NSString stringWithFormat:@"Round %i", self.round] forDuration:1.5];

    } else if (self.round == 4) {
        SKSpriteNode *defender3 = [SKSpriteNode spriteNodeWithImageNamed:@"redDefender"];
        defender3.xScale = 0.75f;
        defender3.yScale = defender3.xScale;
        defender3.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:defender3.frame.size.height / 2.0f + 7.0f];
        defender3.position = CGPointMake(100, self.frame.size.height * 2.0 / 5.0 - 15);
        defender3.physicsBody.dynamic = NO;
        defender3.name = @"defender3";
        [self addChild:defender3];

        [self displayMessage:[NSString stringWithFormat:@"Round %i", self.round] forDuration:1.5];

    } else {
        [self displayMessage:[NSString stringWithFormat:@"Round %i", self.round] forDuration:1.5];

    }
    
    if (self.round != 6) {
        [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(startNewRound) userInfo:nil repeats:NO];
    }
    

}


-(void)gameStart {
    // sets up game properties like round and score, removes possible game over message, and pauses the game briefly
    
    SKNode *gameOverNode = [self childNodeWithName:@"gameOverNode"];
    [gameOverNode removeFromParent];
    
    self.timerIsPaused = YES;
    self.timeOfRound = 300;
    self.round = 1;
    self.score = 0;
    
    SKSpriteNode *defender2 = (SKSpriteNode *)[self childNodeWithName:@"defender2"];
    [defender2 removeFromParent];
    
    SKSpriteNode *defender3 = (SKSpriteNode *)[self childNodeWithName:@"defender3"];
    [defender3 removeFromParent];
    
    [self updateScoreTo:0];
    [self displayMessage:@"Round 1" forDuration:2.5];
    
    [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(startNewRound) userInfo:nil repeats:NO];
}


-(void)gameOver {
    // handles when the game ends, adds an semi-opaque overlay message, pauses the game and then restarts
    self.timerIsPaused = YES;
    
    SKNode *ball = [self childNodeWithName:@"ball"];
    [ball removeFromParent];
    
    SKSpriteNode *gameOverNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithWhite:1.0 alpha:0.9] size:self.frame.size];
    gameOverNode.position = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
    gameOverNode.zPosition = 1;
    gameOverNode.name = @"gameOverNode";
    
    SKLabelNode *gameOverMessageNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    gameOverMessageNode.text = @"GAME OVER";
    gameOverMessageNode.fontColor = [UIColor redColor];
    gameOverMessageNode.fontSize = 48;
    gameOverMessageNode.position = CGPointMake(0, 75);
    
    SKLabelNode *finalScoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    finalScoreNode.text = [NSString stringWithFormat:@"Final score is %i", self.score];
    finalScoreNode.fontSize = 32;
    finalScoreNode.position = CGPointMake(0, -50);
    finalScoreNode.fontColor = [UIColor blackColor];
    
    SKLabelNode *gameRestartNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
    gameRestartNode.text = @"Game will start over soon";
    gameRestartNode.fontSize = 24;
    gameRestartNode.fontColor = [UIColor blackColor];
    gameRestartNode.position = CGPointMake(0, -150);
    
    [gameOverNode addChild:gameOverMessageNode];
    [gameOverNode addChild:finalScoreNode];
    [gameOverNode addChild:gameRestartNode];
    
    [self addChild:gameOverNode];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(gameStart) userInfo:nil repeats:NO];
}



-(void)update:(CFTimeInterval)currentTime {
   
    // Called before each frame is rendered
    // checks if the ball is in the goal, moves defenders, reset ball if needed
    
    SKSpriteNode *ball = (SKSpriteNode *)[self childNodeWithName:@"ball"];
    SKNode *lowerGoalAreaNode = [self childNodeWithName:@"lowerGoalAreaNode"];
    
    BOOL ballHasLeftGoalArea = ![lowerGoalAreaNode containsPoint:ball.position];
    
    if (self.hasMadeShot && ballHasLeftGoalArea && self.durationOfShot > 30) {
//        NSLog(@"New round");
        self.durationOfShot = 0;
        [self resetBall];
    }

    if (ball.position.y > self.frame.size.height) {
//        NSLog(@"Mål!");
        [self displayMessage:@"Goal!" forDuration:1];
        [self resetBall];
        ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
        ball.physicsBody.angularVelocity = 0;
        [self goalWasScored];
    }
    
    
    // controls max rotation of the ball
    if (ball.physicsBody.angularVelocity > 7.0f){
        ball.physicsBody.angularVelocity = 7.0f;
    } else if (ball.physicsBody.angularVelocity < -7.0f){
        ball.physicsBody.angularVelocity = -7.0f;
    }
    
    // moves defenders, depending on the round
    float velocityFactor;
    switch (self.round) {
        case 1:
            velocityFactor = 1.0;
            break;
        case 2:
            velocityFactor = 1.0;
            break;
        case 3:
            velocityFactor = 1.5;
            break;
        case 4:
            velocityFactor = 1.5;
            break;
        case 5:
            velocityFactor = 2.0;
            break;
        default:
            velocityFactor = 1.0;
            break;
    }
    
    SKSpriteNode *defender1 = (SKSpriteNode *)[self childNodeWithName:@"defender1"];
    SKSpriteNode *defender2 = (SKSpriteNode *)[self childNodeWithName:@"defender2"];
    SKSpriteNode *defender3 = (SKSpriteNode *)[self childNodeWithName:@"defender3"];
    
    static float xDeltaDefender1 = 2.0f;
    static float xDeltaDefender2 = 3.0f;
    static float xDeltaDefender3 = -1.5;

    if (defender1.position.x > self.frame.size.width * 0.9f) {
        xDeltaDefender1 *= -1.0f;
    } else if (defender1.position.x < self.frame.size.width * 0.1f) {
        xDeltaDefender1 *= -1.0f;
    }
    
    defender1.position = CGPointMake(defender1.position.x + xDeltaDefender1 * velocityFactor, defender1.position.y);
    
    if (defender2.position.x > self.frame.size.width * 0.9f) {
        xDeltaDefender2 *= -1.0f;
    } else if (defender2.position.x < self.frame.size.width * 0.1f) {
        xDeltaDefender2 *= -1.0f;
    }
    
    defender2.position = CGPointMake(defender2.position.x + xDeltaDefender2 * velocityFactor, defender2.position.y);

    if (defender3.position.x > self.frame.size.width * 0.9f) {
        xDeltaDefender3 *= -1.0f;
    } else if (defender3.position.x < self.frame.size.width * 0.1f) {
        xDeltaDefender3 *= -1.0f;
    }
    
    defender3.position = CGPointMake(defender3.position.x + xDeltaDefender3 * velocityFactor, defender3.position.y);
}

@end
