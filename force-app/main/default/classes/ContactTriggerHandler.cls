/*
*
*Name  :  ContactTriggerHandler
*Author:  Appirio India (Ashu Gupta)
*Date  :  October 13, 2016
*Purpose :  This class contains static methods for the Contact object
Logic includes but not limited to
-  Field enhancements (ex GOL amt, HPC36
- Salutation management (insert, delete, update)
- Merge Tracking
- Deceased management
- Apex Sharing management
- Primary Secondary Contact Management"
*
*/
public class ContactTriggerHandler {
    
    public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    public static final string contactHouseholdRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static Boolean deceasedChecked;
    static {
        deceasedChecked = false;
    }
    public static void mainEntry(List<Contact> newList, List<Contact> oldList, Map<Id, Contact> newMap, Map<Id, Contact> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        if(TriggerState.isActive('ContactTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)){ 
            if (isBefore) {
                if (isInsert) {
                    onBeforeInsert(newList);
                }
                if (isUpdate) {
                    onBeforeUpdate(newList, oldMap);
                }
            }
            if(isAfter){
                
                if(isInsert){
                    onAfterInsert(newList);
                }
                if(isUpdate){
                    onAfterUpdate(newMap, oldMap);
                }
                
                if(isDelete) {
                    onAfterDelete(oldMap);
                }
            }
        }
    }
    
    public static void onBeforeInsert(List<Contact> newList) {
        Set<Id> accountIds = new Set<Id>();
        
        for (Contact c : newList) {
            accountIds.add(c.AccountId);
        }
        
        Map<Id, Account> accounts = new Map<Id, Account>(
            [SELECT Id, GOL_Current_Amount__c, HPC36_Amount__c
             FROM Account
             WHERE Id IN :accountIds]);
        
        for (Contact c : newList) {
            if (c.AccountId != null && accounts.containsKey(c.AccountId)) {
                c.GOL_Current_Amount__c = accounts.get(c.AccountId).GOL_Current_Amount__c;
                c.HPC36_Amount__c = accounts.get(c.AccountId).HPC36_Amount__c;
            }
        }
    }
    
    /*    
*
*Method onAfterDelete
*@param : newlist

*calls on onAfterDelete
*
*/
    public static void onAfterDelete(Map<Id, Contact> oldMap){
        // Method Variables
        Set<Id> setOfAccountIds = new Set<Id>();
        
        for(Contact con : oldMap.values()) {
            if(con.AccountId != null && con.rC_Bios__Active__c == True &&
               (con.rC_Bios__Preferred_Contact__c == True || con.rC_Bios__Secondary_Contact__c == True)) {
                   setOfAccountIds.add(con.AccountId);
               }
        }  
        
        // Generate Salutations
        if(!setOfAccountIds.IsEmpty()){
            SalutationsUtility.generateSalutations(setOfAccountIds);
        }
        
        // Record a merge, if appropriate.
        List<Contact_Merge_History__c> mergeHistoryList = new List<Contact_Merge_History__c>();
        Set<Id> retainedContactIds = new Set<Id>();
        
        for (Contact c : oldMap.values()) {
            if(String.isNotBlank(c.MasterRecordId)) {
                String name = Schema.SobjectType.Contact.getRecordTypeInfosById().get(c.RecordTypeId).getName();
                
                mergeHistoryList.add(new Contact_Merge_History__c(
                    Deleted_Contact_Number__c = c.Contact_Number__c,
                    Deleted_Id__c = c.Id,
                    Merged_Date__c = Date.today(),
                    Record_Type__c = name,
                    Retained_Contact__c = c.MasterRecordId,
                    Retained_Id__c = c.MasterRecordId
                ));
                
                retainedContactIds.add(c.MasterRecordId);
            }
        }
        
        if (mergeHistoryList.size() > 0) {
            Map<Id, Contact> retained = new Map<Id, Contact>([SELECT Id, Contact_Number__c FROM Contact WHERE Id IN :retainedContactIds]);
            
            for (Contact_Merge_History__c m : mergeHistoryList) {
                m.Retained_Contact_Number__c = retained.get(m.Retained_Id__c).Contact_Number__c;
            }
            
            insert mergeHistoryList;
        }
        
    }
    
    /*    
*
*Method onAfterInsert
*@param : newlist

*calls on onAfterInsert
*
*/
    public static void onAfterInsert(List<Contact> newList){
        // Method Variables
        Set<Id> setAccountId = new Set<Id>();
        Set<Id> setOfAccountIds = new Set<Id>();
        
        Map<Id, Id> deceasedAccountContactId  = new Map<Id, Id>();
        
        for(Contact con : newList){
            if((con.RecordTypeId == contactHouseholdRecTypeId )){
                if(con.accountid != null) {
                    //fetch the account id from all contacts
                    setAccountId.add(con.AccountId);
                }
            }
            
            // Generate Salutations
            if((con.rC_Bios__Preferred_Contact__c == True || con.rC_Bios__Secondary_Contact__c == True)
               && con.AccountId != null && con.rC_Bios__Active__c == True ) {
                   setOfAccountIds.add(con.AccountId);
               }
            
            if (con.rC_Bios__Deceased__c) {
                deceasedAccountContactId.put(con.AccountId, con.Id);
            }
        }
        
        if(!setAccountId.IsEmpty()){
            AccountConstituentUpdater.updateAccountAllContactsDeceased(setAccountId);
        }
        if (!deceasedAccountContactId.isEmpty() && !trac_HandleDeceasedContacts.isRecursive) {
            trac_HandleDeceasedContacts.isRecursive = true;
            trac_HandleDeceasedContacts.startDeceaseContactProcess(newList, deceasedAccountContactId);
        }
        // Generate Salutations
        if(!setOfAccountIds.IsEmpty()){
            SalutationsUtility.generateSalutations(setOfAccountIds);
        }
        

    }
    /*    
*
*Method onAfterUpdate
*@param : newMap
*@param : OldMap
*It checks whether the Account Lookup changed.
*
*/
    public static void onAfterUpdate(Map<Id, Contact> newMap, Map<Id, Contact> oldMap){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> primaryContactDeceasedAccounts = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        set<Id> setContactIdWithUpdatedName = new set<Id>();
        Map<Id, Id> deceasedAccountContactId  = new Map<Id, Id>();
        
        for(contact con: newMap.values()){
            if(oldMap.get(con.Id).AccountId != con.AccountId ){
                accountIds.add(oldMap.get(con.Id).AccountId);
                contactIds.add(con.Id);
            }
            // updateAccountAllContactsDeceased
            if((con.RecordTypeId == contactHouseholdRecTypeId &&
                (oldMap != null && (con.rC_Bios__Deceased__c != oldMap.get(con.Id).rC_Bios__Deceased__c)) 
               )){
                   if(con.accountid != null) {
                       //fetch the account id from all contacts
                       setAccountId.add(con.AccountId);
                   }
               }
            
            //Generate Salutations
            if((oldMap.get(con.Id).rC_Bios__Preferred_Contact__c != con.rC_Bios__Preferred_Contact__c || 
                oldMap.get(con.Id).rC_Bios__Secondary_Contact__c != con.rC_Bios__Secondary_Contact__c) ||
               (oldMap.get(con.Id).rC_Bios__Active__c != con.rC_Bios__Active__c) || 
               ((con.rC_Bios__Preferred_Contact__c == True || con.rC_Bios__Secondary_Contact__c == True) &&
                ((oldMap.get(con.Id).AccountId != con.AccountId) || 
                 ((oldMap.get(con.Id).Salutation != con.Salutation) || (oldMap.get(con.Id).FirstName != con.FirstName) || 
                  (oldMap.get(con.Id).LastName != con.LastName) ||
                  (oldMap.get(con.Id).rC_Bios__Middle_Name__c != con.rC_Bios__Middle_Name__c) || 
                  (oldMap.get(con.Id).rC_Bios__Suffix__c != con.rC_Bios__Suffix__c) || (oldMap.get(con.Id).Nickname__c != con.Nickname__c) ||
                  (oldMap.get(con.Id).Title != con.Title) || (oldMap.get(con.Id).Account_Name__c != con.Account_Name__c)))
               )
              ) {
                  setOfAccountIds.add(con.AccountId);
                  if(oldMap.get(con.Id).AccountId != con.AccountId) {
                      setOfAccountIds.add(oldMap.get(con.Id).AccountId);
                  }
              }
            //Make the secondaryContact as Primary if the Primary Contact deceased
            if(oldMap.get(con.Id).rC_Bios__Deceased__c != con.rC_Bios__Deceased__c &&  con.rC_Bios__Deceased__c == true){
                primaryContactDeceasedAccounts.add(con.accountId);
                
                // Run Decease process for those contact who deceased actually
                deceasedAccountContactId.put(con.AccountId, con.Id);
            }   
            
            if(con.rC_Bios__Preferred_Contact__c == true && (con.LastName != oldMap.get(con.Id).LastName || con.FirstName != oldMap.get(con.Id).FirstName)) {
                setContactIdWithUpdatedName.add(con.Id);
            }
        }
        
        if(!setContactIdWithUpdatedName.isEmpty()) {
            populateSortNameOnHouseholdAccounts(setContactIdWithUpdatedName);
        }
        
        for(Account acc: [SELECT id,Affiliation__c FROM Account WHERE Id =: accountIds]){
            if(acc.Affiliation__c != null)
                OldAffiliations.add(acc.Affiliation__c);
        }
        if(!OldAffiliations.isEmpty()){
            resetNGOCSharingRecords(contactIds, OldAffiliations);
        }
        
        // updateAccountAllContactsDeceased
        if(!setAccountId.IsEmpty()){
            AccountConstituentUpdater.updateAccountAllContactsDeceased(setAccountId);
        }
        
        //Make the secondaryContact as Primary if the Primary Contact deceased
        if(!primaryContactDeceasedAccounts.IsEmpty()){
            try{
                secondaryCntAsPrimary(primaryContactDeceasedAccounts);
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ContactTriggerHandler','onAfterUpdate',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }

        if(!deceasedAccountContactId.isEmpty() && !trac_HandleDeceasedContacts.isRecursive) {
            trac_HandleDeceasedContacts.isRecursive = true;
            trac_HandleDeceasedContacts.startDeceaseContactProcess(newMap.values(), deceasedAccountContactId);
        }
        
        // Generate Salutations
        if(!setOfAccountIds.IsEmpty()){
            SalutationsUtility.generateSalutations(setOfAccountIds);
        }
        //=================
        
        

    }
    /*    
*
*Method onBeforeUpdate
*@param : newMap
*@param : OldMap
*
*/
    public static void onBeforeUpdate(List<Contact> newList, Map<Id, Contact> oldMap){
        for(Contact con : newList) {
            
            // Restrict User to Uncheck the Deceased Contact, once it marked as true
            if(UserInfo.getProfileId() != Label.SysAdminProfileId) {
                if(con.rC_Bios__Deceased__c != oldMap.get(con.id).rC_Bios__Deceased__c && !con.rC_Bios__Deceased__c) {
                    con.addError(System.Label.Deceased_Contact_Irreversible_Action);
                }
            }
            if(con.rC_Bios__Deceased__c != oldMap.get(con.id).rC_Bios__Deceased__c && con.rC_Bios__Deceased__c) {
                deceasedChecked = true;
                break;
            }
        }
        
        if(deceasedChecked) {
            User us = [SELECT Id, Validation_Bypass__c FROM User WHERE Id =: UserInfo.getUserId()];
            if( us.Validation_Bypass__c != true){
                us.Validation_Bypass__c = true;
                update us; 
            }
        }
    }
    
    // Issue - I-318542
    // purpose - to populate sort name on household accounts if not locked 
    // created by - Aashita Sharma 
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    private static void populateSortNameOnHouseholdAccounts(Set<Id> setContactIdWithUpdatedName) {
        List<Account> lstAccountToUpdate = new List<Account>();
        
        for(Contact con : [SELECT Id, AccountId, rC_Bios__Preferred_Contact__c, LastName, FirstName,
                           Account.Sort_Name__c, Account.Sort_Name_Locked__c, Account.RecordTypeId
                           FROM Contact
                           WHERE Id IN: setContactIdWithUpdatedName
                           AND Account.RecordTypeId =: houseHoldId
                           AND Account.Sort_Name_Locked__c = FALSE]) {
                               con.Account.Sort_Name__c = (con.LastName!= '' && con.LastName != null) ? String.valueOf(con.LastName): '' ;
                               con.Account.Sort_Name__c += (con.FirstName != '' && con.FirstName != null) ? ', '+String.valueOf(con.FirstName): '';
                               lstAccountToUpdate.add(con.Account);
                           }
        
        if(!lstAccountToUpdate.isEmpty()) {
            try{
                update lstAccountToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ContactTriggerHandler','',
                                                                        'populateSortNameOnHouseholdAccounts error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    //@future
    public static void secondaryCntAsPrimary (Set<Id> accountIds){
        //Set<Id> accountIds = new Set<Id>();
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Account acc: [SELECT Id, (SELECT Id FROM Contacts WHERE rC_Bios__Secondary_Contact__c = true AND rC_Bios__Active__c = true LIMIT 1) FROM Account WHERE Id =:accountIds]){
            for(contact con: acc.contacts){
                contactsToUpdate.add(new Contact(Id = con.Id, rC_Bios__Secondary_Contact__c = false, rC_Bios__Preferred_Contact__c = true));
            }
        }
        
        if(!contactsToUpdate.IsEmpty()) {
            try{
                update contactsToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ContactTriggerHandler','secondaryCntAsPrimary',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    
    /*    
*
*Method resetNGOCSharingRecords
*@param : set<Id> accountIds
*@param : List<String> OldAffiliations
*It resets the Preference,Salutation,Relationship,ActionPlan share Records if present.
*
*/
    
    public static void resetNGOCSharingRecords( set<Id> contactIds, List<String> OldAffiliations){
        Set<Id> preferenceIds = new Set<Id> ();
        Set<Id> salutationIds = new Set<Id> ();
        Set<Id> actionPlanIds = new Set<Id> ();
        Set<Id> relationshipIds = new Set<Id>();
        Set<Id> prospectResearchIds = new Set<Id>();
        Set<Id> ConfidentialDataIds = new Set<Id>();
        
        
        //Preference Share records
        
        for(rC_Bios__Preference__c pr: [SELECT Id, rC_Bios__Contact__r.Account.Affiliation__c FROM rC_Bios__Preference__c WHERE  rC_Bios__Contact__c =: contactIds]){
            preferenceIds.add(pr.Id);
        }
        
        // Salutation Share records
        for(rC_Bios__Salutation__c sl: [SELECT Id, rC_Bios__Contact__r.Account.Affiliation__c FROM rC_Bios__Salutation__c WHERE  rC_Bios__Contact__c =: contactIds]){
            salutationIds.add(sl.Id);
        }
        
        //Relationship
        for(rC_Bios__Relationship__c rl: [SELECT Id, rC_Bios__Contact_2__r.Account.Affiliation__c, rC_Bios__Contact_1__r.Account.Affiliation__c FROM rC_Bios__Relationship__c WHERE  rC_Bios__Contact_2__c =: contactIds OR rC_Bios__Contact_1__c =: contactIds]){
            relationshipIds.add(rl.Id);
        }
        
        //ActionPlan
        for(rC_Bios__Action_Plan__c ap: [SELECT Id, rC_Bios__Contact__r.Account.Affiliation__c FROM rC_Bios__Action_Plan__c WHERE  rC_Bios__WhatId__c =: contactIds ]){
            actionPlanIds.add(ap.Id);
        }
        
        //Prospect Research
        for(Prospect_Research__c pr: [SELECT Id, Name,  Contact__c, Contact__r.account.Affiliation__c FROM Prospect_Research__c Where Contact__c =: contactIds]){
            prospectResearchIds.add(pr.Id);
        }
        
        //Confidential Data
        for(Confidential_Data__c conf: [SELECT Id, Name, Contact__c, Contact__r.account.Affiliation__c FROM Confidential_Data__c where Contact__c =: contactIds]){
            ConfidentialDataIds.add(conf.Id);
        }
        
        // Re-calculate the sharing rules in a future method .
        if((!preferenceIds.IsEmpty() || !salutationIds.IsEmpty() || !relationshipIds.IsEmpty() || !actionPlanIds.IsEmpty() || !prospectResearchIds.IsEmpty() || !ConfidentialDataIds.IsEmpty()) && Utilities.CanUseFutureContext())
            resetNGOCShareRecordsFutureHandler(preferenceIds, salutationIds, actionPlanIds, relationshipIds, prospectResearchIds,ConfidentialDataIds, OldAffiliations);
    }
    
    /*    
*
*Method resetActionPlanShareRecords
*@param : Set<Id> (preferenceIds)
*@param : Set<Id> (salutationIds)
*@param : Set<Id> (actionPlanIds)
*@param : Set<Id> (relationshipIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    @future
    public static void resetNGOCShareRecordsFutureHandler(Set<Id> preferenceIds, Set<Id> salutationIds, Set<Id> actionPlanIds, Set<Id> relationshipIds, Set<Id> prospectResearchIds,Set<Id> ConfidentialDataIds, List<String> OldAffiliations){
        if(!preferenceIds.IsEmpty())
            ContactTriggerHandler.resetPreferenceShareRecords(preferenceIds, OldAffiliations);
        
        if(!salutationIds.IsEmpty())
            ContactTriggerHandler.resetSalutationShareRecords(salutationIds, OldAffiliations);
        
        if(!relationshipIds.IsEmpty())
            ContactTriggerHandler.resetRelationshipShareRecords(relationshipIds, OldAffiliations);
        
        if(!actionPlanIds.IsEmpty())
            ContactTriggerHandler.resetActionPlanShareRecords(actionPlanIds, OldAffiliations);
        
        if(!prospectResearchIds.IsEmpty()){
            ContactTriggerHandler.resetProspectResearch(prospectResearchIds, OldAffiliations);
        }
        
        if(!ConfidentialDataIds.IsEmpty()){
            contactTriggerHandler.resetConfidential(ConfidentialDataIds,oldAffiliations);
        }
    }   
    
    /*
*
*Method: resetConfidential
*@param : Map<Id,String> AccountId To Affiliations
*@description : Method which recalculates as per the respective Affiliation__c
*
*/ 
    public static void resetConfidential(Set<Id> confidentialIds, List<String> OldAffiliations){
        map<Id,String> mapConfidentialIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapConfidentialIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        
        for(Confidential_Data__c cnf: [SELECT Id, Name, Contact__c, Contact__r.Account.Affiliation__c, Contact__r.Account.Restricted_Account__c FROM Confidential_Data__c where Id =: confidentialIds]){
            mapConfidentialIdToNewAffiliation.put(cnf.Id, cnf.Contact__r.Account.Affiliation__c);
            mapProspectIdToRestricted.put(cnf.Id, cnf.Contact__r.Account.Restricted_Account__c);
        }
        
        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapConfidentialIdToNewAffiliation.values() OR Name =:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        ConfDataTriggerHandler.deleteConfidentialSharingRecords (confidentialIds, OldAffiliations, mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ConfDataTriggerHandler.InsertConfidentialShareRecords (mapConfidentialIdToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
    }
    
    /*
*
*Method: resetProspectResearch
*@param : Map<Id,String> AccountId To Affiliations
*@description : Method which recalculates as per the respective Affiliation__c
*
*/ 
    public static void resetProspectResearch(Set<Id> prospectResearchIds, List<String> OldAffiliations){
        map<Id,String> mapProspectResearchToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        
        for(Prospect_Research__c pr: [SELECT Id, Name,  Contact__c, Contact__r.account.Affiliation__c, Contact__r.account.Restricted_Account__c  FROM Prospect_Research__c Where Id =: prospectResearchIds]){
            if(pr.Contact__c != null && pr.Contact__r.accountId != null && pr.Contact__r.account.Affiliation__c != null ){
                mapProspectResearchToNewAffiliation.put(pr.Id, pr.Contact__r.account.Affiliation__c);
                mapProspectIdToRestricted.put(pr.Id, pr.Contact__r.account.Restricted_Account__c);
            }
        }
        
        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapProspectResearchToNewAffiliation.values() OR Name =:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        ProsResearchTriggerHandler.deleteProspectSharingRecords (prospectResearchIds, OldAffiliations, mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ProsResearchTriggerHandler.InsertProspectShareRecords (mapProspectResearchToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
    }
    
    
    /*    
*
*Method resetActionPlanShareRecords
*@param : Set<Id> (actionPlanIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    
    
    public static void resetActionPlanShareRecords(Set<Id> actionPlanIds, List<String> OldAffiliations){
        Map<Id,String> mapActionPlanIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        Map<Id,Id> mapActionPlanIdTocontactId = new Map<Id,Id>();
        Map<Id,rC_Bios__Action_Plan__c> mapActionPlan = new Map<Id,rC_Bios__Action_Plan__c>();      
        Map<Id,contact> mapContact = new Map<Id,contact>();
        
        // Collect the ActionPlanIdToAffiliation
        for(rC_Bios__Action_Plan__c mapAcp: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Account__r.Affiliation__c, rC_Bios__Contact__r.account.Affiliation__c FROM rC_Bios__Action_Plan__c WHERE Id =: actionPlanIds]){
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('003')){
                mapActionPlanIdTocontactId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
            }
        }
        
        if(!mapActionPlanIdTocontactId.Keyset().IsEmpty()){
            for(Contact con: [SELECT id, account.Affiliation__c, account.Restricted_Account__c FROM Contact where id=: mapActionPlanIdTocontactId.Values()]){
                if(con.account.Affiliation__c != null){
                    mapContact.put(con.Id,con);
                    
                }
            }
        }
        
        for(Id objId: mapActionPlanIdTocontactId.keySet()){
            if(mapActionPlan.get(objId) != null && mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(objId,mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(objId,mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deleteActionPlanSharingRecords (mapActionPlanIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapActionPlanIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertActionPlanSharingRecords (mapActionPlanIdToAffiliate, mapGroupNameToId, mapActionPlanIdToRestricted);
        
    }
    
    /*    
*
*Method resetSalutationShareRecords
*@param : Set<Id> (salutationIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    
    public static void resetSalutationShareRecords (Set<Id> salutationIds, List<String> OldAffiliations){
        //variables
        Map<Id,String> mapSalutationIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapSalutationIdToRestricted = new map<Id,Boolean> ();
        
        // Collect the AccountIds
        for(rC_Bios__Salutation__c mapSal: [SELECT Id, rC_Bios__Contact__r.Account.Restricted_Account__c, rC_Bios__Contact__r.Account.Affiliation__c, rC_Bios__Contact__c, rC_Bios__Contact__r.AccountId, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Salutation__c WHERE Id =: salutationIds]){
            
            //Contact Accounts Affiliations Relations
            if(mapSal.rC_Bios__Contact__c != null && mapSal.rC_Bios__Contact__r.AccountId != null && mapSal.rC_Bios__Contact__r.Account.Affiliation__c != null ){
                mapSalutationIdToAffiliate.put(mapSal.Id,mapSal.rC_Bios__Contact__r.Account.Affiliation__c);
                mapSalutationIdToRestricted.put(mapSal.Id,mapSal.rC_Bios__Contact__r.Account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapSalutationIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deleteSalutationSharingRecords (mapSalutationIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapSalutationIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertSalutationSharingRecords (mapSalutationIdToAffiliate, mapGroupNameToId,mapSalutationIdToRestricted);
    }
    
    
    /*    
*
*Method resetRelationshipShareRecords
*@param : Set<Id> (relationshipIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    
    public static void resetRelationshipShareRecords(Set<Id> relationshipIds, List<String> OldAffiliations){
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,Boolean> mapRelationshipIdToRestricted = new Map<Id,Boolean>(); 
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new Map<Id,rC_Bios__Relationship__c>();
        
        // Collect the RelationshipIdToRelationship and collect the affiliations
        for(rC_Bios__Relationship__c mapRe: [SELECT Id, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact_1__r.Account.Restricted_Account__c, rC_Bios__Contact_2__r.Account.Restricted_Account__c, rC_Bios__Account_1__r.Restricted_Account__c, rC_Bios__Account_2__r.Restricted_Account__c,
                                             rC_Bios__Opportunity__c, rC_Bios__Account_1__c, rC_Bios__Account_2__c, rC_Bios__Account_1__r.Affiliation__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Contact_2__r.accountId, rC_Bios__Contact_2__r.account.Affiliation__c, rC_Bios__Contact_1__r.accountId, rC_Bios__Contact_1__r.account.Affiliation__c, rC_Bios__Account_2__r.Affiliation__c FROM rC_Bios__Relationship__c WHERE Id =: relationshipIds]){
                                                 mapRelationshipIdToRelationship.put(mapRe.Id,mapRe);
                                                 if(mapRe.rC_Bios__Account_1__c != null && mapRe.rC_Bios__Account_1__r.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Account_1__r.Affiliation__c);
                                                 if(mapRe.rC_Bios__Account_2__c != null && mapRe.rC_Bios__Account_2__r.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Account_2__r.Affiliation__c);
                                                 if(mapRe.rC_Bios__Contact_1__c != null && mapRe.rC_Bios__Contact_1__r.account.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Contact_1__r.account.Affiliation__c);
                                                 if(mapRe.rC_Bios__Contact_2__c != null &&  mapRe.rC_Bios__Contact_2__r.account.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Contact_2__r.account.Affiliation__c);
                                                 if(mapRe.rC_Bios__Opportunity__c != null && mapRe.rC_Bios__Opportunity__r.account.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Opportunity__r.account.Affiliation__c);
                                                 
                                                 if(mapRe.rC_Bios__Account_1__r.Restricted_Account__c == true || mapRe.rC_Bios__Account_2__r.Restricted_Account__c == true ||
                                                    mapRe.rC_Bios__Contact_1__r.Account.Restricted_Account__c == true || mapRe.rC_Bios__Contact_2__r.Account.Restricted_Account__c == true ||
                                                    mapRe.rC_Bios__Opportunity__r.account.Restricted_Account__c == true){
                                                        
                                                        mapRelationshipIdToRestricted.put(mapRe.Id,true);
                                                    }
                                                 else{
                                                     mapRelationshipIdToRestricted.put(mapRe.Id,false);
                                                 }
                                             }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deleteRelationshipSharingRecords (mapRelationshipIdToRelationship, OldAffiliations, mapGroupNameToId, mapRelationshipIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertRelationshipSharingRecords (mapRelationshipIdToRelationship, mapGroupNameToId, mapRelationshipIdToRestricted);
    }
    
    /*    
        *
        *Method resetPreferenceShareRecords
        *@param : Set<Id> (preferenceIds)
        *@param : List<String> OldAffiliations
        *It resets the share records based on the their account Affiliation.
        *
	*/
    public static void resetPreferenceShareRecords(Set<Id> preferenceIds, List<String> OldAffiliations){
        //variables
        Map<Id,String> mapPreferenceIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPreferenceIdToRestricted = new map<Id,Boolean> ();
        
        // Collect the AccountIds
        for(rC_Bios__Preference__c mapPre: [SELECT Id, rC_Bios__Contact__r.Account.Restricted_Account__c, rC_Bios__Contact__r.Account.Affiliation__c, rC_Bios__Contact__r.AccountId, rC_Bios__Contact__c, rC_Bios__Account__c, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Preference__c WHERE Id =: preferenceIds]){
            
            //Contact Accounts Affiliations Relations
            if(mapPre.rC_Bios__Contact__c != null && mapPre.rC_Bios__Contact__r.AccountId != null && mapPre.rC_Bios__Contact__r.Account.Affiliation__c != null ){
                mapPreferenceIdToAffiliate.put(mapPre.Id,mapPre.rC_Bios__Contact__r.Account.Affiliation__c);
                mapPreferenceIdToRestricted.put(mapPre.Id,mapPre.rC_Bios__Contact__r.Account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPreferenceIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deletePreferenceSharingRecords (mapPreferenceIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapPreferenceIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPreferenceSharingRecords (mapPreferenceIdToAffiliate, mapGroupNameToId, mapPreferenceIdToRestricted);
    }

}