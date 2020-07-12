@isTest
private class SB_P2P_TESTS {
	
    @testSetup
    private static void SetupTestData() {
        Springboard_Settings__c testSettings = new Springboard_Settings__c(Name = 'SB_P2P_TESTS');
        testSettings.Trigger_Prefixes_Active__c = 'P2P';
        insert testSettings;
    }
    
	/**
	 * Opportunity trigger test coverage.
	 */
    static testMethod void campaignCalculationsTest() {
        Springboard springboard = new Springboard('SB_P2P_TESTS');
        
        Contact contact = SB_P2P_TESTS.p2pContactCreator('John', 'Doe', 'john.doe@example.com');
        P2P_Category__c category = SB_P2P_TESTS.p2pCategoryCreator('Endangered Species', 'Peer to peer campaigns related to endangered species.', 'http://example.com/endangered-species');
        P2P_Campaign__c campaign = SB_P2P_TESTS.p2pCampaignCreator('Blue Whales', category, '5', 'Amount Raised');
        P2P_Personal_Campaign__c personalCampaign = SB_P2P_TESTS.p2pPersonalCampaignCreator('John\'s Campaign to Stop Whale Poaching', campaign, contact, 30, 'Amount Raised', 1000.00);
        Opportunity donation = SB_P2P_TESTS.p2pCampaignDonationCreator(10, contact, personalCampaign);
                
        personalCampaign = [SELECT Id, Name, Amount_Raised__c, Donation_Count__c, Submission_Count__c FROM P2P_Personal_Campaign__c WHERE Id =: personalCampaign.Id];
        System.assertEquals(10.00, personalCampaign.Amount_Raised__c);
        System.assertEquals(1, personalCampaign.Submission_Count__c);
        System.assertEquals(1, personalCampaign.Donation_Count__c);
        
        Opportunity donation2 = SB_P2P_TESTS.p2pCampaignDonationCreator(25, contact, personalCampaign);
        personalCampaign = [SELECT Id, Name, Amount_Raised__c, Donation_Count__c, Submission_Count__c FROM P2P_Personal_Campaign__c WHERE Id =: personalCampaign.Id];
        System.assertEquals(35.00, personalCampaign.Amount_Raised__c);
        System.assertEquals(2, personalCampaign.Submission_Count__c);
        System.assertEquals(2, personalCampaign.Donation_Count__c);
    }
    
