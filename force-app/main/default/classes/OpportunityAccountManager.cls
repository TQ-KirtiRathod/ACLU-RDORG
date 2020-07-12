/*
*
*Name  :  OpportunityAccountManager
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Jan 11, 2017
*Purpose : Contains static methods related to Account and Opportunity. Used as a helper for OpportunityTriggerHandler
*
*/
public class OpportunityAccountManager {
    
    /*
    *Method updateLastMembGiftOnAccount
    *@description : Method to update Last_Membership_Gift__c on Account
    */ 
    public static Map<Id, Account> updateLastMembGiftOnAccount(Map<Id,Id> mapAccIdTooppId, Map<Id, Account> mapUpdateAccounts) {
        
        for(Id acc: mapAccIdTooppId.KeySet()) {
            Account updateacc = new Account(Id = acc, Last_Membership_Gift__c = mapAccIdTooppId.get(acc)); 
            mapUpdateAccounts.put(acc, updateacc);
        }
        
        return mapUpdateAccounts;
    }
    
    /*
    Method updateRenewableFieldonAccount
    @description : Method to update the renewableFieldonAccount
    */
     public static Map<Id, Account> updateRenewableFieldonAccount(Set<Id> accountIds, Map<Id, Account> mapUpdateAccounts) {
        for(Id acc: accountIds) {
            if(mapUpdateAccounts.get(acc) != null) {
                Account uacc = mapUpdateAccounts.get(acc);
                uacc.Has_Renewed_Before__c = true;
                mapUpdateAccounts.put(acc, uacc);
            }
            else {
                Account updateacc = new Account(Id = acc, Has_Renewed_Before__c = true); 
                mapUpdateAccounts.put(acc, updateacc);
            }
        }
        return mapUpdateAccounts;
     }
     
     /*
    Method updateJointMembershipFlagonAccount
    @description : Method to update Joint Membership Flag on Account
    */
     public static Map<Id, Account> updateJointMembershipFlagonAccount(List<Account> listOfAccounts, Map<Id, Account> mapUpdateAccounts) {
         for(Account theAccount : listOfAccounts) {
            if(mapUpdateAccounts.get(theAccount.Id) != null) {
                Account uacc = mapUpdateAccounts.get(theAccount.Id);
                uacc.Joint_Membership_Flag__c = true;
                mapUpdateAccounts.put(theAccount.Id, uacc);
            }else{
                mapUpdateAccounts.put(theAccount.Id, new Account(Id = theAccount.Id, Joint_Membership_Flag__c = true));
            }
        }
        return mapUpdateAccounts;
     }
}