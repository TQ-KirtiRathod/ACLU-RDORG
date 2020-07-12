/*
*
*Name  :  AccountAsyncProcessor
*Author:  ACLU  (David Reed)
*Date  :  June 15, 2017
*Purpose : Class to process Async Requests created for Account. Contains method to set Email ist code and Opt in on Email preferences
*
*/
public with sharing class AccountAsyncProcessor {
  public AsyncRequest__c incomingRequest;
  @TestVisible
  private Map<Id, String> newAffiliationMap;
  @TestVisible
  private Map<Id, String> oldAffiliationMap;
  private Map<String, Set<String>> affiliationToEmailListCode;
  // Added
  public List<Account> AccountObjs = new List<Account>();
  //Ended

  public AccountAsyncProcessor() { }
    
  public AccountAsyncProcessor(AsyncRequest__c request) {
    incomingRequest = request;
    List<Map<Id, String>> inputData = (List<Map<Id, String>>)JSON.deserialize(incomingRequest.Params__c, List<Map<Id, String>>.class);

    newAffiliationMap = inputData[0];
    oldAffiliationMap = inputData[1];

    affiliationToEmailListCode = new Map<String, Set<String>> {}; 

    for(Email_Preference_List__c epl : [SELECT Affiliation__c, List_Code__c
                                       FROM Email_Preference_List__c 
                                       WHERE Is_Home_Affiliate_List__c = true]) {
       if(String.isNotBlank(epl.Affiliation__c) && !affiliationToEmailListCode.containsKey(epl.Affiliation__c)) {
           affiliationToEmailListCode.put(epl.Affiliation__c, new Set<String>());
       }

        if (String.isNotBlank(epl.List_Code__c)) {
            affiliationToEmailListCode.get(epl.Affiliation__c).add(epl.List_Code__c);
        }
    }
  }

  public void account_AffiliationChange() {
    // For any account that has changed affiliation, pull all of its contacts and ensure that any one that had
    // an active subscription to the email list for its old home affiliation is also opted in to the 
    // email list for its new affiliation.

    try {
        List<Email_Preference__c> newPreferences = new List<Email_Preference__c>();
        Set<String> emailListCodes = new Set<String>();

        for (String k : oldAffiliationMap.values()) {
            if (affiliationToEmailListCode.containsKey(k)) {
                emailListCodes.addAll(affiliationToEmailListCode.get(k));
            }
        }
        for (String k : newAffiliationMap.values()) {
            if (affiliationToEmailListCode.containsKey(k)) {
                emailListCodes.addAll(affiliationToEmailListCode.get(k));
            }
        }

        Set<Email__c> emailsToAdd = new Set<Email__c>();
        Map<Email__c, Set<Email_Preference__c>> emailsWithExisting = new Map<Email__c, Set<Email_Preference__c>>();

        // Query Email Preferences that are on a primary email address, for contacts affiliated with updated accounts,
        // where the email list code is one that we're interested in (either an old home affiliation email list
        // or a new home affiliation email list).

        // Accumulate two sets, where emailsToAdd is emails that had a qualifying subscription to old home affiliation email list
        // and emailsWithExisting is emails that already have a qualifying subscription to new home affiliation email list.
        // We'll subtract b from a to get our processing list.

        // We query all Email Preferences, even those that aren't opted-in, so we can upsert an existing but non-opted-in 
        // Email Preference for the new affiliate.

        for (Email_Preference__c c : [SELECT Email_List_Code__c, Email__r.Contact__r.AccountId, opt_In__c
                                      FROM Email_Preference__c 
                                      WHERE Email__r.Contact__r.AccountId IN :oldAffiliationMap.keySet()
                                            AND Email_List_Code__c IN :emailListCodes
                                            AND Email__r.opt_in__c = true
                                            AND Email__r.Primary__c = true
                                      FOR UPDATE]) {
            if (String.isNotBlank(oldAffiliationMap.get(c.Email__r.Contact__r.AccountId))
                && affiliationToEmailListCode.containsKey(oldAffiliationMap.get(c.Email__r.Contact__r.AccountId).left(2))
                && affiliationToEmailListCode.get(oldAffiliationMap.get(c.Email__r.Contact__r.AccountId).left(2)).contains(c.Email_List_Code__c)
                && c.opt_In__c == true) {
                // This Email has a qualifying Email Preference for the old home affiliation.
                // Note that we don't care if it has more than one such preference (emailsToAdd is a set)
                // We're also not going to check that it has *all* the available list memberships for the old home affil.

                emailsToAdd.add(c.Email__r);

            }

            if (affiliationToEmailListCode.containsKey(newAffiliationMap.get(c.Email__r.Contact__r.AccountId).left(2))
                && affiliationToEmailListCode.get(newAffiliationMap.get(c.Email__r.Contact__r.AccountId).left(2)).contains(c.Email_List_Code__c)) {
                // This email already has a qualifying Email Preference for the new home affiliation,
                // or has an existing Email Preference that we'll update to opted-in if it also has a qualifying preference for the old affiliation.
                // Note that if there are multiple Email Preference List codes for the new home affiliation,
                // we're going to do some additional tracking to make sure that all are added or upserted.
                if (!emailsWithExisting.containsKey(c.Email__r)) {
                  emailsWithExisting.put(c.Email__r, new Set<Email_Preference__c>());
                }

                emailsWithExisting.get(c.Email__r).add(c);
            }

        }

        // Iterate through the candidates for having their preference codes upserted
        for (Email__c e : emailsWithExisting.keySet()) {
          if (emailsToAdd.contains(e)) {
            // This email did have a qualifying preference for the old affiliation.
            // It also has at least one of the required preferences for the new affiliation.
            // Find all the required list codes for the new affiliation, then iterate
            // across the found new-affiliation preferences. Opt in any that exist and create
            // any that don't.
            Set<String> requiredListCodes = new Set<String>(affiliationToEmailListCode.get(newAffiliationMap.get(e.Contact__r.AccountId).left(2)));

            for (Email_Preference__c ep : emailsWithExisting.get(e)) {
              if (!ep.opt_In__c) {
                ep.opt_In__c = true;
                newPreferences.add(ep);
              }  

             requiredListCodes.remove(ep.Email_List_Code__c);
            }

            for (String lc : requiredListCodes) {
              newPreferences.add(new Email_Preference__c(Email__c = e.Id, Email_List_Code__c = lc, opt_In__c = true));
            }

            emailsToAdd.remove(e);
          }
        }

        // Add an Email Preference record for each email that qualifies for each list code for the new affiliation 
        // that hasn't already been covered.
        for (Email__c e : emailsToAdd) {
          if (affiliationToEmailListCode.containsKey(newAffiliationMap.get(e.Contact__r.AccountId))) {
            for (String lc : affiliationToEmailListCode.get(newAffiliationMap.get(e.Contact__r.AccountId))) {
                newPreferences.add(new Email_Preference__c(Email__c = e.Id, Email_List_Code__c = lc, opt_In__c = true));
            }
          }
        }

        upsert newPreferences;
    } catch(Exception e) {
        incomingRequest.Error__c = true;
        incomingRequest.Error_Message__c = e.getMessage();

        update incomingRequest;
    }
  }
    
    //Modified by :roundCorner Inc. 05-Dec-18 :: Ticket#61850
    //The intetion here to create a async request is to update account billing address if its blank and 
    //BU has the value in custom address fields
    public void account_CustomCommitAddress(AsyncRequest__c request) {
        System.debug('account_CustomCommitAddress :: request :: '+ request);
        try {
            //logic to update account address
            Map<String, String> inputParamMap = (Map<String, String>)JSON.deserialize(request.Params__c, Map<String, String>.class);
            Map<Id, rC_Connect__Batch_Upload__c> buIdToObjectMap = new Map<Id, rC_Connect__Batch_Upload__c> ([
                SELECT Id
                     , Custom_Zip_Code__c
                     , Custom_State__c
                     , Custom_City__c
                     , Custom_Country__c
                  FROM rC_Connect__Batch_Upload__c
                 WHERE Id IN :inputParamMap.keySet()
            ]); 

            Map<Id, Account> accIdToObjectMap = new Map<Id, Account>([
                SELECT Id
                     , BillingCity
                     , BillingCountry
                     , BillingPostalCode
                     , BillingState
                  FROM Account
                 WHERE Id IN :inputParamMap.values()
            ]); 

            Account[] accountUpdateableList = new Account[] { };

            for(Id buId :buIdToObjectMap.keySet()){
                Account account = accIdToObjectMap.get(inputParamMap.get(buId));
                rC_Connect__Batch_Upload__c batchUpload = buIdToObjectMap.get(buId);
                Boolean isAccountUpdated = false;

                if(String.isBlank(account.BillingCity) && String.isNotBlank(batchUpload.Custom_City__c)) {
                    account.BillingCity = batchUpload.Custom_City__c;
                    isAccountUpdated = true;
                }
                
                if(String.isBlank(account.BillingState) && String.isNotBlank(batchUpload.Custom_State__c)) {
                    account.BillingState = batchUpload.Custom_State__c;
                    isAccountUpdated = true;
                }
                
                if(String.isBlank(account.BillingPostalCode) && String.isNotBlank(batchUpload.Custom_Zip_Code__c)) {
                    account.BillingPostalCode = batchUpload.Custom_Zip_Code__c;
                    isAccountUpdated = true;
                }
                
                if(String.isBlank(account.BillingCountry) && String.isNotBlank(batchUpload.Custom_Country__c)) {
                    account.BillingCountry = batchUpload.Custom_Country__c;
                    isAccountUpdated = true;
                }
                
                if(isAccountUpdated == true) {
                    accountUpdateableList.add(account);
                }
            }//end for

            if(accountUpdateableList.size() > 0) {
                update accountUpdateableList;
            }
        } catch(Exception e) {
            incomingRequest.Error__c = true;
            incomingRequest.Error_Message__c = e.getMessage();

            update incomingRequest;
        }
    }
}