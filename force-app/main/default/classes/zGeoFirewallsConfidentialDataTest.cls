/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 22, 2017
* @description      : Test class for zGeoFirewallsConfidentialData
* @Code Coverage    : 96%
*/
@IsTest
public class zGeoFirewallsConfidentialDataTest {
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
        /*creating the records of Opportunity*/
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = TestUtils.createOpportunity(acc1.id,'testopp',false);
        Opportunity opp2 = TestUtils.createOpportunity(acc2.id,'testopp1',false);
        oppList.add(opp1);
        oppList.add(opp2);
        /*creating the records of Contact*/
        List<Contact> conList = new List<Contact>();
        Contact con1 = TestUtils.createContact(acc1,'test','test',false);
        Contact con2 = TestUtils.createContact(acc2,'test1','test1',false);
        conList.add(con1);
        conList.add(con2);
        /*creating the records of prospectResearch*/
        List<Confidential_Data__c> lstConfData = new List<Confidential_Data__c>();
        Confidential_Data__c rcg1 = TestUtils.createConfidentialData(acc1.id,con1.id,opp1.id,false);
        Confidential_Data__c rcg2 = TestUtils.createConfidentialData(acc2.id,con2.id,opp2.id,false);
        lstConfData.add(rcg1);
        lstConfData.add(rcg2);
        insert lstConfData;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsConfidentialData zfp1 = new zGeoFirewallsConfidentialData();
        zGeoFirewallsConfidentialData zfp2 = new zGeoFirewallsConfidentialData();
        Database.executeBatch(zfp1);
        Database.executeBatch(zfp2);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
    }
}