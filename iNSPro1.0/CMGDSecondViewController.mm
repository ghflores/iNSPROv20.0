//
//  CMGDSecondViewController.m
//  iNSPro1.0
//
//  Created by German H Flores on 5/28/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#import "CMGDSecondViewController.h"
#import "FliteTTS.h"

@interface CMGDSecondViewController ()

@end

@implementation CMGDSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Load user settings
    [self loadUserSettings];
    
    //Initialize queue
    gyroQueue = [NSOperationQueue currentQueue];
	
    //Disable autolock
    UIApplication *thisApp = [UIApplication sharedApplication];
    thisApp.idleTimerDisabled = YES;
    
    //Set background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.jpg"]];
    
    //Only initialized once
    appRunningFirstTime = true;
    veryFirstTime = false;
    fileCounter = 1; //Four files are created for the calibration steps
    firstTime = true;
    
    //Set text to Speech system
    fliteEngine = [[FliteTTS alloc] init];
    [fliteEngine setPitch:100.0 variance:50.0 speed:40.0];
    [fliteEngine setVoice:@"cmu_us_slt"];
    
    
    [fliteEngine speakText:@"Press calibrate to begin calibration process."];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSLog(@"tab selected: %@", item.title);
}

- (void) loadUserSettings {
    
    NSArray *userSettingsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *userSettingsDocumentsDirectory = [userSettingsPath objectAtIndex:0];
    NSString *userSettingsFullPath = [userSettingsDocumentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"userSettings.usr", nil]];
    std::string *userSettingsFileName = new std::string([userSettingsFullPath UTF8String]);
    char *charFileName = (char*)userSettingsFileName->c_str();
    std::string record;
    
    //Open read stream
    std::ifstream myfile (charFileName);
    
    //Check to see if file exists. If not, the use default value
    if (myfile) {
        if (myfile.is_open()) {
            while ( myfile.good() ) {
                getline (myfile,record);
            }
            myfile.close();
        }
        
        char *token = strtok ((char*)record.c_str(),",");
        _averageStepThreshold.text = [NSString stringWithFormat:@"Threshold: %f", atof(token)];
        
    } else {
        _averageStepThreshold.text = @"No threshold set";
    }
}

- (void) deleteExistingFiles {
    
    NSArray *finalPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *finalDocumentsDirectory = [finalPath objectAtIndex:0];
    NSString *finalFullPath;
    
    NSString *extension = @"cal";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory2 = [paths2 objectAtIndex:0];
    
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory2 error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    
    //Remove all existing setting files
    while ((filename = [e nextObject])) {
        
        if ([[filename pathExtension] isEqualToString:extension]) {
            finalFullPath  = [finalDocumentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:filename, nil]];
            [fileManager removeItemAtPath:[documentsDirectory2 stringByAppendingPathComponent:filename] error:NULL];
        }
    }
    
    //Reset file counter
    fileCounter = 1;
    
    //Initialize flags
    calibrating = false;
    stopWritting = false;
    
}

- (void) defaultCalibration {
    
    calibrationdata2log = [[NSMutableString alloc] init];
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"userSettings.usr", nil]];
    
    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    
    [calibrationdata2log appendString:[NSString stringWithFormat:@"%f", 0.4]];
    [calibrationdata2log writeToFile:fullPath atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
    
}

- (void) createTempFile {
    
    //Create and get full path for CVS file
    calibrationdata2log = [[NSMutableString alloc] init];
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"calibrationFile_%i.cal",fileCounter, nil]];
    
}



- (void) calibrate {
    
    switch (fileCounter) {
        case 1:
            _calibrationStatus.text = @"Step 1";
            [fliteEngine speakText:@"Start Walking."];
            //First set of steps
            //Create file and increment file counter
            [self createTempFile];
            fileCounter++;
            [self realTimeStart];
            break;
        
        case 2:
            _calibrationStatus.text = @"Step 2";
            [fliteEngine speakText:@"Start Walking again."];
            //First set of steps
            //Create file and increment file counter
            [self createTempFile];
            fileCounter++;
            [self realTimeStart];
            break;
            
        case 3:
            _calibrationStatus.text = @"Step 3";
            [fliteEngine speakText:@"Start Walking again."];
            //First set of steps
            //Create file and increment file counter
            [self createTempFile];
            fileCounter++;
            [self realTimeStart];
            break;
            
        case 4:
            _calibrationStatus.text = @"Step 4";
            [fliteEngine speakText:@"Start Walking again."];
            //First set of steps
            //Create file and increment file counter
            [self createTempFile];
            fileCounter++;
            [self realTimeStart];
            break;
            
        case 5:
            [fliteEngine speakText:@"Calibration process completed."];
            [self process];
            break;
            
        default:
            break;
    }

    
    
}


