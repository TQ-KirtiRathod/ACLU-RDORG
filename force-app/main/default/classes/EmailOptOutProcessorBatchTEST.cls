@isTest
private class EmailOptOutProcessorBatchTEST {

    private static void disableEmailTrigger() {
        insert new TriggerSettings__c(Name = 'Email_Trigger', IsActive__c = false, IsTestMode__c = false);
    }
	
	@isTest static void testOptOutBatchSimple() {
        // Disable trigger so it doesn't affect our test data.
        disableEmailTrigger(); 

        List<Contact> cs = new List<Contact>{
            new Contact(FirstName='Test', LastName='Testerson'),
            new Contact(FirstName='Testy', LastName='McTest'),
            new Contact(FirstName='Foo', LastName='Bar'),
            new Contact(FirstName='Perikles', LastName='son of Xanthippos')
        };
        
        insert cs;

        List<Email__c> ems = new List<Email__c> {
            new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[2].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[3].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@devnull.com', Opt_in__c = true, Primary__c = false)
        };

        insert ems;

        // Set the Status Changed flag manually - we can't re-enable the trigger in the same transaction due to design of
        // TriggerState class.
        ems[0].Opt_in__c = false;
        ems[0].Opt_In_Status_Changed__c = true;
        update ems[0];

        Test.startTest();
        Database.executeBatch(new EmailOptOutProcessorBatch(), 200);
        Test.stopTest();

        System.assertEquals(4, [SELECT count() FROM Email__c WHERE Email_address__c = 'test@example.com' AND Opt_in__c = false]);
        System.assertEquals(1, [SELECT count() FROM Email__c WHERE Email_address__c = 'test@devnull.com' AND Opt_in__c = true]);
        System.assertEquals(0, [SELECT count() FROM Email__c WHERE Opt_In_Status_Changed__c = true]);
	}

    @isTest static void testOptOutBatchMultiple() {
        // Disable trigger so it doesn't affect our test data.
        disableEmailTrigger();

        List<Contact> cs = new List<Contact>{
            new Contact(FirstName='Test', LastName='Testerson'),
            new Contact(FirstName='Testy', LastName='McTest'),
            new Contact(FirstName='Foo', LastName='Bar'),
            new Contact(FirstName='Perikles', LastName='son of Xanthippos')
        };
        
        insert cs;

        List<Email__c> ems = new List<Email__c> {
            new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[2].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[3].Id, Email_address__c = 'test@devnull.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@devnull.com', Opt_in__c = true, Primary__c = false)
        };

        insert ems;

        // Set the Status Changed flag manually - we can't re-enable the trigger in the same transaction due to design of
        // TriggerState class.
        ems[0].Opt_in__c = false;
        ems[0].Opt_In_Status_Changed__c = true;
        update ems[0];

        ems[4].Opt_in__c = false;
        ems[4].Opt_In_Status_Changed__c = true;
        update ems[4];

        Test.startTest();
        Database.executeBatch(new EmailOptOutProcessorBatch(), 200);
        Test.stopTest();

        System.assertEquals(3, [SELECT count() FROM Email__c WHERE Email_address__c = 'test@example.com' AND Opt_in__c = false]);
        System.assertEquals(2, [SELECT count() FROM Email__c WHERE Email_address__c = 'test@devnull.com' AND Opt_in__c = false]);
        System.assertEquals(0, [SELECT count() FROM Email__c WHERE Opt_In_Status_Changed__c = true]);
    }

    @isTest static void testOptOutBatchConflictingChanges() {
        // Disable trigger so it doesn't affect our test data.
        disableEmailTrigger();

        List<Contact> cs = new List<Contact>{
            new Contact(FirstName='Test', LastName='Testerson'),
            new Contact(FirstName='Testy', LastName='McTest'),
            new Contact(FirstName='Thucydides', LastName='son of Oloros'),
            new Contact(FirstName='Perikles', LastName='son of Xanthippos')
        };
        
        insert cs;

        List<Email__c> ems = new List<Email__c> {
            new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[2].Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true),
            new Email__c(Contact__c = cs[3].Id, Email_address__c = 'test@example.com', Opt_in__c = false, Primary__c = true),
            new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@devnull.com', Opt_in__c = true, Primary__c = false)
        };

        insert ems;

        // Insert conflicting changes. They should be applied to matching emails in order, so the opt in = true should win.
        // Set the Status Changed flag manually - we can't re-enable the trigger in the same transaction due to design of
        // TriggerState class.
        ems[0].Opt_in__c = false;
        ems[0].Opt_In_Status_Changed__c = true;
        update ems[0];
        
        ems[3].Opt_in__c = true;
        ems[3].Opt_In_Status_Changed__c = true;
        update ems[3];
        
        // Call through the handler class directly - we can't modify the SystemModStamp here.
        EmailOptOutProcessor.processOptOutsForEmails(new List<Email__c>{ems[0], ems[3]});
		
        System.assertEquals(4, [SELECT count() FROM Email__c WHERE Email_address__c = 'test@example.com' AND Opt_in__c = true]);
        System.assertEquals(1, [SELECT count() FROM Email__c WHERE Email_address__c = 'test@devnull.com' AND Opt_in__c = true]);
        System.assertEquals(0, [SELECT count() FROM Email__c WHERE Opt_In_Status_Changed__c = true]);
    }	
}