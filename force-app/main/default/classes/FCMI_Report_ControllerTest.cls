/**
 * Test Class for FCMI_Report_Controller
 **/
@isTest
private class FCMI_Report_ControllerTest {
    private static testMethod void testFCMI_Report_Controller(){
        list<Account> accList = new list<Account>();
        String affiliateId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        for(Integer i = 0; i < 10; i++) {
            Account testacc1 = TestUtils.createAccount('testAcc1', false);
            testacc1.RecordTypeId = affiliateId;
            accList.add(testacc1);
        }
        insert accList;
        list<Affiliate_Yearly__c> affList = new list<Affiliate_Yearly__c>();
        for(Integer i = 0; i < 10; i++) {
            Affiliate_Yearly__c testAffYearly1 = TestUtils.createAffiliateYearly('testAffYearly1',accList[i].Id,'2017',false);
            testAffYearly1.FCMI_stage_DateStart__c = Date.today()-i;
            testAffYearly1.FCMI_stage_DateEnd__c = Date.today()+i;
            affList.add(testAffYearly1);
        }
        insert affList;
        Test.setCurrentPage(Page.FCMI_Reports);
        ApexPages.CurrentPage().getParameters().put('fiscalYear', '2017');
        FCMI_Report_Controller fcmi = new FCMI_Report_Controller();
        system.assertEquals(10, fcmi.listOfRecords.size());
    }
}