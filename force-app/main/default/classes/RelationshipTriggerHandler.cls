/*
*
*Name  :  RelationshipTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose :  Handler Class for Relationship Trigger
            Logic includes
            - Apex Sharing
            - Limits Create access based on custom logic
            (T-555635)
*
*/
public class RelationshipTriggerHandler{

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
    public static void mainEntry(List<rC_Bios__Relationship__c > newList, List<rC_Bios__Relationship__c> oldList, Map<Id, rC_Bios__Relationship__c> newMap, Map<Id, rC_Bios__Relationship__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        
        //if trigger is active
        if(TriggerState.isActive('Relationship_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            // It is called on before insert
            if(isBefore){
                if(isInsert) {
                    hasPermission(newList);
                }   
                    
                if(isDelete) {
                    hasPermission(oldList);
                }      
            }
            
            // It is called on after insert
            if(isAfter) {
                if(isInsert) {
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
    *Method onAfterInsert
    *@param : newList
    *
    */
    public static void onAfterInsert(List<rC_Bios__Relationship__c> newList) {
        Set<Id> relationshipIds = new Set<Id>();
        Map<Id, Set<Id>> relAccountMap = new Map<Id, Set<Id>>();
        
        for(rC_Bios__Relationship__c rl : newList){
            relationshipIds.add(rl.Id);
            if(rl.rC_Bios__Account_1__c != null) {
            	if(!relAccountMap.containsKey(rl.rC_Bios__Account_1__c)) {
	                relAccountMap.put(rl.rC_Bios__Account_1__c, new Set<Id>());
	            }
	            relAccountMap.get(rl.rC_Bios__Account_1__c).add(rl.Id);
            }
        }
        
        if(!relationshipIds.isEmpty() && Utilities.CanUseFutureContext()) {
            setRelationshipShareRecords(relationshipIds);
        }
        
        if(!relAccountMap.isEmpty()) {
            RelationshipTriggerHandler.shareRelWithAccountTeam(relAccountMap);
        }
    }
    
    /*    
    *
    *Method hasCreatePermission
    *@param : newList
    *It checks the createPermissions.
    */
    public static void hasPermission(List<rC_Bios__Relationship__c> newList){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, ID> mapContactIdToAccountId = new Map<ID, ID>();
        Map<ID, ID> mapOpportunityIdToAccountId = new Map<ID, ID>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();
        
        for(rC_Bios__Relationship__c obj: newList){
            if(obj.rC_Bios__Account_1__c != null){
                accountIds.add(obj.rC_Bios__Account_1__c);
            }
            
            if(obj.rC_Bios__Account_2__c != null){
                accountIds.add(obj.rC_Bios__Account_2__c);
            }
            
            if(obj.rC_Bios__Contact_1__c != null){
                contactIds.add(obj.rC_Bios__Contact_1__c);
            }
            
            if(obj.rC_Bios__Contact_2__c != null){
                contactIds.add(obj.rC_Bios__Contact_2__c);
            }
            
            if(obj.rC_Bios__Opportunity__c != null){
                opportunityIds.add(obj.rC_Bios__Opportunity__c);
            }
        }
        
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
        
        for(rC_Bios__Relationship__c obj: newList){
            //Below code is added for I-312661, by:Bhavesh
            //Info: if the matching contact was added in giving record through BGE, we do not need this validation if matched account is added on giving record through BGE
            Boolean skipValidatoinForMatchingAccount = obj.rC_Bios__Role_1__c == ACLU_Constants.CONST_ROLE1_EMPLOYEE 
                                                        && obj.rC_Bios__Role_2__c == ACLU_Constants.CONST_ROLE2_EMPLOYER
                                                        && obj.rC_Bios__Category__c == ACLU_Constants.CONST_CATEGORY_EMPLOYMENT ? TRUE : FALSE;
            if(userAccessMap.containsKey(obj.rC_Bios__Account_1__c+'-'+UserInfo.getUserId()) && !userAccessMap.get(obj.rC_Bios__Account_1__c+'-'+UserInfo.getUserId())) {
                if(obj.rC_Bios__Account_1__c != null && !skipValidatoinForMatchingAccount){
                    if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account_1__c)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account_1__c)) ){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
            }
            
            /*if(obj.rC_Bios__Account_2__c != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account_2__c)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account_2__c))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }*/
            
            if(obj.rC_Bios__Contact_1__c != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact_1__c))) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact_1__c)))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
            
