/*
*Name  :  ZipAffiliateBatch
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 20, 2016
*Purpose : Batch process for updating account Chapter & Affiliation fields (T-547896)
*          Can run this when/if Zip Affiliate object data changes to reset chapter and affilate
*
*/
global class ZipAffiliateBatch implements Database.Batchable<sObject>, Schedulable {
    private String query = 'SELECT Name,Affiliation__c,Chapter__c,Affiliate_Changed__c,Chapter_Changed__c FROM Zip_Affiliate__c WHERE Chapter_Changed__c = True OR Affiliate_Changed__c = True' ;
    public static Id organizationId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    public static List<String> zipAffiliateName;
    public static List<Account> listAccount;
    public static Map<string,Zip_Affiliate__c> mapZipAffiliate;
    /*
* method implemented from Schedulable interface
*/
    global void execute(SchedulableContext sc) {
        Database.executebatch(this);
    }

    /*
*Start Method which retrieves the records of Account
*/
    global Database.QueryLocator start(Database.BatchableContext BC)  {

        return Database.getQueryLocator(query);
    }
    /*
* Execute Method
*It updates Affiliate and Chapter on Account
*if Zip Affilates and Chapter gets changed
*/
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        zipAffiliateName = new List<String>();
        listAccount = new List<Account>();
        mapZipAffiliate = new Map<String,Zip_Affiliate__c>();
        List<Zip_Affiliate__c> zipAffiliateRecords = (List<Zip_Affiliate__c>)scope;
        for(Zip_Affiliate__c zp : zipAffiliateRecords) {

            zipAffiliateName.add(zp.Name);
            mapZipAffiliate.put(zp.Name,zp);
        }
        for(Account acc : [SELECT Id,BillingPostalCode,Affiliation__c,Lock_Affiliation__c,Chapter__c
                           FROM Account
                           WHERE BillingPostalCode IN : zipAffiliateName
                           AND (RecordTypeId =: organizationId OR RecordTypeId =: houseHoldId )]) {

                               if(mapZipAffiliate.size()>0 && mapZipAffiliate.containsKey(acc.BillingPostalCode)) {

                                   if(acc.Lock_Affiliation__c == false) {
                                       acc.Affiliation__c = mapZipAffiliate.get(acc.BillingPostalCode).Affiliation__c;
                                   }
                                   acc.Chapter__c = mapZipAffiliate.get(acc.BillingPostalCode).Chapter__c;

                                   listAccount.add(acc);
                               }
        }
        if(listAccount.size()>0) {
            try{
                update listAccount;
            } catch(Exception e) {
                  apexLogHandler.apexLog log = new apexLogHandler.apexLog('ZipAffiliateBatch','execute',e.getMessage());
                  log.logException(e);
                  log.saveLogs();
            }
        }

    }

    /*
* Method for Finish
*/
    global void finish(Database.BatchableContext BC) {

    }


}