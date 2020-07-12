/*
*
*Name  :  PreferenceTriggerHandler
*Author:  Appirio India (Saikrishna Tavva)
*Date  :  November 17, 2016
*Purpose :  Handler Class for PreferenceTrigger
            Logic includes but not limited to
            - Sets Apex Sharing model, Sharing with Account Team
            - Sends Chatter 
            - Updates Account Preference related fields like Preference_String__c and others
* Modified By : Zendesk : #68651 - 16th Sept 2019
*/
public class PreferenceTriggerHandler {
    
    public static final String ALLACLU = Label.All_ACLU;
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
    public static void mainEntry(List<rC_Bios__Preference__c> newList, List<rC_Bios__Preference__c> oldList, Map<Id, rC_Bios__Preference__c> newMap,
                                Map<Id, rC_Bios__Preference__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, 
                                Boolean isBefore, Boolean isAfter) {
        
        //if trigger is active
        if(TriggerState.isActive('Preference_Trigger') 
            && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) 
            && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
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
            }
        }
        
    }
    
    
/*    
*
*Method onBeforeInsert
*@param : newList
*
*/
   public static void onBeforeInsert(List<rC_Bios__Preference__c> newList) {
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> SetAccountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        
        for(rC_Bios__Preference__c obj: newList){
            if(obj.rC_Bios__Account__c != null){
                accountIds.add(obj.rC_Bios__Account__c);
            }
            /*Traction(Mounica), January 28,2020, BGE-2 : Added BuP sequence to bypass the trigger logic when the preference is created via BUP*/
            if(obj.rC_Bios__Account__c != null && string.isBlank(obj.Bup_Sequence__c)){ 
                SetAccountIds.add(obj.rC_Bios__Account__c);
            }
            if(obj.rC_Bios__Contact__c != null){
                contactIds.add(obj.rC_Bios__Contact__c);
            }
        }
        
        hasPermission(accountIds, contactIds, newList); 
        if(!SetAccountIds.isEmpty())
        DuplicatePreferenceCheck(SetAccountIds ,newList );
    }
    
    
/*    
*
*Method onBeforeDelete
*@param : oldList
*
*/
   public static void onBeforeDelete(List<rC_Bios__Preference__c> oldList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> preferenceIdSendChatter = new Set<Id>();

        List<Account> updateAccountFlags = new List<Account>();
        for(rC_Bios__Preference__c obj: oldList){
            if(obj.rC_Bios__Account__c != null){
                accountIds.add(obj.rC_Bios__Account__c);
            }
          
            if(obj.rC_Bios__Contact__c != null){
                contactIds.add(obj.rC_Bios__Contact__c);
            }
        }
        sendChatters(oldList);
        hasPermission(accountIds, contactIds, oldList);
        
    }
    
    public static void onAfterDelete(list<rC_Bios__Preference__c> oldList) {
        set<Id> deletedValues = new set<Id>();
        for(rC_Bios__Preference__c obj: oldList){
            if(obj.rC_Bios__Code_Value__c != null && (!String.isBlank(obj.rC_Bios__Code_Value__c)) && obj.rC_Bios__Account__c != null) {
              deletedValues.add(obj.rC_Bios__Account__c);      
            }
        }
        if(deletedValues != null) {
          updateAccountPrefStrings(deletedValues);
        }
    }

