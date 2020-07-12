@isTest
private class zGeoFirewallsPreferenceTest {

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
        List<rC_Bios__Preference__c> lstBiospreference = new List<rC_Bios__Preference__c>();
        rC_Bios__Preference__c rcBios1 = TestUtils.createPreferences(acc1.id,false);
        rC_Bios__Preference__c rcBios2 = TestUtils.createPreferences(acc2.id,false);
        lstBiospreference.add(rcBios1);
        lstBiospreference.add(rcBios2);
        insert lstBiospreference;
    }
    /*for testing execute batch method*/
    public static testMethod void exeuteTest(){
        List<Group> lstGroup = [SELECT ID FROM Group];
        Test.startTest();
        zGeoFirewallsPreference zfp = new zGeoFirewallsPreference();
        Database.executeBatch(zfp);
        /*validating List of group has records or not*/
        System.assert(lstGroup.size() > 0);
        System.assertEquals(True, [Select id FROM rC_Bios__Preference__share].size() > 0 );
        Test.stopTest();
    }

}