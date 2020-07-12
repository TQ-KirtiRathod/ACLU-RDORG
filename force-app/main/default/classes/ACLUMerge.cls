global class ACLUMerge implements dupcheck.dc3Plugin.InterfaceMerge {

   global void beforeMerge(String objectPrefix, Sobject masterRecord, List < sobject > mergedRecordList) {
    /* Standard Objects */
    
    // Accounts
    if (objectPrefix == '001') {
        
        /*  masterAccount only includes fields that were updated in merge, necessitating a clone when
            we'll neeed to reference an account field*/
        Account masterClone = [SELECT Id, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, Affiliation__c, Chapter__c, Lock_Affiliation__c,
                                Is_Email_Salutation_Locked__c,Default_Email_Salutation__c, 
                                Is_Formal_Inside_Locked__c,Formal_Inside__c, 
                                Is_Formal_Outside_1_Locked__c,Formal_Outside_1__c, 
                                Is_Formal_Outside_2_Locked__c,Formal_Outside_2__c, 
                                Is_Formal_Outside_3_Locked__c,Formal_Outside_3__c,
                                Is_Informal_Inside_Locked__c,Informal_Inside__c, 
                                Is_Informal_Outside_1_Locked__c,Informal_Outside_1__c, 
                                Is_Informal_Outside_2_Locked__c,Informal_Outside_2__c, 
                                Is_Informal_Outside_3_Locked__c,Informal_Outside_3__c,
                                Is_Recognition_Formal_Locked__c,Recognition_Formal__c, 
                                Is_Recognition_Informal_Locked__c,Recognition_Informal__c
                                FROM Account 
                                WHERE Id = :masterRecord.Id]; 

        List<Id> mergedRecordIds = new List<Id>();
        for (SObject obj : mergedRecordList) {
            mergedRecordIds.add(obj.Id);
        }
        List<Account> mergedAccounts = [SELECT Id, Affiliation__c, Chapter__c, Lock_Affiliation__c,
                                Is_Email_Salutation_Locked__c,Default_Email_Salutation__c, 
                                Is_Formal_Inside_Locked__c,Formal_Inside__c, 
                                Is_Formal_Outside_1_Locked__c,Formal_Outside_1__c, 
                                Is_Formal_Outside_2_Locked__c,Formal_Outside_2__c, 
                                Is_Formal_Outside_3_Locked__c,Formal_Outside_3__c,
                                Is_Informal_Inside_Locked__c,Informal_Inside__c, 
                                Is_Informal_Outside_1_Locked__c,Informal_Outside_1__c, 
                                Is_Informal_Outside_2_Locked__c,Informal_Outside_2__c, 
                                Is_Informal_Outside_3_Locked__c,Informal_Outside_3__c,
                                Is_Recognition_Formal_Locked__c,Recognition_Formal__c, 
                                Is_Recognition_Informal_Locked__c,Recognition_Informal__c
                                FROM Account 
                                WHERE Id IN :mergedRecordIds];

        ACLUMergeManager.accountBeforeMerge_handleLockAffiliateSetting((Account)masterClone,(List<Account>)mergedAccounts);
        ACLUMergeManager.accountBeforeMerge_handleLockedSalutations((Account)masterClone,(List<Account>)mergedAccounts);
        ACLUMergeManager.accountBeforeMerge_updateContacts((Account)masterClone,(List<Account>)mergedRecordList);
        ACLUMergeManager.accountBeforeMerge_updatePaymentMethods((Account)masterRecord,(List<Account>)mergedRecordList);
        ACLUMergeManager.accountBeforeMerge_updateAccountAddresses((Account)masterRecord,(List<Account>)mergedRecordList);
    }

    // Contacts
    if (objectPrefix == '003') {
        ACLUMergeManager.triggersDisabledMap.put('Email', TRUE);
        ACLUMergeManager.contactBeforeMerge_updatecontactAddresses((Contact)masterRecord,(List<Contact>)mergedRecordList);
        ACLUMergeManager.contactBeforeMerge_handleEmails((Contact)masterRecord,(List<Contact>)mergedRecordList);
        ACLUMergeManager.contactBeforeMerge_handlePhones((Contact)masterRecord,(List<Contact>)mergedRecordList);
    }       

    return;
   }

   global void mergeFailed(String objectPrefix, Sobject masterRecord, Set <Id> mergedRecordsIds, dupcheck.dc3Exception.MergeException exceptionData) {
       return;
   }

   global void afterMerge(String objectPrefix, Sobject masterRecord, Set <Id> mergedRecordIds) {
    // Accounts
    if (objectPrefix == '001') { 
        Account masterClone = [SELECT Id, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, Affiliation__c, Chapter__c, Lock_Affiliation__c
            FROM Account 
            WHERE Id = :masterRecord.Id]; 
        List<Account> mergedAccounts = [SELECT Id, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, Affiliation__c, Chapter__c, Lock_Affiliation__c
            FROM Account 
            WHERE Id IN :mergedRecordIds AND
            IsDeleted = TRUE ALL ROWS]; 

        ACLUMergeManager.accountAfterMerge_deleteDuplicateAccountAddresses(masterRecord.Id);
        ACLUMergeManager.accountAfterMerge_deleteDuplicateAccountTeams(masterRecord.Id);
        ACLUMergeManager.accountAfterMerge_handleDuplicatePreferences(masterRecord.Id);
        ACLUMergeManager.accountAfterMerge_handleLockAffiliateSetting((Account)masterClone);
    
        Set<Id> allRecordIds;
        Id scheduleMergeContactsJob;
        for (Id mergedRecordId : mergedRecordIds) {
            allRecordIds = new Set<Id>{mergedRecordId,masterRecord.id};
            scheduleMergeContactsJob = ACLUMergeManager.accountAfterMerge_scheduleMergeContacts(masterRecord.Id, allRecordIds);
        }
    }

    // Contacts
   if (objectPrefix == '003') { 
        ACLUMergeManager.triggersDisabledMap.put('Email', TRUE);
        ACLUMergeManager.contactAfterMerge_mergeDuplicateEmails(masterRecord.Id);
        ACLUMergeManager.contactAfterMerge_mergeDuplicatePhones(masterRecord.Id);
        ACLUMergeManager.contactAfterMerge_deleteDuplicateContactAddresses(masterRecord.Id);
        ACLUMergeManager.triggersDisabledMap.put('Email', FALSE);

    }



    /* Custom Objects */

    String emailPrefix = Utilities.getObjectPrefix('Email__c');
    String phonePrefix = Utilities.getObjectPrefix('Phone__c');

    // Email
    if (objectPrefix == emailPrefix) {
        ACLUMergeManager.emailAfterMerge_deleteLosingEmailPrefs(mergedRecordIds);
    }   
    
    // Phone
    if (objectPrefix == phonePrefix) {
        ACLUMergeManager.phoneAfterMerge_setPrimaryPhoneOnContact(masterRecord.Id);
    }  

    return;
   }
}