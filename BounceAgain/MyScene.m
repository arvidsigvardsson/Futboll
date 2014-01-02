//
//  MyScene.m
//  BounceAgain
//
//  Created by Arvid on 2013-12-16.
//  Copyright (c) 2013 Arvid. All rights reserved.
//

#import "MyScene.h"

@interface MyScene ()

@property BOOL ballIsSelected;
@property CGPoint originalBallPosition;
@property BOOL hasMadeShot; // för att veta om spelaren skjutit bollen och hindra denne från fler skott i samma omgång
@property int score;
@property int round;

@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
    
        self.score = 0;
        self.round = 1;
        
        
        // bakgrund och spelplan
        self.backgroundColor = [SKColor colorWithRed:255.0/255.0f green:134.0/255.0f blue:25.0/255.0f alpha:1];
        
        // målområden
        CGMutablePathRef lowerGoalAreaPath = CGPathCreateMutable();
        CGPathMoveToPoint(lowerGoalAreaPath, nil, 3.0f, 3.0f);
        CGPathAddArc(lowerGoalAreaPath, nil, self.frame.size.width / 2.0f, 3.0f, self.frame.size.width / 2.0f - 6, 0, M_PI, 0);
        
        SKShapeNode *lowerGoalAreaNode = [[SKShapeNode alloc] init];
        lowerGoalAreaNode.path = lowerGoalAreaPath;
        lowerGoalAreaNode.lineWidth = 5;
        lowerGoalAreaNode.fillColor = [UIColor colorWithRed:0.0f green:145.0 / 255.0f blue:178.0 / 255.0 alpha:1.0f];
        [self addChild:lowerGoalAreaNode];
        
        CGMutablePathRef upperGoalAreaPath = CGPathCreateMutable();
        CGPathMoveToPoint(upperGoalAreaPath, nil, 3.0f, self.frame.size.height - 3.0f);
        CGPathAddArc(upperGoalAreaPath, nil, self.frame.size.width / 2.0f, self.frame.size.height - 3.0f, self.frame.size.width / 2.0f - 6, 0, M_PI, 1);
        
        SKShapeNode *upperGoalAreaNode = [[SKShapeNode alloc] init];
        upperGoalAreaNode.path = upperGoalAreaPath;
        upperGoalAreaNode.lineWidth = 5;
        upperGoalAreaNode.fillColor = [UIColor colorWithRed:0.0f green:145.0 / 255.0f blue:178.0 / 255.0 alpha:1.0f];
        [self addChild:upperGoalAreaNode];
        
        // mittlinje
        CGMutablePathRef midlinePath = CGPathCreateMutable();
        CGPathMoveToPoint(midlinePath, nil, 0.0f, self.frame.size.height / 2.0f);
        CGPathAddLineToPoint(midlinePath, nil, self.frame.size.width, self.frame.size.height / 2.0f);
        
        SKShapeNode *midlineNode = [[SKShapeNode alloc] init];
        midlineNode.path = midlinePath;
        midlineNode.lineWidth = 5.0f;
        [self addChild:midlineNode];
        
        // sid- och baslinjer
        SKShapeNode *sidelines = [[SKShapeNode alloc] init];
        sidelines.path = CGPathCreateWithRect(self.frame, nil);
        sidelines.lineWidth = 10.0f;
        [self addChild:sidelines];
        
        
        // textnoder, för poängräkning, etc
        SKSpriteNode *scoreHolderNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.0] size:CGSizeMake(75, 75)];
        scoreHolderNode.position = CGPointMake(self.frame.size.width - 50, self.frame.size.height - 33);
        scoreHolderNode.name = @"scoreHolderNode";
        
        SKLabelNode *scoreTitleNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        scoreTitleNode.fontSize = 15;
        scoreTitleNode.text = @"SCORE";
        scoreTitleNode.position = CGPointMake(0, 10);
        
        SKLabelNode *scoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        scoreNode.position = CGPointMake(0, -25);
        scoreNode.fontSize = 40;
        scoreNode.name = @"scoreNode";
//        scoreNode.text = @"-1";
        
        [scoreHolderNode addChild:scoreTitleNode];
        [scoreHolderNode addChild:scoreNode];
        [self addChild:scoreHolderNode];
        
        // rounds
        SKSpriteNode *roundHolderNode = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.0] size:CGSizeMake(75, 75)];
        roundHolderNode.position = CGPointMake(50, self.frame.size.height - 33);
        roundHolderNode.name = @"roundHolderNode";
        
        SKLabelNode *roundTitleNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        roundTitleNode.fontSize = 15;
        roundTitleNode.text = @"ROUND";
        roundTitleNode.position = CGPointMake(0, 10);
        
        SKLabelNode *roundNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        roundNode.position = CGPointMake(0, -25);
        roundNode.fontSize = 40;
        roundNode.name = @"roundNode";
