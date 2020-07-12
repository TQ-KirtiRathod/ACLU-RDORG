@isTest
public class AccountAsyncProcessorTEST {
    @testSetup
    public static void setupCustomSettings() {
        List<Email_Preference_List__c> epls;

        epls = new List<Email_Preference_List__c>{
            new Email_Preference_List__c(Name = 'NY', Affiliation__c = 'NY', List_Code__c = 'NY', Is_Home_Affiliate_List__c = true),
            new Email_Preference_List__c(Name = 'TX', Affiliation__c = 'TX', List_Code__c = 'TX', Is_Home_Affiliate_List__c = true),
            new Email_Preference_List__c(Name = 'CA', Affiliation__c = 'CS', List_Code__c = 'CA', Is_Home_Affiliate_List__c = true),
            new Email_Preference_List__c(Name = 'CA2', Affiliation__c = 'CS', List_Code__c = 'CS', Is_Home_Affiliate_List__c = true),
            new Email_Preference_List__c(Name = 'CD', Affiliation__c = 'CD', List_Code__c = 'CA', Is_Home_Affiliate_List__c = true),
            new Email_Preference_List__c(Name = 'CD2', Affiliation__c = 'CD', List_Code__c = 'CD', Is_Home_Affiliate_List__c = true)
        };

        insert epls;
    } 

    public static TestMethod void testEmailPreferencesOnMoveNullCase() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

