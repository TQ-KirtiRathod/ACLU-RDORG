/*
*
*Name  :  TBD_BatchUpdateChapterOnAccounts
*Author:  Appirio India (Aashita Sharma)
*Date  :  April 12, 2018
*Purpose : Batch class to populate Chapter on Accounts for one time run
*
*/
global without sharing class TBD_BatchUpdateChapterOnAccounts implements Database.Batchable<sObject>{
    global set<Id> contactIds;
    String queryString; 
    global TBD_BatchUpdateChapterOnAccounts() {
        queryString = 'SELECT Id, Affiliation__c, Chapter__c,BillingPostalCode, Lock_Affiliation__c FROM Account';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        map<Account,String> accIdToBillingPostal = new map<Account,String>();
        map<String, String> mapBillingCodeToChapter = new map<String, String>();
        List<Account> lstAccountToUpdate = new List<Account>();
        for(Account acc : (List<Account>)scope) {
           if(acc.BillingPostalCode != null 
               && acc.BillingPostalCode.length() >=5 
               && acc.Chapter__c == null
               && acc.Lock_Affiliation__c == false 
               && acc.Affiliation__c != null) {
               accIdToBillingPostal.put(acc, acc.BillingPostalCode.substring(0,5));
           }
           else if(acc.Affiliation__c != null && acc.Chapter__c == null
                   && (acc.BillingPostalCode == null || acc.BillingPostalCode.length() < 5)){
             acc.Chapter__c = acc.Affiliation__c.substring(0,2) + 'A';
             lstAccountToUpdate.add(acc);
           } 
        }
        
        if(accIdToBillingPostal != null && accIdToBillingPostal.keyset() != null) {
            for(Zip_Affiliate__c obj: [SELECT Id, Chapter__c, Name FROM Zip_Affiliate__c WHERE name =: accIdToBillingPostal.Values()]){
                mapBillingCodeToChapter.put(obj.Name, obj.Chapter__c);
            }
        }
        
        for(Account acc : accIdToBillingPostal.keyset()) {
            String chp = '';
            
            if(acc.BillingPostalCode != null && mapBillingCodeToChapter.get(acc.BillingPostalCode) != null){
                chp = String.ValueOf(mapBillingCodeToChapter.get(acc.BillingPostalCode));
                if(chp.length() < 3){
                    acc.Chapter__c = chp;
                } else {
                    acc.Chapter__c = chp.substring(0,3);
                }
                lstAccountToUpdate.add(acc);
            } else {
              acc.Chapter__c = acc.Affiliation__c.substring(0,2) + 'A';
              lstAccountToUpdate.add(acc);
            }
          
        }
        
        List<Database.SaveResult> opResults = new  List<Database.SaveResult>();
        if(!lstAccountToUpdate.isEmpty()) {
            opResults = database.update(lstAccountToUpdate, false);
        }
        integer i = 0; 
        set<String> messages; 
        apexLogHandler.apexLog log; 
        for (Database.SaveResult result : opresults) {
            messages = new set<String>();
            if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    if(!messages.contains(err.getMessage())) {
                        log = new apexLogHandler.apexLog('AcctChptrUpdateFAIL','execute', scope[i].Id+' '+err.getMessage());   
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
        Datetime dt = System.now();
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('TBD_BatchUpdateChapterOnAccounts DONE at: ' + dt );
        log.saveLogs();
    }
}