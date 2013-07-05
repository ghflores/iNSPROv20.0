//
//  CMGDFirstViewController.h
//  iNSPro1.0
//
//  Created by German H Flores on 5/28/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <fstream>
#import <CoreMotion/CoreMotion.h>
#import "pcaObj.h"
#import "hmmObject.h"
#import "detectSteps.h"
#include "Parameters.h"

@class FliteTTS;

@interface CMGDFirstViewController : UIViewController
{
    
    //Motion manager and queue
    CMMotionManager *mManager;
    NSOperationQueue *gyroQueue;
    
    //CoreMotion attitude
    CMAttitude *initialAttidute;
    NSTimeInterval timestampReference;
    CMAcceleration gravityVector;
    CMAttitude *currentAttitude;
    CMRotationRate rotationRate;
    
    //Data logging the gyroscope data for turning: hmm and pca
    NSMutableString *data2logStr_direction;
    NSArray *paths_direction;
    NSString *documentsDirectory_direction;
    NSDateFormatter *dateFormatter_direction;
    NSString *dateString_direction;
    NSString *fullPath_direction;
    
    //Variables used for datalogging for step counting
    NSMutableString *data2logStr_steps;
    NSArray *paths_steps;
    NSString *documentsDirectory_steps;
    NSDateFormatter *dateFormatter_steps;
    NSString *dateString_steps;
    NSString *fullPath_steps;
    
    //Variables used for datalogging for step counting
    NSMutableString *data2logStr_log;
    NSArray *paths_log;
    NSString *documentsDirectory_log;
    NSDateFormatter *dateFormatter_log;
    NSString *dateString_log;
    NSString *fullPath_log;
    
    //Flags for state of the system
    int  phonePosition;
    bool stopWritting;
    bool systemRunning;
    bool systemPreviouslyExecuted;
    bool firstTime;
    bool appRunningFirstTime;
    bool systemStopped;
    bool appRunning;
    
    //Text to Speech Library variables
    FliteTTS *fliteEngine;
    
    //Detection step variables
    double jayalathAlgorithThreshold;
    cv::Mat numberOfSteps;
    int stepIndex;
    
    //Direction variables
    int totalNumberOfInstructions;
    NSMutableArray *turnInstructions;
    int turnIndex;
    
    //Real-time processing of steps
    DetectSteps *rsSteps;
    int stepCounter;
    int previousStepCounter;
    bool spokeInstructions;
    
    //Master indeces
    int realTimeStepIndex;
    int realTimeTurnIndex;
    int extraSteps;
    
    bool firstTimeToSpeak;
    
    bool userManualReset;
    
    int clickTurn;
    
    cv::Mat rollG, pitchG, yawG, tG;
    
    int runningIndex;
    int previosDetectedIndex;
    
    bool veryFirstTime;
    
    
    int stepsTowait;
    
    bool haltSystem;
    
}

//Actions
- (IBAction)startButton:(id)sender;
- (IBAction)stopButton:(id)sender;
- (IBAction)onOffButton:(id)sender;
- (IBAction)directionsButton:(id)sender;
- (IBAction)resetButton:(id)sender;


//Outlets
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onOffButton;
@property (weak, nonatomic) IBOutlet UIButton *directionsButton;
@property (weak, nonatomic) IBOutlet UILabel *totalStepCount;
@property (weak, nonatomic) IBOutlet UILabel *avgStepTime;
@property (weak, nonatomic) IBOutlet UILabel *phonePositionLabel;

@property (weak, nonatomic) IBOutlet UILabel *liveStepLabel;
@property (weak, nonatomic) IBOutlet UILabel *onlineTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *userRTTurnLabel;

@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UILabel *stepsToWalk;



@end
