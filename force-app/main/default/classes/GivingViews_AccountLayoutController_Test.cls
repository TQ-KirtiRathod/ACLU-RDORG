/*
 *
 *Name  :  GivingViews_AccountLayoutController_Test
 *Author:  Appirio India
 *Date  :  June 21, 2017
 *Purpose : Test Class for GivingViews_AccountLayoutController class
 *
 */
@isTest
private class GivingViews_AccountLayoutController_Test {

    //Test method to check GivingViews_AccountLayoutController constructor
    private static testMethod void test() {
        Account acc = TestUtils.createAccount('Account' + 1, true);

        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        GivingViews_AccountLayoutController obj = new GivingViews_AccountLayoutController(sc);

        System.assertEquals(acc.id, obj.AccountId);
    }

}