@isTest
private class EmailPreferenceOptOutProcessorBatchTEST {
    private static void disableEmailPreferenceTrigger() {
        insert new TriggerSettings__c(Name = 'Email_Preference_Trigger', IsActive__c = false, IsTestMode__c = false);
    }

    private static void disableEmailTrigger() {
        insert new TriggerSettings__c(Name = 'Email_Trigger', IsActive__c = false, IsTestMode__c = false);
    }

    @isTest static void testOptOutBatchSimple() {
        // Disable triggers so they don't affect our test data.
        disableEmailPreferenceTrigger();
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

        List<Email_Preference__c> eps = new List<Email_Preference__c>{
            new Email_Preference__c(Email__c = ems[0].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[1].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[2].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[3].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[0].Id, Opt_in__c = true, Email_List_Code__c = 'MemberNational'),
            new Email_Preference__c(Email__c = ems[4].Id, Opt_in__c = true, Email_List_Code__c = 'MemberNational'),
            new Email_Preference__c(Email__c = ems[4].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational')
        };

        insert eps;

        eps[0].Opt_in__c = false;
        eps[0].Opt_In_Status_Changed__c = true;
		update eps;

        Test.startTest();
        Database.executeBatch(new EmailPreferenceOptOutProcessorBatch(), 200);
        Test.stopTest();

        System.assertEquals(4, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'ActionNational' 
                                      AND Email__r.Email_address__c = 'test@example.com' 
                                      AND Opt_in__c = false]);
        System.assertEquals(1, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'MemberNational' 
                                      AND Email__r.Email_address__c = 'test@example.com' 
                                      AND Opt_in__c = true]);
        System.assertEquals(1, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'MemberNational' 
                                      AND Email__r.Email_address__c = 'test@devnull.com' 
                                      AND Opt_in__c = true]);
        System.assertEquals(1, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'ActionNational' 
                                      AND Email__r.Email_address__c = 'test@devnull.com' 
                                      AND Opt_in__c = true]);

        System.assertEquals(0, [SELECT count() FROM Email_Preference__c WHERE Opt_In_Status_Changed__c = true]);
    }

    @isTest static void testOptOutBatchMultiple() {
        // Disable triggers so they don't affect our test data.
        disableEmailTrigger();
        disableEmailPreferenceTrigger();

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

        List<Email_Preference__c> eps = new List<Email_Preference__c>{
            new Email_Preference__c(Email__c = ems[0].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[1].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[2].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[3].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[0].Id, Opt_in__c = true, Email_List_Code__c = 'MemberNational'),
            new Email_Preference__c(Email__c = ems[4].Id, Opt_in__c = true, Email_List_Code__c = 'MemberNational'),
            new Email_Preference__c(Email__c = ems[4].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational')
        };

        insert eps;

        eps[0].Opt_in__c = false;
        eps[0].Opt_In_Status_Changed__c = true;
        eps[5].Opt_in__c = false;
        eps[5].Opt_In_Status_Changed__c = true;
        update eps;

        Test.startTest();
        Database.executeBatch(new EmailPreferenceOptOutProcessorBatch(), 200);
        Test.stopTest();

        System.assertEquals(3, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'ActionNational' 
                                      AND Email__r.Email_address__c = 'test@example.com' 
                                      AND Opt_in__c = false]);
        System.assertEquals(1, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'MemberNational' 
                                      AND Email__r.Email_address__c = 'test@example.com' 
                                      AND Opt_in__c = true]);
        System.assertEquals(1, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'MemberNational' 
                                      AND Email__r.Email_address__c = 'test@devnull.com' 
                                      AND Opt_in__c = false]);
        System.assertEquals(2, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email_List_Code__c = 'ActionNational' 
                                      AND Email__r.Email_address__c = 'test@devnull.com' 
                                      AND Opt_in__c = true]);

        System.assertEquals(0, [SELECT count() FROM Email_Preference__c WHERE Opt_In_Status_Changed__c = true]);    
    }

    @isTest static void testOptOutBatchConflictingChanges() {
        // Disable triggers so they don't affect our test data.
        disableEmailTrigger();
        disableEmailPreferenceTrigger();

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

        List<Email_Preference__c> eps = new List<Email_Preference__c>{
            new Email_Preference__c(Email__c = ems[0].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[1].Id, Opt_in__c = false, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[2].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[3].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational'),
            new Email_Preference__c(Email__c = ems[0].Id, Opt_in__c = true, Email_List_Code__c = 'MemberNational'),
            new Email_Preference__c(Email__c = ems[4].Id, Opt_in__c = true, Email_List_Code__c = 'MemberNational'),
            new Email_Preference__c(Email__c = ems[4].Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational')
        };

        insert eps;

        // Insert conflicting changes. They should be applied to matching emails in order, so the opt in = true should win.
        eps[0].Opt_in__c = false;
        eps[0].Opt_In_Status_Changed__c = true;
        update eps[0];
        
        eps[3].Opt_in__c = true;
        eps[3].Opt_In_Status_Changed__c = true;
        update eps[3];
        
        // Call through the handler class directly - we can't modify the SystemModStamp here.
        EmailOptOutProcessor.processOptOutsForEmailPreferences(new List<Email_Preference__c>{eps[0], eps[3]});
        
        System.assertEquals(3, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email__r.Email_address__c = 'test@example.com' 
                                      AND Email_List_Code__c = 'ActionNational'
                                      AND Opt_in__c = true]);
        System.assertEquals(1, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Email__r.Email_address__c = 'test@example.com' 
                                      AND Email_List_Code__c = 'MemberNational'
                                      AND Opt_in__c = true]);
        System.assertEquals(0, [SELECT count() 
                                FROM Email_Preference__c 
                                WHERE Opt_In_Status_Changed__c = true]);
    }   
}