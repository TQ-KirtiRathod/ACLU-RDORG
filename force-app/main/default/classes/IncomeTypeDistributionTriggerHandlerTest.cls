/**
* Test Class for IncomeTypeDistributionTriggerHandlerTest
*/
@isTest
private class IncomeTypeDistributionTriggerHandlerTest {
    
    static List <Income_Type_Distribution__c> IntDs1,IntDs2; 
    static List <Income_Type_Distribution__c> updateList;
    /*
    *
    *Method insertIncomeTypeDistribution
    *Testing data for IncomeTypeDistribution Calculation on insert.
    */
    static testMethod void insertIncomeTypeDistribution() {
        User u = testUtils.createUser('userNameTest','testMani@gmail.com',null,false);
        u.Is_Affiliate_User__c = false;
        insert u;
        
        system.runAs(u)
        {
            setup();
        }
        for(Affiliate_Yearly__c aff: [SELECT Unrestricted_Annual_Mega_Incentive__c, Unsolicited_Earmarked_Annual_Mega__c, Multi_Year_Mega_Incentive_Income__c,
                                      Solicited_Earmarked_Annual_MegaIncentive__c, Endowment_Gifts__c, Endowment_Mega_Gifts__c, 
                                      Mega_Bequest_Total__c,Campaign_Mega_Incentive_Income_Above_2M__c,Earmarked_Bequest_Total__c, Unrestricted_Bequest_Planned_Gift_Total__c 
                                      FROM Affiliate_Yearly__c WHERE Name = 'test0']){
                                          
                                          system.assertEquals(200,aff.Unrestricted_Annual_Mega_Incentive__c);
                                          system.assertEquals(100,aff.Multi_Year_Mega_Incentive_Income__c);   
                                          system.assertEquals(100,aff.Solicited_Earmarked_Annual_MegaIncentive__c);   
                                          system.assertEquals(200,aff.Endowment_Mega_Gifts__c);   
                                          system.assertEquals(100,aff.Mega_Bequest_Total__c); 
                                          system.assertEquals(100,aff.Earmarked_Bequest_Total__c);    
                                          system.assertEquals(100,aff.Unrestricted_Bequest_Planned_Gift_Total__c);                          
                                      }
    }
    
