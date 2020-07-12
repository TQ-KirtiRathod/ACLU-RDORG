/* Ticket#  Modified Date       Modified By         Description
*  #77028   18th June 2020   Kirti Rathod(SFDO)     Changed the query to find existing preference records
*/
public class trac_HandleDeceasedContacts {
    
    public static Integer contactsAccountsUpdated = 0;
    public static Integer contactsOpportunityUpdated = 0;
    public static Integer contactsEmailUpdated = 0;
    public static Integer contactsPhoneUpdated = 0;
    public static Integer accountsPreferredCreated = 0;
    public static Boolean isRecursive = false;
    
    /*    
        * 
        *updateContactRelatedRecords : It update and creates the contact related object's records like: account, Email, Phone etc
        *@param : newContacts A list of new contacts
        *@param : accountContactId A map with Account Id as key and contact Id as value
        *
    */
    public static void startDeceaseContactProcess(List<Contact> newContacts, Map<Id,Id> accountContactId) {
        
        Boolean isOppAndUserAffiliateSame = true;
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsToUpdate = new List<Contact>();
        Set<Id> accountIdSetToUpdate = new Set<Id>();
        Set<Id> accountIdsToCreatePreference = new Set<Id>();
        Set<String> primaryAffiliates = new Set<String>{'UN - Union National','NN - National Chapters','NGO'};
            
        User user = [SELECT Id, Is_Affiliate_User__c, Primary_Affiliate__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        
        List<Account> accounts = [SELECT Id, rC_Giving__Active_Sustainer__c, All_Contacts_Deceased__c,
                                  rC_Bios__Preferred_Contact__c, rC_Bios__Preferred_Contact__r.Id, 
                                  rC_Bios__Secondary_Contact__c, Is_Email_Salutation_Locked__c
                                  FROM Account 
                                  WHERE Id IN : accountContactId.keySet()];
        
        Savepoint sp = Database.setSavepoint();
        for(Account account : accounts) { 
            Boolean isUpdated = false;
            //Mark Email Solution as False
            if(account.Is_Email_Salutation_Locked__c) {
                account.Is_Email_Salutation_Locked__c = false;
                isUpdated = true;
            }
            
            // Update Account's Pref. and Sec. Contact
            if(account.rC_Bios__Preferred_Contact__r.Id == accountContactId.get(account.Id)) {
                
                if ( account.rC_Bios__Secondary_Contact__c != null) {
                    //Handle to update the secondary contact to avoid issue with recursive RC_Triggers
                    contactsToUpdate.add(new Contact(Id = account.rC_Bios__Secondary_Contact__c, rC_Bios__Secondary_Contact__c = false, rC_Bios__Preferred_Contact__c = true));
                }
                contactsToUpdate.add(new Contact(Id = accountContactId.get(account.Id), rC_Bios__Preferred_Contact__c = false));
                
                //update Account
                account.rC_Bios__Preferred_Contact__c = account.rC_Bios__Secondary_Contact__c;
                account.rC_Bios__Secondary_Contact__c = null;
                isUpdated = true;
                
            }
            
            // Update Opportunity and Active substainer
            if(account.rC_Giving__Active_Sustainer__c && account.All_Contacts_Deceased__c) {
                account.rC_Giving__Active_Sustainer__c = false;
                accountIdSetToUpdate.add(account.Id);
                isUpdated = true;
            }
            
            //Create Account Id set for where All Contact Deceased is true
            if(account.All_Contacts_Deceased__c) {
                accountIdsToCreatePreference.add(account.Id);
                isUpdated = true;
            }

            if(isUpdated) {
                accountsToUpdate.add(account);
            }
        }
        // Update the accounts
        contactsAccountsUpdated = accountsToUpdate.size();
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
        if(!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
        
        // Update Email records
        updateContactRelatedEmailRecords(accountContactId.values());
        
        // Update Phone Records
        updateContactRelatedPhoneRecords(accountContactId.values());
        
        //create preference reocrds
        Id recordTypeId = Schema.SObjectType.rC_Bios__Preference__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        createAccountRelatedPreferenceRecords(accountIdsToCreatePreference, recordTypeId);
        
        List<Opportunity> opportunities = [SELECT Id, StageName, Cancellation_Reason__c, rC_Giving__Affiliation__c
                                           FROM Opportunity 
                                           WHERE AccountId IN :accountIdSetToUpdate
                                           AND (StageName = 'Open' OR StageName = 'Partially Complete'
                                           OR StageName = 'Partially Collected' OR StageName = 'Pending')
                                           AND RecordTypeId IN (SELECT Id FROM RecordType WHERE Name =: 'Pledge')];
        for(Opportunity opp : opportunities) {
            
            if(opp.rC_Giving__Affiliation__c != user.Primary_Affiliate__c) {
                isOppAndUserAffiliateSame = false;
            }
            
            opp.StageName = 'Canceled';
            opp.Cancellation_Reason__c = 'Deceased Donor';
        }
        
        If(opportunities.size() > 0) {
            if((primaryAffiliates.contains(user.Primary_Affiliate__c) && !user.Is_Affiliate_User__c) 
               || (user.Is_Affiliate_User__c && isOppAndUserAffiliateSame) ) {
                   
                   update opportunities;
                   contactsOpportunityUpdated = opportunities.size();
               } else {
                   Database.rollback(sp);
                   throw new trac_Exception('CAN_NOT_UPDATE_NATIONAL_PLEDGE');
               }
        } 
    }
    
    /*    
        * 
        *updateContactRelatedEmailRecords : It updates the contact related email records
        *@param : contactIdSet A set of contact Ids
        *@return : Size of email records updated
        *
    */
    public static void updateContactRelatedEmailRecords(List<Id> contactIdSet) {
        List<Email__c> emailsToUpdate = new List<Email__c>();
        List<Email__c> emails = [SELECT Id, Email_Status__c, Opt_Out_Date__c, 
                                 Opt_In__c, Primary__c
                                 FROM Email__c
                                 WHERE Contact__c IN : contactIdSet];
        
        for(Email__c email : emails) {
            Boolean isUpdated = false;

            // Mark email status as Invalid
            if(!String.isBlank(email.Email_Status__c) && email.Email_Status__c.equalsIgnoreCase('Valid')) {
                email.Email_Status__c = 'Invalid';
                isUpdated = true;
            }
            
            //Mark Opt in false
            if(email.Opt_In__c) {
                email.Opt_In__c = false;
                email.Opt_Out_Date__c = Date.today();
                isUpdated = true;
            }
            
            if(email.Primary__c) {
                email.Primary__c = false;
                isUpdated = true;
            }
            
            if(isUpdated) {
                emailsToUpdate.add(email);
            }
        }
        contactsEmailUpdated = emailsToUpdate.size();
        update emailsToUpdate;
    }
    
    /*    
        * 
        *updateContactRelatedPhoneRecords : It updates the contact related phone records
        *@param : contactIdSet A set of contact Ids
        *@return : Size of phone records updated
        *
    */
    public static void updateContactRelatedPhoneRecords(List<Id> contactIdSet) {
        List<Phone__c> phonesToUpdate = new List<Phone__c>();
        List<Phone__c> phones = [SELECT Id, Phone_Status__c, IsPrimary__c, Universal_SMS_Opt_Out__c
                                 FROM Phone__c
                                 WHERE Contact__c IN : contactIdSet];
        
        for(Phone__c phone : phones) {
            Boolean isUpdated = false;
            
            // Mark email status as Invalid
            if(!String.isBlank(phone.Phone_Status__c) && phone.Phone_Status__c.equalsIgnoreCase('Valid')) {
                phone.Phone_Status__c = 'Invalid';
                isUpdated = true;
            }
            
            //Mark Is primary as false
            if(phone.IsPrimary__c) {
                phone.IsPrimary__c = false;
                isUpdated = true;
            }
            
            //Mark Universal SMS Opt Out as true
            if(!phone.Universal_SMS_Opt_Out__c) {
                phone.Universal_SMS_Opt_Out__c = true;
                isUpdated = true;
            }
            
            if(isUpdated) {
                phonesToUpdate.add(phone);
            }
            
        }
        contactsPhoneUpdated = phonesToUpdate.size();
        update phonesToUpdate;
    }
    
    /*    
        * 
        *createAccountRelatedPreferenceRecords : It creates the account related preference records
        *@param : accountIdsToCreatePreference A set of account Ids to create related records
        *@return : Size of preference records created
        *
    */
    public static void createAccountRelatedPreferenceRecords(Set<Id> accountIdsToCreatePreference, Id recordTypeId) {
        
        List<rC_Bios__Preference__c> preferencesToInsert = new List<rC_Bios__Preference__c>();
        Set<Id> existingPreferenceAccountId = new Set<Id>();
        
        for(rC_Bios__Preference__c preference : [SELECT Id, rC_Bios__Account__c FROM rC_Bios__Preference__c
                                                WHERE rC_Bios__Account__c IN : accountIdsToCreatePreference
                                                AND RecordTypeId =: recordTypeId
                                                AND rC_Bios__Code_Value__c = 'OXXCTNO'
                                                AND rC_Bios__Active__c = true
                                                AND rC_Bios__End_Date__c = null//ACLU : #77028 ::Changed the query to find existing preference records
                                                ]) {
                                                     
            existingPreferenceAccountId.add(preference.rC_Bios__Account__c);
        }
        
        if(!accountIdsToCreatePreference.IsEmpty()) {
            for(Id accId : accountIdsToCreatePreference) {
                If(!existingPreferenceAccountId.contains(accId)) {
                    rC_Bios__Preference__c preference = new rC_Bios__Preference__c();
                    preference.RecordTypeId = recordTypeId;
                    
                    preference.rC_Bios__Code_Value__c = 'OXXCTNO';
                    preference.rC_Bios__Category__c = 'Excludes';
                    preference.rC_Bios__Active__c = true;
                    preference.rC_Bios__Subcategory__c = 'DO NOT Contact in Any Way';
                    preference.rC_Bios__Value__c = 'ORG-DO NOT CONTACT in Any Way';
                    preference.rC_Bios__Start_Date__c = Date.today();
                    preference.rC_Bios__Account__c = accId;
                    preference.rC_Bios__Status__c = 'Confirmed';
                    
                    preferencesToInsert.add(preference);
                    
                }
            }
            accountsPreferredCreated = preferencesToInsert.size();
            insert preferencesToInsert;
        }
    }
}