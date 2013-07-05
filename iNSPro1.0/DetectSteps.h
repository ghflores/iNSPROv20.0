//
//  DetectSteps.h
//  iNSv22.0
//
//  Created by German H Flores on 5/17/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#ifndef __iNSv22_0__DetectSteps__
#define __iNSv22_0__DetectSteps__

#include <iostream>
#include <fstream>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include "Parameters.h"



class DetectSteps {
    
    
private:
    
    int order;
    int phonePosition;
    double *a, *b;
    cv::Mat data, gx, gy, gz, time;
    int totalNumberOfReadings;
    
    cv::Mat filter(cv::Mat);
    
    int numberOfRecords(std::string);
    int sign(double);
    
    cv::Mat stepsDetected;
    cv::Mat vectorG;
    cv::Mat vectorTime;
    cv::Mat filteredData;
    
    int firstStepDetected;
    cv::Mat indexesDetectedSteps;
    float calibratedTime;
    
    int realTimeIndex;
    
public:
    
    DetectSteps(std::string, int);
    DetectSteps(int, int);
    void loadData(std::string);
    cv::Mat rawDetectedSteps(void);
    int numberOfExtraSteps(int);
    cv::Mat getTime(void);
    cv::Mat getXData(void);
    cv::Mat getYData(void);
    bool realtime(double, double);
    int jayalathAlgorith(double);
    void resetRealTime(void);
    float calibrateStepsCounter(void);
    float getAverageFromLeastErrors(std::vector<int>, std::vector<float>);
    ~DetectSteps();
    
    
};

#endif /* defined(__iNSv22_0__DetectSteps__) */