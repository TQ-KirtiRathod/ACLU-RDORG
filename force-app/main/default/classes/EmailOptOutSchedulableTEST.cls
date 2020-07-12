@isTest
private class EmailOptOutSchedulableTEST {
	
	@isTest static void testSchedulable() {
		new EmailOptOutSchedulable().execute(null);
        System.assertEquals(1, [SELECT count() FROM AsyncApexJob WHERE AsyncApexJob.ApexClass.Name = 'EmailOptOutProcessorBatch']);
	}	
}