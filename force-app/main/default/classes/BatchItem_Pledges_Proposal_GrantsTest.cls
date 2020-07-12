/*
*
*Name  :  BatchItem_Pledges_Proposal_GrantsTest
*Author:  Appirio India (Shobhit Pant)
*Date  :  June 12, 2017
*Purpose : Test Class for BatchItem_Pledges_Proposal_GrantsCont class
*
*/
@isTest
public class BatchItem_Pledges_Proposal_GrantsTest {

	@isTest
	static void pledgeProposalGrantsControllerTest(){
		//creating account using TestUtils
		Account accToPass = TestUtils.createAccount('ControllerTestAccount', true);
		//List to store opportunities
		List<Opportunity> opportunityList = new List<Opportunity>();
		//obtaining different opportunity record type ids
		Map<String,Schema.RecordTypeInfo> opptyRTMap = Schema.SObjectType.opportunity.getRecordTypeInfosByName();
	    String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
	    String OPPORTUNITY_RT_PROPOSAL_ID = opptyRTMap.get('Proposal').getRecordTypeId();
	    String OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
	    String OPPORTUNITY_RT_GRANT_Id = opptyRTMap.get('Grant').getRecordTypeId();

	    //creating 12 (static) opportunities, 3 for each recordtype
		for(Integer i=0; i<12; i++){
			Opportunity opp = TestUtils.createOpportunity(accToPass.Id, 'ControllerTestOpportunity' + i, false);
			opp.isCreatedFromBatchLog__c = false;

			if(i >= 0 && i <=2) {
				opp.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
				opp.StageName = 'Open';
			}
			else if ( i > 2 && i <= 5){
				opp.RecordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
			}
			else if (i > 5 && i <= 8){
				opp.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
			}
			else{
				opp.RecordTypeId = OPPORTUNITY_RT_GRANT_Id;
			}
			//adding the created opportunity to list
			opportunityList.add(opp);
		}
		//null check
		if(opportunityList != null){
			insert opportunityList;
		}
		//setting currentpage as BatchItem_Pledges_Proposal_Grants vf page
		PageReference pageRef = Page.BatchItem_Pledges_Proposal_Grants;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        //passing arguments before calling controller constructor method
        ApexPages.currentPage().getParameters().put('accId', String.valueOf(accToPass.Id));
        ApexPages.currentPage().getParameters().put('batchId', null);
        //controller constructor 
        BatchItem_Pledges_Proposal_GrantsCont controller = new BatchItem_Pledges_Proposal_GrantsCont();
        //calling controller methods
        controller.manageTransactions();
        controller.close();
        Test.stopTest();
        system.assertEquals(3,controller.pledgePayments.size());
        system.assertEquals(3,controller.proposals.size());
        system.assertEquals(3,controller.grants.size());
	}

}