    /*
    *
    *Method updateIncomeTypeDistribution
    *Testing data for IncomeTypeDistribution Calculation on update.
    */
    static testMethod void updateIncomeTypeDistribution() {
        User u = testUtils.createUser('userNameTest','testMani@gmail.com',null,false);
        u.Is_Affiliate_User__c = false;
        insert u;
        
        system.runAs(u)
        {
            setup();
        }
        //Update
    	updateList = new List <Income_Type_Distribution__c>();
        for(Income_Type_Distribution__c inc: [SELECT Amount__c,Affiliate_Yearly__r.name , Income_Type__c FROM Income_Type_Distribution__c WHERE Affiliate_Yearly__r.name='Test0']){
            inc.Amount__c = 500;
            updateList.add(inc);
        }
        
        Test.startTest();
        if(!updateList.IsEmpty())
        {
            system.runAs(u){
            upsert updateList;
            }
		}   
        Test.stopTest();
        for(Affiliate_Yearly__c aff: [SELECT Unrestricted_Annual_Mega_Incentive__c, Unsolicited_Earmarked_Annual_Mega__c, Multi_Year_Mega_Incentive_Income__c,
                                      Solicited_Earmarked_Annual_MegaIncentive__c, Endowment_Gifts__c, Endowment_Mega_Gifts__c, Campaign_Mega_Incentive_Income_Above_2M__c,
                                      Mega_Bequest_Total__c,Earmarked_Bequest_Total__c, Unrestricted_Bequest_Planned_Gift_Total__c FROM Affiliate_Yearly__c 
                                      WHERE Name = 'test0']){
                                          
                                          system.assertEquals(1000,aff.Unrestricted_Annual_Mega_Incentive__c);
                                          system.assertEquals(500,aff.Multi_Year_Mega_Incentive_Income__c);   
                                          system.assertEquals(500,aff.Solicited_Earmarked_Annual_MegaIncentive__c);   
                                          system.assertEquals(1000,aff.Endowment_Mega_Gifts__c);   
                                          system.assertEquals(500,aff.Mega_Bequest_Total__c); 
                                          system.assertEquals(500,aff.Earmarked_Bequest_Total__c);    
                                          system.assertEquals(500,aff.Unrestricted_Bequest_Planned_Gift_Total__c);                          
                                         }
    }
    
    
    /*
    *Method deleteIncomeTypeDistribution
    *Testing data for IncomeTypeDistribution Calculation on delete.
    */
    static testMethod void deleteIncomeTypeDistribution() {
        List <Income_Type_Distribution__c> deleteList = new List <Income_Type_Distribution__c>();
        // Delete 
        setup();
        Test.startTest();
        for(Income_Type_Distribution__c inc: [SELECT Income_Type__c FROM Income_Type_Distribution__c]){
            deleteList.add(inc);
        }
        
        if(!deleteList.IsEmpty())
            delete deleteList;
        
        for(Affiliate_Yearly__c aff: [SELECT Unrestricted_Annual_Mega_Incentive__c, Unsolicited_Earmarked_Annual_Mega__c, Multi_Year_Mega_Incentive_Income__c,
                                      Solicited_Earmarked_Annual_MegaIncentive__c, Endowment_Gifts__c, Endowment_Mega_Gifts__c, Campaign_Mega_Incentive_Income_Above_2M__c,
                                      Mega_Bequest_Total__c,Earmarked_Bequest_Total__c, Unrestricted_Bequest_Planned_Gift_Total__c FROM Affiliate_Yearly__c WHERE Name = 'test0']){
                                          system.assertEquals(0.00,aff.Unrestricted_Annual_Mega_Incentive__c);
                                          system.assertEquals(0.00,aff.Multi_Year_Mega_Incentive_Income__c);  
                                          system.assertEquals(0.00,aff.Solicited_Earmarked_Annual_MegaIncentive__c);  
                                          system.assertEquals(0.00,aff.Endowment_Mega_Gifts__c);  
                                          system.assertEquals(0.00,aff.Mega_Bequest_Total__c);    
                                          system.assertEquals(0.00,aff.Earmarked_Bequest_Total__c);   
                                          system.assertEquals(0.00,aff.Unrestricted_Bequest_Planned_Gift_Total__c);                         
                                      }
        Test.stopTest();
    }
    
    
    /*
    *Method undeleteIncomeTypeDistribution
    *Testing data for IncomeTypeDistribution Calculation on undelete.
    */
    static testMethod void undeleteIncomeTypeDistribution() {
        List <Income_Type_Distribution__c> deleteList = new List <Income_Type_Distribution__c>();
        List <Income_Type_Distribution__c> undeleteList = new List <Income_Type_Distribution__c>();
        //Undelete 
        setup();
        Test.startTest();
        for(Income_Type_Distribution__c inc: [SELECT Income_Type__c FROM Income_Type_Distribution__c]){
            deleteList.add(inc);
        }
        
        if(!deleteList.IsEmpty())
            delete deleteList;
        
        for(Income_Type_Distribution__c inc: [SELECT Income_Type__c FROM Income_Type_Distribution__c ALL Rows]){
            undeleteList.add(inc);
        }
        
        if(!undeleteList.IsEmpty())
            undelete undeleteList;
        
        
        for(Affiliate_Yearly__c aff: [SELECT Unrestricted_Annual_Mega_Incentive__c, Unsolicited_Earmarked_Annual_Mega__c, Multi_Year_Mega_Incentive_Income__c,
                                      Solicited_Earmarked_Annual_MegaIncentive__c, Endowment_Gifts__c, Endowment_Mega_Gifts__c, Campaign_Mega_Incentive_Income_Above_2M__c,
                                      Mega_Bequest_Total__c,Earmarked_Bequest_Total__c, Unrestricted_Bequest_Planned_Gift_Total__c FROM Affiliate_Yearly__c WHERE Name = 'test0']){
                                          system.assertEquals(200,aff.Unrestricted_Annual_Mega_Incentive__c);
                                          system.assertEquals(100,aff.Multi_Year_Mega_Incentive_Income__c);   
                                          system.assertEquals(100,aff.Solicited_Earmarked_Annual_MegaIncentive__c);   
                                          system.assertEquals(200,aff.Endowment_Mega_Gifts__c);   
                                          system.assertEquals(100,aff.Mega_Bequest_Total__c); 
                                          system.assertEquals(100,aff.Earmarked_Bequest_Total__c);    
                                          system.assertEquals(100,aff.Unrestricted_Bequest_Planned_Gift_Total__c);  
                                      }
        
        
        Test.stopTest();
    }
    