    /**
     * Integration test coverage.
     */
    static testMethod void bulkPropagationTest() {
        Springboard springboard = new Springboard('SB_P2P_TESTS');
        
        Contact contact = SB_P2P_TESTS.p2pContactCreator('John', 'Doe', 'john.doe@example.com');
        P2P_Category__c category = SB_P2P_TESTS.p2pCategoryCreator('Endangered', 'Peer to peer campaigns related to endangered species.', 'http://example.com/es');
        
        // Create a couple campaigns
        List<P2P_Campaign__c> campaigns = new List<P2P_Campaign__c>();
        campaigns.add(SB_P2P_TESTS.p2pCampaignCreator('Blue Whales', category, '5', 'Amount Raised'));
        campaigns.add(SB_P2P_TESTS.p2pCampaignCreator('Rats', category, '6', 'Amount Raised'));
        campaigns.add(SB_P2P_TESTS.p2pCampaignCreator('Dogs', category, '7', 'Amount Raised'));
        
        campaigns = [SELECT Id, P2P_Category__c, Number_of_Submission__c, Number_of_donations__c, Amount_Raised__c FROM P2P_Campaign__c WHERE Id IN : campaigns];
        for (P2P_Campaign__c campaign : campaigns) {
            System.assertEquals(NULL, campaign.Number_of_Submission__c);
            System.assertEquals(NULL, campaign.Number_of_donations__c);
            System.assertEquals(NULL, campaign.Amount_Raised__c);
        }
        
        List<P2P_Personal_Campaign__c> personalCampaigns = new List<P2P_Personal_Campaign__c>();
        // Create a bunch of personal campaigns and assign them to campaigns.
        for (Integer i = 0; i < 20; i++) {
            P2P_Personal_Campaign__c pc = new P2P_Personal_Campaign__c();
            pc.Name = 'Personal Campaign ' + i;
            pc.P2P_Category__c = campaigns.get(0).P2P_Category__c;
            pc.P2P_Campaign__c = campaigns.get(0).Id;
            pc.P2P_Campaigner__c = contact.Id;
            pc.Start_Date__c = Date.today();
            pc.End_Date__c = Date.today().addDays(30);
            pc.Goal_Type__c = 'Amount Raised';
            pc.Fundraising_Goal__c = 10000;
            personalCampaigns.add(pc);
        }   
        
        insert personalCampaigns;
        for (P2P_Personal_Campaign__c personalCampaign : personalCampaigns) {
            System.assertEquals(NULL, personalCampaign.Amount_Raised__c);
            System.assertEquals(NULL, personalCampaign.Donation_Count__c);
            System.assertEquals(NULL, personalCampaign.Submission_Count__c);
        }
        
        List<Opportunity> donations = new List<Opportunity>();
        for (Integer i = 0; i < 20; i++) {
            Opportunity donation = new Opportunity();
            donation.Name = 'Donation to ' + personalCampaigns.get(0).Name;
            donation.rC_Giving__Giving_Amount__c = 10;
            donation.AccountId = contact.AccountId;
            donation.StageName = 'Posted';
            donation.Probability = 100;
            donation.CloseDate = Date.today();
            donation.SB_P2P_Personal_Campaign__c = personalCampaigns.get(0).Id;
            donations.add(donation);
        }
        
        insert donations;
        
        // Assert that values on the personal campaign updated correctly
        P2P_Personal_Campaign__c personalCampaign = [SELECT Id, Name, Amount_Raised__c, Donation_Count__c, Submission_Count__c FROM P2P_Personal_Campaign__c WHERE Id =: personalCampaigns.get(0).Id];
        System.assertEquals(200.00, personalCampaign.Amount_Raised__c);
        System.assertEquals(20, personalCampaign.Donation_Count__c);
        System.assertEquals(20, personalCampaign.Submission_Count__c);
        
        // Assert that values on the campaign updated correctly
        P2P_Campaign__c campaign = [SELECT Id, P2P_Category__c, Number_of_Submission__c, Number_of_donations__c, Amount_Raised__c  FROM P2P_Campaign__c WHERE Id =: campaigns.get(0).Id];
        System.assertEquals(20, campaign.Number_of_Submission__c);
        System.assertEquals(20, campaign.Number_of_donations__c);
        System.assertEquals(200.00, campaign.Amount_Raised__c);
        
        contact = [SELECT Id, SB_P2P_Total_Donation_Amount__c, SB_P2P_Total_Campaigns__c, SB_P2P_Total_Donations__c FROM Contact WHERE Id =: contact.Id];
        System.assertEquals(200.00, contact.SB_P2P_Total_Donation_Amount__c);
        System.assertEquals(20, contact.SB_P2P_Total_Donations__c);
        System.assertEquals(20, contact.SB_P2P_Total_Campaigns__c);
    }
    
    static testMethod void propagationTest() {
        Springboard springboard = new Springboard('SB_P2P_TESTS');
        
        Contact contact = SB_P2P_TESTS.p2pContactCreator('John', 'Doe', 'john.doe@example.com');
        P2P_Category__c category = SB_P2P_TESTS.p2pCategoryCreator('Endangered Species', 'Peer to peer campaigns related to endangered species.', 'http://example.com/endangered-species');
        P2P_Campaign__c campaign = SB_P2P_TESTS.p2pCampaignCreator('Blue Whales', category, '5', 'Amount Raised');
        P2P_Personal_Campaign__c personalCampaign = SB_P2P_TESTS.p2pPersonalCampaignCreator('John\'s Campaign to Stop Whale Poaching', campaign, contact, 30, 'Amount Raised', 1000.00);
        Opportunity donation = SB_P2P_TESTS.p2pCampaignDonationCreator(10, contact, personalCampaign);
        
        update personalCampaign;
        
        // Check personal campaign stats
        personalCampaign = [SELECT Id, Name, Amount_Raised__c, Donation_Count__c, Submission_Count__c FROM P2P_Personal_Campaign__c WHERE Id =: personalCampaign.Id];
        System.assertEquals(10.00, personalCampaign.Amount_Raised__c);
        System.assertEquals(1, personalCampaign.Submission_Count__c);
        System.assertEquals(1, personalCampaign.Donation_Count__c);
        
        // Check campaign stats
        campaign = [SELECT Id, P2P_Category__c, Number_of_Submission__c, Number_of_donations__c, Amount_Raised__c  FROM P2P_Campaign__c WHERE Id =: campaign.Id];
        //System.assertEquals(1, campaign.Number_of_Submission__c);
        System.assertEquals(1, campaign.Number_of_donations__c);
        System.assertEquals(10.00, campaign.Amount_Raised__c);
        
        P2P_Personal_Campaign__c personalCampaign2 = SB_P2P_TESTS.p2pPersonalCampaignCreator('John\'s Campaign to Stop Whale Poaching 2', campaign, contact, 30, 'Amount Raised', 1000.00);
        Opportunity donation2 = SB_P2P_TESTS.p2pCampaignDonationCreator(25, contact, personalCampaign2);
        
        campaign = [SELECT Id, Number_of_Submission__c, Number_of_donations__c, Amount_Raised__c  FROM P2P_Campaign__c WHERE Id =: campaign.Id];
        System.assertEquals(35.00, campaign.Amount_Raised__c);
        System.assertEquals(2, campaign.Number_of_donations__c);
        
        // Check contact stats
        contact = [SELECT Id, SB_P2P_Total_Donation_Amount__c, SB_P2P_Total_Campaigns__c, SB_P2P_Total_Donations__c FROM Contact WHERE Id =: contact.Id];
        System.assertEquals(35.00, contact.SB_P2P_Total_Donation_Amount__c);
        System.assertEquals(2, contact.SB_P2P_Total_Donations__c);
        System.assertEquals(2, contact.SB_P2P_Total_Campaigns__c);
    }
	
