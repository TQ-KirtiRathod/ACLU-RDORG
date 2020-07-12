/*
*
*Name  :  ContentDocumentLinkTriggerHandler
*Author:  Appirio India (Lalit Bohra)
*Date  :  Aug 16, 2017
*Purpose : Handler class for ContentDocumentLinkTrigger
*          Logic includes cusotm validations and updates flags on opportunity
*Modified by :: SFDO :: 10-June-2019 :: Zendesk: #57624
*/
public class ContentDocumentLinkTriggerHandler {
    public static Set<String> unAllowedAffiliations = new Set<String>{'UN - Union National', 'FN - Foundation National', 'EN - Endowment Bequest National', 'National Acquisition'};
    public static Set<String> allowedCampaignLevels = new Set<String>{'K', 'G', 'D'};
    public static User loggedInUser;
    
    static {
        loggedInUser = [select Profile.Name, Is_Affiliate_User__c from User where id = :Userinfo.getUserId()];
    }
    public static void mainEntry(List<ContentDocumentLink> newList, List<ContentDocumentLink> oldList, Map<Id,ContentDocumentLink> newMap, Map<Id,ContentDocumentLink> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter){
        if(TriggerState.isActive('ContentDocumentLinkTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_WebTools_profile_Id)) { 
             if(isBefore) {
                if(isInsert) {
                    beforeInsert(newList);
                }
             }
            if(isAfter){
                // Zendesk:  #57624 
                 if(isInsert) {
                     afterInsert(newList);
                 }//End #57624 
             }
        }
    }
    
    
    public static void beforeInsert(List<ContentDocumentLink> newLst){
        Set<Id> opptyIdsToSetDocAttahedFlag = new Set<Id>();
        Set<Id> cmpIdsToSetDocAttahedFlag = new Set<Id>();
        Set<Id> accIdsToAttachFile = new Set<Id>();
        list<ContentDocumentLink> contentList = new list<ContentDocumentLink>();
        for(ContentDocumentLink objAttach : newLst) {
            //Check if added attachment is related to Opportunity or not
           System.debug('Before Insert');
            if(objAttach.LinkedEntityId.getSobjectType() == Opportunity.SobjectType && loggedInUser.Is_Affiliate_User__c){
                  opptyIdsToSetDocAttahedFlag.add(objAttach.LinkedEntityId);
             } else if(objAttach.LinkedEntityId.getSobjectType() == Campaign.SobjectType && loggedInUser.Is_Affiliate_User__c) {
                 cmpIdsToSetDocAttahedFlag.add(objAttach.LinkedEntityId);
             } else if(objAttach.LinkedEntityId.getSobjectType() == Account.SobjectType) {
                 accIdsToAttachFile.add(objAttach.LinkedEntityId);
             }
        }
        
        if(!opptyIdsToSetDocAttahedFlag.isEmpty()) {
            updateDocumentAttachedFlagonOppty(opptyIdsToSetDocAttahedFlag);
        }
        
        if(!cmpIdsToSetDocAttahedFlag.isEmpty()) {
            updateDocumentAttachedFlagonCampaign(cmpIdsToSetDocAttahedFlag);
        }
        if(accIdsToAttachFile.size() > 0) {
            hasPermission(accIdsToAttachFile, contentList);
        }
    }
    // Zendesk:  #57624
    public static void afterInsert(List<ContentDocumentLink> contentDocumentLinkList) {
		final String OPPORTUNITYOBJ = 'Opportunity';
		final String TASKOBJ = 'Task';
		final String CONTACTOBJ = 'Contact';
		final String EVENTOBJ = 'Event';
		final String PLANNED_GIVING = 'Planned Giving';
		final String PROSPECT_RESEARCH = 'Prospect Research';
        List<ContentDocumentLink> contentDocListToInsert = new List<ContentDocumentLink>();
        Map<Id,Id> contentDocLinkedEntityMap = new Map<Id,Id>(); 
        Map<Id,Id> objAccountMap = new Map<Id,Id>(); 
        Set<String> queryObjSet = new Set<String>(); // Set is used to query objects
        List<ContentDocumentLink> newContentDocList = new List<ContentDocumentLink>();
        Map<Id,Set<String>> existingAccountContentTitle = new Map<Id,Set<String>>();
        Map<id,ContentDocument> newMapContentTitle = new Map<id,ContentDocument>();
        for(ContentDocumentLink objAttach : contentDocumentLinkList) {
            //Check if added attachment is related to Oppty, Contact,Activity, Planned Giving, Prospect Research, etc. 
            Boolean isInsert = false;    
            if(objAttach.LinkedEntityId != null) {
                if(objAttach.LinkedEntityId.getSobjectType() == Opportunity.SobjectType) {
                    queryObjSet.add(OPPORTUNITYOBJ);
                    isInsert = true;
                }else if(objAttach.LinkedEntityId.getSobjectType() == Task.SobjectType) {
                    queryObjSet.add(TASKOBJ);
                    isInsert = true;
                }else if(objAttach.LinkedEntityId.getSobjectType() == Event.SobjectType) {
                    queryObjSet.add(EVENTOBJ);
                    isInsert = true;
                }else if(objAttach.LinkedEntityId.getSobjectType() == rC_Giving__Planned_Giving__c.SobjectType) {
                    queryObjSet.add(PLANNED_GIVING);
                    isInsert = true;
                }else if(objAttach.LinkedEntityId.getSobjectType() == Prospect_Research__c.SobjectType) {
                    queryObjSet.add(PROSPECT_RESEARCH);
                    isInsert = true;
                }else if(objAttach.LinkedEntityId.getSobjectType() == Contact.SobjectType) {
                    queryObjSet.add(CONTACTOBJ);
                    isInsert = true;
                }
                if(isInsert) {
                    contentDocLinkedEntityMap.put(objAttach.ContentDocumentId,objAttach.LinkedEntityId);
                    newContentDocList.add(objAttach);
                }
            }
        }
        if(queryObjSet.contains(OPPORTUNITYOBJ)){
            objAccountMap.putAll(queryOppoAccountIds(contentDocLinkedEntityMap.Values()));
        }if(queryObjSet.contains(CONTACTOBJ)){
            objAccountMap.putAll(queryConAccountIds(contentDocLinkedEntityMap.Values()));
        }if(queryObjSet.contains(PROSPECT_RESEARCH)) {
            objAccountMap.putAll(queryProspectResearchAccountIds(contentDocLinkedEntityMap.Values()));
        }if(queryObjSet.contains(PLANNED_GIVING)) {
            objAccountMap.putAll(queryPlannedGivingIds(contentDocLinkedEntityMap.Values()));
        }if(queryObjSet.contains(EVENTOBJ)) {
            objAccountMap.putAll(queryEventIds(contentDocLinkedEntityMap.Values()));
        }if(queryObjSet.contains(TASKOBJ)) {
            objAccountMap.putAll(queryTaskIds(contentDocLinkedEntityMap.Values()));
        }
        
        if(objAccountMap.isEmpty()) {
            return; 
        }
        //Get the title values to find duplicate records
        newMapContentTitle = new Map<id,ContentDocument>([SELECT   Id
                                                              , Title 
                                                              FROM ContentDocument
                                                              WHERE Id IN :contentDocLinkedEntityMap.KeySet()]);
         //Get the all existing content Document records related to accounts   
         existingAccountContentTitle = queryContentDocumentAccountIds(objAccountMap.Values()); 
        
         for(ContentDocumentLink content :newContentDocList) {
             if(objAccountMap.get(content.LinkedEntityId) != null) {
             	
                 if(existingAccountContentTitle.containsKey(objAccountMap.get(content.LinkedEntityId))) {
                     //Check existing content doc, if it contains then don't create content doc
                     if(existingAccountContentTitle.get(objAccountMap.get(content.LinkedEntityId)).contains(newMapContentTitle.get(content.ContentDocumentId).Title)){
                         continue; 
                     }else {
                     	//Add in the existingAccountContentTitle,It will not create duplicate records
                        existingAccountContentTitle.get(objAccountMap.get(content.LinkedEntityId)).add(newMapContentTitle.get(content.ContentDocumentId).Title);
                        contentDocListToInsert.add(createContentDocumentObj(content,objAccountMap.get(content.LinkedEntityId)));
                     }
                 }else {
                 	//New content doc records to insert 
                    existingAccountContentTitle.put(objAccountMap.get(content.LinkedEntityId),new Set<String>{objAccountMap.get(content.LinkedEntityId)});
                    contentDocListToInsert.add(createContentDocumentObj(content,objAccountMap.get(content.LinkedEntityId)));
                    }
                }
            }
        if(contentDocListToInsert.size() > 0){
            insert contentDocListToInsert;
        }
    }
    private static Map<Id,Set<String>> queryContentDocumentAccountIds(List<Id> accountIds){
       
        Map<Id,Set<String>> existingAccountContentDocTitle = new Map<Id,Set<String>>();                                          
        List<ContentDocumentLink> contentList = [SELECT   Id
                                                        , LinkedEntityId
                                                        , ContentDocumentId
                                                        , ContentDocument.Title 
                                                   FROM   ContentDocumentLink 
                                                  WHERE   LinkedEntityId IN :accountIds];
        for(ContentDocumentLink con :contentList) {
            if(existingAccountContentDocTitle.containskey(con.LinkedEntityId)) {
                existingAccountContentDocTitle.get(con.LinkedEntityId).add(con.ContentDocument.Title);
            }else {
                existingAccountContentDocTitle.put(con.LinkedEntityId,new Set<String>{con.ContentDocument.Title});
            }
        }
        return existingAccountContentDocTitle;
        
    }
    private static Map<id,Id> queryOppoAccountIds(List<Id> sObjctIds){
        Map<id,Id> objAccountMap = new Map<Id,Id>();
        List<Opportunity> opportunities = ([SELECT  Id
                                                  , AccountId 
                                            FROM  Opportunity 
                                            WHERE Id IN :sObjctIds]);
                                            
        for(Opportunity opp :opportunities) {
            objAccountMap.put(opp.Id,Opp.AccountId);
        }
        return objAccountMap;
    }
    private static Map<id,Id> queryConAccountIds(List<Id> sObjctIds){
        Map<id,Id> objAccountMap = new Map<Id,Id>();
        List<Contact> contacts= [SELECT  id 
                                       , AccountId 
                                   FROM  Contact 
                                  WHERE id IN :sObjctIds];
        for(Contact con :contacts) {
            objAccountMap.put(con.Id,con.AccountId);
        }
      return objAccountMap;
    }
    private static Map<id,Id> queryProspectResearchAccountIds(List<Id> sObjectIds){
        Map<id,Id> objAccountMap = new Map<Id,Id>();
        List<Prospect_Research__c> prospectResearchList = [SELECT  id
                                                                 , Account__c 
                                                             FROM Prospect_Research__c 
                                                            WHERE Id IN :sObjectIds];
        for(Prospect_Research__c prospectResearch :prospectResearchList) {
            objAccountMap.put(prospectResearch.Id,prospectResearch.Account__c);
        }
        
        return objAccountMap;
    }
    private static Map<id,Id> queryTaskIds(List<Id> sObjectIds){
        Map<id,Id> objAccountMap = new Map<Id,Id>();
        List<Task> taskList = [SELECT  id
                                     , AccountId 
                                 FROM Task 
                                WHERE Id IN :sObjectIds];
        for(Task taskObj :taskList) {
                objAccountMap.put(taskObj.Id,taskObj.AccountId);
        }
        return objAccountMap;
    }
    private static Map<id,Id> queryEventIds(List<Id> sObjectIds){
        Map<id,Id> objAccountMap = new Map<Id,Id>();
        List<Event> eventList = [SELECT  id
                                 , AccountId 
                                 FROM Event 
                                 WHERE Id IN :sObjectIds];                                    
        for(Event eventObj :eventList) {
            objAccountMap.put(eventObj.Id,eventObj.AccountId);
        }
        return objAccountMap;
    }
    private static Map<id,Id> queryPlannedGivingIds(List<Id> sObjectIds){
        Map<id,Id> objAccountMap = new Map<Id,Id>();
        List<rC_Giving__Planned_Giving__c> plannedGivingList = [SELECT  id
                                                                , rC_Giving__Account__c 
                                                                FROM rC_Giving__Planned_Giving__c 
                                                                WHERE Id IN :sObjectIds];
        for(rC_Giving__Planned_Giving__c givingPlannedObj :plannedGivingList) {
            objAccountMap.put(givingPlannedObj.Id,givingPlannedObj.rC_Giving__Account__c);
        }
        return objAccountMap;
    }
    private static ContentDocumentLink createContentDocumentObj(ContentDocumentLink contentDoc,Id accountId) {
        ContentDocumentLink contentDocClone = new ContentDocumentLink();
        contentDocClone.ShareType = contentDoc.ShareType;
        contentDocClone.Visibility = contentDoc.Visibility;
        contentDocClone.ContentDocumentId = contentDoc.contentDocumentId;
        contentDocClone.LinkedEntityId = accountId;
        return contentDocClone;
    }
     // END:  #57624 
    /*
    *
    *Method updateDocumentAttachedFlagonCampaign
    *@param : cmpIds
    *@description : Method to Set Document Attached Flag on Campaign
    *
    */ 
    private static void updateDocumentAttachedFlagonCampaign(Set<Id> cmpIds) {
        List<Campaign> cmpLstToUpdate = new List<Campaign>();
        
        for(Campaign objCmp : [    SELECT Id, Set_Document_Attached__c, rC_Giving__Affiliation__c, rC_Giving__Campaign_Type__c 
                                    FROM Campaign 
                                    WHERE Id IN: cmpIds 
                                    AND rC_Giving__Affiliation__c NOT IN: unAllowedAffiliations]) {
            if(!objCmp.Set_Document_Attached__c && objCmp.rC_Giving__Campaign_Type__c != null && String.valueOf(objCmp.rC_Giving__Campaign_Type__c).substring(0,1) == 'S') {
                objCmp.Set_Document_Attached__c = true;
                cmpLstToUpdate.add(objCmp);
            }
        }
        
        if(cmpLstToUpdate.size() > 0) {
            try{
            update cmpLstToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('AttachmentTriggerHandler','updateDocumentAttachedFlagonCampaign',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    /*
    *
    *Method updateDocumentAttachedFlagonOppty
    *@param : opptyIds
    *@description : Method to Set Document Attached Flag on Opportunity
    *
    */ 
    private static void updateDocumentAttachedFlagonOppty(Set<Id> opptyIds) {
        List<Opportunity> opptyLstToUpdate = new List<Opportunity>();
        
        for(Opportunity objOppty : [    SELECT Id, Set_Document_Attached__c, Campaign.rC_Giving__Affiliation__c, Campaign_Type__c 
                                        FROM Opportunity 
                                        WHERE Id IN: opptyIds 
                                        AND Campaign.rC_Giving__Affiliation__c NOT IN: unAllowedAffiliations
                                        AND Campaign_Type__c IN: allowedCampaignLevels]) {
            if(!objOppty.Set_Document_Attached__c) {
                objOppty.Set_Document_Attached__c = true;
                opptyLstToUpdate.add(objOppty);
            }
        }
        
        if(opptyLstToUpdate.size() > 0) {
            try{
                update opptyLstToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('AttachmentTriggerHandler','updateDocumentAttachedFlagonOppty',e.getMessage());
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
    public static void hasPermission(Set<Id> accountIds, List<ContentDocumentLink> newList){
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();

        for(Account acc: [SELECT id,Affiliation__C FROM Account WHERE Id =: accountIds]){
            mapAccountIdToAffiliation.put(acc.Id,acc.Affiliation__c);
        }
        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(mapAccountIdToAffiliation.Values());
        for(ContentDocumentLink obj: newList){    
            if(obj.LinkedEntityId != null){
                if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.LinkedEntityId)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.LinkedEntityId))){
                    obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                }
            }
        }
    }
}