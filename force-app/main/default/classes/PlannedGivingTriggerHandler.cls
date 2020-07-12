/*
*
*Name  :  PlannedGivingTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose :  Handler Class for PlannedGiving Trigger
            Logic includes
            - Apex Sharing
            - Rollup updates on delete
            - Limits Create access based on custom logic
            - Account Teams sharing
            (T-555635)
*
*/

public with sharing class PlannedGivingTriggerHandler {
    
    public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    private static final String STAGE_VALUE = 'Inactive';
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
    public static void mainEntry(List<rC_Giving__Planned_Giving__c > newList, List<rC_Giving__Planned_Giving__c> oldList, Map<Id, rC_Giving__Planned_Giving__c> newMap, Map<Id, rC_Giving__Planned_Giving__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        
        //if trigger is active
        if(TriggerState.isActive('PlannedGiving_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            // It is called on before insert and update
            if(isBefore){
                if(isInsert){
                    onBeforeInsert(newList);
                }            
                
                if(isDelete){
                    onBeforeDelete(oldList);
                }  
            }
            
            
            // It is called on after insert and update
            if(isAfter){
                if(isInsert){
                    onAfterInsert(newList);
                    
                }
                
                if(isUpdate){
                    onAfterUpdate(newMap, oldMap);
                }
                
                if(isDelete) {
                    onAfterDelete(oldList);
                }
                
                if(isUndelete) {
                    onAfterUndelete(newList);
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
   public static void onBeforeInsert(List<rC_Giving__Planned_Giving__c> newList) {
      
      Set<Id> accountIds = new Set<Id>();
      Set<Id> contactIds = new Set<Id>();
    
      for(rC_Giving__Planned_Giving__c obj: newList){
        if(obj.rC_Giving__Account__c != null){
            accountIds.add(obj.rC_Giving__Account__c);
          }         
      }
      
      hasPermission(accountIds,newList);
    }
    
    
/*    
*
*Method onBeforeDelete
*@param : oldList
*
*/
   public static void onBeforeDelete(List<rC_Giving__Planned_Giving__c> oldList) {
      
      Set<Id> accountIds = new Set<Id>();
      Set<Id> contactIds = new Set<Id>();
    
      for(rC_Giving__Planned_Giving__c obj: oldList){
        if(obj.rC_Giving__Account__c != null){
            accountIds.add(obj.rC_Giving__Account__c);
          }        
      }
      
      hasPermission(accountIds,oldList);
    }
    
    public static void onAfterDelete(List<rC_Giving__Planned_Giving__c> oldList) {
        list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', 'rC_Giving__Estimated_Giving_Amount__c ','PG_Level__c')};        
        RSFUtility.rollUpTrigger(fieldDefinitions, oldList, 'rC_Giving__Planned_Giving__c', 'rC_Giving__Account__c', 'Account', ' AND rC_Giving__Stage__c !=\''+ STAGE_VALUE+'\' ');          
    }
    
    public static void onAfterUndelete(List<rC_Giving__Planned_Giving__c> newList) {
        list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', 'rC_Giving__Estimated_Giving_Amount__c ','PG_Level__c')};        
      RSFUtility.rollUpTrigger(fieldDefinitions, newList, 'rC_Giving__Planned_Giving__c', 'rC_Giving__Account__c', 'Account', ' AND rC_Giving__Stage__c !=\''+ STAGE_VALUE+'\' ');             
    }      
    
    
/*    
*
*Method onAfterInsert
*@param : listPlanned
*
*/
  
    public static void onAfterInsert(list<rC_Giving__Planned_Giving__c> listPlanned){  
        Map<Id, Set<Id>> pGivingAccountMap = new Map<Id, Set<Id>>();
        list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', 'rC_Giving__Estimated_Giving_Amount__c ','PG_Level__c')};
        Set<Id> plannedGivingIds = new Set<Id>();
        List<rC_Giving__Planned_Giving__c> listOfPlannedGivings = new List<rC_Giving__Planned_Giving__c>();
        for(rC_Giving__Planned_Giving__c pg: listPlanned){
                plannedGivingIds.add(pg.Id);
                if(pg.rC_Giving__Account__c != null && pg.rC_Giving__Estimated_Giving_Amount__c  != null) {
                    listOfPlannedGivings.add(pg);
                }
                
                if(pg.rC_Giving__Account__c != null) {
                    if(!pGivingAccountMap.containsKey(pg.rC_Giving__Account__c)) {
                        pGivingAccountMap.put(pg.rC_Giving__Account__c, new Set<Id>());
                    }
                    pGivingAccountMap.get(pg.rC_Giving__Account__c).add(pg.Id);
                }
        }
        if(!plannedGivingIds.isEmpty() && Utilities.CanUseFutureContext()){
            setPlannedGivingShareRecords(plannedGivingIds);
        }
        
        RSFUtility.rollUpTrigger(fieldDefinitions, listOfPlannedGivings, 'rC_Giving__Planned_Giving__c', 'rC_Giving__Account__c', 'Account', ' AND rC_Giving__Stage__c !=\''+ STAGE_VALUE+'\'');    
    
        if(!pGivingAccountMap.isEmpty()) {
            PlannedGivingTriggerHandler.sharePGivingWithAccountTeam(pGivingAccountMap);
        }
  }      
    
    /*    
*
*Method hasPermission
*@param : newList
*It checks the createPermissions.
*
*/
    public static void hasPermission(Set<Id> accountIds,List<rC_Giving__Planned_Giving__c> plannedList){
       
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();
        
        
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
        
        for(rC_Giving__Planned_Giving__c obj: plannedList){
            if(userAccessMap.containsKey(obj.rC_Giving__Account__c+'-'+UserInfo.getUserId()) && !userAccessMap.get(obj.rC_Giving__Account__c+'-'+UserInfo.getUserId())) {
                if(obj.rC_Giving__Account__c != null){
                    if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Giving__Account__c)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Giving__Account__c))){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
            }
        }
    }
    
     /*    
    *
    *Method sharePGivingWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void sharePGivingWithAccountTeam(Map<Id, Set<Id>> pGivingAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (pGivingAccountMap.size() > 0) {
            Map<Id, Set<Id>> newpGivingAccountMap = new Map<Id, Set<Id>>();

            for (Id key : pGivingAccountMap.KeySet()) { 
                if (newpGivingAccountMap.size() < accountAsyncBatchMax) {
                    newpGivingAccountMap.put(key, pGivingAccountMap.get(key));
                    pGivingAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'rC_Giving__Planned_Giving__c',
                                   Params__c = JSON.serialize(newpGivingAccountMap)));
        }
        
        try {
            insert newAsyncRequests;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('PlannedGivingTriggerHandler','sharePGivingWithAccountTeam', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
/*    
*
*Method setPlannedGivingShareRecords
*@param : newMap
*It creates the share records based on the their accountAffiliation.
*
*/
    //@future
    public static void setPlannedGivingShareRecords(Set<Id> plannedGivingIds){
        // Method Variables
        List<rC_Giving__Planned_Giving__share> PlannedGivingSharesToBeInsert = new List<rC_Giving__Planned_Giving__share>();
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,Boolean> mapPlannedGivingToRestricted = new Map<Id,Boolean>();   
        Map<Id,rC_Giving__Planned_Giving__c> mapPlannedGivingIdToPlannedGiving = new Map<Id,rC_Giving__Planned_Giving__c>();
        
        
        // Collect the PlannedGivingIdToPlannedGiving and collect the affiliations
        for(rC_Giving__Planned_Giving__c mapPg: [SELECT Id,rC_Giving__Account__r.Restricted_Account__c, rC_Giving__Fund__r.Restricted_Account__c, rC_Giving__Account__r.Affiliation__c, rC_Giving__Fund__r.Affiliation__c FROM rC_Giving__Planned_Giving__c WHERE Id =: plannedGivingIds]){
            mapPlannedGivingIdToPlannedGiving.put(mapPg.Id,mapPg);
            if(mapPg.rC_Giving__Account__r.Affiliation__c != null)
                groupNames.add(mapPg.rC_Giving__Account__r.Affiliation__c);
            if(mapPg.rC_Giving__Fund__r.Affiliation__c != null)
                groupNames.add(mapPg.rC_Giving__Fund__r.Affiliation__c);
            if(mapPg.rC_Giving__Account__r.Restricted_Account__c == true || mapPg.rC_Giving__Fund__r.Restricted_Account__c == true){
                mapPlannedGivingToRestricted.put(mapPg.Id,true);
            }
            else{
                mapPlannedGivingToRestricted.put(mapPg.Id,false);
            }
        }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPlannedGivingSharingRecords (mapPlannedGivingIdToPlannedGiving, mapGroupNameToId, mapPlannedGivingToRestricted);
         
    }
    
    /*    
*
*Method onAfterUpdate
*@param : newMap
*@param : OldMap
*It checks whether the Account/Contact Lookup changed.
*
*/

    public static void onAfterUpdate(Map<Id,rC_Giving__Planned_Giving__c> newMap, Map<Id,rC_Giving__Planned_Giving__c> OldMap){
          Set<Id> accountIds = new Set<Id>();
        Set<Id> plannedGivingIds = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        Set<Id> setOfParentIds = new Set<Id>();
        List<rC_Giving__Planned_Giving__c> listOfPlannedGivingsToProcess = new List<rC_Giving__Planned_Giving__c>();
        
        for(rC_Giving__Planned_Giving__c pg: newMap.Values()){
            if(OldMap.get(pg.Id).rC_Giving__Account__c != pg.rC_Giving__Account__c){
                accountIds.add(OldMap.get(pg.Id).rC_Giving__Account__c);
                plannedGivingIds.add(pg.Id);
            }
            
            if(OldMap.get(pg.Id).rC_Giving__Fund__c != pg.rC_Giving__Fund__c){
                accountIds.add(OldMap.get(pg.Id).rC_Giving__Fund__c);
                plannedGivingIds.add(pg.Id);
            }
            if(OldMap.get(pg.Id).rC_Giving__Account__c != pg.rC_Giving__Account__c || OldMap.get(pg.Id).rC_Giving__Estimated_Giving_Amount__c  != pg.rC_Giving__Estimated_Giving_Amount__c ) {
                listOfPlannedGivingsToProcess.add(pg);
                setOfParentIds.add(pg.rC_Giving__Account__c);
            }
            
        }
        
        for(Account acc: [SELECT id,Affiliation__c FROM Account WHERE Id =: accountIds]){
            OldAffiliations.add(acc.Affiliation__c);
        }
        if(!OldAffiliations.IsEmpty()){
            resetPlannedGivingShareRecords(plannedGivingIds,OldAffiliations);
        }
        list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', 'rC_Giving__Estimated_Giving_Amount__c ','PG_Level__c')};
        RSFUtility.processRollUp(fieldDefinitions, listOfPlannedGivingsToProcess, 'rC_Giving__Planned_Giving__c', 'rC_Giving__Account__c', 'Account', ' AND rC_Giving__Stage__c !=\''+ STAGE_VALUE+'\' ', setOfParentIds);
    }
    
    /*    
*
*Method resetPlannedGivingShareRecords
*@param : Set<Id> (relationshipIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    
    //@future
    public static void resetPlannedGivingShareRecords(Set<Id> plannedGivingIds, List<String> OldAffiliations){
        Map<Id,rC_Giving__Planned_Giving__c> mapPlannedGivingIdToPlannedGiving = new Map<Id,rC_Giving__Planned_Giving__c>();
        Map<Id,Boolean> mapPlannedGivingToRestricted = new Map<Id,Boolean>();   
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        
        // Collecting All PlannedGiving account Share records having edit access 
        for(rC_Giving__Planned_Giving__c pG: [SELECT Id, rC_Giving__Account__r.Restricted_Account__c, rC_Giving__Fund__r.Restricted_Account__c, rC_Giving__Account__r.Affiliation__c,   rC_Giving__Fund__r.Affiliation__c FROM rC_Giving__Planned_Giving__c WHERE Id =: plannedGivingIds]){
            mapPlannedGivingIdToPlannedGiving.put(pG.Id,pG);
            if(pG.rC_Giving__Account__r.Affiliation__c != null){
                groupNames.add(pG.rC_Giving__Account__r.Affiliation__c);
            }
            if(pG.rC_Giving__Fund__r.Affiliation__c != null){
                groupNames.add(pG.rC_Giving__Fund__r.Affiliation__c);
            }
            
            if(pG.rC_Giving__Account__r.Restricted_Account__c == true || pG.rC_Giving__Fund__r.Restricted_Account__c == true){
                mapPlannedGivingToRestricted.put(pG.Id,true);
            }
            else{
                mapPlannedGivingToRestricted.put(pG.Id,false);
            }
        }
        
         //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name =: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deletePlannedGivingRecords (mapPlannedGivingIdToPlannedGiving.KeySet(), OldAffiliations, mapGroupNameToId, mapPlannedGivingToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPlannedGivingSharingRecords (mapPlannedGivingIdToPlannedGiving, mapGroupNameToId, mapPlannedGivingToRestricted);
    }
    
}