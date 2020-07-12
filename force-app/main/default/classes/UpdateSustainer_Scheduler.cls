/*
*
*Name  :  UpdateSustainer_Scheduler
*Author:  SFDO (Amar Kulkarni)
*Date  :  March 24, 2020
*Purpose : To Schedule rc giving's update sustainer batch
*/

global class UpdateSustainer_Scheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
         AsyncApexJob[] AsyncApexJobList = [
             SELECT ApexClassId
                  , Id
                  , Status
                  , JobType
               FROM AsyncApexJob
              WHERE JobType IN ('BatchApexWorker','ScheduledApex')
                AND Status IN ('Preparing', 'Queued', 'Processing','Holding')
                                AND ApexClass.Name = 'Opportunity_UpdateSustainersBatchable'];
        
        if(AsyncApexJobList.size() == null ||
            AsyncApexJobList.size() == 0) {
				rC_Giving.Opportunity_UpdateSustainersBatchable.schedule(); 
                
            }
	}
}