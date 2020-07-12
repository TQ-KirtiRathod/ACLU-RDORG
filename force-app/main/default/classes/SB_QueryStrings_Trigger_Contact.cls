/*
*
*Name  :  SB_QueryStrings_Trigger_Contact
*Author:  Jacksonriver (Joel Rothschild)
*Date  :  Nov 21, 2016
*Purpose : Contains methods related to Contact to be used along with SpringboardTriggerHandler 
*
*/
public with sharing class SB_QueryStrings_Trigger_Contact extends SpringboardTriggerHandler {
    
    public override void onBeforeInsert() {
        this.onBeforeUpdate();
    }
    
    public override void onBeforeUpdate() {
        // loop over all the contacts in the update and encrypt their gift strings
        for (Contact c : (Contact[]) Trigger.new) {
            c.SB_Gift_String_Encrypted__c = this.sb.encrypt('amounts=' + c.SB_Gift_String__c
            +'&recurring_amounts=' + c.SB_Recurring_Gift_String__c);
            c.GOL_Upgrade_String_Encrypted__c = this.sb.encrypt('amounts=' + c.SB_Gift_String__c 
                + '&recurring_amounts=' + c.GOL_Upgrade_String__c);
            c.GOL_Update_String_Encrypted__c = this.sb.encrypt('amounts=' + c.SB_Gift_String__c 
                + '&recurring_amounts=' + c.GOL_Update_String__c);
            c.Renewal_Gift_String_Encrypted__c = this.sb.encrypt('amounts=' + c.Renewal_Gift_String__c 
                                                                 + '&recurring_amounts=' + c.SB_Recurring_Gift_String__c);
            c.Direct_Mail_Appeal_String_Encrypted__c = this.sb.encrypt('amounts=' + c.Direct_Mail_Appeal_String__c
                                                                       + '&recurring_amounts=' + c.SB_Recurring_Gift_String__c);
        }
    }

    public override void onAfterUpdate() {
        // Query all Email objects associated with the updated Contacts.
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        for (Contact c : (Contact[]) Trigger.new) {
            contacts.put(c.Id, c);
        }
        List<Email__c> emails = [
            SELECT SB_Gift_String_Encrypted__c, 
                   SB_Query_String__c, 
                   SB_Query_String_Encrypted__c,
                   GOL_Upgrade_String_Encrypted__c,
                   Renewal_Gift_String_Encrypted__c,
                   Direct_Mail_Appeal_String_Encrypted__c,
                   Contact__c 
            FROM Email__c WHERE Contact__c IN :contacts.keySet() LIMIT 49999
        ];
        // Update Email objects.
        Map<Id, Email__c> emailsToUpdate = new Map<Id, Email__c>();  // To guard against recursion, only DML update when there's an actual change.
        for (Email__c email : emails) {
            // Copy over the encrypted gift string.
            if (email.SB_Gift_String_Encrypted__c != contacts.get(email.Contact__c).SB_Gift_String_Encrypted__c) {
                email.SB_Gift_String_Encrypted__c = contacts.get(email.Contact__c).SB_Gift_String_Encrypted__c;
                emailsToUpdate.put(email.Id, email);
            }
            
            if (email.GOL_Upgrade_String_Encrypted__c != contacts.get(email.Contact__c).GOL_Upgrade_String_Encrypted__c) {
                email.GOL_Upgrade_String_Encrypted__c = contacts.get(email.Contact__c).GOL_Upgrade_String_Encrypted__c;
                emailsToUpdate.put(email.Id, email);
            }
            if (email.Renewal_Gift_String_Encrypted__c != contacts.get(email.Contact__c).Renewal_Gift_String_Encrypted__c) {
                email.Renewal_Gift_String_Encrypted__c = contacts.get(email.Contact__c).Renewal_Gift_String_Encrypted__c;
                emailsToUpdate.put(email.Id, email);
            }
            if (email.Direct_Mail_Appeal_String_Encrypted__c != contacts.get(email.Contact__c).Direct_Mail_Appeal_String_Encrypted__c) {
                email.Direct_Mail_Appeal_String_Encrypted__c = contacts.get(email.Contact__c).Direct_Mail_Appeal_String_Encrypted__c;
                emailsToUpdate.put(email.Id, email);
            }

            // Encrypt the query string.
            String queryStringEncrypted = this.sb.encrypt(email.SB_Query_String__c);
            if (email.SB_Query_String_Encrypted__c != queryStringEncrypted) {
                email.SB_Query_String_Encrypted__c = queryStringEncrypted;
                emailsToUpdate.put(email.Id, email);
            }
        }
        if (!emailsToUpdate.isEmpty()) {
            update emailsToUpdate.values();
        }
    }
}