/*
*
*Name  :  RevSharing_Calc_Batch_Test
*Author:  Appirio India
*Date  :  June 22, 2017
*Purpose : Test Class for RevSharing_Calc_Batch Batch class
*
*/

@isTest
private class RevSharing_Calc_Batch_Test {
    private static Affiliate_Yearly__c AY;
    private static Affiliate_Yearly__c AY1;
    private static List<Opportunity> lstOpp;
    private static User usr;
    
    //Create test data
	private static void Setup() {
	    
	    usr = TestUtils.createUser('usertest1', 'usertest1@aclu.org', null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest1@aclu.org';
        insert usr;
        
        List<Account> lstAccs = new List<Account>();
	    Account acc = TestUTils.createAccount('TestAcc',false);
	    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
	    acc.Affiliation__c = 'AA';
	    lstAccs.add(acc);
	    //insert acc;
        Account acc1 = TestUTils.createAccount('TestAcc',false);
	    acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
	    acc1.Affiliation__c = 'AA';
	    lstAccs.add(acc1);
	    //insert acc1;
	    insert lstAccs;
	    
	    List<Affiliate_Yearly__c> lstAYs = new List<Affiliate_Yearly__c>();
        AY = TestUTils.createAffiliateYearly('TestYear',acc.id,'2018',false);
        AY.Eligible_for_GMI__c = true;
        lstAYs.add(AY);
        AY1 = TestUTils.createAffiliateYearly('TestYear1',acc1.id,'2016',false);
        AY1.Eligible_for_GMI__c = false;
        lstAYs.add(AY1);
        insert lstAYs;
        
        lstOpp = new List<Opportunity>();
        
        Opportunity opp;
        for(Integer i=0;i<15;i++){
            opp = TestUtils.CreateOpportunity(acc.id,'Test Opp'+i,false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
            opp.Sharing_Code__c = 'D009';
            opp.Sharing_Entity_Affiliation__c = 'AA';
            opp.stageName = 'Completed' ;
            opp.CloseDate =  date.newinstance(System.Today().year()-1, 6, 1);
            opp.Sharing_Entity_Affiliation__c= 'NA';
            opp.Amount = 200;
            lstOpp.add(opp);
        }
        
        lstOpp[0].Use_Campaign_Cost__c = true;
        lstOpp[0].Cost_Factor__c= 1000;
        lstOpp[0].Sharing_Code__c = 'N111';
        
        lstOpp[1].Program_Type__c = '1';
        lstOpp[1].Sharing_Code__c = 'N111';
        
        lstOpp[2].Sharing_Code__c = 'N111';
        lstOpp[3].Sharing_Code__c = 'N175';
        lstOpp[4].Sharing_Code__c = 'R131';
        lstOpp[5].Sharing_Code__c = 'R141';
        lstOpp[6].Sharing_Code__c = 'R151';
        lstOpp[7].Sharing_Code__c = 'R181';
        lstOpp[8].Sharing_Code__c = 'A001';
        lstOpp[9].Sharing_Code__c = 'E131';
        lstOpp[9].Deposit_Site__c = 'AK_Alaska';
        lstOpp[10].Sharing_Code__c = 'E151';
        lstOpp[11].Sharing_Code__c = 'E181';
        lstOpp[12].Sharing_Code__c = 'C165';
        lstOpp[13].Sharing_Code__c = 'C161';
        System.runAs(usr){
            insert lstOpp;
        }
        
        Calculate_Reconciliation_Report_Status__c crrs = new Calculate_Reconciliation_Report_Status__c();
        crrs.Receiver_Name__c='Test';
        crrs.Report_Request_In_Progress__c=true;
        crrs.Receiver_Email_Id__c='test@ymail.com';
        crrs.Sender_Email__c='test@ymail.com';
        insert crrs;
        
	}
	
	
	static testmethod void testBatch() { 
	    Setup();
        Test.startTest();
        RevSharing_Calc_Batch obj = new RevSharing_Calc_Batch(AY.id);
        DataBase.executeBatch(obj,200);
        
        //Assert to check opportunity list size
        system.assertEquals(15, lstOpp.size());
        
        //Webservice Method
        RevSharing_Calc_Batch.updateRevenue(AY.id);
        Test.stopTest();
    }
    static testmethod void testBatch1() { 
	    Setup();
        Test.startTest();
        RevSharing_Calc_Batch obj = new RevSharing_Calc_Batch(AY1.id);
        DataBase.executeBatch(obj,200);
        system.assertEquals(15, lstOpp.size());
        
        //Webservice Method
        RevSharing_Calc_Batch.updateRevenue(AY1.id);
        Test.stopTest();
    }
    

}