/*
*
*Name  :  UpdateGenderOnContact_Batch
*Author:  Appirio India (Shikha Gupta)
*Date  :  April 18, 2017
*Purpose : Batch Class to update Gender field on Contact
*
*/
global class UpdateGenderOnContact_Batch implements Database.Batchable<sObject>{
   global UpdateGenderOnContact_Batch() {
   }

   global Database.QueryLocator start(Database.BatchableContext Bc ){
     DateTime dt = DateTime.now()-2;
     DateTime ndt = DateTime.now()-1;
     return Database.getQueryLocator([SELECT Id, FirstName,rC_Bios__Gender__c,Salutation, AccountID
                                      FROM Contact
                                      WHERE CreatedDate >=: dt
                                      AND CreatedDate <: ndt
                                      AND rC_Bios__Gender__c = NULL]);
   }

   global void execute(Database.BatchableContext Bc, List<Contact> scope){
       Set<Id> scopeAcctIds = new Set<Id>();
       
       Set<String> requiredFirstNames = new Set<String>();
       Map<String,String> mapOfFirstNameVsGenderCode = new Map<String,String>();
       List<Contact> listOfContactsToUpdate = new List<Contact>();
       for(Contact theContact : scope){
           requiredFirstNames.add(theContact.FirstName);
           scopeAcctIds.add(theContact.AccountID);
       }

       //gets list of accounts that are in scope and being processed by bup
       List<rC_Connect__Batch_Upload__c> inProcessBatchUpload = new List<rC_Connect__Batch_Upload__c>();
       inProcessBatchUpload = [
          SELECT id, rC_Connect__Batch_Upload_Status__c, rC_Connect__Batch_Upload_Account_Matched__c 
          FROM rC_Connect__Batch_Upload__c 
          WHERE rC_Connect__Batch_Upload_Status__c NOT IN ('Committed', 'Flagged')
          AND rC_Connect__Batch_Upload_Account_Matched__c IN :scopeAcctIds];
       Set<Id> bupAcctIds = new Set<Id>();
       if(inProcessBatchUpload.size()>0){
         for(rC_Connect__Batch_Upload__c bu : inProcessBatchUpload){
           bupAcctIds.add(bu.rC_Connect__Batch_Upload_Account_Matched__c);
         }
       }

       for(Gender_Names__c genderName : [SELECT Id, Name, Gender_Code__c,IsActive__c FROM Gender_Names__c 
                                         WHERE Name IN : requiredFirstNames AND IsActive__c = True]) {
         String gender = genderName.Gender_Code__c == 'M' ? 'Male' 
                         : (genderName.Gender_Code__c == 'F' ? 'Female' 
                          : (genderName.Gender_Code__c == 'U' ? 'Unknown' 
                           : null)
                         );
         mapOfFirstNameVsGenderCode.put(genderName.Name.toUpperCase(),gender);
       }
       //system.debug('mapOfFirstNameVsGenderCode' + mapOfFirstNameVsGenderCode);
       
       for(Contact theContact : scope){
         if(!bupAcctIds.contains(theContact.AccountId) ){
           if(theContact.rC_Bios__Gender__c == null) {
             theContact.rC_Bios__Gender__c = ((theContact.Salutation != null && theContact.Salutation == 'Mr.') 
                                           ? ('Male') 
                                           :( (theContact.Salutation != null && 
                                               (theContact.Salutation == 'Mrs.' || theContact.Salutation == 'Ms.' 
                                                || theContact.Salutation == 'Miss.')
                                               ) 
                                              ?('Female')
                                              :( (theContact.FirstName != null && mapOfFirstNameVsGenderCode!= null 
                                                  && mapOfFirstNameVsGenderCode.containsKey(theContact.FirstName.toUpperCase() )
                                                 ) 
                                                 ? (mapOfFirstNameVsGenderCode.get(theContact.FirstName.toUpperCase() ))
                                                 : (theContact.rC_Bios__Gender__c)
                                              )
                                            )
                                           );
             listOfContactsToUpdate.add(theContact);
           }
         }
         //else {system.debug('record skipped: accountid:: '+theContact.AccountId );} //for testing
       }

       if(!listOfContactsToUpdate.IsEmpty()){
           try{
            update listOfContactsToUpdate;
           } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('UpdateGenderOnContact_Batch','','execute :: ' + e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
       }

   }
   global void finish(Database.BatchableContext Bc){
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('UpdateGenderOnContact_Batch','', 'UpdateGenderOnContact_Batch FINISHED');
      log.saveLogs();
   }
}