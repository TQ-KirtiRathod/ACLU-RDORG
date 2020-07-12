/*
*
*Name  :  SalutationTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose :  Handler Class for Salutation Trigger
            Logic includes
            - Apex Sharing
            - Limits Create access based on custom logic
            (T-555635)
*
*/

public with sharing class SalutationTriggerHandler {

    Public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    public static double accountAsyncBatchMax;
    public static Map<String, Boolean> userAccessMap;
    
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            accountAsyncBatchMax = q.Batch_Size_Account__c;
        } else {
            accountAsyncBatchMax = 100;
        }
        userAccessMap = new Map<String, Boolean>();
    }
    
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */ 
    public static void mainEntry(List<rC_Bios__Salutation__c > newList, List<rC_Bios__Salutation__c> oldList, Map<Id, rC_Bios__Salutation__c> newMap, Map<Id, rC_Bios__Salutation__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        
        //if trigger is active
        if(TriggerState.isActive('Salutation_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            // It is called on before insert
            if(isBefore){
                if(isInsert){
                    onBeforeInsert(newList);
                }         
                
                if(isDelete){
                    onBeforeDelete(oldList);
                }     
            }
            
            // It is called on after 
            if(isAfter){
                if(isInsert){
                    onAfterInsert(newList);
                }
                if(isUpdate){
                    onAfterUpdate(newMap, oldMap);
                }
            }
        }
        
    }
    
    /*    
    *
    *Method onBeforeInsert
    *@param : newList
    *
    */
    public static void onBeforeInsert(List<rC_Bios__Salutation__c> newList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        for(rC_Bios__Salutation__c obj: newList){
            if(obj.rC_Bios__Account__c != null){
                accountIds.add(obj.rC_Bios__Account__c);
            }
            
            if(obj.rC_Bios__Contact__c != null){
                contactIds.add(obj.rC_Bios__Contact__c);
            }
        }
        
        hasPermission(accountIds, contactIds, newList);
    }
    
    /*    
    *
    *Method onBeforeDelete
    *@param : oldList
    *
    */
    public static void onBeforeDelete(List<rC_Bios__Salutation__c> oldList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        for(rC_Bios__Salutation__c obj: oldList){
            if(obj.rC_Bios__Account__c != null){
                accountIds.add(obj.rC_Bios__Account__c);
            }
            
            if(obj.rC_Bios__Contact__c != null){
                contactIds.add(obj.rC_Bios__Contact__c);
            }
        }
        
        hasPermission(accountIds, contactIds, oldList);
    }
    
    /*    
    *
    *Method onAfterInsert
    *@param : newList
    *
    */
    public static void onAfterInsert(List<rC_Bios__Salutation__c> newList) {
        Set<Id> salutationIds = new Set<Id>();
        Map<Id, Set<Id>> salAccountMap = new Map<Id, Set<Id>>();
        
        for(rC_Bios__Salutation__c sl: newList) {
            if(sl.rC_Bios__Account__c != null || sl.rC_Bios__Contact__c != null) {
                salutationIds.add(sl.Id);
            }
            if(sl.rC_Bios__Account__c != null) {
            	if(!salAccountMap.containsKey(sl.rC_Bios__Account__c)) {
	                salAccountMap.put(sl.rC_Bios__Account__c, new Set<Id>());
	            }
	            salAccountMap.get(sl.rC_Bios__Account__c).add(sl.Id);
            }
        }
        if(!salutationIds.isEmpty() && Utilities.CanUseFutureContext()) {
            setSalutationShareRecords(salutationIds);
        }
        
        if(!salAccountMap.isEmpty()) {
            SalutationTriggerHandler.shareSalWithAccountTeam(salAccountMap);
        } 
    }
    
    /*    
    *
    *Method hasCreatePermission
    *@param : newList
    *It checks the createPermissions.
    *
    */
    public static void hasPermission(Set<Id> accountIds, Set<Id> contactIds, List<rC_Bios__Salutation__c> newList){
        
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, ID> mapContactIdToAccountId = new Map<ID, ID>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();
        
        for(Contact con: [SELECT accountId FROM Contact WHERE Id=: contactIds ]){
            accountIds.add(con.accountId);
            mapContactIdToAccountId.put(con.Id,con.accountId);
        }
        
        
        for(Account acc: [SELECT id,Affiliation__C FROM Account WHERE Id =: accountIds]){
            mapAccountIdToAffiliation.put(acc.Id,acc.Affiliation__c);
        }
        
        if(!accountIds.isEmpty()) {
            for(Account_Team__c objTeam : [ SELECT Id, Grant_Edit_Access__c, Team_Member__c, Account__c 
                                            FROM Account_Team__c 
                                            WHERE Account__c IN: accountIds]) {
                userAccessMap.put(objTeam.Account__c+'-'+objTeam.Team_Member__c, objTeam.Grant_Edit_Access__c);
            }
        }
        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(mapAccountIdToAffiliation.Values());
        
        for(rC_Bios__Salutation__c obj: newList){
            if((userAccessMap.containsKey(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId()) && !userAccessMap.get(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId())) ||
                    !userAccessMap.containsKey(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId())) {
                if(obj.rC_Bios__Account__c != null){
                    if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account__c))!= null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account__c))){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
            }
            
            if(obj.rC_Bios__Contact__c != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact__c))) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact__c)))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
        }
    }
  
  
  
    /*    
    *
    *Method shareSalWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void shareSalWithAccountTeam(Map<Id, Set<Id>> salAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (salAccountMap.size() > 0) {
            Map<Id, Set<Id>> newSalAccountMap = new Map<Id, Set<Id>>();

            for (Id key : salAccountMap.KeySet()) { 
                if (newSalAccountMap.size() < accountAsyncBatchMax) {
                    newSalAccountMap.put(key, salAccountMap.get(key));
                    salAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'rC_Bios__Salutation__c',
                                   Params__c = JSON.serialize(newSalAccountMap)));
        }
        
        try {
            insert newAsyncRequests;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('SalutationTriggerHandler','shareSalWithAccountTeam', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    /*    
    *
    *Method setSalutationShareRecords
    *@param : newMap
    *It creates the share records based on the their accountAffiliation.
    *
    */
    //@future
    public static void setSalutationShareRecords(Set<Id> salutationIds){
        //variables
        Map<Id,String> mapSalutationIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapSalutationIdToRestricted = new map<Id,Boolean> ();
        
        // Collect the AccountIds
        for(rC_Bios__Salutation__c mapSal: [SELECT Id, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Contact__r.Account.Restricted_Account__c, rC_Bios__Contact__r.Account.Affiliation__c, rC_Bios__Contact__c, rC_Bios__Contact__r.AccountId, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Salutation__c WHERE Id =: salutationIds]){
            if(mapSal.rC_Bios__Account__c != null && mapSal.rC_Bios__Account__r.Affiliation__c != null){
                mapSalutationIdToAffiliate.put(mapSal.Id,mapSal.rC_Bios__Account__r.Affiliation__c);
                mapSalutationIdToRestricted.put(mapSal.Id,mapSal.rC_Bios__Account__r.Restricted_Account__c);
            }
                
            //Contact Accounts Affiliations Relations
            if(mapSal.rC_Bios__Contact__c != null && mapSal.rC_Bios__Contact__r.AccountId != null && mapSal.rC_Bios__Contact__r.Account.Affiliation__c != null ){
                mapSalutationIdToAffiliate.put(mapSal.Id,mapSal.rC_Bios__Contact__r.Account.Affiliation__c);
                mapSalutationIdToRestricted.put(mapSal.Id,mapSal.rC_Bios__Contact__r.Account.Restricted_Account__c);
            }
        }
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapSalutationIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertSalutationSharingRecords (mapSalutationIdToAffiliate, mapGroupNameToId, mapSalutationIdToRestricted);
    }
    
    /*    
    *
    *Method onAfterUpdate
    *@param : newMap
    *@param : OldMap
    *It checks whether the Account/Contact Lookup changed.
    *
    */
    public static void onAfterUpdate(Map<Id,rC_Bios__Salutation__c> newMap, Map<Id,rC_Bios__Salutation__c> OldMap){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> salutationIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        
        for(rC_Bios__Salutation__c sl: newMap.Values()){
            if(OldMap.get(sl.Id).rC_Bios__Account__c != sl.rC_Bios__Account__c){
                accountIds.add(OldMap.get(sl.Id).rC_Bios__Account__c);
                salutationIds.add(sl.Id);
            }
            
            if(OldMap.get(sl.Id).rC_Bios__Contact__c != sl.rC_Bios__Contact__c){
                accountIds.add(OldMap.get(sl.Id).rC_Bios__Contact__r.accountId);
                salutationIds.add(sl.Id);
                contactIds.add(OldMap.get(sl.Id).rC_Bios__Contact__c);
            }
        }
        
        for(Contact con: [SELECT Id,account.Affiliation__c,accountId FROM Contact WHERE Id =: contactIds]){
            if(con.accountId != null )
                accountIds.add(con.accountId);
        }
        
        for(Account acc: [SELECT id,Affiliation__c FROM Account WHERE Id =: accountIds]){
            if(acc.Affiliation__c != null)
                OldAffiliations.add(acc.Affiliation__c);
        }
        if(!OldAffiliations.IsEmpty()){
            resetSalutationShareRecords(salutationIds,OldAffiliations);
        }
    }
    
    /*    
    *
    *Method resetSalutationShareRecords
    *@param : Set<Id> (salutationIds)
    *@param : List<String> OldAffiliations
    *It resets the share records based on the their account Affiliation.
    *
    */
    //@future
    public static void resetSalutationShareRecords (Set<Id> salutationIds, List<String> OldAffiliations){
        //variables
        Map<Id,String> mapSalutationIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapSalutationIdToRestricted = new map<Id,Boolean> ();
        
        // Collect the AccountIds
        for(rC_Bios__Salutation__c mapSal: [SELECT Id, rC_Bios__Contact__r.Account.Restricted_Account__c, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Contact__r.Account.Affiliation__c, rC_Bios__Contact__c, rC_Bios__Contact__r.AccountId, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Salutation__c WHERE Id =: salutationIds]){
            if(mapSal.rC_Bios__Account__c != null && mapSal.rC_Bios__Account__r.Affiliation__c != null){
                mapSalutationIdToAffiliate.put(mapSal.Id,mapSal.rC_Bios__Account__r.Affiliation__c);
                mapSalutationIdToRestricted.put(mapSal.Id,mapSal.rC_Bios__Account__r.Restricted_Account__c);
            }
                
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
        RecordAccessUtility.InsertSalutationSharingRecords (mapSalutationIdToAffiliate, mapGroupNameToId, mapSalutationIdToRestricted);
    }
}