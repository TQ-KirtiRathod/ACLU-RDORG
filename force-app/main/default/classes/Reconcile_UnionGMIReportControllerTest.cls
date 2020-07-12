/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 28, 2017
* @description      : Test class for Reconcile_UnionGMIReportController
* @Code Coverage    : 100%
*/
@IsTest
public class Reconcile_UnionGMIReportControllerTest {
    
    @testSetup //Creating test data
    public static void createTestData() {
        User sysAdmin = TestUtils.createUser('Admin', 'testUser@example.com.random2', null, true);

        Account testAcc1 = TestUtils.createAccount('testAcc1', false);
        testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        testAcc1.Affiliation__c = 'AK';
        insert testAcc1;

        Account testAcc2 = TestUtils.createAccount('testAcc2', false);
        testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        testAcc1.Affiliation__c = 'AK';
        insert testAcc2;

        String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i=0; i<=27; i++) {
            Opportunity opp = TestUtils.createOpportunity(testAcc1.Id,'testOpp'+i,false);
            opp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp.Sharing_Entity_Affiliation__c = 'AK';
            opp.StageName = 'Completed';
            opp.CloseDate = Date.today()-2;
            opp.Exclude_from_Revenue_Sharing__c = False;
            opp.Amount = 2;
            opp.Deposit_Site__c = 'AK_Alaska';
            opp.RPT_Package_Code__c = 'xxCP';
            opp.Description = 'Test Record';
            opp.Restriction__c = 'BRT - Bill of Rights Trust';
            oppList.add(opp);
        }

        oppList[0].Sharing_Code__c = 'E121';
        oppList[0].Deposit_Site__c = 'NAA - Nat U-Chase';
        oppList[0].Amount = 20;
        oppList[1].Sharing_Code__c = 'E121';
        oppList[1].Amount = 30;
        oppList[2].Sharing_Code__c = 'E151';
        oppList[2].Deposit_Site__c = 'NAA - Nat U-Chase';
        oppList[2].Amount = 4;
        oppList[3].Sharing_Code__c = 'R131';
        oppList[4].Sharing_Code__c = 'E121';
        oppList[5].Sharing_Code__c = 'E191';
        oppList[6].Sharing_Code__c = 'E141';
        oppList[7].Sharing_Code__c = 'E181';
        oppList[8].Sharing_Code__c = 'C165';
        oppList[9].Sharing_Code__c = 'C161';
        oppList[10].Sharing_Code__c = 'U001';
        oppList[11].Sharing_Code__c = 'U002';
        oppList[12].Sharing_Code__c = 'U003';
        oppList[13].Sharing_Code__c = 'U004';
        oppList[14].Sharing_Code__c = 'U005';
        oppList[15].Sharing_Code__c = 'E191';
        oppList[15].Deposit_Site__c = 'NAA - Nat U-Chase';
        oppList[16].Sharing_Code__c = 'E151';
        oppList[16].Deposit_Site__c = 'NAA - Nat U-Chase';
        oppList[17].Sharing_Code__c = 'R191';
        oppList[17].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[18].Sharing_Code__c = 'U001';
        oppList[18].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[19].Sharing_Code__c = 'U002';
        oppList[19].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[20].Sharing_Code__c = 'U003';
        oppList[20].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[21].Sharing_Code__c = 'U004';
        oppList[21].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[22].Sharing_Code__c = 'U005';
        oppList[22].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[23].Sharing_Code__c = 'E181';
        oppList[23].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[24].Sharing_Code__c = 'E141';
        oppList[24].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[25].Sharing_Code__c = 'R151';
        oppList[26].Sharing_Code__c = 'R113';
        oppList[27].Sharing_Code__c = 'R113';
        oppList[27].Deposit_Site__c = 'NAE_NatF_Endowment';
        insert oppList;
      
        //Create Affiliate_Yearly__c record
        Affiliate_Yearly__c affYearly = TestUtils.createAffiliateYearly('testAffiliateYeary1',testAcc1.Id,'2017',false);
        affYearly.Foundation_Cost_Factor__c = 0.2000;
        affYearly.Union_Cost_Factor__c = 0.2000;
        affYearly.CMI_stage_DateEnd__c = Date.today()-2;
        affYearly.CMI_stage_DateStart__c = Date.today()-3;
        affYearly.Fiscal_Year__c = getCFY();
        insert affYearly;

        Donors_Over_10K__c  d10k = New Donors_Over_10K__c();
        d10k.Affiliate_Yearly__c = affYearly.id;
        d10k.Account__c = testAcc2.id;
        d10k.Banked_by_Affiliate_Fdn__c = 10000.0;
        d10k.Banked_by_National_Fdn__c = 500.0;
        d10k.Base_Amount__c = 500;
        d10k.Affiliate_CP_and_Earmark_Info__c = 4000;
        d10k.National_CP_and_Earmark_Info__c = 2000;
        d10k.Fund_Type__c='Union';
        
        System.runAs(sysAdmin){
            Income_Type_Distribution__c itd = TestUtils.createIncomeTypeDistribution(affYearly.Id, 'Unrestricted Bequest / Planned Gift', 20.0, false);
            String ITD_RT_TRANSACTION_Id = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Affiliate Direct Mail').getRecordTypeId();
            itd.RecordTypeId = ITD_RT_TRANSACTION_Id;
            itd.Shared_in_Advance__c = true;
            insert itd;
            insert d10k;
        }

    }


    /*for testing Reconcile_FoundationNonGMIRptControllerTest method*/
    @isTest
    static void testReconcile_FoundationNonGMIRptController() {
        Affiliate_Yearly__c affYearly = [SELECT ID FROM Affiliate_Yearly__c LIMIT 1];
        Test.setCurrentPage(Page.Reconcile_UnionGMIReportPage);
        ApexPages.currentPage().getParameters().put('afid', affYearly.Id);
        
        Test.startTest();
        Reconcile_UnionGMIReportController r = new Reconcile_UnionGMIReportController();

        system.debug([Select name from Opportunity where Sharing_Code__c='E121']);

        Test.stopTest();
        //validate affiliate is not null
        system.assertEquals(2000, r.one_c8Total); //National_CP_and_Earmark_Info__c

        system.assertEquals(22, r.two_a); //E121 na 22
        //system.assertEquals(0, r.two_b); //E121 affil 22
        //system.assertEquals(0, r.a_1b); //E121 na 22 
        //system.assertEquals(0, r.s2_Total_woGMI); //E121 na 22 

        system.assertEquals(6, r.three_aTotal); //E151 na 6
        system.assertEquals(2, r.s1_megaSchedTotal); //E191

    }

    private static String getCFY() {
        Organization orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                                FROM Organization
                                WHERE id=:Userinfo.getOrganizationId()];

        Date today = system.today();
        Integer currentFY;
        if (today.month() >= orgInfo.FiscalYearStartMonth) {
            currentFY = today.year() + 1; 
        } else{
            currentFY = today.year();
        }
        return String.valueOf(currentFY);
    }

}