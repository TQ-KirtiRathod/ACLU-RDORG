/*
*
*Name  :  BatchUpload_CreateSoftCreditBatch
*Author:  roundCorner Inc.
*Date  :  Nov 06, 2018
*Purpose : This batch would help to ignore Soft Credit - No Transaction to fulfill errors 
            and proceed towards committing the batch upload record.
*
*/
public class BatchUpload_CreateSoftCreditBatch  implements Database.Batchable<sObject>, Database.stateful {
    public static String query = '';
    
    public BatchUpload_CreateSoftCreditBatch() {
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext Bc ){
        //query
        query = 'SELECT Id, rC_BUP__Event_State__c, rC_BUP__Topic_Name__c, rC_BUP__Batch_Upload__c '+
                    ' , rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c ' +
                    ' , (SELECT Id, rC_BUP__Queue_State__c FROM rC_BUP__Queues__r) '+
                    ' FROM rC_BUP__Event__c '+
                    ' WHERE  rC_BUP__Batch_Upload__r.isSoft_Credit__c = true '+
                      ' AND rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Status__c = \'Flagged\' '+
                      ' AND rC_BUP__Topic_Name__c IN (\'Transaction_Topic\') '+
                      ' AND rC_BUP__Event_State__c = \'Suspend\'';

            return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext Bc, List<rC_BUP__Event__c> eventList){
        System.debug('eventList :: ' + eventList);
        rC_BUP__Event__c[] eventTransactionList = new rC_BUP__Event__c[] { };
        Set<String> batchUploadIdSet = new Set<String>();
        //Filter the batch upload records with Error
        for(rC_BUP__Event__c event :eventList) {
            String errorReason = event.rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c;
            if(String.isNotBlank(errorReason) && errorReason.containsIgnoreCase('No Remaining')) {
                eventTransactionList.add(event);
                batchUploadIdSet.add(event.rC_BUP__Batch_Upload__c);
            }
        }
        
        ignoreSoftCreditTransactionError(eventTransactionList, batchUploadIdSet);
    }
    
    public void finish(Database.BatchableContext Bc){
        // Nothing
    }
    
    //Ignore Soft Credit Transaction having an error as 'No Remaining Transaction to fulfill'
    private static void ignoreSoftCreditTransactionError(rC_BUP__Event__c[] eventList, Set<String> batchUploadIdSet) {
        rC_BUP__Event__c[] batchUploadTopicDeleteList = new rC_BUP__Event__c[] { };
        rC_BUP__Event__c[] eventUpdateableList = new rC_BUP__Event__c[] { };
        rC_BUP__Queue__c[] queueUpdateableList = new rC_BUP__Queue__c[] { };
        Set<rC_Connect__Batch_Upload__c> batchUploadSet = new Set<rC_Connect__Batch_Upload__c>();
        System.debug('eventList :: ' + eventList);
        
        batchUploadTopicDeleteList = [SELECT Id, rC_BUP__Batch_Upload__c FROM rC_BUP__Event__c WHERE rC_BUP__Batch_Upload__c IN :batchUploadIdSet AND rC_BUP__Topic_Name__c = 'BatchUpload_Topic' AND rC_BUP__Event_State__c IN ('Complete', 'Processed')];
        
        for(rC_BUP__Event__c event :eventList) {
            // Ignore batch upload topic event which needs to deleted
            if(event.rC_BUP__Topic_Name__c == 'BatchUpload_Topic') {
                batchUploadTopicDeleteList.add(event);
                continue;
            }

            // Mark Transaction queues to Complete 
            for(rC_BUP__Queue__c queue :event.rC_BUP__Queues__r) {
                queue.rC_BUP__Queue_State__c = 'Complete';
                queueUpdateableList.add(queue);
            }

            rC_Connect__batch_Upload__c batchUpload = new rC_Connect__batch_Upload__c(Id =event.rC_BUP__Batch_Upload__c);
            if(String.isNotBlank(event.rC_BUP__Batch_Upload__r.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c)) {
                batchUpload.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = '';
                batchUpload.rC_Connect__Batch_Upload_Error_Category__c = '';
                batchUpload.rC_Connect__Batch_Upload_Flagged_Reason__c = '';
                batchUpload.rC_Connect__Batch_Upload_Flagged_Data__c = false;
                batchUpload.rC_Connect__Batch_Upload_Status__c = 'In Progress';
                batchUploadSet.add(batchUpload);
            }
            event.rC_BUP__Event_State__c = 'In Progress';
            eventUpdateableList.add(event);
        }
        System.debug('batchUploadTopicDeleteList :: ' + batchUploadTopicDeleteList);
        // Adding batch upload set into list where it needs to e updated
        List<rC_Connect__Batch_Upload__c> batchUploadUpdateableList = new List<rC_Connect__Batch_Upload__c> (batchUploadSet);
        Savepoint savepoint = Database.setSavepoint();
        try {
            
            // Update Queue, Event and Batch Upload
            if(eventUpdateableList.size() > 0) {
                update queueUpdateableList;
                update eventUpdateableList;
                update batchUploadUpdateableList;
            }
            
            // Delete Batch Upload topic which is not required
            if(batchUploadTopicDeleteList.size() > 0) {
                delete batchUploadTopicDeleteList;
            }
            
        }catch(Exception ex) {
            System.debug('Exception :: ' + ex.getMessage());
            Database.rollback(savepoint);
        }
        
  }
}