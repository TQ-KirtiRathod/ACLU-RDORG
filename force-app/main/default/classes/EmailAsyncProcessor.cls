/*
*
*Name  :  EmailAsyncProcessor
*Author:  Appirio (Tom Burre)
*Date  :  May 28, 2017
*Purpose : Class to process Async Requests created for Email
*
*/
public with sharing class EmailAsyncProcessor {
  public list<Email__c> incomingObjs = new list<Email__c>();
  public AsyncRequest__c incomingRequest = new AsyncRequest__c();
  

  public EmailAsyncProcessor( AsyncRequest__c request ) {
    incomingRequest = request;
    list<ID> idsAfterSplit = incomingRequest.Params__c.split(',');

    // the FOR UPDATE gives the async processor control over the record so locking can't occur.
    incomingObjs = [SELECT ID, Opt_In__c, Primary__c,Contact__c,Email_address__c
                    FROM Email__c
                    WHERE ID IN :idsAfterSplit FOR UPDATE];
  }

  // Singe AsyncType method
  public void email_primarySet(){
    Set<Id> setOfEmailIds = new Set<Id>();
    Set<Id> setOfContactIds = new Set<Id>();
    for(Email__c obj:incomingObjs){
      if(obj.Email_address__c != null && obj.Contact__c != null) {
        setOfContactIds.add(obj.Contact__c); 
        setOfEmailIds.add(obj.Id);
      }
    }
    if(setOfContactIds != null) {
      setPrimaryEmails(setOfContactIds,setOfEmailIds);      
    }
  }

  // Maybe we just have this one method to "do it all" for a given object
  //    And if so, maybe you pass a map of "key=Event, value=ListOfIds"
  //    Then parse the map and run the order of operations you desire
  //  A bit more complex for sure.. but maybe worth it if you need to conserve AsyncApexJobs per 24hr, etc..
  
  
      public static void setPrimaryEmails(Set<Id> setOfContactIds, Set<Id> emailObjIds) {
        List<Email__c> listOfEmails = new List<Email__c>();
        List<Contact> contactListToUpdate = new List<Contact>();
        for(Email__c theEmail : [SELECT Id, Contact__c, Email_address__c, Primary__c
                                    FROM Email__c 
                                    WHERE (Primary__c = TRUE 
                                        AND Contact__c IN : setOfContactIds)
                                        OR ID IN: emailObjIds]) {
            if(!emailObjIds.contains(theEmail.Id) && theEmail.Primary__c == TRUE ) {
              theEmail.Primary__c = False;
              listOfEmails.add(theEmail);
            } else if(emailObjIds.contains(theEmail.Id)) {
                if( theEmail.Primary__c == TRUE ){
                    contactListToUpdate.add( new Contact(Id= theEmail.Contact__c,
                                                rC_Bios__Home_Email__c = theEmail.Email_address__c,
                                                rC_Bios__Preferred_Email__c = 'Home'));
                } else {
                    contactListToUpdate.add( new Contact(Id= theEmail.Contact__c,
                                                rC_Bios__Home_Email__c = NULL,
                                                rC_Bios__Preferred_Email__c = NULL));
                }
            }
        }
        EmailTriggerHandler.asyncFunctionCalled = TRUE;
        update listOfEmails;
        EmailTriggerHandler.asyncFunctionCalled = False;
        update contactListToUpdate;
    }

}