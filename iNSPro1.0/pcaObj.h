//
//  pcaObj.h
//  iPhoneNavigationSystem
//
//  Created by German H Flores on 5/5/13.
//  Copyright (c) 2013 German H Flores. All rights reserved.
//

#ifndef __iPhoneNavigationSystem__pcaObj__
#define __iPhoneNavigationSystem__pcaObj__

#include <iostream>
#include <fstream>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <string.h>

class pcaObj {
    
public:
    
    //Constructor
    pcaObj(std::string);
    pcaObj(cv::Mat, cv::Mat, cv::Mat);
    ~pcaObj();
    
    cv::Mat getEigenVectors(void);
    cv::Mat getEigenValues(void);
    cv::Mat getMean(void);
    cv::Mat getData(void);
    cv::Mat getDataProjected(void);
    int getNumberOfRecords(void);
    
private:
    
    //Variables
    cv::Mat data;
    cv::Mat dataProjected;
    cv::PCA pcaResult;
    int dataSize;
    
    
    void readCSVFile(std::string);
    int numberOfRecords(std::string);
    void projectData(void);
    cv::Mat getDataBackProjected(void);
    
};

#endif /* defined(__iPhoneNavigationSystem__pcaObj__) */
