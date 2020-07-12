//
// (c) 2017 Appirio, Inc.
//
// Scheduler Class to for MatchBatchLogViaBatchUpload_Schedule
//
// Harshita Khandelwal (Appirio) Original
//
@isTest
private class MatchBatchLogViaBatchUpload_ScheduleTest {

	private static testMethod void testMatchBatchLogViaBatchUpload_Schedule() {
        Test.startTest();
            String sch = '0 0 * * * ?';
            String jobID = system.schedule('Test', sch,  new MatchBatchLogViaBatchUpload_Schedule());
            CronTrigger ct = [  SELECT ID, CronExpression
                                FROM CronTrigger 
                                WHERE id = :jobID];
            system.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
	}
}