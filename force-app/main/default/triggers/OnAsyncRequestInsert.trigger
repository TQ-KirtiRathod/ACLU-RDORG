trigger OnAsyncRequestInsert on AsyncRequest__c (after insert, after update) {
    
    AsyncRequestTriggerHandler.mainEntry( Trigger.new, Trigger.oldMap, Trigger.isInsert ,Trigger.IsUpdate, Trigger.isAfter);
  
}