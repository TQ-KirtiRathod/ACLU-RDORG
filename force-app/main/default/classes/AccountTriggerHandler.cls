/*
*
*Name  :  AccountTriggerHandler
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 17, 2016
*Purpose :  Handler Class for AccountTrigger
            Logic includes but not limited to
            - Merge History tracking
            - Apex Sharing
            - Field enrichment based on criteria, ex Household Count
            - Salutation are set
            - Affiliation and Chapter is set
            - Email Preferences, Preferences 
*	Ticket 		Modified Date		Modified by				Purpose
*   #74075        02/26/2020		SFDO (Kirti Rathod)     set the expiration date to null
*/
public class AccountTriggerHandler {

    public static list<String> accZipCode;
    public static list<Account> listAccount;
    public static Map<String,Zip_Affiliate__c> mapZipCode;
    public static Id organizationId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    private static Set<String> pluralPrefixes;
    private static Set<String> preferenceCodes;
    private static Set<String> preferenceCodesWithoutPZ;
    public static double accountAsyncBatchMax;
    private static Boolean recordAccessUtilityHasRun;
    @testVisible
    private static Boolean doChainJob = true;


    static {
        pluralPrefixes = new Set<String>{'Mr & Mrs.', 'The','Board of Directors of','Capt. and Mrs.','Captain and Mrs.','Cdr. and Mrs.','Chap. and Mrs.',
                                         'Chaplain and Mr.','Chaplain and Mrs.','Chaplain Capt. and Mrs.','Cmdr. and Mrs.','Cmsgt. and Mrs.','Col. and Mrs.',
                                         'Commission','Committee','Committee to Re-Elect','Co-Workers at','Co-Workers in','Co-Workers of','Dr. & Mr.','Dr. & Mrs.',
                                         'Dr. & Ms.','Dr. and Mr.','Dr. and Mrs.','Dr. and Ms.','Drs.','Estate of','Faculty at','Friends at','From the','Hon. & Mrs.',
                                         'Hon. and Mrs.','Judge & Mrs.','Judge and Mrs.','Lcdr. and Mrs.','Lt. Cdr. and Mrs.','Lt. Col. and Mrs.','Ltc. and Mrs.',
                                         'Maj. Gen. and Mrs.','Major and Mr.','Major and Mrs.','Members of','Messrs.','Misses','Misters','Mr. & Mrs.','Mr. & Ms.',
                                         'Mr. and Mr.','Mr. and Mrs.','Mr. and Ms.','Mrs. and Mrs.','Ms. & Mr.','Ms. and Ms.','Msgt. and Mrs.','MSgt. and Mrs.',
                                         'Officers of','Prof. and Mrs.','Professor & Mrs.','Rabbi & Mrs.','Ret. Col. and Mrs.','Rev. and Mrs.','Reverend & Mrs.',
                                         'Senator & Mrs.','Senator and Mrs.','SFC and Mrs.','Sfc. and Mrs.','Sgt. and Mrs.','Sp6 and Mrs.','SSG and Mrs.',
                                         'Ssg. and Mrs.','Ssgt. and Mrs.','The','The Family of','The Honorable & Mrs.','The Staff of','Trust of',
                                         'Tsgt. and Mrs.','TSgt. and Mrs.','Vicar and Mrs.'};
       preferenceCodes = new Set<String>{'PA','PB','PC','PZ'};
       preferenceCodesWithoutPZ = new Set<String>{'PA','PB','PC'};

        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            accountAsyncBatchMax = q.Batch_Size_Account__c;
        } else {
            accountAsyncBatchMax = 100;
        }

        recordAccessUtilityHasRun = false;

    }

