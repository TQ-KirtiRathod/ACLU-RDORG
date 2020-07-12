/*
*
*Name  :  AccountTeamRecordAccessUtilityTest
*Author:  Appirio India (Bhavesh)
*Date  :  Nov 6, 2017
*Purpose : test Class for AccountTeamRecordAccessUtility
*/
@isTest
public class AccountTeamRecordAccessUtilityTest {
    static Account acc;
    static Contact con;
    static User u1, u2, u3;
    static Account_Team__c accteam1, accteam2, accteam3;
    @testSetup
    private static void testData(){
        acc = TestUtils.createAccount('Test Account', true);
        con = TestUtils.createContact(acc, 'Test', 'Contact', true);
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Marketing User' LIMIT 1];
        List<User> userList = new List<User>();
        u1 = TestUtils.createUser('xxxtest1','test1@aclu.org', null, false);
        u1.ProfileId = p.id;
        userList.add(u1);
        u2 = TestUtils.createUser('xxxtest2','test12@aclu.org', null, false);
        u2.ProfileId = p.id;
        userList.add(u2);
        u3 = TestUtils.createUser('xxxtest3','test13@aclu.org', null, false);
        u3.ProfileId = p.id;
        userList.add(u3);
        insert userList;    
        /*rC_Bios__Salutation__Share sharingRec = new rC_Bios__Salutation__Share(ParentId = sal.id, accessLevel = 'Read', UserOrGroupId = u2.id);
        insert sharingRec;*/
        List<Account_Team__c> accTeamList = new List<Account_Team__c>();
        accteam1 = TestUtils.createAccountTeam(acc.id, con.id, u1.id, 'Major Gifts Affiliate', false);
        accteam1.Grant_Edit_Access__c = false;
        accteam2 = TestUtils.createAccountTeam(acc.id, con.id, u2.id, 'Major Gifts Affiliate', false);
        accteam2.Grant_Edit_Access__c = false;
        accTeamList.add(accteam1);
        accTeamList.add(accteam2);
        accteam3 = TestUtils.createAccountTeam(acc.id, con.id, u3.id, 'Major Gifts Affiliate', false);
        accTeamList.add(accteam3);
        insert accTeamList;
        rC_Bios__Salutation__c sal = TestUtils.createSalutation(acc.id, true);
        /*rC_Bios__Salutation__Share sharingRec = new rC_Bios__Salutation__Share(ParentId = sal.id, accessLevel = 'Read', UserOrGroupId = u2.id);
        insert sharingRec;*/
    }
    
