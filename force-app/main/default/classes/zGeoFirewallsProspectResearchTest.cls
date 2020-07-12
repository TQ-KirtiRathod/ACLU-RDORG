/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 19, 2017
* @description      : Test class for zGeoFirewallsProspectResearch
*/
@IsTest
public class zGeoFirewallsProspectResearchTest {
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
        List<Prospect_Research__c> lstProspectResearch = new List<Prospect_Research__c>();
        lstProspectResearch = TestUtils.createProspectResearchList(2);
        lstProspectResearch.get(0).Account__c = acc1.id;
        lstProspectResearch.get(1).Account__c = acc2.id;
        insert lstProspectResearch;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsProspectResearch zfp = new zGeoFirewallsProspectResearch();
        Database.executeBatch(zfp);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
    }
}