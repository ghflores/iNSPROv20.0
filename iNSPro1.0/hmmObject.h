//
//  hmmObject.h
//  iPhoneNavigationSystem
//
//  Created by German H Flores on 5/6/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#ifndef __iPhoneNavigationSystem__hmmObject__
#define __iPhoneNavigationSystem__hmmObject__

#include <iostream>
#include <algorithm>
#include "math.h"
#include <limits>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#define PI 3.1416
#define NEG_INF -INFINITY//-std::numeric_limits<double>::max()

//Note: LEFT and RIGHT have been switch since we giving the instructions backward
#define LEFT "right"
#define RIGHT "left"
#define CT "around"
#define NN "none"

#define LEFTR "left"
#define RIGHTR "right"


class hmmObject {
    
private:
    
    int N;
    int setSize;
    double same;
    double x;
    double y;
    double z;
    double sigma;
    std::string stateNames;
    cv::Mat A;
    cv::Mat logA;
    cv::Mat States;
    cv::Mat currentState;
    cv::Mat data;
    cv::Mat finalStates;
    
    bool flow;
    
    double probOgivenS(double, int);
    void hmmviterbi(void);
    void calculateStates(void);
    void calculateStatesReversed(void);
    
public:
    
    hmmObject(int, cv::Mat,bool);
    ~hmmObject();
    cv::Mat getCompleteRawStates();
    cv::Mat getSimpleRawStates();
    std::string getStateNames();
    
};

#endif /* defined(__iPhoneNavigationSystem__hmmObject__) */
