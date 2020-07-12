/*
*
*Name  :  RecordAccessUtility
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 15, 2016
*Purpose :  Reset the apex based sharing for the Account and related records.  
            This class establishes the sharing, security and access model(T-555213)"
*
*/

public class RecordAccessUtility {

    public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    /*
    *
    *Method: resetNGOCObjectsSharing
    *@param : Map<Id,String> (AccountIdToOldAffiliations)
    *@param : Boolean determines to reset otherNGOC object shares records or not.
    *@description : Method which resets the Sharing records for the NGOC as per the respective account Affiliation__c
    * Preference, Relationship, Salutation, Action Plan, Planned Giving, Payment Method are NGOC Objects
    */
    public static void resetNGOCObjectsSharing(Map<Id,String> AccountIdToOldAffiliations, Boolean isUpdateAccount){
        //Calculating the Account Sharing
        if(!system.isbatch()){
            RecordAccessUtility.resetAccountSharingWithFutureCall(isUpdateAccount,AccountIdToOldAffiliations);
        }else{
            RecordAccessUtility.resetAccountSharing(isUpdateAccount,AccountIdToOldAffiliations);
        }
    }

    /*
    *
    *Method: hasCreatePermission
    *@param : AffiliationName
    *@description : if the Logged in UserRole is affiliateUser and he is in the affiliate group then the method returns true.
    *
    */
    public static map<String, Boolean> hasCreatePermission(List<String> affiliations){
        map<String, Boolean> isCreate = new map<String, Boolean>();
        Boolean isAffiliateUser = [SELECT id, Is_Affiliate_User__c from USER WHERE Id =: UserInfo.getUserId()].Is_Affiliate_User__c;
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];

        if(UserInfo.getProfileId() == adminProfile.Id){
            for(String s: affiliations){
                isCreate.put(s,true);
            }
        }
        else if(!isAffiliateUser){
            for(String s: affiliations){
                isCreate.put(s,true);
            }
        }

        else if(isAffiliateUser){
            for(String s: affiliations){
                isCreate.put(s,false);
            }
            for(groupmember gp: [SELECT id, Group.name, UserOrGroupId FROM GroupMember WHERE Group.name =: affiliations AND UserOrGroupId =: UserInfo.getUserId()]){
                isCreate.put(gp.Group.name, true);
            }
        }