/*
*
*Method mainEntry
*@description : defining all trigger events
*
*/
    public static void mainEntry(List<Account> newList, List<Account> oldList, Map<Id, Account> newMap, 
                                 Map<Id, Account> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, 
                                 Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('Account_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {
            // It is called on before 
            if(isBefore){
                // Before insert
                if(isInsert){
                    beforeInsert(newList);
                }
                // Before update
                if(isUpdate){
                    beforeUpdate(newList, oldMap);
                }
            }

            //is called  After insert/Update
            if(isAfter){
                if(isInsert){
                    afterInsert(newList);
                }
                if(isUpdate){
                    afterUpdate(newList, newMap, oldMap);
                }
                if (isDelete) {
                    afterDelete(oldMap);
                }
            }

        }

    }
    
    /*
    *Method afterDelete
    *@description : calls on afterDelete
    */

    public static void afterDelete(Map<Id, Account> oldMap) {
        List<Account_Merge_History__c> mergeHistoryList = new List<Account_Merge_History__c>();
        Set<Id> retainedAccountIds = new Set<Id>();
        map<Id, String> accountIdsOldAffiliationMap = new map<Id, String>();
        
        for (Account acc : oldMap.values()) {
            if(String.isNotBlank(acc.MasterRecordId)) {
                String name = Schema.SobjectType.Account.getRecordTypeInfosById().get(acc.RecordTypeId).getName();

                mergeHistoryList.add(new Account_Merge_History__c(
                    Deleted_Account_Number__c = acc.Account_Number__c,
                    Deleted_Id__c = acc.Id,
                    Merged_Date__c = Date.today(),
                    Record_Type__c = name,
                    Retained_Account__c = acc.MasterRecordId,
                    Retained_Id__c = acc.MasterRecordId
                ));

                retainedAccountIds.add(acc.MasterRecordId); 
                accountIdsOldAffiliationMap.put(acc.MasterRecordId, acc.Affiliation__c);
            }
        }
    
        if(!retainedAccountIds.isEmpty()){
            // queue future jobs QueueUpdateIsSharedGroup, which calls QueueMergePostProcessingFutureWrapper
            Id isSharedGroupJob =  System.enqueueJob(new QueueUpdateIsSharedGroup(retainedAccountIds));
        }
        
        if (mergeHistoryList.size() > 0) {
            Map<Id, Account> retained = new Map<Id, Account>([SELECT Id, Account_Number__c, Affiliation__c 
                                                              FROM Account WHERE Id IN :retainedAccountIds]);
            for (Account_Merge_History__c m : mergeHistoryList) {
                m.Retained_Account_Number__c = retained.get(m.Retained_Id__c).Account_Number__c;
            }

            insert mergeHistoryList;
            
            //added for I-288400
            if(accountIdsOldAffiliationMap.keySet().size() > 0  && !recordAccessUtilityHasRun) {
                recordAccessUtilityHasRun = true;
                RecordAccessUtility.resetNGOCObjectsSharing(accountIdsOldAffiliationMap,true);
            }
        }
    
    }

    public static void updateIsSharedGroup(Set<Id> retainedAccountIds){
        List<Account> accountsToUpdateSharedGroup = new List<Account>();
        for(Id objId: retainedAccountIds){
            accountsToUpdateSharedGroup.add(new Account(Id= objId, Is_Shared_Group__c = true));
        }
        
        if(!accountsToUpdateSharedGroup.isEmpty()){
            update accountsToUpdateSharedGroup;
        } 
    }
    
    public class QueueUpdateIsSharedGroup implements Queueable {        
        Set<Id> accountIds;
        public QueueUpdateIsSharedGroup(Set<Id> accountIds) {
            this.accountIds = accountIds;
        }
        public void execute(QueueableContext context) {
            updateIsSharedGroup(accountIds);
            
            if(doChainJob) {
                System.enqueueJob(new QueueMergePostProcessingFutureWrapper(accountIds));
            }
        }
    }

    public static void mergePostProcessingFutureWrapper(set<Id> accountIdSet) {
        PreferenceTriggerHandler.updateAccountPrefStrings(accountIdSet);
        AccountConstituentUpdater.updateAccountAllContactsDeceased(accountIdSet); 
    } 
    

    public class QueueMergePostProcessingFutureWrapper implements Queueable {
        Set<Id> accountIds;
        public QueueMergePostProcessingFutureWrapper(Set<Id> accountIds) {
            this.accountIds = accountIds;
        }
        public void execute(QueueableContext context) {
            mergePostProcessingFutureWrapper(accountIds);
        }
    }

    /*
    *Method beforeInsert
    *@description : calls on beforeInsert
    */

    private static void beforeInsert(List<Account> newList){
        accZipCode = new list<String>();
        listAccount = new list<Account>();

        for(Account acc : newList) {

            if((acc.RecordTypeId == organizationId || acc.RecordTypeId == houseHoldId)) {

                if(acc.BillingPostalCode != null && acc.BillingPostalCode.Split('-')[0] != null && acc.BillingPostalCode.Split('-')[0].length() == 5) {

                        accZipCode.add(acc.BillingPostalCode.Split('-')[0]);

                }
                listAccount.add(acc);
            }
            
            //If account from batch Context set boolean
            if(system.isbatch()){
                acc.Is_Shared_Group__c = true;
            }
            
            //I-318542 - populate sort name on organisation account
            if(acc.RecordTypeId == organizationId && acc.Name != null && acc.Sort_Name_Locked__c == false) {
                acc.Sort_Name__c = acc.Name;
            }
            
            //S-554448 - Populate Chapter for Accounts with only Affiliation no Zip no Chapter
            if(String.isBlank(acc.Chapter__c) && !String.isBlank(acc.Affiliation__c) && String.isBlank(acc.BillingPostalCode)) {
                acc.Chapter__c = String.valueOf(acc.Affiliation__c)+'A';
            }
        }

        if(!listAccount.IsEmpty()){
            UpdateAffiliationChapter();
        }
      // Updating Household Count on Account
        updateCountOfHouseholdRecords(newList,null);
        
    }

    /*
    *Method beforeUpdate
    *@description : calls on beforeUpdate
    */

    private static void beforeUpdate(List<Account> newList, Map<Id,Account> oldMap){
        Integer priority;
        accZipCode = new list<String>();
        listAccount = new list<Account>();
        List<String> choices = new List<String>();
        Map<String, Integer> salutationPriorityMap = new Map<String, Integer>();
        Map<Id, Map<String, Integer>> accountSalutationChoiceMap = new Map<Id, Map<String, Integer>>();
        for(Account acc : newList) {
            if(acc.Formal_Inside__c != oldMap.get(acc.Id).Formal_Inside__c && (!Utilities.invokedByContactTrigger) 
                && (!acc.Salutation_From_WF__c)) {
              acc.Is_Formal_Inside_Locked__c = true;    
            }
            if(acc.Formal_Outside_1__c  != oldMap.get(acc.Id).Formal_Outside_1__c  && (!Utilities.invokedByContactTrigger) 
                && (!acc.Salutation_From_WF__c)) {
              acc.Is_Formal_Outside_1_Locked__c  = true;    
            }
            if(acc.Formal_Outside_2__c  != oldMap.get(acc.Id).Formal_Outside_2__c  && (!Utilities.invokedByContactTrigger)) {
                acc.Is_Formal_Outside_2_Locked__c  = true;    
            }
            if(acc.Formal_Outside_3__c  != oldMap.get(acc.Id).Formal_Outside_3__c  && (!Utilities.invokedByContactTrigger)) {
                acc.Is_Formal_Outside_3_Locked__c  = true;    
            }
            if(acc.Informal_Inside__c  != oldMap.get(acc.Id).Informal_Inside__c  && (!Utilities.invokedByContactTrigger)) {
                acc.Is_Informal_Inside_Locked__c  = true;    
            }
            if(acc.Informal_Outside_1__c != oldMap.get(acc.Id).Informal_Outside_1__c && (!Utilities.invokedByContactTrigger)) {
              acc.Is_Informal_Outside_1_Locked__c = true;    
            }
            if(acc.Informal_Outside_2__c != oldMap.get(acc.Id).Informal_Outside_2__c && (!Utilities.invokedByContactTrigger)) {
              acc.Is_Informal_Outside_2_Locked__c = true;  
            }
            if(acc.Default_Email_Salutation__c  != oldMap.get(acc.Id).Default_Email_Salutation__c  && (!Utilities.invokedByContactTrigger)) {
              acc.Is_Email_Salutation_Locked__c = true;    
            }
            if(acc.Recognition_Formal__c  != oldMap.get(acc.Id).Recognition_Formal__c  && (!Utilities.invokedByContactTrigger)) {
              acc.Is_Recognition_Formal_Locked__c = true;    
            }
            if(acc.Recognition_Informal__c   != oldMap.get(acc.Id).Recognition_Informal__c   && (!Utilities.invokedByContactTrigger)) {
              acc.Is_Recognition_Informal_Locked__c = true;    
            }
            if(acc.Salutation_From_WF__c) {
              acc.Salutation_From_WF__c = False;    
            }
            if((oldMap.get(acc.Id).BillingPostalCode != acc.BillingPostalCode || oldMap.get(acc.Id).BillingCountry != acc.BillingCountry) && (acc.RecordTypeId == organizationId || acc.RecordTypeId == houseHoldId)) {

                if(acc.BillingPostalCode != null && acc.BillingPostalCode.Split('-')[0].length() == 5) {

                        accZipCode.add(acc.BillingPostalCode.Split('-')[0]);

                }
                listAccount.add(acc);
            }

            // updatePriorityOnSalutations Logic
            priority = 1;
            if(acc.Salutation_Choices__c != null && acc.Salutation_Choices__c != oldMap.get(acc.Id).Salutation_Choices__c) {
                choices = acc.Salutation_Choices__c.split(',');

                for(String salutation : choices) {
                    salutationPriorityMap.put(salutation,priority);
                    priority++;
                }

                accountSalutationChoiceMap.put(acc.Id, salutationPriorityMap);
            }
            
            //If account from batch Context set boolean
            if(system.isbatch() && acc.Affiliation__c  != oldMap.get(acc.Id).Affiliation__c){
                acc.Is_Shared_Group__c = true;
            }
            //Zendesk : #74075 - Identify the membership expiration date is populated first time
            if(oldMap.get(acc.Id).Membership_Expiration_date__c == null && acc.Membership_Expiration_date__c != null) {
                acc.FirstMembership__c = true;
            }
            
            //I-318542 - populate sort name on organisation account
            if(acc.RecordTypeId == organizationId && acc.Name != null 
              && acc.Sort_Name_Locked__c == false && acc.Name != oldMap.get(acc.Id).Name) {
                acc.Sort_Name__c = acc.Name;
            }
            
            //S-554448 - Populate Chapter for Accounts with only Affiliation no Zip no Chapter
            if(String.isBlank(acc.Chapter__c) && !String.isBlank(acc.Affiliation__c) && String.isBlank(acc.BillingPostalCode) 
              && (acc.Affiliation__c != oldMap.get(acc.Id).Affiliation__c || acc.Chapter__c != oldMap.get(acc.Id).Chapter__c 
                || acc.BillingPostalCode != oldMap.get(acc.Id).BillingPostalCode)) {
                acc.Chapter__c = String.valueOf(acc.Affiliation__c)+'A';
            }
        }

        if(!listAccount.IsEmpty()){
            UpdateAffiliationChapter();
        }

        // Check for affiliation changes (either direct change or via UpdateAffiliationChapter() above)
        // If we find an affiliation change and the old value isn't 'AA', write the old affiliation to 
        // the Previous State Affiliation field for use in processing state-to-state moves.
        // (where we need to ignore intermediate 'AA' steps)

        for (Account a : newList) {
            String oldAffil = oldMap.get(a.Id).Affiliation__c;
            if ((a.Affiliation__c != oldAffil) 
                && (oldAffil != 'AA')
                && String.isNotBlank(oldAffil)) {
                a.Previous_State_Affiliation__c = oldAffil;
                a.Previous_State_Affiliation_Date__c = Datetime.now();
            }
        }

        if(!accountSalutationChoiceMap.keySet().IsEmpty()){
            updatePriorityOnSalutations(accountSalutationChoiceMap, choices, salutationPriorityMap, priority);
        }
        // Updating Household Count on Account
        updateCountOfHouseholdRecords(newList,oldMap);
        
    }

    /*
    *Method afterInsert
    *@description : calls on afterInsert
    */

    private static void afterInsert(List<Account> newList){
        Map<Id,String> AccountIdToOldAffiliations = new Map<Id,String>();
        List<Account> listOfAccounts = new List<Account>();
        
        for(Account acc: newList){
            AccountIdToOldAffiliations.put(acc.Id,null);
            //checking if the record type is either houshold or Organization and auto account number is populated   
            if((acc.RecordTypeId == houseHoldId || acc.RecordTypeId == organizationId) && acc.Auto_Account_Number__c != null) {
                Account a  = new Account(Id = acc.Id);
                //passing the accounts to calculateCheckDigit method of utilities class for further processing 
                a.Override_Account_Number__c = String.valueOf(Utilities.calculateCheckDigit(acc.Auto_Account_Number__c)); 
                listOfAccounts.add(a);
            }
        }

        if(!AccountIdToOldAffiliations.KeySet().isEmpty() && !recordAccessUtilityHasRun){
           recordAccessUtilityHasRun = true;
            RecordAccessUtility.resetNGOCObjectsSharing(AccountIdToOldAffiliations,false);
        }
        
        //updating the accounts 
        if(!listOfAccounts.isEmpty()) {
            update listOfAccounts;
        }
    }

    /*
    *Method afterUpdate
    *@description : calls on afterUpdate
    */

    private static void afterUpdate(List<Account> newList, Map<Id, Account> newMap, Map<Id,Account> oldMap){
        Map<Id,String> AccountIdToOldAffiliations = new Map<Id,String>();
        Map<Id,String> AccountIdToNewAffiliations = new Map<Id,String>();
        Map<Id,String> AccountIdToPreviousStateAffiliations = new Map<Id,String>();
        Set<Id> setOfAccountIds = new set<Id>();

        for(Account acc: newList){
                if(oldMap.get(acc.Id).Affiliation__c != acc.Affiliation__c && oldMap.get(acc.Id).Affiliation__c != null){
                    AccountIdToOldAffiliations.put(acc.Id,oldMap.get(acc.Id).Affiliation__c);
                }
                else if(oldMap.get(acc.Id).Affiliation__c != acc.Affiliation__c && oldMap.get(acc.Id).Affiliation__c == null){
                    AccountIdToOldAffiliations.put(acc.Id,null);
                }

                if(oldMap.get(acc.Id).Restricted_Account__c != acc.Restricted_Account__c ){
                    AccountIdToOldAffiliations.put(acc.Id,oldMap.get(acc.Id).Affiliation__c);
                }
                
                // Detect a state-to-state move
                // If we're not going to 'AA' (used for blank zip codes) and the previous state affiliation was set 
                // less than an hour ago, we qualify.
                if ((acc.Affiliation__c != 'AA')
                    && String.isNotBlank(acc.Affiliation__c)
                    && String.isNotBlank(acc.Previous_State_Affiliation__c)
                    && (acc.Previous_State_Affiliation__c != acc.Affiliation__c)
                    && ((Datetime.now().getTime() - acc.Previous_State_Affiliation_Date__c.getTime()) < (60*60*1000))) {
                    AccountIdToNewAffiliations.put(acc.Id, acc.Affiliation__c);
                    AccountIdToPreviousStateAffiliations.put(acc.Id, acc.Previous_State_Affiliation__c);
                }
        }

        if(!AccountIdToOldAffiliations.KeySet().isEmpty() && !recordAccessUtilityHasRun) {
            recordAccessUtilityHasRun = true;
            RecordAccessUtility.resetNGOCObjectsSharing(AccountIdToOldAffiliations,true);
        }
        if(!AccountIdToNewAffiliations.KeySet().isEmpty()) {
            updateEmailPreferencesForAffiliateChange(AccountIdToNewAffiliations, AccountIdToPreviousStateAffiliations);
        }
        
      //populate sort name on Household Account    
      populateSortNameOnHouseholdAccounts(newList,oldMap);

      createOrUpdatePreferencesOnAccount(newList,oldMap);
    }

    private static void updateEmailPreferencesForAffiliateChange(Map<Id, String> newAffiliationMap, Map<Id, String> oldAffiliationMap) {
        try {
            List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();

            while (newAffiliationMap.size() > 0) {
                Map<Id, String> segmentNewAffiliationMap = new Map<Id, String>(), segmentOldAffiliationMap = new Map<Id, String>();

                // Unclear if it's okay to mutate the map while iterating over keySet(), so copy.
                for (Id key : new List<Id>(newAffiliationMap.keySet())) {
                    if (segmentNewAffiliationMap.size() < accountAsyncBatchMax) {
                        segmentNewAffiliationMap.put(key, newAffiliationMap.remove(key));
                        segmentOldAffiliationMap.put(key, oldAffiliationMap.get(key));
                    } else {
                        break;
                    }
                }

                newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='account_AffiliationChange', 
                                       Object_API_Name__c = 'Account',
                                       Params__c = JSON.serialize(new List<Map<Id, String>> { segmentNewAffiliationMap, segmentOldAffiliationMap })));
            }

            insert newAsyncRequests;        
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountTriggerHandler','updateEmailPreferencesForAffiliateChange', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }

    }

    /*
    *Method updatePriorityOnSalutations
    *@description :
    */

    private static void updatePriorityOnSalutations(Map<Id, Map<String, Integer>> accountSalutationChoiceMap, 
                                                    List<String> choices, Map<String, Integer> salutationPriorityMap, 
                                                    Integer priority) {
        List<rC_Bios__Salutation__c> salutationsToUpdate = new List<rC_Bios__Salutation__c>();


        for(rC_Bios__Salutation__c objSalutation : [SELECT Id, rC_Bios__Account__c, Priority__c, rC_Bios__Salutation_Type__c 
                                                    FROM rC_Bios__Salutation__c 
                                                    WHERE rC_Bios__Account__c IN: accountSalutationChoiceMap.keySet()]) {
            if(accountSalutationChoiceMap.containsKey(objSalutation.rC_Bios__Account__c)) {
                if(accountSalutationChoiceMap.get(objSalutation.rC_Bios__Account__c).containsKey(objSalutation.rC_Bios__Salutation_Type__c)) {
                    objSalutation.Priority__c = accountSalutationChoiceMap.get(objSalutation.rC_Bios__Account__c).get(objSalutation.rC_Bios__Salutation_Type__c);
                    salutationsToUpdate.add(objSalutation);
                } else if(objSalutation.Priority__c != 0) {
                    objSalutation.Priority__c = 0;
                    salutationsToUpdate.add(objSalutation);
                }
            }
        }

        if(salutationsToUpdate.size() > 0) {
            try{
                update salutationsToUpdate;
            } catch(Exception e) {
                 apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountTriggerHandler','updatePriorityOnSalutations',e.getMessage());
                 log.logException(e);
                 log.saveLogs();
            }
        }
    }

    /*
*
*Method UpdateAffiliationChapter
*@param : newList
*@param : oldMap
*It checks if Account BillingPostalCode on Account matches Name field on Zip Affiliate object
*It then update Account Affiliates and Chapter field on Account with Zip Affiliate
*Also,if Account country is US/United States/USA or null
*Affiliate is updated with 'NN'(All Affiliate)
*if Account country does not contain any of these values
*Affiliate is updated with 'ZF'(Foreign)
*
*/

    private static void UpdateAffiliationChapter() {
        mapZipCode = new Map<String,Zip_Affiliate__c>();
        if(accZipCode != null) {
            for(Zip_Affiliate__c zp : [SELECT Name,Affiliation__c,Chapter__c
                                       FROM Zip_Affiliate__c
                                       WHERE Name IN: accZipCode]) {
              mapZipCode.put(zp.Name,zp);
    
            }
        }
        for(Account newAcc : listAccount) {
          if(newAcc.Lock_Affiliation__c == false) {
                if(newAcc.BillingCountry == 'US' || newAcc.BillingCountry == 'United States' || newAcc.BillingCountry == 'USA'
                || newAcc.BillingCountry == '' || newAcc.BillingCountry == null) {
                    if((newAcc.BillingPostalCode != null && newAcc.BillingPostalCode.Split('-')[0] != null) 
                        && (newAcc.BillingPostalCode.Split('-')[0].length() > 5 || newAcc.BillingPostalCode.Split('-')[0].length() < 5)) {
                        if(String.isBlank(newAcc.Affiliation__c)) {
                            newAcc.Affiliation__c = 'NN';
                        }
                        if(String.isBlank(newAcc.Chapter__c)) {
                            newAcc.Chapter__c = Label.Default_Chapter_for_NN;
                        }
                    }
                    else if((newAcc.BillingPostalCode != null && newAcc.BillingPostalCode.Split('-')[0] != null) 
                             && newAcc.BillingPostalCode.Split('-')[0].length() == 5) {
                        if(newAcc.BillingPostalCode.Split('-')[0] == '00000') {
                            if(String.isBlank(newAcc.Affiliation__c)) {
                                newAcc.Affiliation__c = 'AA';
                                newAcc.Chapter__c = Label.Default_Chapter_for_AA;
                            }
                        }
                        else if(mapZipCode.containsKey(newAcc.BillingPostalCode.Split('-')[0])) {
                            newAcc.Affiliation__c = mapZipCode.get(newAcc.BillingPostalCode.Split('-')[0]).Affiliation__c;
                            newAcc.Chapter__c = mapZipCode.get(newAcc.BillingPostalCode.Split('-')[0]).Chapter__c;
                        }
                        else {
                            if(String.isBlank(newAcc.Affiliation__c)) {
                                newAcc.Affiliation__c = 'NN';
                                newAcc.Chapter__c = Label.Default_Chapter_for_NN;
                            }  
                        }
                    }
                    else if(newAcc.BillingPostalCode == null || newAcc.BillingPostalCode == '') {
                        
                        if(String.isBlank(newAcc.Affiliation__c)) {
                            newAcc.Affiliation__c = 'AA';
                            newAcc.Chapter__c = Label.Default_Chapter_for_AA;
                        }
                    }
                }
                else {
              if(String.isBlank(newAcc.Affiliation__c)) {
                  newAcc.Affiliation__c = 'ZF';
                  newAcc.Chapter__c = Label.Default_Chapter_for_ZF;
              }
            }
          }
        }
    }

    private static void updateCountOfHouseholdRecords(List<Account> newList, map<Id,Account> oldMap) {
      
      List<Account> listOfAccounts = new List<Account>();
      for(Account theAccount : newList) {
          if(theAccount.RecordTypeId == houseHoldId && (oldMap== null ||
             (oldMap!= null && (theAccount.rC_Bios__Preferred_Contact__c != oldMap.get(theAccount.Id).rC_Bios__Preferred_Contact__c
                         || theAccount.rC_Bios__Secondary_Contact__c != oldMap.get(theAccount.Id).rC_Bios__Secondary_Contact__c
                         || theAccount.Title_Of_Preferred_Contact__c != oldMap.get(theAccount.Id).Title_Of_Preferred_Contact__c)))) {
              if((theAccount.rC_Bios__Secondary_Contact__c  != null && theAccount.rC_Bios__Preferred_Contact__c!= null)
                ||  (pluralPrefixes.contains(theAccount.Title_Of_Preferred_Contact__c))) {
                theAccount.Household_Count__c = 2;
              }
              else if((theAccount.rC_Bios__Secondary_Contact__c  == null && theAccount.rC_Bios__Preferred_Contact__c!= null) ||
                      (theAccount.rC_Bios__Secondary_Contact__c  != null && theAccount.rC_Bios__Preferred_Contact__c== null)) {
                theAccount.Household_Count__c = 1;
              }
              else {
                theAccount.Household_Count__c = null;
              }
            }
        }
    }
    
    // Issue - I-318542
    // purpose - to populate sort name on household accounts if not locked 
    // created by - Aashita Sharma 
    private static void populateSortNameOnHouseholdAccounts(List<Account> newList, map<Id,Account> oldMap) {
        List<Account> lstAccountToUpdate = new List<Account>();
        
        for(Account acc : [SELECT id, RecordTypeID, rC_Bios__Preferred_Contact__c, 
                                  rC_Bios__Preferred_Contact__r.LastName, rC_Bios__Preferred_Contact__r.FirstName, 
                                  Name, Sort_Name__c, Sort_Name_Locked__c
                           FROM Account
                           WHERE Id IN: newList
                           And RecordTypeID =: houseHoldId]) {
           if(acc.RecordTypeId == houseHoldId && acc.rC_Bios__Preferred_Contact__c != null && 
             acc.Sort_Name_Locked__c == false && (oldMap == null || (oldMap!= null  
             && acc.rC_Bios__Preferred_Contact__c != oldMap.get(acc.Id).rC_Bios__Preferred_Contact__c))) {
                acc.Sort_Name__c = (acc.rC_Bios__Preferred_Contact__r.LastName!= '' 
                                    && acc.rC_Bios__Preferred_Contact__r.LastName != null) 
                                    ? String.ValueOf(acc.rC_Bios__Preferred_Contact__r.LastName): '' ;
                acc.Sort_Name__c += (acc.rC_Bios__Preferred_Contact__r.FirstName != '' 
                                    && acc.rC_Bios__Preferred_Contact__r.FirstName != null) 
                                    ? ', '+String.ValueOf(acc.rC_Bios__Preferred_Contact__r.FirstName): '';
                lstAccountToUpdate.add(acc);
            }
        }
        
        if(!lstAccountToUpdate.isEmpty()) {
            try{
              update lstAccountToUpdate;
            } catch(Exception e) {
                 apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountTriggerHandler','',
                                            'populateSortNameOnHouseholdAccounts error:: '+e.getMessage());
                 log.logException(e);
                 log.saveLogs();
            }
        }
    }

    private static void createOrUpdatePreferencesOnAccount(List<Account> newList, map<Id,Account> oldMap) {

        Set<Id> setOfAccountIds = new Set<Id>();
      for(Account theAcc : newList) {
          if(oldMap.get(theAcc.Id).PG_Level__c != theAcc.PG_Level__c && theAcc.PG_Level__c != null) {
          setOfAccountIds.add(theAcc.Id);
        }
      }
        if(setOfAccountIds.isEmpty()) {
            return;
        }
        Boolean hasPZcode = false;
        Boolean hasExistingCode = false;
        map<Account,String> mapOfAccountAndKey = new map<Account,String>();
        List<rC_Bios__Preference__c> listOfPreferences = new List<rC_Bios__Preference__c>();
        for(Account theAcc : [SELECT Id, PG_Level__c, (SELECT rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r 
                                                       WHERE rC_Bios__Code_Value__c IN : preferenceCodes)
                              FROM Account
                              WHERE Id IN : setOfAccountIds]) {
          for(rC_Bios__Preference__c pref : theAcc.rC_Bios__Preferences__r) {
            if(pref.rC_Bios__Code_Value__c == 'PZ') {
              hasPZcode = true;
            }
            if(preferenceCodesWithoutPZ.contains(pref.rC_Bios__Code_Value__c)) {
              hasExistingCode = true;
            }
          }
          String key = hasPZcode ? 'T' : 'F';
          key = hasExistingCode ? key + 'T' : key + 'F';
          mapOfAccountAndKey.put(theAcc,key);
          hasPZcode = false;
          hasExistingCode = false;
        }

        for(Account theAcc : mapOfAccountAndKey.keyset()) {
          String code = theAcc.PG_Level__c <= 99999 ? 'PC' : ((theAcc.PG_Level__c <= 499999 && theAcc.PG_Level__c >= 100000) ? 'PB'
                                   :( theAcc.PG_Level__c >= 500000 ? 'PA' : ''));
          if(mapOfAccountAndKey.get(theAcc) == 'FF' && code!= '') {
            listOfPreferences.add(new rC_Bios__Preference__c(rC_Bios__Account__c = theAcc.Id, rC_Bios__Code_Value__c = code,
                                    rC_Bios__Subcategory__c = 'Planned Giving', rC_Bios__Category__c = 'Programmatic'));
          }
          else if(mapOfAccountAndKey.get(theAcc) == 'FT' && code!= '') {
            // Assuming there will be only one preference record with PA, PB or PC Preference Codes
            if(theAcc.rC_Bios__Preferences__r.get(0).rC_Bios__Code_Value__c != code) {
              listOfPreferences.add(new rC_Bios__Preference__c(Id = theAcc.rC_Bios__Preferences__r.get(0).Id, rC_Bios__Code_Value__c = code,
                                    rC_Bios__Subcategory__c = 'Planned Giving', rC_Bios__Category__c = 'Programmatic'));
            }
          }
        }
        if(!listOfPreferences.isEmpty()) {
            try{
              upsert listOfPreferences;
            } catch(Exception e) {
                 apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountTriggerHandler',
                                                                  'createOrUpdatePreferencesOnAccount',e.getMessage());
                 log.logException(e);
                 log.saveLogs();
            }
        }
    }

    public static void resetRecordAccessUtilityHasRun(){recordAccessUtilityHasRun = false;}
}