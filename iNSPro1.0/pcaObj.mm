//
//  pcaObj.cpp
//  iPhoneNavigationSystem
//
//  Created by German H Flores on 5/5/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#include "pcaObj.h"

using namespace cv;
using namespace std;

pcaObj::pcaObj(string fileName) {
    
    //Read CSV File with the data
    readCSVFile(fileName);
    
    //Calculate pca
    pcaResult(data, Mat(), 0, 0);
    
    projectData();
    //dataProjected = pcaResult.project(data);
}

pcaObj::pcaObj(cv::Mat roll, cv::Mat pitch, cv::Mat yaw) {
    
    data = Mat::zeros(roll.rows,3,CV_64FC1);
    dataSize = data.rows;
    
    for (int i=0; i<data.rows; i++) {
        data.at<double>(i,0) = roll.at<double>(i);
        data.at<double>(i,1) = pitch.at<double>(i);
        data.at<double>(i,2) = yaw.at<double>(i);
    }
    
    //Calculate pca
    pcaResult(data, Mat(), 0, 0);
    
    projectData();
    
}


pcaObj::~pcaObj() {
    
    //Variables
    data.release();
    dataProjected.release();
}


Mat pcaObj::getEigenVectors(void) {
    return pcaResult.eigenvectors.clone();
}

Mat pcaObj::getEigenValues(void) {
    return pcaResult.eigenvalues.clone();
}

Mat pcaObj::getMean(void) {
    return pcaResult.mean.clone();
}

Mat pcaObj::getData(void) {
    return data.clone();
}

//Data rotated after dot product
Mat pcaObj::getDataProjected(void) {
    return dataProjected.clone();
}

//From PCA library
Mat pcaObj::getDataBackProjected(void) {
    return pcaResult.backProject(dataProjected).clone();
}

int pcaObj::getNumberOfRecords(void) {
    return dataSize;
}

void pcaObj::projectData(void) {
    
    Mat eigVect = pcaResult.eigenvectors;
    
    Mat pc = Mat::zeros(3, 1,CV_64FC1);
    Mat a = Mat::zeros(3, 1,CV_64FC1);
    
    //Main component in along the colunms. So need to put it in row format
    pc.at<double>(0,0) = eigVect.at<double>(0,0);
    pc.at<double>(1,0) = eigVect.at<double>(0,1);
    pc.at<double>(2,0) = eigVect.at<double>(0,2);
    
    
    Mat rotData = Mat::zeros(dataSize, 1, CV_64FC1);
    
    for (int i=0; i<dataSize; i++ ) {
        
        a.at<double>(0,0) = data.at<double>(i,0);//roll
        a.at<double>(1,0) = data.at<double>(i,1);//pitch
        a.at<double>(2,0) = data.at<double>(i,2);//yaw
        
        
        rotData.at<double>(i,0) = a.dot(pc)/norm(pc);
    }
    
    dataProjected = rotData.clone();
}

int pcaObj::numberOfRecords(string fileName) {
    
    char *charFileName = (char*)fileName.c_str();
    int counter = -1; //Start at -1 to remove extra at end
    string record;
    
    //Open read stream
    ifstream myfile (charFileName);
    
    if (myfile.is_open()) {
        while ( myfile.good() ) {
            getline (myfile,record); counter++;
        }
        myfile.close();
    }
    
    dataSize = counter;
    
    return counter;
}


void pcaObj::readCSVFile(string fileName) {
    
    int row = 0;
    int col = 0;
    char *tokens;
    string record;
    
    //Convert filename to char array
    char *charFileName = new char[fileName.size()+1];
    charFileName[fileName.size()] = 0;
    memcpy(charFileName,fileName.c_str(),fileName.size());
    
    int numOfRecords = numberOfRecords(fileName);
    data = Mat::zeros(numOfRecords,3,CV_64FC1);
    
    //Open read stream
    ifstream myfile (charFileName);
    
    //Extract the values and store in matrix
    if (myfile.is_open()) {
        while ( myfile.good() ) {
            getline (myfile,record);
            tokens = strtok ((char*)record.c_str(),",");
            
            while (tokens != NULL && col < 3) {
                tokens = strtok (NULL, ",");
                data.at<double>(row,col) = atof(tokens);
                col++;
            }
            
            col = 0;
            row++;
        }
        myfile.close();
    }
    
}