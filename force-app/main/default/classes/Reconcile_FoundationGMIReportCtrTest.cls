/**
 * Test Class for Reconcile_FoundationGMIReportController
 **/
@isTest
public with sharing class Reconcile_FoundationGMIReportCtrTest {

  private static List<Affiliate_Yearly__c> lstAffiliateYear = new List<Affiliate_Yearly__c>();

  @testSetup //Method to create test data
  public static void createTestData() {
    system.debug('here 1');
    User sysAdmin = TestUtils.createUser('Admin', 'testUser@example.com.random2', null, true);
    Account testAcc1 = TestUtils.createAccount('testAcc1', false);
    testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
    testAcc1.Affiliation__c = 'AK';
    insert testAcc1;

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

    // Set diffrent Sharing_Code__c
    oppList[0].Sharing_Code__c = 'N111';
    oppList[0].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[0].Amount = 20;
    oppList[1].Sharing_Code__c = 'N175';
    oppList[1].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[1].Amount = 30;
    oppList[2].Sharing_Code__c = 'R131';
    oppList[2].Amount = 4;
    oppList[3].Sharing_Code__c = 'R131';
    oppList[3].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[4].Sharing_Code__c = 'R151';
    oppList[4].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[5].Sharing_Code__c = 'R151';
    oppList[6].Sharing_Code__c = 'R181';
    oppList[7].Sharing_Code__c = 'R191';
    oppList[8].Sharing_Code__c = 'R141';
    oppList[9].Sharing_Code__c = 'R181';
    oppList[10].Sharing_Code__c = 'K165';
    oppList[11].Sharing_Code__c = 'K161';
    oppList[12].Sharing_Code__c = 'Q001';
    oppList[13].Sharing_Code__c = 'Q002';
    oppList[14].Sharing_Code__c = 'Q003';
    oppList[15].Sharing_Code__c = 'Q004';
    oppList[16].Sharing_Code__c = 'Q005';
    oppList[17].Sharing_Code__c = 'R191';
    oppList[17].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[18].Sharing_Code__c = 'Q001';
    oppList[18].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[19].Sharing_Code__c = 'Q002';
    oppList[19].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[20].Sharing_Code__c = 'Q003';
    oppList[20].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[21].Sharing_Code__c = 'Q004';
    oppList[21].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[22].Sharing_Code__c = 'Q005';
    oppList[22].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[23].Sharing_Code__c = 'R181';
    oppList[23].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[24].Sharing_Code__c = 'R141';
    oppList[24].Deposit_Site__c = 'NAE_NatF_Endowment';
    oppList[25].Sharing_Code__c = 'R112';
    oppList[26].Sharing_Code__c = 'R113';
    oppList[27].Sharing_Code__c = 'R113';
    oppList[27].Deposit_Site__c = 'NAE_NatF_Endowment';
    insert oppList;


    Affiliate_Yearly__c testAffiliateYeary1 = TestUtils.createAffiliateYearly('testAffiliateYeary1',testAcc1.Id,'2017',false);
    testAffiliateYeary1.Foundation_Cost_Factor__c = 0.2000;
    testAffiliateYeary1.Union_Cost_Factor__c = 0.2000;
    testAffiliateYeary1.CMI_stage_DateEnd__c = Date.today()-2;
    testAffiliateYeary1.CMI_stage_DateStart__c = Date.today()-3;
    testAffiliateYeary1.Fiscal_Year__c = getCFY();
    insert testAffiliateYeary1;

    Donors_Over_10K__c  d10k = New Donors_Over_10K__c();
    d10k.Affiliate_Yearly__c = testAffiliateYeary1.id;
    //d10k.Account__c = testAffiliateYeary1.id;
    d10k.Banked_by_Affiliate_Fdn__c = 10000.0;
    d10k.Banked_by_National_Fdn__c = 500.0;
    d10k.Base_Amount__c = 500;
    d10k.Affiliate_CP_and_Earmark_Info__c = 4000;
    d10k.National_CP_and_Earmark_Info__c = 2000;
    d10k.Fund_Type__c='Foundation';
    
    
    System.runAs(sysAdmin){
        Income_Type_Distribution__c itd = TestUtils.createIncomeTypeDistribution(testAffiliateYeary1.Id, 'Unrestricted Bequest / Planned Gift', 20.0, false);
        String ITD_RT_TRANSACTION_Id = Schema.SObjectType.Income_Type_Distribution__c.getRecordTypeInfosByName().get('Affiliate Direct Mail').getRecordTypeId();
        itd.RecordTypeId = ITD_RT_TRANSACTION_Id;
        itd.Shared_in_Advance__c = true;
        insert itd;
        insert d10k;
    }
  }


  @isTest
  static void testReconcile_FoundationGMIReportCtr() {
    lstAffiliateYear = [SELECT ID FROM Affiliate_Yearly__c]; 
    Test.startTest();
      //setting the current page reference
      Test.setCurrentPage(Page.Reconcile_FoundationGMIReportPage);
      //setting the URL parameters of the page
      ApexPages.currentPage().getParameters().put('afid',lstAffiliateYear.get(0).id);
      Reconcile_FoundationGMIReportController r = new Reconcile_FoundationGMIReportController();
    Test.stopTest();   

    system.assertEquals(20, r.one_a); //N111
    system.assertEquals(30, r.one_c); //N175
    system.assertEquals(4, r.three_a); //R151
    system.assertEquals(10000, r.two_c2Total); //d10k
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