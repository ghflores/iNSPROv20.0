//
//  CMGDSecondViewController.h
//  iNSPro1.0
//
//  Created by German H Flores on 5/28/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#include <fstream>
#import "detectSteps.h"

@class FliteTTS;

@interface CMGDSecondViewController : UIViewController
{
    //Following variables used for datalogging
    NSMutableString *calibrationdata2log;
    NSArray *paths;
    NSString *fullPath;
    NSString *documentsDirectory;
    
    int fileCounter;
    
    //Text to Speech
    FliteTTS *fliteEngine;
    
    //State flags
    bool stopWritting;
    bool calibrating;
    bool firstTime;
    int  phonePosition;
    bool veryFirstTime;
    bool appRunningFirstTime;
    
    //Motion manager and queue
    CMMotionManager *mManager;
    NSOperationQueue *gyroQueue;
    //CoreMotion attitude
    CMAttitude *initialAttidute;
    NSTimeInterval timestampReference;
    CMAcceleration gravityVector;
    CMAttitude *currentAttitude;
    CMRotationRate rotationRate;
    
    //Real-time processing of steps
    DetectSteps *rsSteps;
    int stepCounter;
    int previousStepCounter;
    bool spokeInstructions;
    int runningIndex;
}

//Outlets
@property (weak, nonatomic) IBOutlet UILabel *averageStepThreshold;
@property (weak, nonatomic) IBOutlet UILabel *calibrationStatus;



//Action
- (IBAction)calibrateButton:(id)sender;
- (IBAction)defaultButton:(id)sender;


@end