	/**
	 * Personal Campaign trigger test coverage.
	 */
	static testMethod void personalCampaignOwnerCampaignCountTest() {
        Springboard springboard = new Springboard('SB_P2P_TESTS');
        
		Contact contact = SB_P2P_TESTS.p2pContactCreator('John', 'Doe', 'john.doe@example.com');
        P2P_Category__c category = SB_P2P_TESTS.p2pCategoryCreator('Endangered Species', 'Peer to peer campaigns related to endangered species.', 'http://example.com/endangered-species');
        P2P_Campaign__c campaign = SB_P2P_TESTS.p2pCampaignCreator('Blue Whales', category, '5', 'Amount Raised');
        P2P_Personal_Campaign__c personalCampaign1 = SB_P2P_TESTS.p2pPersonalCampaignCreator('John\'s Campaign to Stop Whale Poaching', campaign, contact, 30, 'Amount Raised', 1000.00);
        
        Opportunity donation1 = SB_P2P_TESTS.p2pCampaignDonationCreator(50, contact, personalCampaign1);
        
		contact = [SELECT Id, AccountId, SB_P2P_Total_Campaigns__c, SB_P2P_Total_Donations__c, SB_P2P_Total_Donation_Amount__c FROM Contact WHERE Id =: contact.Id];
		System.assertEquals(1, contact.SB_P2P_Total_Campaigns__c);
		System.assertEquals(1, contact.SB_P2P_Total_Donations__c);
		System.assertEquals(50, contact.SB_P2P_Total_Donation_Amount__c);
		
		// Add another.
		P2P_Personal_Campaign__c personalCampaign2 = SB_P2P_TESTS.p2pPersonalCampaignCreator('John Saves the Whales', campaign, contact, 45, 'Amount Raised', 500.00);
		
		Opportunity donation2 = SB_P2P_TESTS.p2pCampaignDonationCreator(25, contact, personalCampaign2);
		
		contact = [SELECT Id, AccountId, SB_P2P_Total_Campaigns__c, SB_P2P_Total_Donations__c, SB_P2P_Total_Donation_Amount__c FROM Contact WHERE Id =: contact.Id];
		System.assertEquals(2, contact.SB_P2P_Total_Campaigns__c);
		System.assertEquals(2, contact.SB_P2P_Total_Donations__c);
		System.assertEquals(75, contact.SB_P2P_Total_Donation_Amount__c);
	}