/*    
*
*Method onAfterInsert
*@param : listMap
*
*/
    
   public static void onAfterInsert(list<rC_Bios__Preference__c> listMap){  
        
        Set<Id> preferenceIds = new Set<Id>();
        List<rC_Bios__Preference__c> preferenceIdSendChatter = new List<rC_Bios__Preference__c>();
        set<Id> updateAccStrings = new set<Id>();
        Map<Id, Set<Id>> prefAccountMap = new Map<Id, Set<Id>>();
        
        for(rC_Bios__Preference__c pre: listMap){
            if(Pre.rC_Bios__Account__c != null || Pre.rC_Bios__Contact__c != null){
                preferenceIds.add(pre.Id);
            }
            if(!pre.rC_Bios__Active__c  || pre.rC_Bios__End_Date__c != null){
                preferenceIdSendChatter.add(pre);
            }
            
            if(!String.isBlank(pre.rC_Bios__Code_Value__c) && pre.rC_Bios__Account__c != null) {
                updateAccStrings.add(pre.rC_Bios__Account__c);
            }
            
            if(pre.rC_Bios__Account__c != null) {
                if(!prefAccountMap.containsKey(pre.rC_Bios__Account__c)) {
                    prefAccountMap.put(pre.rC_Bios__Account__c, new Set<Id>());
                }
                prefAccountMap.get(pre.rC_Bios__Account__c).add(pre.Id);
            }
        }
        
        if(!preferenceIds.isEmpty() && Utilities.CanUseFutureContext()){
            setpreferenceShareRecords(preferenceIds);
        }
        if(!preferenceIdSendChatter.isEmpty()){
            sendChatters(preferenceIdSendChatter);
        }
        if(!updateAccStrings.isEmpty()) {
            updateAccountPrefStrings(updateAccStrings);
        }
        if(!prefAccountMap.isEmpty()) {
            PreferenceTriggerHandler.sharePrefWithAccountTeam(prefAccountMap);
        } 
    }
    
