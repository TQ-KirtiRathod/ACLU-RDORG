/*
*
*Name  :  SB_Sustainers_Trigger_SustainerUpgrade
*Author:  Jacksonriver (Joel Rothschild)
*Date  :  April 06, 2017
*Purpose : Sprinboard class to set SB_Last_Sustainer_Upgrade_Date__c and SB_Last_Sustainer_Upgrade_Successful__c on contacts. 
*          Works along with SpringboardTriggerHandler.
*
*/
public with sharing class SB_Sustainers_Trigger_SustainerUpgrade extends SpringboardTriggerHandler {
	
	public override void onAfterInsert() {
	    Map<Id, DateTime> contactIdToLatestTimestamp = new Map<Id, DateTime>();
	    Map<Id, Boolean> contactIdToLatestSuccess = new Map<Id, Boolean>();
	    for (Sustainer_Upgrade__c upgrade : (Sustainer_Upgrade__c[]) Trigger.new) {
	        if (upgrade.Contact__c != NULL && (contactIdToLatestTimestamp.get(upgrade.Contact__c) == NULL 
	            || contactIdToLatestTimestamp.get(upgrade.Contact__c) < upgrade.Timestamp__c)
	        ) {
	            contactIdToLatestTimestamp.put(upgrade.Contact__c, upgrade.Timestamp__c);
	            contactIdToLatestSuccess.put(upgrade.Contact__c, String.isBlank(upgrade.Failure_Flag__c));
	        }
	    }
	    if (contactIdToLatestTimestamp.size() > 0) {
	        // Query and update the relevant Contact records.
	        List<Contact> contacts = [
	            SELECT SB_Last_Sustainer_Upgrade_Date__c, SB_Last_Sustainer_Upgrade_Successful__c
	            FROM Contact WHERE Id IN :contactIdToLatestTimestamp.keySet() 
	        ];
	        for (Contact contact : contacts) {
	            if (contact.SB_Last_Sustainer_Upgrade_Date__c == null 
	                || contactIdToLatestTimestamp.get(contact.Id) > contact.SB_Last_Sustainer_Upgrade_Date__c
	            ) {
	                contact.SB_Last_Sustainer_Upgrade_Date__c = contactIdToLatestTimestamp.get(contact.Id);
	                contact.SB_Last_Sustainer_Upgrade_Successful__c = contactIdToLatestSuccess.get(contact.Id);
	            }
	        }
	        update contacts;
	    }
	}
}