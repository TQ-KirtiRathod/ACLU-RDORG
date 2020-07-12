/*
*
*Name  :  AccountTeamHandlerTest
*Author:  Appirio India (Bhavesh)
*Date  :  Nov 6, 2017
*Purpose : test Class for AccountTeamHandler
*/
@isTest
private class AccountTeamHandlerTest {
    static Account acc;
    static Contact con;
    static User u1, u2;
    static Account_Team__c accteam1, accteam2, accteam3, accteam4;
    
    @testSetup
    private static void createAccoumeTeam(){
        acc = TestUtils.createAccount('Test Account', true);
        rC_Bios__Salutation__c sal = TestUtils.createSalutation(acc.id, true);
        
        con = TestUtils.createContact(acc, 'Test', 'Contact', true);
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Marketing User' LIMIT 1];
        List<User> userList = new List<User>();
        u1 = TestUtils.createUser('xxxtest1','test1@aclu.org', null, false);
        u1.ProfileId = p.id;
        userList.add(u1);
        u2 = TestUtils.createUser('xxxtest2','test12@aclu.org', null, false);
        u2.ProfileId = p.id;
        userList.add(u2);
        User u3 = TestUtils.createUser('xxxtest3','test13@aclu.org', null, false);
        u3.ProfileId = p.id;
        userList.add(u3);
        insert userList;    
        rC_Bios__Salutation__Share sharingRec = new rC_Bios__Salutation__Share(ParentId = sal.id, accessLevel = 'Read', UserOrGroupId = u2.id);
        insert sharingRec;
        Account_Team__c at3 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u3.id, 'Major Gifts Affiliate', true);
    }
    
    private static testMethod void testAfterInsertTrigger(){
        Test.StartTest();
            acc = [Select id from Account];
            con = [Select id from Contact];
            u1 = [Select id from User where Lastname = 'xxxtest1'];
            u2 = [Select id from User where Lastname = 'xxxtest2'];
            List<Account_Team__c> accTeamList = new List<Account_Team__c>();
            accteam1 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u1.id, 'Major Gifts Affiliate', false);
            accteam1.Grant_Edit_Access__c = false;
            accteam1.Status__c = 'Current';
            accteam2 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u2.id, 'Major Gifts National', false);
            accteam2.Grant_Edit_Access__c = false;
            accteam2.Status__c = 'Current';
            accteam3 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u1.id, 'Leadership Gifts Affiliate', false);
            accteam3.Grant_Edit_Access__c = false;
            accteam3.Status__c = 'Current';
            accteam4 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u2.id, 'Leadership Gifts National', false);
            accteam4.Grant_Edit_Access__c = false;
            accteam4.Status__c = 'Current';
            accTeamList.add(accteam1);
            accTeamList.add(accteam2);
            accTeamList.add(accteam3);
        	accTeamList.add(accteam4);
            insert accTeamList;
            
            Account_Team__c accTeam = [Select Id, Team_Member_Name__c From Account_team__c Where Id =: accteam1.id];
            Account acc = [Select Id, affiliate_LG__c, National_LG__c, Affiliate_MG__c, National_MG__c From Account Where id =: acc.Id];
            String affMG = acc.Affiliate_MG__c;
            System.assert(affMG != Null );
            System.assert(true, affMG.indexOf(accTeam.Team_Member_Name__c) != -1 );
            Delete accteam1; 
            String affMG1 = [Select Id, Affiliate_MG__c From Account Where id =: acc.Id].Affiliate_MG__c;
            System.assertEquals(true, affMG1 != affMG);
            
            Account_Team__c accTeam2 = [Select Id, Team_Member_Name__c From Account_team__c Where Id =: accteam2.id];
            String natMG = acc.National_MG__c;
            System.assert(natMG != Null );
            System.assert(true, natMG.indexOf(accTeam.Team_Member_Name__c) != -1 );
            
            Account_Team__c accTeam3 = [Select Id, Team_Member_Name__c From Account_team__c Where Id =: accteam3.id];
            String affLG = acc.affiliate_LG__c;
            System.assert(affLG != Null );
            System.assert(true, affLG.indexOf(accTeam.Team_Member_Name__c) != -1 );
            
            Account_Team__c accTeam4 = [Select Id, Team_Member_Name__c From Account_team__c Where Id =: accteam4.id];
            String natLG = acc.national_LG__c;
            System.assert(natLG != Null );
            System.assert(true, natLG.indexOf(accTeam.Team_Member_Name__c) != -1 );
        Test.stopTest();
            
    }
    
    
    
    private static testMethod void testUpdateTeamMember(){
        Test.StartTest();
            acc = [Select id from Account];
            con = [Select id from Contact];
            u1 = [Select id from User where Lastname = 'xxxtest1'];
            u2 = [Select id from User where Lastname = 'xxxtest2'];
            List<Account_Team__c> accTeamList = new List<Account_Team__c>();
            accteam1 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u1.id, 'Major Gifts Affiliate', false);
            accteam1.Grant_Edit_Access__c = true;
            accteam2 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u2.id, 'Major Gifts Affiliate', false);
            accteam2.Grant_Edit_Access__c = false;
            accTeamList.add(accteam1);
            accTeamList.add(accteam2);
            insert accTeamList;
            accteam1.Grant_Edit_Access__c = false;
            update accteam1;
        Test.stopTest();
        system.assertEquals(3, [SELECT Id FROM Account_Team__c].size());
        system.assertEquals(3, [SELECT Id from AccountShare].size());
    }
    
    private static testMethod void testAfterDeleteTrigger(){
        Test.StartTest();
            delete [Select id from Account_Team__c LIMIT 1];
            acc = [Select id from Account];
            u1 = [Select id from User where Lastname = 'xxxtest3'];
        Test.stopTest();
        system.assertEquals(0, [SELECT Id, Team_Member__c, Team_Role__c, Team_Member_Name__c FROM Account_Team__c].size());
        system.assertEquals(3, [SELECT Id,UserOrGroupId from AccountShare].size());
    }

}