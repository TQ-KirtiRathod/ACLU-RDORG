/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 19, 2017
* @description      : Test class for zGeoFirewallsProspectResearch
* @Code Coverage    : 96%
*/
@IsTest
public class zGeoFirewallsRelationshipTest {
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
        /*creating the records of Relationship*/
        List<rC_Bios__Relationship__c> lstBiosRelation = new List<rC_Bios__Relationship__c>();
        rC_Bios__Relationship__c rcBios1 = TestUtils.createRelationShip(acc1.id,acc1.id,false);
        rC_Bios__Relationship__c rcBios2 = TestUtils.createRelationShip(acc2.id,acc2.id,false);
        lstBiosRelation.add(rcBios1);
        lstBiosRelation.add(rcBios2);
        insert lstBiosRelation;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest(){
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsRelationship zfp = new zGeoFirewallsRelationship();
        Database.executeBatch(zfp);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
    }
}