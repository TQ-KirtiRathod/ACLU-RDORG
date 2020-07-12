global class ACLUMergeScheduleContactMerge implements Schedulable{

    global Set<Id> accountIds;

    global void execute(SchedulableContext SC) {
        System.debug(LoggingLevel.ERROR, accountIds );
        ACLUMergeManager.accountAfterMerge_mergeContacts(accountIds);
        deleteJobs(); 
    }

    public ACLUMergeScheduleContactMerge(Set<Id> acctIds) {
        if (accountIds == null ) {
            accountIds = acctIds;
        } else {
            accountIds.addAll(accountIds);
        }
    }
    
    public static void deleteJobs(){
        Integer times = !Test.isRunningTest() ? 1 : 0; // in test execution the job will not have been triggered
        List<CronTrigger> crons = [SELECT Id FROM CronTrigger WHERE CronJobDetail.JobType = '7' and CronJobDetail.Name like 'DC Merge%' and TimesTriggered = :times];
    	if ((!crons.isEmpty() && crons.size() >= Integer.valueOf(System.Label.DCMerge_ContactJobThreshold)) || Test.isRunningTest()) {
            for(CronTrigger cron : crons) {
                if (cron != null) {
                    system.abortJob(cron.id);
                }
            }
        } 
    }
}