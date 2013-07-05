//
//  DetectSteps.cpp
//  iNSv22.0
//
//  Created by German H Flores on 5/17/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#include "DetectSteps.h"

using namespace cv;
using namespace std;

DetectSteps::DetectSteps(string fileName, int phonePos){
    
	loadData(fileName);
    
    phonePosition = phonePos;
	order = 6;
	a = new double[order + 1];
	b = new double[order + 1];
    
	//parameters obtained with matlab [b,a]=butter(6,(2*2)/20);
    
    
     a[0] = 1.0;
     a[1] = -3.579434798331192;
     a[2] = 5.658667165933625;
     a[3] = -4.965415228778570;
     a[4] = 2.529494905841447;
     a[5] = -0.705274114509901;
     a[6] = 0.083756479618679;
     
     b[0] = 3.405376527201021e-04;
     b[1] = 0.002043225916321;
     b[2] = 0.005108064790802;
     b[3] = 0.006810753054402;
     b[4] = 0.005108064790802;
     b[5] = 0.002043225916321;
     b[6] = 3.405376527201021e-04;
    
    //Realtime Index is the master index that keeps track of the realtime step Detection
    realTimeIndex = 0;
    
    calibratedTime = DEFAULTUSERSTEPTIME;
    
}

DetectSteps::DetectSteps(int phonePos, int calibrationThreshold){
    
    phonePosition = phonePos;
	order = 6;
	a = new double[order + 1];
	b = new double[order + 1];
    
	//parameters obtained with matlab [b,a]=butter(6,(2*2)/20);
    
    
     a[0] = 1.0;
     a[1] = -3.579434798331192;
     a[2] = 5.658667165933625;
     a[3] = -4.965415228778570;
     a[4] = 2.529494905841447;
     a[5] = -0.705274114509901;
     a[6] = 0.083756479618679;
     
     b[0] = 3.405376527201021e-04;
     b[1] = 0.002043225916321;
     b[2] = 0.005108064790802;
     b[3] = 0.006810753054402;
     b[4] = 0.005108064790802;
     b[5] = 0.002043225916321;
     b[6] = 3.405376527201021e-04;
    
    realTimeIndex = 0;
    
    calibratedTime = calibrationThreshold;
    
}


DetectSteps::~DetectSteps(){
    
	delete a;
	delete b;
    data.release();
    gx.release();
    gy.release();
    gz.release();
    time.release();
    stepsDetected.release();
    
}

Mat DetectSteps::filter(Mat input){
    
	Mat output = Mat::zeros(input.rows, 1, CV_64FC1);
	int i,j;
	output.at<double>(0) = b[0] * input.at<double>(0);
	for(i = 1; i < order + 1; i++)
	{
		output.at<double>(i) = 0.0;
		for(j = 0; j < i + 1; j++)
			output.at<double>(i) = output.at<double>(i) + b[j] * input.at<double>(i - j);
		for(j = 0; j < i; j++)
			output.at<double>(i) = output.at<double>(i) -a[j + 1] * output.at<double>(i - j - 1);
	}
	/* end of initial part */
	for(i = order + 1; i < input.rows + 1; i++)
	{
		output.at<double>(i) = 0.0;
		for (j = 0; j < order + 1; j++)
			output.at<double>(i) = output.at<double>(i) + b[j] * input.at<double>(i-j);
		for (j = 0; j < order; j++)
			output.at<double>(i) = output.at<double>(i) - a[j+1] * output.at<double>(i - j - 1);
	}
    
	return output.clone();
}

void DetectSteps::loadData(string fileName){
    
    int row = 0;
    int col = 0;
    char *tokens;
    string record;
    
    //Convert filename to char array
    char *charFileName = new char[fileName.size()+1];
    charFileName[fileName.size()] = 0;
    memcpy(charFileName,fileName.c_str(),fileName.size());
    
    int numOfRecords = numberOfRecords(fileName);
    data = Mat::zeros(numOfRecords,4,CV_64FC1);
    
    //Open read stream
    std::ifstream myfile (charFileName);
    
    //Extract the values and store in matrix
    if (myfile.is_open()) {
        while ( myfile.good() && row < totalNumberOfReadings ) {
            getline (myfile,record);
            tokens = strtok ((char*)record.c_str(),",");
            data.at<double>(row,col) = atof(tokens);
            col++;
            
            while (tokens != NULL && col < 4) {
                tokens = strtok (NULL, ",");
                data.at<double>(row,col) = atof(tokens);
                col++;
            }
            
            col = 0;
            row++;
        }
        myfile.close();
    }
    
    data.col(0).copyTo(time);
    data.col(1).copyTo(gx);
    data.col(2).copyTo(gy);
    data.col(3).copyTo(gz);
    
}


