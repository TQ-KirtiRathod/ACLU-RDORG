@isTest
private class EmailPreferenceOptOutSchedulableTEST {
	@isTest static void testSchedulable() {
        new EmailPreferenceOptOutSchedulable().execute(null);
        System.assertEquals(1, [SELECT count() FROM AsyncApexJob WHERE AsyncApexJob.ApexClass.Name = 'EmailPreferenceOptOutProcessorBatch']);
	}	
}