//        scoreNode.position = CGPointMake(100.0f, 100.0f);
        
        [roundHolderNode addChild:roundTitleNode];
        [roundHolderNode addChild:roundNode];
        [self addChild:roundHolderNode];
        
        
        
        
        // skapa spelyta, hela skärmen, ingen gravitation, kontaktdelegat för att registrera att bollen gått i mål
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        // borderbody skall ha ett "hål" vid mållinjen för att bollen vid höj hastighet inte ska studsa tillbaka, utan fortsätta upp utanför skärmen
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
        
        
        // friktion, ************  ska nog ändras ********************
        self.physicsBody.friction = 0.0f;
        
        // initiera en boll
        SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ballWithHolder"];
        ball.xScale = 0.75f;
        ball.yScale = ball.xScale;
        ball.alpha = 0.0f; // metoden beginRound gör bollen synlig och ger den en position
        [ball setName:@"ball"];
        
        // ge bollen en physicsbody
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:23.0f];
        ball.physicsBody.dynamic = YES;
        ball.physicsBody.affectedByGravity = NO;
        
        // bollen är ej ännu selected
        self.ballIsSelected = NO;
        
        [self addChild:ball];
        
        

        
        // hållare för målet, skall inkludera en bild av målet, samt ett antal child nodes med physicsbodies för att simulera ett mål
        
        float alphaOfGoalNodes = 0.0f; // testing
        
        SKSpriteNode *goalContainer = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0 green:0 blue:1.0f alpha:0.0f] size:CGSizeMake(150, 100)];
        goalContainer.position = CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height - 30);
        [self addChild:goalContainer];
        
        // målgrafiken
        
        SKSpriteNode *goalImageSprite = [SKSpriteNode spriteNodeWithImageNamed:@"goalBW"];
        goalImageSprite.xScale = 0.65f;
        goalImageSprite.yScale = goalImageSprite.xScale;
        [goalContainer addChild:goalImageSprite];
        
        // noder för stolpar
        SKShapeNode *leftGoalPost = [[SKShapeNode alloc] init];
        leftGoalPost.path = CGPathCreateWithRoundedRect(CGRectMake(-70.0f, -25.0f, 15.0f, 50.0f), 5.0, 5.0, nil);
        leftGoalPost.fillColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alphaOfGoalNodes];
        leftGoalPost.lineWidth = 0.0f;
//        leftGoalPost.position = CGPointMake(-75.0, -25.0);
        leftGoalPost.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:leftGoalPost.path];
        [goalContainer addChild:leftGoalPost];
        
        SKShapeNode *rightGoalPost = [[SKShapeNode alloc] init];
        rightGoalPost.path = CGPathCreateWithRoundedRect(CGRectMake(75.0 - 20.0f, -25.0f, 15.0f, 50.0f), 5.0, 5.0, nil);
        rightGoalPost.fillColor = [SKColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:alphaOfGoalNodes];
        rightGoalPost.lineWidth = 0.0f;
//        rightGoalPost.position = CGPointMake(75.0-30.0, -25.0);
        rightGoalPost.physicsBody = [SKPhysicsBody bodyWithEdgeChainFromPath:rightGoalPost.path];
        [goalContainer addChild:rightGoalPost];
        
        // försvarare
        SKSpriteNode *defender = [SKSpriteNode spriteNodeWithImageNamed:@"defender"];
        defender.xScale = 0.75f;
        defender.yScale = defender.xScale;
        defender.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:defender.frame.size.height / 2.0f + 7.0f];
        defender.position = CGPointMake(200, 200);
        defender.physicsBody.dynamic = NO;
        defender.name = @"defender";
        [self addChild:defender];
        
        
        // nod för meddelanden
        SKLabelNode *messageNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        messageNode.name = @"messageNode";
        messageNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
        messageNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        messageNode.position = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0 + 75.0);
        messageNode.fontSize = 75;
        messageNode.alpha = 0.0;
        [self addChild:messageNode];
        
        
//        [self beginRound];
        
        [self updateScoreTo:0];
        [self updateRoundTo:1];
        [self displayMessage:@"Första rundan" forDuration:3];
        
        
    }
    return self;
}

// metod för start av omgång
-(void)beginRound {
    NSLog(@"beginRound");
    
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];
    // se till att spelaren kan skjuta bollen
    self.hasMadeShot = NO;
    
    float startX = arc4random_uniform(self.frame.size.width - 50.0) + 25.0;
    float startY = arc4random_uniform(25.0) + 50.0;
    // initera bollen i nedre målområdet
    
    //NSLog(@"lowergoalareaposition = %f, %f", [lower)
    
//    ball.position = CGPointMake(50.0f, 50.0f);
    ball.position = CGPointMake(startX, startY);
    ball.alpha = 1.0f;
    ball.physicsBody.angularVelocity = 0.0f;
    ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
}





-(void)didMoveToView:(SKView *)view {
    
	// för att skjuta iväg bollen
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[self view] addGestureRecognizer:panGestureRecognizer];
    
    // för att reseta under utveckling
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
    [[self view] addGestureRecognizer:pinchGestureRecognizer];
    
    NSLog(@"didMoveToView-metoden");
    
