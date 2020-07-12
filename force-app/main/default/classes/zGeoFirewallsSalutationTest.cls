/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 22, 2017
* @description      : Test class for zGeoFirewallsSalutation
*/
@IsTest
public class zGeoFirewallsSalutationTest {
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
        List<rC_Bios__Salutation__c> lstBiosSal = new List<rC_Bios__Salutation__c>();
        rC_Bios__Salutation__c rcg1 = TestUtils.createSalutation(acc1.id,false);
        rC_Bios__Salutation__c rcg2 = TestUtils.createSalutation(acc2.id,false);
        lstBiosSal.add(rcg1);
        lstBiosSal.add(rcg2);
        insert lstBiosSal;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsSalutation zfp1 = new zGeoFirewallsSalutation();
        Database.executeBatch(zfp1);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
    }
}