/*
*
*Name  :  RecalculateSharingDownstream
*Author:  Appirio India (Sai Krishna)
*Date  :  April 17, 2017
*Purpose : Class Called from Custom Button on Account to Recalculate Sharing for account and its downStream.
*
*/
global class RecalculateSharingDownstream
{
    webservice static void reCalculateSharing(String accountId, String affiliation) 
    { 
         Map<Id,String> mapAccountIdToOldAffiliations = new Map<Id,String>();
         if(!String.isBlank(accountId) && !String.isBlank(affiliation)){
            mapAccountIdToOldAffiliations.put(Id.valueOf(accountId),affiliation);
            RecordAccessUtility.resetAccountSharing(true,mapAccountIdToOldAffiliations);
            update new Account(Id = accountId, Is_Shared_Group__c = false);
         }
    }
}