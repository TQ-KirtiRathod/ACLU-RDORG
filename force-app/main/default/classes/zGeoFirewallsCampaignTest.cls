/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 22, 2017
* @description      : Test class for zGeoFirewallsCampaign
*/
@IsTest
public class zGeoFirewallsCampaignTest {
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
        /*creating the records of Campaign*/
        List<Campaign> campList = new List<Campaign>();
        Campaign camp1 = TestUtils.createCampaign('test',false);
        camp1.rC_Giving__Source_Code__c = '123';
        camp1.Account_Code__c = 'ABAD - Abortion Ad';
        camp1.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        campList.add(camp1);
        Campaign camp2 = TestUtils.createCampaign('test1',false);
        camp2.rC_Giving__Source_Code__c = '1234';
        camp2.Account_Code__c = 'ABAD - Abortion Ad';
        camp2.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        campList.add(camp2);
        insert campList;
        /*creating the lead records */
        List<Lead> leadList = new List<Lead>();
        Lead lead1 = TestUtils.createLead('test', 'test', 'Open', false);
        Lead lead2 = TestUtils.createLead('test1', 'test1', 'Open', false);
        leadList.add(lead1);
        leadList.add(lead2);
        insert leadList;
        /*creating the records of zGeoFirewallsCampaign*/
        List<CampaignMember> lstCampShare = new List<CampaignMember>();
        CampaignMember rcg1 = TestUtils.createCampaignMember(camp1.id,lead1.id, false);
        CampaignMember rcg2 = TestUtils.createCampaignMember(camp2.id,lead2.id, false);
        lstCampShare.add(rcg1);
        lstCampShare.add(rcg2);
        insert lstCampShare;
        
    }
    
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsCampaign zfp1 = new zGeoFirewallsCampaign();
        Database.executeBatch(zfp1);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        Test.stopTest();
        
    }
}