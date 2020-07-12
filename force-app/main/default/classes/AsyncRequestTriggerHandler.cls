/*
*
*Name  :  AsyncRequestTriggerHandler
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  March 28, 2017
*Purpose : Handler class for AsyncRequest Trigger
*
*/
public class AsyncRequestTriggerHandler {
    public static void mainEntry(List<AsyncRequest__c> newList, Map<Id, AsyncRequest__c> oldMap, 
                     Boolean isInsert, Boolean isUpdate, Boolean isAfter) {
        //If Trigger is active
        if(TriggerState.isActive('AsyncRequestTrigger')
          && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) ) {
            if(isAfter) {
                if(isUpdate) {
                    onAfterUpdate(newList, oldMap);
                }
                if(isInsert) {
                    onAfterInsert();
                }   
            }
        }
        
            
         
    }
    public static void onAfterInsert(){
        try {
            if(Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                QueueableCentralProcessor.enqueueAsyncRequest(null); 
            }
            // note: if you're sending in a batch size greater than 1, QueueableCentralProcessor execute method chains each AsyncRequest__c for this batch
        } catch(Exception ex) {
            // Ignore for now
        }
    }

    public static void onAfterUpdate( List<AsyncRequest__c> newList , Map<Id, AsyncRequest__c> oldMap ){
        List<AsyncRequest__c> asyncReqToUpdate = new List<AsyncRequest__c>();
        for( AsyncRequest__c req : newList ){
            if( req.Error__c != oldMap.get(req.id).Error__c && req.Error__c == TRUE 
                && req.AutoRetry_Count__c < integer.valueof(Label.AsyncRequest_AutoRetry_Count) ){
                asyncReqToUpdate.add(req);
            }
        }
        if( asyncReqToUpdate.size() > 0 ){
            updateAsyncReq( asyncReqToUpdate );
        }
        
        
    }
    
    public static void updateAsyncReq( List<AsyncRequest__c> asyncList ){
        List<AsyncRequest__c> asyncReqToUpdate = new List<AsyncRequest__c>();
        for(AsyncRequest__c req: [Select Id,Error__c FROM AsyncRequest__c WHERE Id IN: asyncList ]){
            req.Error__c = False;
            asyncReqToUpdate.add(req);
        }
        if( asyncReqToUpdate.size()> 0 ){
            update asyncReqToUpdate;
            try {
                if(Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                    QueueableCentralProcessor.enqueueAsyncRequest(null);
                }
                // note: if you're sending in a batch size greater than 1, QueueableCentralProcessor execute method chains each AsyncRequest__c for this batch
            } catch(Exception ex) {
                // Ignore for now
            }
        }
        
    }
}