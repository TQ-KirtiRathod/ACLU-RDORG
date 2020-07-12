/*
*
*Name  :  AccountConstituentUpdater
*Author:  Appirio  (Tom Burre)
*Date  :  Nov 05, 2016
*Purpose : This class contains static methods for the Account object. 
*          1. Update All_Contacts_Deceased__c and Deceased_Contact__c on Accounts on the basis of deceased contacts. 
*          2. Update Acquisition_Source__c on Accounts from the related sb_Actions_Taken's Campaign's Source code
*
*/
public with sharing class AccountConstituentUpdater {


    //if all contacts in an account are deceased then set all contacts deceased field on Account to true else false
    public static void updateAccountAllContactsDeceased(Set<Id> setAccountId) {
        
        List<Account> accountListToUpdate = new List<Account>();
        
        if(setAccountId.size()>0){
            for(Account acc : [SELECT Id ,All_Contacts_Deceased__c ,
                               (SELECT Id,rC_Bios__Deceased__c FROM Contacts) 
                               FROM ACCOUNT 
                               WHERE ID IN: setAccountId ]){
                                   
                                   boolean allContactDeceased = true;
                                   boolean contactDeceased = false;
                                  //Traverse all contacts of an account when there are more than 1 contact in an account 
                                   if(acc.Contacts.size() >= 1){
                                       for(Contact con2 : acc.Contacts){
                                           // if any contact is not deceased ,set boolean variable false
                                           if(!con2.rC_Bios__Deceased__c){
                                               
                                               allContactDeceased = false; 
                                           }
                                           //if any contact is deceased , set boolean variable to true
                                           if(con2.rC_Bios__Deceased__c){
                                               contactDeceased = true; 
                                               
                                           }
                                           
                                                     
                                       }
                                        acc.All_Contacts_Deceased__c = allContactDeceased; 
                                        acc.Deceased_Contact__c = contactDeceased;
                                         accountListToUpdate.add(acc);
                                   }  //End of if(acc.Contacts.size() > 1)    
                                   
                                   //When there is only Contact associated with an account
                                   /*if(acc.Contacts.size() == 1){
                                       for(Contact con2 : acc.Contacts){
                                       //Set the boolean variable to true when contact is deceased
                                           if(con2.rC_Bios__Deceased__c){
                                               contactDeceased = true; 
                                               
                                           }
                                       }
                                       acc.Deceased_Contact__c = contactDeceased;
                                      accountListToUpdate.add(acc);
                                   }*/
                               }
            if(!accountListToUpdate.isempty()){
                try{
                //update the account list
                update accountListToUpdate; 
                } catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountConstituentUpdater','updateAccountAllContactsDeceased',e.getMessage());
                    log.logException(e);
                    log.saveLogs();
                }
            }
        }
    } 
    
    public static List<Account> updateAcquisitonSourceOnAccounts(List<Account> listOfAccountToProcess) {
      system.debug('listOfAccountToProcess '+listOfAccountToProcess);
      List<Account> listOfAccount = new List<Account>();
      set<Id> accountsIds = new set<Id>();
      set<Id>contactIds = new set<Id>();
      for(Account theAccount : listOfAccountToProcess) {
      accountsIds.add(theAccount.Id);
      if(theAccount.Contacts != null) {
        for(Contact theContact : theAccount.Contacts) {
          contactIds.add(theContact.Id);
        }
      }
      }
      map<Id,Opportunity> mapOfAccountIdVsOppId = new map<Id,Opportunity>();
      if(accountsIds != null) {
      for(Opportunity opp : [SELECT Id, Campaign.rC_Giving__Source_Code__c, CreatedDate,AccountId
                               FROM Opportunity
                               WHERE (RecordType.Name = 'Pledge' OR RecordType.Name = 'Donation')
                               AND AccountId IN : accountsIds
                               AND CampaignId != NULL
                               AND AccountId != NULL
                               ORDER BY CreatedDate ASC]) {
        if(!mapOfAccountIdVsOppId.containsKey(opp.AccountId)) {
          mapOfAccountIdVsOppId.put(opp.AccountId,opp);
          break;
        }
      }
      }
      
      map<Id,sb_Actions_Taken__c> mapOfAccountIdVsActionId = new map<Id,sb_Actions_Taken__c>();
      if(contactIds != null) {
          for(sb_Actions_Taken__c response : [SELECT Id, Campaign__r.rC_Giving__Source_Code__c, Contact__c, Contact__r.AccountId,CreatedDate
                                             FROM sb_Actions_Taken__c
                                             WHERE Contact__c IN : contactIds
                                             AND Campaign__c != NULL
                                             AND Contact__c != NULL
                                             ORDER BY CreatedDate ASC]) {
            if(!mapOfAccountIdVsActionId.containsKey(response.Contact__r.AccountId)) {
              mapOfAccountIdVsActionId.put(response.Contact__r.AccountId,response);
              break;
            }
          }
      }
      
      for(Account theAccount : listOfAccountToProcess) {
        if(theAccount.Acquisition_Source__c == NULL) {
          if(mapOfAccountIdVsActionId.containsKey(theAccount.Id) && mapOfAccountIdVsOppId.containsKey(theAccount.Id)) {
            theAccount.Acquisition_Source__c = mapOfAccountIdVsActionId.get(theAccount.Id).CreatedDate < mapOfAccountIdVsOppId.get(theAccount.Id).CreatedDate?
                                                (mapOfAccountIdVsActionId.get(theAccount.Id)).Campaign__r.rC_Giving__Source_Code__c
                                                : (mapOfAccountIdVsOppId.get(theAccount.Id)).Campaign.rC_Giving__Source_Code__c;
          }
          else if(mapOfAccountIdVsActionId.containsKey(theAccount.Id)) {
            theAccount.Acquisition_Source__c = mapOfAccountIdVsActionId.get(theAccount.Id).Campaign__r.rC_Giving__Source_Code__c;
          }
          else if(mapOfAccountIdVsOppId.containsKey(theAccount.Id)) {
            theAccount.Acquisition_Source__c = mapOfAccountIdVsOppId.get(theAccount.Id).Campaign.rC_Giving__Source_Code__c;
          }
        }
        listOfAccount.add(theAccount);
        system.debug('listOfAccount '+listOfAccount);
      }
      return listOfAccount;
    }
    
}