int DetectSteps::numberOfExtraSteps(int index){
    
    Mat dest(stepsDetected.rowRange(index+1, stepsDetected.rows));
    Scalar destTotal = cv::sum(dest);
    
    
    std::cout << stepsDetected << std::endl;
    
	return destTotal[0];
}


Mat DetectSteps::getTime() {
    return time.clone();
}

Mat DetectSteps::getXData(void){
    return gx.clone();
}

Mat DetectSteps::getYData(void){
    return gy.clone();
}


int DetectSteps::numberOfRecords(string fileName) {
    
    char *charFileName = (char*)fileName.c_str();
    int counter = -1; //Start at -1 to remove extra at end
    string record;
    
    //Open read stream
    std::ifstream myfile (charFileName);
    
    if (myfile.is_open()) {
        while ( myfile.good() ) {
            getline (myfile,record); counter++;
        }
        myfile.close();
    }
    
    totalNumberOfReadings = counter;
    
    return counter;
}

int DetectSteps::jayalathAlgorith(double timeThreshold){
	int countedSteps = 0;
	Mat filteredData;
	Mat indexesDetectedSteps;
    double threshold = 0.0;
    int start = 0;
    int end = 0;
    int firstStepDetected = 0;
    double timeLastZeroCross = 0;
    double currentTime = 0;
    int index;
    
    if (phonePosition == STANDINGUP) {
        filteredData = filter(gy);
    } else if(phonePosition == ONSIDE || phonePosition == ONHAND) {
        filteredData = filter(gx);
    } else {
        filteredData = filter(gy);
    }
    
    //keep track of the Detected steps
    stepsDetected = Mat::zeros(1, filteredData.rows, CV_64FC1);
    
    //Apply appropriate threshold according to the position of the iPhone
    if (phonePosition == STANDINGUP || phonePosition == ONSIDE) {
        threshold = 0.5;
    } else if(phonePosition == ONHAND) {
        threshold = 0.07;
    }
    
    //Do to the order, need at least 7 prior data points
    for (int i=(order+1); i<=filteredData.rows; i++) {
        
        if(sign(filteredData.at<double>(i)) != sign(filteredData.at<double>(i - 1))){
            
            
            if (firstStepDetected == 0) {
                stepsDetected.at<float>(0,i) = 1;
                indexesDetectedSteps.push_back(i);
                firstStepDetected = 1; //Clear Flag
                countedSteps++;
                
            } else {
                
                //Check the difference in time between the last zero cross and the actual one
                index = indexesDetectedSteps.at<int>(indexesDetectedSteps.rows-1);
                timeLastZeroCross = time.at<double>(index);
                currentTime = time.at<double>(i);
                
                if ((currentTime - timeLastZeroCross) >= TIMETOOCCUR) {
                    
                    end = i-1;
                    start = indexesDetectedSteps.at<int>(indexesDetectedSteps.rows-1);
                    Mat dataToCheck = filteredData.rowRange(start, end);
                    
                    double minVal, maxVal;
                    minMaxIdx(dataToCheck, &minVal, &maxVal);
                    
                    if(fabs(minVal) > threshold || fabs(maxVal) > threshold) {
                        
                        stepsDetected.at<float>(0,i) = 1;
                        indexesDetectedSteps.push_back(i);
                        countedSteps++;
                        
                    }
                }
            }
        }
        
    }
    
    return countedSteps;
}


