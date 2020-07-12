@isTest
private class OppRelatedProposalComponentContTest {
    static Account acc;
    static Opportunity opp;
    private static void createTestData(){
        String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
	    acc = TestUtils.createAccount('testAcc', TRUE);
        
        opp = TestUtils.createOpportunity(acc.id, 'opp', false);
        opp.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        opp.rC_Giving__Giving_Amount__c  = 52;
        opp.rC_Giving__Requested_Amount__c = 90;
        opp.stageName = 'Completed';
        opp.Sharing_Code__c = 'P001';
        opp.closeDate = date.Today();
        opp.Bank_Date__c = Date.today()-1;
        opp.Batch_Date__c = Date.today()+1;
        opp.Tax_Date__c  = Date.today() ;
        opp.rC_Giving__Payment_Method__c = 'Charge Card';
        opp.rC_Giving__Expected_Giving_Amount__c = 20;
        insert opp;
        
        Proposal_Detail__c propDetail = new Proposal_Detail__c( Opportunity__c = opp.id);
        insert propDetail;
    }
	private static testMethod void testController() {
	    createTestData();
	    
        OppRelatedProposalComponentController contrlr = new OppRelatedProposalComponentController();
        contrlr.oppId = ''+opp.id;
        System.assertEquals(True, contrlr.proposalList.size() > 0);
	}

}