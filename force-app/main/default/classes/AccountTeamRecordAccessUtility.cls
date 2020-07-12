/*
*
*Name  :  AccountTeamRecordAccessUtility
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  October 31, 2017
*Purpose : Resets the apex sharing record model for the custom Account Team Records (T-639732)
*
*/
public class AccountTeamRecordAccessUtility {
    public static double accountTeamAsyncBatchMax;
    
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            accountTeamAsyncBatchMax = q.Batch_Size_Account_Team__c;
        } else {
            accountTeamAsyncBatchMax = 100;
        }
    }
    
    /*
    * Method grantReadORWriteAccessToRelatedObjects
    * @description : Grants Read Write/ Read Access to User for related Objects (T-639732)
    */
    public static void grantReadORWriteAccessToRelatedObjects(Map<Id, Set<Id>> userToAccount_RWAccess, Set<Id> accountIds, Boolean isRWAccess) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        String jsonObj = JSON.serialize(userToAccount_RWAccess)+'--'+JSON.serialize(accountIds)+'--'+JSON.serialize(isRWAccess);
        
        try {
            newAsyncRequests.add(new AsyncRequest__c ( AsyncType__c ='grantUserAccess', 
                                                       Object_API_Name__c = 'Account_Team__c',
                                                       Params__c = jsonObj));
            insert newAsyncRequests;    
        } catch(Exception e) {
            Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'grantReadORWriteAccessToRelatedObjects :: '
                                         + e.getMessage() + ' Insert:  '+newAsyncRequests);
        }
    }
    
    /*
    * Method deleteRelatedSharingRecords
    * @description : Delete Sharing records of Related Objects (T-639732)
    */
    public static void deleteRelatedSharingRecords(Map<Id, Set<Id>> userToAccountMap, Set<Id> accountIds) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        String jsonObj = JSON.serialize(userToAccountMap)+'--'+JSON.serialize(accountIds)+'--'+'true';
        
        try {
            newAsyncRequests.add(new AsyncRequest__c ( AsyncType__c ='removeUserAccess', 
                                                       Object_API_Name__c = 'Account_Team__c',
                                                       Params__c = jsonObj));
            insert newAsyncRequests;    
        } catch(Exception e) {
            Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'deleteRelatedSharingRecords :: ' 
                                         + e.getMessage() + ' Insert:  '+ newAsyncRequests);
        }
    }
    
    /*
    * Method grantRWAccessToAccountRecord
    * @description : Grants Read Write/ Read Access to User for relaetd Account Record (T-639732)
    */
    public static void grantRWAccessToAccountRecord(Map<Id, Set<Id>> userToAccountMap, Set<Id> accountIds, Boolean isRWAccess) {
        Map<String, AccountShare> existingAccShares = new Map<String, AccountShare>();
        List<AccountShare> accSharesToInsert = new List<AccountShare>();
        List<AccountShare> accSharesToUpdate = new List<AccountShare>();
        
        String accessLvl = isRWAccess ? 'Edit': 'Read';
        String toggledAccessLvel = isRWAccess ? 'Read' : 'Edit';
        //Added by Aashita for I-324488
        Map<Id, Id> mapAccountToOwnerID = new Map<Id,Id>();
        for(Account acc : [SELECT Id, createdbyId, OwnerID 
                               FROM Account 
                               WHERE Id IN: accountIds]) {
                mapAccountToOwnerID.put(acc.Id, acc.OwnerID);
        }
        
        for(AccountShare accShare : [   SELECT  Id, AccountAccessLevel, UserOrGroupId, AccountId 
                                        FROM    AccountShare 
                                        WHERE   UserOrGroupId IN: userToAccountMap.keySet()
                                        AND     AccountAccessLevel =: toggledAccessLvel
                                        AND     AccountId IN: accountIds]) {
            if(userToAccountMap.containsKey(accShare.UserOrGroupId) && userToAccountMap.get(accShare.UserOrGroupId).contains(accShare.AccountId)) {
                existingAccShares.put(accShare.AccountId+'-'+accShare.UserOrGroupId, accShare); 
            }   
        }
        
        for(Id usrId : userToAccountMap.keySet()) {
            for(Id accId : userToAccountMap.get(usrId)) {
                String key = accId+'-'+usrId;
                if(mapAccountToOwnerID.containsKey(accId) && mapAccountToOwnerID.get(accId) != usrId) {
                    if(!existingAccShares.containsKey(key)) {
                        AccountShare objAccShare = new AccountShare();
                        objAccShare.AccountId = accId;
                        objAccShare.AccountAccessLevel = accessLvl;
                        objAccShare.OpportunityAccessLevel = accessLvl;
                        //objAccShare.CaseAccessLevel = accessLvl; //Commented by Bhavesh, I-312158
                        objAccShare.ContactAccessLevel = accessLvl;
                        objAccShare.UserOrGroupId = usrId;
                        accSharesToInsert.add(objAccShare);
                    } else {
                        AccountShare objAccShare = existingAccShares.get(key);
                        objAccShare.AccountAccessLevel = accessLvl;
                        objAccShare.OpportunityAccessLevel = accessLvl;
                        //objAccShare.CaseAccessLevel = accessLvl; //Commented by Bhavesh, I-312158
                        objAccShare.ContactAccessLevel = accessLvl;
                        accSharesToUpdate.add(objAccShare);
                    }
                }
            }
        }
        
        if(accSharesToInsert.size() > 0) {
            try {
                insert accSharesToInsert;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'grantRWAccessToAccountRecord :: ' 
                                             + e.getMessage() + ' Insert:  '+accSharesToInsert);
            }
        }
        
        if(accSharesToUpdate.size() > 0) {
            try {
                update accSharesToUpdate;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'grantRWAccessToAccountRecord :: ' 
                                             + e.getMessage() + ' Update:  '+accSharesToInsert);
            }
        }
    }
    
     /*
    * Method grantRWAccessToRelatedRecord
    * @description : Grants Read Write/ Read Access to Related Record (T-639732)
    */
    public static void grantRWAccessToRelatedRecord(Map<Id, Set<Id>> userToAccountMap, Set<Id> accountIds, Boolean isRWAccess, Schema.SObjectType shareObjectType, Schema.SObjectType sObjectType) {
        String listType = 'Map<String,' + shareObjectType + '>';
        Map<String, SObject> existingShares = (Map<String, SObject>)Type.forName(listType).newInstance();
        Map<Id, Set<Id>> objDataMap = new Map<Id, Set<Id>>();
        Set<Id> objIds = new Set<Id>();
        Set<Id> userIds = userToAccountMap.keySet();
        
        String accessLvl = isRWAccess ? 'Edit': 'Read';
        String toggledAccessLvel = isRWAccess ? 'Read' : 'Edit';
        
        String accountAPIName = sObjectType == Confidential_Data__c.getSObjectType() ? 'Account__c': 
                                (sObjectType == rC_Giving__Payment_Method__c.getSObjectType() ? 'rC_Giving__Account__c':
                                (sObjectType == rC_Bios__Preference__c.getSObjectType() ? 'rC_Bios__Account__c':
                                (sObjectType == rC_Giving__Planned_Giving__c.getSObjectType() ? 'rC_Giving__Account__c':
                                (sObjectType == Prospect_Research__c.getSObjectType() ? 'Account__c':
                                (sObjectType == rC_Bios__Relationship__c.getSObjectType() ? 'rC_Bios__Account_1__c':
                                (sObjectType == rC_Bios__Salutation__c.getSObjectType() ? 'rC_Bios__Account__c': ''
                                ))))));
        
        String objQuery = 'SELECT Id, '+accountAPIName;
        objQuery += ' FROM '+sObjectType;
        objQuery += ' WHERE '+accountAPIName+' IN: accountIds';
        
        for(SObject obj : Database.query(objQuery)) {
            if(!objDataMap.containsKey((Id)obj.get(accountAPIName))) {
                objDataMap.put((Id)obj.get(accountAPIName), new Set<Id>());
            }
            objDataMap.get((Id)obj.get(accountAPIName)).add((Id)obj.get('Id'));
            objIds.add((Id)obj.get('Id'));
        }
        
        if(!objIds.isEmpty()) {
            
            String queryString = 'SELECT Id, accessLevel, UserOrGroupId, ParentId';
            queryString += ' FROM '+shareObjectType;
            queryString += ' WHERE UserOrGroupId IN: userIds ';
            queryString += ' AND accessLevel =: toggledAccessLvel';
            queryString += ' AND ParentId IN: objIds';
            
            for(SObject objShare : Database.query(queryString)) {
                if(userToAccountMap.containsKey((Id)objShare.get('UserOrGroupId'))) {
                    for(Id accID : userToAccountMap.get((Id)objShare.get('UserOrGroupId'))) {
                        if(objDataMap.containsKey(accID) && objIds.contains((Id)objShare.get('ParentId'))) {
                            existingShares.put((Id)objShare.get('ParentId')+'-'+objShare.get('UserOrGroupId'), objShare);
                        }
                    }   
                }
            }
            AccountTeamRecordAccessUtility.createOrUpdateSharingRecords(userToAccountMap, objDataMap, accessLvl, shareObjectType, JSON.serialize(existingShares));
        }
    }
    
    /*
    * Method createOrUpdateSharingRecords
    * @description : Create or Update Sharing Records. (T-639732)
    */
    private static void createOrUpdateSharingRecords(Map<Id, Set<Id>> userToAccountMap, Map<Id, Set<Id>> objDataMap, String accessLvl, Schema.SObjectType sObjectType, String existingShareString) {
        String listType = 'List<' + sObjectType + '>';
        List<SObject> sharesToInsert = (List<SObject>)Type.forName(listType).newInstance();
        List<SObject> sharesToUpdate = (List<SObject>)Type.forName(listType).newInstance();

        String mapType = 'Map<String,'+sObjectType+'>';
        Map<String, SObject> existingShares = (Map<String,SObject>)JSON.deserialize(existingShareString, Map<String,SObject>.class);

        //Added by Aashita for I-324488
        Set<Id> accountIds = new Set<Id>();
        for (Set<Id> accId : userToAccountMap.values()) {
            accountIds.addAll(accId);
        }
        Map<Id, Id> mapAccountToOwnerID = new Map<Id,Id>();
        for(Account acc : [SELECT Id, createdbyId, OwnerID 
                               FROM Account
                               WHERE Id IN: accountIds]) {
                mapAccountToOwnerID.put(acc.Id, acc.OwnerID);
        }
        
        for(Id usrId : userToAccountMap.keySet()) {
            for(Id accId : userToAccountMap.get(usrId)) {
                for(Id objId : objDataMap.get(accId)) {
                    String key = objId+'-'+usrId;
                    if(mapAccountToOwnerID.containsKey(accId) && mapAccountToOwnerID.get(accId) != usrId) {
                        if(!existingShares.containsKey(key)) {
                            SObject objShare = sObjectType.newSObject();
                            objShare.put('ParentId', objId);
                            objShare.put('accessLevel', accessLvl);
                            objShare.put('UserOrGroupId', usrId);
                            sharesToInsert.add(objShare);
                        } else {
                            SObject objShare = existingShares.get(key);
                            objShare.put('accessLevel', accessLvl);
                            sharesToUpdate.add(objShare);
                        }
                    }
                }
            }
        }
        
        if(sharesToInsert.size() > 0) {
            try {
                insert sharesToInsert;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'createOrUpdateSharingRecords :: ' 
                                             + e.getMessage() + ' Insert:  '+sharesToInsert);
            }
        }
        
        if(sharesToUpdate.size() > 0) {
            try {
                update sharesToUpdate;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'createOrUpdateSharingRecords :: ' 
                                             + e.getMessage() + ' Update:  '+sharesToUpdate);
            }
        }
    }
    
     /*
    * Method removeAccessToAccountRecord
    * @description : Removes sharing from Related Account Records. (T-639732)
    */
    public static void removeAccessToAccountRecord(Map<Id, Set<Id>> userToAccountMap, Set<Id> accountIds) {
        List<AccountShare> sharesToDeleteLst = new List<AccountShare>();
        for(AccountShare accShare : [   SELECT  Id, AccountAccessLevel, UserOrGroupId, AccountId 
                                        FROM    AccountShare 
                                        WHERE   UserOrGroupId IN: userToAccountMap.keySet()
                                        AND     AccountId IN: accountIds]) {
            if(userToAccountMap.containsKey(accShare.UserOrGroupId) && userToAccountMap.get(accShare.UserOrGroupId).contains(accShare.AccountId)) {
                sharesToDeleteLst.add(accShare);    
            }   
        }
        
        if(sharesToDeleteLst.size() > 0) {
            try {
                delete sharesToDeleteLst;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'removeAccessToAccountRecord :: ' 
                                             + e.getMessage() + ' Delete:  '+sharesToDeleteLst);
            }
        }
    }
    
     /*
    * Method removeAccessFromRelatedRecord
    * @description : Removes sharing from Related Records. (T-639732)
    */
    public static void removeAccessFromRelatedRecord(Map<Id, Set<Id>> userToAccountMap, Set<Id> accountIds, 
                                                   Schema.SObjectType shareObjectType, Schema.SObjectType sObjectType) {
        Set<Id> userIds = userToAccountMap.keySet();
        Set<Id> objIds = new Set<Id>();
        Map<Id, Set<Id>> objDataMap = new Map<Id, Set<Id>>();
        String listType = 'List<' + shareObjectType + '>';
        List<SObject> sharesToDeleteLst = (List<SObject>)Type.forName(listType).newInstance();
        String accountAPIName = sObjectType == Confidential_Data__c.getSObjectType() ? 'Account__c': 
                                (sObjectType == rC_Giving__Payment_Method__c.getSObjectType() ? 'rC_Giving__Account__c':
                                (sObjectType == rC_Bios__Preference__c.getSObjectType() ? 'rC_Bios__Account__c':
                                (sObjectType == rC_Giving__Planned_Giving__c.getSObjectType() ? 'rC_Giving__Account__c':
                                (sObjectType == Prospect_Research__c.getSObjectType() ? 'Account__c':
                                (sObjectType == rC_Bios__Relationship__c.getSObjectType() ? 'rC_Bios__Account_1__c':
                                (sObjectType == rC_Bios__Salutation__c.getSObjectType() ? 'rC_Bios__Account__c': ''
                                ))))));
        
        String objQuery = 'SELECT Id, '+accountAPIName;
        objQuery += ' FROM '+sObjectType;
        objQuery += ' WHERE '+accountAPIName+' IN: accountIds';
        
        for(SObject obj : Database.query(objQuery)) {
            if(!objDataMap.containsKey((Id)obj.get(accountAPIName))) {
                objDataMap.put((Id)obj.get(accountAPIName), new Set<Id>());
            }
            objDataMap.get((Id)obj.get(accountAPIName)).add((Id)obj.get('Id'));
            objIds.add((Id)obj.get('Id'));
        }
        
        String queryString = 'SELECT Id, accessLevel, UserOrGroupId, ParentId';
        queryString += ' FROM '+shareObjectType;
        queryString += ' WHERE UserOrGroupId IN: userIds ';
        queryString += ' AND ParentId IN: objIds';
        
        for(SObject objShare : Database.query(queryString)) {
            if(userToAccountMap.containsKey((Id)objShare.get('UserOrGroupId'))) {
                for(Id accID : userToAccountMap.get((Id)objShare.get('UserOrGroupId'))) {
                    if(objDataMap.containsKey(accID) && objIds.contains((Id)objShare.get('ParentId'))) {
                        sharesToDeleteLst.add(objShare);
                    }
                }   
            }
        }
       
        if(sharesToDeleteLst.size() > 0) {
            try {
                delete sharesToDeleteLst;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'removeAccessFromRelatedRecord :: ' 
                                             + e.getMessage() + ' Delete:  '+sharesToDeleteLst);

            }
        }
    }
    
      /*
    * Method shareRecordsWithAccountTeam
    * @description : Share New records with account teams. (T-642446)
    */
    public static void shareRecordsWithAccountTeam(Map<Id, Set<Id>> accountToObjMap, Schema.SObjectType shareObjectType) {
        Map<Id, Set<String>> accountToTeamMap = new Map<Id, Set<String>>();
        String listType = 'List<' + shareObjectType + '>';
        List<SObject> sharesToCreateLst = (List<SObject>)Type.forName(listType).newInstance();
        Map<Id, Id> mapAccountToOwnerID = new map<Id, Id>();
        if(!accountToObjMap.isEmpty()) {
            //added by Aashita for I-324488
            for(Account acc : [SELECT Id, createdbyId, OwnerID 
                               FROM Account 
                               WHERE Id IN: accountToObjMap.keySet()]) {
                mapAccountToOwnerID.put(acc.Id, acc.OwnerID);
            }
            for(Account_Team__c objTeam : [ SELECT  Id, Team_Member__c, Account__c, Grant_Edit_Access__c
                                            FROM    Account_Team__c 
                                            WHERE   Account__c IN: accountToObjMap.keySet() 
                                                AND Team_Member__r.isActive = TRUE]) {
                if(!accountToTeamMap.containsKey(objTeam.Account__c)) {
                    accountToTeamMap.put(objTeam.Account__c, new Set<String>());
                }
                
                for(Id objId : accountToObjMap.get(objTeam.Account__c)) {
                    if(mapAccountToOwnerID.containsKey(objTeam.Account__c) && mapAccountToOwnerID.get(objTeam.Account__c) != objTeam.Team_Member__c) {
                        accountToTeamMap.get(objTeam.Account__c).add(objId+'--'+objTeam.Team_Member__c+'--'+objTeam.Grant_Edit_Access__c);
                    }
                }
            }
        }
        
        if(!accountToTeamMap.isEmpty()) {
            for(Id accId : accountToTeamMap.keySet()) {
                for(String teamDetail : accountToTeamMap.get(accId)) {
                    List<String> teamDetails = teamDetail.split('--');
                    SObject objShare = shareObjectType.newSObject();
                    objShare.put('ParentId', teamDetails[0]);
                    objShare.put('UserOrGroupId', teamDetails[1]);
                    if(teamDetails[2] == 'true') {
                        objShare.put('accessLevel', 'Edit');
                    } else {
                        objShare.put('accessLevel', 'Read');
                    }
                    sharesToCreateLst.add(objShare);
                }
            }
        }
        
        if(!sharesToCreateLst.isEmpty()) {
            try {
                insert sharesToCreateLst;
            } catch(Exception e) {
                Exceptionutils.createApexLog('AccountTeamRecordAccessUtility','',e,'shareRecordsWithAccountTeam :: ' 
                                             + e.getMessage() + ' Insert:  '+sharesToCreateLst);
            }
        }
    }
    
     //create Account_Team__c record
    public static Account_Team__c createAccountTeam( Id accId, Id conId, Id userId, String teamrole, Boolean isInsert ){
        Account_Team__c at = new Account_Team__c();
        at.Account__c = accId;
        at.Contact__c = conid;
        at.Team_Member__c = userid;
        at.Team_Role__c = teamrole;
        if(isInsert) {
            insert at;
        }
        return at;
    }
}