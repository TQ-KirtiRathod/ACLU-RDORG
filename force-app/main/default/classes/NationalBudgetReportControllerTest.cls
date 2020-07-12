/**
 * Test Class for NationalBudgetReportController
 **/
@isTest
private class NationalBudgetReportControllerTest {
    private static NationalBudgetReportController nbrc;
    @isTest
    private static void testNBRC(){
        nbrc = new NationalBudgetReportController();
        nbrc.Budget_Fiscal_Year = '2017';
        nbrc.c3NationBudgetReport = 'report';
        nbrc.c4NationBudgetReport = 'c4';
        nbrc.current_YTD_EndDate = system.today();
        nbrc.current_YTD_StartDate = system.today().addDays(11);
        nbrc.DefaultBudget_Fiscal_Year = '2011';
        nbrc.Prior_Fiscal_Year = '2101';
        nbrc.nationBudgetSummaryReport = 'summary';
        nbrc.nationBudgetUnbudgetGiftReport = 'gift';
        nbrc.isShowError = true;
        nbrc.prior_YTD_EndDate = system.today();
        nbrc.prior_YTD_StartDate =  system.today();
        nbrc.getBudgetFiscalYearOptions();
        nbrc.getPriorFiscalYearOptions();
        nbrc.showReport();
        nbrc.current_YTD_EndDate = null;
        nbrc.showReport();
        System.assertEquals(false,nbrc.isRecordExist);
     } 
    
    @isTest
    private static void testNBRC1(){
     //Creating an non-affiliated user
        User u = TestUtils.createUser('testLast', 'syst@testorg.com', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        System.runAs(u){
        nbrc = new NationalBudgetReportController();
        nbrc.Budget_Fiscal_Year = '2017';
        nbrc.c3NationBudgetReport = 'report';
        nbrc.c4NationBudgetReport = 'c4';
        nbrc.current_YTD_EndDate = system.today();
        nbrc.current_YTD_StartDate = system.today().addDays(-11);
        nbrc.DefaultBudget_Fiscal_Year = '2011';
        nbrc.Prior_Fiscal_Year = '2101';
        nbrc.nationBudgetSummaryReport = 'summary';
        nbrc.nationBudgetUnbudgetGiftReport = 'gift';
        nbrc.isShowError = true;
        nbrc.prior_YTD_EndDate = system.today();
        nbrc.prior_YTD_StartDate =  system.today().addDays(-11);
        National_Budget_Report_Status__c nbrs = new National_Budget_Report_Status__c();
        nbrs.Name = 'test';
        nbrs.Report_Request_In_Progress__c = true;
        Test.startTest();
        insert nbrs;
        Test.stopTest();
        nbrc.showReport();
        System.assertEquals(false,nbrc.isRecordExist);
        }
}
    
    @isTest
    private static void testNBRC2(){
        nbrc = new NationalBudgetReportController();
        nbrc.Budget_Fiscal_Year = '2017';
        nbrc.c3NationBudgetReport = 'report';
        nbrc.c4NationBudgetReport = 'c4';
        nbrc.current_YTD_EndDate = system.today();
        nbrc.current_YTD_StartDate = system.today().addDays(-11);
        nbrc.DefaultBudget_Fiscal_Year = '2011';
        nbrc.Prior_Fiscal_Year = '2101';
        nbrc.nationBudgetSummaryReport = 'summary';
        nbrc.nationBudgetUnbudgetGiftReport = 'gift';
        nbrc.isShowError = true;
        nbrc.prior_YTD_EndDate = system.today();
        nbrc.prior_YTD_StartDate =  system.today().addDays(-11);
        National_Budget_Report_Status__c nbrs = new National_Budget_Report_Status__c();
        nbrs.Name = 'test';
        nbrs.Report_Request_In_Progress__c = false;
        insert nbrs;
        nbrc.showReport();
        System.assertEquals(true,nbrc.isRecordExist);
    }
}