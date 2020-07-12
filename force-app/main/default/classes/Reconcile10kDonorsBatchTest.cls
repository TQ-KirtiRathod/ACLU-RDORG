@isTest
private class Reconcile10kDonorsBatchTest {
    Static string affiliate;
    static Account acc;
    @testSetup
	private static void createData() {
	    Set<String> setOfRequiredCodes = new Set<String> {'R131','R113','R121','K171','R181','R151'};
	    String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
	    List<Opportunity> oppToInsert = new List<Opportunity>();
	    String accRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
	    acc = TestUtils.createAccount('Test Account', false);
	    acc.RecordTypeId  = accRecordType;
	    acc.Affiliation__c = 'AR';
	    insert acc;
	    
	    Integer i = 0;
	    affiliate = 'AR';
	    Campaign cmp = TestUtils.createCampaign('Test',false);
	    cmp.rC_Giving__Campaign_Type__c = 'B - Benefit';
	    cmp.rC_Giving__Source_Code__c = 'test';
	    cmp.rC_Giving__End_Date_Time__c = datetime.newInstance(2018, 9, 15, 12, 30, 0);
	    insert cmp;
	    Opportunity opp;
	    List<String> affliationList = new List<String>{'NA','NN','UN','FN','PF','EN','PU','UA'};
	    for(String sharingCode : setOfRequiredCodes){
            opp = TestUtils.createOpportunity(acc.id, 'OppName'+sharingCode+i, false);
            opp.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp.Sharing_Code__c = sharingCode;
            opp.Amount = 2000+i;
            opp.Sharing_Entity_Affiliation__c = affiliate;
            opp.stageName = 'Completed';
            opp.CloseDate = Date.newInstance(2017, 12, 17).addDays(i);
            opp.Exclude_from_Revenue_Sharing__c = false;
            opp.Deposit_Site__c = 'AR_Arkansas';
            opp.RPT_Package_Code__c = 'ABCP';
            opp.CampaignIdText__c = cmp.id;
            i++;
            oppToInsert.add(opp);
	    }
        insert oppToInsert;
        //System.assert(false, [Select id, Sharing_Entity_Affiliation__c from Opportunity]);
        
	}
	private static testMethod void test() {
	    Account acc = [Select id, name from account LIMIT 1];
        Affiliate_Yearly__c ay = TestUtils.createAffiliateYearly('Test FY', acc.id, '2018', true);
        Donors_Over_10K__c donors = new Donors_Over_10K__c(Affiliate_Yearly__c = ay.id);
        insert donors;
        Reconcile10kDonorsBatch obj = new Reconcile10kDonorsBatch();
        obj.accAffiliationCode = 'AR';
        obj.ayId = ay.id;
        obj.fiscalYear = '2018';
        DataBase.executeBatch(obj);
        Reconcile10kDonorsBatch.initialize(ay.id, '2018','AR');
        list<Donors_Over_10K__c> d = [SELECT Id,Fund_Type__c, Affiliate_CP_and_Earmark_Info__c,National_CP_and_Earmark_Info__c,Banked_by_Affiliate_Fdn__c FROM Donors_Over_10K__c];
        system.assertEquals(1, d.size()); //Test.runningTest written in main class to execute catch block
	}

}