    @isTest
    private static void testAccessToAccoutnOBject(){
        Test.StartTest();
            //delete [select id from rC_Bios__Salutation__Share];
            acc = [Select id from Account];
	        con = [Select id from Contact];
	        u1 = [Select id from User where Lastname = 'xxxtest1'];
	        u2 = [Select id from User where Lastname = 'xxxtest2'];
	        u3 = [Select id from User where Lastname = 'xxxtest3'];
	        
	        Map<id, Set<Id>> userToAccountMap = new Map<id, Set<ID>>();
	        userToAccountMap.put(u1.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u2.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u3.id, new Set<Id>{acc.id});
            AccountTeamRecordAccessUtility.grantRWAccessToAccountRecord(userToAccountMap, new Set<Id>{acc.id}, true);
            System.assertEquals(3, [select id from Accountshare where UserOrGroupId =: u1.id OR UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id].size());
            AccountTeamRecordAccessUtility.grantReadORWriteAccessToRelatedObjects(userToAccountMap, new Set<Id>{acc.id}, true);
        Test.StopTest();
    }
    @isTest
    private static void grantRWAccessToRelatedRecord(){
        Test.StartTest();
            //delete [select id from rC_Bios__Salutation__Share];
            acc = [Select id from Account];
	        con = [Select id from Contact];
	        u1 = [Select id from User where Lastname = 'xxxtest1'];
	        u2 = [Select id from User where Lastname = 'xxxtest2'];
	        u3 = [Select id from User where Lastname = 'xxxtest3'];
	        
	        Map<id, Set<Id>> userToAccountMap = new Map<id, Set<ID>>();
	        userToAccountMap.put(u1.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u2.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u3.id, new Set<Id>{acc.id});
	        Schema.sObjectType salShare= Schema.rC_Bios__Salutation__Share.getSObjectType();
	        Schema.sObjectType sal= Schema.rC_Bios__Salutation__c.getSObjectType();
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccountMap, new Set<Id>{acc.id}, true, salShare, sal);
            System.assertEquals(3, [select id from rC_Bios__Salutation__Share where UserOrGroupId =: u1.id OR UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id].size());
        Test.StopTest();
    }
    
    @isTest
    private static void testAccessToAccoutnOBjectExistingShare(){
        Test.StartTest();
            //delete [select id from rC_Bios__Salutation__Share];
            acc = [Select id from Account];
            
	        con = [Select id from Contact];
	        u1 = [Select id from User where Lastname = 'xxxtest1'];
	        u2 = [Select id from User where Lastname = 'xxxtest2'];
	        u3 = [Select id from User where Lastname = 'xxxtest3'];
	        
	        AccountShare accShare = new AccountShare(AccountId = acc.id, UserOrGroupId = u1.id, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'Edit');
            insert accShare;
	        Map<id, Set<Id>> userToAccountMap = new Map<id, Set<ID>>();
	        userToAccountMap.put(u1.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u2.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u3.id, new Set<Id>{acc.id});
            AccountTeamRecordAccessUtility.grantRWAccessToAccountRecord(userToAccountMap, new Set<Id>{acc.id}, true);
            System.assertEquals(3, [select id from Accountshare where UserOrGroupId =: u1.id OR UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id].size());
        Test.StopTest();
    }
    @isTest
    private static void grantRWAccessToRelatedRecordExistingShare(){
        Test.StartTest();
            //delete [select id from rC_Bios__Salutation__Share];
            acc = [Select id from Account];
	        con = [Select id from Contact];
	        u1 = [Select id from User where Lastname = 'xxxtest1'];
	        u2 = [Select id from User where Lastname = 'xxxtest2'];
	        u3 = [Select id from User where Lastname = 'xxxtest3'];
	        rC_Bios__Salutation__c sal1 = [Select id from rC_Bios__Salutation__c LIMIT 1];
	        rC_Bios__Salutation__Share accShare = new rC_Bios__Salutation__Share(ParentId = sal1.id, UserOrGroupId = u1.id, accessLevel = 'Edit');
            insert accShare;
	        Map<id, Set<Id>> userToAccountMap = new Map<id, Set<ID>>();
	        userToAccountMap.put(u1.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u2.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u3.id, new Set<Id>{acc.id});
	        Schema.sObjectType salShare= Schema.rC_Bios__Salutation__Share.getSObjectType();
	        Schema.sObjectType sal= Schema.rC_Bios__Salutation__c.getSObjectType();
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccountMap, new Set<Id>{acc.id}, true, salShare, sal);
            System.assertEquals(3, [select id from rC_Bios__Salutation__Share where UserOrGroupId =: u1.id OR UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id].size());
        Test.StopTest();
    }
    
    @isTest
    private static void testRemoveAccess(){
        Test.StartTest();
            //delete [select id from rC_Bios__Salutation__Share];
            acc = [Select id from Account];
            
	        con = [Select id from Contact];
	        u1 = [Select id from User where Lastname = 'xxxtest1'];
	        u2 = [Select id from User where Lastname = 'xxxtest2'];
	        u3 = [Select id from User where Lastname = 'xxxtest3'];
	        
	        AccountShare accShare = new AccountShare(AccountId = acc.id, UserOrGroupId = u1.id, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'Edit');
            insert accShare;
	        Map<id, Set<Id>> userToAccountMap = new Map<id, Set<ID>>();
	        userToAccountMap.put(u1.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u2.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u3.id, new Set<Id>{acc.id});
	        
            AccountTeamRecordAccessUtility.grantRWAccessToAccountRecord(userToAccountMap, new Set<Id>{acc.id}, true);
            System.assertEquals(2, [select id from Accountshare where (UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id) AND AccountId =: acc.id].size());
            userToAccountMap.remove(u1.id);
            AccountTeamRecordAccessUtility.removeAccessToAccountRecord(userToAccountMap, new Set<Id>{acc.id});
            System.assertEquals(0, [select id from Accountshare where (UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id) AND AccountId =: acc.id].size());
            AccountTeamRecordAccessUtility.deleteRelatedSharingRecords(userToAccountMap, new Set<Id>{acc.id});
        Test.StopTest();
    }
    @isTest
    private static void RemoveAccessToRelatedRecord(){
        Test.StartTest();
            //delete [select id from rC_Bios__Salutation__Share];
            acc = [Select id from Account];
	        con = [Select id from Contact];
	        u1 = [Select id from User where Lastname = 'xxxtest1'];
	        u2 = [Select id from User where Lastname = 'xxxtest2'];
	        u3 = [Select id from User where Lastname = 'xxxtest3'];
	        rC_Bios__Salutation__c sal1 = [Select id from rC_Bios__Salutation__c LIMIT 1];
	        rC_Bios__Salutation__Share accShare = new rC_Bios__Salutation__Share(ParentId = sal1.id, UserOrGroupId = u1.id, accessLevel = 'Edit');
            insert accShare;
	        Map<id, Set<Id>> userToAccountMap = new Map<id, Set<ID>>();
	        userToAccountMap.put(u1.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u2.id, new Set<Id>{acc.id});
	        userToAccountMap.put(u3.id, new Set<Id>{acc.id});
	        Schema.sObjectType salShare= Schema.rC_Bios__Salutation__Share.getSObjectType();
	        Schema.sObjectType sal= Schema.rC_Bios__Salutation__c.getSObjectType();
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccountMap, new Set<Id>{acc.id}, true, salShare, sal);
            System.assertEquals(2, [select id from rC_Bios__Salutation__Share where (UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id) AND parentId =: sal1.id].size());
            userToAccountMap.remove(u1.id);
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccountMap, new Set<Id>{acc.id},  salShare, sal);
            System.assertEquals(0, [select id from rC_Bios__Salutation__Share where (UserOrGroupId =: u2.id OR UserOrGroupId =: u3.id) AND parentId =: sal1.id].size());
        Test.StopTest();
    }
}