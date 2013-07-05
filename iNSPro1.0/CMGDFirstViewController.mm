//
//  CMGDFirstViewController.m
//  iNSPro1.0
//
//  Created by German H Flores on 5/28/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#import "CMGDFirstViewController.h"
#import "FliteTTS.h"
#include <pthread.h>

@interface CMGDFirstViewController ()

@end

@implementation CMGDFirstViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setMultipleTouchEnabled:YES];
	
//Disable autolock
    UIApplication *thisApp = [UIApplication sharedApplication];
    thisApp.idleTimerDisabled = YES;
    
//Set background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.jpg"]];
    
//Initialize System's State flags, constant variables and object variables
    
    //Only initialized once
    appRunningFirstTime = true;
    veryFirstTime = false;
    runningIndex = -1;
    previosDetectedIndex = 0;
    stepsTowait = 0;
    
    [self initializeSystemStateVariables];
    
    
//Initialize queue
    gyroQueue = [NSOperationQueue currentQueue];
    
//Initialize temporary file paths for data logging
    [self initializeCSVFilePaths];
    [self initializeLogFilePath];
    
//Set the text to speech system
    fliteEngine = [[FliteTTS alloc] init];
    [fliteEngine setPitch:FLITENGINE_PITCH variance:FLITENGINE_VARIANCE speed:FLITENGINE_SPEED];
    [fliteEngine setVoice:@"cmu_us_slt"];
    [fliteEngine speakText:@"Welcome."];
    
//NSNotification from App delegate
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(update:) name: @"UpdateUINotification" object: nil];
    
//Load user settings from file
    [self loadUserSettings];
    
}

//System's State variables
- (void) initializeSystemStateVariables {
    
    phonePosition = NONE;               //Determines the position of the iPhone
    stopWritting = false;               //Used so that information is not written to the file after the queue has stopped
    systemPreviouslyExecuted = false;   //Flag used to reset the system after it has previously ran. To reset all the variables
    systemRunning = false;
    firstTime = true;
    systemStopped = false;               //Flag to know that the user has either pressed the Stop button or double clicked the remote to stop
    appRunning = false;                 //Flag used for the remote control to know if the first or second double clicks are start or stop
    
    //Step detection variables
    
    //Initialize coremotion attitudes
   // initialAttidute = nil;
    
    //Direction variables
    totalNumberOfInstructions = 0;
    
    spokeInstructions = false;
    firstTimeToSpeak = false;
    userManualReset = false;
    
    //stepCounter = 0;
    clickTurn = 0;
    
    stepCounter = 0;
    
    haltSystem = false;
    
}

