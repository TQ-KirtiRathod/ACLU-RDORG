/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 23, 2017
* @description      : Test class for zGeoFirewallsActionPlan
*/
@IsTest
public class zGeoFirewallsActionPlanTest {
    /*For creating test data*/
    @testSetup
    public static void createTestData() {
        /*creating Account records*/
        List<Account> lstAccount = new List<Account>();
        Account acc1 = TestUtils.createAccount('test1', false);
        acc1.Affiliation__c = 'AA';
        lstAccount.add(acc1);
        Account acc2 = TestUtils.createAccount('test2', false);
        acc2.Affiliation__c = 'AK';
        lstAccount.add(acc2);
        insert lstAccount;
        /*creating the records of group */
        List<Group> lstGroup = TestUtils.createGroupList(2);
        insert lstGroup;
        System.debug('lstAccount.get(0)'+lstAccount.get(0));
        System.debug('lstAccount.get(1)'+lstAccount.get(1));
        /*creating the records of rC_Bios__Action_Plan__c*/
        List<rC_Bios__Action_Plan__c> lstBiosAction = new List<rC_Bios__Action_Plan__c>();
        rC_Bios__Action_Plan__c rcg1 = TestUtils.createBiosActionPlan(lstAccount.get(0).id,false);
        rC_Bios__Action_Plan__c rcg2 = TestUtils.createBiosActionPlan(lstAccount.get(1).id,false);
        lstBiosAction.add(rcg1);
        lstBiosAction.add(rcg2);
        insert lstBiosAction;
    }
    
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsActionPlan zfp1 = new zGeoFirewallsActionPlan();
        Database.executeBatch(zfp1);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
    }
}