/*
*
*Name  :  ACLUMergeManager
*Author:  Dave Seidman
*Date  :  May 14, 2019
*Purpose : Methods supporting the ACLUMerge class, which governs behavior on Duplicate Manager merge actions
*
*/

public with sharing class ACLUMergeManager {

    public static final String LEGACY_DUPLICATE_PREFCODE = 'OXXCTNO';
    public static final Date LEGACY_DUPLICATE_PREFCODE_DUMMY_END_DATE = Date.newInstance(2020, 12, 31);
    public static final Set<String> PRESERVE_ALL_PREFCODES = new Set<String>{'MM'};
    public static final Set<String> PRESERVE_MOST_RECENT_PREFCODES = new Set<String>{'NREIDPRO'};
    public static final Map<String,String> accountLockedSalutationFieldsMap = new Map<String,String>{'Is_Email_Salutation_Locked__c'=>'Default_Email_Salutation__c', 
                                                                                                     'Is_Formal_Inside_Locked__c'=>'Formal_Inside__c', 
                                                                                                     'Is_Formal_Outside_1_Locked__c'=>'Formal_Outside_1__c', 
                                                                                                     'Is_Formal_Outside_2_Locked__c'=>'Formal_Outside_2__c', 
                                                                                                     'Is_Formal_Outside_3_Locked__c'=>'Formal_Outside_3__c',
                                                                                                     'Is_Informal_Inside_Locked__c'=>'Informal_Inside__c', 
                                                                                                     'Is_Informal_Outside_1_Locked__c'=>'Informal_Outside_1__c', 
                                                                                                     'Is_Informal_Outside_2_Locked__c'=>'Informal_Outside_2__c', 
                                                                                                     'Is_Informal_Outside_3_Locked__c'=>'Informal_Outside_3__c',
                                                                                                     'Is_Recognition_Formal_Locked__c'=>'Recognition_Formal__c', 
                                                                                                     'Is_Recognition_Informal_Locked__c'=>'Recognition_Informal__c'};

    public static Account lockedAffiliateAccount;

    private class CustomMergeException extends Exception { }


    public static Map<String, Boolean> triggersDisabledMap = new Map<String, Boolean>();

/**
 * ACCOUNT MERGE METHODS
 * 
 *
 * 
 *             
 */

    public static void accountBeforeMerge_updateAccountAddresses(Account masterAccount, List<Account> mergedAccountList) {
        rC_Bios__Account_Address__c preferredAddress;
        Map <Id, rC_Bios__Account_Address__c> addressesToUpdateMap = new Map<Id, rC_Bios__Account_Address__c>();
        List <rC_Bios__Account_Address__c> masterAccountAddresses = [SELECT id, rC_Bios__Preferred_Billing__c, rC_Bios__Preferred_Shipping__c, LastModifiedDate, CreatedDate
            FROM rC_Bios__Account_Address__c 
            WHERE rC_Bios__Account__c = :masterAccount.id AND Address_Status__c = 'Valid'
            ORDER BY LastModifiedDate DESC];
        
        /** If the master account has a preferred address, use it, and no need to update the Account Address record
        //  If the master account has a non-preferred address and none has been established for the account, it might
        //  wind up being the preferred address, so add it to the map of addresses to update
        **/
        for (rC_Bios__Account_Address__c accountAddress : masterAccountAddresses) {
            if (preferredAddress == NULL && accountAddress.rC_Bios__Preferred_Billing__c == true) {
                preferredAddress = accountAddress;
            } else {
                addressesToUpdateMap.put(accountAddress.Id, accountAddress);
            }
        }   

        List<Id> mergedAccountIds = new List<Id>();
            
        for (Account mergedAccount : mergedAccountList) {
            mergedAccountIds.add(mergedAccount.Id);
        }

        // CreatedDate sort not necessary in prod execution, but aids in testing since
        // it is far easier to mock create date values for test data than last modified date, 
        // and the latter will likely be equal among test addresses
        List <rC_Bios__Account_Address__c> mergedAccountAddresses = [SELECT id, rC_Bios__Preferred_Billing__c, rC_Bios__Preferred_Shipping__c, LastModifiedDate, CreatedDate
            FROM rC_Bios__Account_Address__c 
            WHERE rC_Bios__Account__c IN :mergedAccountIds AND Address_Status__c = 'Valid'
            ORDER BY LastModifiedDate DESC, CreatedDate DESC];
        
        /** If the preferred address has been established, subsequent addresses should be set to non-preferred
        //  If the preferred address has not been established, an existing non-preferred address might still
        //  wind up being the preferred address.
        //  If the preferred address has not been established, the first preferred address encountered (by last mod date)
        //  will become the the preferred address.
        **/
        for (rC_Bios__Account_Address__c accountAddress : mergedAccountAddresses) {
            if (preferredAddress != NULL || accountAddress.rC_Bios__Preferred_Billing__c == FALSE) {
                addressesToUpdateMap.put(accountAddress.Id, accountAddress);
            }
            else if (preferredAddress == NULL && accountAddress.rC_Bios__Preferred_Billing__c == TRUE) {
                preferredAddress = accountAddress;                
            }
        }

        /** If the preferred address has still not been established, the most recently created or modified non-preferred
        //  address will become the preferred address.
        **/
        if (preferredAddress == NULL && !mergedAccountAddresses.isEmpty() && !masterAccountAddresses.isEmpty()) {
            preferredAddress = ((mergedAccountAddresses[0].lastModifiedDate > masterAccountAddresses[0].lastModifiedDate) ||
                                ((mergedAccountAddresses[0].lastModifiedDate == masterAccountAddresses[0].lastModifiedDate) && 
                                  mergedAccountAddresses[0].createdDate > masterAccountAddresses[0].createdDate)) ?
                                     mergedAccountAddresses[0] : masterAccountAddresses[0];
            preferredAddress.rC_Bios__Preferred_Billing__c = TRUE;
            preferredAddress.rC_Bios__Preferred_Shipping__c = TRUE;
            addressesToUpdateMap.put(preferredAddress.Id, preferredAddress);
        }
        
        /** Ensure all of the previous preferred addresses that are not the new master preferred address
        //  are set as non-preferred.
        **/
        List <rC_Bios__Account_Address__c> addressesToUpdate = addressesToUpdateMap.values();
        for (rC_Bios__Account_Address__c addressToUpdate : addressesToUpdate) {
            if (preferredAddress != NULL && addressToUpdate.Id != preferredAddress.Id) {
                addressToUpdate.rC_Bios__Preferred_Billing__c = FALSE;
                addressToUpdate.rC_Bios__Preferred_Shipping__c = FALSE;
            }
        }

        update addressesToUpdate;
    }
     
    public static void accountBeforeMerge_updateContacts(Account masterAccount, List<Account> mergedAccountList) {
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Id> mergedAccountIds = new List<Id>();

        for (Account acct : mergedAccountList) {
            mergedAccountIds.add(acct.Id);
        }

        List<Contact> mergedAccountsPreferredOrSecondaryContacts = [SELECT id, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, LastModifiedDate
            FROM Contact
            WHERE AccountId IN :mergedAccountIds AND 
                (rC_Bios__Preferred_Contact__c = TRUE OR rC_Bios__Secondary_Contact__c = TRUE)
            ORDER BY LastModifiedDate DESC, CreatedDate DESC];
         
        /** HANDLE CONTACTS' PREFERRED CONTACT FIELD **/
        /*  If Master Account has a preferred contact, then none of the merged contacts' should be marked Preferred */
        if (masterAccount.rC_Bios__Preferred_Contact__c != NULL) {
            for (Contact con : mergedAccountsPreferredOrSecondaryContacts) {
                if (con.rC_Bios__Preferred_Contact__c == TRUE) {
                    con.rC_Bios__Preferred_Contact__c = FALSE;
                    contactsToUpdate.add(con);
                }
            }
        }
        /*  If Master Account does not have a preferred contact, then the most recently modified merged contact
            will be marked preferred */
        else {
            Boolean preferredContactSet = false;
            for (Contact con : mergedAccountsPreferredOrSecondaryContacts) {
                if (con.rC_Bios__Preferred_Contact__c == TRUE) {
                    if (!preferredContactSet) {
                        preferredContactSet = TRUE;
                    }
                    else {
                        con.rC_Bios__Preferred_Contact__c = FALSE;
                        contactsToUpdate.add(con);
                    }
                }
            }
        }

        /** HANDLE CONTACTS' SECONDARY CONTACT FIELD **/
        /*  If Master Account has a secondary contact, then none of the merged contacts' should be marked Secondary */
        if (masterAccount.rC_Bios__Secondary_Contact__c != NULL) {
            for (Contact con : mergedAccountsPreferredOrSecondaryContacts) {
                if (con.rC_Bios__Secondary_Contact__c == TRUE) {
                    con.rC_Bios__Secondary_Contact__c = FALSE;
                    contactsToUpdate.add(con);
                }
            }
        }
        /*  If Master Account does not have a secondary contact, then the most recently modified merged secondary contact
            will be marked Secondary for the account by virtue of setting other secondary vals to false*/
        else {
            Boolean secondaryContactSet = FALSE;
            for (Contact con : mergedAccountsPreferredOrSecondaryContacts) {
                if (con.rC_Bios__Secondary_Contact__c) {
                    if (!secondaryContactSet) {
                        secondaryContactSet = TRUE;
                    }
                    else {
                        con.rC_Bios__Secondary_Contact__c = FALSE;
                        contactsToUpdate.add(con);
                    }
                }
            }
        }

        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    public static void accountBeforeMerge_updatePaymentMethods(Account masterAccount, List<Account> mergedAccountList) {
        List<rC_Giving__Payment_Method__c> paymentMethodsToUpdate = new List<rC_Giving__Payment_Method__c>();
        List<Id> allAccountIds = new List<Id>();
        allAccountIds.add(masterAccount.Id);

        for (Account acct : mergedAccountList) {
            allAccountIds.add(acct.Id);
        }

        List<rC_Giving__Payment_Method__c> mergedAccountsPaymentMethods = [SELECT Id, rC_Giving__Is_Default__c, CreatedDate
            FROM rC_Giving__Payment_Method__c
            WHERE rC_Giving__Account__c IN :allAccountIds
            ORDER BY rC_Giving__Is_Default__c DESC, CreatedDate DESC];
         
        if (!mergedAccountsPaymentMethods.IsEmpty()) {
            Boolean defaultPaymentMethodSet = FALSE;
            for (rC_Giving__Payment_Method__c pm : mergedAccountsPaymentMethods) {
                if (!defaultPaymentMethodSet && pm.rC_Giving__Is_Default__c == TRUE) {
                    defaultPaymentMethodSet = TRUE;
                }
                else if (defaultPaymentMethodSet && pm.rC_Giving__Is_Default__c == TRUE) {
                    pm.rC_Giving__Is_Default__c = FALSE;
                    paymentMethodsToUpdate.add(pm);
                }
            }
        }
       
        if(!paymentMethodsToUpdate.isEmpty()) {
            update paymentMethodsToUpdate;
        }
    }

    public static void accountBeforeMerge_handleLockAffiliateSetting(Account masterAccount, List<Account> mergedAccountList) {
        lockedAffiliateAccount = setLockedAccountOrFailMerge(masterAccount, mergedAccountList);
    }

    public static void accountBeforeMerge_handleLockedSalutations(Account masterAccount, List<Account> mergedAccountList) {
        Set<String> masterLockedSalFields;
        Map<Id,Set<String>> mergedLockedSalFieldsMap = new Map<Id,Set<String>>();
        for (Account mergedAccount : mergedAccountList) {
            Set<String> mergedLockedSalFields = getAccountLockedSalutationFields(mergedAccount);
            if (!mergedLockedSalFields.isEmpty()) {
                mergedLockedSalFieldsMap.put(mergedAccount.Id,mergedLockedSalFields);
            }
        }  
        if (mergedLockedSalFieldsMap.isEmpty()) {
            return;
        }       
        else {
            masterLockedSalFields = getAccountLockedSalutationFields(masterAccount);
            for (String salBoolField : accountLockedSalutationFieldsMap.keySet()) {
                if (masterLockedSalFields.contains(salBoolField)) {
                    continue;
                }
                else {
                    for (Account mergedAccount : mergedAccountList) {
                        //Map<Id,Datetime> mergedAccount
                        Set<String> mergedLockedSalFields = mergedLockedSalFieldsMap.get(mergedAccount.Id);
                        if(mergedLockedSalFields != null && mergedLockedSalFields.contains(salBoolField)) {
                            String salStringField  = accountLockedSalutationFieldsMap.get(salBoolField);
                            String salStringFieldValue = (String)mergedAccount.get(salStringField);
                            masterAccount.put(salStringField, salStringFieldValue);
                        }
                    }
                }
            }
        }
    }

    public static void accountAfterMerge_deleteDuplicateAccountAddresses(Id masterAccountId) {
        List<rC_Bios__Account_Address__c> accountAddresses = [SELECT Id, rc_Bios__Address__r.rC_Bios__Unique_MD5__c 
            FROM rC_Bios__Account_Address__c 
            WHERE rc_Bios__Account__c = :masterAccountId 
            ORDER BY rc_Bios__Preferred_Billing__c DESC, rC_Bios__Active__c DESC, LastModifiedDate DESC];
        
        List<rC_Bios__Account_Address__c> duplicateAddressesToDelete = new List<rC_Bios__Account_Address__c>();
        Set<String> md5Vals = new Set<String>();

        for (rC_Bios__Account_Address__c address : accountAddresses) {
            SYSTEM.DEBUG('MD5: ' + address.rc_Bios__Address__r.rC_Bios__Unique_MD5__c);
            if (md5Vals.contains(address.rc_Bios__Address__r.rC_Bios__Unique_MD5__c)) {
                duplicateAddressesToDelete.add(address);
            }
            else {
                md5Vals.add(address.rc_Bios__Address__r.rC_Bios__Unique_MD5__c);
            }
        }

        if (!duplicateAddressesToDelete.isEmpty()) {
            // ensure rC setting to delete contact addresses is turned off for user so that
            // additional account addresses are not also deleted
            updateAccountAddressSettings(); 

            delete duplicateAddressesToDelete;
        }
    }

    public static void accountAfterMerge_deleteDuplicateAccountTeams(Id masterAccountId) {
        List<Account_Team__c> accountTeams = [SELECT Id, End_Date__c, Start_Date__c, Status__c, Team_Member__c, Team_Role__c from Account_Team__c
            WHERE Account__c = :masterAccountId 
            ORDER BY LastModifiedDate DESC];
        
        List<Account_Team__c> duplicateAccountTeamsToDelete = new List<Account_Team__c>();
        Set<String> teamDetails = new Set<String>();

        for (Account_Team__c team : accountTeams) {
            String teamDetail = team.Team_Member__c + team.Team_Role__c + team.Status__C + team.Start_Date__c + team.End_Date__c;
            if (teamDetails.contains(teamDetail)) {
                duplicateAccountTeamsToDelete.add(team);
            }
            else {
                teamDetails.add(teamDetail);
            }
        }

        if (!duplicateAccountTeamsToDelete.isEmpty()) {
            delete duplicateAccountTeamsToDelete;
        }
    }

    public static void accountAfterMerge_handleDuplicatePreferences(Id masterAccountId) {
        List<rC_Bios__Preference__c> preferences = [SELECT Id, rC_Bios__Code_Value__c, rC_Bios__Category__c, rC_Bios__Start_Date__c, rC_Bios__End_Date__c, CreatedDate
            FROM rC_Bios__Preference__c 
            WHERE rC_Bios__Active__c = TRUE AND rc_Bios__Account__c = :masterAccountId
            ORDER BY rC_Bios__Start_Date__c ASC];

        PreferenceWrapper[] pwPrefsSortedMostRecent = new List<PreferenceWrapper>();
        
        List<rC_Bios__Preference__c> duplicatePreferencesToDelete = new List<rC_Bios__Preference__c>();

        Set<String> preferenceValues = new Set<String>();

        for (rC_Bios__Preference__c pref : preferences) {
            String prefValue = pref.rc_Bios__Code_Value__c + pref.rc_Bios__Category__c;
            if (pref.rc_Bios__Code_Value__c == LEGACY_DUPLICATE_PREFCODE && pref.rC_Bios__End_Date__c == LEGACY_DUPLICATE_PREFCODE_DUMMY_END_DATE) {
                duplicatePreferencesToDelete.add(pref);
                continue;
            }
            if (PRESERVE_ALL_PREFCODES.contains(pref.rc_Bios__Code_Value__c)) {
                continue;
            }
            system.debug('PRESERVE_MOST_RECENT_PREFCODES ' + PRESERVE_MOST_RECENT_PREFCODES );
            system.debug('CURRENT PREF CODE ' + pref.rc_Bios__Code_Value__C);
            if (PRESERVE_MOST_RECENT_PREFCODES.contains(pref.rc_Bios__Code_Value__C)) {
                pwPrefsSortedMostRecent.add(new PreferenceWrapper(pref));
                continue;
            }
            if (preferenceValues.contains(prefValue)) {
                duplicatePreferencesToDelete.add(pref);
            }
            else {
                preferenceValues.add(prefValue);
            }
        }

       if (!pwPrefsSortedMostRecent.isEmpty()) {
           pwPrefsSortedMostRecent.sort();
           preferenceValues.clear();
           for (PreferenceWrapper pw : pwPrefsSortedMostRecent) {

               /*** DEBUG */
                system.debug('START DATE: ' + pw.p.rC_Bios__Start_Date__c);



               String prefValue = pw.p.rc_Bios__Code_Value__c + pw.p.rc_Bios__Category__c;

               if (preferenceValues.contains(prefValue)) {
                   duplicatePreferencesToDelete.add(pw.p);
               }
               else {
                   preferenceValues.add(prefValue);
               }
            }
       }

       if (!duplicatePreferencesToDelete.isEmpty()) {
           delete duplicatePreferencesToDelete;
       }
    }

    public static void accountAfterMerge_handleLockAffiliateSetting(Account masterAccount) {
        if (lockedAffiliateAccount != NULL && lockedAffiliateAccount.Id != masterAccount.Id) {
            masterAccount.Chapter__c = lockedAffiliateAccount.Chapter__c;
            masterAccount.Affiliation__c = lockedAffiliateAccount.Affiliation__c;
            masterAccount.Lock_Affiliation__c = TRUE;
            update masterAccount;
        }
    }

    public static Id accountAfterMerge_scheduleMergeContacts(Id masterRecordId, Set<Id> allRecordIds) {
        Integer contactDelay = System.Label.DCMerge_ContactDelay.isNumeric() ? Integer.valueOf(System.Label.DCMerge_ContactDelay) : 10;
        Datetime futureTime = Datetime.now().addSeconds(contactDelay);
        String hour = String.valueOf(futureTime.hour());
        String min = String.valueOf(futureTime.minute()); 
        String ss =  String.valueOf(futureTime.second());
        String fireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        ACLUMergeScheduleContactMerge contactMerge = new ACLUMergeScheduleContactMerge(allRecordIds);
        Id mergeContactsJobId = System.schedule('DC Merge Contacts | ' + masterRecordId + '|' + allRecordIds.iterator().next(), fireTime, contactMerge);
        return mergeContactsJobId;
    }

    //TODO - Future enhancement - all of this code except for the actual merge could be moved tot he the scheduleMergeContact method, to cut down on scheduled jobs
    public static void accountAfterMerge_mergeContacts(Set<Id> accountIds) {
        Map<String,List<Contact>> listOfContactListsToMerge = new Map<String,List<Contact>>();
        Set<Id> contactIdsToMerge = new Set<Id>();
        List<Contact> accountContacts = getChildContacts(accountIds);
        if (!accountContacts.isEmpty()) {
            for (Contact c : accountContacts) {
                String matchKey = c.FirstName.left(3) + c.LastName;
                if (!listOfContactListsToMerge.keySet().contains(matchKey)) {
                    listOfContactListsToMerge.put(matchKey, new List<Contact>{c});
                }
                else {
                    List<Contact> matchContactList = listOfContactListsToMerge.get(matchKey);
                    matchContactList.add(c);
                    listOfContactListsToMerge.put(matchKey,matchContactList);
                }
            }
        }
        if (!listOfContactListsToMerge.isEmpty()) {
            Dupcheck.dc3Api dcAPI = new Dupcheck.dc3Api();
            for (List<Contact> contactsToMerge : listOfContactListsToMerge.values()) {
                if (contactsToMerge.size() > 1) {
                    if (!System.isScheduled()) {
                        dcAPI.doMerge(contactsToMerge);
                    }
                    else {
                        try {
                            dcAPI.doMerge(contactsToMerge);
                        }
                        catch(dupcheck.dc3Exception.MergeException me) {
                            logMergeError(contactsToMerge, me);
                            return;
                        }
                    }
                }
            }
        }
    }

    @TestVisible
    private static void logMergeError(List<SObject> objs, dupcheck.dc3Exception.MergeException me) {
        String idString = '';
        for(SObject obj : objs)
            {
                idString += obj.Id + ' ';
            }
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('ACLUMerge','mergeFailed',idString+'| ' + me.getMessage(),LoggingLevel.FINEST);
        log.logException(me);
        log.saveLogs();
        return;
    }

    @TestVisible
    private static void updateAccountAddressSettings() {
        Id currentUserId = UserInfo.getUserId();
        List<rC_Bios__Account_Address_Setting__c> aaSetting = [select CreatedById, CreatedDate, Id, IsDeleted, LastModifiedById, 
                                                        LastModifiedDate, Name, rC_Bios__Disable_DeleteContactAddress__c 
                                                        from rC_Bios__Account_Address_Setting__c where SetupOwnerId = :currentUserId];

        if (aaSetting.isEmpty()) {
            rC_Bios__Account_Address_Setting__c newAASetting = new rC_Bios__Account_Address_Setting__c(
                    rC_Bios__Disable_DeleteContactAddress__c = TRUE,
                    SetupOwnerId = currentUserId);
            insert newAASetting;
        }
        else {
            if (aaSetting[0].rC_Bios__Disable_DeleteContactAddress__c == FALSE) {
                aaSetting[0].rC_Bios__Disable_DeleteContactAddress__c = TRUE;
                update aaSetting[0];
            }
        }
    }

    public static Set<String> getAccountLockedSalutationFields(Account a) {
        Set<String> accountLockedSalutationFields = new Set<String>();
        for (String accountLockedSalutationFlag : accountLockedSalutationFieldsMap.keySet()) {
            if ((Boolean)a.get(accountLockedSalutationFlag) == TRUE) {
                accountLockedSalutationFields.add(accountLockedSalutationFlag);
            }
        }
        return accountLockedSalutationFields;       
    }

    private static Account setLockedAccountOrFailMerge(Account masterAccount, List<Account> mergedAccountList) {
        Integer lockedAffiliateCount = 0;
        Account lockedAffiliateAccount;
        List<Account> combinedAccounts = mergedAccountList;
        combinedAccounts.add(masterAccount);
        
        for (Account a : combinedAccounts) {
            if (a.Lock_Affiliation__c == TRUE) {
                lockedAffiliateCount++;

                // if two accounts are locked and don't share the same affiliation, stop the merge
                // if multiple accounts are locked and share the same affiliation, choose the account last modified
                if (lockedAffiliateCount > 1 && a.Affiliation__c != lockedAffiliateAccount.Affiliation__c) {
                    lockedAffiliateAccount = NULL;
                    system.debug('FAIL THE MERGE');
                    throw new CustomMergeException('Multiple locked accounts have different affiliates');
                }
                else if (lockedAffiliateCount > 1 && a.Affiliation__c == lockedAffiliateAccount.Affiliation__c) {
                    lockedAffiliateAccount = (lockedAffiliateAccount.lastModifiedDate > a.lastModifiedDate) ?
                        lockedAffiliateAccount : a;
                    // for testing purposes; can't test on lastModifiedDate without using Test.loadData, which 
                    // we're not currently doing (but ideally should); we can easily mock CreatedDate, however
                    if(Test.isRunningTest()) {
                        lockedAffiliateAccount = (lockedAffiliateAccount.CreatedDate > a.CreatedDate) ?
                        lockedAffiliateAccount : a;
                    }
                }
                else if (lockedAffiliateCount == 1) {
                    lockedAffiliateAccount = a;
                }
            }
        }
        return lockedAffiliateAccount;
    }

    /* wrapper used so that Preference list can be sorted by date using a custom sort */
    public class PreferenceWrapper implements Comparable {
        private rC_Bios__Preference__c p;
        private Datetime prefCreatedDate;
        public PreferenceWrapper(rC_Bios__Preference__c p) {
            this.p = p;
            this.prefCreatedDate = p.createdDate;
        }

        public Integer compareTo(Object compareTo) {
            PreferenceWrapper pW = (PreferenceWrapper) compareTo;
            if (pW.prefCreatedDate > this.p.createdDate) return +1;
            if (pw.prefCreatedDate < this.p.createdDate) return -1;
            return 0; 
        }
    }

    /*
    * 
    * This may be a performance hit in a mass merge since we have to do a get describe on Contact for every single merge
    * TODO look into caching
    */
    private static List<Contact> getChildContacts(Set<Id> accountIds) {
        List<Contact> contacts = new List<Contact>();

        // Initialize setup variables
        String query = Utilities.getQueryOfAllFields('Contact');
        query += ' where AccountId in :accountIds';
        
        try {
            contacts = database.query(query);
        } catch (QueryException e){
            //perform exception handling
        }

        return contacts;
    }



/**
 * CONTACT MERGE METHODS
 * 
 *
 * 
 *             
 */

    public static void contactBeforeMerge_updatecontactAddresses(Contact masterContact, List<Contact> mergedContactList) {
        rC_Bios__Contact_Address__c preferredAddress;
        Map <Id, rC_Bios__Contact_Address__c> addressesToUpdateMap = new Map<Id, rC_Bios__Contact_Address__c>();
        List <rC_Bios__contact_Address__c> masterContactAddresses = [SELECT id, rC_Bios__Preferred_Mailing__c, rC_Bios__Preferred_Other__c, LastModifiedDate, CreatedDate
            FROM rC_Bios__Contact_Address__c 
            WHERE rC_Bios__Contact__c = :masterContact.id AND Address_Status__c = 'Valid'
            ORDER BY LastModifiedDate DESC];
        
        /** If the master contact has a preferred address, use it, and no need to update the contact Address record
        //  If the master contact has a non-preferred address and none has been established for the contact, it might
        //  wind up being the preferred address, so add it to the map of addresses to update
        **/
        for (rC_Bios__contact_Address__c contactAddress : masterContactAddresses) {
            if (preferredAddress == NULL && contactAddress.rC_Bios__Preferred_Mailing__c == true) {
                preferredAddress = contactAddress;
            } else {
                addressesToUpdateMap.put(contactAddress.Id, contactAddress);
            }
        }

        List<Id> mergedcontactIds = new List<Id>();
        for (contact mergedContact : mergedContactList) {
            mergedContactIds.add(mergedContact.Id);
        }

        List <rC_Bios__Contact_Address__c> mergedContactAddresses = [SELECT id, rC_Bios__Preferred_Mailing__c, rC_Bios__Preferred_Other__c, CreatedDate, LastModifiedDate
            FROM rC_Bios__Contact_Address__c 
            WHERE rC_Bios__Contact__c IN :mergedContactIds AND Address_Status__c = 'Valid'
            ORDER BY LastModifiedDate, CreatedDate DESC];
        
        /** If the preferred address has been established, subsequent addresses should be set to non-preferred
        //  If the preferred address has not been established, an existing non-preferred address might still
        //  wind up being the preferred address.
        //  If the preferred address has not been established, the first preferred address encountered (by last mod date)
        //  will become the the preferred address.
        **/
        for (rC_Bios__contact_Address__c contactAddress : mergedcontactAddresses) {
            if (preferredAddress != NULL || !contactAddress.rC_Bios__Preferred_Mailing__c) {
                addressesToUpdateMap.put(contactAddress.Id, contactAddress);
            }
            else if (preferredAddress == NULL && contactAddress.rC_Bios__Preferred_Mailing__c) {
                preferredAddress = contactAddress;                
            }
        }

        /** If the preferred address has still not been established, the most recently created or modified non-preferred
        //  address will become the preferred address.
        **/
        if (preferredAddress == NULL && !mergedContactAddresses.isEmpty() && !masterContactAddresses.isEmpty()) {       
            preferredAddress = (mergedContactAddresses[0].lastModifiedDate > masterContactAddresses[0].lastModifiedDate) ?
                mergedContactAddresses[0] : mastercontactAddresses[0];
           // for testing purposes; can't test on lastModifiedDate without using Test.loadData, which 
           // we're not currently doing (but ideally should); we can easily mock CreatedDate, however
            if(Test.isRunningTest()) {
                preferredAddress = (mergedContactAddresses[0].createdDate > masterContactAddresses[0].createdDate) ?
                                    mergedContactAddresses[0] : mastercontactAddresses[0];
            }
            preferredAddress.rC_Bios__Preferred_Mailing__c = TRUE;
            preferredAddress.rC_Bios__Preferred_Other__c = TRUE;
            addressesToUpdateMap.put(preferredAddress.Id, preferredAddress);
        }
        
        /** Ensure all of the previous preferred addresses that are not the new master preferred address
        //  are set as non-preferred.
        **/
        List <rC_Bios__contact_Address__c> addressesToUpdate = addressesToUpdateMap.values();
        for (rC_Bios__contact_Address__c addressToUpdate : addressesToUpdate) {
            if (preferredAddress != NULL && addressToUpdate.Id != preferredAddress.Id) {
                addressToUpdate.rC_Bios__Preferred_Mailing__c = FALSE;
                addressToUpdate.rC_Bios__Preferred_Other__c = FALSE;
            }
        }

        triggersDisabledMap.put('Email', TRUE);
        update addressesToUpdate;
       // triggersDisabledMap.put('Email', FALSE);

    }

    public static void contactBeforeMerge_handleEmails(Contact masterContact, List<Contact> mergedContactList) {
        Email__c primaryEmail;
        Map <Id, Email__c> emailsToUpdateMap = new Map<Id, Email__c>();
        List <Email__c> masterContactEmails = [SELECT Id, Primary__c, CreatedDate, LastModifiedDate
            FROM Email__c 
            WHERE Contact__c = :masterContact.id
            AND Email_Status__c = 'Valid'
            ORDER BY CreatedDate  DESC];
        
        /** If the master contact has a primary email, use it, and no need to update the contact's email record
        //  If the master contact has a no primary email, it might
        //  wind up being the primary email, so add it to the map of emails to update
        **/
        for (Email__c email : masterContactEmails) {
            if (primaryEmail == NULL && email.Primary__c == true) {
                primaryEmail = email;
            } else {
                emailsToUpdateMap.put(email.Id, email);
            }
        }

        List<Id> mergedcontactIds = new List<Id>();
        for (contact mergedContact : mergedContactList) {
            mergedContactIds.add(mergedContact.Id);
        }

        List <Email__c> mergedEmails = [SELECT Id, Primary__c, CreatedDate, LastModifiedDate
            FROM Email__c 
            WHERE Contact__c IN :mergedContactIds
            AND Email_Status__c = 'Valid'
            ORDER BY CreatedDate DESC];
        
        /** If the primary email has been established, subsequent emails should be set to non-primary
        //  If the primary email has not been established, an existing primary email might still
        //  wind up being the primary email address.
        //  If the primary email address has not been established, the first email address encountered (by last mod date)
        //  will become the the primary email address.
        **/
        for (Email__c email : mergedEmails) {
            if (primaryEmail != NULL || !email.Primary__c) {
                emailsToUpdateMap.put(email.Id, email);
            }
            else if (primaryEmail == NULL && email.Primary__c) {
                primaryEmail = email;                
            }
        }

        /** If the primary email address has still not been established, the most recently created or modified non-primary
        //  email address will become the primary email address.
        **/
        if (primaryEmail == NULL && !mergedEmails.isEmpty() && !masterContactEmails.isEmpty()) {       
            primaryEmail = (mergedEmails[0].lastModifiedDate > masterContactEmails[0].lastModifiedDate) ?
                mergedEmails[0] : masterContactEmails[0];
           // for testing purposes; can't test on lastModifiedDate without using Test.loadData, which 
           // we're not currently doing (but ideally should); we can easily mock CreatedDate, however
            if(Test.isRunningTest()) {
                primaryEmail = (mergedEmails[0].createdDate > masterContactEmails[0].createdDate) ?
                                    mergedEmails[0] : masterContactEmails[0];
            }
            primaryEmail.Primary__c = TRUE;
            emailsToUpdateMap.put(primaryEmail.Id, primaryEmail);
        }
        
        /** Ensure all of the previous preferred email addresses that are not the new primary email address
        //  are set as non-primary
        **/
        List <Email__c> emailsToUpdate = emailsToUpdateMap.values();
        for (Email__c email : emailsToUpdate) {
            if (primaryEmail != NULL && email.Id != primaryEmail.Id) {
                email.Primary__c = FALSE;
            }
        }

        update emailsToUpdate;

    }

    public static void contactBeforeMerge_handlePhones(Contact masterContact, List<Contact> mergedContactList) {
        Phone__c primaryPhone;
        Map <Id, Phone__c> phonesToUpdateMap = new Map<Id, Phone__c>();
        List <Phone__c> masterContactPhones = [SELECT Id, IsPrimary__c, CreatedDate, LastModifiedDate
            FROM Phone__c 
            WHERE Contact__c = :masterContact.id
            AND Phone_Status__c = 'Valid'
            ORDER BY CreatedDate  DESC];
        
        /** If the master contact has a primary phone, use it, and no need to update the contact's phone record
        //  If the master contact has a no primary phone, it might
        //  wind up being the primary phone, so add it to the map of phones to update
        **/
        for (Phone__c phone : masterContactPhones) {
            if (primaryPhone == NULL && phone.IsPrimary__c == true) {
                primaryPhone = phone;
            } else {
                phonesToUpdateMap.put(phone.Id, phone);
            }
        }

        List<Id> mergedcontactIds = new List<Id>();
        for (contact mergedContact : mergedContactList) {
            mergedContactIds.add(mergedContact.Id);
        }

        List <Phone__c> mergedPhones = [SELECT Id, IsPrimary__c, CreatedDate, LastModifiedDate
            FROM Phone__c 
            WHERE Contact__c IN :mergedContactIds
            AND Phone_Status__c = 'Valid'
            ORDER BY CreatedDate DESC];
        
        /** If the primary phone has been established, subsequent phones should be set to non-primary
        //  If the primary phone has not been established, an existing primary phone might still
        //  wind up being the primary phone address.
        //  If the primary phone address has not been established, the first phone address encountered (by last mod date)
        //  will become the the primary phone address.
        **/
        for (Phone__c phone : mergedPhones) {
            if (primaryPhone != NULL || !phone.IsPrimary__c) {
                phonesToUpdateMap.put(phone.Id, phone);
            }
            else if (primaryPhone == NULL && phone.IsPrimary__c) {
                primaryPhone = phone;                
            }
        }

        /** If the primary phone address has still not been established, the most recently created non-primary
        //  phone address will become the primary phone address.
        **/
        if (primaryPhone == NULL && !mergedPhones.isEmpty() && !masterContactPhones.isEmpty()) {       
            primaryPhone = (mergedPhones[0].createdDate > masterContactPhones[0].createdDate) ?
                mergedPhones[0] : masterContactPhones[0];
            primaryPhone.IsPrimary__c = TRUE;
            phonesToUpdateMap.put(primaryPhone.Id, primaryPhone);
        }
        
        /** Ensure all of the previous preferred phone addresses that are not the new primary phone address
        //  are set as non-primary
        **/
        List <Phone__c> phonesToUpdate = phonesToUpdateMap.values();
        for (Phone__c phone : phonesToUpdate) {
            if (primaryPhone != NULL && phone.Id != primaryPhone.Id) {
                phone.IsPrimary__c = FALSE;
            }
        }
        triggersDisabledMap.put('Phone', TRUE);
        update phonesToUpdate;

    }

    public static void contactAfterMerge_mergeDuplicatePhones(Id masterContactId) {

        String query = Utilities.getQueryOfAllFields('Phone__c');
        query += ' WHERE Contact__c = :masterContactId';
        
        List<Phone__c> phones = new List<Phone__c> ();
        try {
            phones = database.query(query);
        } catch (QueryException e){
            //perform exception handling
        }
        
        List<Phone__c> duplicatePhonesToMerge = new List<Phone__c>();
        Map<String,List<Phone__c>> phoneMap =  new Map<String,List<Phone__c>>();

        for (Phone__c phone : phones) {
            String phoneNumber = Utilities.stripNonNumeric(phone.Phone_Number__c);
            if (phoneMap.keySet().contains(phoneNumber)) {
                List<Phone__c> phoneList = phoneMap.get(phoneNumber);
                phoneList.add(phone);
                phoneMap.put(phoneNumber,phoneList);
            }
            else {
                List<Phone__c> phoneList = new List<Phone__c>{phone};
                phoneMap.put(phoneNumber,phoneList);
            }
        }

        for (String phoneNumber : phoneMap.keySet()) {
            phones = phoneMap.get(phoneNumber);
            if (phones.size() > 1) {
                Dupcheck.dc3Api dcAPI = new Dupcheck.dc3Api();
                dcAPI.doMerge(phones);
            }               
        }
    }

    public static void phoneAfterMerge_setPrimaryPhoneOnContact(Id masterPhoneId) {
        Phone__c masterPhone = [Select Contact__c, Phone_Number__c from Phone__c WHERE Id =:masterPhoneId LIMIT 1];
        Map<Id,String> mapOfPrimaryContactId_PhoneNumber = new Map<Id,String>{masterPhone.Contact__c=>masterPhone.Phone_Number__c};

        // tomorrow morning let's try to figure out why Phone does not get set but Home Phone does
        PhoneTriggerHandler.setPrimaryPhoneOnContact(mapOfPrimaryContactId_PhoneNumber);
        triggersDisabledMap.put('Phone', FALSE);

    }

    public static void contactAfterMerge_mergeDuplicateEmails(Id masterContactId) {
        String query = Utilities.getQueryOfAllFields('Email__c');
        query += ' WHERE Contact__c = :masterContactId';
        
        List<Email__c> emails = new List<Email__c> ();
        try {
            emails = database.query(query);
        } catch (QueryException e){
            //perform exception handling
        }
        
        List<Email__c> duplicateEmailsToMerge = new List<Email__c>();
        Map<String,List<Email__c>> emailMap =  new Map<String,List<Email__c>>();

        for (Email__c email : emails) {
            String emailAddress = email.Email_address__c;
            if (emailMap.keySet().contains(emailAddress)) {
                List<Email__c> emailList = emailMap.get(emailAddress);
                emailList.add(email);
                emailMap.put(emailAddress,emailList);
            }
            else {
                List<Email__c> emailList = new List<Email__c>{email};
                emailMap.put(emailAddress,emailList);
            }
        }

        for (String emailAddress : emailMap.keySet()) {
            emails = emailMap.get(emailAddress);
            if (emails.size() > 1) {
                Dupcheck.dc3Api dcAPI = new Dupcheck.dc3Api();
                dcAPI.doMerge(emails);
            }
            
        }
    }

    public static void contactAfterMerge_deleteDuplicateContactAddresses(Id masterContactId) {
        List<rC_Bios__Contact_Address__c> contactAddresses = [SELECT Id, rc_Bios__Address__r.rC_Bios__Unique_MD5__c 
            FROM rC_Bios__Contact_Address__c 
            WHERE rc_Bios__Contact__c = :masterContactId 
            ORDER BY rc_Bios__Preferred_Mailing__c DESC, LastModifiedDate DESC];
        
        List<rC_Bios__Contact_Address__c> duplicateAddressesToDelete = new List<rC_Bios__Contact_Address__c>();
        Set<String> md5Vals = new Set<String>();

        for (rC_Bios__Contact_Address__c address : contactAddresses) {
            if (md5Vals.contains(address.rc_Bios__Address__r.rC_Bios__Unique_MD5__c)) {
                duplicateAddressesToDelete.add(address);
            }
            else {
                md5Vals.add(address.rc_Bios__Address__r.rC_Bios__Unique_MD5__c);
            }
        }

        if (!duplicateAddressesToDelete.isEmpty()) {
            // ensure rC setting to delete contact addresses is turned off for user so that
            // additional contact addresses are not also deleted
           // updateContactAddressSettings(); 

            delete duplicateAddressesToDelete;
        }
    }

/**
 * EMAIL MERGE METHODS
 * 
 *
 * 
 *             
 */

    public static void emailAfterMerge_deleteLosingEmailPrefs(Set<Id> losingEmailIds) {
        List<Email_Preference__c> emailPrefsToDelete = [SELECT Id from Email_Preference__c where Email__c IN :losingEmailIds];

        if (!emailPrefsToDelete.isEmpty()) {
            delete emailPrefsToDelete;
        }
    }




   
}