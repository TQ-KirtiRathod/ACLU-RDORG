@isTest
public class SB_Sustainers_TESTS {

    @testSetup
    private static void SetupTestData() {
        Springboard_Settings__c testSettings = new Springboard_Settings__c(Name = 'SB_Sustainers_TESTS');
        testSettings.Sustainers_HMAC_Token_Lifespan__c = 30;
        testSettings.Encryptor_IV__c = '22SIRITmX9L7irSJ';
        testSettings.Encryptor_Key__c = 'SQgOCb34r2i3tfMvPZDkkLMVwqD90g9S';
        testSettings.Trigger_Prefixes_Active__c = 'Sustainers';
        insert testSettings;
        
		Springboard_Settings_Profile__c sbSettingsProfile = Springboard_Settings_Profile__c.getInstance();
		if (sbSettingsProfile == NULL) {
			sbSettingsProfile = new Springboard_Settings_Profile__c();
		}
		sbSettingsProfile.Name__c = 'SB_Sustainers_TESTS';
		upsert sbSettingsProfile;
        
    }

    private static testMethod void TokensTestBatch() {
        // Set-up: custom settings.
        Springboard springboard = new Springboard();
        springboard.settings.Sustainers_Upgrade_Amount_Field__c = 'SB_Recurring_Donation_Amount__c';  // But, you protest, this is the wrong field! Doesn't matter. It's a field we can set.
        springboard.settings.Sustainers_Upgrade_Form_Id__c = 98765;
        upsert springboard.settings;

        // Set-up: Contact to upsell and upgrade.
        Contact testContact = new Contact(
            FirstName = 'Test Contact',
            LastName = 'SB_Sustainers_TESTS',
            SB_User_Id__c = '12345'
        );
        insert testContact;
        
        // Create a recurring donation for this contact. The amount should get
        // written over to the SB_Recurring_Donation_Amount__c field on the contact object.
        Opportunity recurringDonation = new Opportunity(
        	Name = 'SB_Sustainers_TESTS Donation 1',
        	SB_Donation_Id__c = '54321',
        	CloseDate = Date.today(),
        	rC_Giving__Giving_Amount__c = 22.22,
            rC_Giving__Primary_Contact__c = testContact.Id,
        	rC_Giving__Is_Sustainer__c = true,
        	StageName = 'Partially Complete'
        );
        insert recurringDonation;
        
        insert new OpportunityContactRole(
        	ContactId = testContact.Id,
        	OpportunityId = recurringDonation.Id,
        	IsPrimary = true,
        	Role = 'Other'
        );
        
        // Create some opportunities in the recurring series.
        List<Opportunity> payments = new List<Opportunity>();
        for (integer i = 1; i <= 10; i++) {
            Opportunity donation = new Opportunity();
            donation.Name = 'Donation ' + String.valueOf(100 + i);
            donation.rC_Giving__Giving_Amount__c = 22.22;
            donation.rC_Giving__Parent__c = recurringDonation.Id;
            donation.rC_Giving__Primary_Contact__c = testContact.Id;
            donation.StageName = 'Open';
            donation.CloseDate = Date.today().addMonths(i);
            payments.add(donation);
        }
        insert payments;
        
        // Create an old recurring donation for this contact. It should be ignored in preference for the latest.
        Opportunity oldRecurringDonation = new Opportunity(
        	Name = 'SB_Sustainers_TESTS Donation 0',
        	SB_Donation_Id__c = '4321',
        	CloseDate = Date.today().addMonths(-6),
        	rC_Giving__Giving_Amount__c = 11.11,
            rC_Giving__Primary_Contact__c = testContact.Id,
        	rC_Giving__Is_Sustainer__c = true,
        	StageName = 'Partially Complete'
        );
        insert oldRecurringDonation;
        
        insert new OpportunityContactRole(
        	ContactId = testContact.Id,
        	OpportunityId = oldRecurringDonation.Id,
        	IsPrimary = true,
        	Role = 'Other'
        );
        
	    // Create some opportunities in the recurring series.
        payments = new List<Opportunity>();
        for (integer i = 1; i <= 5; i++) {
            Opportunity donation = new Opportunity();
            donation.Name = 'Donation ' + String.valueOf(10 + i);
            donation.rC_Giving__Giving_Amount__c = 11.11;
            donation.rC_Giving__Parent__c = oldRecurringDonation.Id;
            donation.rC_Giving__Primary_Contact__c = testContact.Id;
            donation.StageName = 'Open';
            donation.CloseDate = Date.today().addMonths(i - 1);
            payments.add(donation);
        }
        insert payments;

        Test.startTest();
        SB_Sustainers_Scheduler scheduler = new SB_Sustainers_Scheduler();
        SchedulableContext context;
        scheduler.execute(context);
        Test.stopTest();
        
        // Query the test Contact and verify the upgrade URL and expiry.
        Contact contact = [
        	SELECT SB_Upgrade_URL__c, SB_Sustainer_Upgrade_Token_Expiration__c, SB_Upgradable_Recurring_Donation__r.Id
        	FROM Contact WHERE LastName='SB_Sustainers_TESTS'
    	];

		// Sustainer Upgrade assertions.
        System.assertEquals(recurringDonation.Id, contact.SB_Upgradable_Recurring_Donation__r.Id);
        String expectedMessage = '12345.' + String.valueOf(contact.SB_Sustainer_Upgrade_Token_Expiration__c.getTime() / 1000) + '.su.2222.54321.98765';
        String expectedToken = springboard.signHMAC(expectedMessage);
        String expectedUrl = 'hmac/' + EncodingUtil.base64Encode( Blob.valueOf(expectedMessage) ) + '/' + expectedToken;
        System.assertEquals(expectedUrl, contact.SB_Upgrade_URL__c);
        System.assertEquals(contact.SB_Sustainer_Upgrade_Token_Expiration__c.date(), Date.today().addDays(30));  // Make sure our custom setting overrode the hardwired default.
    }
    