        a.Affiliation__c = 'TX';

        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'TX');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        System.assertEquals(0, [SELECT count() FROM Email_Preference__c]);
    }

    public static TestMethod void testEmailPreferencesOnMoveNullToAffiliation() {
        Account a = new Account(Name = 'Test', Affiliation__c = null, Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

        a.Affiliation__c = 'TX';

        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'TX');
        oldAffiliationMap.put(a.Id, null);

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        System.assertEquals(0, [SELECT count() FROM Email_Preference__c]);
    }

    public static TestMethod void testEmailPreferencesOnMoveAffiliationToNull() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

        a.Affiliation__c = null;

        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, null);
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        System.assertEquals(0, [SELECT count() FROM Email_Preference__c]);
    }

    public static TestMethod void testEmailPreferencesOnMoveNoExisting() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

         // Contact 0 will have email preferences for the old affiliation on both their email addresses.
         // Contact 1 will not.

         List<Email_Preference__c> eps = new List<Email_Preference__c>{ 
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'NY', opt_In__c = true),
            new Email_Preference__c(Email__c = ems[1].Id, Email_List_Code__c = 'NY', opt_In__c = true)
         };

         insert eps;

        // Move to Texas. We should see Contact 0 get a single new email preference on their primary email address for Texas, and no other changes.
        a.Affiliation__c = 'TX';
        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'TX');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        // Verify that the original email preferences are unchanged, and a single new one is added.
        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c];

        System.assertEquals(3, eps.size());

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'NY'];

        System.assertEquals(2, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assert(eps[1].Opt_In__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'TX'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assertEquals(ems[0].Id, eps[0].Email__c);
    }

      public static TestMethod void testEmailPreferencesOnMoveExistingOptedOut() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

         // Contact 0 will have email preferences for the old affiliation on both their email addresses.
         // Contact 1 will not.
         // In this scenario, Contact 0 is opted out.

        List<Email_Preference__c> eps = new List<Email_Preference__c>{ 
          new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'NY', opt_In__c = false),
          new Email_Preference__c(Email__c = ems[1].Id, Email_List_Code__c = 'NY', opt_In__c = false)
        };

        insert eps;

        // Move to Texas. We should see Contact 0 get no changes.
        a.Affiliation__c = 'TX';
        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'TX');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        // Verify that the original email preferences are unchanged, and none are added.
        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c];

        System.assertEquals(2, eps.size());

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'NY'];

        System.assertEquals(2, eps.size());
        System.assert(!eps[0].Opt_In__c);
        System.assert(!eps[1].Opt_In__c);
    }

    public static TestMethod void testEmailPreferencesOnMoveCurrentOptedOut() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

         // Contact 0 will have email preferences for the new affiliation on both their email addresses.
         // Contact 1 will not.
         // In this scenario, Contact 0 is opted out.

        List<Email_Preference__c> eps = new List<Email_Preference__c>{ 
          new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'TX', opt_In__c = false),
          new Email_Preference__c(Email__c = ems[1].Id, Email_List_Code__c = 'TX', opt_In__c = false)
        };

        insert eps;

        // Move to Texas. We should see Contact 0 get no changes.
        a.Affiliation__c = 'TX';
        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'TX');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        // Verify that the original email preferences are unchanged, and none are added.
        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c];

        System.assertEquals(2, eps.size());

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'TX'];

        System.assertEquals(2, eps.size());
        System.assert(!eps[0].Opt_In__c);
        System.assert(!eps[1].Opt_In__c);
    }

    public static TestMethod void testEmailPreferencesOnMoveExistingAndNew() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

         // Contact 0 will have email preferences for the old AND new affiliation.
         // Contact 1 will not.
         // In this scenario, Contact 0 is opted out.

        List<Email_Preference__c> eps = new List<Email_Preference__c>{ 
          new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'NY', opt_In__c = true),
          new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'TX', opt_In__c = true)
        };

        insert eps;

        // Move to Texas. We should see Contact 0 get no changes.
        a.Affiliation__c = 'TX';
        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'TX');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        // Verify that the original email preferences are unchanged, and none are added.
        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c];

        System.assertEquals(2, eps.size());

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'NY'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'TX'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);
    }


    public static TestMethod void testEmailPreferencesOnMoveWithUpsert() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

         // Contact 0 will have email preferences for the old affiliation on both their email addresses.
         // Contact 1 will not.
         // In this scenario, Contact 0 has an additional opted-out email preference for their new affiliation, which we will upsert.

         List<Email_Preference__c> eps = new List<Email_Preference__c>{ 
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'NY', opt_In__c = true),
            new Email_Preference__c(Email__c = ems[1].Id, Email_List_Code__c = 'NY', opt_In__c = true),
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'CS', opt_In__c = false),
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'CA', opt_In__c = false)
         };

         insert eps;

        // Move to California. Both California codes should be upserted to opt-in.
        a.Affiliation__c = 'CS';
        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'CS');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        // Verify that the original email preferences are unchanged, and a single new one is added.
        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c];

        System.assertEquals(4, eps.size());

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'NY'];

        System.assertEquals(2, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assert(eps[1].Opt_In__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'CA'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assertEquals(ems[0].Id, eps[0].Email__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'CS'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assertEquals(ems[0].Id, eps[0].Email__c);
    }

    public static TestMethod void testEmailPreferencesOnMoveWithPartialUpsert() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;

        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };

        insert cs;

        List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                 new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };

        insert ems;

         // Contact 0 will have email preferences for the old affiliation on both their email addresses.
         // Contact 1 will not.
         // In this scenario, Contact 0 has an additional opted-out email preference for their new affiliation, which we will upsert.

         List<Email_Preference__c> eps = new List<Email_Preference__c>{ 
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'NY', opt_In__c = true),
            new Email_Preference__c(Email__c = ems[1].Id, Email_List_Code__c = 'NY', opt_In__c = true),
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'CS', opt_In__c = false),
            new Email_Preference__c(Email__c = ems[0].Id, Email_List_Code__c = 'CA', opt_In__c = false)
         };

         insert eps;

        // Move to California - San Diego. CA should be upserted to opt-in and a new code for CD should be added. CS should stay opted out.
        a.Affiliation__c = 'CD';
        update a;

        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        newAffiliationMap.put(a.Id, 'CD');
        oldAffiliationMap.put(a.Id, 'NY');

        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();

        // Verify that the correct total count of email preferences are present.
        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c];

        System.assertEquals(5, eps.size());

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'NY'];

        System.assertEquals(2, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assert(eps[1].Opt_In__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'CA'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assertEquals(ems[0].Id, eps[0].Email__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'CS'];

        System.assertEquals(1, eps.size());
        System.assert(!eps[0].Opt_In__c);
        System.assertEquals(ems[0].Id, eps[0].Email__c);

        eps = [SELECT Email__c, Email__r.Contact__c, Email_List_Code__c, opt_In__c 
               FROM Email_Preference__c 
               WHERE Email_List_Code__c = 'CD'];

        System.assertEquals(1, eps.size());
        System.assert(eps[0].Opt_In__c);
        System.assertEquals(ems[0].Id, eps[0].Email__c);

    }

    public static TestMethod void testEmailPreferencesOnMoveBulk() {
        List<Account> acts = new List<Account>();
        Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
        Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();

        for (Integer i = 0; i < 15; i++) {
            acts.add(new Account(Name = 'Test ' + String.valueOf(i), Affiliation__c = 'NY', Lock_Affiliation__c = true));
        }

        insert acts;
        For (Account a : acts) {
            oldAffiliationMap.put(a.Id, 'NY');
        }

        List<Contact> cs = new List<Contact>();

        for (Integer i = 0; i < 15; i++) {
            cs.add(new Contact(FirstName = 'Testy ' + String.valueOf(i), LastName = 'Testerson', AccountId = acts[i].Id));
        }

        insert cs;
        List<Email__c> ems = new List<Email__c>();

        for (Integer i = 0; i < 15; i++) {
            ems.add(new Email__c(Contact__c = cs[i].Id, Email_address__c = 'test'+String.valueof(i)+'@test.com', Opt_In__c = true, Primary__c = true));
        }

        insert ems;
        
        List<Email_Preference__c> eps = new List<Email_Preference__c>();
        for (Integer i = 0; i < 15; i++) {
            eps.add(new Email_Preference__c(Email__c = ems[i].Id, Email_List_Code__c = 'NY', opt_In__c = true));
        }

        insert eps;
        for (Account a : acts) {
            a.Affiliation__c = 'TX';
            newAffiliationMap.put(a.Id, 'TX');
        }

        update acts;
        List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };

        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(l));

        AccountAsyncProcessor aap = new AccountAsyncProcessor(ar);

        aap.account_AffiliationChange();
        System.assertEquals(15, [SELECT count() 
                                   FROM Email_Preference__c 
                                   WHERE Email_List_Code__c = 'TX' AND opt_In__c = true]);

        System.assertEquals(15, [SELECT count() 
                                   FROM Email_Preference__c 
                                   WHERE Email_List_Code__c = 'NY' AND opt_In__c = true]);
    }

}