bool DetectSteps::realtime(double g, double time){
    
    bool isStep = false;
    Mat filteredSubData;
    double timeLastZeroCross = 0;
    int index;
    double peakThreshold = 0.0;
    int start = 0;
    int end = 0;
    double threshold = 0.0;
    
    //push elements
	Mat G = Mat::ones(1,1,CV_64FC1) * g;
	vectorG.push_back(G.clone());
    
	Mat Time = Mat::ones(1,1,CV_64FC1) * time;
	vectorTime.push_back(Time.clone());
    
    stepsDetected.push_back(0);
    
    //Increment number of entries
    realTimeIndex++;
    
    //Apply appropriate threshold according to the position of the iPhone
    if (phonePosition == STANDINGUP || phonePosition == ONSIDE) {
        peakThreshold = 0.5;
    } else if(phonePosition == ONHAND) {
        peakThreshold = 0.05;
    }
    
    //Apply appropriate threshold according to the position of the iPhone
    if (phonePosition == STANDINGUP || phonePosition == ONSIDE) {
        threshold = 0.5;
    } else if(phonePosition == ONHAND) {
        threshold = 0.07;
    }
    
    //Wait for enought elements
    if (vectorG.rows < (order+1)) {
        isStep = false;
    } else {
        
        //Run filter once we have enough data
        if (realTimeIndex > FILTERWINDOW) {
            
            Mat dataToFilter = vectorG.rowRange((realTimeIndex-1)-FILTERWINDOW, (realTimeIndex));
            filteredSubData = filter(dataToFilter);
            
            //Allocate space at the end of the matrix in order to do the copying
            Mat temp = Mat::ones(1,1,CV_64FC1) * 0;
            filteredData.push_back(temp.clone());
            
            Mat dest(filteredSubData.rowRange(0, filteredSubData.rows));
            dest.copyTo(filteredData.rowRange((realTimeIndex-1)-FILTERWINDOW,(realTimeIndex)));
            
        } else {
            filteredData = filter(vectorG);
        }
        
        //Check to see if zero crossing exist
        if(sign(filteredData.at<double>(realTimeIndex-1)) != sign(filteredData.at<double>(realTimeIndex - 2))){
            
            if (firstStepDetected == 0) {
                stepsDetected.at<int>(realTimeIndex-1) = 1;
                indexesDetectedSteps.push_back(realTimeIndex);
                isStep = true;
                firstStepDetected = 1; //Clear Flag
                
            } else {
                
                cout << indexesDetectedSteps << endl;
                
                //Check the difference in time between the last zero cross and the actual one
                index = indexesDetectedSteps.at<int>(indexesDetectedSteps.rows-1);//(int)indexesDetectedSteps.back();
                timeLastZeroCross = vectorTime.at<double>(index-1);
                
                if ((time - timeLastZeroCross) >= TIMETOOCCUR) {
                    
                    end = realTimeIndex-1;
                    start = indexesDetectedSteps.at<int>(indexesDetectedSteps.rows-1);
                    Mat dataToCheck = filteredData.rowRange(start, end);
                    
                    double minVal, maxVal;
                    minMaxIdx(dataToCheck, &minVal, &maxVal);
                    
                    if(fabs(minVal) > threshold || fabs(maxVal) > threshold) {
                        
                        stepsDetected.at<int>(realTimeIndex-1) = 1;
                        indexesDetectedSteps.push_back(realTimeIndex);
                        isStep = true;
                        
                    }
                }
            }
            
        }
        
    }
    
    return isStep;
    
}

float DetectSteps::calibrateStepsCounter(void){
	int stepsToCount = 20;
	vector<float> times;
	vector<int> errorTimes;
	for(float i=0.1; i <= 1.20002; i+=0.05){
		times.push_back(i);
		int detectedSteps = jayalathAlgorith(i);
		errorTimes.push_back(abs(stepsToCount - detectedSteps));
	}
    
	return getAverageFromLeastErrors(errorTimes, times);
}

float DetectSteps::getAverageFromLeastErrors(vector<int> errorTimes, vector<float> times){
    
	vector<int> minimums;
	int minimum = 255;
	float average = 0.0;
    
    
	//find minimum value
	for(unsigned int i = 0; i < errorTimes.size(); i++)
		minimum = errorTimes.at(i) < minimum ? errorTimes.at(i) : minimum;
    
	//find all the indexes having the minimum
	for(unsigned int i = 0; i < errorTimes.size(); i++)
		if(errorTimes.at(i) == minimum)
			minimums.push_back(i);
    
	//find the average of times
	for(unsigned int i = 0; i < minimums.size(); i++)
		average += times.at(minimums.at(i));
    
	average /= (float)minimums.size();
    
	return average;
}

void DetectSteps::resetRealTime(void) {
    
    filteredData.release();
    vectorG.release();
    vectorTime.release();
    stepsDetected.release();
    realTimeIndex = 0;//Start at -1 so that all the ranges go from 0 to n-1
    firstStepDetected = 0;
    indexesDetectedSteps.release();
}

Mat DetectSteps::rawDetectedSteps(void) {
    return stepsDetected.clone();
}


int DetectSteps::sign(double value){
	if(value > 0)
		return 1;
	if(value < 0)
		return -1;
	return 0;
}

