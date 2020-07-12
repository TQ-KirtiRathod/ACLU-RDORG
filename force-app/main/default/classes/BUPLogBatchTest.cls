//This class is a test class Batch_Log_Scheduler and this is added by RoundCorner Team
///Added By : RoundCorner Team ZenDesk #65149
@isTest
public class BUPLogBatchTest {
    @isTest
    static void testschedule()
    {
        getBatchUploadSettings();
        test.startTest();
        Datetime sysTime = System.now().addSeconds( 5 );
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        String jobName = BUPLogScheduler.Class.getName() + sysTime;
        BUPLogScheduler  monitorSchedule = new BUPLogScheduler();
        System.schedule(jobName, chronExpression, monitorSchedule);
        test.stopTest();
        List<BUP_Log__c> bupLogs = new List<BUP_Log__c>();
        bupLogs  = [SELECT id FROM BUP_Log__c];
        System.assertEquals(bupLogs != null , true);
    }
    public static testmethod rC_BUP__Batch_Upload_Framework_Settings__c getBatchUploadSettings() {
        rC_BUP__Batch_Upload_Framework_Settings__c frameworkSettings = rC_BUP__Batch_Upload_Framework_Settings__c.getInstance();
        if(frameworkSettings == null 
         || frameworkSettings.rC_BUP__Framework_Scheduler_Timeout_In_Minutes__c == null 
         || frameworkSettings.rC_BUP__Monitor_Scheduler_Interval_Time_Second__c == null) {
            frameworkSettings = new rC_BUP__Batch_Upload_Framework_Settings__c(rC_BUP__Enable_Delete_Events_and_Queues__c = false
                                                                     , rC_BUP__Framework_Scheduler_Timeout_In_Minutes__c = 5
                                                                     , rC_BUP__Monitor_Scheduler_Interval_Time_Second__c = 30
                                                                     , rC_BUP__BUF_CompletedEventScheduler_Scope__c = 1500
                                                                     , rC_BUP__BUF_CompletedQueueScheduler_Scope__c = 2000
                                                                     , rC_BUP__BUF_ErrorEventScheduler_Scope__c = 2000
                                                                     , rC_BUP__BUF_NewEventScheduler_Scope__c = 2000
                                                                     , rC_BUP__BUF_NewQueueScheduler_Scope__c = 2000
                                                                     , rC_BUP__Run_Monitor_Scheduler_After_Matching__c = true
                                                                     , rC_BUP__System_Failure_Scheduler_Time_In_Hrs__c = 1
                                                                     , rC_BUP__In_Progress_Queue_Timeout_In_Min__c = 120
                                                                     , BUPLogTimeoutInMinutes__c = 15);
        } else {
            frameworkSettings.rC_BUP__System_Failure_Scheduler_Time_In_Hrs__c = 1;
            frameworkSettings.rC_BUP__In_Progress_Queue_Timeout_In_Min__c = 1;
        }
        upsert frameworkSettings;
        return frameworkSettings;
    }

}