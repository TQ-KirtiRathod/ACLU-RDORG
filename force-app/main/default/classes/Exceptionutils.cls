/*
*
*Name  :  Exceptionutils
*Author:  Appirio India (Sai)
*Date  :  Oct 09, 2017
*Purpose : Utility Class to create Apex Log files, methods can be used to reuce the number of lines of code in a class
*
*/
public with sharing class Exceptionutils {
    
    public static void createApexLog(String className, String methodName, Exception  e){
        apexLogHandler.apexLog log = new apexLogHandler.apexLog(className, methodName, e.getMessage());
        log.logException(e);
        log.saveLogs();
    }

    public static void createApexLog(String className, String methodName, Exception e, String s){
        apexLogHandler.apexLog log = new apexLogHandler.apexLog(className, methodName, s);
        log.logException(e);
        log.saveLogs();
    }  
}