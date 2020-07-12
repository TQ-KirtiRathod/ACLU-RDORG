//Createdby: Salesforce.org :: 13 March 2019
//TS-502 :: Evaluating SMD Restart Solution
global class SMDScheduler implements Schedulable {

    global Integer delay;
    
    // Duration in minutes
    public SMDScheduler(Integer dispatcherDelay) {
    	delay = dispatcherDelay;
    }

    global void execute(SchedulableContext sc) {
    	// Get any scheduled service message dispatchers
        List<CronTrigger> cronTriggerList = getCronTriggerList();

        // Get any currently processing service message dispatchers
    	List<AsyncApexJob> asyncApexJobList = getAsyncJob();
        // Be extra cautious and try to get any scheduled service message dispatchers again in case timing was off first time around
        
        cronTriggerList.addAll(getCronTriggerList());
        // If no scheduled or processing service message dispatchers, call service message dispatcher
    	if (cronTriggerList.isEmpty() && asyncApexJobList.isEmpty()) {
    		Database.executeBatch(new rC_Connect.ServiceMessageDispatcher(delay),1);
    	}       
  	}
    
    private List<CronTrigger> getCronTriggerList() {
        Datetime now = Datetime.now();
        return [
            SELECT Id
                 , CronJobDetail.Name
                 , NextFireTime
                 , State 
              FROM CronTrigger 
             WHERE State = 'WAITING' 
               AND NextFireTime >= :now 
               AND CronJobDetail.Name = 'rC_Connect.ServiceMessageDispatcher'
       ];
    }
    
    private List<AsyncApexJob> getAsyncJob() {
        return [
            SELECT Id
                 , ApexClass.Name
                 , Status
                 , JobType 
              FROM AsyncApexJob  
             WHERE JobType IN ('BatchApexWorker','ScheduledApex') 
               AND Status IN ('Preparing','Queued','Processing','Holding') 
               AND ApexClass.Name = 'ServiceMessageDispatcher'
        ];
    }
}