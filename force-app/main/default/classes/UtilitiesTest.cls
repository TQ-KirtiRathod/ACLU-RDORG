@isTest
private class UtilitiesTest {
    private static testMethod void testUtilities(){
        boolean canUseFutureContext = Utilities.CanUseFutureContext();
        System.assertEquals(true,canUseFutureContext);
        
        User sfdcUser = createUser('SFDC');
        integer totalFutureCallsAllowed = Utilities.getMaxFutureCallsAllowed();
       // System.assertEquals(250000,totalFutureCallsAllowed);
        Date d = Date.newInstance(2018, 7, 12);
        String year = Utilities.getFiscalYearFromDate(d);
        System.assertEquals('2019',year);
        
        year = Utilities.getFiscalYearFromDate(d.addMonths(-5));
        System.assertEquals('2018',year);
        
        Integer lastDayFutureCalls = Utilities.GetNumFutureCallsInLast24Hours();
        system.assertEquals(0, lastDayFutureCalls);
        
        List<String> depositeSites = Utilities.getDepositSiteSet('test');
        system.assertEquals(1, depositeSites.size()); 
    }
    
    private static User createUser(String licence){
        User testUser = new User();
        Profile p = [SELECT Id FROM Profile WHERE UserLicense.LicenseDefinitionKey =: licence][0];
        testUser.ProfileId = p.id;
        testUser.FirstName = 'testUser';
        testUser.LastName = licence;
        testUser.Username = 'testUser' + '@email.com'+'.random1';
        testUser.Email = 'testUser' + '@testorg.com';
        testUser.Alias = 'testUser';
        testUser.CommunityNickname = 'testUser';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        //testUser.IsActive = true;
        testUser.Department = 'Executive/Admin';
        return testUser;
    }
    
    /*
    * Author : Aashita Sharma
    * Purpose : to cover method CalculateCheckDigit
    * Date : 17th Jan 2018
    */
    private static testMethod void testCalculateCheckDigit() {
        User sfdcUser = createUser('SFDC');
        String autoAccountNumber;
        String overrideAccountNumber;
        autoAccountNumber = '10001001';
        overrideAccountNumber = String.valueOf(Utilities.calculateCheckDigit(autoAccountNumber));
        system.assertEquals(overrideAccountNumber, '100010016');
    }

    private static testMethod void testGetType() {
        Object o;
        Object accountx = new Account();
        Object b = true;
        Object idx = Id.valueOf('001000000000000');
        Object str = 'string';
        Object bl = Blob.valueOf(String.valueOf(str));
        Object d = Date.today();
        Object dt = Datetime.now();
        Object t = Time.newInstance(0, 0, 0, 0);
        Object intg = 2;
        Object l = Long.valueOf('3444444');
        Object dec = 1.25;
        Object listx = new List<Object>();
        Object mapx = new Map<Object,Object>();
        system.AssertEquals('',Utilities.getType(o));
        system.AssertEquals('Account',Utilities.getType(accountx));
        system.AssertEquals('Boolean',Utilities.getType(b));
        system.AssertEquals('Id',Utilities.getType(idx));
        system.AssertEquals('String',Utilities.getType(str));
        system.AssertEquals('Blob',Utilities.getType(bl));
        system.AssertEquals('Date',Utilities.getType(d));
        system.AssertEquals('Datetime',Utilities.getType(dt));
        system.AssertEquals('Time',Utilities.getType(t));
        system.AssertEquals('Integer',Utilities.getType(intg));
        system.AssertEquals('Long',Utilities.getType(l));
        system.AssertEquals('Decimal',Utilities.getType(dec));
        system.AssertEquals('List',Utilities.getType(listx));
        system.AssertEquals('Object',Utilities.getType(mapx));
    }

    /*
    * Author : Anne-Lise Millereux
    * Purpose : to cover method getPickListOptions
    * Date : July 11th, 2019
    */
    private static testMethod void testgetPickListOptions() {
        Test.startTest();
            List<String> deceasedDay = Utilities.getPickListOptions('Contact', 'rC_Bios__Deceased_Day__c');
        Test.stopTest();
        System.assertNotEquals(deceasedDay.size(), 0, 'DeceasedDay Should contains the picklist values available for Deceased Day field from Contact.');
    }

    /*
    * Author : Anne-Lise Millereux
    * Purpose : to cover method GetFieldsHelpText
    * Date : July 11th, 2019
    */
    private static testMethod void testGetFieldsHelpText() {
        Test.startTest();
            List<String> fieldToGetHelpText = new List<String>{'rc_bios__deceased_day__c','rc_bios__deceased_month__c','rc_bios__deceased_year__c'};
            Map<String, String> helperText = Utilities.getFieldsHelpText('Contact', fieldToGetHelpText);

        Test.stopTest();

        System.assertEquals(helperText.size(), 3);
        System.assertEquals(true, helperText.containsKey('rc_bios__deceased_day__c'));
    }
    
    private static testMethod void getIsDepositSiteSameAsAffiliate() {
        Account acct = TestUtils.createAccount('Test Account', true);
        Opportunity opp = TestUtils.createOpportunity(acct.Id, 'Test Opportunity',false);
        opp.Deposit_Site__c = 'CD_SanDiegoCal';
        insert opp;
        
        Boolean isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(opp, new List<String>{'test'}, 'test Site');
        
        System.assertEquals(false, isDepositSiteSameAsAffiliate);
    }


    /*
    * Author : Dave Seidman
    * Purpose : to cover method getQueryOfAllFields
    * Date : 2019-08-06
    */
    private static testMethod void testgetQueryOfAllFields() {
        Account acct = TestUtils.createAccount('Test Account', true);
        List<Account> accts;

        Contact con = TestUtils.createContact(acct, 'Test', 'Test', true);
        List<Contact> cons;
        
        // Test contacts because it has been problembatic with regard to not include fields
        // like MiddleName, InformalName
        Test.startTest();
           String query1 = Utilities.getQueryOfAllFields('Contact');
           cons = Database.Query(query1);
           String query2 = Utilities.getQueryOfAllFields('Account');
           accts = Database.Query(query2);
        Test.stopTest();

        System.assertEquals(accts.size(), 1);
    }

    /*
    * Author : Dave Seidman
    * Purpose : to cover method getObjectPrefix
    * Date : 2019-08-06
    */
    private static testMethod void testGetObjectPrefix() {
        System.assertEquals('001', Utilities.getObjectPrefix('Account'));
    }

    /*
    * Author : Dave Seidman
    * Purpose : to cover method stripNonNumeric
    * Date : 2019-08-13
    */
    private static testMethod void testStripNonNumeric() {
        String a = '1-919-555-5555';
        String b = '(1) 919.555.5555';
        String c = '19195555555ext';
        String numericOnly = '19195555555';
        system.assertEquals(numericOnly,Utilities.stripNonNumeric(a));
        system.assertEquals(numericOnly,Utilities.stripNonNumeric(b));
        system.assertEquals(numericOnly,Utilities.stripNonNumeric(c));
    }
}