/*
*
*Name  :  AccountTeamAsyncProcessor
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  October 31, 2017
*Purpose : AsyncRequest processor to create the Apex sharing for the Account Team Member.
*
*/

public without sharing class AccountTeamAsyncProcessor  {
    public AsyncRequest__c incomingRequest;
    @TestVisible
    private  Map<Id,Set<Id>> userToAccount_RWAccess;
    private  Set<Id> account_RWAccessSet;
    private  Boolean isRWAccess;
    private Schema.SObjectType shareObjectType;
    
    // Constructor Called from QueueableCentralProcessor
    public AccountTeamAsyncProcessor(AsyncRequest__c request) {
        incomingRequest = request;
        this.userToAccount_RWAccess = (Map<Id,Set<Id>>)JSON.deserialize(incomingRequest.Params__c.split('--')[0], Map<Id, Set<Id>>.class);
        this.account_RWAccessSet = (Set<Id>)JSON.deserialize(incomingRequest.Params__c.split('--')[1], Set<Id>.class);
        this.isRWAccess = (Boolean)JSON.deserialize(incomingRequest.Params__c.split('--')[2], Boolean.class);
    }
    
    // Constructor Called from QueueableCentralProcessor
    public AccountTeamAsyncProcessor(AsyncRequest__c request, Schema.SObjectType shareObjectType) {
        incomingRequest = request;
        this.userToAccount_RWAccess = (Map<Id,Set<Id>>)JSON.deserialize(incomingRequest.Params__c, Map<Id, Set<Id>>.class);
        this.shareObjectType = shareObjectType;
    }
    
     /*
    * Method shareWithAccountTeam
    * @description : Share records with Account teams (T-642446)
    */
    public void shareWithAccountTeam() {
        try {
            AccountTeamRecordAccessUtility.shareRecordsWithAccountTeam(userToAccount_RWAccess, shareObjectType);
        }
        catch(Exception e) {
	        update new AsyncRequest__c(Id=incomingRequest.id, Error__c = true, Error_Message__c = e.getMessage());	        
        }
    }
    
     /*
    * Method createUserSharing
    * @description : Create Sharing Records (T-639732)
    */
    public void createUserSharing() {
        try{
            // Account Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToAccountRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess);
            
            // Confidential Data Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, Confidential_Data__Share.getSobjectType(), Confidential_Data__c.getSobjectType());
            
            // Payment Method Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, rC_Giving__Payment_Method__Share.getSobjectType(), rC_Giving__Payment_Method__c.getSobjectType());
            
            // Preference Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, rC_Bios__Preference__Share.getSobjectType(), rC_Bios__Preference__c.getSobjectType());
            
            // Planned Giving Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, rC_Giving__Planned_Giving__Share.getSobjectType(), rC_Giving__Planned_Giving__c.getSobjectType());
            
            // Prospect Research Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, Prospect_Research__Share.getSobjectType(), Prospect_Research__c.getSobjectType());
            
            // Relationship Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, rC_Bios__Relationship__Share.getSobjectType(), rC_Bios__Relationship__c.getSobjectType());
            
            // Salutation Sharing
            AccountTeamRecordAccessUtility.grantRWAccessToRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, isRWAccess, rC_Bios__Salutation__Share.getSobjectType(), rC_Bios__Salutation__c.getSobjectType());
            
        }
        catch(Exception e) {
	        update new AsyncRequest__c(Id=incomingRequest.id, Error__c = true, Error_Message__c = e.getMessage());	        
        }
    }
    
     /*
    * Method deleteUserSharing
    * @description : Delete Sharing Records (T-639732)
    */
    public void deleteUserSharing() {
        try{
            // Remove Account Sharing
            AccountTeamRecordAccessUtility.removeAccessToAccountRecord(userToAccount_RWAccess, account_RWAccessSet);
            
            // Remove Confidential Data Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, Confidential_Data__Share.getSobjectType(), Confidential_Data__c.getSobjectType());
            
            // Remove Payment Method Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, rC_Giving__Payment_Method__Share.getSobjectType(), rC_Giving__Payment_Method__c.getSobjectType());
            
            // Remove Preference Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, rC_Bios__Preference__Share.getSobjectType(), rC_Bios__Preference__c.getSobjectType());
            
            // Remove Planned Giving Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, rC_Giving__Planned_Giving__Share.getSobjectType(), rC_Giving__Planned_Giving__c.getSobjectType());
            
            // Remove Prospect Research Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, Prospect_Research__Share.getSobjectType(), Prospect_Research__c.getSobjectType());
            
            // Remove Relationship Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, rC_Bios__Relationship__Share.getSobjectType(), rC_Bios__Relationship__c.getSobjectType());
            
            // Remove Salutation Sharing
            AccountTeamRecordAccessUtility.removeAccessFromRelatedRecord(userToAccount_RWAccess, account_RWAccessSet, rC_Bios__Salutation__Share.getSobjectType(), rC_Bios__Salutation__c.getSobjectType());
        }
        catch(Exception e) {
	        update new AsyncRequest__c(Id=incomingRequest.id, Error__c = true, Error_Message__c = e.getMessage());	
        }
    }
}