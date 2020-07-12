/*
*
*Name  :  BatchUploadGKUpdateDupsFlags_Batch
*Author:  Salesforce.com
*Date  :  Sept 10, 2019
*Purpose : This batch would reset the duplicate flags on batch upload records.
*
*/
public class BatchUploadGKUpdateDupsFlags_Batch implements Database.Batchable<sObject>, Database.stateful {
    public Set<String> batchUploadStatusSet = new Set<String> {
        'New Springboard',
        'New Non-Springboard'
    };

    public BatchUploadGKUpdateDupsFlags_Batch() { // constructor
    }
    
    public Database.QueryLocator start(Database.BatchableContext Bc ){
        String query = 'SELECT Id FROM rC_Connect__batch_upload__c' +
                        ' WHERE Is_Processing_Duplicate__c = true AND rC_Connect__Batch_Upload_Status__c IN :batchUploadStatusSet';//Add status
        return Database.getQueryLocator(query);   
    }
    
    public void execute(Database.BatchableContext Bc, List<rC_Connect__Batch_Upload__c> batchUploadList){
        rC_Connect__Batch_Upload__c[] batchUploadUpdateableList = new rC_Connect__Batch_Upload__c[] { };
            
        //Set processing flag to False
        for(rC_Connect__Batch_Upload__c batchUpload :batchUploadList) {
            batchUpload.Is_Processing_Duplicate__c = false;
            batchUploadUpdateableList.add(batchUpload);
        }
        
        // Update batch upload records
        if(batchUploadUpdateableList.size() > 0) {
            update batchUploadUpdateableList;
        }
    }
    
    public void finish(Database.BatchableContext Bc){ }
}