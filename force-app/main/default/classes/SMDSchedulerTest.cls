@isTest
private class SMDSchedulerTest {
	
	@isTest private static void testSchedule() {
        Date dtSchedule = Date.today().addYears(1);
		String CRON_EXP = '0 0 0 15 3 ? ' + String.valueOf(dtSchedule.year());
		Test.startTest();
		System.schedule('ScheduleApexClass', CRON_EXP, new SMDScheduler(5));
		Test.stopTest();
	}
}