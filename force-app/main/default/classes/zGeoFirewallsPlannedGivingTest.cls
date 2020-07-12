/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 19, 2017
* @description      : Test class for zGeoFirewallsPlannedGiving
*/
@IsTest
public class zGeoFirewallsPlannedGivingTest {
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
        List<rC_Giving__Planned_Giving__c> lstGivingPlannedGiving = new List<rC_Giving__Planned_Giving__c>();
        rC_Giving__Planned_Giving__c rcg1 = TestUtils.createPlannedGiving(acc1.id,acc1.id,false);
        rC_Giving__Planned_Giving__c rcg2 = TestUtils.createPlannedGiving(acc2.id,acc2.id,false);
        lstGivingPlannedGiving.add(rcg1);
        lstGivingPlannedGiving.add(rcg2);
        insert lstGivingPlannedGiving;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsPlannedGiving zfp1 = new zGeoFirewallsPlannedGiving('NATIONAL', datetime.now());
        zGeoFirewallsPlannedGiving zfp2 = new zGeoFirewallsPlannedGiving('NATIONAL', null);
        Database.executeBatch(zfp1);
        Database.executeBatch(zfp2);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
	}
}