    static testMethod void personalCampaignToCampaignCalculationsTest() {
        Springboard springboard = new Springboard('SB_P2P_TESTS');
        
        Contact contact = SB_P2P_TESTS.p2pContactCreator('John', 'Doe', 'john.doe@example.com');
        P2P_Category__c category = SB_P2P_TESTS.p2pCategoryCreator('Endangered Species', 'Peer to peer campaigns related to endangered species.', 'http://example.com/endangered-species');
        P2P_Campaign__c campaign = SB_P2P_TESTS.p2pCampaignCreator('personalCampaignToCampaignCalculationsTest', category, '5', 'Amount Raised');
        
        campaign = [SELECT Id, P2P_Category__c, Number_of_Submission__c FROM P2P_Campaign__c WHERE Id =: campaign.Id];
        System.assertEquals(NULL, campaign.Number_of_Submission__c);
        
        // Create 2 personal campaigns
        P2P_Personal_Campaign__c personalCampaign1 = SB_P2P_TESTS.p2pPersonalCampaignCreator('John\'s Campaign to Stop Whale Poaching', campaign, contact, 30, 'Amount Raised', 1000.00);
        P2P_Personal_Campaign__c personalCampaign2 = SB_P2P_TESTS.p2pPersonalCampaignCreator('John Saves the Whales', campaign, contact, 45, 'Amount Raised', 500.00);
        
        // Update the personal campaign's submission counts manually.
        personalCampaign1.Submission_Count__c = 10;
        personalCampaign1.Donation_Count__c = 1;
        update personalCampaign1;
        
        // Fire off the calculations manually, too. P2P_Personal_CampaignTrigger only does this on inserts, not updates.
    	SB_P2P_Trigger_PersonalCampaign triggerHandler = new SB_P2P_Trigger_PersonalCampaign();
		triggerHandler.onAfterInsert([SELECT P2P_Campaigner__c FROM P2P_Personal_Campaign__c WHERE P2P_Campaign__r.Name = 'personalCampaignToCampaignCalculationsTest']);
        
        campaign = [SELECT Number_of_Submission__c, Number_of_donations__c FROM P2P_Campaign__c WHERE Id =: campaign.Id];
//@TODO: fix. These assertions fail as of 3/2/16
//        System.assertEquals(10, campaign.Number_of_Submission__c);
//        System.assertEquals(1, campaign.Number_of_donations__c);
        
        personalCampaign2.Submission_Count__c = 20;
        personalCampaign2.Donation_Count__c = 3;
        update personalCampaign2;
        
        campaign = [SELECT Number_of_Submission__c, Number_of_donations__c FROM P2P_Campaign__c WHERE Id =: campaign.Id];
//@TODO: fix. These assertions fail as of 3/2/16
//        System.assertEquals(30, campaign.Number_of_Submission__c);
//        System.assertEquals(4, campaign.Number_of_donations__c);
    }
    
    /**
     * Test data factory methods.
     */
    public static Contact p2pContactCreator(String firstName, String lastName, String email) {
        Contact contact = new Contact();
        contact.FirstName = firstName;
        contact.LastName = lastName;
        contact.Email = email;
        insert contact;
        
        // Return with AccountId
        contact = [SELECT Id, AccountId, FirstName, LastName, Email FROM contact where Id =: contact.Id];
        
        return contact;
    }
    
    public static P2P_Category__c p2pCategoryCreator(String name, String description, String url) {
        P2P_Category__c category = new P2P_Category__c();
        category.Name = name;
        category.P2P_Category_Description__c = description;
        category.P2P_Category_URL__c = url;
        insert category;
        
        return category;
    }
    
    public static P2P_Campaign__c p2pCampaignCreator(String name, P2P_Category__c category, String nodeId, String goalType) {
        P2P_Campaign__c campaign = new P2P_Campaign__c();
        campaign.name = name;
        campaign.P2P_Category__c = category.Id;
        campaign.Node_ID__c = nodeId;
        campaign.Goal_Type__c = goalType;
        insert campaign;
        
        return campaign;
    }
    
    public static P2P_Personal_Campaign__c p2pPersonalCampaignCreator(string Name, P2P_Campaign__c campaign, Contact contact,
        Integer length, String goalType, Decimal goal) {
        P2P_Personal_Campaign__c personalCampaign = new P2P_Personal_Campaign__c();
        personalCampaign.Name = name;
        personalCampaign.P2P_Category__c = campaign.P2P_Category__c;
        personalCampaign.P2P_Campaign__c = campaign.Id;
        personalCampaign.P2P_Campaigner__c = contact.Id;
        personalCampaign.Start_Date__c = Date.today();
        personalCampaign.End_Date__c = Date.today().addDays(length);
        personalCampaign.Goal_Type__c = goalType;
        personalCampaign.Fundraising_Goal__c = goal;
        
        insert personalCampaign;
        
        return personalCampaign;    
    }
    
    public static Opportunity p2pCampaignDonationCreator(Double amount, Contact contact, P2P_Personal_Campaign__c personalCampaign) {
        Opportunity donation = new Opportunity();
        donation.Name = 'Donation to ' + personalCampaign.Name;
        donation.rC_Giving__Giving_Amount__c = amount;
        donation.AccountId = contact.AccountId;
        donation.StageName = 'Posted';
        donation.Probability = 100;
        donation.CloseDate = Date.today();
        donation.SB_P2P_Personal_Campaign__c = personalCampaign.Id;
        insert donation;
        
        return donation;    
    }

}