    static testMethod void testDeleteReconciledAY() {
        User u = testUtils.createUser('userNameTest','testMani@gmail.com',null,false);
        u.Is_Affiliate_User__c = false;
        insert u;
        Income_Type_Distribution__c iTD;
        system.runAs(u) {
            Account acc = TestUtils.createAccount('Test', false);
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
    	    insert acc;
            Affiliate_Yearly__c reconAff = TestUtils.createAffiliateYearly('Test',acc.Id, '2014',false);
    	    insert reconAff; 
    	    
    	    //To verify deletion if Reconciled & Locked Affiliate Yearly not possible
    	    Test.startTest();
    	    Id natId = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Other Income Types').getRecordTypeId();
    	    iTD = TestUtils.createIncomeTypeDistribution(reconAff.Id, 'Unrestricted Annual Mega Incentive', 100, false);
    	    iTD.RecordTypeId = natId;
    	    insert iTD;
    	    reconAff.Reconciled_and_Locked__c = true;
    	    update reconAff;
        }
	    try{
	        delete iTD;
	    } catch(Exception ex) {
	        iTD = [SELECT Id FROM Income_Type_Distribution__c];
	        system.assert(iTD.Id != null);
	    }
	    Test.stopTest();
	}
    /*
    *
    *Method setup
    *Testing data for IncomeTypeDistribution Calculation.
    */
    public static void setup(){
    	//Creating an non-affiliated user
        User u = TestUtils.createUser('testFirst', 'syst@testorg.com', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        
        System.runAs(u){
	        List<Account> accList = new List<Account>();
	        Account a = testUtils.createAccount('Account'+0,false);
	        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
	        accList.add(a);
	        
	        Account b = testUtils.createAccount('Account'+1,false);
	        b.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
	        accList.add(b);
	        
	        insert accList;
	        
	        List<Affiliate_Yearly__c> affList = new List<Affiliate_Yearly__c>();
	        Affiliate_Yearly__c aff1 = TestUtils.createAffiliateYearly('Test'+0,accList[0].id, '2014',false);
	        affList.add(aff1);
	        Affiliate_Yearly__c aff2 = TestUtils.createAffiliateYearly('Test'+1,accList[1].id, '2014',false);
	        affList.add(aff2);
	        upsert affList;
	        
	        Id affId = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Affiliate Direct Mail').getRecordTypeId();
	        Id natId = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Other Income Types').getRecordTypeId();
	        IntDs1 = new List <Income_Type_Distribution__c>();
	        //Income TypeDistribution
	        Income_Type_Distribution__c iTD = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Unrestricted Annual Mega Incentive', 100, false);
	        iTD.RecordTypeId = natId;
	        //iTD.Income_Type__c = 'Multi-Year Mega-Gifts';
	        Income_Type_Distribution__c iTD1 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Unrestricted Annual Mega Incentive', 100, false);
	        iTD1.RecordTypeId = natId;
	        //iTD1.Income_Type__c = 'Multi-Year Mega-Gifts';
	        Income_Type_Distribution__c iTD2 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Multi-Year Mega-Gifts', 100, false);
	        iTD2.RecordTypeId = natId;
	        //iTD2.Income_Type__c = 'Multi-Year Mega-Gifts';
	        Income_Type_Distribution__c iTD3 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Solicited Earmarked Annual Mega Incentive', 100, false);
	        Income_Type_Distribution__c iTD4 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Endowment Mega Gifts', 100, false); 
	        Income_Type_Distribution__c iTD5 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Endowment Mega Gifts', 100, false);
	        Income_Type_Distribution__c iTD7 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Unrestricted Bequest / Planned Gift', 100, false);
	        Income_Type_Distribution__c iTD8 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Earmarked Bequest', 100, false);
	        Income_Type_Distribution__c iTD9 = TestUtils.createIncomeTypeDistribution(affList[0].id, 'Mega Bequest', 100, false);
	        iTD3.RecordTypeId = natId;
	        iTD4.RecordTypeId = natId;
	        iTD5.RecordTypeId = natId;
	        iTD7.RecordTypeId = natId;
	        iTD8.RecordTypeId = natId;
	        iTD9.RecordTypeId = natId;
	        IntDs1.add(iTD);
	        IntDs1.add(iTD1);
	        IntDs1.add(iTD2);
	        IntDs1.add(iTD3);
	        IntDs1.add(iTD4);
	        IntDs1.add(iTD5);
	        IntDs1.add(iTD7);
	        IntDs1.add(iTD8);
	        IntDs1.add(iTD9);
	        
	        
	        if(!IntDs1.IsEmpty()){
	            insert IntDs1;
	        }    
	        IntDs2 = new List <Income_Type_Distribution__c>();
	        Income_Type_Distribution__c iTD11 = TestUtils.createIncomeTypeDistribution(affList[1].id, 'Special Sharing', 100, false);
	        Income_Type_Distribution__c iTD12 = TestUtils.createIncomeTypeDistribution(affList[1].id, 'Special Sharing', 100, false);
	        iTD11.RecordTypeId = affId;
	        iTD12.RecordTypeId = affId;
	        IntDs2.add(iTD11);
	        IntDs2.add(iTD12);
	        if(!IntDs2.IsEmpty()){
	            insert IntDs2;
	        }
        }
    }
}