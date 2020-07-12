/*
*
*Name  :  ScheduleDeleteJobs
*Author:  Appirio India (Sai Krishna)
*Date  :  April 10, 2017
*Purpose : Schedule class which calls to delete the Async Jobs
*
*/
global with sharing class ScheduleDeleteJobs implements Schedulable {
    global static String CRON_EXP = '0 0 6 ? * MON,WED,FRI  *';
    
    global void execute(SchedulableContext SC) {
      //Schedule the Class
      DeleteOldAsyncApexJobs.asyncJobCount();  
      
   }
}