/*
*
*Name  :  CaseTriggerHandler
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  April 23, 2018
*Purpose : Handler Class for Case Trigger with logic check for custom permission
*
*/

public with sharing class CaseTriggerHandler {
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */ 
    public static void mainEntry(List<Case> newList, List<Case> oldList, Map<Id, Case> newMap, Map<Id, Case> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('Case_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            //It is called on before
            if(isBefore){
                //Insert
                if(isInsert){
                    beforeInsert(newList);
                }
            }
        }
    }
    
    private static void beforeInsert(List<Case> newList){
        Set<Id> accountIds = new Set<Id>();
        for(Case cs: newList){
            if(cs.AccountId != null){
                accountIds.add(cs.AccountId);
            }
        }
        if(accountIds.size() > 0) {
            hasPermission(accountIds, newList);
        }
    }
    
    /*
    *
    *Method hasPermission
    *@param : newList
    *It checks the createPermissions.
    *
    */
    public static void hasPermission(Set<Id> accountIds, List<Case> newList){
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();

        for(Account acc: [SELECT id,Affiliation__C FROM Account WHERE Id =: accountIds]){
            mapAccountIdToAffiliation.put(acc.Id,acc.Affiliation__c);
        }
        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(mapAccountIdToAffiliation.Values());
        for(Case obj: newList){    
            if(obj.AccountId != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.AccountId)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.AccountId))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
        }
    }
}