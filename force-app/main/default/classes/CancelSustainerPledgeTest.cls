/******************************************
 * Test Class for : CancelSustainerPledge
 * Created By: Bhavesh Malviya
 * Created Date: 31/10/2017
 * ***************************************/

@isTest
private class CancelSustainerPledgeTest {
    public Static Account acc;
    public Static Opportunity op;
    public static Id pledgeOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    //function to create test data
    static void createData() {
        acc = TestUtils.createAccount('Sampel Account', true);
        op = TestUtils.createOpportunity( acc.id, 'OPP1', false);
        op.RecordTypeId = pledgeOppRecordTypeId;
        insert op;
    }
    
    //Test method to check the opportunity values after sustain cancellation button is clicked.
    @isTest
	static void testCancellationValues() {
	    Test.StartTest();
    	    createData();
            CancelSustainerPledge.getCancellationValues();
            CancelSustainerPledge.forceCancelPledge('Donor Requested', op.id);
        Test.stopTest();
        Opportunity updatedOp = [Select id, rC_Giving__Is_Canceled__c, Cancellation_Reason__c from Opportunity where id = : op.id lIMIT 1];
        System.assertEquals('Donor Requested', updatedOp.Cancellation_Reason__c);
        System.assertEquals(true, updatedOp.rC_Giving__Is_Canceled__c);
	}

}