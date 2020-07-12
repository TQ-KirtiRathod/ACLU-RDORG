@isTest
private class CreateAffiliationBatch_ScheduleTest {

	
	//Test method to test scheduling behaviour
    @isTest static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('Test', '0 0 * * * ?', new CreateAffiliationBatch_Schedule());
        Test.stopTest();
        system.assert(jobId != null);
    }  
}