            /*if(obj.rC_Bios__Contact_2__c != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact_2__c))) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact_2__c)))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
            
            if(obj.rC_Bios__Opportunity__c != null && string.ValueOf(obj.rC_Bios__Opportunity__c).startsWith('006')){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapOpportunityIdToAccountId.get(obj.rC_Bios__Opportunity__c))) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapOpportunityIdToAccountId.get(obj.rC_Bios__Opportunity__c)))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }*/
        }
    }
    
     /*    
    *
    *Method shareRelWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void shareRelWithAccountTeam(Map<Id, Set<Id>> relAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (relAccountMap.size() > 0) {
            Map<Id, Set<Id>> newrelAccountMap = new Map<Id, Set<Id>>();

            for (Id key : relAccountMap.KeySet()) { 
                if (newrelAccountMap.size() < accountAsyncBatchMax) {
                    newrelAccountMap.put(key, relAccountMap.get(key));
                    relAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'rC_Bios__Relationship__c',
                                   Params__c = JSON.serialize(newrelAccountMap)));
        }
        
        try {
            insert newAsyncRequests;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('PreferenceTriggerHandler','sharePrefWithAccountTeam', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    /*    
    *
    *Method setRelationshipShareRecords
    *@param : newMap
    *It creates the share records based on the their accountAffiliation.
    *
    */
    //@future
    public static void setRelationshipShareRecords(Set<Id> relationshipIds){
        //variables
        List<String> groupNames = new List<String>();
        List<rC_Bios__Relationship__share> RelationshipSharesToBeInsert = new List<rC_Bios__Relationship__share>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new Map<Id,rC_Bios__Relationship__c>();
        Map<Id,Boolean> mapRelationshipIdToRestricted = new Map<Id,Boolean>(); 
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        
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
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertRelationshipSharingRecords (mapRelationshipIdToRelationship, mapGroupNameToId, mapRelationshipIdToRestricted);

    }
    
    /*    
    *
    *Method onAfterUpdate
    *@param : newMap
    *@param : OldMap
    *It checks whether the Account/Contact Lookup changed.
    *
    */
    public static void onAfterUpdate(Map<Id,rC_Bios__Relationship__c> newMap, Map<Id,rC_Bios__Relationship__c> OldMap){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> relationshipIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> OpporutunityIds = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        
        for(rC_Bios__Relationship__c rl: newMap.Values()){
            if(OldMap.get(rl.Id).rC_Bios__Account_1__c != rl.rC_Bios__Account_1__c){
                accountIds.add(OldMap.get(rl.Id).rC_Bios__Account_1__c);
                relationshipIds.add(rl.Id);
            }
            
            if(OldMap.get(rl.Id).rC_Bios__Account_2__c != rl.rC_Bios__Account_2__c){
                accountIds.add(OldMap.get(rl.Id).rC_Bios__Account_2__c);
                relationshipIds.add(rl.Id);
            }
            
            if(OldMap.get(rl.Id).rC_Bios__Contact_1__c != rl.rC_Bios__Contact_1__c){
                accountIds.add(OldMap.get(rl.Id).rC_Bios__Contact_1__r.accountId);
                relationshipIds.add(rl.Id);
                contactIds.add(OldMap.get(rl.Id).rC_Bios__Contact_1__c);
            }
            
            if(OldMap.get(rl.Id).rC_Bios__Contact_2__c != rl.rC_Bios__Contact_2__c){
                accountIds.add(OldMap.get(rl.Id).rC_Bios__Contact_2__r.accountId);
                relationshipIds.add(rl.Id);
                contactIds.add(OldMap.get(rl.Id).rC_Bios__Contact_2__c);
            }
            
            if(OldMap.get(rl.Id).rC_Bios__Opportunity__r != rl.rC_Bios__Opportunity__r){
                accountIds.add(OldMap.get(rl.Id).rC_Bios__Opportunity__r.accountId);
                relationshipIds.add(rl.Id);
                OpporutunityIds.add(OldMap.get(rl.Id).rC_Bios__Opportunity__c);
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
        if(!OldAffiliations.IsEmpty() && Utilities.CanUseFutureContext()){
            resetRelationshipShareRecords(relationshipIds,OldAffiliations);
        }
    }
    
    /*    
    *
    *Method resetRelationshipShareRecords
    *@param : Set<Id> (relationshipIds)
    *@param : List<String> OldAffiliations
    *It resets the share records based on the their account Affiliation.
    *
    */
    //@future
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
            if(mapRe.rC_Bios__Contact_2__c != null && mapRe.rC_Bios__Contact_2__r.account.Affiliation__c != null)
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
}