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

@property int timeOfRound;
@property bool timerIsPaused;

@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        //
        //      initWithSize-metoden genererar bakgrund och spelplan, samt vissa andra element typ mål
        //
        
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
        scoreNode.position = CGPointMake(0, -20);
        scoreNode.fontSize = 30;
        scoreNode.name = @"scoreNode";
//        scoreNode.text = @"-1";
        
        [scoreHolderNode addChild:scoreTitleNode];
        [scoreHolderNode addChild:scoreNode];
        [self addChild:scoreHolderNode];
        
        // tid kvar i omgång
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
        
        
        // friktion,
        self.physicsBody.friction = 1.0f;
        
        // hållare för målet, skall inkludera en bild av målet, samt ett antal child nodes med physicsbodies för att simulera ett mål
        
        float alphaOfGoalNodes = 0.0f; // testing, skall vara = 0.0 i färdig app
        
        SKSpriteNode *goalContainer = [SKSpriteNode spriteNodeWithColor:[UIColor colorWithRed:0 green:0 blue:1.0f alpha:0.0f] size:CGSizeMake(150, 100)];
        goalContainer.position = CGPointMake(self.frame.size.width / 2.0f, self.frame.size.height - 30);
        [self addChild:goalContainer];
        
        // målgrafiken
        
        SKSpriteNode *goalImageSprite = [SKSpriteNode spriteNodeWithImageNamed:@"goalBW"];
        goalImageSprite.xScale = 0.65f;
        goalImageSprite.yScale = goalImageSprite.xScale;
        goalImageSprite.zPosition = 0.5;
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
        
        // en defender skapas här, de två andra i end OfRound-metoden, då de inte ska vara med i första leveln
        SKSpriteNode *defender1 = [SKSpriteNode spriteNodeWithImageNamed:@"redDefender"];
        defender1.xScale = 0.75f;
        defender1.yScale = defender1.xScale;
        defender1.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:defender1.frame.size.height / 2.0f + 7.0f];
        defender1.position = CGPointMake(200, self.frame.size.height * 3.0 / 5.0 - 15);
        defender1.physicsBody.dynamic = NO;
        defender1.name = @"defender1";
        [self addChild:defender1];
        
        
        
        
        
        // nod för meddelanden
        SKLabelNode *messageNode = [SKLabelNode labelNodeWithFontNamed:@"Futura Medium"];
        messageNode.name = @"messageNode";
        messageNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
        messageNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
        messageNode.position = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0 + 75.0);
        messageNode.fontSize = 50;
        messageNode.alpha = 0.0;
        [self addChild:messageNode];
        
        // sätter igång omgångstimern, men sätter pausproperien till YES eftersom spelet inte startar direkt
        self.timerIsPaused = YES;
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerCountdown) userInfo:nil repeats:YES];

        
        
        
    }
    return self;
}


-(void)createBall {
    // initiera en boll
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ballWithHolder"];
    ball.xScale = 0.75f;
    ball.yScale = ball.xScale;
    [ball setName:@"ball"];
    
    // ge bollen en physicsbody
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:23.0f];
    ball.physicsBody.dynamic = YES;
    ball.physicsBody.affectedByGravity = NO;
    ball.physicsBody.restitution = 0.17;
    ball.physicsBody.friction = 1.0;
    
    // bollen är ej ännu selected
    self.ballIsSelected = NO;
    
    [self addChild:ball];

}






-(void)timerCountdown {
    
    //      räknar ner tiden i en omgång. Timern avfyrar kontinuerligt, propertien timerIsPaused styr om tiden ska räknas ner. Är pausat mellan omgångar
    
    if (!self.timerIsPaused) {
        SKNode *roundHolderNode = [self childNodeWithName:@"roundHolderNode"];
        SKLabelNode *roundNode = [roundHolderNode childNodeWithName:@"roundNode"];
    //
        self.timeOfRound -= 1;
        NSString *displayTime;
        
        if (self.timeOfRound / 10 == 0) {
            displayTime = [NSString stringWithFormat:@"                %i.%i", self.timeOfRound / 10, self.timeOfRound % 10];
        } else {
            displayTime = [NSString stringWithFormat:@"%i.%i", self.timeOfRound / 10, self.timeOfRound % 10];
        }
   
        roundNode.text = displayTime;
        
        if (self.timeOfRound == 0) {
            self.timerIsPaused = YES;
            [self endOfRound];
        }
    }
}



-(void)resetBall {
   
    //      placerar bollen i målområdet
    
    
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];
    // se till att spelaren kan skjuta bollen
    self.hasMadeShot = NO;
    
    // slumpvis punkt
    float startX = arc4random_uniform(self.frame.size.width - 50.0) + 25.0;
    float startY = arc4random_uniform(25.0) + 50.0;
    // initera bollen i nedre målområdet
    
    
    ball.position = CGPointMake(startX, startY);
    ball.alpha = 1.0f;
    ball.physicsBody.angularVelocity = 0.0f;
    ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
}





