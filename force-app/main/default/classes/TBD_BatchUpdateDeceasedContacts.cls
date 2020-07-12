/*
*
*Name  :  TBD_BatchUpdateDeceasedContacts
*Author:  Appirio India (Aashita Sharma)
*Date  :  April 12, 20178
*Purpose : Batch class to deactivate deceased contacts for one time run
*
*/
global without sharing class TBD_BatchUpdateDeceasedContacts implements Database.Batchable<sObject>{
    global set<Id> contactIds;
    global set<Id> IdSet;
    String queryString; 
    private static final String CONTACT_RT_HOUSEHOLD_Id = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    private static final String CONTACT_RT_ORG_Id = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Organizational').getRecordTypeId();

    global TBD_BatchUpdateDeceasedContacts(String runSegment) {
        If(runSegment=='Secondary'){
            queryString = 'select id, rC_Bios__Active__c, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, rC_Bios__Deceased__c '
                    + 'from contact '
                    + 'where rC_Bios__Deceased__c = true '
                    + 'and rC_Bios__Secondary_Contact__c = true'; 
        }Else if(runSegment=='Primary'){
            queryString = 'select id, rC_Bios__Active__c, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, rC_Bios__Deceased__c '
                    + 'from contact '
                    + 'where rC_Bios__Deceased__c = true '
                    + 'and rC_Bios__Preferred_Contact__c = true'; 
        }Else if(runSegment=='All'){
            queryString = 'select id, rC_Bios__Deceased__c '
                        + ' from contact '
                        + ' where rC_Bios__Deceased__c = false '
                        + ' and recordtypeid in (:CONTACT_RT_HOUSEHOLD_Id, :CONTACT_RT_ORG_Id)'
                        + ' and lastmodifieddate <= 2018-05-01T00:00:00Z'
                        + ' and rC_Bios__Birth_Year__c != \'0\' ';

        }
        system.debug(CONTACT_RT_HOUSEHOLD_Id);system.debug(CONTACT_RT_ORG_Id);
    }
    global TBD_BatchUpdateDeceasedContacts(Set<Id> ids) {
        IdSet = new Set<Id>(ids);

        queryString = 'select id, rC_Bios__Active__c, rC_Bios__Preferred_Contact__c, rC_Bios__Secondary_Contact__c, rC_Bios__Deceased__c '
                    + 'from contact '
                    +' where ID = :IdSet';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('Query :: ' + queryString);
        system.debug('ids :: '+ IdSet);
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope){
        //system.debug('scope::  ' + scope.size());
        List<Database.SaveResult> opResults = new  List<Database.SaveResult>();
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact c: scope){
            if(c.rC_Bios__Deceased__c==true){
                c.rC_Bios__Active__c = false;
                c.rC_Bios__Preferred_Contact__c = false;
                c.rC_Bios__Secondary_Contact__c = false;
            }
            contactsToUpdate.add(c);
        }

        opResults = database.update(contactsToUpdate, false);
        integer i = 0; 
        set<String> messages; 
        apexLogHandler.apexLog log; 
        for (Database.SaveResult result : opresults) {
            messages = new set<String>();
            if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    if(!messages.contains(err.getMessage())) {
                        log = new apexLogHandler.apexLog('DeceasedContact','Update', scope[i].Id+' '+err.getMessage());   
                        messages.add(err.getMessage());
                    }
                }
            }
            i++;
        }
        if(log != null) {
        log.saveLogs();
        }

    }
    
    global void finish(Database.BatchableContext BC) {
    }
}