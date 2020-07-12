@isTest
private class TBD_GeoFirewallsPreferenceRerunTest {

     public static testMethod void exeuteTest1(){
        /*creating Account records*/
        List<Account> lstAccount = new List<Account>();
        Account acc1 = TestUtils.createAccount('test', false);
        acc1.Affiliation__c = 'AA';
        lstAccount.add(acc1);
        insert lstAccount;

        List<Group> lstGroup = TestUtils.createGroupList(2);
        insert lstGroup;
        
        List<rC_Bios__Preference__c> lstBiospreference = new List<rC_Bios__Preference__c>();
        rC_Bios__Preference__c rcBios1 = TestUtils.createPreferences(acc1.id,false);
        rcBios1.rC_Bios__Code_Value__c = 'MM';
        rC_Bios__Preference__c rcBios2 = TestUtils.createPreferences(acc1.id,false);
        rcBios2.rC_Bios__Code_Value__c = 'ML';
        lstBiospreference.add(rcBios1);
        lstBiospreference.add(rcBios2);
        insert lstBiospreference;
        
        lstBiospreference[0].rC_Bios__Code_Value__c = 'MM';
        update lstBiospreference[0];
        
        list<rC_Bios__Preference__share> lstSharerecords = new list<rC_Bios__Preference__share>(); 
        
        for(rC_Bios__Preference__share pfShare : [SELECT Id, UserOrGroupId, ParentId,AccessLevel
                                         FROM rC_Bios__Preference__share
                                         Where parentID =: lstBiospreference[0].Id and RowCause = 'Manual']) {
                                lstSharerecords.add(pfShare);             
        }
        if(!lstSharerecords.isEmpty()) {
            delete lstSharerecords;
        }
        
        Database.executeBatch(new TBD_GeoFirewallsPreferenceRerun(), 50);
    } 

}