-(void)didMoveToView:(SKView *)view {
    
	// för att skjuta iväg bollen
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [[self view] addGestureRecognizer:panGestureRecognizer];
    
    
	// starta spelet efter att panGestureRecognizer är initierad
    
    [self gameStart];
    //  [self resetBall];
    
}

// för att hantera skottet
-(void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];
    SKNode *lowerGoalAreaNode = [self childNodeWithName:@"lowerGoalAreaNode"];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchLocation = [recognizer locationInView:self.view];
        
        touchLocation = [self convertPointFromView:touchLocation];
        if ([ball containsPoint:touchLocation] && [lowerGoalAreaNode containsPoint:touchLocation]) {
            NSLog(@"Ball is touched");
            self.ballIsSelected = YES;
            self.originalBallPosition = touchLocation;
            
        }
        
    }

    else if (recognizer.state == UIGestureRecognizerStateEnded && self.ballIsSelected) { // && !self.hasMadeShot) {
        self.ballIsSelected = NO;
        self.hasMadeShot = YES;
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGVector velocityVector = CGVectorMake(velocity.x * 0.05, -velocity.y * 0.05);
        [ball.physicsBody applyImpulse:velocityVector];
    }
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
    
    //      hanterar att det blivit mål
    
    self.score += 1;
    if (self.round == 5) {
        self.timeOfRound += 20;
    }
    
    [self updateScoreTo:self.score];
}

-(void)displayMessage:(NSString *)message forDuration:(NSTimeInterval)duration {
    
    //      för att visa meddelanden ovanför spelgrafiken
    
    SKLabelNode *messageNode = [self childNodeWithName:@"messageNode"];
    messageNode.text = message;
    
    SKAction *fadeAction = [SKAction sequence:@[
                                          [SKAction fadeInWithDuration:0.1],
                                          [SKAction fadeOutWithDuration:duration]]];
    
    
    [messageNode runAction:fadeAction];
    
}


-(void)startNewRound {
    
    //      startar ny omgång
    
    self.timerIsPaused = NO;
    [self createBall];
    [self resetBall];
}


-(void)endOfRound {
    
    //      avslutar omgång, lägger till nya defenders, pausar spelet kort

    self.round += 1;
    self.timeOfRound = 300;
    
    // tar bort bollen mellan omgångarna
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];
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

    //      ställer in spelproperties som round och score, tar bort gameOver-meddelandet om spelaren redan spelat en omgång, samt pausar spelet kort
    
    SKNode *gameOverNode = [self childNodeWithName:@"gameOverNode"];
    [gameOverNode removeFromParent];
    
    self.timerIsPaused = YES;
    self.timeOfRound = 300;
    self.round = 1;
    self.score = 0;
    
    SKSpriteNode *defender2 = [self childNodeWithName:@"defender2"];
    [defender2 removeFromParent];
    
    SKSpriteNode *defender3 = [self childNodeWithName:@"defender3"];
    [defender3 removeFromParent];
    
//    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerCountdown) userInfo:nil repeats:YES];
  
    [self updateScoreTo:0];
    [self displayMessage:@"Round 1" forDuration:2.5];
    
    [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(startNewRound) userInfo:nil repeats:NO];

    
}

-(void)gameOver {
    
    //      hanterar när spelet tagit slut, lägger på ett meddelande över skärmen, pausar spelet, och startar om via gameStart-
    
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
   
    /* Called before each frame is rendered */
    
    //      update-metoden gör rutinkontroller på om bollen gått i mål, flyttar defenders, och kontrollerar om bollen stannat, och resetar den då
    
    
    
    SKSpriteNode *ball = [self childNodeWithName:@"ball"];
    if (self.hasMadeShot && ABS(ball.physicsBody.velocity.dx) < 15.0f && ABS(ball.physicsBody.velocity.dy) < 15.0f) {
        NSLog(@"New round");
        [self resetBall];
    }

    if (ball.position.y > self.frame.size.height) {
        NSLog(@"Mål!");
        [self displayMessage:@"Goal!" forDuration:1];
        
        ball.physicsBody.velocity = CGVectorMake(0.0f, 0.0f);
        ball.physicsBody.angularVelocity = 0;
        [self goalWasScored];


    }
    
    
    // hindra bollen från att få för stor rotation
    if (ball.physicsBody.angularVelocity > 7.0f){
        ball.physicsBody.angularVelocity = 7.0f;
    } else if (ball.physicsBody.angularVelocity < -7.0f){
        ball.physicsBody.angularVelocity = -7.0f;
    }
    
    // flytta defender, beronde på omgång
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
    
    SKSpriteNode *defender1 = [self childNodeWithName:@"defender1"];
    SKSpriteNode *defender2 = [self childNodeWithName:@"defender2"];
    SKSpriteNode *defender3 = [self childNodeWithName:@"defender3"];
    
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
