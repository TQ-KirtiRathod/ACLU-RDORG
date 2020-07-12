/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 * Test class for Member_Donor_Count_Calc class
 */
@isTest
private class Member_Donor_Count_Calc_Test {

    private static List<Opportunity>listOpportunity;
    private static  Affiliate_Yearly__c affiliateYearlyobj;
    private static Set<Id> affiliateId;
    @isTest
    private static void TestMember_Donor_Count_Calc(){
        Test.startTest();
        createData();
        for(Integer i=0;i<5;i++){
           listOpportunity.get(i).Sharing_Code__c='P001'; 
           listOpportunity.get(i).Manual_Sharing_Code__c = true;
        }
        
        for(Integer i=5;i<10;i++){
           listOpportunity.get(i).Sharing_Code__c='U001'; 
           listOpportunity.get(i).Manual_Sharing_Code__c = true;
        }
   
        insert listOpportunity;
        Database.executebatch(new Member_Donor_Count_Calc(affiliateId), 200);
        Test.stopTest();
        Affiliate_Yearly__c aff = [SELECT Id, Member_Count__c, Donor_Count__c FROM  Affiliate_Yearly__c LIMIT 1];
        system.assertEquals(5, aff.Member_Count__c);
        system.assertEquals(5, aff.Donor_Count__c);
    }
    
    private static void createData(){
        affiliateId = new set<Id>();
        Account ac= TestUtils.createAccount('Test',False);
        ac.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        ac.Affiliation__c='AA';
        insert ac;
        
        //creating Affiliate Yearly record
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
            
        affiliateId.add(affiliateYearlyobj.id);
        
            
        listOpportunity = new List<Opportunity>();
         
        for(Integer i=0;i<10;i++){
            Opportunity opp = TestUtils.createOpportunity(ac.Id,'TestOpp'+i,False);
            opp.Amount=10+i;
            opp.Sharing_Entity_Affiliation__c='NA';
            opp.Program_Type__c='35';
            opp.Exclude_Cost_Factors_in_RevShare__c=true;
            opp.Exclude_from_Revenue_Sharing__c=false;
            opp.Sharing_Entity__c='AA - All Affiliates';
            //opp.Sharing_Code__c='D009';
            opp.StageName='Completed';
            // opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('TRANSACTION').getRecordTypeId();
            opp.RecordTypeId='01236000000fBmO';
            opp.Cost_Factor__c=10;
            opp.Use_Campaign_Cost__c=true;
            opp.CloseDate=Date.today();
            //  opp.Exclude_from_Revenue_Sharing__c=
            listOpportunity.add(opp);            
            
        }
        //insert listOpportunity;
        
    }
}