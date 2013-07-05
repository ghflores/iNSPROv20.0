//
//  hmmObject.cpp
//  iPhoneNavigationSystem
//
//  Created by German H Flores on 5/6/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#include "hmmObject.h"

using namespace cv;
using namespace std;

//Constructor
hmmObject::hmmObject(int dataSetSize, cv::Mat inputData, bool flowDirection) {
    
    flow = flowDirection;
    
    //Initialize variables
    N = 8;
    setSize = dataSetSize;
    sigma = 1.6;
    same = 0.99;
    x = 0.0003571428571429;
    y = 0.008;
    z = 0.0016428571428571;
    A = Mat::zeros(8,8,CV_64FC1);
    States = Mat::zeros(1, N, CV_64FC1);
    data = inputData.clone();
    
    //Temporary A C array
    double _A[8][8] = {  {same, x/4, y/2, x/4, z, x/4, y/2, x/4},
        {x/4, same, x/4, y/2, x/4, z, x/4, y/2},
        {y/2, x/4, same, x/4, y/2, x/4, z, x/4},
        {x/4, y/2, x/4, same, x/4, y/2, x/4, z},
        {z, x/4, y/2, x/4, same, x/4, y/2, x/4},
        {x/4, z, x/4, y/2, x/4, same, x/4, y/2},
        {y/2, x/4, z, x/4, y/2, x/4, same, x/4},
        {x/4, y/2, x/4, z, x/4, y/2, x/4, same} };
    
    double _states[8] = {0, PI/4, PI/2, (3.0/4.0)*PI, PI, -(3.0/4.0)*PI, -PI/2, -PI/4};
    
    A = cv::Mat(N,N,CV_64FC1,_A).clone();
    cv::log(A, logA);
    
    States = cv::Mat(1,N,CV_64FC1,_states).clone();
    
    currentState = Mat::zeros(1, setSize, CV_32FC1);
    
    //Perform vitervi
    hmmviterbi();
    
    if (flow == 0) {
        calculateStates();
    } else {
        calculateStatesReversed();
    }
    
}

hmmObject::~hmmObject() {
    
    stateNames = "";
    A.release();
    logA.release();
    States.release();
    currentState.release();
    data.release();
    finalStates.release();
}


double hmmObject::probOgivenS(double observation, int state) {
    
    double alpha = States.at<double>(state);
    double gamma = observation - alpha;
    
    if(gamma < 0)
        gamma = MIN(fabs(gamma),fabs(gamma + 2.0*PI));
    else
        gamma = MIN(fabs(gamma),fabs(gamma - 2.0*PI));
    
    return log(exp(-pow(gamma,2)/(2.0*pow(sigma,2))) / (sqrt(2.0*PI)*sigma));
}


void hmmObject::hmmviterbi(void) {
    
    double bestVal, val, probability;
    double min, max;
    int maxID, minID;
    int bestPtr;
    
    
    Mat pTR = Mat::zeros(N,setSize,CV_32FC1);
    
    double negInf[8] = { NEG_INF,NEG_INF,NEG_INF,NEG_INF,
        NEG_INF,NEG_INF,NEG_INF,NEG_INF };
    Mat v = Mat(N,1,CV_64FC1,negInf);
    
    v.at<double>(0) = 0;
    Mat vOld = v.clone();
    
    
    //Loop through the model
    for (int count = 0; count<setSize; count++) {
        
        for (int state = 0; state<N; state++) {
            
            bestVal = NEG_INF;
            bestPtr = 0;
            
            //Loop to avoid lost of calls to max
            for (int inner = 0; inner<N; inner++) {
                
                val = vOld.at<double>(inner) + logA.at<double>(inner,state);
                
                if (val > bestVal) {
                    
                    bestVal = val;
                    bestPtr = inner;
                }
            }
            
            pTR.at<float>(state,count) = bestPtr;
            
            probability = probOgivenS(data.at<double>(count), state);
            
            v.at<double>(state) = probability + bestVal;
        }
        
        
        vOld = v.clone();
    }
    
    //Decide wich of the final states is post probable
    cv::minMaxIdx(v, &max, &min, &maxID, &minID);
    
    //Backtracing through the model
    currentState.at<float>(0,setSize-1) = minID;
    
    for (int count = setSize-2; count >=0; count--) {
        currentState.at<float>(0,count) = pTR.at<float>((int)(currentState.at<float>(0,count+1)),count+1);
    }
    
}