//    UIScreenEdgePanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer ]
	
	// starta spelet
    [self beginRound];
}

// för att hantera skottet
-(void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchLocation = [recognizer locationInView:self.view];
        
        touchLocation = [self convertPointFromView:touchLocation];
        if ([ball containsPoint:touchLocation]) {
            NSLog(@"Ball is touched");
            self.ballIsSelected = YES;
            self.originalBallPosition = touchLocation;
            
        }
        
    }

    else if (recognizer.state == UIGestureRecognizerStateEnded && self.ballIsSelected && !self.hasMadeShot) {
        self.ballIsSelected = NO;
        self.hasMadeShot = YES;
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGVector velocityVector = CGVectorMake(velocity.x * 0.05, -velocity.y * 0.05);
        [ball.physicsBody applyImpulse:velocityVector];
    }
}


-(void)handlePinchFrom:(UIPinchGestureRecognizer *)recognizer {
    // reseta under utveckling
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self beginRound];
    }
}


-(void)updateRoundTo:(int)newRound {
    SKNode *roundHolderNode = [self childNodeWithName:@"roundHolderNode"];
    SKLabelNode *roundNode = [roundHolderNode childNodeWithName:@"roundNode"];
    
    NSString *roundString;
    
    if (newRound / 10 == 0) {
        roundString = [NSString stringWithFormat:@"0%i", newRound];
    } else {
        roundString = [NSString stringWithFormat:@"%i", newRound];
    }
    
    roundNode.text = roundString;
}


-(void)updateScoreTo:(int)newScore {
    NSLog(@"score = %i", newScore);
    
    SKNode *scoreHolderNode = [self childNodeWithName:@"scoreHolderNode"];
    SKLabelNode *scoreNode = [scoreHolderNode childNodeWithName:@"scoreNode"];
    
    NSLog(@"poängnodens namn: %@", scoreNode.name);
    
    NSString *scoreString;
    
    if (newScore / 10 == 0) {
        scoreString = [NSString stringWithFormat:@"0%i", newScore];
    } else {
        scoreString = [NSString stringWithFormat:@"%i", newScore];
    }
    
    scoreNode.text = scoreString;
    
}

-(void)goalWasScored {
    self.score += 1;
    [self updateScoreTo:self.score];
}

-(void)displayMessage:(NSString *)message forDuration:(NSTimeInterval)duration {
    SKLabelNode *messageNode = [self childNodeWithName:@"messageNode"];
    messageNode.text = message;
//    messageNode.alpha = 1.0;
    
    SKAction *fadeAction = [SKAction sequence:@[
                                          [SKAction fadeInWithDuration:duration / 3.0],
                                          [SKAction fadeOutWithDuration:duration]]];
    
    
    [messageNode runAction:fadeAction];
    
}



-(void)update:(CFTimeInterval)currentTime {
    
    // testing
//    NSLog(@"ball velocity:  dx = %f     dy = %f", self.ball.physicsBody.velocity.dx, self.ball.physicsBody.velocity.dy);
    
    /* Called before each frame is rendered */
    
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];
    SKSpriteNode *defender = [self childNodeWithName:@"defender"];
    if (self.hasMadeShot && ABS(ball.physicsBody.velocity.dx) < 10.0f && ABS(ball.physicsBody.velocity.dy) < 10.0f) {
        NSLog(@"New round");
        [self beginRound];
    }
    
    
    
    // detektera mål
//    if ([self.ballRegistrationNode intersectsNode:self.goalRegistrationNode]) {
//        NSLog(@"Mål!");
//        self.ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
//        self.ball.physicsBody.angularVelocity = 0;
//    }

    if (ball.position.y > self.frame.size.height) {
        NSLog(@"Mål!");
        [self displayMessage:@"Goal!" forDuration:1];
        
        ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
        ball.physicsBody.angularVelocity = 0;
        [self goalWasScored];


    }
    
    
    // hindra bollen från att få för stor rotation
//    NSLog(@"Ang vel = %f", self.ball.physicsBody.angularVelocity);
    if (ball.physicsBody.angularVelocity > 7.0f){
        ball.physicsBody.angularVelocity = 7.0f;
    } else if (ball.physicsBody.angularVelocity < -7.0f){
        ball.physicsBody.angularVelocity = -7.0f;
    }
    
    // detektera kollision med spikesnode
//    if ([self.ball intersectsNode:self.spikesNode]) {
//        self.ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
//        SKAction *fadeAction =[SKAction fadeOutWithDuration:0.1];
//        [self.ball runAction:fadeAction];
//    }
    
    // flytta defender
    static float xDeltaDefender = 2.0f;
    if (defender.position.x > self.frame.size.width * 0.9f) {
        xDeltaDefender *= -1.0f;
    } else if (defender.position.x < self.frame.size.width * 0.1f) {
        xDeltaDefender *= -1.0f;
    }
    
    
    defender.position = CGPointMake(defender.position.x + xDeltaDefender, defender.position.y);
    
}

@end
