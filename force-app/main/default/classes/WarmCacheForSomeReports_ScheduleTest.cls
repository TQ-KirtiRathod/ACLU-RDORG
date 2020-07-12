//
// (c) 2018 Appirio, Inc.
//
// Test class for Scheduler Class of WarmCacheForSomeReports_Schedule
//
// Yohan Anand (Appirio) Original
//
@isTest
public class WarmCacheForSomeReports_ScheduleTest  {
    // Method to test Scheduler  
    private static testMethod void testWarmCacheForSomeReports_Schedule() {
        Test.startTest();
            String sch = '0 0 * * * ?';
            String jobID = system.schedule('Test', sch,  new WarmCacheForSomeReports_Schedule());
            CronTrigger ct = [  SELECT ID, CronExpression
                                FROM CronTrigger 
                                WHERE id = :jobID];
            system.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
    }
}