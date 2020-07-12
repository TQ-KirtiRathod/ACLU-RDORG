//
// (c) 2016 Appirio, Inc.
//
// test Class for OpportunityProposalPageController.
//
// 02 Feb 2018       Bhavesh Malviya (Appirio) Original
//
@isTest
private class OpportunityProposalPageControllerTest {
    Private static Opportunity opp;
    Private static Proposal_Detail__c pd;
	private static testMethod void test() {
        createTestData();
        PageReference pageRef = Page.OpportunityProposalPage;
        Test.setCurrentPage(pageRef);
        User u = new User(Id = UserInfo.getUserId(), Validation_Bypass__c = true );
        update u;
        pageRef.getParameters().put('Id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityProposalPageController cntrlr = new OpportunityProposalPageController(sc);
        
        opp.CloseDate = Date.newInstance(system.today().year()+1,3, 5); 
        pd.National_c3_Requested_Amount__c = 1000;
        cntrlr.propDetail = pd;
        cntrlr.saveOpportunityAndPortFolioRecord();
        
        System.assertEquals(system.today().year()+1+'',''+[Select id, CloseDate FROM Opportunity WHERE ID=: opp.id].CloseDate.year());
        System.assertEquals(1000,[Select id, National_c3_Requested_Amount__c FROM Proposal_Detail__c WHERE ID=: pd.id].National_c3_Requested_Amount__c);
        
	}
	
	private static testMethod void testRedirectPage(){
	    opp = new Opportunity();
	    PageReference pageRef = Page.OpportunityProposalPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityProposalPageController cntrlr = new OpportunityProposalPageController(sc);
        
	    cntrlr.redirectToOtherPage();
	    cntrlr.returnToViewPage();
	}
	private static void createTestData(){
	    String OPPORTUNITY_RT_PROPOSAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
	    Account acc = TestUtils.createAccount('testAcc', TRUE);
	    opp = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
        opp.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        opp.StageName = 'Completed';
        opp.CloseDate = Date.newInstance(system.today().year(),3, 5);
	    insert opp;
	    pd = new Proposal_Detail__c(Opportunity__c = opp.id);
	    insert pd;
	}

}