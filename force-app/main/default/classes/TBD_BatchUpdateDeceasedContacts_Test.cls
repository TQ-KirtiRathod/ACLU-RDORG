@isTest
private class TBD_BatchUpdateDeceasedContacts_Test {

	private static testMethod void testTBD_BatchUpdateDeceasedContacts() {
        Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

        insert a;
        
        List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                              new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id, 
                                                          rC_Bios__Deceased__c = true, rC_Bios__Secondary_Contact__c = true) };

        insert cs;
       
        Database.executeBatch(new TBD_BatchUpdateDeceasedContacts('Secondary'), 50);
        Database.executeBatch(new TBD_BatchUpdateDeceasedContacts('Primary'), 50);
        Database.executeBatch(new TBD_BatchUpdateDeceasedContacts('All'), 50);
        Set<Id> ids = new Set<Id>{cs[0].id};
        TBD_BatchUpdateDeceasedContacts bud = new TBD_BatchUpdateDeceasedContacts(ids);
        Database.executeBatch(bud, 50);

	}

}