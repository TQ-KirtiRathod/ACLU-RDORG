/***********************************************************************************************************
 * Name         : TestUtilsTest
 * Created By   : Dave Seidman
 * Purpose      : Rudimentary code coverage for TestUtils when TestUtils is occasionally updated and code
 *                coverage proof is desired without running all test classes
 * Created Date : July 29, 2019
 *
 **********************************************************************************************************/

@isTest
public with sharing class TestUtilsTest {

    public static UserRole r;
    public static String t = 'TEST';
    public static Date d1 = Date.newInstance(2019, 1, 1);
    public static Date d2 = Date.newInstance(2019, 12, 31);
    public static Account acct;
    public static Contact con;
    public static Opportunity opp;

    static testMethod void testUtilMethods1() {
      //  r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
      //  insert r;

      //  User usr = [Select id from User where Id = :UserInfo.getUserId()];

     //   System.RunAs(usr) {
       //     Test.startTest();
         //   runTest();
          //  Test.stopTest();
     //   }
    }

    static void runSetupTest() {
        acct = TestUtils.createAccount(t, true);
        con = TestUtils.createContact(acct, t,t, true);
        opp = TestUtils.createOpportunity(acct.Id, t, true);
    }

   // @future
    static testMethod void runTests1() {
        runSetupTest();

        List<Account> A = TestUtils.createAccounts(false);
        A = TestUtils.createAccounts(2,false);
        Contact con2 = TestUtils.createContact(acct, t,t, true);
        Email__c e = TestUtils.createEmail(con.Id, 't@example.com', true);
        Phone__c ph = TestUtils.createPhone(con.Id, '5555555555', true);

        Email_Preference_List__c epl = TestUtils.createEmailPrefList(t, 'NY', false, true, t, t, true);
        Email_Preference__c ep = TestUtils.createEmailPreference(e.Id, 'NY', false, true);

        rC_Connect__Batch_Upload__c bup = TestUtils.createBatchUpload(t,t,con.id,'t@example.com',true);
        rC_Bios__Preference__c pref = TestUtils.createPreferences(acct.Id, true);
        pref = TestUtils.createPreferences(acct.Id, t, t, d1, d2, true);
        TestUtils.createPreferenceCodes();
        pref = TestUtils.createPreferencesUsingContact(con.Id, true);

        rC_Bios__Relationship__c rel = TestUtils.createRelationShip(A[0].Id, A[1].Id, true);
        rC_Bios__Relationship__c rel2 = TestUtils.createRelationShipUsingContact(con.Id, con2.Id, true);
        rc_Bios__Relationship__c rel3 = TestUtils.createRelationShipUsingOpportunity(opp.Id, acct.Id, false);
        rC_Giving__Payment_Method__c pm = TestUtils.createPaymentMethod(acct.Id, true);
        rC_Bios__Salutation__c sal1 = TestUtils.createSalutation(acct.Id, true);
        rC_Bios__Salutation__c sal2 = TestUtils.createSalutationUsingContact(con.Id, true);
        rC_Giving__Planned_Giving__c pg = TestUtils.createPlannedGiving(A[0].Id, A[1].Id, true);
    }

        static testMethod void runTests2() {
            runSetupTest();

            rC_Bios__Action_Plan__c ap1 = TestUtils.createActionPlan(acct.Id, true);
            rC_Bios__Action_Plan__c ap2 = TestUtils.createBiosActionPlan(acct.Id, true);
            rC_Bios__Action_Plan__c ap3 = TestUtils.createActionPlanUsingContact(con.Id, true);
            
            Prospect_Research__c pr = TestUtils.createProspectResearch(con.Id, true);
            Confidential_Data__c cd = TestUtils.createConfidentialData(acct.Id, con.Id, opp.Id, true);

            rC_Bios__Address__c addr = TestUtils.createAddress (t, true);
            rC_Bios__Account_Address__c aAddr = TestUtils.createAccountAddress (addr.Id, acct.Id, true);
            rC_Bios__Contact_Address__c cAddr = TestUtils.createContactAddress (addr.Id, con.Id, true);
            
            rC_Giving__Opportunity_Credit__c oc = testUtils.createOpportunityCredits(opp.Id, 'donation', 4, t, false);
            
            Zip_Affiliate__c za = TestUtils.createZipAffiliate(t, false);
            Batch_Log__c bl = TestUtils.batchLog(t, false);

            Attachment att = TestUtils.createAttachment(t, acct.Id, t, true);
            Product2 prod2 = TestUtils.createProduct(t, true, true);
            Pricebook2 pb2 = TestUtils.createPriceBook(t, true);
            PricebookEntry pbe = TestUtils.createPriceBookEntry(prod2.Id, true);
            OpportunityLineItem oli = TestUtils.createOpportunityLineItem(opp.Id, pbe.Id, false);
            Campaign camp = TestUtils.createCampaign(t, true);
            Lead l = TestUtils.createLead(t, t, 'Active', true);
            CampaignMember cm = TestUtils.createCampaignMember(camp.Id, l.Id, true);
        }

        static testMethod void runTests3() {
           r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
           insert r;
           User u = TestUtils.createUser(t, 't@example.com', r.Id, true);   
           User u2 = TestUtils.createSysAdminUser('System Administrator'); 
                       Group gr = TestUtils.createGroup(t,true);

           Groupmember gm = TestUtils.createGroupmember(u.Id, gr.Id, true);
        }

        static testMethod void runTests4() {
            runSetupTest();
            User u = [Select Id from User where Id = :System.UserInfo.getUserId()];

            acct = [Select Id from Account LIMIT 1];
            AccountTeamMember atm = TestUtils.createAccountTeamMember(u.Id, acct.Id, true);
            TriggerSettings__c ts = TestUtils.createTriggerSettings(t, true);
            
            National_Fiscal_Year__c nfy = TestUtils.createFiscalyearCSData(t, '2020', 1, 1, 1, true);
            // ERROR // Affiliate_Yearly__c ay = TestUtils.createAffiliateYearly(t, acct.Id, '2020', true);
            // ERROR // Income_Type_Distribution__c itd = TestUtils.createIncomeTypeDistribution(ay.Id, t, 1, false);

            Batch_Log__c bl = TestUtils.createBatchLog(t, true);
            Batch_Log_Summary__c bls = TestUtils.createBatchLogSummary(t, true);
            List<National_Budget__c> nbs = TestUtils.createListNationalBudget(1);
            List<Prospect_Research__c> prs = TestUtils.createProspectResearchList(1);
            List<Group> groups = TestUtils.createGroupList(1);
            Portfolio__c port = TestUtils.createPortfolio(t, true);

        }

}