- (void) process {
    
    float calibratedTime = 0;
    
    NSArray *finalPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *finalDocumentsDirectory = [finalPath objectAtIndex:0];
    NSString *finalFullPath;
    
    NSString *extension = @"cal";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory2 = [paths2 objectAtIndex:0];
    
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory2 error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    
    
    while ((filename = [e nextObject])) {
        
        if ([[filename pathExtension] isEqualToString:extension]) {
            
            finalFullPath  = [finalDocumentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:filename, nil]];
            
            std::string *finalFileName = new std::string([finalFullPath UTF8String]);
            
            DetectSteps ds(*finalFileName,phonePosition);
            calibratedTime += ds.calibrateStepsCounter();
            
            //[fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
    
    calibratedTime /= 4.0;
    
    _averageStepThreshold.text = [NSString stringWithFormat:@"The new threshold is: %f", calibratedTime];
    
    calibrationdata2log = [[NSMutableString alloc] init];
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"userSettings.usr", nil]];
    
    [calibrationdata2log appendString:[NSString stringWithFormat:@"%f", calibratedTime]];
    [calibrationdata2log writeToFile:fullPath atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
    
}



- (IBAction)calibrateButton:(id)sender {
    
    //Delete all existing calibration files (.cal) prior to starting the calibration process
    [self deleteExistingFiles];
    
    //Start calibration process
    [self calibrate];
    
}


//System's State variables
- (void) initializeSystemStateVariables {
    
    phonePosition = NONE;               //Determines the position of the iPhone
    stopWritting = false;               //Used so that information is not written to the file after the queue has stopped
    spokeInstructions = false;
    stepCounter = 0;
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
            
            //Only allow the first thread to run
            if ([gyroQueue operationCount] < 2) {
                
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

                    }else if (abs(gravityVector.y*100.0) > ORIENTATION_THRESHOLD) {
                        phonePosition = STANDINGUP;

                    } else if (abs(gravityVector.z*100.0) >= ORIENTATION_THRESHOLD){
                        phonePosition = ONHAND;

                    } else {
                        phonePosition = NONE;
                    }
                    
                    std::cout << phonePosition << std::endl;
                    
                    //Only allocate one time for the entire run
                    if (!veryFirstTime) {
                        
                        timestampReference = time;
                        time = timestampReference;
                        
                        //Initialize steps detector object. Initally assume that the user walks at 0.4, which is the average
                        rsSteps = new DetectSteps(phonePosition,DEFAULTUSERSTEPTIME);
                        rsSteps->resetRealTime();
                        
                        veryFirstTime = true;
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
                        
                        //Only need to do this when the phone is held vertically in order to avoid singularity
                        //Make reference start at 0, 0, 0
                        [currentAttitude multiplyByInverseOfAttitude:initialAttidute];
                    }
                    
                    //Display time to the iphone screen
                    //_onlineTimeLabel.text = [NSString stringWithFormat:@"Online time: %f", time];
                    
                    //Run realtime
                    if (phonePosition == STANDINGUP) {
                        stepCounter += rsSteps->realtime(rotationRate.x, time) ? 1 : 0;
                    } else if(phonePosition == ONSIDE || phonePosition == ONHAND) {
                        stepCounter += rsSteps->realtime(rotationRate.y, time) ? 1 : 0;
                    } else {
                        stepCounter += rsSteps->realtime(rotationRate.y, time) ? 1 : 0;
                    }
                    
                    std::cout << stepCounter << std::endl;
                    
                    //_liveStepLabel.text = [NSString stringWithFormat:@"Live step counter: %i", stepCounter+extraSteps];
                    
                    //The user has walked at least MAXNUMBEROFSTEPS
                    if (stepCounter == MAXNUMBEROFSTEPS) {
                        
                        //Stop writting to the file
                        stopWritting = true;
                        
                        [fliteEngine speakText:@"Stop Walking and turn around."];
                        
                        [gyroQueue setSuspended:TRUE];
                                                
                        //Stop all threads not yet executing
                        [gyroQueue cancelAllOperations];
                        
                        //Clear remanining threads that are executing but suspended
                        [mManager stopGyroUpdates];
                        [mManager stopDeviceMotionUpdates];
                        
                        //Calibrate again
                        [self calibrate];
                        
                    }
                    
                    if (!stopWritting) {
                        [self writeGyroRRCSVDataToDisk:time:rotationRate.x :rotationRate.y :rotationRate.z];
                    }
                    
                }
                
            }
        }];
        
    }
}

//Save Gyroscope data as CSV format
- (void) writeGyroRRCSVDataToDisk:(double)time :(double)rx :(double)ry :(double)rz {
    
    [calibrationdata2log appendString:[NSString stringWithFormat:@"%f,", time]];
    [calibrationdata2log appendString:[NSString stringWithFormat:@"%f,", rx]];
    [calibrationdata2log appendString:[NSString stringWithFormat:@"%f,", ry]];
    [calibrationdata2log appendString:[NSString stringWithFormat:@"%f,", rz]];
    [calibrationdata2log appendString:[NSString stringWithFormat:@"\n"]];
    
    [calibrationdata2log writeToFile:fullPath atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}


- (IBAction)defaultButton:(id)sender {
    
    [self deleteExistingFiles]; //Delete any previous files
    [self defaultCalibration]; //Create default calibration file
    [self loadUserSettings]; //Load the calibration file
    
}
@end
