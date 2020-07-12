/*
*
*Name  :  RecordAccessQueueableClass
*Author:  Appirio India (Sai Krishna)
*Date  :  September 19, 2017
*Purpose : AsyncRequest processor to create the Apex sharing for the Child records. called from the QueueableCentralProcessor.
*
*/

public with sharing class RecordAccessQueueableClass  {
    public AsyncRequest__c incomingRequest;
    @TestVisible
    private  Map<Id,String> mapAccountIdToOldAffiliations;
    //class called from RecordAccessUtility by passing the mapAccountIdToOldAffiliations as parameter.
    public RecordAccessQueueableClass(AsyncRequest__c request) {
        incomingRequest = request;
        this.mapAccountIdToOldAffiliations = (Map<Id,String>)JSON.deserialize(incomingRequest.Params__c, Map<Id, String>.class);
    }

    public void createChildSharing() {
        try{
            //calls the setSharingForChildRecords method of RecordAccessUtility by passing mapAccountIdToOldAffiliations as parameter.
            RecordAccessUtility.setSharingForChildRecords(mapAccountIdToOldAffiliations);
        }
        catch(Exception e) {
	        update new AsyncRequest__c(Id=incomingRequest.id, Error__c = true, Error_Message__c = e.getMessage());	        
        }
    }
}