@isTest
private class RevSharingIndemnificationActualBatchTest {
    
    @isTest
    static void testupdateIndemnificationTotal(){
        Affiliate_Yearly__c affYearly = [SELECT Id FROM Affiliate_Yearly__c LIMIT 1];
        Set<Id> affYearlySet= new Set<Id>();
        affYearlySet.add(affYearly.Id);
        
        Test.startTest();
        Database.executebatch(new RevSharing_IndemnificationActuals_Batch(affYearlySet, 'Test'), 200);
        RevSharing_IndemnificationActuals_Batch.updateIndemnificationTotal(affYearly.Id);
        Test.stopTest();
        
        affYearly = [SELECT National_Actual_Indemnification_Today__c FROM Affiliate_Yearly__c LIMIT 1];
        //Assert to check sum of all opporunities
        System.assertEquals(140, affYearly.National_Actual_Indemnification_Today__c);
    }
    
    @testSetup //Create test data
    public static void setup(){
        // Insert 
        Account acc = TestUtils.createAccount('test', false);
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        acc.Affiliation__c = 'AA';
        insert acc;
        
        Affiliate_Yearly__c ay = TestUtils.createAffiliateYearly('Test yearly', acc.Id, '2018', true);
        
        //Insert update Opportunities
        List<Opportunity> listOpportunity = new List<Opportunity>();
        for(Integer i=0;i<15;i++){
            Opportunity opp = TestUtils.createOpportunity(acc.Id,'TestOpp'+i,False);
            opp.Amount=10;
            opp.Sharing_Entity_Affiliation__c='NA';
            opp.Program_Type__c='35';
            opp.Exclude_Cost_Factors_in_RevShare__c=true;
            opp.Exclude_from_Revenue_Sharing__c=false;
            opp.Sharing_Entity__c='AA - All Affiliates';
            opp.Sharing_Code__c='R112';
            opp.StageName='Completed';
            opp.Deposit_Site__c='NAA_NatU_Operating_chk/cash	';
            opp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
            opp.Cost_Factor__c=10;
            opp.Use_Campaign_Cost__c=true;
            opp.CloseDate=Date.today();
            listOpportunity.add(opp);
        }
        insert listOpportunity;
        listOpportunity[0].Deposit_Site__c = 'AK_Alaska';
        update listOpportunity;
    }
}