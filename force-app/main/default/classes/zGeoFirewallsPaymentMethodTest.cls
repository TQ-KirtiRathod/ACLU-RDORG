/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 22, 2017
* @description      : Test class for zGeoFirewallsPaymentMethod
*/
@IsTest
public class zGeoFirewallsPaymentMethodTest {
    /*For creating test data*/
    @testSetup
    public static void createTestData() {
        /*creating Account records*/
        List<Account> lstAccount = new List<Account>();
        Account acc1 = TestUtils.createAccount('test', false);
        acc1.Affiliation__c = 'AA';
        lstAccount.add(acc1);
        Account acc2 = TestUtils.createAccount('test2', false);
        acc2.Affiliation__c = 'AK';
        lstAccount.add(acc2);
        insert lstAccount;
        /*creating the records of group*/
        List<Group> lstGroup = TestUtils.createGroupList(2);
        insert lstGroup;
        /*creating the records of prospectResearch*/
        List<rC_Giving__Payment_Method__c> lstGivingPayment = new List<rC_Giving__Payment_Method__c>();
        rC_Giving__Payment_Method__c rcg1 = TestUtils.createPaymentMethod(acc1.id,false);
        rC_Giving__Payment_Method__c rcg2 = TestUtils.createPaymentMethod(acc2.id,false);
        lstGivingPayment.add(rcg1);
        lstGivingPayment.add(rcg2);
        insert lstGivingPayment;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsPaymentMethod zfp1 = new zGeoFirewallsPaymentMethod('NATIONAL', datetime.now());
        zGeoFirewallsPaymentMethod zfp2 = new zGeoFirewallsPaymentMethod('NATIONAL', null);
        Database.executeBatch(zfp1);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
        
    }
}