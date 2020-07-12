/*
*
*Name  :  SB_OCDonate_Batch
*Author:  Jacksonriver (Joel Rothschild)
*Date  :  Feb 17, 2017
*Purpose : Batch class to populate subscription fields on Contacts
*
*/
global with sharing class SB_OCDonate_Batch implements Database.Batchable<SObject>, Database.Stateful {

    global List<Contact> subscribers;
    global Springboard springboard;
    global Datetime tokenExpiration;
    
    global SB_OCDonate_Batch() {
        this.springboard = new Springboard();
        // Get token lifespan from settings. Default to 60 days.
        Integer tokenLifespan = 60;
        if (this.springboard.settings != NULL && this.springboard.settings.OCDonate_HMAC_Token_Lifespan__c != NULL) {
            tokenLifespan = Integer.valueOf(this.springboard.settings.OCDonate_HMAC_Token_Lifespan__c);
        }
        this.tokenExpiration = Datetime.now().addDays(tokenLifespan);
    }

    global List<Contact> start(Database.BatchableContext context) {
    	// First, find any active-default subscriptions whose cards have expired, and de-activate them.
    	List<One_Click_Donate_Subscription__c> expiredSubscriptions = [
    		SELECT Default_Payment_Method__c FROM One_Click_Donate_Subscription__c
			WHERE Default_Payment_Method__c = true AND (
				CC_Exp_Year__c < :Date.today().year() OR (
    				CC_Exp_Year__c = :Date.today().year() AND CC_Exp_Month__c < :Date.today().month()
    			)
			)
			LIMIT 25000
    	];
    	if (expiredSubscriptions.size() > 0) {
	    	for (One_Click_Donate_Subscription__c expiredSubscription : expiredSubscriptions) {
	    		expiredSubscription.Default_Payment_Method__c = false;
	    	}
	    	update expiredSubscriptions;
    	}
    	
        // Query Quick Donation Subscriptions to be batched up and processed.
        // To stay within governor limits, we'll pick those with the least-fresh (or non-existant) HMACs first, 
        // and skip any with tokens created within the last day.
        this.subscribers = [
        	SELECT SB_User_Id__c, SB_OCDonate_Token_Expiration__c, SB_OCDonate_Payment_Gateway__c, 
        		SB_OCDonate_CC_Type__c, SB_OCDonate_CC_Exp_Month__c, SB_OCDonate_CC_Exp_Year__c, 
        		SB_OCDonate_CC_Last_4__c, SB_OCDonate_Opt_In_Date__c, SB_OCDonate_Opt_Out_Date__c,
        		SB_OCDonate_Active_Subscription__c,
        		SB_OCDonate_Active_Subscription__r.Payment_Token_Id__c,
        		SB_OCDonate_Active_Subscription__r.Default_Payment_Method__c
        	FROM Contact 
        	WHERE SB_User_Id__c != null AND SB_OCDonate_Active_Subscription__r.Id != null
        		AND (SB_OCDonate_Token_Expiration__c = null OR SB_OCDonate_Token_Expiration__c < :this.tokenExpiration.addDays(-1))
        	ORDER BY SB_OCDonate_Token_Expiration__c ASC
        	LIMIT 25000
        ];
        
        // Onwards!
        return this.subscribers;
    }
    
    global void execute(Database.BatchableContext context, List<Contact> scope) {
        for (Contact subscriber : scope) {
			// Did this subscription expire?
			if (!subscriber.SB_OCDonate_Active_Subscription__r.Default_Payment_Method__c) {
				// For an expired subscription, blank out OCDonate fields on the Contact.
				subscriber.SB_OCDonate_Active_Subscription__c = null;
				subscriber.SB_OCDonate_URL__c = null;
				subscriber.SB_OCDonate_Token_Expiration__c = null;
				subscriber.SB_OCDonate_CC_Exp_Month__c = null;
				subscriber.SB_OCDonate_CC_Exp_Year__c = null;
				subscriber.SB_OCDonate_CC_Last_4__c = null;
				subscriber.SB_OCDonate_CC_Type__c = null;
				subscriber.SB_OCDonate_Payment_Gateway__c = null;
        	} else {
				// Generate the Quick Donate HMAC.
				List<String> parameters = new List<String>();
				parameters.add(subscriber.SB_OCDonate_Active_Subscription__r.Payment_Token_Id__c);
				String message = this.springboard.createHMAC(subscriber.SB_User_Id__c, this.tokenExpiration, 'ocd', parameters);
				// Sign the message and set the quick donate URL segment and expiration.
				String token = this.springboard.signHMAC(message);
				subscriber.SB_OCDonate_URL__c = 'hmac/' + EncodingUtil.base64Encode( Blob.valueOf(message) ) + '/' + token;
				subscriber.SB_OCDonate_Token_Expiration__c = this.tokenExpiration;
			}
        }
        
        // Save the updated contacts.
        update scope;
    }
    
    global void finish(Database.BatchableContext context) {
       
    }
}