//Initialize CSV file paths for logging of gyroscope data for calculating steps and direction
- (void) initializeCSVFilePaths {
    
//Create and get full path for Gyroscope CVS file for directions
    data2logStr_direction = [[NSMutableString alloc] init];
    paths_direction = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory_direction = [paths_direction objectAtIndex:0];
    dateFormatter_direction = [[NSDateFormatter alloc] init];
    [dateFormatter_direction setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter_direction setDateStyle:NSDateFormatterShortStyle];
    
    //Some filesystems hate colons
    dateString_direction = [[dateFormatter_direction stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    
    //Remove spaces
    dateString_direction = [dateString_direction stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    dateString_direction = [dateString_direction stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    fullPath_direction = [documentsDirectory_direction stringByAppendingPathComponent:[NSString stringWithFormat:@"gyro_%@.csv",dateString_direction, nil]];
    
    
//Create and get full path for Gyroscope CVS file for steps
    data2logStr_steps = [[NSMutableString alloc] init];
    paths_steps = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory_steps = [paths_steps objectAtIndex:0];
    dateFormatter_steps = [[NSDateFormatter alloc] init];
    [dateFormatter_steps setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter_steps setDateStyle:NSDateFormatterShortStyle];
    
    // Some filesystems hate colons
    dateString_steps = [[dateFormatter_steps stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    
    //Remove spaces
    dateString_steps = [dateString_steps stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    dateString_steps = [dateString_steps stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    fullPath_steps = [documentsDirectory_steps stringByAppendingPathComponent:[NSString stringWithFormat:@"steps_%@.csv",dateString_steps, nil]];
}

- (void) initializeLogFilePath {
    
    //Create a Log of everything for debuggin purposes
    data2logStr_log = [[NSMutableString alloc] init];
    paths_log = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory_log = [paths_log objectAtIndex:0];
    dateFormatter_log = [[NSDateFormatter alloc] init];
    [dateFormatter_log setTimeStyle:NSDateFormatterLongStyle];
    [dateFormatter_log setDateStyle:NSDateFormatterShortStyle];
    
    // Some filesystems hate colons
    dateString_log = [[dateFormatter_log stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    
    //Remove spaces
    dateString_log = [dateString_log stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    dateString_log = [dateString_log stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    fullPath_log = [documentsDirectory_log stringByAppendingPathComponent:[NSString stringWithFormat:@"log_%@.txt",dateString_log, nil]];
}

//Receive notification from AppDelegate once the application has restarted in order to reactive the remote controls
-(void)update:(NSNotification*)notification{
    
    if (appRunningFirstTime) {
        appRunningFirstTime = !appRunningFirstTime;
    } else {
        [fliteEngine speakText:@"Welcome back."];
    }
}

//Load user settings. The setting is the threshold from the calibration step
- (void) loadUserSettings {
    
    NSArray *userSettingsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *userSettingsDocumentsDirectory = [userSettingsPath objectAtIndex:0];
    NSString *userSettingsFullPath = [userSettingsDocumentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"userSettings.usr", nil]];
    std::string *userSettingsFileName = new std::string([userSettingsFullPath UTF8String]);
    char *charFileName = (char*)userSettingsFileName->c_str();
    std::string record;
    
    //Open read stream
    std::ifstream myfile (charFileName);
    
    //Check to see if file exists. If not, the use average default value of 0.4
    if (myfile) {
        if (myfile.is_open()) {
            while ( myfile.good() ) {
                getline (myfile,record);
            }
            myfile.close();
        }
        
        char *thresholdSetting = strtok ((char*)record.c_str(),",");
        jayalathAlgorithThreshold = atof(thresholdSetting);
    } else {
        jayalathAlgorithThreshold = DEFAULTUSERSTEPTIME;
    }
    
    _avgStepTime.text = [NSString stringWithFormat:@"Avg step time: %f sec", jayalathAlgorithThreshold];
    
    [self writeLogToDisk: [NSString stringWithFormat:@"User's single step time loaded: %f sec", jayalathAlgorithThreshold]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Save gyroscope data as CSV format for the direction
- (void) writeDirectionsCSVDataToDisk:(double)time :(double)roll :(double)pitch :(double)yaw {
    
    [data2logStr_direction appendString:[NSString stringWithFormat:@"%f,", time]];
    [data2logStr_direction appendString:[NSString stringWithFormat:@"%f,", roll]];
    [data2logStr_direction appendString:[NSString stringWithFormat:@"%f,", pitch]];
    [data2logStr_direction appendString:[NSString stringWithFormat:@"%f,", yaw]];
    [data2logStr_direction appendString:[NSString stringWithFormat:@"\n"]];
    
    [data2logStr_direction writeToFile:fullPath_direction atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}

//Save gyroscope data as CSV format for the steps
- (void) writeStepsCSVDataToDisk:(double)time :(double)rx :(double)ry :(double)rz {
    
    [data2logStr_steps appendString:[NSString stringWithFormat:@"%f,", time]];
    [data2logStr_steps appendString:[NSString stringWithFormat:@"%f,", rx]];
    [data2logStr_steps appendString:[NSString stringWithFormat:@"%f,", ry]];
    [data2logStr_steps appendString:[NSString stringWithFormat:@"%f,", rz]];
    [data2logStr_steps appendString:[NSString stringWithFormat:@"\n"]];
    
    [data2logStr_steps writeToFile:fullPath_steps atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}

- (void) writeLogToDisk:(NSString*)data {
    
    [data2logStr_log appendString:data];
    [data2logStr_log writeToFile:fullPath_log atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}

- (void) start {
    
    [self writeLogToDisk: @"Start Function\n"];
    
    //Disable tabBar so the user does not press it by accident
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    
    //Reset system only if the system has been previously stopped
    if (systemPreviouslyExecuted) {
        [self resetSystem];
        [self writeLogToDisk: @" System previously executed, so reseting all variables\n"];
    }
    //Cannot press start again if the system is currently running
    if (!systemRunning) {
        
        //System running so cannot star over again until system restarts
        systemRunning = true;
        
        //Disable start button so user does not press it again while system running
        _startButton.enabled = false;
        
        //Play "Start" voice to indicate the start button or control has started
        [fliteEngine speakText:@"Start"];
        
        //Initialize motion manager and update interval. Do to the ifs and the write to the log file, the maximum rate is 70. However, it was observed that at higher data rates, complete turns are missed since now we have more readings between PI/4 and (3/4)PI. Through testing, 20 recordings per second seems to be ok, allowing the system to detect completer turns
        mManager = [[CMMotionManager alloc] init];
        mManager.deviceMotionUpdateInterval = 1.0/20.0;
        
        [self writeLogToDisk: @" Device motion update Interval is: 20 times per second\n"];
        
        //Make sure the gyroscope is available
        if (mManager.gyroAvailable) {
            
            [self writeLogToDisk: @" Gyro available so queue will start\n"];
            
            [mManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:gyroQueue withHandler:^(CMDeviceMotion *motion, NSError *error){
                
                NSTimeInterval time = mManager.deviceMotion.timestamp;
                
                //Cache the reference attitude
                if (initialAttidute == nil) {
                    initialAttidute = mManager.deviceMotion.attitude;
                }
                
                //First time, store initial time in order to have the offset and start at 0
                if (firstTime) {
                    timestampReference = time;
                    time = timestampReference;
                    firstTime = false;
                    
                    //Get the gravity vector
                    gravityVector = mManager.deviceMotion.gravity;
                    
                    //TODO: Need to deal with NONE!!!!!!!!
                    //Get initial position of the iPhone
                    if (abs(gravityVector.x*100.0) > ORIENTATION_THRESHOLD) {
                        phonePosition = ONSIDE;
                        _phonePositionLabel.text = @"Phone position: On side";
                        [self writeLogToDisk:@" Phone initial position: On side\n"];
                    }else if (abs(gravityVector.y*100.0) > ORIENTATION_THRESHOLD) {
                        phonePosition = STANDINGUP;
                        _phonePositionLabel.text = @"Phone position: Standing up";
                        [self writeLogToDisk:@" Phone initial position: Standing up\n"];
                    } else if (abs(gravityVector.z*100.0) >= ORIENTATION_THRESHOLD){
                        phonePosition = ONHAND;
                        _phonePositionLabel.text = @"Phone position: On hand";
                        [self writeLogToDisk:@" Phone initial position: On hand\n"];
                    } else {
                        phonePosition = NONE;
                        _phonePositionLabel.text = @"Phone position: None";
                        [self writeLogToDisk:@" Phone intial position: None\n"];
                    }
                    
                
                } else {
                    
                    time = time - timestampReference;
                    
                    currentAttitude = mManager.deviceMotion.attitude;
                    rotationRate = mManager.deviceMotion.rotationRate;
                    
                    //Check to see if the y-axis is pointing in the direction of gravity. If this is the case,
                    //then let's avoid singularity by making the reference frame start at 0,0,0. Doing so, makes
                    //the reference frame be the position of the iphone. So in this case the roll is changing.
                    //Otherwise, the yaw values changes since we are making the reference frame be
                    //CMAttitudeReferenceFrameXArbitraryZVertical
                    //Check for either direction, up or down
                    if (abs(gravityVector.y*100.0) > ORIENTATION_THRESHOLD) {
                        //NSLog(@"Vertical position");
                        
                        //Only need to do this when the phone is held vertically in order to avoid singularity
                        //Make reference start at 0, 0, 0
                        [currentAttitude multiplyByInverseOfAttitude:initialAttidute];
                    }
                    
                    //Display time to the iphone screen
                    _timeLabel.text = [NSString stringWithFormat:@"Time: %f", time];
                    
                    //There is a delay when the device motion is stopped. The queue keeps getting filled with the same values. So to avoid that, stopWritting flag is checked in order to not write the repetitive data
                    if (!stopWritting) {
                        
                        //Save to log file in the following order: rotationrate X, rotationrate Y, rotationrate Z
                        [self writeStepsCSVDataToDisk:time:rotationRate.x :rotationRate.y :rotationRate.z];
                        
                        //Save to log file in the following order: roll, pitch, yaw
                        //Phone is upside down so invert roll sign. For all other phone positions, the sign is the same regardless of position
                        if (gravityVector.y*100.0 > -ORIENTATION_THRESHOLD) {
                            [self writeDirectionsCSVDataToDisk:time:-currentAttitude.roll:currentAttitude.pitch:currentAttitude.yaw];
                            
                        }else {
                            [self writeDirectionsCSVDataToDisk:time:currentAttitude.roll:currentAttitude.pitch:currentAttitude.yaw];
                        }
                        
                    }
                    
                }
            }];
        }
    }
}



- (void) realTimeStart {
    
   // gyroQueue = [NSOperationQueue currentQueue];
    [self initializeSystemStateVariables];
        
        //Initialize motion manager and update interval. Do to the ifs and the write to the log file, the maximum rate is 70. However, it was observed that at higher data rates, complete turns are missed since now we have more readings between PI/4 and (3/4)PI. Through testing, 20 recordings per second seems to be ok, allowing the system to detect completer turns
        mManager = [[CMMotionManager alloc] init];
        mManager.deviceMotionUpdateInterval = 1.0/20.0;
        
        //Make sure the gyroscope is available
        if (mManager.gyroAvailable) {
            
            [mManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:gyroQueue withHandler:^(CMDeviceMotion *motion, NSError *error){
                
                if ([gyroQueue operationCount] < 2) {
                
                
                std::cout << "Thread ID: " << [gyroQueue operationCount] << std::endl;
                
                
                NSTimeInterval time = mManager.deviceMotion.timestamp;
                
                //Cache the reference attitude
                if (initialAttidute == nil) {
                    initialAttidute = mManager.deviceMotion.attitude;
                }
                
                //First time, store initial time in order to have the offset and start at 0
                if (firstTime) {
                    
                    firstTime = false;
                    
                    //Get the gravity vector
                    gravityVector = mManager.deviceMotion.gravity;
                    
                    //TODO: Need to deal with NONE!!!!!!!!
                    //Get initial position of the iPhone
                    if (abs(gravityVector.x*100.0) > ORIENTATION_THRESHOLD) {
                        phonePosition = ONSIDE;
                        _phonePositionLabel.text = @"Phone position: On side";
                        //[self writeLogToDisk:@" Phone initial position: On side\n"];
                    }else if (abs(gravityVector.y*100.0) > ORIENTATION_THRESHOLD) {
                        phonePosition = STANDINGUP;
                        _phonePositionLabel.text = @"Phone position: Standing up";
                        //[self writeLogToDisk:@" Phone initial position: Standing Up\n"];
                    } else if (abs(gravityVector.z*100.0) >= ORIENTATION_THRESHOLD){
                        phonePosition = ONHAND;
                        _phonePositionLabel.text = @"Phone position: On hand";
                        //[self writeLogToDisk:@" Phone initial position: On hand\n"];
                    } else {
                        phonePosition = NONE;
                        _phonePositionLabel.text = @"Phone position: None";
                        //[self writeLogToDisk:@" Phone initial position: None\n"];
                    }
                    
                    //Only allocate one time for the entire run
                    if (!veryFirstTime) {
                        
                        timestampReference = time;
                        time = timestampReference;

                        //Initialize steps detector object
                        rsSteps = new DetectSteps(phonePosition,jayalathAlgorithThreshold);
                        rsSteps->resetRealTime();
                        
                        veryFirstTime = true;
                    }
                    
                } else {
                    
                    runningIndex++;
                    
                    time = time - timestampReference;
                    
                    currentAttitude = mManager.deviceMotion.attitude;
                    rotationRate = mManager.deviceMotion.rotationRate;
                    
                    //Check to see if the y-axis is pointing in the direction of gravity. If this is the case,
                    //then let's avoid singularity by making the reference frame start at 0,0,0. Doing so, makes
                    //the reference frame be the position of the iphone. So in this case the roll is changing.
                    //Otherwise, the yaw values changes since we are making the reference frame be
                    //CMAttitudeReferenceFrameXArbitraryZVertical
                    //Check for either direction, up or down
                    if (abs(gravityVector.y*100.0) > ORIENTATION_THRESHOLD) {
                
                        //Only need to do this when the phone is held vertically in order to avoid singularity
                        //Make reference start at 0, 0, 0
                        [currentAttitude multiplyByInverseOfAttitude:initialAttidute];
                    }
                    
                    //Display time to the iphone screen
                    _onlineTimeLabel.text = [NSString stringWithFormat:@"Online time: %f", time];
                    
                    //Run realtime
                    if (phonePosition == STANDINGUP) {
                        stepCounter += rsSteps->realtime(rotationRate.x, time) ? 1 : 0;
                    } else if(phonePosition == ONSIDE || phonePosition == ONHAND) {
                        stepCounter += rsSteps->realtime(rotationRate.y, time) ? 1 : 0;
                    } else {
                        stepCounter += rsSteps->realtime(rotationRate.y, time) ? 1 : 0;
                    }
                    
                    _liveStepLabel.text = [NSString stringWithFormat:@"Live step counter: %i", stepCounter+extraSteps];
                    
                
                    
                    //Provide information to user before hmm. Also if the person only walked straight, not need to process at all
                    //Just tell the user that he/she has reached his/her destination
                    if (stepCounter == ( (numberOfSteps.at<int>(realTimeStepIndex,0)) - extraSteps - 3) && !spokeInstructions) {
                        
                        spokeInstructions = true;
                        
                        if (realTimeStepIndex == 0) {
                            
                            [gyroQueue setSuspended:TRUE];
                            
                            //Stop all threads not yet executing
                            [gyroQueue cancelAllOperations];
                            
                            
                            stopWritting = true;
                            [mManager stopGyroUpdates];
                            [mManager stopDeviceMotionUpdates];
                            
                            [fliteEngine speakText:@"You have reach your destination"];
                        }else {
                            [NSThread detachNewThreadSelector:@selector(startTheBackgroundJob) toTarget:self withObject:nil];
                        }
                        
                    }
                   
                    
                    _stepsToWalk.text =[NSString stringWithFormat:@"Steps to Walk: %i", numberOfSteps.at<int>(realTimeStepIndex,0)];
                    
                    if (numberOfSteps.at<int>(realTimeStepIndex,0) <= 20) {
                        stepsTowait = EXTRASTEPSERROR;
                    } else {
                        stepsTowait = 10;//numberOfSteps.at<int>(realTimeStepIndex,0)/20;
                    }

                    
                    [gyroQueue setSuspended:TRUE];
                    
                    //Hmm corrects error and confirms turn Realtime system has detected the user has walked the required number of steps
                    if (stepCounter >= (numberOfSteps.at<int>(realTimeStepIndex,0) + stepsTowait - extraSteps)) {
                        
                        //Stop all threads not yet executing
                        [gyroQueue cancelAllOperations];
                        
                        //Clear remanining threads that are executing but suspended
                        stopWritting = true;
                        [mManager stopGyroUpdates];
                        [mManager stopDeviceMotionUpdates];
                        
                        
                        //Subselect data
                        cv::Mat subRoll(rollG.rowRange(previosDetectedIndex, runningIndex));
                        cv::Mat subPitch(pitchG.rowRange(previosDetectedIndex, runningIndex));
                        cv::Mat subYaw(yawG.rowRange(previosDetectedIndex, runningIndex));
                        cv::Mat subTime(tG.rowRange(previosDetectedIndex, runningIndex));
                        
                        pcaObj *pcaDirection;
                        hmmObject *hmmDirection;
                        
                        
                        //if ([gyroQueue operationCount] < 2 && realTimeStepIndex != 0) {
                         
                        pcaDirection = new pcaObj(subRoll,subPitch,subYaw);
                        hmmDirection = new hmmObject(pcaDirection->getNumberOfRecords(),pcaDirection->getDataProjected(), true);
                        
                        
                        //Get the first index of detected turns
                        cv::Mat rawStates = hmmDirection->getCompleteRawStates();

                        std::cout << "The raw states: " << std::endl << hmmDirection->getCompleteRawStates() << std::endl;
                        
                        cv::Mat indecesOfTurns;
                        int rt_turnIndex = 0;
                        
                        for (int i=0; i<rawStates.cols-1; i++) {
                            if (rawStates.at<float>(0,i) != rawStates.at<float>(0,i+1))
                            {
                                rt_turnIndex = (int)i;
                                indecesOfTurns.push_back((int)i);
                            }
                        }
                        
                        
                        
                        std::cout << "The indeces of turns: " << indecesOfTurns << std::endl;
                        
                        //Detected at least one turn
                        if (indecesOfTurns.rows >= 1) {
                        
                            int firstIndex = indecesOfTurns.at<int>(indecesOfTurns.rows-1);
                            
                            std::cout << firstIndex << std::endl;
                            
                            int stepsDetectedPerTurn = stepCounter + extraSteps;
                            
                            //Get extra steps
                            extraSteps = rsSteps->numberOfExtraSteps(previosDetectedIndex+firstIndex);

                            //Remove extra steps
                            stepsDetectedPerTurn = stepsDetectedPerTurn - extraSteps;
                            previosDetectedIndex = previosDetectedIndex + firstIndex + 40;
                            
                            stepCounter = 1;
                            spokeInstructions = false;
                            indecesOfTurns.release();
                            
                            //Check for the turn
                            std::string finalstates = hmmDirection->getStateNames();
                            NSString *directions = [NSString stringWithCString:finalstates.c_str() encoding:[NSString defaultCStringEncoding]];
                            NSArray *listOfInstructions = [directions componentsSeparatedByString: @","];
                            
                            std::cout << finalstates << std::endl;
                            std::cout << "******" << listOfInstructions[0] << "****"<< std::endl;
                            std::cout << "******" << turnInstructions[realTimeStepIndex-1] << "****"<< std::endl;
                            
                            std::cout << listOfInstructions.count << std::endl;
                            
                             //If both are equal then start again for next set of steps
                             if ([listOfInstructions[listOfInstructions.count-2] isEqual:turnInstructions[realTimeStepIndex-1] ])  {
                                
                             
                                 NSMutableString *rtTurn = [[NSMutableString alloc] init];
                                 [rtTurn setString:@"User RT Turn: "];
                                 [rtTurn appendString:listOfInstructions[0]];
                             
                                 //Display realtime turn
                                 _userRTTurnLabel.text = rtTurn;
                             
                                 //Increment master indeces for next direction
                                 //realTimeStepIndex--;
                                 //realTimeTurnIndex++;

                             } else {
                                 haltSystem = true;
                                 _userRTTurnLabel.text = @"Incorrect turn";
                                 [fliteEngine speakText:@"Incorrect turn."];
                                 
                                
                             }
                            
                            realTimeStepIndex--;
                            realTimeTurnIndex++;
                        }
                        
                            //Restart without pressing button
                        
                            if (!haltSystem) {
                                [self realTimeStart];
                            }
                        //}
                    }
                    
                    if (!stopWritting) {
                        
                        //Phone is upside down so invert roll sign. For all other phone positions, the sign is the same regardless of position
                        if (gravityVector.y*100.0 > -ORIENTATION_THRESHOLD) {
                            tG.push_back(time); rollG.push_back(-currentAttitude.roll); pitchG.push_back(currentAttitude.pitch); yawG.push_back(currentAttitude.yaw);
                        }else {
                            tG.push_back(time); rollG.push_back(currentAttitude.roll); pitchG.push_back(currentAttitude.pitch); yawG.push_back(currentAttitude.yaw);
                        }
                    }
                    
                }
                    
                }
            }];
        
    }
}


- (void)startTheBackgroundJob {
    
    
    // wait for 3 seconds before starting the thread, you don't have to do that. This is just an example how to stop the NSThread for some time
    //[NSThread sleepForTimeInterval:3];
    //[self performSelectorOnMainThread:@selector(makeMyProgressBarMoving) withObject:nil waitUntilDone:NO];
    [self speakDirections];
}


- (void) stop {
    
    //Re-enable tabBar
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    
    //Avoid disabling the stop by accident if spoken first
    if (!systemStopped && systemRunning) {
        
        //Process all the data right away
        [self processData];
        
        systemPreviouslyExecuted = true;
        systemStopped = true;
        _startButton.enabled = true;
        
        //Stop writting any data left in the queue and stop the queues
        stopWritting = true;
        [mManager stopGyroUpdates];
        [mManager stopDeviceMotionUpdates];
        
        //Let the user know the system has stopped
        [fliteEngine speakText:@"Stop"];
    }
}


- (void) resetSystem {
    
    //Delete files from documents directory
    //[[NSFileManager defaultManager] removeItemAtPath:fullPath_direction error:nil];
    //[[NSFileManager defaultManager] removeItemAtPath:fullPath_steps error:nil];
    
    //Re-Initialize system's state variables
    [self initializeSystemStateVariables];

    //Release steps and direction main objects
    numberOfSteps.release();
    [turnInstructions removeAllObjects];
    stepIndex = 0;
    turnIndex = 0;
    
    //Reinitialize full path for CVS files
    [self initializeCSVFilePaths];
 
    //Reinitialize time label
    _timeLabel.text = @"Time: 0.0";
    [_directionsButton setTitle:@"Directions" forState:UIControlStateNormal];
}

- (void) processData {
    
    [self writeLogToDisk:@"In processData Funtion\n"];

//Process for directions
    std::string *fileName = new std::string([fullPath_direction UTF8String]);

    //Apply PCA to the gyroscope data and then hmm on the data with most variance
    pcaObj *pcaDirection = new pcaObj(*fileName);
    hmmObject *hmmDirection = new hmmObject(pcaDirection->getNumberOfRecords(),pcaDirection->getDataProjected(),false);
    
    //Get the directions in string format and then covert to type NSString
    std::string finalstates = hmmDirection->getStateNames();
    NSString *directions = [NSString stringWithCString:finalstates.c_str() encoding:[NSString defaultCStringEncoding]];
    
    [self writeLogToDisk:@" Directions are: "];
    [self writeLogToDisk:directions];
    [self writeLogToDisk:@"\n"];
    
    //List of instructions (left, right, around) and total number of turns/directions
    NSArray *listOfInstructions = [directions componentsSeparatedByString: @","];
    totalNumberOfInstructions = listOfInstructions.count;
    
    [self writeLogToDisk:[NSString stringWithFormat:@" Total number of instruction: %i\n", totalNumberOfInstructions]];
    
    //Allocate space
    turnInstructions = [[NSMutableArray alloc] initWithCapacity:totalNumberOfInstructions];
    
    //Convert to NSMutable array
    for (int i=0; i<totalNumberOfInstructions; i++) {
        turnInstructions[i] = listOfInstructions[i];
    }
    
//Process for steps
    //Detect steps by running jayalath algorithm
    std::string *fileNameSteps = new std::string([fullPath_steps UTF8String]);
    DetectSteps steps(*fileNameSteps, phonePosition);
    int stepCount = steps.jayalathAlgorith(jayalathAlgorithThreshold);
    
    _totalStepCount.text = [NSString stringWithFormat:@"Total steps walked: %i", stepCount];
    [self writeLogToDisk:[NSString stringWithFormat:@" Total steps counted: %i\n", stepCount]];
    
    //Iterate through all the raw states to find the indeces of state changes from hmm
    cv::Mat completeRawStates = hmmDirection->getCompleteRawStates();
    cv::Mat finalStatesIndices;
    
    for (int i=0; i<completeRawStates.cols-1; i++) {
        if (completeRawStates.at<float>(0,i) != completeRawStates.at<float>(0,i+1))
        {
            finalStatesIndices.push_back(i);
        }
    }
    
    //Push the last index so to have a range
    finalStatesIndices.push_back(completeRawStates.cols);
    
    //Get raw data of detected steps (1's mark steps)
    cv::Mat stepsDetected = steps.rawDetectedSteps();
    
    int startIndex = 0;
    int endIndex = 0;
    int sum = 0;
    
    //Calculate the total number of steps taken between directions (eg. 20 steps between a right and left, etc...)
    for (int i=0; i<finalStatesIndices.rows; i++) {
        
        endIndex = finalStatesIndices.at<int>(i,0);
        
        while (startIndex<endIndex) {
            
            if(stepsDetected.at<float>(0,startIndex) == 1)
                sum++;
            
            startIndex++;
        }
        
        //Save the total number of steps between intervals and move on to next interval
        numberOfSteps.push_back(sum);
        
        [self writeLogToDisk:[NSString stringWithFormat:@" Total number of steps at path: %i = %i\n",i, sum]];
        
        sum = 0;
        startIndex = endIndex;
    }
    
    //Set the master indeces for playing, fastforward or rewind
    stepIndex = totalNumberOfInstructions-1;
    turnIndex = 0;
    
    //Indeces used for realtime component
    realTimeStepIndex = stepIndex;
    realTimeTurnIndex = turnIndex;
    
    //Release memory right away of the objects
    finalStatesIndices.release();
    directions = nil;
    stepsDetected.release();
    delete pcaDirection;
    delete hmmDirection;
    delete fileName;
    delete fileNameSteps;
    finalstates = "";
}


- (void) speakDirections {
    
    if (stepIndex >= 0) {
        
        NSMutableString *finalInstructions;
        finalInstructions = [[NSMutableString alloc] init];
        
        //[finalInstructions appendString:[NSString stringWithFormat:@"Walk %i steps", numberOfSteps.at<int>(stepIndex,0)]];
        //[fliteEngine speakText:finalInstructions];
        
     
        
        if(stepIndex > 0)
        {
            [finalInstructions setString:@""];
            //[finalInstructions appendString:[NSString stringWithFormat:@""]];
            [finalInstructions appendString:turnInstructions[stepIndex-1]];//-1 to avoid blank instruction since there are n-1 instructions (n=step count sets)
            [fliteEngine speakText:finalInstructions];
            
            
        } else {
            [fliteEngine speakText:@"You have reach your destination"];
            [_directionsButton setTitle:@"Directions" forState:UIControlStateNormal];
            
            _userRTTurnLabel.text = @"You have reach your destination";
            [mManager stopGyroUpdates];
            [mManager stopDeviceMotionUpdates];
        }
        
        stepIndex--;
        turnIndex++;
    } else {
        [_directionsButton setTitle:@"Directions" forState:UIControlStateNormal];
    }
}

//Override methods for Remote Control events and become first responder
//Make sure the Remote Control event events handling continues eventhough
//the user has swtiched views
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}
- (void)viewWillDisappear:(BOOL)animated {
    //[super viewWillDisappear:animated];
    //[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    //[self resignFirstResponder];
    
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}



-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}



/* Remote control types
 UIEventSubtypeNone
 UIEventSubtypeMotionShake
 UIEventSubtypeRemoteControlPlay
 UIEventSubtypeRemoteControlPause       
 UIEventSubtypeRemoteControlStop                
 UIEventSubtypeRemoteControlTogglePlayPause    
 UIEventSubtypeRemoteControlNextTrack          
 UIEventSubtypeRemoteControlPreviousTrack     
 UIEventSubtypeRemoteControlBeginSeekingBackward 
 UIEventSubtypeRemoteControlEndSeekingBackward 
 UIEventSubtypeRemoteControlBeginSeekingForward  
 UIEventSubtypeRemoteControlEndSeekingForward
 */
- (void)remoteControlReceivedWithEvent:(UIEvent *)theEvent
{
	if (theEvent.type == UIEventTypeRemoteControl) {
        
        switch(theEvent.subtype) {
                
                
                //Single click
            case UIEventSubtypeRemoteControlTogglePlayPause:
                
                switch (clickTurn) {
                    case 0: //start
                        [self start];
                        clickTurn++;
                        break;
                        
                    case 1://stop
                        firstTimeToSpeak = true;
                        [self stop];
                        clickTurn++;
                        break;
                    case 2://start directions
                        if (firstTimeToSpeak) {
                            [fliteEngine speakText:@"Start Walking"];
                            firstTimeToSpeak = false;
                        }
                        
                        [_directionsButton setTitle:@"Next" forState:UIControlStateNormal];
                        
                        _userRTTurnLabel.text = @"User RT Turn: ";
                        [self realTimeStart];
                        clickTurn++;
                        break;
                        
                    case 3: //Next set of directions
                        userManualReset = true;
                        clickTurn++;
                        break;
                        
                    default:
                        userManualReset = true;
                        break;
                }
                
                
                break;
                
                default: ;
            
                
                
            /*
                
            //Single click
            case UIEventSubtypeRemoteControlTogglePlayPause:
       
                if (systemStopped) {
                    
                    if (firstTimeToSpeak) {
                        [fliteEngine speakText:@"Start Walking"];
                        firstTimeToSpeak = false;
                        userManualReset = false;
                    }
                    
                    [_directionsButton setTitle:@"Next" forState:UIControlStateNormal];
                    
                    _userRTTurnLabel.text = @"User RT Turn: ";
                    [self realTimeStart];
                    
                }
                
                
                break;
                
            //Double click
            default:
                
                if (onlyOneClick) {
                
                
                    if(!appRunning)
                        [self start];
                    else {
                        [self stop];
                        systemStopped = true;
                        firstTimeToSpeak = true;
                    }
                    //Toggle flag for next double click
                    appRunning = !appRunning;
                    
                    //onlyOneClick = false;
                
                }
         */       
        }
         
    }
}

- (IBAction)startButton:(id)sender {
    self.directionsButton.enabled = false;
    [self start];
}

- (IBAction)stopButton:(id)sender {
    
    self.directionsButton.enabled = true;
    firstTimeToSpeak = true;
    [self stop];
}

//Enable/Disable buttons to control user options
- (IBAction)onOffButton:(id)sender {
    if (self.onOffButton.isOn) {
        self.startButton.enabled = true;
        self.stopButton.enabled = true;
        //self.directionsButton.enabled = true;
        self.resetButton.enabled = true;
    } else {
        self.startButton.enabled = false;
        self.stopButton.enabled = false;
        //self.directionsButton.enabled = false;
        self.resetButton = false;
    }
}

//Directions Button action
- (IBAction)directionsButton:(id)sender {
    
    if (firstTimeToSpeak) {
        [fliteEngine speakText:@"Start Walking"];
        firstTimeToSpeak = false;
    }
    
    
    
    [_directionsButton setTitle:@"Next" forState:UIControlStateNormal];
    
    _userRTTurnLabel.text = @"User RT Turn: ";
    [self realTimeStart];
}

- (IBAction)resetButton:(id)sender {
    userManualReset = true;
}


//****************************************************************************************
//C++ Code goes here
//****************************************************************************************

#ifdef __cplusplus




void* PosixThreadMainRoutine(void* data)
{
    
    // Do some work here.


    
    return NULL;
    
}



void LaunchThread()

{
    
    // Create the thread using POSIX routines.
    
    pthread_attr_t  attr;
    
    pthread_t       posixThreadID;
    
    int             returnVal;
    
    
    
    returnVal = pthread_attr_init(&attr);
    
    assert(!returnVal);
    
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    
    assert(!returnVal);
    
    
    
    int     threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, NULL);
    
    
    
    returnVal = pthread_attr_destroy(&attr);
    
    assert(!returnVal);
    
    if (threadError != 0)
        
    {
        
        // Report an error.
        
    }
    
}



#endif

//****************************************************************************************



@end






