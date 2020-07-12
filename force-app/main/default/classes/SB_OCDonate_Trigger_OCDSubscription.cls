/*
*
*Name  :  SB_OCDonate_Trigger_OCDSubscription
*Author:  Jacksonriver (Joel Rothschild)
*Date  :  Feb 17, 2017
*Purpose : Contains method to populate subscription details on contact when One_Click_Donate_Subscription__c is created
*
*/
public with sharing class SB_OCDonate_Trigger_OCDSubscription extends SpringboardTriggerHandler {
	
	public override void onAfterInsert() {
		List<Id> contactIds = new List<Id>();
		List<One_Click_Donate_Subscription__c> nonDefaultSubscriptions = new List<One_Click_Donate_Subscription__c>();
	    for (One_Click_Donate_Subscription__c subscription : (One_Click_Donate_Subscription__c[]) Trigger.new) {
	    	contactIds.add(subscription.Contact__c);
	    	if (!subscription.Default_Payment_Method__c) {
				nonDefaultSubscriptions.add(subscription);
			}
	    }
	    Map<Id, Contact> contacts = new Map<Id, Contact>([
	    	SELECT SB_OCDonate_CC_Exp_Month__c, SB_OCDonate_CC_Exp_Year__c, SB_OCDonate_Payment_Gateway__c, 
	    		SB_OCDonate_CC_Last_4__c, SB_OCDonate_CC_Type__c, SB_OCDonate_Active_Subscription__c, 
	    		SB_OCDonate_Token_Expiration__c, SB_OCDonate_URL__c
	    	FROM Contact
	    	WHERE Id IN :contactIds
	    ]);
	    // Blank the opt-outs first.
	    for (One_Click_Donate_Subscription__c subscription : nonDefaultSubscriptions) {
	    	Contact contact = contacts.get(subscription.Contact__c);
	    	if (contact.SB_OCDonate_Active_Subscription__c == subscription.Id) {
		    	contact.SB_OCDonate_Active_Subscription__c = null;
		    	contact.SB_OCDonate_URL__c = null;
		    	contact.SB_OCDonate_Token_Expiration__c = null;
		    	contact.SB_OCDonate_CC_Exp_Month__c = null;
		    	contact.SB_OCDonate_CC_Exp_Year__c = null;
		    	contact.SB_OCDonate_CC_Last_4__c = null;
		    	contact.SB_OCDonate_CC_Type__c = null;
		    	contact.SB_OCDonate_Payment_Gateway__c = null;
	    	}
	    }
	    // Propagate the data from active default subscriptions.
	    for (One_Click_Donate_Subscription__c subscription : (One_Click_Donate_Subscription__c[]) Trigger.new) {
	    	Contact contact = contacts.get(subscription.Contact__c);
	    	if (subscription.Default_Payment_Method__c) {
		    	// Propagate subscription details to contact.
		    	contact.SB_OCDonate_Active_Subscription__c = subscription.Id;
		    	String expMonth = String.valueOf(Integer.valueOf(subscription.CC_Exp_Month__c));  // string representation, no decimals
		    	if (expMonth != null && expMonth.length() > 2) { expMonth = expMonth.substring(expMonth.length() - 2); }  // limit to 2 characters
		    	contact.SB_OCDonate_CC_Exp_Month__c = (expMonth == null) ? '' : expMonth;
		    	String expYear = String.valueOf(Integer.valueOf(subscription.CC_Exp_Year__c));  // string representation, no decimals
		    	if (expYear != null && expYear.length() > 4) { expYear = expYear.substring(expYear.length() - 4); }  // limit to 4 characters
		    	contact.SB_OCDonate_CC_Exp_Year__c = (expYear == null) ? '' : expYear;
		    	contact.SB_OCDonate_CC_Last_4__c = subscription.CC_Last_4__c;
		    	contact.SB_OCDonate_CC_Type__c = subscription.CC_Type__c;
		    	contact.SB_OCDonate_Payment_Gateway__c = subscription.Payment_Gateway__c;
	    	}
	    }
	    // Save the updated contacts.
	    update contacts.values();
	}
	
	public override void onAfterUpdate() {
		this.onAfterInsert();
	}
}