Mat hmmObject::getCompleteRawStates(){
    return currentState.clone();
}

//1 added to start at state 1
Mat hmmObject::getSimpleRawStates(){
    return (finalStates.clone()+1);
}

std::string hmmObject::getStateNames(){
    return stateNames;
}


void hmmObject::calculateStates() {
    
    int row, col;
    
    std::string turns[8][8] = { {NN, RIGHT, RIGHT, CT, CT, CT, LEFT, LEFT},
        {LEFT, NN, RIGHT, RIGHT, CT, CT,CT, LEFT},
        {LEFT, LEFT, NN, RIGHT, RIGHT, CT, CT, CT},
        {CT, LEFT, LEFT, NN, RIGHT, RIGHT, CT, CT},
        {CT, CT, LEFT, LEFT, NN, RIGHT, RIGHT, CT},
        {CT, CT, CT, LEFT, LEFT, NN, RIGHT, RIGHT},
        {RIGHT, CT, CT, CT, LEFT, LEFT, NN, RIGHT},
        {RIGHT, RIGHT, CT, CT, CT, LEFT, LEFT, NN} };
    
    
    //Iterate through the current states to only get states without duplicates
    for (int i =0; i<currentState.cols-1; i++) {
        
        if (currentState.at<float>(0,i) != currentState.at<float>(0,i+1)) {
            finalStates.push_back(currentState.at<float>(0,i));
        }
    }
    //Push the last element
    finalStates.push_back(currentState.at<float>(0,currentState.cols-1));
    
    //Iterate through all the final states to get turn names
    //Store everything in a string CSV format
    for (int i=0; i<finalStates.rows-1; i++) {
        
        col = (int)(finalStates.at<float>(i,0));
        row = (int)(finalStates.at<float>(i+1,0));
        
        stateNames.append(turns[row][col]+",");
    }
    
}


void hmmObject::calculateStatesReversed() {
    
    int row, col;
    
    std::string turns[8][8] = { {NN, RIGHTR, RIGHTR, CT, CT, CT, LEFTR, LEFTR},
        {LEFTR, NN, RIGHTR, RIGHTR, CT, CT,CT, LEFTR},
        {LEFTR, LEFTR, NN, RIGHTR, RIGHTR, CT, CT, CT},
        {CT, LEFTR, LEFTR, NN, RIGHTR, RIGHTR, CT, CT},
        {CT, CT, LEFTR, LEFTR, NN, RIGHTR, RIGHTR, CT},
        {CT, CT, CT, LEFTR, LEFTR, NN, RIGHTR, RIGHTR},
        {RIGHTR, CT, CT, CT, LEFTR, LEFTR, NN, RIGHTR},
        {RIGHTR, RIGHTR, CT, CT, CT, LEFTR, LEFTR, NN} };
    
    
    //Iterate through the current states to only get states without duplicates
    for (int i =0; i<currentState.cols-1; i++) {
        
        if (currentState.at<float>(0,i) != currentState.at<float>(0,i+1)) {
            finalStates.push_back(currentState.at<float>(0,i));
        }
    }
    //Push the last element
    finalStates.push_back(currentState.at<float>(0,currentState.cols-1));
    
    //Iterate through all the final states to get turn names
    //Store everything in a string CSV format
    for (int i=0; i<finalStates.rows-1; i++) {
        
        col = (int)(finalStates.at<float>(i,0));
        row = (int)(finalStates.at<float>(i+1,0));
        
        stateNames.append(turns[row][col]+",");
    }
    
}

