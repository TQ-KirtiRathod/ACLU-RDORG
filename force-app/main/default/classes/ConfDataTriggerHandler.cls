/*
*
*Name  :  ConfDataTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  March 15, 2016
*Purpose :  Handler Class for Confidential Data Trigger
            Logic includes
            - Apex Sharing
            - Limits Create access based on custom logic
            (T-555635)
*
*/
public with sharing class ConfDataTriggerHandler {
    
    public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    public static double accountAsyncBatchMax;
    
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            accountAsyncBatchMax = q.Batch_Size_Account__c;
        } else {
            accountAsyncBatchMax = 100;
        }
    }
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */ 
    public static void mainEntry(List<Confidential_Data__c> newList, List<Confidential_Data__c> oldList, Map<Id, Confidential_Data__c> newMap, Map<Id, Confidential_Data__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('ConfidentialData_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            // It is called on after 
            if(isAfter){
                //Insert
                if(isInsert){
                    afterInsert(newList);
                }  
                
                //Update
                if(isUpdate){
                    afterUpdate(newMap, oldMap);
                }
            }
        }
    }
    
    /*
    *Method afterInsert
    *@description : calls on afterInsert
    */ 
    
    private static void afterInsert(List<Confidential_Data__c> newList){
        Set<Id> confidentialIds = new Set<Id>();
        Map<Id, Set<Id>> confDataAccountMap = new Map<Id, Set<Id>>();
        
        for(Confidential_Data__c cnf: newList){
            confidentialIds.add(cnf.Id);
            if(cnf.Account__c != null) {
            	if(!confDataAccountMap.containsKey(cnf.Id)) {
	                confDataAccountMap.put(cnf.Account__c, new Set<Id>());
	            }
	            confDataAccountMap.get(cnf.Account__c).add(cnf.Id);
            }
        }
        
        if(!confidentialIds.isEmpty() && Utilities.CanUseFutureContext())
            setConfidentialShareRecords(confidentialIds, false, null);
            
        if(!confDataAccountMap.isEmpty()) {
            ConfDataTriggerHandler.shareConfDataWithAccountTeam(confDataAccountMap);
        }  
    }
    
    /*    
    *
    *Method onAfterUpdate
    *@param : newMap
    *@param : OldMap
    *@description : calls on afterUpdate
    */

    public static void afterUpdate(Map<Id,Confidential_Data__c> newMap, Map<Id,Confidential_Data__c> OldMap){
        Set<Id> confidentialIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        for(Confidential_Data__c cnf: newMap.Values()){
            //Account Changed
            if(OldMap.get(cnf.Id).Account__c != cnf.Account__c){
                //Old account Id
                if(OldMap.get(cnf.Id).Account__c != null ){
                    accountIds.add(OldMap.get(cnf.Id).Account__c);
                }
                
                confidentialIds.add(cnf.Id);
            }
            //Contact Changed
            if(OldMap.get(cnf.Id).Contact__c != cnf.Contact__c){
                //Old Contact Id
                if(OldMap.get(cnf.Id).Contact__c != null ){
                    contactIds.add(OldMap.get(cnf.Id).Contact__c);
                }
                confidentialIds.add(cnf.Id);
            }
            //Opportunity Changed
            if(OldMap.get(cnf.Id).Opportunity__c != cnf.Opportunity__c){
                //Old Opportunity Id
                if(OldMap.get(cnf.Id).Opportunity__c != null ){
                    opportunityIds.add(OldMap.get(cnf.Id).Opportunity__c);
                }
                confidentialIds.add(cnf.Id);
            }
        }
        
        // Collect  Old Opportunity Affiliations
        for(Opportunity opp: [SELECT Id, account.Affiliation__c, accountId FROM Opportunity WHERE Id =: opportunityIds]){
            if(opp.accountId != null && opp.account.Affiliation__c != null){
                OldAffiliations.add(opp.account.Affiliation__c);
            }
        }
        
        // Collect Old Contact Affiliations
        for(Contact con: [SELECT Id, account.Affiliation__c,accountId FROM Contact WHERE Id =: contactIds]){
            if(con.accountId != null && con.account.Affiliation__c != null){
                OldAffiliations.add(con.account.Affiliation__c);
            }
        }
        
        // Collect Old Account Affiliations
        for(Account acc: [SELECT id,Affiliation__c FROM Account WHERE Id =: accountIds]){
            if(acc.Affiliation__c != null && acc.Affiliation__c != null)
                OldAffiliations.add(acc.Affiliation__c);
        }
        
        if(!confidentialIds.isEmpty() && Utilities.CanUseFutureContext())
            setConfidentialShareRecords(confidentialIds, true, OldAffiliations);
    }
    
    /*    
    *
    *Method shareConfDataWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void shareConfDataWithAccountTeam(Map<Id, Set<Id>> confDataAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (confDataAccountMap.size() > 0) {
            Map<Id, Set<Id>> newConfDataAccountMap = new Map<Id, Set<Id>>();

            for (Id key : confDataAccountMap.KeySet()) {
                if (newConfDataAccountMap.size() < accountAsyncBatchMax) {
                    newConfDataAccountMap.put(key, confDataAccountMap.get(key));
                    confDataAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'Confidential_Data__c',
                                   Params__c = JSON.serialize(newConfDataAccountMap)));
        }
        
        try {
            insert newAsyncRequests;        
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('ConfDataTriggerHandler','setConfidentialShareRecords', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    /*    
    *
    *Method setConfidentialShareRecords
    *@param : newMap
    *It creates the share records based on the their accountAffiliation.
    */
    //@future
    public static void setConfidentialShareRecords(Set<Id> confidentialIds, Boolean isUpdate, List<String>oldAffiliations){
        Map<Id,String> mapconfidentialIdToAffiliate = new Map<Id,String>();
        Map<Id, Boolean> mapconfidentialToRestricted = new Map<Id, Boolean> ();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        // Collect the confidentialIdToAffiliation
        for(Confidential_Data__c Cnf: [SELECT Id, Account__c, Account__r.Affiliation__c, Account__r.Restricted_Account__c, Contact__c, Contact__r.Account.Affiliation__c, Contact__r.Account.Restricted_Account__c, Opportunity__c, Opportunity__r.account.Affiliation__c, Opportunity__r.account.Restricted_Account__c  FROM Confidential_Data__c WHERE Id =: confidentialIds]){
            //Account Affiliate
            if(Cnf.Account__c != null && Cnf.Account__r.Affiliation__c != null){
                mapconfidentialIdToAffiliate.put(Cnf.Id, Cnf.Account__r.Affiliation__c);
                mapconfidentialToRestricted.put(Cnf.Id, Cnf.Account__r.Restricted_Account__c);
            }
            //Contact Affiliate
            if(Cnf.Contact__c != null && Cnf.Contact__r.Account.Affiliation__c != null){
                mapconfidentialIdToAffiliate.put(Cnf.Id, Cnf.Contact__r.Account.Affiliation__c);
                mapconfidentialToRestricted.put(Cnf.Id, Cnf.Contact__r.Account.Restricted_Account__c);
            }
            //Opportunity Affiliate
            if(Cnf.Opportunity__c != null && Cnf.Opportunity__r.Account.Affiliation__c != null){
                mapconfidentialIdToAffiliate.put(Cnf.Id, Cnf.Opportunity__r.Account.Affiliation__c);
                mapconfidentialToRestricted.put(Cnf.Id, Cnf.Opportunity__r.Account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        if(OldAffiliations != null){
            for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapconfidentialIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL OR Name=: OldAffiliations]){
                mapGroupNameToId.put(grp.Name,grp.Id);
            }
        }
        else if(OldAffiliations == null){
            for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapconfidentialIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
                mapGroupNameToId.put(grp.Name,grp.Id);
            }
        }
        //Delete the Existing Share records
        if(isUpdate){
            deleteConfidentialSharingRecords(confidentialIds, oldAffiliations, mapGroupNameToId, mapconfidentialToRestricted);
        }
        
        // Insert the new Affiliations records.
        InsertConfidentialShareRecords(mapconfidentialIdToAffiliate, mapGroupNameToId, mapconfidentialToRestricted);
    }
    
    /*
    *
    *Method: InsertConfidentialShareRecords
    *@param : Map<Id,String> (Confidential Id to AffiliateName)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Confidential Object. 
    */ 
    public static void InsertConfidentialShareRecords(Map<Id,String> mapConfidentialIdToAffiliate, Map<String,Id> mapGroupNameToId, Map<Id, Boolean> mapconfidentialToRestricted){
        
        List<Confidential_Data__share> confidentialSharesToBeInsert = new List<Confidential_Data__share>();
        //Create the ActionPlan Share Records to all of Objects
        
        for(Id objId: mapConfidentialIdToAffiliate.keyset()){
            
            if(mapconfidentialToRestricted.get(ObjId) == false && mapConfidentialIdToAffiliate.get(ObjId) != null && mapGroupNameToId.get(mapConfidentialIdToAffiliate.get(ObjId)) != null){
                Confidential_Data__share cnfShare = new Confidential_Data__share();
                cnfShare.ParentId = ObjId;
                cnfShare.AccessLevel = 'Edit';
                cnfShare.UserOrGroupId = mapGroupNameToId.get(mapConfidentialIdToAffiliate.get(ObjId));
                confidentialSharesToBeInsert.add(cnfShare);
            }
            
            //Apex Share for National group
            if(mapconfidentialToRestricted.get(ObjId) == false && mapGroupNameToId.get(ALLACLU) != null){
                Confidential_Data__share cnfShare = new Confidential_Data__share();
                cnfShare.ParentId = ObjId;
                cnfShare.AccessLevel = 'Read';
                cnfShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                confidentialSharesToBeInsert.add(cnfShare);
            }
            
            //Apex Share for National group
            if(mapconfidentialToRestricted.get(ObjId) == false && mapGroupNameToId.get(NATIONAL) != null){
                Confidential_Data__share cnfShare = new Confidential_Data__share();
                cnfShare.ParentId = ObjId;
                cnfShare.AccessLevel = 'Edit';
                cnfShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                confidentialSharesToBeInsert.add(cnfShare);
            }
        }
       
        system.debug('confidentialSharesToBeInsert>>>'+confidentialSharesToBeInsert);
        // Insert the ActionPlan share Objects
        if(!confidentialSharesToBeInsert.IsEmpty()) {
            try{
                insert confidentialSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ConfDataTriggerHandler','InsertConfidentialShareRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    /*
    *
    *Method: deleteConfidentialSharingRecords
    *@param : setId (Confidential Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to Confidential Object. 
    *
    */ 
    public static void deleteConfidentialSharingRecords(Set<Id> confidentialIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, Map<Id, Boolean> mapconfidentialToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> confidentialPrivateIds = new Set<Id>();
        List<Confidential_Data__share> confidentialSharesToBeDelete = new List<Confidential_Data__share> ();
        //Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }
        
        // Collect Confidential Share records having edit access 
        for(Confidential_Data__share cnfShare: [SELECT Id, AccessLevel, ParentId FROM Confidential_Data__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:confidentialIds]){
            confidentialSharesToBeDelete.add(cnfShare);
        }
        
        // Delete ALL ACLU if the Confidetial Data is Private.
        for(Id cnfId: confidentialIds){
            if(mapconfidentialToRestricted.get(cnfId) == true){
                confidentialPrivateIds.add(cnfId);
            }
        }
        if(!confidentialPrivateIds.IsEmpty()){
            for(Confidential_Data__share cnfShare: [SELECT Id, AccessLevel, ParentId FROM Confidential_Data__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:confidentialPrivateIds]){
                confidentialSharesToBeDelete.add(cnfShare);
            }
        }
        // Delete the ActionPlan Share records.
        if(!confidentialSharesToBeDelete.isEmpty()){
            try{
                delete confidentialSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ConfDataTriggerHandler','deleteConfidentialSharingRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
        
}