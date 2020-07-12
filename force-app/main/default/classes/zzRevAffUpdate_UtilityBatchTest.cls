/*
*
*Name  :  zzRevAffUpdate_UtilityBatchTest
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  09/05/2018
*Purpose : Test class for zzRevAffUpdate_UtilityBatch.
*
*/
@isTest
private class zzRevAffUpdate_UtilityBatchTest {
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
      
    @testSetup
	private static void createTestData() {
        Account acc1 = TestUtils.createAccount('TestAccount',false);
        Account acc2 = TestUtils.createAccount('TestAccount',false);
        Insert new List<Account>{acc1,acc2};
        
        // Create Campaign
        Campaign cmpgn = TestUtils.createCampaign('TestCampaign', false);
        cmpgn.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert cmpgn;
         
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        Opportunity opp = TestUtils.createOpportunity(acc1.id, 'Bulk test-Opportunity'+1, false);
        opp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id; 
        opp.IsCreatedFromBatchLog__c = true;
        opp.rC_Giving__Giving_Frequency__c = 'One Payment';
        opp.rC_Giving__Giving_Amount__c = 1000;
        opp.CampaignId = cmpgn.Id;
        opp.Program_Type__c = '1';
        opp.StageName = 'Open';
        opp.Revenue_Affiliation__c = null;
        opp.Sharing_Entity_Affiliation__c = 'NA';
        opp.Account_Affiliation__c = 'NA';
        opp.stageName = 'Completed';
        opp.Adjustment_Code__c = 'N';
        opp.CloseDate = Date.parse(Label.PatchUtilityStartDate).addDays(2);
        
        Opportunity opp2 = TestUtils.createOpportunity(acc2.id, 'Bulk test-Opportunity'+1, false);
        opp2.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id; 
        opp2.IsCreatedFromBatchLog__c = true;
        opp2.rC_Giving__Giving_Frequency__c = 'One Payment';
        opp2.rC_Giving__Giving_Amount__c = 1000;
        opp2.CampaignId = cmpgn.Id;
        opp2.Program_Type__c = '2';
        opp2.StageName = 'Open';
        opp2.Revenue_Affiliation__c = null;
        opp2.Sharing_Entity_Affiliation__c = 'A';
        opp2.Account_Affiliation__c = 'NA';
        opp2.stageName = 'Completed';
        opp2.Adjustment_Code__c = 'N';
        opp2.CloseDate = Date.parse(Label.PatchUtilityStartDate).addDays(2);
        
        insert new List<Opportunity>{opp,opp2};
        opp.Sharing_Entity_Affiliation__c = 'NA';
        update opp;
	}
	
	@istest
	public static void testBatchMethod (){
	    Test.startTest();
            Database.executeBatch(new zzRevAffUpdate_UtilityBatch(), 100);
        Test.stopTest();
        for(Opportunity opp : [Select id, Revenue_Affiliation__c, Sharing_Entity_Affiliation__c From Opportunity]){
            System.assertEquals(True, (opp.Revenue_Affiliation__c == opp.Sharing_Entity_Affiliation__c));
        } 
	}

}