/*
*
*Name  :  ProsResearchTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  March 15, 2016
*Purpose :  Handler Class for Prospect Research Trigger
            Logic includes
            - Apex Sharing
            - Limits Create access based on custom logic
            (T-555635)
*Modified by :: roundCorner Inc. :: 11-Feb-2019 :: Zendesk: #56321
*/

public with sharing class ProsResearchTriggerHandler {
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
    public static void mainEntry(List<Prospect_Research__c> newList, List<Prospect_Research__c> oldList, Map<Id, Prospect_Research__c> newMap, Map<Id, Prospect_Research__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('ProspectResearch_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
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
            //It is called on before
            if(isBefore){
                //Insert
                if(isInsert){
                    beforeInsert(newList);
                }
                if(isUpdate) {
                    beforeUpdate(newMap, oldMap);
                }
            }
        }
    }
    
    /*
    *Method afterInsert
    *@description : calls on afterInsert
    */ 
    
    private static void afterInsert(List<Prospect_Research__c> newList){
        Set<Id> prospectIds = new Set<Id>();
         Map<Id, Set<Id>> prosResearchAccountMap = new Map<Id, Set<Id>>();
         
        for(Prospect_Research__c pr: newList){
            prospectIds.add(pr.Id);
            if(pr.Account__c != null) {
                if(!prosResearchAccountMap.containsKey(pr.Account__c)) {
                    prosResearchAccountMap.put(pr.Account__c, new Set<Id>());
                }
                prosResearchAccountMap.get(pr.Account__c).add(pr.Id);
            }
        }
        
        if(!prospectIds.isEmpty() && Utilities.CanUseFutureContext()){
            setProspectShareRecords(prospectIds, false, null);
        }
        
        if(!prosResearchAccountMap.isEmpty()) {
            ProsResearchTriggerHandler.sharePResearchWithAccountTeam(prosResearchAccountMap);
        }
    }
    
     /*    
    *
    *Method onAfterUpdate
    *@param : newMap
    *@param : OldMap
    *@description : calls on afterUpdate
    */

    public static void afterUpdate(Map<Id,Prospect_Research__c> newMap, Map<Id,Prospect_Research__c> OldMap){
        Set<Id> prospectIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        List<String> OldAffiliations = new List<String>();
        for(Prospect_Research__c pr: newMap.Values()){
            //Account Changed
            if(OldMap.get(pr.Id).Account__c != pr.Account__c){
                //Old account Id
                if(OldMap.get(pr.Id).Account__c != null ){
                    accountIds.add(OldMap.get(pr.Id).Account__c);
                }
                
                prospectIds.add(pr.Id);
            }
            //Contact Changed
            if(OldMap.get(pr.Id).Contact__c != pr.Contact__c){
                //Old Contact Id
                if(OldMap.get(pr.Id).Contact__c != null ){
                    contactIds.add(OldMap.get(pr.Id).Contact__c);
                }
                prospectIds.add(pr.Id);
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
        
        if(!prospectIds.isEmpty() && Utilities.CanUseFutureContext()){
            setProspectShareRecords(prospectIds, true, OldAffiliations);
        }
    }
    
        /*
    *Method beforeInsert
    *@description : calls on beforeInsert
    */ 
    
    private static void beforeInsert(List<Prospect_Research__c> newList){
        String otherCharitableId = Schema.SObjectType.Prospect_Research__c.getRecordTypeInfosByName().get('Other Charitable Giving').getRecordTypeId();
        Set<Id> accountIds = new Set<Id>();
        for(Prospect_Research__c pr: newList){
            if(pr.Account__c != null){
                accountIds.add(pr.Account__c);
            }//   Zendesk: #56321
            if(otherCharitableId.equalsIgnoreCase(String.ValueOf(pr.RecordTypeId))) {
                populateInfoForCharitableGiving(pr);
            }//   Zendesk: END #56321
        }
        if(accountIds.size() > 0) {
            hasPermission(accountIds, newList);
        }
    }
    
     /*
    *Method beforeUpdate
    *@description : calls on beforeInsert
    Zendesk: #56321
    */ 
    private static void beforeUpdate(Map<Id,Prospect_Research__c> newMap, Map<Id,Prospect_Research__c> OldMap) {
        //Get record Id of Other Charitable Giving
        String otherCharitableId = Schema.SObjectType.Prospect_Research__c.getRecordTypeInfosByName().get('Other Charitable Giving').getRecordTypeId();
        for(id prId :newMap.KeySet()) {
            //RecordType is Other Charitable Giving then update Gift Year and Gift Date
            if(otherCharitableId.equalsIgnoreCase(String.ValueOf(newMap.get(prId).RecordTypeId))) {
                if(newMap.get(prId).Gift_Year__c != null && (newMap.get(prId).Gift_Year__c.length() != 4
                    || !newMap.get(prId).Gift_Year__c.IsNumeric() )) {
                    newMap.get(prId).Gift_Year__c.addError('Gift Year must be in YYYY format');
                    
                    return;
                }
                if(newMap.get(prId).Gift_Year__c != null && OldMap.get(prId).Gift_Year__c != newMap.get(prId).Gift_Year__c 
                   && newMap.get(prId).Gift_Date__c == OldMap.get(prId).Gift_Date__c) {
                    newMap.get(prId).Gift_Date__c = date.newInstance(integer.ValueOf(newMap.get(prId).Gift_Year__c), 1, 1);
                }else if(newMap.get(prId).Gift_Date__c != null && OldMap.get(prId).Gift_Date__c != newMap.get(prId).Gift_Date__c 
                         && OldMap.get(prId).Gift_Year__c.equalsIgnoreCase(newMap.get(prId).Gift_Year__c)) {
                     newMap.get(prId).Gift_Year__c = String.ValueOf((newMap.get(prId).Gift_Date__c.year()));
                }else {
                    populateInfoForCharitableGiving(newMap.get(prId));
                }
            }
        }
    }
    //Zendesk:END #56321
    /*    
    *
    *Method populateInfoForCharitableGiving
    *@param : Prospect_Research__c
    *Check either Gift Date or Gift Year is populated then update respective field
    */
    //   Zendesk: #56321
    public static void populateInfoForCharitableGiving(Prospect_Research__c pr) {
        
        //Validate Gift year
        if(pr.Gift_Year__c != null && (pr.Gift_Year__c.length() != 4 || !pr.Gift_Year__c.IsNumeric())) {
          pr.Gift_Year__c.addError('Gift Year must be in YYYY format');
          return;
        }
        //populte the Gift Date and Gift Year
        if(pr.Gift_Date__c != null && pr.Gift_Year__c == null) {
            pr.Gift_Year__c = String.ValueOf(pr.Gift_Date__c.year());
        } else if(pr.Gift_Date__c == null && pr.Gift_Year__c != null) {
            pr.Gift_Date__c = date.newInstance(integer.ValueOf(pr.Gift_Year__c), 1, 1);
        }
    }
    //   Zendesk:END #56321
     /*    
    *
    *Method sharePResearchWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void sharePResearchWithAccountTeam(Map<Id, Set<Id>> prosResearchAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (prosResearchAccountMap.size() > 0) {
            Map<Id, Set<Id>> newPResearchAccountMap = new Map<Id, Set<Id>>();

            for (Id key : prosResearchAccountMap.KeySet()) { 
                if (newPResearchAccountMap.size() < accountAsyncBatchMax) {
                    newPResearchAccountMap.put(key, prosResearchAccountMap.get(key));
                    prosResearchAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'Prospect_Research__c',
                                   Params__c = JSON.serialize(newPResearchAccountMap)));
        }
        
        try {
            insert newAsyncRequests;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('ProsResearchTriggerHandler','', 'sharePResearchWithAccountTeam :: ' + e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
     /*    
    *
    *Method setProspectShareRecords
    *@param : newMap
    *It creates the share records based on the their accountAffiliation.
    */
    //@future
    public static void setProspectShareRecords(Set<Id> prospectIds, Boolean isUpdate, List<String>oldAffiliations){
        Map<Id,String> mapProspectIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean> ();
        // Collect the confidentialIdToAffiliation
        for(Prospect_Research__c pr: [SELECT Id, Account__c, Account__r.Affiliation__c, Account__r.Restricted_Account__c, Contact__c, Contact__r.Account.Affiliation__c, Contact__r.Account.Restricted_Account__c  FROM Prospect_Research__c WHERE Id =: prospectIds]){
            //Account Affiliate
            if(pr.Account__c != null && pr.Account__r.Affiliation__c != null){
                mapProspectIdToAffiliate.put(pr.Id, pr.Account__r.Affiliation__c);
                //Restriction
                mapProspectIdToRestricted.put(pr.Id, pr.Account__r.Restricted_Account__c);
            }
            //Contact Affiliate
            if(pr.Contact__c != null && pr.Contact__r.Account.Affiliation__c != null){
                mapProspectIdToAffiliate.put(pr.Id, pr.Contact__r.Account.Affiliation__c);
                //Restriction
                mapProspectIdToRestricted.put(pr.Id, pr.Contact__r.Account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        if(OldAffiliations != null){
            for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapProspectIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL OR Name=: OldAffiliations]){
                mapGroupNameToId.put(grp.Name,grp.Id);
            }
        }
        else if(OldAffiliations == null){
            for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapProspectIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
                mapGroupNameToId.put(grp.Name,grp.Id);
            }
        }
        
        //Delete the Existing Share records
        if(isUpdate){
            deleteProspectSharingRecords(prospectIds, oldAffiliations, mapGroupNameToId, mapProspectIdToRestricted);
        }
        
        // Insert the new Affiliations records.
        InsertProspectShareRecords(mapProspectIdToAffiliate, mapGroupNameToId, mapProspectIdToRestricted);
    }
    
    
    /*
    *
    *Method: InsertProspectShareRecords
    *@param : Map<Id,String> (Prospect Id to AffiliateName)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Prospect Research Object. 
    */ 
    public static void InsertProspectShareRecords(Map<Id,String> mapProspectIdToAffiliate, Map<String,Id> mapGroupNameToId, map<Id,Boolean> mapProspectIdToRestricted){
        
        List<Prospect_Research__share> prospectSharesToBeInsert = new List<Prospect_Research__share>();
        
        //Create the Prospect Share Records to all of Objects
        for(Id objId: mapProspectIdToAffiliate.keyset()){
            
            if(mapProspectIdToRestricted.get(ObjId) == false && mapProspectIdToAffiliate.get(ObjId) != null && mapGroupNameToId.get(mapProspectIdToAffiliate.get(ObjId)) != null){
                Prospect_Research__share prosShare = new Prospect_Research__share();
                prosShare.ParentId = ObjId;
                prosShare.AccessLevel = 'Edit';
                prosShare.UserOrGroupId = mapGroupNameToId.get(mapProspectIdToAffiliate.get(ObjId));
                prospectSharesToBeInsert.add(prosShare);
            }
            
            //Apex Share for ALL ACLU group
            if(mapProspectIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(ALLACLU) != null ){
                Prospect_Research__share prosShare = new Prospect_Research__share();
                prosShare.ParentId = ObjId;
                prosShare.AccessLevel = 'Read';
                prosShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                prospectSharesToBeInsert.add(prosShare);
            }
            
            //Apex Share for National group
            if(mapProspectIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(NATIONAL) != null){
                Prospect_Research__share prosShare = new Prospect_Research__share();
                prosShare.ParentId = ObjId;
                prosShare.AccessLevel = 'Edit';
                prosShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                prospectSharesToBeInsert.add(prosShare);
            }
        }
        // Insert the ActionPlan share Objects
        if(!prospectSharesToBeInsert.IsEmpty()) {
            try{
            insert prospectSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ProsResearchTriggerHandler','','InsertProspectShareRecords :: ' + e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    /*
    *
    *Method: deleteProspectSharingRecords
    *@param : setId (Prospect Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to Prospect Research Object. 
    *
    */ 
    public static void deleteProspectSharingRecords(Set<Id> prospectIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, map<Id,Boolean> mapProspectIdToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> prospectPrivateIds = new Set<Id>();
        List<Prospect_Research__share> prospectSharesToBeDelete = new List<Prospect_Research__share> ();
        
        //Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }
        
        // Collect Confidential Share records having edit access 
        for(Prospect_Research__share prosShare: [SELECT Id, AccessLevel, ParentId FROM Prospect_Research__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:prospectIds]){
            prospectSharesToBeDelete.add(prosShare);
        }
        
        // Delete ALL ACLU if the Prospect Research is Private.
        for(Id psId: prospectIds){
            if(mapProspectIdToRestricted.get(psId) == true){
                prospectPrivateIds.add(psId);
            }
        }
        if(!prospectPrivateIds.IsEmpty()){
            for(Prospect_Research__share prosShare: [SELECT Id, AccessLevel, ParentId FROM Prospect_Research__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:prospectPrivateIds]){
                prospectSharesToBeDelete.add(prosShare);
            }
        }

        // Delete the ActionPlan Share records.
        if(!prospectSharesToBeDelete.isEmpty()){
            try{
                delete prospectSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('ProsResearchTriggerHandler','','deleteProspectSharingRecords ::' + e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }  

    /*
    *
    *Method hasPermission
    *@param : newList
    *It checks the createPermissions.
    *
    */
    public static void hasPermission(Set<Id> accountIds, List<Prospect_Research__c> newList){
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();

        for(Account acc: [SELECT id,Affiliation__C FROM Account WHERE Id =: accountIds]){
            mapAccountIdToAffiliation.put(acc.Id,acc.Affiliation__c);
        }
        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(mapAccountIdToAffiliation.Values());
        for(Prospect_Research__c obj: newList){    
            if(obj.Account__c != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.Account__c)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.Account__c))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
        }
    }  
}