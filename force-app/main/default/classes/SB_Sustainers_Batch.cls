global with sharing class SB_Sustainers_Batch implements Database.Batchable<SObject>, Database.Stateful {

    global Springboard springboard;
    global String upgradeAmountField;
    global String upgradeFormId;
    global Datetime tokenExpiration;
    
    global List<Contact> contacts;
    global Map<Id, Id> contactToOpportunity;
    global Map<Id, String> contactToDonationId;
    global Map<Id, Date> contactToCloseDate;
    global Map<Id, Decimal> contactToAmount;
    
    global SB_Sustainers_Batch() {
        this.springboard = new Springboard();
        Integer tokenLifespan;
        // Set defaults.
        tokenLifespan = 60;
        this.upgradeAmountField = 'SB_Upgrade_Amount__c';
        // Override defaults where possible.
    	if (this.springboard.settings.Sustainers_HMAC_Token_Lifespan__c != NULL) {
            tokenLifespan = Integer.valueOf(this.springboard.settings.Sustainers_HMAC_Token_Lifespan__c);
    	}
    	if (this.springboard.settings.Sustainers_Upgrade_Amount_Field__c != NULL) {
            this.upgradeAmountField = this.springboard.settings.Sustainers_Upgrade_Amount_Field__c;
    	}
        if (this.springboard.settings.Sustainers_Upgrade_Form_Id__c != NULL) {
            this.upgradeFormId = String.valueOf(this.springboard.settings.Sustainers_Upgrade_Form_Id__c);
        }
        this.tokenExpiration = Datetime.now().addDays(tokenLifespan);
        // Instantiate the Contact-Opportunity concordance maps.
        this.contactToOpportunity = new Map<Id, Id>();
		this.contactToDonationId = new Map<Id, String>();
		this.contactToCloseDate = new Map<Id, Date>();
		this.contactToAmount = new Map<Id, Decimal>();
    }

    global List<Contact> start(Database.BatchableContext context) {
        // Query sustainer series to be batched up and processed.
        // We're interested only in the master donation records, and only ones with Springboard IDs.
        // We're also interested only in Contacts with Drupal user IDs.
        // To stay within governor limits, we'll pick those with the least-fresh (or non-existant) HMACs first.
        List<Opportunity> sustainerSeries = new List<Opportunity>([
        	SELECT rC_Giving__Primary_Contact__r.Id, SB_Donation_Id__c, CloseDate, rC_Giving__Giving_Amount__c
        	FROM Opportunity
			WHERE rC_Giving__Parent__c = null AND rC_Giving__Is_Sustainer__c = true AND StageName IN ('Open', 'Partially Complete')
				AND rC_Giving__Primary_Contact__r.SB_User_Id__c != null AND SB_Donation_Id__c != null
        	ORDER BY rC_Giving__Primary_Contact__r.SB_Sustainer_Upgrade_Token_Expiration__c ASC, CloseDate DESC
        	LIMIT 25000
        ]);
        Set<Id> contactIds = new Set<Id>();
        for (Opportunity masterDonation : sustainerSeries) {
        	// A Contact could have multiple recurring donations, so take the most recent.
        	if (this.contactToOpportunity.get(masterDonation.rC_Giving__Primary_Contact__r.Id) == null 
        		|| masterDonation.CloseDate > this.contactToCloseDate.get(masterDonation.rC_Giving__Primary_Contact__r.Id)
    		) {
	        	contactIds.add(masterDonation.rC_Giving__Primary_Contact__r.Id);
	        	this.contactToOpportunity.put(masterDonation.rC_Giving__Primary_Contact__r.Id, masterDonation.Id);
	        	this.contactToDonationId.put(masterDonation.rC_Giving__Primary_Contact__r.Id, masterDonation.SB_Donation_Id__c);
	        	this.contactToCloseDate.put(masterDonation.rC_Giving__Primary_Contact__r.Id, masterDonation.CloseDate);
	        	this.contactToAmount.put(masterDonation.rC_Giving__Primary_Contact__r.Id, masterDonation.rC_Giving__Giving_Amount__c);
    		}
        }
        this.contacts = Database.query('SELECT SB_User_Id__c, ' + this.upgradeAmountField + ' FROM Contact WHERE Id IN :contactIds');
        
        // Onwards!
        return this.contacts;
    }
    
    global void execute(Database.BatchableContext context, List<Contact> scope) {
        // First populate the Upgradable_Recurring_Donations__c fields for all Contacts in scope.
        List<Id> contactIds = new List<Id>();
        for (Contact contact : scope) {
            contactIds.add(contact.Id);
        }
        for (Contact contact : scope) {
            // Set the Contact's upgradable recurring series.
            contact.SB_Upgradable_Recurring_Donation__c = this.contactToOpportunity.get(contact.Id);
            contact.SB_Recurring_Donation_Amount__c = this.contactToAmount.get(contact.Id);
            String recurringDonationId = this.contactToDonationId.get(contact.Id);
            // Run formula fields so that the upgradeAmountField will update.
			try {
	            contact.recalculateFormulas();
			} catch (Exception e) {
				// This shouldn't happen. But if something's goofy with Salesforce, we want to soldier on.
			}
            // Sustainer Upgrade HMAC is only available for a Contact with an upgradable series and an upgrade amount.
            if (recurringDonationId != NULL && contact.get(this.upgradeAmountField) != NULL) {
                // Generate the HMAC sustainer upgrade message for this Contact.
                List<String> parameters = new List<String>();
                parameters.add( String.valueOf(Integer.valueOf(100 * Double.valueOf(contact.get(this.upgradeAmountField)))) );
                parameters.add(recurringDonationId);
                if (this.upgradeFormId != NULL) {
                    parameters.add(this.upgradeFormId);
                }
                String message = this.springboard.createHMAC(contact.SB_User_Id__c, this.tokenExpiration, 'su', parameters);
                // Sign the message and set the upgrade URL segment and expiration.
                String token = this.springboard.signHMAC(message);
                contact.SB_Upgrade_URL__c = 'hmac/' + EncodingUtil.base64Encode( Blob.valueOf(message) ) + '/' + token;
                contact.SB_Sustainer_Upgrade_Token_Expiration__c = this.tokenExpiration;
            }
            else {
            	// Make sure old HMACs don't hang around.
            	contact.SB_Upgrade_URL__c = null;
            	contact.SB_Sustainer_Upgrade_Token_Expiration__c = null;
            }
        }
        
        // Save the updated Contacts.
        update scope;
    }
    
    global void finish(Database.BatchableContext context) {
       
    }
}