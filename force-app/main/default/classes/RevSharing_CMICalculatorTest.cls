/**
 * Test Class for RevSharing_CMICalculator
 * Modified by :: Salesforce.org :: 03-August-2020 :: Zendesk: #79232
 **/
@isTest
private class RevSharing_CMICalculatorTest {
    
    private static List<Opportunity>listOpportunity;
    private static  Affiliate_Yearly__c affiliateYearlyobj;
    private static Set<Id> affiliateId;
    private static Id recordId;
    static{
        recordId = [Select id from RecordType where SObjectType = 'Opportunity' AND name = 'TRANSACTION' LIMIT 1].id;
    }
    @isTest
    Private static void TestRevSharing_CMICalculatorTest(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
            listOpportunity.get(i).Sharing_Code__c='D009';
        }
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_UBRI_RenewalDues_Count__c from Affiliate_Yearly__c];
        System.assertEquals(10,listOpportunity.size());
        System.assertEquals(10,lst[0].CMI_stage_UBRI_RenewalDues_Count__c,lst);
        
    }
    @isTest
    private static void TestRevSharing_CmI(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='A001'; 
        }
      
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Unshared_New_Nat_Count__c from Affiliate_Yearly__c];
        System.assertEquals(10,lst[0].CMI_stage_Unshared_New_Nat_Count__c,lst);
        
    }
    
    @isTest
    private static void TestRevSharing_CmI1(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='B003'; 
        }
    
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Unshared_Recap_Nat_Count__c from Affiliate_Yearly__c];
        System.assertEquals(10,lst[0].CMI_stage_Unshared_Recap_Nat_Count__c,lst);
    }
    
    @isTest
    private static void TestRevSharing_CmI2(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='C161'; 
        }
     
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Nat_UnsolicitedEarmarked__c from Affiliate_Yearly__c];
        System.assertEquals(145,lst[0].CMI_stage_Nat_UnsolicitedEarmarked__c,lst);
        
    }
    
    @isTest
    private static void TestRevSharing_CmI3(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='C165'; 
        }
   
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Nat_RecogGrants__c from Affiliate_Yearly__c];
        System.assertEquals(145,lst[0].CMI_stage_Nat_RecogGrants__c,lst);
    }
    
    @isTest
    private static void TestRevSharing_CmI4(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
         
           listOpportunity.get(i).Sharing_Code__c='C171'; 
        }
     
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_UBRI_ExtraContribs__c from Affiliate_Yearly__c];
        System.assertEquals(145,lst[0].CMI_stage_UBRI_ExtraContribs__c,lst);
    }
    
    @isTest
    private static void TestRevSharing_CmI5(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='E121'; // #79232 :Changed the Sharing code instead of R121
        }
   
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Nat_Advertising__c from Affiliate_Yearly__c];
        System.assertEquals(145,lst[0].CMI_stage_Nat_Advertising__c,lst);
        
    }
    
    @isTest
    private static void TestRevSharing_CmI6(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='E151'; 
        }
     
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Nat_SolicitedEarmarked__c from Affiliate_Yearly__c];
        System.assertEquals(145,lst[0].CMI_stage_Nat_SolicitedEarmarked__c,lst);
        
    } 
    
    @isTest
    private static void TestRevSharing_CmI7(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='E141'; 
        }
    
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Nat_Benefit__c from Affiliate_Yearly__c];
        System.assertEquals(145,lst[0].CMI_stage_Nat_Benefit__c,lst);
        
    }
    
    @isTest
    private static void TestRevSharing_CmI8(){
        createData();
        Test.startTest();
        for(Integer i=0;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='P001'; 
        }
   
        insert listOpportunity;
        Database.executebatch(new RevSharing_CMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        List<Affiliate_Yearly__c> lst = [SELECT Id,CMI_stage_Unshared_FirstRenew_Nat_Count__c from Affiliate_Yearly__c];
        System.assertEquals(10,lst[0].CMI_stage_Unshared_FirstRenew_Nat_Count__c,lst);
        
    }
    
    //Create Test data
    private static void createData(){
        Revenue_Sharing_Sytem_Controls__c custSetting = new Revenue_Sharing_Sytem_Controls__c();
        custSetting.Name = 'test';
        insert custSetting;
        affiliateId = new set<Id>();
        
        Account ac1 = TestUtils.createAccount('Test12',False);
        ac1.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        ac1.Affiliation__c='AA';
        insert ac1;
        Account ac= TestUtils.createAccount('Test',False);
        ac.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        ac.Affiliation__c='AA';
        insert ac;
        
	    affiliateYearlyobj= TestUtils.createAffiliateYearly('Testit', ac.Id, 'four', false);
        affiliateYearlyobj.GMI_Amount__c=100;
        affiliateYearlyobj.Incentive_National_Share__c=10;
        affiliateYearlyobj.Union_Cost_Factor__c=19;
        affiliateYearlyobj.Foundation_Cost_Factor__c=19;
        affiliateYearlyobj.BRI_Affiliate_Share__c=12;
        affiliateYearlyobj.Eligible_for_GMI__c=false;
        affiliateYearlyobj.CMI_stage_DateStart__c=Date.today();    
        affiliateYearlyobj.CMI_stage_DateEnd__c=Date.today().addDays(1);    
       
        insert affiliateYearlyobj;
        
        Affiliate_Yearly__c affiliateYearlyobj1= TestUtils.createAffiliateYearly('Testit1', ac1.Id, 'five', false);
        affiliateYearlyobj1.GMI_Amount__c=100;
        affiliateYearlyobj1.Incentive_National_Share__c=10;
        affiliateYearlyobj1.Union_Cost_Factor__c=19;
        affiliateYearlyobj1.Foundation_Cost_Factor__c=19;
        affiliateYearlyobj1.BRI_Affiliate_Share__c=12;
        affiliateYearlyobj1.Eligible_for_GMI__c=false;
        affiliateYearlyobj1.CMI_stage_DateStart__c=Date.today();    
        affiliateYearlyobj1.CMI_stage_DateEnd__c=Date.today().addDays(2);    
       
        insert affiliateYearlyobj1;
            
        affiliateId.add(affiliateYearlyobj.id);
        affiliateId.add(affiliateYearlyobj1.id);
        
            
        listOpportunity = new List<Opportunity>(); 
        
        for(Integer i=0;i<10;i++){
            Opportunity opp = TestUtils.createOpportunity(ac.Id,'TestOpp'+i,False);
            opp.Amount=10+i;
            opp.Sharing_Entity_Affiliation__c='NA';
            opp.Program_Type__c='35';
            opp.Deposit_Site__c = 'NAA - Nat U-Chase';
            opp.Exclude_Cost_Factors_in_RevShare__c=true;
            opp.Exclude_from_Revenue_Sharing__c=false;
            opp.Sharing_Entity__c='NAA - National ACLU (Membership)';
            //opp.Sharing_Code__c='D009';
            opp.StageName='Completed';

           // opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('TRANSACTION').getRecordTypeId();
            opp.RecordTypeId=recordId;
            opp.Cost_Factor__c=10;
            opp.Use_Campaign_Cost__c=true;
            opp.CloseDate=Date.today();
          //  opp.Exclude_from_Revenue_Sharing__c=
            listOpportunity.add(opp);            
            
        }
       // insert listOpportunity;
        
    }
}