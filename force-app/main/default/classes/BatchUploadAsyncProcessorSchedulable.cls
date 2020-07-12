global class BatchUploadAsyncProcessorSchedulable implements Schedulable {
    

    global void execute(SchedulableContext SC) {
        
        List<AsyncRequest__c> customCommitAsyncRequestList = new List<AsyncRequest__c>();
        
		List<AsyncRequest__c> asyncRequestList = [SELECT ID 
                                                       , AsyncType__c
                                                       , Params__c
                                                       , Object_API_Name__c
                                                       , AutoRetry_Count__c
                                                       , Error_Message__c
                                                    FROM AsyncRequest__c
                                                   WHERE Error__c = true
                                                     AND Object_API_Name__c = 'rC_Connect__Batch_Upload__c'
                                                   LIMIT 1 FOR UPDATE];
        if(asyncRequestList != null && asyncRequestList.size()>0){
            Set<String> batchUploadStatues = new Set<String>();
            batchUploadStatues.add('New');
            batchUploadStatues.add('Ready');
            batchUploadStatues.add('In Progress');
            List<Id> batchUploadIds = asyncRequestList[0].Params__c.split(',');
            System.debug(batchUploadIds);
            integer count = [SELECT count() 
                             FROM rC_Connect__Batch_Upload__c 
                            WHERE  id IN :batchUploadIds
                              AND rC_Connect__Batch_Upload_Status__c IN : batchUploadStatues];
            System.debug(count);
            if(count==0) {
                delete asyncRequestList;
                List<String> btupsIds  = getFlaggedBUList();
                if(btupsIds != null && btupsIds.size() > 0) {
                    getCustomAsyncObj(customCommitAsyncRequestList,btupsIds);
                }
            }
        }else {
            List<String> btupsIds  = getFlaggedBUList();
            if(btupsIds.size() > 0){
                getCustomAsyncObj(customCommitAsyncRequestList,btupsIds);
            }
        }
        //reRunSchedule();
	}
    public List<Id> getFlaggedBUList() {
		Integer batchUploadAsyncBatchMax = 0;
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null && q.Batch_size_BatchUpload__c != null) {
            batchUploadAsyncBatchMax = integer.ValueOf(q.Batch_size_BatchUpload__c);
        } else {
            batchUploadAsyncBatchMax = 100;
        }  
        List<String> btupsIds = new List<String>();
        integer errorCount = integer.valueof(System.Label.Batch_Upload_Error_Retry_Limit);
        List<rC_Connect__Batch_Upload__c> buList = new List<rC_Connect__Batch_Upload__c>();
	    buList = [SELECT id 
                  , rC_Connect__Batch_Upload_Flagged_Technical_Reason__c
                  , rC_Connect__Batch_Upload_Flagged_Reason__c
                  , rC_Connect__Batch_Upload_Status__c
                  , Error_Count__c
                  FROM  rC_Connect__Batch_Upload__c
                  WHERE  (rC_Connect__Batch_Upload_Status__c = 'Flagged'
                          AND  rC_Connect__Batch_Upload_Flagged_Reason__c = 'Salesforce System Exception'
                  		  AND Error_Count__c <= :errorCount)
                  LIMIT  :batchUploadAsyncBatchMax];
        
        if(buList != null && buList.size()> 0) {
            for(rC_Connect__Batch_Upload__c btups :buList) {
                if(btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c != null 
                 && btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.containsIgnoreCase(Label.Salesforce_System_Exception)
                 && btups.rC_Connect__Batch_Upload_Flagged_Reason__c != null 
                 && btups.rC_Connect__Batch_Upload_Flagged_Reason__c.containsIgnoreCase('Salesforce System Exception')) {
                     btups.rC_Connect__Batch_Upload_Status__c = 'New';
                    btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = null;
                    btups.rC_Connect__Batch_Upload_Error_Category__c = null;
                    btups.rC_Connect__Batch_Upload_Flagged_Data__c = false;
                    btups.rC_Connect__Batch_Upload_Flagged_Matched__c = false;
                    btups.rC_Connect__Batch_Upload_Flagged_Reason__c = null;
                     btupsIds.add(btups.id);
                 }
                
        	}
        update buList;
        }
        return btupsIds;
    }
    public void getCustomAsyncObj(List<AsyncRequest__c> customCommitAsyncRequestList,List<id> btupsIds) {
        customCommitAsyncRequestList.add(new AsyncRequest__c(AsyncType__c ='batchUpload_SystemExceptionSet', 
                                                                     Object_API_Name__c = 'rC_Connect__Batch_Upload__c',
                                                                     Error__c = true,
                                                                     Params__c = String.join(btupsIds,',')));
        insert customCommitAsyncRequestList;
    }
    /*public void reRunSchedule(){
        Datetime sysTime = System.now();
        String jobName = BatchUploadAsyncProcessorSchedulable.Class.getName() + sysTime;
        BatchUploadAsyncProcessorSchedulable scheduleBU = new BatchUploadAsyncProcessorSchedulable();
        try {
            System.schedule(jobName, '0 15 * * * ?', new BatchUploadAsyncProcessorSchedulable());
        } catch (Exception ex) {
            System.schedule(jobName, '0 30 * * * ?', new BatchUploadAsyncProcessorSchedulable());
        }
    }*/
}