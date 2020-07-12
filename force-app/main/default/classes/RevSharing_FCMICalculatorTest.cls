/**
 * Test Class for RevSharing_FCMICalculator
 **/
@isTest
private class RevSharing_FCMICalculatorTest {
    private static Set<Id> affiliateId;
    private static List<Opportunity>listOpportunity;
    
    //Create test data
    public static void setup(){
        Account acc = TestUtils.createAccount('test', false);
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        acc.Affiliation__c = 'AA';
        insert acc;
        
        Affiliate_Yearly__c ay = TestUtils.createAffiliateYearly('Test yearly', acc.Id, '2013', true);
        ay.GMI_Amount__c=100;
        ay.Incentive_National_Share__c=23.00;
        ay.Union_Cost_Factor__c = 15.0000;
        ay.Foundation_Cost_Factor__c = 11.0000;
        ay.Eligible_for_GMI__c=false;
        ay.Affiliate_Indemnification_Threshold__c= 34567;
        ay.Affiliate_Actual_Indemnification_from_To__c = 123456;
        ay.Affiliate_Actual_Indemnification__c=1234;
        ay.National_Actual_Indemnification_Today__c=1234;
        ay.National_Actual_Indemnification__c=1234;
        ay.FCMI_stage_DateStart__c=System.today();
        ay.FCMI_stage_DateEnd__c=system.today()+5;
        update ay;
        affiliateId = new Set<Id>();
        affiliateId.add(ay.Id);
        
        
        listOpportunity = new List<Opportunity>();
       	
        for(Integer i=0;i<15;i++){
            Opportunity opp = TestUtils.createOpportunity(acc.Id,'TestOpp'+i,False);
            opp.Amount=10;
            opp.Sharing_Entity_Affiliation__c='NA';
            opp.Program_Type__c='35';
            opp.Exclude_Cost_Factors_in_RevShare__c=true;
            opp.Exclude_from_Revenue_Sharing__c=false;
            opp.Sharing_Entity__c='NAA - National ACLU (Membership)';
            
            opp.StageName='Completed';
            opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
            
            opp.Cost_Factor__c=10;
            opp.Use_Campaign_Cost__c=true;
            opp.CloseDate=Date.today();
            listOpportunity.add(opp);            
            
        }
        
    }
    @isTest
    static void testMethod1(){
        setup();
        Test.startTest();
        
        listOpportunity.get(0).Sharing_Code__c='N111';
        listOpportunity.get(1).Sharing_Code__c='N175';
        listOpportunity.get(2).Sharing_Code__c='R113';
        listOpportunity.get(2).Deposit_site__c='NAA - Nat U-Chase';
        listOpportunity.get(3).Sharing_Code__c='R121';
        listOpportunity.get(4).Sharing_Code__c='R131';
        listOpportunity.get(5).Sharing_Code__c='R141';
        listOpportunity.get(6).Sharing_Code__c='R151';
        listOpportunity.get(7).Sharing_Code__c='R181';
        listOpportunity.get(8).Sharing_Code__c='R112';
        listOpportunity.get(8).Deposit_site__c='NAA - Nat U-Chase';
        listOpportunity.get(9).Sharing_Code__c='K161';
        listOpportunity.get(10).Sharing_Code__c='K165';
        listOpportunity.get(11).Sharing_Code__c='K171';
        listOpportunity.get(11).Program_Type__c='12';
        listOpportunity.get(11).CloseDate=Date.newInstance(1999,01,01);
        listOpportunity.get(12).Sharing_Code__c='R191';
        listOpportunity.get(12).Program_Type__c='12';
        listOpportunity.get(13).Sharing_Code__c='R192';
        listOpportunity.get(13).Program_Type__c='12';
        listOpportunity.get(14).Sharing_Code__c='T400';
        listOpportunity.get(14).Program_Type__c='12';
        insert listOpportunity;
        
        //Execute batch
        Database.executebatch(new RevSharing_FCMICalculator(affiliateId,'Test'), 200);
        Test.stopTest();
        
        Affiliate_Yearly__c ayc = [SELECT FCMI_NatDirectMailLess2500__c FROM Affiliate_Yearly__c WHERE Id IN:affiliateId];
        System.assertEquals(10, ayc.FCMI_NatDirectMailLess2500__c);
    }
        
}