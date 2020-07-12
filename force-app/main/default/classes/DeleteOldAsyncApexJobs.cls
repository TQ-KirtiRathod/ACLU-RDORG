/*
*
*Name  :  DeleteOldAsyncApexJobs
*Author:  Appirio India (Sai Krishna)
*Date  :  April 10, 2017
*Purpose : Deletes the Old Async Jobs if there are more than 10K.
*
*/

public with sharing class DeleteOldAsyncApexJobs {
    
    public static void asyncJobCount(){
    	Integer asyncJobRecs = [SELECT COUNT() FROM AsyncApexJob];
    	Integer asyncJobRecsLimit = (Test.isRunningTest())?-1:100000;
    	//Deletes the AsyncApexJob.
    	if(asyncJobRecs > asyncJobRecsLimit){
    		Integer count = System.purgeOldAsyncJobs(Date.today().addDays(-3));  	
    	}
    } 
}