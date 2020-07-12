/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 28, 2017
* @description      : Test class for Reconcile_FoundationNonGMIRptCtr
* @Code Coverage    : 90%
*/
@IsTest
public class Reconcile_FoundationNonGMIRptCtrTest {
    private static List<Affiliate_Yearly__c> lstAffiliateYear = new List<Affiliate_Yearly__c>();
    
    //Method For testing Reconcile_FoundationNonGMIRptControllerTest method
    public static testMethod void Reconcile_FoundationNonGMIRptControllerTest() {
        lstAffiliateYear = [SELECT ID FROM Affiliate_Yearly__c]; 
        ApexPages.currentPage().getParameters().put('afid',lstAffiliateYear.get(0).id);
        Test.startTest();
        Reconcile_FoundationNonGMIRptController rfc = new Reconcile_FoundationNonGMIRptController();
        Test.stopTest();
        System.assert(rfc.affiliate!=null);
    }
    
    @testSetup //Method to create test data
    public static void createTestData() {
        Account testAcc1 = TestUtils.createAccount('testAcc1', false);
        testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        testAcc1.Affiliation__c = 'AK';
        insert testAcc1;
        
         Account testAcc2 = TestUtils.createAccount('testAcc2', false);
        testAcc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        testAcc2.Affiliation__c = 'AR';
        insert testAcc2;
        
        
        //Creating opportunity records
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i=0; i<20; i++) {
            Opportunity opp = TestUtils.createOpportunity(testAcc1.Id,'testOpp1',false);
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
            opp.Sharing_Entity_Affiliation__c = 'AK';
            opp.StageName = 'Completed';
            opp.CloseDate = Date.today()-2;
            opp.Exclude_from_Revenue_Sharing__c = False;
            opp.Amount = 2;
            opp.Deposit_Site__c = 'AK_Alaska';
            opp.RPT_Package_Code__c = 'ABCP';
            oppList.add(opp);
        }
        // Set diffrent Sharing_Code__c
        oppList[0].Sharing_Code__c = 'E151';
        oppList[0].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[0].AccountId = testAcc2.id;
        oppList[0].Sharing_Entity_Affiliation__c = 'AR';
        oppList[1].Sharing_Code__c = 'E191';
        oppList[1].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[1].AccountId = testAcc2.id; 
        oppList[1].Sharing_Entity_Affiliation__c = 'AR';
        oppList[2].Sharing_Code__c = 'E181';
        oppList[3].Sharing_Code__c = 'K161';
        oppList[4].Sharing_Code__c = 'K165';
        oppList[5].Sharing_Code__c = 'R112';
        oppList[6].Sharing_Code__c = 'R113';
        oppList[7].Sharing_Code__c = 'R151';
        oppList[8].Sharing_Code__c = 'Q001';
        oppList[9].Sharing_Code__c = 'Q002';
        oppList[10].Sharing_Code__c = 'Q003';
        oppList[11].Sharing_Code__c = 'Q004';
        oppList[12].Sharing_Code__c = 'Q005';
        oppList[13].Sharing_Code__c = 'N111';
        oppList[13].RPT_Package_Code__c = 'ABCP';
        oppList[13].Deposit_Site__c = 'NA_CN_NoCal_NNBanked';
        oppList[14].Sharing_Code__c = 'N175';
        oppList[15].Sharing_Code__c = 'R131';
        oppList[16].Sharing_Code__c = 'R181';
        oppList[17].Sharing_Code__c = 'R191';
        oppList[18].Sharing_Code__c = 'R113';
        oppList[18].Deposit_Site__c = 'NA_CN_NoCal_NNBanked';
        oppList[19].Sharing_Code__c = 'R151';
        oppList[19].Deposit_Site__c = 'NA_CN_NoCal_NNBanked';
        insert oppList;
        
        Affiliate_Yearly__c testAffiliateYeary1 = TestUtils.createAffiliateYearly('testAffiliateYeary1',testAcc1.Id,'2017',false);
        testAffiliateYeary1.Foundation_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.Union_Cost_Factor__c = 0.2000;
        testAffiliateYeary1.CMI_stage_DateEnd__c = Date.today();
        testAffiliateYeary1.CMI_stage_DateStart__c = Date.today()-3;
        testAffiliateYeary1.Fiscal_Year__c = getCFY();
        lstAffiliateYear.add(testAffiliateYeary1);
        insert lstAffiliateYear;
        
        List<Income_Type_Distribution__c> incomeTypeList = new List<Income_Type_Distribution__c >();
        Income_Type_Distribution__c it = TestUtils.createIncomeTypeDistribution(testAffiliateYeary1.id, 'Unrestricted Bequest / Planned Gift', 2, false);
        it.Fund_Type__c = 'Foundation';
        it.Shared_in_Advance__c = True;
        incomeTypeList.add(it);
        
        Income_Type_Distribution__c it2 = TestUtils.createIncomeTypeDistribution(testAffiliateYeary1.id, 'All Affiliate Fund', 2, false);
        it2.Fund_Type__c = 'Foundation';
        it2.RecordTypeId = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Other Income Types').getRecordTypeId();
        it2.Shared_in_Advance__c = True;
        incomeTypeList.add(it2);
        
        Income_Type_Distribution__c it3 = TestUtils.createIncomeTypeDistribution(testAffiliateYeary1.id, 'Special Sharing', 2, false);
        it3.Fund_Type__c = 'Foundation';
        it3.RecordTypeId = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Other Income Types').getRecordTypeId();
        it3.Shared_in_Advance__c = True;
        it3.Description__c = 'afasdfasf';
        incomeTypeList.add(it3);
        insert incomeTypeList;
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