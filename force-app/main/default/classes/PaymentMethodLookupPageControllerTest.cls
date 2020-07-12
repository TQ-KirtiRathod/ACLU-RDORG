/*
*
*Name  :  PaymentMethodLookupPageController
*Author:  Ana Ferreira
*Date  :  Dec 02, 2019
* BGE-84
*Purpose : Custom controller for PaymentMethod page. Used in BGE and opened when lookup icon.
*
*/
@isTest
private without sharing class PaymentMethodLookupPageControllerTest {

    private static List<Account> accList = new List<Account>();
    private static Opportunity opp = new Opportunity();
    private static  rC_Giving__Payment_Method__c payment = new rc_Giving__Payment_Method__c();
    private static PageReference pageRef = Page.Payment_Method_Lookup_Page;
    private static PaymentMethodLookupPageController accLPC = new PaymentMethodLookupPageController();

    public static void testSetup() {
        accList = TestUtils.createAccounts(true);
        opp = testUtils.createOpportunity(accList.get(0).id, 'Name', false);
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Grant').getRecordTypeId();
        insert opp;
        payment = TestUtils.createPaymentMethod(accList[0].id, true);
        pageRef.getParameters().put('accountId', accList[0].Id);
    }

    @isTest
    private static void testExceptionChar(){
        testSetup();
        Test.setCurrentPageReference(pageRef);
        Test.setCurrentPage(pageRef);
        System.assertEquals(10,accList.size());
        String testQuery1='m';
        accLPC.query=testQuery1;
        accLPC.runQuery();
        System.assert(ApexPages.hasMessages(), 'Search term must be more than two Characters');
    }

    @isTest
    private static void testReturnResult(){
        testSetup();
        Test.setCurrentPageReference(pageRef);
        Test.setCurrentPage(pageRef);
        System.assertEquals(10,accList.size());
        accLPC.paymentMethodCreated=true;
        accLPC.query=payment.name;
        accLPC.runQuery();
        system.assertEquals(ApexPages.hasMessages(), false);

        accLPC.saveNewPaymentMethod();
        system.assertEquals(true, ApexPages.hasMessages());
    }

    @isTest
    private static void testAccountNotNullAndTherm(){
        testSetup();
        ApexPages.currentPage().getParameters().put('accountId',accList[0].Id);
        accLPC.accountId=accList[0].Id;
        PageReference page = Page.Payment_Method_Lookup_Page;
        PaymentMethodLookupPageController paymentMethodLPC = new PaymentMethodLookupPageController();
        Test.setCurrentPageReference(page);
        Test.setCurrentPage(page);
        String testQuery1='cash';
        accLPC.query=testQuery1;
        paymentMethodLPC.runQuery();

        System.assert(ApexPages.hasMessages(), null);
    }

    @isTest
    private static void testAccountNotNull(){
        testSetup();
        ApexPages.currentPage().getParameters().put('accountId',accList[0].Id);
        accLPC.accountId=accList[0].Id;
        PageReference page = Page.Payment_Method_Lookup_Page;
        PaymentMethodLookupPageController paymentMethodLPC = new PaymentMethodLookupPageController();
        Test.setCurrentPageReference(page);
        Test.setCurrentPage(page);
        paymentMethodLPC.runQuery();

        System.assert(ApexPages.hasMessages(), 'Search term must be more than two Characters');
    }

    @isTest
    private static void newPaymentWindow(){
        Test.setCurrentPageReference(pageRef);
        Test.setCurrentPage(pageRef);
        PageReference page = accLPC.newPaymentWindow();
        System.assertEquals(page.getUrl().contains('/apex/Payment_Method_Lookup_Page?accountId'), true);
    }

    @isTest
    private static void getRecordTyoes(){
        PaymentMethodLookupPageController controller =new PaymentMethodLookupPageController();

        List<SelectOption> recType = PaymentMethodLookupPageController.getPaymentMethodsRecordType();
        System.assertNotEquals(recType.size(), 0);

    }


}