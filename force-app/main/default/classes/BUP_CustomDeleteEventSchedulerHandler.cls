/*
*
*Name  :  BUP_CustomDeleteEventSchedulerHandler
*Author:  Niraj Shrikhande
*Date  :  Aug 23, 2017
*Purpose : Scheduler Class to BUP_CustomDeleteEventsBatchable.
*
*/
public with sharing class BUP_CustomDeleteEventSchedulerHandler {
     
     public static void execute(SchedulableContext SC) { 
        // Get the batchUploadFramework custom settting to define scope of batch class
        rC_BUP__Batch_Upload_Framework_Settings__c batchUploadFrameworkSettings = rC_BUP__Batch_Upload_Framework_Settings__c.getInstance();
        Integer batchSize = 200;
        
        if(batchUploadFrameworkSettings.Delete_Events_Batch_Scope__c != null) {
            batchSize = Integer.valueOf(batchUploadFrameworkSettings.Delete_Events_Batch_Scope__c);
        }
       
        Database.executeBatch(new BUP_CustomDeleteEventsBatchable(), batchSize);
        
     }
}