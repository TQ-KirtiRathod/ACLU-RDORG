/**
 * Test Class for WarmCacheForSomeReports
 **/
@isTest
private class WarmCacheForSomeReportsTest {
    private static String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    
    @testSetUp 
    static void testDateCreation() {
        list<Opportunity> listOpportunities = new list<Opportunity>();
        Account acc = TestUtils.createAccount('TestAcc', true);
        for(Integer i = 0; i<50; i++) {
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'Opp ' + i, false);
            opp.StageName = 'Completed';
            if(i >= 0 && i < 20) {
                opp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            } else if(i >= 20 && i < 50) {
                opp.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            }
            listOpportunities.add(opp);
        }
        insert listOpportunities;
    }
	private static testMethod void testBatch() {
        Test.startTest();
            Database.executeBatch(new WarmCacheForSomeReports(system.today().addDays(-2)), 100);
        Test.stopTest();
        list<Apex_Log__c> log = [SELECT Id, Message__c FROM Apex_Log__c];
        system.assertEquals(1, log.size());
        system.assertEquals(true, log[0].Message__c.contains('WarmCacheForSomeReports'));
	}

}