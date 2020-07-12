/*Description - This class is used to abort the BUP's main schedulers
Created By - SFDO (KIRTI RATHOD)
Created Date - 15th April 2020*/
Public class AbortApexJobScheduler implements Schedulable {
    
    Public void execute(SchedulableContext ctx) {
      //Remove
      Set<String> apexJobs = new Set<String>{'BUF_NewEventSchedulable','BUF_CompletedEventSchedulable','BUF_ErrorEventSchedulable'
            									,'BUF_CompletedQueueSchedulable','BUF_NewQueueSchedulable'};
	    rC_BUP__Batch_Upload_Framework_Settings__c bupFrameworkSetting = rC_BUP__Batch_Upload_Framework_Settings__c.getOrgDefaults();
        Datetime abortTime =  System.now().addMinutes(-(30)); 
        if(bupFrameworkSetting != null && bupFrameworkSetting.BUP_QueuedJobTimeout__c!= null) {
         	 abortTime = System.now().addMinutes(-(Integer.ValueOf(bupFrameworkSetting.BUP_QueuedJobTimeout__c))); 
        }
       
        List<AsyncApexJob> asyncApexJobList = new List<AsyncApexJob>();  
        if(test.isRunningTest()) {
           asyncApexJobList = [SELECT Id, ApexClassID, ApexClass.Name, CompletedDate, ExtendedStatus, 
                               		  JobItemsProcessed, JobType, MethodName,Status, TotalJobItems,CreatedById
           					     FROM AsyncApexJob];
            
        }else {
             asyncApexJobList = [SELECT Id,CreatedDate, ApexClassID, ApexClass.Name, Status,JobType,CreatedById  
                                   FROM AsyncApexJob
                                  WHERE Status = 'Queued' 
                                    AND (ApexClass.Name IN :apexJobs 
                                        OR ApexClass.Name LIKE 'BUP_%')
                                    AND CreatedDate <= :abortTime];
        }
        BUP_Log__c[] bupLogInsertList = new BUP_Log__c[]{ };
        for(AsyncApexJob asyncJob :asyncApexJobList) {
            try {
                System.debug(asyncJob.CreatedDate);
                System.debug(abortTime);
              System.abortJob(asyncJob.id);   
              bupLogInsertList.add(createBUPLog(asyncJob, null));
            } catch(Exception ex){ 
              bupLogInsertList.add(createBUPLog(asyncJob, ex));
            }
		    }  

        if(bupLogInsertList.size() > 0) {
          insert bupLogInsertList;
        }
    }

  private BUP_Log__c createBUPLog(AsyncApexJob asyncJob, Exception ex) {
    BUP_Log__c log = new BUP_Log__c();
    log.Details__c = 'Job Name: '+ asyncJob.ApexClass.Name +'; Id:'+asyncJob.Id;
    log.Error_Message__c = ex != null ? ex.getMessage() : '';
    log.Type__c = asyncJob.JobType;
    log.Status__c = ex == null ? 'Aborted' :  asyncJob.Status;
    log.Created_By__c = asyncJob.CreatedById; 

    return log;
  }
}