/*    
*
*Method hasCreatePermission
*@param : accountIds
*@param : contactIds
*@param : preferenceList
*It checks the createPermissions.
*
*/
    public static void hasPermission(Set<Id> accountIds, Set<Id> contactIds, List<rC_Bios__Preference__c> preferenceList){
        
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, ID> mapContactIdToAccountId = new Map<ID, ID>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();
        
        for(Contact con: [SELECT Id,accountId FROM Contact WHERE Id=: contactIds ]){
            accountIds.add(con.accountId);
            mapContactIdToAccountId.put(con.Id,con.accountId);
        }
        
        
        for(Account acc: [SELECT id,Affiliation__C FROM Account WHERE Id =: accountIds]){
            mapAccountIdToAffiliation.put(acc.Id,acc.Affiliation__c);
        }
        
        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(mapAccountIdToAffiliation.Values());
        
        if(!accountIds.isEmpty()) {
            for(Account_Team__c objTeam : [ SELECT Id, Grant_Edit_Access__c, Team_Member__c, Account__c 
                                            FROM Account_Team__c 
                                            WHERE Account__c IN: accountIds]) {
                userAccessMap.put(objTeam.Account__c+'-'+objTeam.Team_Member__c, objTeam.Grant_Edit_Access__c);
            }
        }
        
        for(rC_Bios__Preference__c obj: preferenceList){
            if(userAccessMap.containsKey(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId()) && !userAccessMap.get(obj.rC_Bios__Account__c+'-'+UserInfo.getUserId())) {
                if(obj.rC_Bios__Account__c != null){
                    if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account__c)) != null 
                        && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Bios__Account__c))){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
                
                if(obj.rC_Bios__Contact__c != null){
                    if(mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact__c))) != null 
                        && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(mapContactIdToAccountId.get(obj.rC_Bios__Contact__c)))){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
            }
        }
    }
    
     /*    
    *
    *Method sharePrefWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void sharePrefWithAccountTeam(Map<Id, Set<Id>> prefAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (prefAccountMap.size() > 0) {
            Map<Id, Set<Id>> newPrefAccountMap = new Map<Id, Set<Id>>();

            for (Id key : prefAccountMap.KeySet()) { 
                if (newPrefAccountMap.size() < accountAsyncBatchMax) {
                    newPrefAccountMap.put(key, prefAccountMap.get(key));
                    prefAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'rC_Bios__Preference__c',
                                   Params__c = JSON.serialize(newPrefAccountMap)));
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
*Method setpreferenceShareRecords
*@param : preferenceIds
*It creates the share records based on the their accountAffiliation.
*
*/
    //@future
    public static void setpreferenceShareRecords(Set<Id> preferenceIds){
        //variables
        Map<Id,String> mapPreferenceIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPreferenceIdToRestricted = new map<Id,Boolean> ();

        // Collect the AccountIds
        for(rC_Bios__Preference__c mapPre: [    SELECT  Id, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Account__r.Restricted_Account__c, 
                                                        rC_Bios__Contact__r.Account.Affiliation__c, rC_Bios__Contact__r.AccountId, rC_Bios__Contact__c, 
                                                        rC_Bios__Account__c, rC_Bios__Account__r.Affiliation__c 
                                                FROM    rC_Bios__Preference__c 
                                                WHERE   Id =: preferenceIds]){
            if(mapPre.rC_Bios__Account__c != null && mapPre.rC_Bios__Account__r.Affiliation__c != null){
                mapPreferenceIdToAffiliate.put(mapPre.Id,mapPre.rC_Bios__Account__r.Affiliation__c);
                mapPreferenceIdToRestricted.put(mapPre.Id,mapPre.rC_Bios__Account__r.Restricted_Account__c);
            }
            
            //Contact Accounts Affiliations Relations
            if(mapPre.rC_Bios__Contact__c != null && mapPre.rC_Bios__Contact__r.AccountId != null && mapPre.rC_Bios__Contact__r.Account.Affiliation__c != null ){
                mapPreferenceIdToAffiliate.put(mapPre.Id,mapPre.rC_Bios__Contact__r.Account.Affiliation__c);
                mapPreferenceIdToRestricted.put(mapPre.Id,mapPre.rC_Bios__Contact__r.Account.Restricted_Account__c);
            }
        }
                
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPreferenceIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPreferenceSharingRecords (mapPreferenceIdToAffiliate, mapGroupNameToId, mapPreferenceIdToRestricted);
    }
    
    /*    
*
*Method onAfterUpdate
*@param : newMap
*@param : OldMap
*It checks whether the Account/Contact Lookup changed.
*
*/
    
    public static void onAfterUpdate(Map<Id,rC_Bios__Preference__c> newMap, Map<Id,rC_Bios__Preference__c> OldMap){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> preferenceIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        List<rC_Bios__Preference__c> preferenceIdSendChatter = new List<rC_Bios__Preference__c>();
        List<String> OldAffiliations = new List<String>();
        set<Id> updateAccStrings = new set<Id>();
        
        for(rC_Bios__Preference__c pr: newMap.Values()){
            if(OldMap.get(pr.Id).rC_Bios__Account__c != pr.rC_Bios__Account__c){
                accountIds.add(OldMap.get(pr.Id).rC_Bios__Account__c);
                preferenceIds.add(pr.Id);
            }
            
            if(OldMap.get(pr.Id).rC_Bios__Contact__c != pr.rC_Bios__Contact__c){
                accountIds.add(OldMap.get(pr.Id).rC_Bios__Contact__r.accountId);
                preferenceIds.add(pr.Id);
                contactIds.add(OldMap.get(pr.Id).rC_Bios__Contact__c);
            }
           if(!pr.rC_Bios__Active__c  || pr.rC_Bios__End_Date__c != null){
                preferenceIdSendChatter.add(pr);
            }
            
            if(pr.rC_Bios__Account__c != null && (pr.rC_Bios__Code_Value__c != oldMap.get(pr.Id).rC_Bios__Code_Value__c ||
                    pr.rC_Bios__Active__c != oldMap.get(pr.Id).rC_Bios__Active__c)) {
                updateAccStrings.add(pr.rC_Bios__Account__c);
            }
        }
        sendChatters(preferenceIdSendChatter);
        
        for(Contact con: [SELECT Id,account.Affiliation__c,accountId FROM Contact WHERE Id =: contactIds]){
            if(con.accountId != null )
                accountIds.add(con.accountId);
        }
        
        for(Account acc: [SELECT id,Affiliation__c FROM Account WHERE Id =: accountIds]){
            if(acc.Affiliation__c != null)
                OldAffiliations.add(acc.Affiliation__c);
        }
        if(!OldAffiliations.IsEmpty() && Utilities.CanUseFutureContext()){
            resetPreferenceShareRecords(preferenceIds,OldAffiliations);
        }
        if(!updateAccStrings.isEmpty()) {
            updateAccountPrefStrings(updateAccStrings);    
        }
    }
    
        /*    
*
*Method resetPreferenceShareRecords
*@param : Set<Id> (preferenceIds)
*@param : List<String> OldAffiliations
*It resets the share records based on the their account Affiliation.
*
*/
    
    //@future
    public static void resetPreferenceShareRecords(Set<Id> preferenceIds, List<String> OldAffiliations){
        //variables
        Map<Id,String> mapPreferenceIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPreferenceIdToRestricted = new map<Id,Boolean> ();
        
        // Collect the PreferenceIds
        for(rC_Bios__Preference__c mapPre: [    SELECT  Id, rC_Bios__Contact__r.account.Restricted_Account__c, rC_Bios__Account__r.Restricted_Account__c, 
                                                        rC_Bios__Contact__r.Account.Affiliation__c, rC_Bios__Contact__r.AccountId, rC_Bios__Contact__c, rC_Bios__Account__c, 
                                                        rC_Bios__Account__r.Affiliation__c 
                                                FROM    rC_Bios__Preference__c 
                                                WHERE   Id =: preferenceIds]){
            if(mapPre.rC_Bios__Account__c != null && mapPre.rC_Bios__Account__r.Affiliation__c != null){
                mapPreferenceIdToAffiliate.put(mapPre.Id,mapPre.rC_Bios__Account__r.Affiliation__c);
                mapPreferenceIdToRestricted.put(mapPre.Id,mapPre.rC_Bios__Account__r.Restricted_Account__c);
            }
            
            //Contact Accounts Affiliations Relations
            if(mapPre.rC_Bios__Contact__c != null && mapPre.rC_Bios__Contact__r.AccountId != null && mapPre.rC_Bios__Contact__r.Account.Affiliation__c != null ){
                mapPreferenceIdToAffiliate.put(mapPre.Id,mapPre.rC_Bios__Contact__r.Account.Affiliation__c);
                mapPreferenceIdToRestricted.put(mapPre.Id,mapPre.rC_Bios__Contact__r.account.Restricted_Account__c);
            }
        }
        
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPreferenceIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deletePreferenceSharingRecords (mapPreferenceIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapPreferenceIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPreferenceSharingRecords (mapPreferenceIdToAffiliate, mapGroupNameToId, mapPreferenceIdToRestricted);
    }
 
 
    
/*    
*Task Number : T-589135
*Author : Niza Khunger
*Method sendChatters
*@param : List<rC_Bios__Preference__c>
*It is used to chatter AccountTeamMember and OpportunityTeamMember.
*/

    public static void sendChatters(List<rC_Bios__Preference__c> prefListDeleted) {
        TriggerSettings__c triggerSetting = TriggerSettings__c.getInstance('Preference_Trigger');
        if(!Test.isRunningTest() && triggerSetting.Enable_Alerts__c == false) {// Zendesk - #68651 - Added custom setting check
                return;
        }
       System.debug(triggerSetting);
       // Variables
       Map<rC_Bios__Preference__c, Set<Id>> mapPrefwithTeamMembers = new Map<rC_Bios__Preference__c, Set<Id>>();
       MAp<Id, list<rC_Bios__Preference__c>> accToPref = new Map<Id, list<rC_Bios__Preference__c>>();
       Map<Id, Id> oppToAcc = new Map <Id, Id>();
       List<FeedItem> feedPostList = new List<FeedItem>();
       Set<Id> usrIdSet = new Set<Id>();
       
       // Get Preference based on the Criteria
      for (rC_Bios__Preference__c pref: [   SELECT  Id, rC_Bios__Category__c, rC_Bios__Subcategory__c, rC_Bios__Type__c, rC_Bios__Code_Value__c, rC_Bios__Account__r.Id 
                                            FROM    rC_Bios__Preference__c 
                                            WHERE   Id = : prefListDeleted]) 
      {
            // Criteria  based on rC_Bios__Category__c, rC_Bios__Subcategory__c, rC_Bios__Type__c, rC_Bios__Subtype__c
            If((pref.rC_Bios__Category__c != NULL && pref.rC_Bios__Subcategory__c != NULL && pref.rC_Bios__Type__c != NULL && pref.rC_Bios__Code_Value__c != NULL) 
                && pref.rC_Bios__Category__c.equalsignorecase('Programmatic') && pref.rC_Bios__Subcategory__c.equalsignorecase('Major Gifts')
                && (pref.rC_Bios__Code_Value__c.equalsignorecase('M1') || pref.rC_Bios__Code_Value__c.equalsignorecase('M2') ||pref.rC_Bios__Code_Value__c.equalsignorecase('M3') 
                    || pref.rC_Bios__Code_Value__c.equalsignorecase('M4') || pref.rC_Bios__Code_Value__c.equalsignorecase('M5') || pref.rC_Bios__Code_Value__c.equalsignorecase('M6'))
                && (pref.rC_Bios__Type__c.equalsignorecase('Top Prospects') || pref.rC_Bios__Type__c.equalsignorecase('Emerging Prospects') 
                    || pref.rC_Bios__Type__c.equalsignorecase('Suspects') || pref.rC_Bios__Type__c.equalsignorecase('Core Donors') || pref.rC_Bios__Type__c.equalsignorecase('Event Donors') 
                    || pref.rC_Bios__Type__c.equalsignorecase('CN ONLY Pre-Engagement Suspects')) )  {
                           
                       if (!accToPref.containsKey(pref.rC_Bios__Account__r.Id)) {
                            accToPref.put(pref.rC_Bios__Account__r.Id, new list<rC_Bios__Preference__c>()); }
                       
                accToPref.get(pref.rC_Bios__Account__r.Id).add(pref); 
            }
      }
       
       // Get AccountTeamMembers
       String recordTypeId =Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
       for (Account acc: [  Select  Id, (Select id from Opportunities where recordTypeId =: recordTypeId),(SELECT ID, UserId From AccountTeamMembers) 
                            From    Account 
                            where   account.Id In: accToPref.keySet()]) 
       {
             for (AccountTeamMember atm: acc.AccountTeamMembers) {
               for (rC_Bios__Preference__c pref: accToPref.get(acc.id)) {
                 if (!mapPrefwithTeamMembers.containsKey(pref)) {
                   mapPrefwithTeamMembers.put(pref, new Set < ID > ());
                 }
                 mapPrefwithTeamMembers.get(pref).add(atm.userId);
               }
             }
             
             for (Opportunity opp: acc.Opportunities){
               if (!oppToAcc.containsKey(opp.ID)){
                 oppToAcc.put(opp.ID, acc.ID);
               }
             }
       }
      
      // Get OpportunityTeamMember
      for (OpportunityTeamMember otm: [ Select  userid, opportunityId 
                                        from    OpportunityTeamMember 
                                        where   opportunity.id In: oppToAcc.keySet()]){
         for (rC_Bios__Preference__c pref: accToPref.get(oppToAcc.get(otm.opportunityId))){
           if (!mapPrefwithTeamMembers.containsKey(pref)) {
             mapPrefwithTeamMembers.put(pref, new Set < ID > ());
           }
           mapPrefwithTeamMembers.get(pref).add(otm.userID);
         }
       }
       
       // Check if user is Active and send Chatter
       for (Set < Id > userIdSet: mapPrefwithTeamMembers.values()){
         for (Id uID: userIdSet)
           usrIdSet.add(uID);
       }
       
       if(!usrIdSet.isEmpty()) {
            for(User usr: [ SELECT  id, isActive 
                            FROM    user 
                            WHERE   user.Id in : usrIdSet and isActive = true]){
                 for(Id accId: accToPref.keySet()) {
                     FeedItem item = new FeedItem();
                     item.parentId = usr.id;
                     item.body = 'A Major Gifts preference was either removed, inactivated or end dated. Click here to view the record:';
                     item.LinkUrl = 'https://'+System.URL.getSalesforceBaseUrl().getHost()+'/'+accId; 
                     item.Title = 'Record Link';
                     item.Type = 'LinkPost';
                     feedPostList.add(item);
                 }
            }
       }
       
       if(feedPostList.size() > 0) {
            insert feedPostList;
       }
     }
/*    
*Issue Number : I-271782
*Method 
*@param : List<rC_Bios__Preference__c>
* process updates Account fields: Preference String, Interest String and Common Preference Filters for active preferences
*/     
     public static void updateAccountPrefStrings(set<Id> accountIdSet) {
         Set<String> commonPreValues = new Set<String>{'AL','AN','AY','FA','FN','U1','UA','UN','Z1','ZD','ZN',
                                            'AXXAPNO','AXXBNNO','AXXCUNO','AXXEMNO','AXXINNO',
                                            'AXXNWNO','AXXPHNO','AXXTMNO','OXXAKNO','OXXAPNO',
                                            'OXXCTNO','OXXINNO','OXXIPNO','OXXNWNO','OXXPCNO',
                                            'OXXPHNO','OXXPUNA','OXXPUNL','OXXPUNO','OXXTMNO','OXXVDNO',
                                            'AXXTRANS','AJ','AN','AL', 'PX','PA','PB','PC','MM'
                                            };
         list<Account> accountsToProcess = [    select  id, name, Rpt_Board_Member__c, Affiliate_Major_Gifts_Program_ML__c, 
                                                        Affiliate_Major_Donor_Prospect_MQ__c, Rpt_Common_Preference_Filters__c, Rpt_Interest_String__c, Preference_String__c,                               
                                                        (select rC_Bios__Code_Value__c, rC_Bios__Category__c, rC_Bios__Active__c from rC_Bios__Preferences__r 
                                                order by rC_Bios__Code_Value__c ASC)//where rC_Bios__Active__c = True  
                                                from    Account 
                                                where   Id IN :accountIdSet];
        List<Account> accountsToUpdate = new List<Account>();
        if(accountsToProcess.size()>0){
            for(Account a: accountsToProcess){
                a.Rpt_Interest_String__c = '';
                a.Preference_String__c = '';
                a.Rpt_Common_Preference_Filters__c = '';
                a.Affiliate_Major_Donor_Prospect_MQ__c = false;
                a.Affiliate_Major_Gifts_Program_ML__c = false;
                a.Rpt_Board_Member__c = false;
                if(a.rC_Bios__Preferences__r.size() > 0){
                    for(rC_Bios__Preference__c pref:  a.rC_Bios__Preferences__r){
                        if(pref.rC_Bios__Code_Value__c != null){
                            if(commonPreValues.contains(pref.rC_Bios__Code_Value__c) && pref.rC_Bios__Active__c){  //Common Preference Filters
                                a.Rpt_Common_Preference_Filters__c = add_dedup(a.Rpt_Common_Preference_Filters__c, pref.rC_Bios__Code_Value__c);
                            }
                            if(pref.rC_Bios__Active__c) {//check added for only active pref records
                                if(pref.rC_Bios__Category__c == 'Interests') {  //Interest String
                                    a.Rpt_Interest_String__c = add_dedup(a.Rpt_Interest_String__c, pref.rC_Bios__Code_Value__c);
                                } else {  //Preference String
                                    a.Preference_String__c = add_dedup(a.Preference_String__c, pref.rC_Bios__Code_Value__c);
                                }
                            }
                            if(pref.rC_Bios__Active__c) {
                                if(pref.rC_Bios__Code_Value__c == 'MQ'){
                                    a.Affiliate_Major_Donor_Prospect_MQ__c = true;
                                }
                                if(pref.rC_Bios__Code_Value__c == 'ML'){
                                    a.Affiliate_Major_Gifts_Program_ML__c = true;
                                }
                                if(pref.rC_Bios__Code_Value__c == 'BA') {
                                    a.Rpt_Board_Member__c = true;
                                }
                            }
                        }
                    }//end pref loop
                    //accountsToUpdate.add(a);
                } 
                accountsToUpdate.add(a);
            }//end account for loop
        }

        try{
          if(!accountsToUpdate.isEmpty()) {
             update accountsToUpdate;
          }
        }
        catch(Exception e) {
          Exceptionutils.createApexLog('PreferenceTriggerHandler ','updateAccountPrefStrings',e);         
        }
    
     }
     public static String add_dedup(String prefString, String codeVal){
        if(String.isBlank(prefstring)){
            prefString = ':'+codeVal+':';
        } else if(!prefstring.contains(':'+codeVal+':')){
            prefString = prefString + codeVal+':';
        }
        return prefString;
    }
    
    /*Traction(Mounica), January 28,2020, BGE-2 : Prevent duplicate preference creation from dataloader*/
    Public static void DuplicatePreferenceCheck(Set<id> accountIds, List<rC_Bios__Preference__c> lstNewPre){
        
     Map<id,List<rC_Bios__Preference__c>> mapAccPreference = new Map<id,List<rC_Bios__Preference__c>>(); 
     Map<String,String> mapError = new Map<String,string>(); 
     List<String> lstAccCode = new List<String>();
     List<rC_Bios__Preference__c> lstAccPreference = [SELECT Id,rC_Bios__Active__c,rC_Bios__End_Date__c,rC_Bios__Contact__c,rC_Bios__Code_Value__c,rC_Bios__Account__c from rC_Bios__Preference__c
                                                          where rC_Bios__Account__c IN: accountIds];
                                                          
    for(rC_Bios__Preference__c opre: lstAccPreference){
      
    if(mapAccPreference.containsKey(opre.rC_Bios__Account__c))
     {   
     mapAccPreference.get(opre.rC_Bios__Account__c).add(opre);
      }
    else 
     {   
     mapAccPreference.put(opre.rC_Bios__Account__c,new list<rC_Bios__Preference__c>{opre}); 
      }   
      
     }  
        for(rC_Bios__Preference__c oPre: lstNewPre) { 
         String sAccCode = '';
         if(oPre.rC_Bios__End_Date__c == null) 
         sAccCode = oPre.rC_Bios__Code_Value__c+oPre.rC_Bios__Account__c+oPre.rC_Bios__Contact__c;
         if(sAccCode <> '' && !lstAccCode.contains(sAccCode))
         lstAccCode.add(sAccCode);
         else if(sAccCode <> '' && lstAccCode.contains(sAccCode)){ 
         oPre.addError('Duplicate on processing Preference list Identified - Preference not Inserted');
         continue;
         }
         
         if(!mapAccPreference.isEmpty() && mapAccPreference.containskey(oPre.rC_Bios__Account__c)){
           for(rC_Bios__Preference__c oAcc : mapAccPreference.get(oPre.rC_Bios__Account__c)){

              if(oAcc.rC_Bios__Code_Value__c == oPre.rC_Bios__Code_Value__c){
                 
                if((oAcc.rC_Bios__Contact__c <> null && oPre.rC_Bios__Contact__c <> null && oAcc.rC_Bios__Contact__c == oPre.rC_Bios__Contact__c) || oPre.rC_Bios__Contact__c == null) { 
             
                if(oPre.rC_Bios__Active__c == True && oAcc.rC_Bios__Active__c == True && oPre.rC_Bios__End_Date__c == null && oAcc.rC_Bios__End_Date__c == null) {
                 
                    oPre.addError('Duplicate On Account Identified - Preference not Inserted');
                   }
                  }
                 }
                } 
              }
           }
    }
 
}