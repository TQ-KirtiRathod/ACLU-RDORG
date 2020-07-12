@isTest
private class LimitsHistoryDailySchedulableTEST {
	
	@isTest //Method to test LimitsHistoryDailySchedulable scheduling
    static void testSchedulable() {
        Test.startTest();
        System.schedule('Test', '0 0 * * * ?', new LimitsHistoryDailySchedulable());
        Test.stopTest();

        System.assertEquals(1, [SELECT count() 
                                FROM CronTrigger 
                                WHERE CronJobDetail.Name = :LimitsHistoryUtilities.LIMITS_DAILY_JOB_NAME]);
    }	
}