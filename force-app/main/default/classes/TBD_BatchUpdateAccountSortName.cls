/*
*
*Name  :  TBD_BatchUpdateAccountSortName
*Author:  Appirio India (Aashita Sharma)
*Date  :  April 17, 2018
*Purpose : Batch class to populate Sort_Name__c on Account  for one time run
*
*/
global class TBD_BatchUpdateAccountSortName implements Database.Batchable<sObject>{
    
    String queryString; 
    public static Id organizationId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    
    global TBD_BatchUpdateAccountSortName() {
        queryString = 'select id, RecordTypeID, rC_Bios__Preferred_Contact__c, rC_Bios__Preferred_Contact__r.LastName, rC_Bios__Preferred_Contact__r.FirstName, Name, Sort_Name__c ';
        queryString += 'from Account Where RecordTypeID =: organizationId OR RecordTypeID =: houseHoldId'; 
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext Bc, List<sObject> scope){
        updateAccountSortName((List<Account>)scope);
    }
    
    
    global void finish(Database.BatchableContext Bc){ 
        
    }
    
    global void updateAccountSortName( List<Account> accList ){
        
        
        List<Account> lstAccountToUpdate = new List<Account>();
        for(Account acc : accList) {
          if(acc.RecordTypeID == houseHoldId) {
                acc.Sort_Name__c = (acc.rC_Bios__Preferred_Contact__r.LastName!= '' && acc.rC_Bios__Preferred_Contact__r.LastName != null) ? String.ValueOf(acc.rC_Bios__Preferred_Contact__r.LastName): '' ;
                acc.Sort_Name__c += (acc.rC_Bios__Preferred_Contact__r.FirstName != '' && acc.rC_Bios__Preferred_Contact__r.FirstName != null) ? ', '+String.ValueOf(acc.rC_Bios__Preferred_Contact__r.FirstName): '';
          } else if (acc.RecordTypeID == organizationId) {
              acc.Sort_Name__c = acc.Name;
          }
          lstAccountToUpdate.add(acc);
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
                        log = new apexLogHandler.apexLog('AcctSortNameUpdateFAIL','', 'execute error:: '+accList[i].Id+' '+err.getMessage());   
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
    
}