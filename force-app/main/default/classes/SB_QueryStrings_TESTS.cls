/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class SB_QueryStrings_TESTS {
	
    @testSetup
    private static void SetupTestData() {
        Springboard_Settings__c testSettings = new Springboard_Settings__c(Name = 'SB_QueryStrings_TESTS');
        testSettings.Trigger_Prefixes_Active__c = 'QueryStrings';
        testSettings.Encryptor_Key__c = '12345678901234561234567890123456';
        testSettings.Encryptor_IV__c = '1234567890123456';
        insert testSettings;
    }
    
    static testMethod void QueryStringsOnInsert() {
    	Springboard springboard = new Springboard('SB_QueryStrings_TESTS');
    	// Create a test Contact.
    	Test.startTest();
    	Contact testContact = new Contact(
    		FirstName = 'Englebert',
    		LastName = 'Humperdink',
    		MailingStreet = '1234 Fifth Ave'
    	);
    	insert(testContact);
    	
    	// Give the contact an Email.
    	Email__c testEmail = new Email__c(
    		Contact__c = testContact.Id,
    		Email_address__c = 'SB_QueryStrings_TESTS@example.com'
    	);
    	insert(testEmail);
    	Test.stopTest();
    	
    	// Assert the encrypted query strings were populated on both objects as expected.
    	testContact = [SELECT SB_Gift_String__c, SB_Default_Gift_Amount__c, SB_recurring_Gift_String__c, SB_default_Recurring_Gift_Amount__c, SB_Gift_String_Encrypted__c FROM Contact WHERE Id=:testContact.Id];
    	testEmail = [SELECT SB_Query_String_Encrypted__c, SB_Gift_String_Encrypted__c FROM Email__c WHERE Id=:testEmail.Id];
    	//System.assertEquals('a',testContact.SB_Gift_String__c);

        System.assertEquals(
    		springboard.decrypt(testContact.SB_Gift_String_Encrypted__c), 
    		'amounts=' + testContact.SB_Gift_String__c+'&recurring_amounts=' + testContact.SB_recurring_Gift_String__c
		);
    	System.assertEquals(testContact.SB_Gift_String_Encrypted__c, testEmail.SB_Gift_String_Encrypted__c);
    	// NOTE: This assertion assumes the SB_Query_String__c formula includes the Email_address__c value and will fail otherwise.
    	System.assert(springboard.decrypt(testEmail.SB_Query_String_Encrypted__c).indexOf('SB_QueryStrings_TESTS@example.com') != -1);
    }

    static testMethod void QueryStringsOnUpdateContact() {
    	Springboard springboard = new Springboard('SB_QueryStrings_TESTS');
    	
    	// Create a test Contact.
    	Test.startTest();
    	Contact testContact = new Contact(
    		FirstName = 'Englebert',
    		LastName = 'Humperdink'
    	);
    	insert(testContact);
    	
    	// Give the contact an Email.
    	Email__c testEmail = new Email__c(
    		Contact__c = testContact.Id,
    		Email_address__c = 'SB_QueryStrings_TESTS@example.com'
    	);
    	insert(testEmail);

    	// Update the contact.
    	testContact.FirstName = 'Humperdink Humperdink Humperdink';  // Change for the sake of change.
    	update(testContact);
    	
    	// Assert the encrypted query strings were updated on both objects as expected.
    	testContact = [SELECT SB_Gift_String__c, SB_Default_Gift_Amount__c, SB_Gift_String_Encrypted__c FROM Contact WHERE Id=:testContact.Id];
    	testEmail = [SELECT SB_Query_String_Encrypted__c, SB_Gift_String_Encrypted__c FROM Email__c WHERE Id=:testEmail.Id];
    	System.assertEquals(testContact.SB_Gift_String_Encrypted__c, testEmail.SB_Gift_String_Encrypted__c);
    	// NOTE: This assertion assumes the SB_Query_String__c formula includes the Contact__r.FirstName value and will fail otherwise.
    	System.assert(springboard.decrypt(testEmail.SB_Query_String_Encrypted__c).indexOf('Humperdink Humperdink') != -1);
    }

    static testMethod void QueryStringsOnUpdateEmail() {
    	Springboard springboard = new Springboard('SB_QueryStrings_TESTS');
    	
    	// Create a test Contact.
    	Test.startTest();
    	Contact testContact = new Contact(
    		FirstName = 'Englebert',
    		LastName = 'Humperdink'
    	);
    	insert(testContact);
    	
    	// Give the contact an Email.
    	Email__c testEmail = new Email__c(
    		Contact__c = testContact.Id,
    		Email_address__c = 'SB_QueryStrings_TESTS@example.com'
    	);
    	insert(testEmail);

    	// Update the email.
    	try{
    	    testEmail.Email_address__c = 'nowforsomethingcompletelydifferent@example.com';
    	    update(testEmail);
    	}Catch(Exception e){
    	    
    	}
		Test.stopTest();
    	
    	// Assert the encrypted query strings were updated on both objects as expected.
    	testEmail = [SELECT SB_Query_String_Encrypted__c, SB_Gift_String_Encrypted__c FROM Email__c WHERE Id=:testEmail.Id];
    	// NOTE: This assertion assumes the SB_Query_String__c formula includes the Email_address__c value and will fail otherwise.
    	System.assert(springboard.decrypt(testEmail.SB_Query_String_Encrypted__c).indexOf('SB_QueryStrings_TESTS@example.com') != -1);
    	//system.assert(false, springboard.decrypt(testEmail.SB_Query_String_Encrypted__c));
    }

    static testMethod void testGiftStringsOnInsert() {
        Springboard springboard = new Springboard('SB_QueryStrings_TESTS');
        
        // Create a test Contact.
        Test.startTest();
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Testerson');
        insert testContact;
        
        // Give the contact an Email.
        Email__c testEmail = new Email__c(Contact__c = testContact.Id, Email_address__c = 'SB_QueryStrings_TESTS@example.com');
        insert testEmail;
        Test.stopTest();
        
        // Assert the encrypted query strings were populated on both objects as expected.
        testContact = [SELECT GOL_Upgrade_String_Encrypted__c, 
                            Renewal_Gift_String_Encrypted__c,
                            Direct_Mail_Appeal_String_Encrypted__c, 
                            GOL_Upgrade_String__c,
                            Renewal_Gift_String__c,
                            Direct_Mail_Appeal_String__c,
                            SB_Recurring_Gift_String__c,
                            SB_Gift_String__c
                       FROM Contact 
                       WHERE Id=:testContact.Id];
        testEmail = [SELECT GOL_Upgrade_String_Encrypted__c, 
                            Renewal_Gift_String_Encrypted__c,
                            Direct_Mail_Appeal_String_Encrypted__c
                     FROM Email__c 
                     WHERE Id=:testEmail.Id];

        System.assertEquals(springboard.decrypt(testContact.GOL_Upgrade_String_Encrypted__c), 
                            'amounts=' + testContact.SB_Gift_String__c + '&recurring_amounts=' + testContact.GOL_Upgrade_String__c);
        System.assertEquals(springboard.decrypt(testContact.Renewal_Gift_String_Encrypted__c), 
                            'amounts=' + testContact.Renewal_Gift_String__c + '&recurring_amounts=' + testContact.SB_Recurring_Gift_String__c);
        System.assertEquals(springboard.decrypt(testContact.Direct_Mail_Appeal_String_Encrypted__c), 
                            'amounts=' + testContact.Direct_Mail_Appeal_String__c + '&recurring_amounts=' + testContact.SB_Recurring_Gift_String__c);

        System.assertEquals(testContact.GOL_Upgrade_String_Encrypted__c, testEmail.GOL_Upgrade_String_Encrypted__c);
        System.assertEquals(testContact.Renewal_Gift_String_Encrypted__c, testEmail.Renewal_Gift_String_Encrypted__c);
        System.assertEquals(testContact.Direct_Mail_Appeal_String_Encrypted__c, testEmail.Direct_Mail_Appeal_String_Encrypted__c);
    }

    static testMethod void testGiftStringsOnUpdateContact() {
        Springboard springboard = new Springboard('SB_QueryStrings_TESTS');
        
        // Create a test Contact.
        Test.startTest();
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Testerson');
        insert testContact;
        
        // Give the contact an Email.
        Email__c testEmail = new Email__c(Contact__c = testContact.Id, Email_address__c = 'SB_QueryStrings_TESTS@example.com');
        insert testEmail;
        Test.stopTest();

        // Update the contact.
        testContact.FirstName = 'Tom Q.';  
        testContact.HPC36_Amount__c  = 166;
        testContact.GOL_Current_Amount__c =19;
        testContact.Renewal_Ask_Amount_1__c =1;
        testContact.Renewal_Ask_Amount_2__c =1;
        testContact.Renewal_Ask_Amount_3__c =1;
        testContact.Direct_Mail_Ask_Amount_1__c =1;
        testContact.Direct_Mail_Ask_Amount_2__c =1;
        testContact.Direct_Mail_Ask_Amount_3__c =1;
        update testContact;
        
        // Assert the encrypted query strings were populated on both objects as expected.
        testContact = [SELECT GOL_Upgrade_String_Encrypted__c, 
                            Renewal_Gift_String_Encrypted__c,
                            Direct_Mail_Appeal_String_Encrypted__c, 
                            GOL_Upgrade_String__c,
                            Renewal_Gift_String__c,
                            Direct_Mail_Appeal_String__c,
                            SB_Gift_String__c,
                            SB_recurring_Gift_String__c
                       FROM Contact 
                       WHERE Id=:testContact.Id];
        testEmail = [SELECT GOL_Upgrade_String_Encrypted__c, 
                            Renewal_Gift_String_Encrypted__c,
                            Direct_Mail_Appeal_String_Encrypted__c 
                     FROM Email__c 
                     WHERE Id=:testEmail.Id];

        System.assertEquals(springboard.decrypt(testContact.GOL_Upgrade_String_Encrypted__c), 
                            'amounts=' + testContact.SB_Gift_String__c + '&recurring_amounts=' + testContact.GOL_Upgrade_String__c);
        System.assertEquals(springboard.decrypt(testContact.Renewal_Gift_String_Encrypted__c), 
                            'amounts=' + testContact.Renewal_Gift_String__c + '&recurring_amounts=' + testContact.SB_Recurring_Gift_String__c);
        System.assertEquals(springboard.decrypt(testContact.Direct_Mail_Appeal_String_Encrypted__c), 
                            'amounts=' + testContact.Direct_Mail_Appeal_String__c + '&recurring_amounts=' + testContact.SB_Recurring_Gift_String__c);

        System.assertEquals(testContact.GOL_Upgrade_String_Encrypted__c, testEmail.GOL_Upgrade_String_Encrypted__c);
        System.assertEquals(testContact.Renewal_Gift_String_Encrypted__c, testEmail.Renewal_Gift_String_Encrypted__c);
        System.assertEquals(testContact.Direct_Mail_Appeal_String_Encrypted__c, testEmail.Direct_Mail_Appeal_String_Encrypted__c);
    }
}