/*
*
*Name  :  LimitsHistoryDailySchedulable
*Author:  ACLU (David Reed)
*Date  :  July 07, 2017
*Purpose : Scheduler Class to for LimitsHistoryHandler
*
*/
global class LimitsHistoryDailySchedulable implements Schedulable {
    global void execute(SchedulableContext sctx) {
        // Get our execution context.
        CronTrigger ct = [SELECT CronJobDetail.Name FROM CronTrigger WHERE Id = :sctx.getTriggerId() LIMIT 1];

        LimitsHistoryHandler.runTasks(ct.CronJobDetail.Name);
    }
}