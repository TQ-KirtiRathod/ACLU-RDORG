//
// (c) 2018 Appirio, Inc.
//
// Test class for Scheduler Class of BatchOnCampaignMember
//
// Aashita Sharma (Appirio) Original
//
@isTest
private class BatchOnCampaignMember_ScheduleTest {

  private static testMethod void testBatchOnCampaignMember_Schedule() {
        Test.startTest();
            String sch = '0 0 * * * ?';
            String jobID = system.schedule('Test', sch,  new BatchOnCampaignMember_Schedule());
            CronTrigger ct = [  SELECT ID, CronExpression
                                FROM CronTrigger 
                                WHERE id = :jobID];
            system.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
  }
}