        return isCreate;
    }

     /*
    *
    *Method: resetAccountSharingWithoutFutureCall
    *@param : setId (AccountId)
    *@description : Future method
    *
    */
    @future
    public static void resetAccountSharingWithFutureCall(Boolean isUpdateAccount,Map<Id,String> mapAccountIdToOldAffiliations){
        RecordAccessUtility.resetAccountSharing(isUpdateAccount,mapAccountIdToOldAffiliations);
    }

        /*
    *
    *Method: resetAccountSharing
    *@param : setId (AccountId)
    *@description : Method which deletes all the Edit Sharing records Related to Accounts and recreates as per the respective Affiliation__c
    *
    */


    public static void resetAccountSharing(Boolean isUpdateAccount,Map<Id,String> mapAccountIdToOldAffiliations){
        // Method Variables
        Set<Id> groupIds = new Set<Id>();
        List<AccountShare> AccountSharesToBeDelete = new List<AccountShare> ();
        List<AccountShare> AccountSharesToBeInsert = new List<AccountShare>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,String> mapAccIdToAffliation = new Map<Id,String>();
        Map<Id,Boolean> mapAccIdToRestricted = new Map<Id,Boolean>();

        //Collect all the Account records Affliate field value;
        for(Account acc: [SELECT Id, Affiliation__c, Restricted_Account__c FROM Account WHERE Id =: mapAccountIdToOldAffiliations.KeySet()]){
            if(acc.Affiliation__c != null){
                mapAccIdToAffliation.put(acc.Id,acc.Affiliation__c);
                mapAccIdToRestricted.put(acc.Id,acc.Restricted_Account__c);
            }
        }

        if(isUpdateAccount ){
            //Collect all the Groups in a map
            for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapAccIdToAffliation.Values() OR Name =:mapAccountIdToOldAffiliations.Values() ]){
                mapGroupNameToId.put(grp.Name,grp.Id);
            }
            //Collect the groupIds based which are related to OldAffiliations
            for(String str: mapAccountIdToOldAffiliations.Values()){
                if(mapGroupNameToId.get(str) != null)
                    groupIds.add(mapGroupNameToId.get(str));
            }
            // Delete account Share records having edit access
            for(AccountShare AccShare: [SELECT Id, AccountAccessLevel, AccountId,UserOrGroupId 
                                        FROM AccountShare 
                                        WHERE UserOrGroupId =: groupIds AND AccountAccessLevel = 'Edit' 
                                        AND AccountId =:mapAccountIdToOldAffiliations.KeySet() And RowCause = 'Manual']){
                AccountSharesToBeDelete.add(AccShare);
            }
            // Delete the AccountShareRecords.
            if(!AccountSharesToBeDelete.isEmpty()){
                System.debug('=======delete'+ [Select id from accountshare where id =: AccountSharesToBeDelete[0].id]+'=='+AccountSharesToBeDelete);
                try{
                    delete AccountSharesToBeDelete;
                } catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                    'resetAccountSharing Delete Account Share error::' +e.getMessage());
                    log.logException(e);
                    log.saveLogs();
                }
            }
            
        }
        //collect the groupIds if not collected above
        if(mapGroupNameToId.keyset().IsEmpty()){
            //Collect all the Groups in a map
            for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapAccIdToAffliation.Values() ]){
                mapGroupNameToId.put(grp.Name,grp.Id);
            }
        }
          
        set<Id> setAccIdWithExistingShareRec = new set<Id>();
        if(isUpdateAccount) {
            // querry existing account share records
            for(AccountShare accShare : [SELECT Id, AccountAccessLevel, ContactAccessLevel, 
                                                OpportunityAccessLevel, UserOrGroupId, AccountId
                                         FROM AccountShare
                                         WHERE AccountId IN: mapAccIdToAffliation.KeySet() and RowCause = 'Manual']) {
                if(accShare.AccountAccessLevel == 'Edit' && accShare.ContactAccessLevel == 'Edit' 
                    && accShare.OpportunityAccessLevel == 'Edit'
                    && accShare.UserOrGroupId == mapGroupNameToId.get(mapAccIdToAffliation.get(accShare.AccountId))) {
                    setAccIdWithExistingShareRec.add(accShare.AccountId);
                }
            }
        }
        //Create accountShare records with their respective Public group.
        for(Id objId: mapAccIdToAffliation.KeySet()){
            if(mapAccIdToAffliation.get(objId) != null && mapGroupNameToId.get(mapAccIdToAffliation.get(objId)) != null 
               && !setAccIdWithExistingShareRec.contains(objId)){
                AccountShare accShare = new AccountShare();
                accShare.AccountAccessLevel = 'Edit';
                accShare.ContactAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                // assigns the groupId from AccountId via using the two maps we created above.
                accShare.UserOrGroupId = mapGroupNameToId.get(mapAccIdToAffliation.get(objId));
                accShare.AccountId = objId;
                if(!mapAccIdToRestricted.get(objId))
                    AccountSharesToBeInsert.add(accShare);
            }
        }

        // InsertsAccountShareRecords
        if(!AccountSharesToBeInsert.isEmpty()){
            System.debug('=======insert'+ AccountSharesToBeInsert);
            try{
                upsert AccountSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                   'resetAccountSharing Upsert Account Shares error:: '+e.getMessage() + 
                                                   ' :: AccountSharesToBeInsert = '+ AccountSharesToBeInsert + 
                                                   '  isUpdateAccount= '+isUpdateAccount  );
                log.logException(e);
                log.saveLogs();
            }
        }

        if(isUpdateAccount ){
            //Payment method
            RecordAccessUtility.resetPaymentMethodSharing(mapAccountIdToOldAffiliations.KeySet(), mapAccountIdToOldAffiliations.Values());
            if(!system.isbatch()){
                RecordAccessUtility.setSharingForChildRecords(mapAccountIdToOldAffiliations);
            }
            else if(system.isbatch()){
                List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
                newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='Create_Sharing', 
                                       Object_API_Name__c = 'Account',
                                       Params__c = JSON.serialize( mapAccountIdToOldAffiliations)));
                                       
                insert newAsyncRequests;                       
                /*if(!Test.isRunningTest()) {//Added for test class failure
                    System.enqueueJob(new RecordAccessQueueableClass(mapAccountIdToOldAffiliations));
                } else {
                    if(Limits.getQueueableJobs() == 0) {
                        System.enqueueJob(new RecordAccessQueueableClass(mapAccountIdToOldAffiliations));
                    }
                }*/
            }                      
        }
    }
    
    @future
    public static void SharingForChildRecordsWithFutureCall (Map<Id,String> mapAccountIdToOldAffiliations){
        RecordAccessUtility.setSharingForChildRecords(mapAccountIdToOldAffiliations);
    }
    
    //set Sharing for Other methods
    public static void setSharingForChildRecords(Map<Id,String> mapAccountIdToOldAffiliations){
        // Preference
        RecordAccessUtility.resetPreferenceSharing(mapAccountIdToOldAffiliations.KeySet(), mapAccountIdToOldAffiliations.Values());
        RecordAccessUtility.resetPreferenceSharingUnderContacts(mapAccountIdToOldAffiliations);
        //Salutation
        RecordAccessUtility.resetSalutationSharing(mapAccountIdToOldAffiliations.KeySet(), mapAccountIdToOldAffiliations.Values());
        RecordAccessUtility.resetSalutationSharingUnderContacts(mapAccountIdToOldAffiliations);
        //Relationship
        RecordAccessUtility.resetRelationshipSharing(mapAccountIdToOldAffiliations.KeySet(), mapAccountIdToOldAffiliations.Values());
        RecordAccessUtility.resetRelationshipSharingUnderContacts(mapAccountIdToOldAffiliations);
        RecordAccessUtility.resetRelationshipSharingUnderOpportunity(mapAccountIdToOldAffiliations);
        
        //Planned Giving
        RecordAccessUtility.resetPlannedGivingSharing(mapAccountIdToOldAffiliations.KeySet(), mapAccountIdToOldAffiliations.Values());
        // Action Plan
        RecordAccessUtility.resetActionPlanSharing(mapAccountIdToOldAffiliations.KeySet(), mapAccountIdToOldAffiliations.Values());
        RecordAccessUtility.resetActionPlanSharingUnderContact(mapAccountIdToOldAffiliations);
        RecordAccessUtility.resetActionPlanSharingUnderOpportunity(mapAccountIdToOldAffiliations);

        //Prospect Research
        RecordAccessUtility.resetProspectResearch(mapAccountIdToOldAffiliations);
        RecordAccessUtility.resetProspectResearchSharingUnderContact(mapAccountIdToOldAffiliations);

        //Confidential Data
        RecordAccessUtility.resetConfidential(mapAccountIdToOldAffiliations);
        RecordAccessUtility.resetConfidentialUnderContacts(mapAccountIdToOldAffiliations);
        RecordAccessUtility.resetConfidentialUnderOpportunities(mapAccountIdToOldAffiliations);
    }


    /*
    *
    *Method: resetActionPlanSharingUnderContact
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which deletes all the Edit Sharing records Related to Opportunities Accounts and recreates as per the respective Affiliation__c
    *
    */


    public static void resetActionPlanSharingUnderContact(Map<Id,String> AccountIdToOldAffiliations){
        // Method Variables
        map<Id,contact> mapContacts = new map<Id,contact>();
        map<Id,String> mapActionPlanIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapActionPlanIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        //collecting the contacts
        for(Contact con: [SELECT id, accountId, account.Affiliation__c, account.Restricted_Account__c FROM Contact WHERE accountId =: AccountIdToOldAffiliations.keyset()]){
            mapContacts.put(con.Id,con);
        }

        // Collecting All ActionPlan account Share records having edit access
        for(rC_Bios__Action_Plan__c aP: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Contact__r.account.Affiliation__c, rC_Bios__Contact__c FROM rC_Bios__Action_Plan__c WHERE rC_Bios__WhatId__c =:mapContacts.KeySet() ]){
            if(aP.rC_Bios__WhatId__c != null && string.ValueOf(aP.rC_Bios__WhatId__c).startsWith('003')){
                mapActionPlanIdToOldAffiliation.put(aP.Id,AccountIdToOldAffiliations.get(mapContacts.get(aP.rC_Bios__WhatId__c).accountId));
                mapActionPlanIdToNewAffiliation.put(aP.Id,mapContacts.get(aP.rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(aP.Id,mapContacts.get(aP.rC_Bios__WhatId__c).account.Restricted_Account__c);

            }
        }


        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToNewAffiliation.values() OR Name =:mapActionPlanIdToOldAffiliation.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deleteActionPlanSharingRecords (mapActionPlanIdToOldAffiliation.KeySet(), mapActionPlanIdToOldAffiliation.Values(), mapGroupNameToId, mapActionPlanIdToRestricted);
        // Insert the new Affiliations records.
        InsertActionPlanSharingRecords (mapActionPlanIdToNewAffiliation, mapGroupNameToId, mapActionPlanIdToRestricted);

    }

     /*
    *
    *Method: resetProspectResearchSharingUnderContact
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which deletes all the Edit Sharing records Related to Opportunities Accounts and recreates as per the respective Affiliation__c
    *
    */
     public static void resetProspectResearchSharingUnderContact(Map<Id,String> AccountIdToOldAffiliations){
        map<Id,String> mapProspectResearchToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean> ();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        for(Prospect_Research__c pr: [SELECT Id, Name, Contact__c, Contact__r.accountId, Contact__r.account.Affiliation__c, Contact__r.account.Restricted_Account__c FROM Prospect_Research__c Where Contact__r.accountId =: AccountIdToOldAffiliations.keyset()]){
            if(pr.Contact__c != null && pr.Contact__r.accountId != null){
                mapProspectResearchToNewAffiliation.put(pr.Id, pr.Contact__r.account.Affiliation__c);
                mapProspectIdToRestricted.put(pr.Id, pr.Contact__r.account.Restricted_Account__c);
            }
        }

         // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapProspectResearchToNewAffiliation.values() OR Name =:AccountIdToOldAffiliations.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        ProsResearchTriggerHandler.deleteProspectSharingRecords (mapProspectResearchToNewAffiliation.KeySet(), AccountIdToOldAffiliations.Values(), mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ProsResearchTriggerHandler.InsertProspectShareRecords (mapProspectResearchToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
     }

    /*
    *
    *Method: resetProspectResearch
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */
    public static void resetProspectResearch(Map<Id,String> AccountIdToOldAffiliations){
        map<Id,String> mapProspectResearchIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapProspectResearchToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean> ();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        for(Prospect_Research__c pr: [SELECT Id, Name,  Account__c, Account__r.Affiliation__c, Account__r.Restricted_Account__c FROM Prospect_Research__c Where Account__c =: AccountIdToOldAffiliations.keyset()]){
            if(pr.Account__c != null && pr.Account__r.Affiliation__c != null){
                mapProspectResearchIdToOldAffiliation.put(pr.Id, AccountIdToOldAffiliations.get(pr.Account__c));
                mapProspectResearchToNewAffiliation.put(pr.Id, pr.Account__r.Affiliation__c);
                mapProspectIdToRestricted.put(pr.Id, pr.Account__r.Restricted_Account__c);
            }
        }

        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapProspectResearchToNewAffiliation.values() OR Name =:mapProspectResearchIdToOldAffiliation.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        ProsResearchTriggerHandler.deleteProspectSharingRecords (mapProspectResearchIdToOldAffiliation.KeySet(), mapProspectResearchIdToOldAffiliation.Values(), mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ProsResearchTriggerHandler.InsertProspectShareRecords (mapProspectResearchToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
    }

    /*
    *
    *Method: resetConfidential
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */
    public static void resetConfidential(Map<Id,String> AccountIdToOldAffiliations){
        map<Id,String> mapConfidentialIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapConfidentialIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        for(Confidential_Data__c cnf: [SELECT Id, Name, Account__c, Account__r.Affiliation__c, Account__r.Restricted_Account__c FROM Confidential_Data__c where Account__c =: AccountIdToOldAffiliations.KeySet()]){
            mapConfidentialIdToNewAffiliation.put(cnf.Id, cnf.Account__r.Affiliation__c);
            mapProspectIdToRestricted.put(cnf.Id, cnf.Account__r.Restricted_Account__c);
        }

        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapConfidentialIdToNewAffiliation.values() OR Name =:AccountIdToOldAffiliations.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

         //Delete the Old affiliations records.
        ConfDataTriggerHandler.deleteConfidentialSharingRecords (mapConfidentialIdToNewAffiliation.KeySet(), AccountIdToOldAffiliations.Values(), mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ConfDataTriggerHandler.InsertConfidentialShareRecords (mapConfidentialIdToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);

    }

    /*
    *
    *Method: resetConfidentialUnderContacts
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */
    public static void resetConfidentialUnderContacts(Map<Id,String> AccountIdToOldAffiliations){
        map<Id,String> mapConfidentialIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapConfidentialIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        for(Confidential_Data__c cnf: [SELECT Id, Name, Contact__c, Contact__r.Account.Affiliation__c, Contact__r.Account.Restricted_Account__c FROM Confidential_Data__c where Contact__r.AccountId =: AccountIdToOldAffiliations.KeySet()]){
            mapConfidentialIdToNewAffiliation.put(cnf.Id, cnf.Contact__r.Account.Affiliation__c);
            mapProspectIdToRestricted.put(cnf.Id, cnf.Contact__r.Account.Restricted_Account__c);
        }

        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapConfidentialIdToNewAffiliation.values() OR Name =:AccountIdToOldAffiliations.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        ConfDataTriggerHandler.deleteConfidentialSharingRecords (mapConfidentialIdToNewAffiliation.KeySet(), AccountIdToOldAffiliations.Values(), mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ConfDataTriggerHandler.InsertConfidentialShareRecords (mapConfidentialIdToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
    }

    /*
    *
    *Method: resetConfidentialUnderOpportunities
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */

    public static void resetConfidentialUnderOpportunities(Map<Id,String> AccountIdToOldAffiliations){
        map<Id,String> mapConfidentialIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapConfidentialIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        for(Confidential_Data__c cnf: [SELECT Id, Name, Opportunity__c, Opportunity__r.Account.Affiliation__c, Opportunity__r.Account.Restricted_Account__c FROM Confidential_Data__c where Opportunity__r.AccountId =: AccountIdToOldAffiliations.KeySet()]){
            mapConfidentialIdToNewAffiliation.put(cnf.Id, cnf.Opportunity__r.Account.Affiliation__c);
            mapProspectIdToRestricted.put(cnf.Id, cnf.Opportunity__r.Account.Restricted_Account__c);
        }

        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapConfidentialIdToNewAffiliation.values() OR Name =:AccountIdToOldAffiliations.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        ConfDataTriggerHandler.deleteConfidentialSharingRecords (mapConfidentialIdToNewAffiliation.KeySet(), AccountIdToOldAffiliations.Values(), mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ConfDataTriggerHandler.InsertConfidentialShareRecords (mapConfidentialIdToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
    }


    /*
    *
    *Method: resetActionPlanSharingUnderOpportunity
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */


    public static void resetActionPlanSharingUnderOpportunity(Map<Id,String> AccountIdToOldAffiliations){
        // Method Variables
        map<Id,Opportunity> mapOpportunity = new map<Id,Opportunity>();
        map<Id,String> mapActionPlanIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapActionPlanIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

        for(Opportunity opp: [SELECT id, accountId, account.Affiliation__c, account.Restricted_Account__c FROM Opportunity where accountId=: AccountIdToOldAffiliations.Keyset()]){
            mapOpportunity.put(opp.Id,opp);
        }
        // Collecting All ActionPlan account Share records having edit access
        for(rC_Bios__Action_Plan__c mapAcp: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Opportunity__c FROM rC_Bios__Action_Plan__c WHERE rC_Bios__WhatId__c =:mapOpportunity.keyset() ]){
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('006')){
                mapActionPlanIdToOldAffiliation.put(mapAcp.Id,AccountIdToOldAffiliations.get(mapOpportunity.get(mapAcp.rC_Bios__WhatId__c).accountId));
                mapActionPlanIdToNewAffiliation.put(mapAcp.Id,mapOpportunity.get(mapAcp.rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(mapAcp.Id,mapOpportunity.get(mapAcp.rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }

        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToNewAffiliation.values() OR Name =:mapActionPlanIdToOldAffiliation.values() OR Name =: ALLACLU]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deleteActionPlanSharingRecords (mapActionPlanIdToOldAffiliation.KeySet(), mapActionPlanIdToOldAffiliation.Values(), mapGroupNameToId, mapActionPlanIdToRestricted);
        // Insert the new Affiliations records.
        InsertActionPlanSharingRecords (mapActionPlanIdToNewAffiliation, mapGroupNameToId, mapActionPlanIdToRestricted);

    }





    /*
    *
    *Method: resetRelationshipSharingUnderOpportunity
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */


    public static void resetRelationshipSharingUnderOpportunity(Map<Id,String> AccountIdToOldAffiliations){
        // Method Variables
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new Map<Id,rC_Bios__Relationship__c>();
        map<Id,Boolean> mapRelationshipIdToRestricted = new map<Id,Boolean> ();

        // Collect the RelationshipIdToRelationship and collect the affiliations
        for(rC_Bios__Relationship__c mapRe: [SELECT Id, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact_1__r.Account.Restricted_Account__c, rC_Bios__Contact_2__r.Account.Restricted_Account__c, rC_Bios__Account_1__r.Restricted_Account__c, rC_Bios__Account_2__r.Restricted_Account__c,
                                                rC_Bios__Opportunity__c, rC_Bios__Account_1__c, rC_Bios__Account_2__c, rC_Bios__Account_1__r.Affiliation__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Contact_2__r.accountId, rC_Bios__Contact_2__r.account.Affiliation__c, rC_Bios__Contact_1__r.accountId, rC_Bios__Contact_1__r.account.Affiliation__c, rC_Bios__Account_2__r.Affiliation__c FROM rC_Bios__Relationship__c WHERE rC_Bios__Opportunity__r.accountId =:AccountIdToOldAffiliations.keyset() ]){
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

        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name =:AccountIdToOldAffiliations.values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deleteRelationshipSharingRecords (mapRelationshipIdToRelationship, AccountIdToOldAffiliations.Values(), mapGroupNameToId, mapRelationshipIdToRestricted);
        // Insert the new Affiliations records.
        InsertRelationshipSharingRecords (mapRelationshipIdToRelationship, mapGroupNameToId, mapRelationshipIdToRestricted);

    }



    /*
    *
    *Method: resetRelationshipSharingUnderContacts
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */


    public static void resetRelationshipSharingUnderContacts(Map<Id,String> AccountIdToOldAffiliations){
        // Method Variables
        List<String> groupNames = new List<String>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new Map<Id,rC_Bios__Relationship__c>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapRelationshipIdToRestricted = new map<Id,Boolean> ();

        // Collect the Relationship  along with contacts account OldAffiliation  & New Affiliation
        // Collect the RelationshipIdToRelationship and collect the affiliations
        for(rC_Bios__Relationship__c mapRe: [SELECT Id, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact_1__r.Account.Restricted_Account__c, rC_Bios__Contact_2__r.Account.Restricted_Account__c, rC_Bios__Account_1__r.Restricted_Account__c, rC_Bios__Account_2__r.Restricted_Account__c,
                                                rC_Bios__Opportunity__c, rC_Bios__Account_1__c, rC_Bios__Account_2__c, rC_Bios__Account_1__r.Affiliation__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Contact_2__r.accountId, rC_Bios__Contact_2__r.account.Affiliation__c, rC_Bios__Contact_1__r.accountId, rC_Bios__Contact_1__r.account.Affiliation__c, rC_Bios__Account_2__r.Affiliation__c FROM rC_Bios__Relationship__c WHERE rC_Bios__Contact_1__r.accountId =: AccountIdToOldAffiliations.keySet() OR rC_Bios__Contact_2__r.accountId =: AccountIdToOldAffiliations.keySet()]){
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
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: AccountIdToOldAffiliations.Values() OR Name =:groupNames OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        // Delete the Old affiliations records.
        deleteRelationshipSharingRecords (mapRelationshipIdToRelationship, AccountIdToOldAffiliations.Values(), mapGroupNameToId, mapRelationshipIdToRestricted);
        // Insert the new Affiliations records.
        InsertRelationshipSharingRecords (mapRelationshipIdToRelationship, mapGroupNameToId, mapRelationshipIdToRestricted);

    }


    /*
    *
    *Method: resetPreferenceSharingUnderContacts
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates sharing as per the respective Affiliation__c
    *
    */


    public static void resetPreferenceSharingUnderContacts(Map<Id,String> AccountIdToOldAffiliations){
        // Method Variables
        map<Id,String> mapPreferenceIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapPreferenceIdToNewAffiliation = new map<Id,String> ();
        map<String,Id> mapGroupNameToId = new map<String,Id>();
        map<Id,Boolean> mapPreferenceIdToRestricted = new map<Id,Boolean> ();

        // Collect the Preferences  along with contacts account OldAffiliation  & New Affiliation
        for(rC_Bios__Preference__c pre:[SELECT Id, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Contact__r.accountId, rC_Bios__Contact__r.account.Affiliation__c FROM rC_Bios__Preference__c WHERE rC_Bios__Contact__r.accountId =: AccountIdToOldAffiliations.keySet()]){
            mapPreferenceIdToOldAffiliation.put(pre.Id,AccountIdToOldAffiliations.get(pre.rC_Bios__Contact__r.accountId));
            mapPreferenceIdToNewAffiliation.put(pre.Id,pre.rC_Bios__Contact__r.account.Affiliation__c);
            mapPreferenceIdToRestricted.put(pre.Id,pre.rC_Bios__Contact__r.account.Restricted_Account__c);
        }
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPreferenceIdToOldAffiliation.Values() OR Name =:mapPreferenceIdToNewAffiliation.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deletePreferenceSharingRecords (mapPreferenceIdToOldAffiliation.KeySet(), mapPreferenceIdToOldAffiliation.values(), mapGroupNameToId, mapPreferenceIdToRestricted);
        // Insert the new Affiliations records.
        InsertPreferenceSharingRecords (mapPreferenceIdToNewAffiliation, mapGroupNameToId, mapPreferenceIdToRestricted);
    }

     /*
    *
    *Method: resetSalutationSharingUnderContacts
    *@param : Map<Id,String> AccountId To Affiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */
    public static void resetSalutationSharingUnderContacts(Map<Id,String> AccountIdToOldAffiliations){
        // Method Variables
        map<Id,String> mapSalutationIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapSalutationIdToNewAffiliation = new map<Id,String> ();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapSalutationIdToRestricted = new map<Id,Boolean> ();
        // Collect the Salutation  along with contacts account OldAffiliation  & New Affiliation
        for(rC_Bios__Salutation__c sal:[SELECT Id, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Contact__r.accountId, rC_Bios__Contact__r.account.Affiliation__c FROM rC_Bios__Salutation__c WHERE rC_Bios__Contact__r.accountId =: AccountIdToOldAffiliations.keySet()]){
            mapSalutationIdToOldAffiliation.put(sal.Id,AccountIdToOldAffiliations.get(sal.rC_Bios__Contact__r.accountId));
            mapSalutationIdToNewAffiliation.put(sal.Id,sal.rC_Bios__Contact__r.account.Affiliation__c);
            mapSalutationIdToRestricted.put(sal.Id,sal.rC_Bios__Contact__r.account.Restricted_Account__c);
        }

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapSalutationIdToOldAffiliation.Values() OR Name =:mapSalutationIdToNewAffiliation.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deleteSalutationSharingRecords (mapSalutationIdToOldAffiliation.KeySet(), mapSalutationIdToOldAffiliation.Values(), mapGroupNameToId, mapSalutationIdToRestricted);
        // Insert the new Affiliations records.
        InsertSalutationSharingRecords (mapSalutationIdToNewAffiliation, mapGroupNameToId, mapSalutationIdToRestricted);

    }

    /*
    *
    *Method: deletePreferenceSharingRecords
    *@param : setId (Preference Id)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to Preference Object
    *
    */
    public static void deletePreferenceSharingRecords(Set<Id> preferenceIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, map<Id,Boolean> mapPreferenceIdToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> preferencePrivateIds = new Set<Id>();
        List<rC_Bios__Preference__share> PreferenceSharesToBeDelete = new List<rC_Bios__Preference__share> ();
        //Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        // Collect Preference Share records having edit access
        for(rC_Bios__Preference__share PreShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Preference__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:preferenceIds]){
            PreferenceSharesToBeDelete.add(PreShare);
        }
        for(Id objId: preferenceIds){
            if(mapPreferenceIdToRestricted.get(objId) == true){
                preferencePrivateIds.add(objId);
            }
        }
        if(!preferencePrivateIds.IsEmpty()){
            for(rC_Bios__Preference__share PreShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Preference__share where (UserOrGroupId =: mapGroupNameToId.get(ALLACLU) OR UserOrGroupId =: mapGroupNameToId.get(NATIONAL)) AND ParentId =:preferencePrivateIds]){
                PreferenceSharesToBeDelete.add(PreShare);
            }
        }

        // Delete the Preference Share records.
        if(!PreferenceSharesToBeDelete.isEmpty()){
            try{
                delete PreferenceSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','','deletePreferenceSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: InsertPreferenceSharingRecords
    *@param : Map<Id,String> (Preference Id to AffiliateName)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Preference Object
    *
    */
    public static void InsertPreferenceSharingRecords(Map<Id,String> mapPreferenceIdToAffiliate, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapPreferenceIdToRestricted){
        List<rC_Bios__Preference__share> PreferenceSharesToBeInsert = new List<rC_Bios__Preference__share>();
        //Create the Preference Share Records to all of Objects
        for(Id objId: mapPreferenceIdToAffiliate.keyset()){

            if(mapPreferenceIdToAffiliate.get(ObjId) != null && !mapPreferenceIdToRestricted.get(objId) && mapGroupNameToId.get(mapPreferenceIdToAffiliate.get(ObjId)) != null){
                rC_Bios__Preference__share PreShare = new rC_Bios__Preference__share();
                PreShare.ParentId = ObjId;
                PreShare.AccessLevel = 'Edit';
                PreShare.UserOrGroupId = mapGroupNameToId.get(mapPreferenceIdToAffiliate.get(ObjId));
                PreferenceSharesToBeInsert.add(PreShare);
            }

            if(mapPreferenceIdToRestricted.get(objId) == false && mapGroupNameToId.get(ALLACLU) != null && mapGroupNameToId.get(NATIONAL) != null){
                rC_Bios__Preference__share PreShare = new rC_Bios__Preference__share();
                PreShare.ParentId = ObjId;
                PreShare.AccessLevel = 'Read';
                PreShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                PreferenceSharesToBeInsert.add(PreShare);
            }

            if(mapPreferenceIdToRestricted.get(objId) == false && mapGroupNameToId.get(NATIONAL) != null){
                rC_Bios__Preference__share PreShare = new rC_Bios__Preference__share();
                PreShare.ParentId = ObjId;
                PreShare.AccessLevel = 'Edit';
                PreShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                PreferenceSharesToBeInsert.add(PreShare);
            }
        }

        // Insert the Preferenceshare Objects
        if(!PreferenceSharesToBeInsert.IsEmpty()) {
            try{
                insert PreferenceSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','','InsertPreferenceSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: resetPreferenceSharing
    *@param : setId (AccountId)
    *@param : List<String> (OldAffiliations)
    *@description : Method which recalculates the sharing as per the respective Account Affiliation__c
    *
    */


    public static void resetPreferenceSharing(Set<Id> AccountIds, List<String> OldAffiliations){
        // Method Variables
        Map<Id,String> mapPreferenceIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPreferenceIdToRestricted = new map<Id,Boolean> ();

        // Collecting All Preferences account Share records having edit access
        for(rC_Bios__Preference__c Pre: [SELECT Id, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Account__c, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Preference__c WHERE rC_Bios__Account__c =:AccountIds]){
            mapPreferenceIdToAffiliate.put(Pre.Id,Pre.rC_Bios__Account__r.Affiliation__c);
            mapPreferenceIdToRestricted.put(Pre.Id,Pre.rC_Bios__Account__r.Restricted_Account__c);
        }

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPreferenceIdToAffiliate.Values() OR Name =:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        //Delete the Old affiliations records.
        deletePreferenceSharingRecords (mapPreferenceIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapPreferenceIdToRestricted);
        // Insert the new Affiliations records.
        InsertPreferenceSharingRecords (mapPreferenceIdToAffiliate, mapGroupNameToId, mapPreferenceIdToRestricted);
    }

    /*
    *
    *Method: deleteSalutationSharingRecords
    *@param : setId (salutation Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void deleteSalutationSharingRecords(Set<Id> salutationIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, map<Id,Boolean> mapSalutationIdToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> salutationPrivateIds = new Set<Id>();
        List<rC_Bios__Salutation__share> SalutationSharesToBeDelete = new List<rC_Bios__Salutation__share> ();

        //Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        // Collect Salutation Share records having edit access
        for(rC_Bios__Salutation__share SalShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Salutation__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:salutationIds]){
            SalutationSharesToBeDelete.add(SalShare);
        }

        for(Id ObjId: salutationIds){
            if(mapSalutationIdToRestricted.get(objId) == true){
                salutationPrivateIds.add(objId);
            }
        }

        if(!salutationPrivateIds.IsEmpty()){
            for(rC_Bios__Salutation__share SalShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Salutation__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:salutationPrivateIds]){
                SalutationSharesToBeDelete.add(SalShare);
            }
        }
        // Delete the Salutation Share records.
        if(!SalutationSharesToBeDelete.isEmpty()){
            try{
                delete SalutationSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','','deleteSalutationSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: InsertSalutationSharingRecords
    *@param : Map<Id,String> (Salutation Id to AffiliateName)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void InsertSalutationSharingRecords(Map<Id,String> mapSalutationIdToAffiliate, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapSalutationIdToRestricted){
        List<rC_Bios__Salutation__share> SalutationSharesToBeInsert = new List<rC_Bios__Salutation__share>();

        //Create the Salutation Share Records to all of Objects
        for(Id objId: mapSalutationIdToAffiliate.keyset()){

            if(mapSalutationIdToAffiliate.get(ObjId) != null && !mapSalutationIdToRestricted.get(ObjId) && mapGroupNameToId.get(mapSalutationIdToAffiliate.get(ObjId)) != null){
                rC_Bios__Salutation__share SalShare = new rC_Bios__Salutation__share();
                SalShare.ParentId = ObjId;
                SalShare.AccessLevel = 'Edit';
                SalShare.UserOrGroupId = mapGroupNameToId.get(mapSalutationIdToAffiliate.get(ObjId));
                SalutationSharesToBeInsert.add(SalShare);
            }

            if(mapSalutationIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(ALLACLU) != null ){
                rC_Bios__Salutation__share SalShare = new rC_Bios__Salutation__share();
                SalShare.ParentId = ObjId;
                SalShare.AccessLevel = 'Read';
                SalShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                SalutationSharesToBeInsert.add(SalShare);
            }

            if(mapSalutationIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(NATIONAL) != null ){
                rC_Bios__Salutation__share SalShare = new rC_Bios__Salutation__share();
                SalShare.ParentId = ObjId;
                SalShare.AccessLevel = 'Edit';
                SalShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                SalutationSharesToBeInsert.add(SalShare);
            }
        }

         // Insert the Salutation share Objects
        if(!SalutationSharesToBeInsert.IsEmpty()) {
            try {
                insert SalutationSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','','InsertSalutationSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    /*
    *
    *Method: resetSalutationSharing
    *@param : setId (AccountId)
    *@param : List<String> (OldAffiliations)
    *@description : Method which  recalculates as per the respective Account Affiliation__c
    *
    */


    public static void resetSalutationSharing(Set<Id> AccountIds, List<String> OldAffiliations){
        // Method Variables
        Map<Id,String> mapSalutationIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapSalutationIdToRestricted = new map<Id,Boolean> ();

        // Collecting All Salutation account Share records having edit access
        for(rC_Bios__Salutation__c Sal: [SELECT Id, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Account__c, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Salutation__c WHERE rC_Bios__Account__c =:AccountIds]){
            mapSalutationIdToAffiliate.put(Sal.Id,Sal.rC_Bios__Account__r.Affiliation__c);
            mapSalutationIdToRestricted.put(Sal.Id,Sal.rC_Bios__Account__r.Restricted_Account__c);
        }

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapSalutationIdToAffiliate.Values() OR Name =:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        //Delete the Old affiliations records.
        deleteSalutationSharingRecords (mapSalutationIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapSalutationIdToRestricted);
        // Insert the new Affiliations records.
        InsertSalutationSharingRecords (mapSalutationIdToAffiliate, mapGroupNameToId, mapSalutationIdToRestricted);



    }

    /*
    *
    *Method: deleteActionPlanSharingRecords
    *@param : setId (salutation Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to ActionPlan Object.
    *
    */
    public static void deleteActionPlanSharingRecords(Set<Id> actionPlanIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, map<Id,Boolean> mapActionPlanIdToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> privateActionPlanIds = new Set<Id>();
        //List<rC_Bios__Action_Plan__share> ActionPlanSharesToBeDelete = new List<rC_Bios__Action_Plan__share> ();

        //Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        // Collect ActionPlan Share records having edit access
        /*for(rC_Bios__Action_Plan__share AcPShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Action_Plan__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:actionPlanIds]){
            ActionPlanSharesToBeDelete.add(AcPShare);
        }*/
        // Delete the Read Access if the Account marked as Private
        for(Id objId: actionPlanIds){
            if(mapActionPlanIdToRestricted.get(objId) == true){
                privateActionPlanIds.add(objId);
            }
        }
        /*if(!privateActionPlanIds.IsEmpty()){
            for(rC_Bios__Action_Plan__share AcPShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Action_Plan__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:privateActionPlanIds]){
                ActionPlanSharesToBeDelete.add(AcPShare);
            }
        }
        // Delete the ActionPlan Share records.
        if(!ActionPlanSharesToBeDelete.isEmpty()){
            try{
                delete ActionPlanSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','deleteActionPlanSharingRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }*/
    }

    /*
    *
    *Method: InsertActionPlanSharingRecords
    *@param : Map<Id,String> (Salutation Id to AffiliateName)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void InsertActionPlanSharingRecords(Map<Id,String> mapActionPlanIdToAffiliate, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapActionPlanIdToRestricted){

        //List<rC_Bios__Action_Plan__share> ActionPlanSharesToBeInsert = new List<rC_Bios__Action_Plan__share>();

        //Create the ActionPlan Share Records to all of Objects
        /*for(Id objId: mapActionPlanIdToAffiliate.keyset()){

            if(mapActionPlanIdToAffiliate.get(ObjId) != null && !mapActionPlanIdToRestricted.get(objId) && mapGroupNameToId.get(mapActionPlanIdToAffiliate.get(ObjId)) != null){
                rC_Bios__Action_Plan__share AcPShare = new rC_Bios__Action_Plan__share();
                AcPShare.ParentId = ObjId;
                AcPShare.AccessLevel = 'Edit';
                AcPShare.UserOrGroupId = mapGroupNameToId.get(mapActionPlanIdToAffiliate.get(ObjId));
                ActionPlanSharesToBeInsert.add(AcPShare);
            }

            if(mapActionPlanIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(ALLACLU) != null){
                rC_Bios__Action_Plan__share AcPShare = new rC_Bios__Action_Plan__share();
                AcPShare.ParentId = ObjId;
                AcPShare.AccessLevel = 'Read';
                AcPShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                ActionPlanSharesToBeInsert.add(AcPShare);
            }

            if(mapActionPlanIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(NATIONAL) != null){
                rC_Bios__Action_Plan__share AcPShare = new rC_Bios__Action_Plan__share();
                AcPShare.ParentId = ObjId;
                AcPShare.AccessLevel = 'Edit';
                AcPShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                ActionPlanSharesToBeInsert.add(AcPShare);
            }
        }
        // Insert the ActionPlan share Objects
        if(!ActionPlanSharesToBeInsert.IsEmpty()){
            try{
                insert ActionPlanSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','InsertActionPlanSharingRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }*/
    }

     /*
    *
    *Method: resetActionPlanSharing
    *@param : setId (AccountId)
    *@param : List<String> (OldAffiliations)
    *@description : Method which  recalculates as per the respective Account Affiliation__c
    *
    */



    public static void resetActionPlanSharing(Set<Id> AccountIds, List<String> OldAffiliations){
        // Method Variables
        Set<Id> groupIds = new Set<Id>();
        Map<Id,String> mapActionPlanIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id, Account> mapAccounts = new map<Id,Account> ();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        // collecting Accountrecords
        for(Account acc: [SELECT id, Affiliation__c, Restricted_Account__c FROM Account where id=: AccountIds]){
            mapAccounts.put(acc.Id,acc);
        }
        // Collecting All ActionPlan account Share records having edit access
        for(rC_Bios__Action_Plan__c mapAcp: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Account__r.Restricted_Account__c, rC_Bios__Account__c, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Action_Plan__c WHERE rC_Bios__WhatId__c =:AccountIds]){
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('001')){
                mapActionPlanIdToAffiliate.put(mapAcp.Id,mapAccounts.get(mapAcp.rC_Bios__WhatId__c).Affiliation__c);
                mapActionPlanIdToRestricted.put(mapAcp.Id,mapAccounts.get(mapAcp.rC_Bios__WhatId__c).Restricted_Account__c);
            }
        }

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToAffiliate.Values() OR Name=:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deleteActionPlanSharingRecords (mapActionPlanIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapActionPlanIdToRestricted);
        // Insert the new Affiliations records.
        InsertActionPlanSharingRecords (mapActionPlanIdToAffiliate, mapGroupNameToId, mapActionPlanIdToRestricted);

    }

    /*
    *
    *Method: deletePaymentMethodSharingRecords
    *@param : setId (salutation Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void deletePaymentMethodSharingRecords(Set<Id> paymentMethodIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId,  map<Id,Boolean> mapPaymentMethodIdToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> paymentMethodPrivateIds = new Set<Id>();
        List<rC_Giving__Payment_Method__share> PaymentMethodSharesToBeDelete = new List<rC_Giving__Payment_Method__share> ();

        //Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        // Collect PaymentMethod Share records having edit access
        for(rC_Giving__Payment_Method__share PmShare: [SELECT Id, AccessLevel, ParentId FROM rC_Giving__Payment_Method__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:paymentMethodIds]){
            PaymentMethodSharesToBeDelete.add(PmShare);
        }
        for(Id objId: paymentMethodIds){
            if(mapPaymentMethodIdToRestricted.get(objId) == true){
                paymentMethodPrivateIds.add(objId);
            }
        }

        if(!paymentMethodPrivateIds.IsEmpty()){
            for(rC_Giving__Payment_Method__share PmShare: [SELECT Id, AccessLevel, ParentId FROM rC_Giving__Payment_Method__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:paymentMethodPrivateIds]){
                PaymentMethodSharesToBeDelete.add(PmShare);
            }
        }

        // Delete the PaymentMethod Share records.
        if(!PaymentMethodSharesToBeDelete.isEmpty()){
            try{
                delete PaymentMethodSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                           'deletePaymentMethodSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: InsertPaymentMethodSharingRecords
    *@param : Map<Id,String> (Salutation Id to AffiliateName)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void InsertPaymentMethodSharingRecords(Map<Id,String> mapPaymentMethodIdToAffiliate, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapPaymentMethodIdToRestricted){

        List<rC_Giving__Payment_Method__share> PaymentMethodSharesToBeInsert = new List<rC_Giving__Payment_Method__share>();

        //Create the PaymentMethod Share Records to all of Objects
        for(Id objId: mapPaymentMethodIdToAffiliate.keyset()){

            if(mapPaymentMethodIdToAffiliate.get(ObjId) != null && !mapPaymentMethodIdToRestricted.get(objId) &&  mapGroupNameToId.get(mapPaymentMethodIdToAffiliate.get(ObjId)) != null){
                rC_Giving__Payment_Method__share PmShare = new rC_Giving__Payment_Method__share();
                PmShare.ParentId = ObjId;
                PmShare.AccessLevel = 'Edit';
                PmShare.UserOrGroupId = mapGroupNameToId.get(mapPaymentMethodIdToAffiliate.get(ObjId));
                PaymentMethodSharesToBeInsert.add(PmShare);
            }

            if(mapPaymentMethodIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(ALLACLU) != null){
                rC_Giving__Payment_Method__share PmShare = new rC_Giving__Payment_Method__share();
                PmShare.ParentId = ObjId;
                PmShare.AccessLevel = 'Read';
                PmShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                PaymentMethodSharesToBeInsert.add(PmShare);
            }

            if(mapPaymentMethodIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(NATIONAL) != null){
                rC_Giving__Payment_Method__share PmShare = new rC_Giving__Payment_Method__share();
                PmShare.ParentId = ObjId;
                PmShare.AccessLevel = 'Edit';
                PmShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                PaymentMethodSharesToBeInsert.add(PmShare);
            }
        }

        // Insert the PaymentMethod share Objects
        if(!PaymentMethodSharesToBeInsert.IsEmpty()) {
            try{
                insert PaymentMethodSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                           'InsertPaymentMethodSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: resetPaymentMethodSharing
    *@param : setId (AccountId)
    *@param : List<String> (OldAffiliations)
    *@description : Method which recalculates as per the respective Account Affiliation__c
    *
    */


    public static void resetPaymentMethodSharing(Set<Id> AccountIds, List<String> OldAffiliations){
        // Method Variables
        Map<Id,String> mapPaymentMethodIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPaymentMethodIdToRestricted = new map<Id,Boolean> ();


        // Collecting All PaymentMethod account Share records having edit access
        for(rC_Giving__Payment_Method__c Pm: [SELECT Id, rC_Giving__Account__r.Restricted_Account__c, rC_Giving__Account__c, rC_Giving__Account__r.Affiliation__c FROM rC_Giving__Payment_Method__c WHERE rC_Giving__Account__c =:AccountIds]){
            mapPaymentMethodIdToAffiliate.put(Pm.Id,Pm.rC_Giving__Account__r.Affiliation__c);
            mapPaymentMethodIdToRestricted.put(Pm.Id,Pm.rC_Giving__Account__r.Restricted_Account__c);
        }

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPaymentMethodIdToAffiliate.Values() OR Name=:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deletePaymentMethodSharingRecords (mapPaymentMethodIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapPaymentMethodIdToRestricted);
        // Insert the new Affiliations records.
        InsertPaymentMethodSharingRecords (mapPaymentMethodIdToAffiliate, mapGroupNameToId, mapPaymentMethodIdToRestricted);



    }

    /*
    *
    *Method: deleteRelationshipSharingRecords
    *@param : setId (salutation Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void deleteRelationshipSharingRecords(Map<Id, rC_Bios__Relationship__c> mapRelationshipIdToRelationship, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, map<Id,Boolean> mapRelationshipIdToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> relationshipPrivateIds = new Set<Id>();
        List<rC_Bios__Relationship__share> relationshipSharesToBeDelete = new List<rC_Bios__Relationship__share> ();

        //Collect the groupIds based which are related to OldAffiliations
        for(rC_Bios__Relationship__c rel: mapRelationshipIdToRelationship.Values()){
            if(mapRelationshipIdToRestricted.get(rel.Id) == true){
                // Deleting all the Existing Affiliations groups.
                if(rel.rC_Bios__Account_1__c != null && rel.rC_Bios__Account_1__r.Affiliation__c != null)
                    OldAffiliations.add(rel.rC_Bios__Account_1__r.Affiliation__c);
                if(rel.rC_Bios__Account_2__c != null && rel.rC_Bios__Account_2__r.Affiliation__c != null)
                    OldAffiliations.add(rel.rC_Bios__Account_2__r.Affiliation__c);
                if(rel.rC_Bios__Contact_1__c != null && rel.rC_Bios__Contact_1__r.account.Affiliation__c != null)
                    OldAffiliations.add(rel.rC_Bios__Contact_1__r.account.Affiliation__c);
                if(rel.rC_Bios__Contact_2__c != null && rel.rC_Bios__Contact_2__r.account.Affiliation__c != null)
                    OldAffiliations.add(rel.rC_Bios__Contact_2__r.account.Affiliation__c);
                if(rel.rC_Bios__Opportunity__c != null && rel.rC_Bios__Opportunity__r.account.Affiliation__c != null)
                    OldAffiliations.add(rel.rC_Bios__Opportunity__r.account.Affiliation__c);
            }
        }
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: OldAffiliations]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        // Collect Relationship Share records having edit access
        for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, userORgroupId, ParentId FROM rC_Bios__Relationship__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:mapRelationshipIdToRelationship.KeySet()]){
            relationshipSharesToBeDelete.add(RSShare);
        }

        // Delete ALL ACLU if the Relationship is Private.
        for(rC_Bios__Relationship__c rs: mapRelationshipIdToRelationship.Values()){
            if(mapRelationshipIdToRestricted.get(rs.Id) == true){
                relationshipPrivateIds.add(rs.Id);
            }
        }
        if(!relationshipPrivateIds.IsEmpty()){
            for(rC_Bios__Relationship__share RSShare: [SELECT Id, AccessLevel, ParentId FROM rC_Bios__Relationship__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:relationshipPrivateIds]){
                relationshipSharesToBeDelete.add(RSShare);
            }
        }
        // Delete the Relationship Share records.
        if(!relationshipSharesToBeDelete.isEmpty()){
            try{
                delete relationshipSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                            'deleteRelationshipSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: InsertRelationshipSharingRecords
    *@param : Map<Id,rC_Bios__Relationship__c> (Relationship Id to Relationship)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void InsertRelationshipSharingRecords(Map<Id, rC_Bios__Relationship__c> mapRelationshipIdToRelationship, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapRelationshipIdToRestricted){
        List<rC_Bios__Relationship__share> relationshipSharesToBeInsert = new List<rC_Bios__Relationship__share>();

        //Create the Relationship Share Records to all of Objects
        for(Id objId: mapRelationshipIdToRelationship.keyset()){
            //Accounts
            if(mapRelationshipIdToRelationship.get(ObjId) != null && !mapRelationshipIdToRestricted.get(ObjId) &&  mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_1__r.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_1__r.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_1__r.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }
            if(mapRelationshipIdToRelationship.get(ObjId) != null && !mapRelationshipIdToRestricted.get(ObjId) && mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_2__r.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_2__r.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Account_2__r.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }

            // Contacts
            if(mapRelationshipIdToRelationship.get(ObjId) != null && !mapRelationshipIdToRestricted.get(ObjId) &&  mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Contact_1__r.account.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Contact_1__r.account.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Contact_1__r.account.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }

            if(mapRelationshipIdToRelationship.get(ObjId) != null && !mapRelationshipIdToRestricted.get(ObjId) &&  mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Contact_2__r.account.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Contact_2__r.account.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Contact_2__r.account.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }

            //Opportunity
            if(mapRelationshipIdToRelationship.get(ObjId) != null && !mapRelationshipIdToRestricted.get(ObjId) && mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Opportunity__r.account.Affiliation__c != null && mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Opportunity__r.account.Affiliation__c) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(mapRelationshipIdToRelationship.get(ObjId).rC_Bios__Opportunity__r.account.Affiliation__c);
                relationshipSharesToBeInsert.add(RSShare);
            }

            if(mapRelationshipIdToRestricted.get(objId) == false && mapGroupNameToId.get(ALLACLU) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Read';
                RSShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                relationshipSharesToBeInsert.add(RSShare);
            }

            if(mapRelationshipIdToRestricted.get(objId) == false && mapGroupNameToId.get(NATIONAL) != null){
                rC_Bios__Relationship__share RSShare = new rC_Bios__Relationship__share();
                RSShare.ParentId = ObjId;
                RSShare.AccessLevel = 'Edit';
                RSShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                relationshipSharesToBeInsert.add(RSShare);
            }


        }
        // Insert the Relationship share Objects
        if(!relationshipSharesToBeInsert.IsEmpty()){
            try{
                insert relationshipSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                            'InsertRelationshipSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: resetRelationshipSharing
    *@param : setId (AccountId)List<String> (OldAffiliations)
    *@description : Method which recalculates as per the respective Account Affiliation__c
    *
    */


    public static void resetRelationshipSharing(Set<Id> AccountIds, List<String> OldAffiliations){
        // Method Variables
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new Map<Id,rC_Bios__Relationship__c>();
        Map<Id,Boolean> mapRelationshipIdToRestricted = new Map<Id,Boolean>();
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();

         // Collect the RelationshipIdToRelationship and collect the affiliations
        for(rC_Bios__Relationship__c mapRe: [SELECT Id, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact_1__r.Account.Restricted_Account__c, rC_Bios__Contact_2__r.Account.Restricted_Account__c, rC_Bios__Account_1__r.Restricted_Account__c, rC_Bios__Account_2__r.Restricted_Account__c,
                                                rC_Bios__Opportunity__c, rC_Bios__Account_1__c, rC_Bios__Account_2__c, rC_Bios__Account_1__r.Affiliation__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Contact_2__r.accountId, rC_Bios__Contact_2__r.account.Affiliation__c, rC_Bios__Contact_1__r.accountId, rC_Bios__Contact_1__r.account.Affiliation__c, rC_Bios__Account_2__r.Affiliation__c FROM rC_Bios__Relationship__c WHERE rC_Bios__Account_1__c =:AccountIds OR rC_Bios__Account_2__c =:AccountIds]){
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
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name =:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deleteRelationshipSharingRecords (mapRelationshipIdToRelationship, OldAffiliations, mapGroupNameToId, mapRelationshipIdToRestricted);
        // Insert the new Affiliations records.
        InsertRelationshipSharingRecords (mapRelationshipIdToRelationship, mapGroupNameToId, mapRelationshipIdToRestricted);



    }

     /*
    *
    *Method: deletePlannedGivingRecords
    *@param : setId (plannedGiving Ids)
    *@param : String List (Affiliations names)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which deletes all the Edit Sharing records Related to plannedGiving Object.
    *
    */
    public static void deletePlannedGivingRecords(Set<Id> plannedGivingIds, List<String> OldAffiliations, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapPlannedGivingToRestricted){
        Set<Id> groupIds = new Set<Id>();
        Set<Id> plannedGivingPrivateIds = new Set<Id>();
        List<rC_Giving__Planned_Giving__share> PlannedGivingSharesToBeDelete = new List<rC_Giving__Planned_Giving__share> ();




        for(rC_Giving__Planned_Giving__c pg: [SELECT Id,rC_Giving__Fund__r.Affiliation__c , rC_Giving__Account__r.Affiliation__c, rC_Giving__Fund__r.Restricted_Account__c ,rC_Giving__Account__r.Restricted_Account__c FROM rC_Giving__Planned_Giving__c WHERE id=: plannedGivingIds]){
            if(mapPlannedGivingToRestricted.get(pg.Id) == true){
                // Deleting all the Existing Affiliations groups.
                if(pg.rC_Giving__Fund__r != null && pg.rC_Giving__Fund__r.Affiliation__c != null)
                    OldAffiliations.add(pg.rC_Giving__Fund__r.Affiliation__c);
                if(pg.rC_Giving__Account__r != null && pg.rC_Giving__Account__r.Affiliation__c != null)
                    OldAffiliations.add(pg.rC_Giving__Account__r.Affiliation__c);

            }
        }

        // Collect the groupIds based which are related to OldAffiliations
        for(String str: OldAffiliations){
            if(mapGroupNameToId.get(str) != null)
                groupIds.add(mapGroupNameToId.get(str));
        }

        // Collect PlannedGiving Share records having edit access
        for(rC_Giving__Planned_Giving__share PGShare: [SELECT Id, AccessLevel, ParentId FROM rC_Giving__Planned_Giving__share where UserOrGroupId =: groupIds AND AccessLevel = 'Edit' AND ParentId =:plannedGivingIds]){
            PlannedGivingSharesToBeDelete.add(PGShare);
        }

        for(Id objId: plannedGivingIds){
            if(mapPlannedGivingToRestricted.get(objId) == true){
                plannedGivingPrivateIds.add(objId);
            }
        }

        if(!plannedGivingPrivateIds.IsEmpty()){
            for(rC_Giving__Planned_Giving__share PGShare: [SELECT Id, AccessLevel, ParentId FROM rC_Giving__Planned_Giving__share where (UserOrGroupId =: mapGroupNameToId.get(NATIONAL) OR UserOrGroupId =: mapGroupNameToId.get(ALLACLU)) AND ParentId =:plannedGivingPrivateIds]){
                PlannedGivingSharesToBeDelete.add(PGShare);
            }
        }

        // Delete the PlannedGiving Share records.
        if(!PlannedGivingSharesToBeDelete.isEmpty()){
            try{
                delete PlannedGivingSharesToBeDelete;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                                  'deletePlannedGivingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    /*
    *
    *Method: InsertPlannedGivingSharingRecords
    *@param : Map<Id,rC_Bios__Relationship__c> (Relationship Id to Relationship)
    *@param : Map<String,Id> (GroupName To Id)
    *@description : Method which inserts all the Edit Sharing records Related to Salutation Object.
    *
    */
    public static void InsertPlannedGivingSharingRecords(Map<Id, rC_Giving__Planned_Giving__c> mapPlannedGivingIdToPlannedGiving, Map<String,Id> mapGroupNameToId, Map<Id,Boolean> mapPlannedGivingIdToRestricted){
        List<rC_Giving__Planned_Giving__share> PlannedGivingSharesToBeInsert = new List<rC_Giving__Planned_Giving__share>();

        //Create the PlannedGiving Share Records to all of Objects
        for(Id objId: mapPlannedGivingIdToPlannedGiving.keyset()){

            if(mapPlannedGivingIdToPlannedGiving.get(ObjId) != null && !mapPlannedGivingIdToRestricted.get(objId) && mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Account__r.Affiliation__c != null &&  mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Account__r.Affiliation__c) != null){
                rC_Giving__Planned_Giving__share PGShare = new rC_Giving__Planned_Giving__share();
                PGShare.ParentId = ObjId;
                PGShare.AccessLevel = 'Edit';
                PGShare.UserOrGroupId = mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Account__r.Affiliation__c);
                PlannedGivingSharesToBeInsert.add(PGShare);
            }

            if(mapPlannedGivingIdToPlannedGiving.get(ObjId) != null && !mapPlannedGivingIdToRestricted.get(objId) && mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Fund__r.Affiliation__c != null && mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Fund__r.Affiliation__c) != null){
                rC_Giving__Planned_Giving__share PGShare = new rC_Giving__Planned_Giving__share();
                PGShare.ParentId = ObjId;
                PGShare.AccessLevel = 'Edit';
                PGShare.UserOrGroupId = mapGroupNameToId.get(mapPlannedGivingIdToPlannedGiving.get(ObjId).rC_Giving__Fund__r.Affiliation__c);
                PlannedGivingSharesToBeInsert.add(PGShare);
            }

            if(mapPlannedGivingIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(ALLACLU) != null){
                rC_Giving__Planned_Giving__share PGShare = new rC_Giving__Planned_Giving__share();
                PGShare.ParentId = ObjId;
                PGShare.AccessLevel = 'Read';
                PGShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                PlannedGivingSharesToBeInsert.add(PGShare);
            }

            if(mapPlannedGivingIdToRestricted.get(ObjId) == false && mapGroupNameToId.get(NATIONAL) != null){
                rC_Giving__Planned_Giving__share PGShare = new rC_Giving__Planned_Giving__share();
                PGShare.ParentId = ObjId;
                PGShare.AccessLevel = 'Edit';
                PGShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                PlannedGivingSharesToBeInsert.add(PGShare);
            }
        }

         // Insert the PlannedGiving share Objects
        if(!PlannedGivingSharesToBeInsert.IsEmpty()) {
            try{
                insert PlannedGivingSharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','',
                                                           'InsertPlannedGivingSharingRecords error:: '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }


    /*
    *
    *Method: resetPlannedGivingSharing
    *@param : setId (AccountId)
    *@param : List<String> OldAffiliations
    *@description : Method which recalculates as per the respective Account Affiliation__c
    *
    */


    public static void resetPlannedGivingSharing(Set<Id> AccountIds, List<String> OldAffiliations){
        // Method Variables

        Map<Id,rC_Giving__Planned_Giving__c> mapPlannedGivingIdToPlannedGiving = new Map<Id,rC_Giving__Planned_Giving__c>();
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,Boolean> mapPlannedGivingToRestricted = new Map<Id,Boolean>();

         // Collecting All PlannedGiving account Share records having edit access
        for(rC_Giving__Planned_Giving__c pG: [SELECT Id, rC_Giving__Fund__r.Restricted_Account__c, rC_Giving__Account__r.Restricted_Account__c, rC_Giving__Account__r.Affiliation__c,   rC_Giving__Fund__r.Affiliation__c FROM rC_Giving__Planned_Giving__c WHERE rC_Giving__Account__c =:AccountIds OR rC_Giving__Fund__c =:AccountIds]){
            mapPlannedGivingIdToPlannedGiving.put(pG.Id,pG);
            if(pG.rC_Giving__Account__r.Affiliation__c != null){
                groupNames.add(pG.rC_Giving__Account__r.Affiliation__c);
            }
            if(pG.rC_Giving__Fund__r.Affiliation__c != null){
                groupNames.add(pG.rC_Giving__Fund__r.Affiliation__c);
            }
            if(pG.rC_Giving__Fund__r.Restricted_Account__c == true || pG.rC_Giving__Account__r.Restricted_Account__c == true){
                mapPlannedGivingToRestricted.put(pG.Id,true);
            }
            else
                mapPlannedGivingToRestricted.put(pG.Id,false);
        }

         //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name =: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        deletePlannedGivingRecords (mapPlannedGivingIdToPlannedGiving.KeySet(), OldAffiliations, mapGroupNameToId, mapPlannedGivingToRestricted);
        // Insert the new Affiliations records.
        InsertPlannedGivingSharingRecords (mapPlannedGivingIdToPlannedGiving, mapGroupNameToId, mapPlannedGivingToRestricted);
    }

    /* Saurabh Deep - 7/26/2017
     * As dicussed with Lalit, commenting this code since Apex sharing would not be needed after updating OWD settings for
     * Portfolio object to Public Read/Write
    public static void InsertPortfolioSharingRecords(Map<Id,Set<Id>>PortfolioIdVsGroupIdsToCreateSharingFor){
      List<Portfolio__share> PortfolioSharesToBeInsert = new List<Portfolio__share>();
      for(Id objId: PortfolioIdVsGroupIdsToCreateSharingFor.keySet()){
        if(PortfolioIdVsGroupIdsToCreateSharingFor.get(objId) != null){
          for(Id groupId : PortfolioIdVsGroupIdsToCreateSharingFor.get(objId)) {
            Portfolio__share PShare = new Portfolio__share();
            PShare.ParentId = ObjId;
            PShare.AccessLevel = 'Edit';
            PShare.UserOrGroupId = groupId;
            PortfolioSharesToBeInsert.add(PShare);
          }
        }
      }
      // Insert the Portfolio share Objects
      if(!PortfolioSharesToBeInsert.IsEmpty()) {
          try{
            insert PortfolioSharesToBeInsert;
          } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','InsertPortfolioSharingRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
        }
      }
    }

    public static void DeletePortfolioSharingRecords(Map<Id,Set<Id>> PortfolioIdVsgroupIdsToDeleteSharingFor){
      List<Portfolio__share> PortfolioSharesToBeDeleted = new List<Portfolio__share>();
      set<Id> groupIds = new set<Id>();
      for(Set<Id> theSet : PortfolioIdVsgroupIdsToDeleteSharingFor.Values()) {
        groupIds.addAll(theSet);
      }
      for(Portfolio__share PShare: [SELECT Id, AccessLevel, ParentId, UserOrGroupId
                                    FROM Portfolio__share
                                    where UserOrGroupId IN: groupIds
                                    AND AccessLevel = 'Edit'
                                    AND ParentId IN : PortfolioIdVsgroupIdsToDeleteSharingFor.keySet()]){
        if(PortfolioIdVsgroupIdsToDeleteSharingFor.containsKey(PShare.ParentId) && PortfolioIdVsgroupIdsToDeleteSharingFor.get(PShare.ParentId).contains(PShare.UserOrGroupId)) {
          PortfolioSharesToBeDeleted.add(PShare);
        }
      }
      // Delete the Portfolio share Objects
      if(!PortfolioSharesToBeDeleted.IsEmpty()) {
        try{
            delete PortfolioSharesToBeDeleted;
        } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('RecordAccessUtility','DeletePortfolioSharingRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
        }
      }
    }*/
}