    private static testMethod void newSustainerUpgrades() {
        Springboard springboard = new Springboard('SB_Sustainers_TESTS');

        // Create a donor.
        Contact donor = new Contact(
        	FirstName = 'Tester',
        	LastName = 'SustainersUpgraded_TESTS'
        );
        insert donor;
        
        // Create a recurring donation for this donor.
        Opportunity recurringDonation = new Opportunity(
        	Name = 'SB_Sustainers_TESTS Donation',
        	SB_Donation_Id__c = '54321',
        	CloseDate = Date.today(),
        	rC_Giving__Giving_Amount__c = 22.22,
            rC_Giving__Primary_Contact__c = donor.Id,
        	rC_Giving__Is_Sustainer__c = true,
        	StageName = 'Partially Complete'
        );
        insert recurringDonation;
        
        insert new OpportunityContactRole(
        	ContactId = donor.Id,
        	OpportunityId = recurringDonation.Id,
        	IsPrimary = true,
        	Role = 'Other'
        );
        
        // Create some opportunities in the recurring series.
        List<Opportunity> payments = new List<Opportunity>();
        for (integer i = 1; i <= 10; i++) {
            Opportunity donation = new Opportunity();
            donation.Name = 'Donation ' + String.valueOf(100 + i);
            donation.rC_Giving__Giving_Amount__c = 22.22;
            donation.rC_Giving__Parent__c = recurringDonation.Id;
            donation.rC_Giving__Primary_Contact__c = donor.Id;
            donation.StageName = 'Open';
            donation.CloseDate = Date.today().addMonths(i);
            payments.add(donation);
        }
        insert payments;
        
        // Create two upgrades for the one donor with different timestamps.
        List<Sustainer_Upgrade__c> upgrades = new List<Sustainer_Upgrade__c>();
        upgrades.add(new Sustainer_Upgrade__c(
        	Contact__c = donor.Id,
        	Failure_Flag__c = 'The first upgrade attempt failed for some reason.',
        	Recurring_Donations__c = recurringDonation.Id
        ));
        upgrades.get(0).Timestamp__c = DateTime.now().addDays(-1);

		DateTime successTimestamp = DateTime.now();
        upgrades.add(new Sustainer_Upgrade__c(
        	Contact__c = donor.Id,
        	Timestamp__c = successTimestamp,
        	Recurring_Donations__c = recurringDonation.Id
        ));
        
        // Insert the upgrade objects to run the trigger.
        Test.startTest();
        insert upgrades;
        Test.stopTest();
        
        // Confirm the contact was updated correctly by the trigger.
        donor = [
        	SELECT SB_Last_Sustainer_Upgrade_Date__c, SB_Last_Sustainer_Upgrade_Successful__c
        	FROM Contact WHERE Id = :donor.Id
    	];
        System.assertEquals(donor.SB_Last_Sustainer_Upgrade_Date__c, successTimestamp);
        System.assertEquals(donor.SB_Last_Sustainer_Upgrade_Successful__c, true);
    }
}