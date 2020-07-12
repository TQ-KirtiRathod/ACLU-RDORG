/*
*
*Name  :  PhoneAsyncProcessor
*Author:  Appirio India (Shikha Gupta)
*Date  :  June 01, 2017
*Purpose : Class to process Async Requests created for Phone to set primary phone for contact
*
*/
public with sharing class PhoneAsyncProcessor {
  public list<Phone__c> incomingObjs = new list<Phone__c>();
  public AsyncRequest__c incomingRequest = new AsyncRequest__c();
  
  // Added
  public list<Phone__c> PhoneObjs = new list<Phone__c>();
  //Ended

  public PhoneAsyncProcessor( AsyncRequest__c request ) {
    incomingRequest = request;
    list<ID> idsAfterSplit = incomingRequest.Params__c.split(',');

    // the FOR UPDATE gives the async processor control over the record so locking can't occur.
    incomingObjs = [SELECT Id,Contact__c,IsPrimary__c,Phone_Number__c
                    FROM Phone__c
                    WHERE ID IN :idsAfterSplit FOR UPDATE];
  }

  // Singe AsyncType method
  public void phone_primarySet(){
    Set<Id> setOfContactIds = new Set<Id>();
    set<Id> setOfPhoneIds = new set<Id>();
    for(Phone__c obj:incomingObjs){
      if(obj.Phone_Number__c != null && obj.Contact__c != null) {
        setOfContactIds.add(obj.Contact__c);
        setOfPhoneIds.add(obj.Id);
      }
    }
    if(setOfContactIds != null) {
      PhoneObjs = setPrimaryPhone(setOfContactIds, setOfPhoneIds);      
    }
  }

  // Maybe we just have this one method to "do it all" for a given object
  //    And if so, maybe you pass a map of "key=Event, value=ListOfIds"
  //    Then parse the map and run the order of operations you desire
  //  A bit more complex for sure.. but maybe worth it if you need to conserve AsyncApexJobs per 24hr, etc..
  
  
      public static List<Phone__c> setPrimaryPhone(Set<Id> setOfContactIds, set<Id> setOfPhoneIds) {
        List<Phone__c> listOfPhone = new List<Phone__c>();
        for(Phone__c thePhone : [SELECT Id FROM Phone__c WHERE IsPrimary__c = TRUE AND Contact__c IN : setOfContactIds]) {
            if(!setOfPhoneIds.contains(thePhone.Id)) {
              thePhone.IsPrimary__c = False;
              listOfPhone.add(thePhone);
            }
        }
        return listOfPhone;
    }

}