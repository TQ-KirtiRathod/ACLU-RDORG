/*
*
*Name  :  CampaignHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 30, 2016
*Purpose :  Handler Class for Campaign_Trigger
            Logic includes but not limited to
            - Custom permission logic
            - Updates Campaign fields
            - Apex Sharing
            - Source Code population and management
            - Creates Tasks
* Made changes by roundCroner #61427
*/
public with sharing class CampaignHandler {
    // Class Members
    public static Id transactionOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    public static Id pledgePaymentOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    public static String national;
    public static List<GroupMember> groupMembers;
    public static Boolean isUpdatedFromInsertTrigger = false;//Added BY Bhavesh, I-295634
    static Id advocacyId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Advocacy').getRecordTypeId();
    static Id standardId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
    static {
        national = Label.National;
        groupMembers = [SELECT id, Group.name, UserOrGroupId FROM GroupMember WHERE Group.name =: national AND UserOrGroupId =: UserInfo.getUserId()];
    }
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */
    public static void mainEntry(List<Campaign> newList, List<Campaign> oldList, Map<Id, Campaign> newMap, Map<Id, Campaign> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {

        //if trigger is active
        if(TriggerState.isActive('Campaign_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {

            // It is called on before insert
            if(isBefore) {
                if(isInsert) {
                    onBeforeInsert(newList);
                }
                if(isUpdate){
                    onBeforeUpdate(newMap, oldMap);
                }
            }
            // It is called on after insert
            if(isAfter) {
                if(isInsert) {
                    onAfterInsert(newList);
                }
            }

            // It is called on after update
            if(isAfter) {
                if(isUpdate) {
                    onAfterUpdate(newMap, oldMap);
                }

            }

        }

    }
    /*
    *
    *Method onBeforeInsert
    *@description : setting the default value for the campaign.
    */
    //ZenDesk - #61427
    public static void onBeforeInsert (List<Campaign> Campaigns){
         for(Campaign cm: Campaigns){
            if(String.ValueOf(cm.RecordTypeId).equalsIgnoreCase(advocacyId)) {
                 cm.IsActive = true;
                 checkRequiredFields(cm);
            }else if(String.ValueOf(cm.RecordTypeId).equalsIgnoreCase(standardId)) {
                cm.IsActive = true;
            }
             if(cm.rC_Giving__Drop_Date__c== null) {
                 cm.rC_Giving__Drop_Date__c = Date.ValueOf(cm.rC_Giving__Start_Date_Time__c);
             }
         }
    }
    //ZenDesk - END #61427
    //ZenDesk - #61427
    //Validates the required fields
    public static void checkRequiredFields(campaign cm) {
        if(String.isBlank(cm.rC_Giving__Affiliation__c)) {
            cm.rC_Giving__Affiliation__c.addError('Please enter a value in Affiliation field.');
        }else if(String.isBlank(cm.rC_Giving__Sub_Affiliation__c)) {
            cm.rC_Giving__Sub_Affiliation__c.addError('Please enter a value in Sub-Affiliation field.');
        }else if(cm.rC_Giving__Start_Date_Time__c == null) {
            cm.rC_Giving__Start_Date_Time__c.addError('Please enter a value in Start Date field.');
        }else if(cm.rC_Giving__End_Date_Time__c == null) {
            cm.rC_Giving__End_Date_Time__c.addError('Please enter a value in End Date field.');
        }
    }//ZenDesk - END #61427
    /*
*
*Method hasCreatePermission
*@param : affiliationCodes
*@param : campaignList
*It checks the createPermissions.
*
*/
    public static void hasPermission(List<String> affiliationCodes, List<Campaign> campaigns){
        //Method Variables
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();

        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(affiliationCodes);
        for(campaign obj: campaigns){
            if(obj.All_Affiliate_Edit_Access__c == false && groupMembers.IsEmpty() && mapRecordToPermissions.get(obj.Record_Sharing_Affiliate__c) != null && !mapRecordToPermissions.get(obj.Record_Sharing_Affiliate__c)){
                obj.addError('You do not have permission to use a campaign (source code) belonging to another affiliate.');
            }
        }
    }

    /*
    *
    *Method onAfterInsert
    *@description : Creates ShareRecords based on Affiliation.
    */
    public static void onAfterInsert (List<Campaign> Campaigns){
       
        isUpdatedFromInsertTrigger = true;//Added BY Bhavesh, I-295634
        //Method Variables
        List<String> affiliationCodes = new List<String>();
        Map<Id,String> mapCampaignIdToAffliation = new Map<Id,String>();
        Id advocacyId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Advocacy').getRecordTypeId();
        Map<Id, Campaign> toUpdate = new Map<Id, Campaign>();

        // Collect the Id's along with the Affilation names
        // Autopopulate source code fields appropriately.
        for(Campaign obj: Campaigns) {
            Campaign c = null;
            if(obj.rC_Giving__Affiliation__c == null) {
                c = new Campaign(Id = obj.Id);
                c.rC_Giving__Affiliation__c = 'UN - Union National';
                toUpdate.put(c.Id, c);
            }

            if (obj.RecordTypeId == advocacyId) {
                if (c == null) {
                    if (toUpdate.containsKey(obj.Id)) {
                        c = toUpdate.get(obj.Id);
                    } else {
                        c = new Campaign(Id = obj.Id);
                    }
                }

                if (String.isBlank(obj.rC_Giving__Campaign_Type__c))
                    c.rC_Giving__Campaign_Type__c = 'W - Website';
                if (String.isBlank(obj.rC_Giving__Channel__c))
                    c.rC_Giving__Channel__c = 'Website';
                if (String.isBlank(obj.rC_Giving__Appeal_Segment__c))
                    c.rC_Giving__Appeal_Segment__c = 'XX Not Specified';
                if (String.isBlank(obj.rC_Giving__Effort__c))
                    c.rC_Giving__Effort__c = '00';
                if (String.isBlank(obj.rC_Giving__Solicitation_Type__c))
                    c.rC_Giving__Solicitation_Type__c = 'New';
                if (obj.StartDate == null)
                    c.StartDate = Date.today();
                if (obj.EndDate == null)
                    c.EndDate = Date.today();
                if (obj.rC_Giving__Start_Date_Time__c == null)
                    c.rC_Giving__Start_Date_Time__c = Datetime.now();
                if (obj.rC_Giving__End_Date_Time__c == null)
                    c.rC_Giving__End_Date_Time__c = Datetime.now();

                c.Status = 'In Progress';

                // This is a defaulted picklist so it'll never be null. Clamp to a reasonable value.
                c.Type = 'Advocacy';

                toUpdate.put(c.Id, c);
            }

            // create Share Records
            if(obj.Record_Sharing_Affiliate__c != null)
                mapCampaignIdToAffliation.put(obj.Id,obj.Record_Sharing_Affiliate__c);
            // Has Permission
            if(obj.Record_Sharing_Affiliate__c != null){
                affiliationCodes.add(obj.Record_Sharing_Affiliate__c);
            }
        }
        if(!mapCampaignIdToAffliation.IsEmpty() && Utilities.CanUseFutureContext()){
            createSharingRecords(mapCampaignIdToAffliation);
        }

        // Check Permission
        if(!affiliationCodes.IsEmpty()){
            hasPermission(affiliationCodes, Campaigns);
        }

        if (toUpdate.size() > 0) {
            update toUpdate.values();
        }

        // Update the campaign name to include the source code post-pended.
        // If we're updating the campaign with an autopopulated value, exclude it. 
        // We will catch those in an after update call.

        List<Campaign> updateSourceCodes = new List<Campaign>();

        for (Campaign c : Campaigns) {
            // If the source code is populated at time of insert, go ahead and append it even if the campaign
            // is having some autopopulation done.
            if (!toUpdate.containsKey(c.Id) || String.isNotBlank(c.rC_Giving__Source_Code__c)) {
                updateSourceCodes.add(c);
            }
        }

        if (updateSourceCodes.size() > 0) {
            updateCampaignNamesWithSourceCodes(updateSourceCodes, null);
        }
        isUpdatedFromInsertTrigger = false;//Added BY Bhavesh, I-295634
    }
    /*
    *
    *Method resetSharingRecords
    *@description : Creates ShareRecords based on Affiliation.
    */
    //@future
    public static void createSharingRecords (Map<Id,String> mapCampaignIdToAffliation){
        // Method Variables
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,String> mapCampaignIdToNewAffliation = new Map<Id,String>();


        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapCampaignIdToAffliation.Values()]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        // Insert the Updated Affiliations
        System.debug('mapCampaignIdToAffliation ->'+mapCampaignIdToAffliation);
        System.debug('mapGroupNameToId ===>'+mapGroupNameToId);
        InsertcampaignShares(mapCampaignIdToAffliation, mapGroupNameToId);
    }
    public static void updateCampaignNamesWithSourceCodes(List<Campaign> cs, Map<Id, Campaign> oldCampMap) {
        // This method will be called either from the afterInsert or afterUpdate method
        // In both cases, we need a DML operation, but we don't have to requery to get the source code.
        // It'll be populated correctly (for the autopopulated case) in the afterUpdate flow.

        Map<Id, Campaign> toUpdate = new Map<Id, Campaign>();

        for (Campaign c : cs) {
            if (String.isNotBlank(c.rC_Giving__Source_Code__c) && !c.Name.endsWith(c.rC_Giving__Source_Code__c)) {
                if(oldCampMap == null) {
                    toUpdate.put(c.Id, new Campaign(Id = c.Id, Name = c.Name+'-'+c.rC_Giving__Source_Code__c));
                } else {
                    toUpdate.put(c.Id, new Campaign(Id = c.Id, 
                    Name = (c.Name).removeEnd('-'+oldCampMap.get(c.Id).rC_Giving__Source_Code__c)+'-'+c.rC_Giving__Source_Code__c));
                }
            }
        }

        if (toUpdate.size() > 0) {
            update toUpdate.values();
        }
    }
    /*
    *
    *Method onBeforeUpdate
    *@description : Validates the required fields
    */
    //ZenDesk - #61427
    public static void onBeforeUpdate (Map<Id,Campaign> newMap, Map<Id,Campaign> OldMap){
         for(Campaign cm: newMap.Values()){
            if(String.ValueOf(cm.RecordTypeId).equalsIgnoreCase(advocacyId)) {
                 checkRequiredFields(cm);
                if(String.isBlank(cm.rC_Giving__Campaign_Type__c)) {
                    cm.rC_Giving__Campaign_Type__c.addError('Please enter a value in Campaign Type field.');
                }else if(String.isBlank(cm.rC_Giving__Channel__c)) {
                    cm.rC_Giving__Channel__c.addError('Please enter a value in Channel field.');
                }else if(String.isBlank(cm.rC_Giving__Appeal_Segment__c)) {
                    cm.addError('Please enter a value in Appeal Segment field.');
                }else if(String.isBlank(cm.rC_Giving__Effort__c )) {
                    cm.rC_Giving__Effort__c .addError('Please enter a value in Effort field.');
                }
            }
            if(cm.rC_Giving__Drop_Date__c== null) {
                 cm.rC_Giving__Drop_Date__c =  Date.ValueOf(cm.rC_Giving__Start_Date_Time__c);
            } 
        }
    }
    //ZenDesk -END #61427
    /*
    *
    *Method onAfterUpdate
    *@description : calls on AfterInsert
    */

    public static void onAfterUpdate (Map<Id,Campaign> newMap, Map<Id,Campaign> OldMap){
        //Method Variables
        List<String> OldAffiliations = new List<String> ();
        List<String> affiliationCodes = new List<String>();
        Map<Id,String> mapCampaignIdToNewAffliation = new Map<Id,String>();
        map<Id, Opportunity> mapOppsToUpdate = new map<Id, Opportunity>();
        Map<Id, Campaign> cmpLstToCreateDocAttachTask = new Map<Id, Campaign>();
        List<Campaign> updateSourceCodes = new List<Campaign>();
        System.debug(isUpdatedFromInsertTrigger);
       
        
        String userProfileId = UserInfo.getProfileId();
        String userName = UserInfo.getUserName();
        // Collect the Id's along with the Affilation names
       
        for(Campaign obj: newMap.Values()){
            
             /*Added below code  BY Bhavesh,FOR I-295634
        Descrition: Removed validation rule, added validation in trigger, if campaign is active then below fields can not be updated.*/
            if( isUpdatedFromInsertTrigger != TRUE 
                && userProfileId != Label.SysAdminProfileId && obj.IsActive == TRUE 
                && (obj.Name != OldMap.get(obj.id).Name
                    || obj.rC_Giving__Affiliation__c != OldMap.get(obj.id).rC_Giving__Affiliation__c
                    || obj.rC_Giving__Sub_Affiliation__c != OldMap.get(obj.id).rC_Giving__Sub_Affiliation__c
                    || obj.rC_Giving__Campaign_Type__c != OldMap.get(obj.id).rC_Giving__Campaign_Type__c
                    || obj.rC_Giving__Appeal_Segment__c != OldMap.get(obj.id).rC_Giving__Appeal_Segment__c
                    || obj.rC_Giving__Effort__c != OldMap.get(obj.id).rC_Giving__Effort__c
                    || obj.rC_Giving__Start_Date_Time__c != OldMap.get(obj.id).rC_Giving__Start_Date_Time__c)
                && !(userName.indexOf('roundData Sync') >= 0 && userProfileId == Label.ACLU_rD_Sync_User_Profile)){ 
                    obj.addError('The Campaign must be inactive in order to update these values.');
            }
            //END  I-295634
            // if Intended Affiliation or Restricted Account Changes
            if((OldMap.get(obj.Id).Record_Sharing_Affiliate__c != obj.Record_Sharing_Affiliate__c)){
                if(obj.Record_Sharing_Affiliate__c != null){
                    mapCampaignIdToNewAffliation.put(obj.Id,obj.Record_Sharing_Affiliate__c);
                }
                if(OldMap.get(obj.Id).Record_Sharing_Affiliate__c!= null){
                    OldAffiliations.add(OldMap.get(obj.Id).Record_Sharing_Affiliate__c);
                }
            }

            // Check if the source code has changed and update the name if necessary.

            if (oldMap.get(obj.Id).get('rC_Giving__Source_Code__c') != obj.rC_Giving__Source_Code__c || oldMap.get(obj.Id).get('Name') != obj.Name) {
                updateSourceCodes.add(obj);
            }

            // Has Permission
            if(obj.Record_Sharing_Affiliate__c != null ){
                affiliationCodes.add(OldMap.get(obj.Id).Record_Sharing_Affiliate__c);
            }

            // Populate variable to pass in createDocumentAttachmentTask Method
            if(!obj.Set_Document_Attached__c && obj.Trigger_Attachment_Review_Process__c != null && oldMap.get(obj.Id).Trigger_Attachment_Review_Process__c != obj.Trigger_Attachment_Review_Process__c) {
                cmpLstToCreateDocAttachTask.put(obj.Id, obj);
            }
        }

        // Check Permission
        if(!affiliationCodes.IsEmpty()){
            if(!ContactTriggerHandler.deceasedChecked) {
                hasPermission(affiliationCodes, newMap.Values());
            }
        }

        if(!mapCampaignIdToNewAffliation.IsEmpty()){
            resetSharingRecords(mapCampaignIdToNewAffliation, OldAffiliations);
        }

        //DML Operation
        if(!mapOppsToUpdate.Keyset().IsEmpty()){
            try{
                update mapOppsToUpdate.Values();
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignHandler','onAfterUpdate',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }

        // Method to create Task for Document Attachment
        if(!cmpLstToCreateDocAttachTask.isEmpty()) {
            createDocumentAttachmentTask(cmpLstToCreateDocAttachTask);
        }
	   //Made changes to not fire again when its insert scenario
        if (updateSourceCodes.size() > 0 && !isUpdatedFromInsertTrigger) {
            updateCampaignNamesWithSourceCodes(updateSourceCodes, OldMap);
        }
    }

    /*
    *
    *Method createDocumentAttachmentTask
    *@param : Map<Id, Campaign> (Campaigns)
    *It creates tasks for Document Attachment on Campaign
    *
    */
    public static void createDocumentAttachmentTask(Map<Id, Campaign> cmpLstToCreateDocAttachTask) {
        List<Task> tsksToInsert = new List<Task>();
        Map<Id, Id> cmpToTskMap = new Map<Id, Id>();

        for(Task objTsk : [SELECT Id, Subject, WhatId FROM Task WHERE WhatId IN: cmpLstToCreateDocAttachTask.KeySet()]) {
            if(objTsk.WhatId.getSobjectType() == Campaign.SobjectType && objTsk.Subject == 'Attach Donation Backup Documentation') {
                cmpToTskMap.put(objTsk.WhatId, objTsk.Id);
            }
        }

        for(Campaign objCmp : cmpLstToCreateDocAttachTask.values()) {
            if(!cmpToTskMap.containsKey(objCmp.Id)) {
                Task newTsk = new Task();
                newTsk.OwnerId = objCmp.OwnerId;
                newTsk.Subject = 'Attach Donation Backup Documentation';
                newTsk.WhatId = objCmp.Id;
                newTsk.Description = Label.Donation_Backup_Documentation_Desc1+ '<br/>'+Label.Donation_Backup_Documentation_Desc2;
                tsksToInsert.add(newTsk);
            }
        }

        if(!tsksToInsert.isEmpty()) {
            try{
                insert tsksToInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignHandler','createDocumentAttachmentTask',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method resetSharingRecords
    *@description : resets the Sharing Records
    */


    //@future
    public static void resetSharingRecords (Map<Id,String> mapCampaignIdToAffliation, List<String> OldAffiliations){
        // Method Variables
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapCampaignIdToAffliation.Values() OR Name=: OldAffiliations]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old Affiliations
        deletecampaignShares(mapCampaignIdToAffliation, OldAffiliations, mapGroupNameToId);
        // Insert the Updated Affiliations
        InsertcampaignShares(mapCampaignIdToAffliation, mapGroupNameToId);

    }

    /*
    *
    *Method InsertcampaignShares
    *@description : Insert the campaign Share Records
    */



    public static void InsertcampaignShares (Map<Id,String> mapCampaignIdToAffliation, Map<String,Id> mapGroupNameToId){
        // Method Variables
        List<Campaignshare> campaignSharesToBeInsert = new List<Campaignshare>();

        //Create campaignShare records with their respective Public group based on Affiliation.
        for(Id objId: mapCampaignIdToAffliation.KeySet()){
            if(mapCampaignIdToAffliation.get(objId) != null && mapGroupNameToId.get(mapCampaignIdToAffliation.get(objId)) != null){
                Campaignshare bUShare = new Campaignshare();
                bUShare.CampaignAccessLevel = 'Edit';
                // assigns the groupId from BatchUpload Id via using the two maps we created above.
                bUShare.UserOrGroupId = mapGroupNameToId.get(mapCampaignIdToAffliation.get(objId));
                bUShare.CampaignId = objId;
                campaignSharesToBeInsert.add(bUShare);
            }
        }
        // Insert campaign ShareRecords
        if(!campaignSharesToBeInsert.isEmpty()){
            try{
                insert campaignSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignHandler','InsertcampaignShares',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method deletecampaignShares
    *@description : Deletes the batch Upload share records
    */



    public static void deletecampaignShares (Map<Id,String> mapCampaignIdToAffliation, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId){
        // Method Variables
        Set<Id> groupIds = new Set<Id>();
        List<Campaignshare> campaignSharesToBeDelete = new List<Campaignshare> ();

        // Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        for(Campaignshare objBU: [SELECT id, CampaignId  FROM Campaignshare WHERE UserOrGroupId =: groupIds AND CampaignAccessLevel = 'Edit' AND CampaignId =:mapCampaignIdToAffliation.KeySet()]){
            campaignSharesToBeDelete.add(objBU);
        }
        // Delete the Old Sharing Records
        if(!campaignSharesToBeDelete.IsEmpty()){
            try{
            delete campaignSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignHandler','deletecampaignShares',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
}