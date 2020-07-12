/*
*
*Name  :  SB_QueryStrings_Trigger_Email
*Author:  Joel Rothschild
*Date  :  April 18, 2017
*Purpose : Contains methods related to Email to be used along with SpringboardTriggerHandler 
*
*/
public with sharing class SB_QueryStrings_Trigger_Email extends SpringboardTriggerHandler {
	
	public override void onBeforeInsert() {
		// Query all Contacts associated with new Email objects.
		Set<Id> contactIds = new Set<Id>();
		for (Email__c email : (Email__c[]) Trigger.new) {
			contactIds.add(email.Contact__c);
		}
		Map<Id, Contact> contacts = new Map<Id, Contact>([
			SELECT SB_Gift_String_Encrypted__c,
				   GOL_Upgrade_String_Encrypted__c,
				   Renewal_Gift_String_Encrypted__c,
				   Direct_Mail_Appeal_String_Encrypted__c
			FROM Contact WHERE Id IN :contactIds
		]);
		// Update Email objects.
		for (Email__c email : (Email__c[]) Trigger.new) {
			// Copy gift string from Contact.
			email.SB_Gift_String_Encrypted__c = contacts.get(email.Contact__c).SB_Gift_String_Encrypted__c;
			email.GOL_Upgrade_String_Encrypted__c = contacts.get(email.Contact__c).GOL_Upgrade_String_Encrypted__c;
			email.Renewal_Gift_String_Encrypted__c = contacts.get(email.Contact__c).Renewal_Gift_String_Encrypted__c;
			email.Direct_Mail_Appeal_String_Encrypted__c = contacts.get(email.Contact__c).Direct_Mail_Appeal_String_Encrypted__c;

			// Encrypt query string.
			email.SB_Query_String_Encrypted__c = this.sb.encrypt(email.SB_Query_String__c);
		}
	}
	
	public override void onBeforeUpdate() {
		// Encrypt query strings.
		for (Email__c email : (Email__c[]) Trigger.new) {
			email.SB_Query_String_Encrypted__c = this.sb.encrypt(email.SB_Query_String__c);
		}
	}
}