/*
*
*Name  :  BUP_CustomDeleteEventSchedulableData
*Author:  Niraj Shrikhande
*Date  :  Aug 24, 2017
*Purpose : This class is used to create test data for BUP_CustomDeleteEventsSchedulableTest
*
*/
@isTest
public class BUP_CustomDeleteEventSchedulableData {
    
    /**
     * @Description: Used to create rC_Connect__Batch_Upload  records.
     * @Param: 1. numberOfRecord( Number of record to create )
     *         2. batchUploadStatus ( value for Batch upload status picklist )
     * @Return: list of rC_Connect__Batch_Upload__c record
     **/
    public list<rC_Connect__Batch_Upload__c> createBatchUploadRecord( Integer numberOfRecord, string batchUploadStatus ) { 
        
        list<rC_Connect__Batch_Upload__c> batchUploadList = new list<rC_Connect__Batch_Upload__c>();
        for( integer count = 0; count < numberOfRecord; count++ ) {
            
            batchUploadList.add( new rC_Connect__Batch_Upload__c( Name = 'TestBatchUpload'+count, rC_Connect__Batch_Upload_Status__c = batchUploadStatus ) );
        }
        return batchUploadList;
    }
    
    /**
     * @Description: Used to Event  records.
     * @Param: 1. numberOfRecord( Number of record to create )
     *         2. batchUploadRecordId ( rC_Connect__Batch_Upload record id )
     * @Return: list of Event record
     **/
    public list<rC_BUP__Event__c> createEventRecord( integer numberOfRecord, Id batchUploadRecordId,String status ) {
        
        list<rC_BUP__Event__c> eventList = new list<rC_BUP__Event__c>();
        for( integer count = 0; count < numberOfRecord; count++ ) {
            
            eventList.add( new rC_BUP__Event__c(  rC_BUP__Batch_Upload__c = batchUploadRecordId, rC_BUP__Topic_Sequence__c = count, rC_BUP__Event_State__c = status ) );
        }
        return eventList;
    }
    
    public void createBatchUploadFrameworkSettings() {
        
        rC_BUP__Batch_Upload_Framework_Settings__c batchUploadFrameworkSettings = new rC_BUP__Batch_Upload_Framework_Settings__c();
        batchUploadFrameworkSettings.Delete_Events_Batch_Scope__c = Integer.valueOf('200');
        batchUploadFrameworkSettings.Delete_Events_Prior_to__c = Integer.valueOf('0');
        batchUploadFrameworkSettings.rC_BUP__BUF_ErrorEventScheduler_Scope__c= 200;
        batchUploadFrameworkSettings.rC_BUP__BUF_CompletedEventScheduler_Scope__c = 200;
        batchUploadFrameworkSettings.rC_BUP__BUF_CompletedQueueScheduler_Scope__c = 200;
        batchUploadFrameworkSettings.rC_BUP__BUF_NewEventScheduler_Scope__c = 200;
        batchUploadFrameworkSettings.rC_BUP__BUF_NewQueueScheduler_Scope__c = 200;
        batchUploadFrameworkSettings.rC_BUP__Monitor_Scheduler_Interval_Time_Second__c = 1;
        batchUploadFrameworkSettings.rC_BUP__System_Failure_Scheduler_Time_In_Hrs__c = 3;
        batchUploadFrameworkSettings.rC_BUP__In_Progress_Queue_Timeout_In_Min__c = 30;
        batchUploadFrameworkSettings.rC_BUP__Framework_Scheduler_Timeout_In_Minutes__c = 30;
        insert batchUploadFrameworkSettings;
    }
}