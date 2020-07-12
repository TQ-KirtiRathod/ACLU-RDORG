/**
 * Test Class for RevenueSharingReportsController
 **/
@isTest
private class RevenueSharingReportsControllerTest {
    private static testMethod void testRevenueSharingReportsController(){
        list<Account> acList = new list<Account>();
        for(Integer i = 0; i<5; i++) {
            Account testAcc1 = TestUtils.createAccount('testAcc1', false);
            testAcc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
    		testAcc1.Affiliation__c = 'AK';
    		acList.add(testAcc1);
        }
        insert acList;
        
        list<Affiliate_Yearly__c> testAffiliateYearlys = new list<Affiliate_Yearly__c>();
        for(Integer i = 0; i<5; i++) {
            Affiliate_Yearly__c testAffiliateYeary1 = TestUtils.createAffiliateYearly('testAffiliateYeary1',acList[i].Id,'2017',false);
            testAffiliateYeary1.Foundation_Cost_Factor__c = 0.2000;
            testAffiliateYeary1.Union_Cost_Factor__c = 0.2000;
            testAffiliateYeary1.CMI_stage_DateEnd__c = Date.today()-2;
            testAffiliateYeary1.CMI_stage_DateStart__c = Date.today()-3;
            testAffiliateYeary1.Fiscal_Year__c = '2018';
            testAffiliateYearlys.add(testAffiliateYeary1);
        }
        insert testAffiliateYearlys;
        
		//setting the current page reference
        Test.setCurrentPage(Page.CMI_Reports);
        //setting the URL parameters of the page
        ApexPages.CurrentPage().getParameters().put('fiscalYear', '2018');
        
        RevenueSharingReportsController rsrc = new RevenueSharingReportsController();
        
        System.assertEquals((Datetime.newInstance(Date.today()-3,Time.newInstance(12, 0, 0, 0))).format('d-MMM-yy'),RevenueSharingReportsController.startDate);
		System.assertEquals((Datetime.newInstance(Date.today()-2,Time.newInstance(12, 0, 0, 0))).format('d-MMM-yy'),RevenueSharingReportsController.endDate);
    }
}