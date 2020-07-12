@isTest
private class AccountFieldPopulate_BatchTest {
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
	private static testMethod void test() {
        Test.StartTest();
            acc = [Select id from Account];
            con = [Select id from Contact];
            u1 = [Select id from User where Lastname = 'xxxtest1'];
            u2 = [Select id from User where Lastname = 'xxxtest2'];
            List<Account_Team__c> accTeamList = new List<Account_Team__c>();
            accteam1 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u1.id, 'Major Gifts Affiliate', false);
            accteam1.Grant_Edit_Access__c = false;
            accteam1.Status__c = 'Current';
            accteam2 = AccountTeamRecordAccessUtility.createAccountTeam(acc.id, con.id, u2.id, 'Primary Relationship Manager', false);
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
            update new Account(Id = acc.id, National_MG__c =null, Affiliate_MG__c= null, National_LG__c=null ,Affiliate_LG__c=null ,Account_PRM__c=null);
            Database.executeBatch(new AccountFieldPopulate_Batch(), 200);
        Test.stopTest();
	}

}