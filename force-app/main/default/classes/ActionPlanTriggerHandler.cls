/*
*
*Name  :  ActionPlanTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose :  Handler Class for ActionPlan Trigger
            Logic includes
            - Apex Sharing
            - Limits Create access based on custom logic
            (T-555635)
*
*/

public with sharing class ActionPlanTriggerHandler {

    Public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    public static Map<String, Boolean> userAccessMap;
    
    static{
        userAccessMap = new Map<String, Boolean>();
    }
/*
*
*Method mainEntry
*@description : defining all trigger events
*
*/ 
    public static void mainEntry(List<rC_Bios__Action_Plan__c > newList, List<rC_Bios__Action_Plan__c> oldList, Map<Id, rC_Bios__Action_Plan__c> newMap, Map<Id, rC_Bios__Action_Plan__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        
        //if trigger is active
        if(TriggerState.isActive('ActionPlan_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            // It is called on before insert
            if(isBefore){
                if(isInsert){
                    beforeInsert(newList);
                }         
            }
            
            
            // It is called on after insert
            if(isAfter){
                if(isInsert){
                    afterInsert(newList);
                    
                }
                if(isUpdate){
                    onAfterUpdate(newMap, oldMap);
                }
            }
            
            // It is called on before Delete
            if(isBefore){
                if(isDelete){
                    beforeDelete(oldList);
                }     
            }
        }
        
    }
    
    /*
    *Method beforeDelete
    *@description : calls on afterInsert
    */ 
    
    private static void beforeDelete(List<rC_Bios__Action_Plan__c> newList){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        List<rC_Bios__Action_Plan__c> actionPlans = new List<rC_Bios__Action_Plan__c>();
        
        for(rC_Bios__Action_Plan__c obj: newList){
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('001')){
                accountIds.add(obj.rC_Bios__WhatId__c);
                actionPlans.add(obj);
            }
            
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('003')){
                contactIds.add(obj.rC_Bios__WhatId__c);
                actionPlans.add(obj);
            }
            
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('006')){
                opportunityIds.add(obj.rC_Bios__WhatId__c);
                actionPlans.add(obj);
            }
            
            
            
        }
        
        if(!actionPlans.IsEmpty()){
            hasPermission(actionPlans, accountIds, contactIds, opportunityIds);
        }
    }
    
     /*
    *Method beforeInsert
    *@description : calls on afterInsert
    */ 
    
    private static void beforeInsert(List<rC_Bios__Action_Plan__c> newList){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        List<rC_Bios__Action_Plan__c> actionPlans = new List<rC_Bios__Action_Plan__c>();
        
        for(rC_Bios__Action_Plan__c obj: newList){
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('001')){
                accountIds.add(obj.rC_Bios__WhatId__c);
                actionPlans.add(obj);
            }
            
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('003')){
                contactIds.add(obj.rC_Bios__WhatId__c);
                actionPlans.add(obj);
            }
            
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('006')){
                opportunityIds.add(obj.rC_Bios__WhatId__c);
                actionPlans.add(obj);
            }
            
            
        }
        
        if(!actionPlans.IsEmpty()){
            hasPermission(actionPlans, accountIds, contactIds, opportunityIds);
        }
    }
    
     /*
    *Method afterInsert
    *@description : calls on afterInsert
    */ 
    
    private static void afterInsert(List<rC_Bios__Action_Plan__c> newList){
        Set<Id> actionPlanIds = new Set<Id>();
        
        for(rC_Bios__Action_Plan__c ap: newList){
            actionPlanIds.add(ap.Id);
        }
        
        if(!actionPlanIds.isEmpty() && Utilities.CanUseFutureContext())
            setActionPlanShareRecords(actionPlanIds);
    }

    
          /*    
*
*Method hasPermission
*@param : newList
*It checks the createPermissions.
*/
    public static void hasPermission(List<rC_Bios__Action_Plan__c> newList, Set<Id> accountIds, Set<Id> contactIds, Set<Id> opportunityIds){
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, ID> mapContactIdToAccountId = new Map<ID, ID>();
        Map<ID, ID> mapOpportunityIdToAccountId = new Map<ID, ID>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();
        
        
        for(Opportunity opp: [SELECT accountId FROM Opportunity WHERE Id=: opportunityIds ]){
            accountIds.add(opp.accountId);
            mapOpportunityIdToAccountId.put(opp.Id,opp.accountId);
        }
        
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
        
        for(rC_Bios__Action_Plan__c obj: newList){
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('001')){
                if(userAccessMap.containsKey(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId()) && !userAccessMap.get(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId())) {
                    if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__WhatId__c)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__WhatId__c))){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
            }
            
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('003')){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__WhatId__c))) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__WhatId__c)))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
            
            if(obj.rC_Bios__WhatId__c != null && string.ValueOf(obj.rC_Bios__WhatId__c).startsWith('006')){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapOpportunityIdToAccountId.get(obj.rC_Bios__WhatId__c))) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapOpportunityIdToAccountId.get(obj.rC_Bios__WhatId__c)))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
        }
    }


    
     /*    
*
*Method setActionPlanShareRecords
*@param : newMap
*It creates the share records based on the their accountAffiliation.
*
*/
    //@future
    public static void setActionPlanShareRecords(Set<Id> actionPlanIds){
        // Method Variables
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        map<Id,Account> mapAccount = new map<Id,Account>();
        map<Id,Contact> mapContact = new map<Id,Contact>();
        map<Id,Opportunity> mapOpportunity = new map<Id,Opportunity>(); 
        Map<Id,Id> mapActionPlanIdToAccountId = new Map<Id,Id>();
        Map<Id,Id> mapActionPlanIdTocontactId = new Map<Id,Id>();
        Map<Id,Id> mapActionPlanIdToopportunityId = new Map<Id,Id>();
        map<Id, rC_Bios__Action_Plan__c> mapActionPlan = new map<Id, rC_Bios__Action_Plan__c>();
        //List<rC_Bios__Action_Plan__share> ActionPlanSharesToBeInsert = new List<rC_Bios__Action_Plan__share>();
        Map<Id,String> mapActionPlanIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        
        
        // Collect the ActionPlanIdToAffiliation
        for(rC_Bios__Action_Plan__c mapAcp: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Account__c, rC_Bios__Contact__c, rC_Bios__Opportunity__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Account__r.Affiliation__c, rC_Bios__Contact__r.account.Affiliation__c FROM rC_Bios__Action_Plan__c WHERE Id =: actionPlanIds]){
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('001')){
                mapActionPlanIdToAccountId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
            }
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('003')){
                mapActionPlanIdTocontactId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
                
            }
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('006')){
                mapActionPlanIdToopportunityId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
            }
                
            
        }
        if(!mapActionPlanIdToAccountId.Keyset().IsEmpty()){
            for(Account acc: [SELECT id, Affiliation__c, Restricted_Account__c FROM Account where id=: mapActionPlanIdToAccountId.Values()]){
                if(acc.Affiliation__c != null){
                    mapAccount.put(acc.Id,acc);
                }
            }
        }
        
        if(!mapActionPlanIdTocontactId.Keyset().IsEmpty()){
            for(Contact con: [SELECT id, account.Affiliation__c, account.Restricted_Account__c FROM Contact where id=: mapActionPlanIdTocontactId.Values()]){
                if(con.account.Affiliation__c != null){
                    mapContact.put(con.Id,con);
                }
            }
        }
        
        if(!mapActionPlanIdToopportunityId.Keyset().IsEmpty()){
            for(Opportunity opp: [SELECT id, account.Affiliation__c, account.Restricted_Account__c FROM Opportunity where id=: mapActionPlanIdToopportunityId.Values()]){
                if(opp.account.Affiliation__c != null){
                    mapOpportunity.put(opp.Id,opp);
                }
            }
        }
        
        for(Id objId: mapActionPlanIdToAccountId.KeySet()){
            if(mapActionPlan.get(objId) != null && mapAccount.get(mapActionPlan.get(objId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(objId,mapAccount.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).Affiliation__c);
                mapActionPlanIdToRestricted.put(objId,mapAccount.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).Restricted_Account__c);
            }
        }
        
        for(Id objId: mapActionPlanIdTocontactId.keySet()){
            if(mapActionPlan.get(objId) != null && mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(objId,mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(objId,mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }
        
        for(Id acPId: mapActionPlanIdToopportunityId.KeySet()){
            if(mapActionPlan.get(acpId) != null && mapOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(acPId,mapOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(acPId,mapOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }
        
        
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertActionPlanSharingRecords (mapActionPlanIdToAffiliate, mapGroupNameToId, mapActionPlanIdToRestricted);
    }
    
    /*    
*
*Method onAfterUpdate
*@param : newMap
*@param : OldMap
*It checks whether the Account/Contact Lookup changed.
*
*/

    public static void onAfterUpdate(Map<Id,rC_Bios__Action_Plan__c> newMap, Map<Id,rC_Bios__Action_Plan__c> OldMap){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> actionPlanIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> OpporutunityIds = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        
        for(rC_Bios__Action_Plan__c ap: newMap.Values()){
            if(OldMap.get(ap.Id).rC_Bios__WhatId__c != ap.rC_Bios__WhatId__c){
                if(OldMap.get(ap.Id).rC_Bios__WhatId__c != null && String.ValueOf(OldMap.get(ap.Id).rC_Bios__WhatId__c).StartsWith('001'))
                    accountIds.add(OldMap.get(ap.Id).rC_Bios__WhatId__c);
                if(OldMap.get(ap.Id).rC_Bios__WhatId__c != null && String.ValueOf(OldMap.get(ap.Id).rC_Bios__WhatId__c).StartsWith('003'))
                    contactIds.add(OldMap.get(ap.Id).rC_Bios__WhatId__c);
                if(OldMap.get(ap.Id).rC_Bios__WhatId__c != null && String.ValueOf(OldMap.get(ap.Id).rC_Bios__WhatId__c).StartsWith('006'))
                    OpporutunityIds.add(OldMap.get(ap.Id).rC_Bios__WhatId__c);
                
                actionPlanIds.add(ap.Id);
            }
            
            
        }
        
        for(Opportunity opp: [SELECT Id,account.Affiliation__c,accountId FROM Opportunity WHERE Id =: OpporutunityIds]){
            if(opp.accountId != null )
                accountIds.add(opp.accountId);
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
            resetActionPlanShareRecords(actionPlanIds,OldAffiliations);
        }
    }
    
    /*    
*
*Method resetActionPlanShareRecords
*@param : Set<Id> (actionPlanIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    
    //@future
    public static void resetActionPlanShareRecords(Set<Id> actionPlanIds, List<String> OldAffiliations){
        map<Id,Account> mapAccount = new map<Id,Account>();
        map<Id,Contact> mapContact = new map<Id,Contact>();
        map<Id,Opportunity> mapOpportunity = new map<Id,Opportunity>(); 
        Map<Id,Id> mapActionPlanIdToAccountId = new Map<Id,Id>();
        Map<Id,Id> mapActionPlanIdTocontactId = new Map<Id,Id>();
        Map<Id,Id> mapActionPlanIdToopportunityId = new Map<Id,Id>();
        map<Id, rC_Bios__Action_Plan__c> mapActionPlan = new map<Id, rC_Bios__Action_Plan__c>();
        Map<Id,Id> mapAccountIdToActionPlanId = new Map<Id,Id>();
        Map<Id,Id> mapcontactIdToActionPlanId = new Map<Id,Id>();
        Map<Id,Id> mapopportunityIdToActionPlanId = new Map<Id,Id>();
        Map<Id,String> mapActionPlanIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        
         // Collect the ActionPlanIdToAffiliation
        for(rC_Bios__Action_Plan__c mapAcp: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Account__c, rC_Bios__Contact__c, rC_Bios__Opportunity__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Account__r.Affiliation__c, rC_Bios__Contact__r.account.Affiliation__c FROM rC_Bios__Action_Plan__c WHERE Id =: actionPlanIds]){
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('001')){
                mapActionPlanIdToAccountId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
            }
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('003')){
                mapActionPlanIdTocontactId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
                
            }
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('006')){
                mapActionPlanIdToopportunityId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
            }
                
            
        }
        if(!mapActionPlanIdToAccountId.Keyset().IsEmpty()){
            for(Account acc: [SELECT id, Affiliation__c, Restricted_Account__c FROM Account where id=: mapActionPlanIdToAccountId.Values()]){
                if(acc.Affiliation__c != null){
                    mapAccount.put(acc.Id,acc);
                }
            }
        }
        
        if(!mapActionPlanIdTocontactId.Keyset().IsEmpty()){
            for(Contact con: [SELECT id, account.Affiliation__c, account.Restricted_Account__c FROM Contact where id=: mapActionPlanIdTocontactId.Values()]){
                if(con.account.Affiliation__c != null){
                    mapContact.put(con.Id,con);
                }
            }
        }
        
        if(!mapActionPlanIdToopportunityId.Keyset().IsEmpty()){
            for(Opportunity opp: [SELECT id, account.Affiliation__c, account.Restricted_Account__c FROM Opportunity where id=: mapActionPlanIdToopportunityId.Values()]){
                if(opp.account.Affiliation__c != null){
                    mapOpportunity.put(opp.Id,opp);
                }
            }
        }
        
        for(Id objId: mapActionPlanIdToAccountId.KeySet()){
            if(mapActionPlan.get(objId) != null && mapAccount.get(mapActionPlan.get(objId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(objId,mapAccount.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).Affiliation__c);
                mapActionPlanIdToRestricted.put(objId,mapAccount.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).Restricted_Account__c);
            }
        }
        
        for(Id objId: mapActionPlanIdTocontactId.keySet()){
            if(mapActionPlan.get(objId) != null && mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(objId,mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(objId,mapContact.get(mapActionPlan.get(objId).rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }
        
        for(Id acPId: mapActionPlanIdToopportunityId.KeySet()){
            if(mapActionPlan.get(acpId) != null && mapOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(acPId,mapOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(acPId,mapOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
           // System.assert(false,mapActionPlanIdToAffiliate.Values());
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deleteActionPlanSharingRecords (mapActionPlanIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapActionPlanIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertActionPlanSharingRecords (mapActionPlanIdToAffiliate, mapGroupNameToId, mapActionPlanIdToRestricted);
        
    }
    
}