/*
*
*Name  :  BUP_CustomDeleteEventsBatchable
*Author:  roundCorner Inc. (Niraj Shrikhande)
*Date  :  Aug 22, 2017
*Purpose : This batch deletes the events for which batch upload records are committed and event state is processed.
*
*/
global class BUP_CustomDeleteEventsBatchable implements Database.Batchable<sObject> {
    public static String EVENT_STATE_PROCESSED = 'Processed';
    public static String BATCH_UPLOAD_STATUS_COMMITTED = 'Committed';
    public static String EVENT_STATE_MATCHING_COMPLETE = 'Matching Complete';
   
    global Database.queryLocator start( Database.BatchableContext bc ) {
        // Get the batchUploadFramework custom settting
        rC_BUP__Batch_Upload_Framework_Settings__c batchUploadFrameworkSettings = rC_BUP__Batch_Upload_Framework_Settings__c.getInstance();
        Integer deleteEventsPriorTo = 1;
        DateTime deleteDateTime = DateTime.now();
        
        if (Test.isRunningTest()) {
            deleteEventsPriorTo = 0;
        } else if(batchUploadFrameworkSettings != null && batchUploadFrameworkSettings.Delete_Events_Prior_to__c != null) {
           deleteEventsPriorTo = Integer.valueOf(batchUploadFrameworkSettings.Delete_Events_Prior_to__c);
        } 
      
        //Calculate LastModified dateTime to delete Events
        deleteDateTime = deleteDateTime.AddHours(-deleteEventsPriorTo);
        
        string eventQuery =  'SELECT Id '
                            +   ', rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c'
                            +   ', rC_BUP__Event_State__c FROM rC_BUP__Event__c' 
                            + ' WHERE  (rC_BUP__Event_State__c =: EVENT_STATE_PROCESSED'
                            +        ' OR rC_BUP__Event_State__c =: EVENT_STATE_MATCHING_COMPLETE)'
                            +  ' AND rC_BUP__Batch_Upload__r.LastModifiedDate  <= : deleteDateTime'  
                            +  ' AND  rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c =: BATCH_UPLOAD_STATUS_COMMITTED' 
                            +  ' ORDER BY rC_BUP__Batch_Upload__r.LastModifiedDate ASC';
                            
        //List<rC_BUP__Event__c> lst = [SELECT Id 
        //                    , rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c
        //                    , rC_BUP__Event_State__c 
        //                     FROM rC_BUP__Event__c
        //                     WHERE  (rC_BUP__Event_State__c =: EVENT_STATE_PROCESSED
        //                     OR rC_BUP__Event_State__c =: EVENT_STATE_MATCHING_COMPLETE)
        //                     AND rC_BUP__Batch_Upload__r.LastModifiedDate  <= : deleteDateTime
        //                    ORDER BY rC_BUP__Batch_Upload__r.LastModifiedDate ASC];
        return Database.getQueryLocator(eventQuery);
    }
    
    /**
     * @Description: Used to delete event record whose parent record( rC_Connect__Batch_Upload ) has batch upload status picklist value
     *              Committed and event state as processed and LastModified date less then calculated datetime..
     * @Param: 1. Database.BatchableContext
     *         2. eventList( list of Event record )
     * @Return: NA 
     **/
    global void execute(Database.BatchableContext bc, List<rC_BUP__Event__c> eventList ) {
        // Check list has record.
        if( eventList == null || eventList.size() == 0 ) {
            return;
        }
        // Delete Event records        
        Database.delete(eventList, false);
        database.emptyRecycleBin(eventList);
    }
    
    global void finish( Database.batchableContext bc ) {
            
    }
}