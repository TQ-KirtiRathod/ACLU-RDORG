/*
*
*Name  :  TBD_BatchUpdateAccountAddress
*Author:  Appirio India (Aashita Sharma)
*Date  :  April 27, 2018
*Purpose : One Time Batch Run for updating accountaddress
*
*/
global class TBD_BatchUpdateAccountAddress implements Database.Batchable<sObject>{
    
    String queryString; 
    String accAddID = 'a02W000000Fqc9g';
    Id bupUserId;

    global TBD_BatchUpdateAccountAddress() {
        bupUserId = [SELECT ID FROM User WHERE Alias = 'buser' limit 1].Id;
        queryString = 'select id, createddate, createdby.Name, rC_Bios__Original_Postal_Code__c,rC_Bios__Account__c,rC_Bios__Address__c, kwrc__Zip_4__c,kwrc__Latitude__c,kwrc__Longitude__c,kwrc__ZDM_Location__Longitude__s,kwrc__ZDM_Location__Latitude__s ';
        queryString += 'from rC_Bios__Account_Address__c where  rC_Bios__Original_Postal_Code__c != null ';
        if(!test.isRunningTest()){
            queryString += 'and createdbyid =: bupUserId  and CreatedDate > 2018-03-10T00:00:00.00z'; 
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext Bc, List<sObject> scope){
        updateAccountAddress((List<rC_Bios__Account_Address__c>)scope);
    }
    
    
    global void finish(Database.BatchableContext Bc){ 
        
    }
    
    global void updateAccountAddress( List<rC_Bios__Account_Address__c> accAddList ){
        Set<Id> accountId = new Set<Id>();
        Set<ID> addressId = new Set<Id>();
        List<rC_Bios__Account_Address__c> lstAccountAddressToUpdate = new List<rC_Bios__Account_Address__c>();
        List<rC_Bios__Account_Address__c> lstAccountAddressToProcess = new List<rC_Bios__Account_Address__c>();
        for(rC_Bios__Account_Address__c acc : accAddList) {
          if(String.isNotBlank(acc.rC_Bios__Original_Postal_Code__c) && acc.rC_Bios__Original_Postal_Code__c.length() == 10 && acc.rC_Bios__Original_Postal_Code__c.substring(5,6) == '-') {
              accountId.add(acc.rC_Bios__Account__c);
              addressId.add(acc.rC_Bios__Address__c);
              lstAccountAddressToProcess.add(acc);
          }
        }
        map<Id, map<Id, rC_Connect__Batch_Upload__c>> mapAccIdToMapAddIdToBatchUpload = new map<Id, map<Id, rC_Connect__Batch_Upload__c>>();
        for(rC_Connect__Batch_Upload__c bu : [SELECT ID,kwrc__Zip_4__c,kwrc__Latitude__c,kwrc__Longitude__c,kwrc__ZDM_Location__Longitude__s, CreatedDate,
                                                     kwrc__ZDM_Location__Latitude__s, rC_Connect__Batch_Upload_Account_Matched__c,rC_Connect__Batch_Upload_Address_Matched__c
                                              FROM   rC_Connect__Batch_Upload__c
                                              WHERE  rC_Connect__Batch_Upload_Account_Matched__c IN: accountId 
                                              AND    rC_Connect__Batch_Upload_Address_Matched__c IN: addressId Order by CreatedDate]) {
            if(!mapAccIdToMapAddIdToBatchUpload.containsKey(bu.rC_Connect__Batch_Upload_Account_Matched__c) && bu.rC_Connect__Batch_Upload_Account_Matched__c != null
                && bu.rC_Connect__Batch_Upload_Address_Matched__c != null) {
                mapAccIdToMapAddIdToBatchUpload.put(bu.rC_Connect__Batch_Upload_Account_Matched__c, new map<Id, rC_Connect__Batch_Upload__c>());
                mapAccIdToMapAddIdToBatchUpload.get(bu.rC_Connect__Batch_Upload_Account_Matched__c).put(bu.rC_Connect__Batch_Upload_Address_Matched__c, bu);
            }
            
        }
        
        for(rC_Bios__Account_Address__c accAdd : lstAccountAddressToProcess) {
            if(mapAccIdToMapAddIdToBatchUpload.containsKey(accAdd.rC_Bios__Account__c)){
                accAdd.kwrc__Zip_4__c = mapAccIdToMapAddIdToBatchUpload.get(accAdd.rC_Bios__Account__c).get(accAdd.rC_Bios__Address__c).kwrc__Zip_4__c;
                accAdd.kwrc__Latitude__c = mapAccIdToMapAddIdToBatchUpload.get(accAdd.rC_Bios__Account__c).get(accAdd.rC_Bios__Address__c).kwrc__Latitude__c;
                accAdd.kwrc__Longitude__c = mapAccIdToMapAddIdToBatchUpload.get(accAdd.rC_Bios__Account__c).get(accAdd.rC_Bios__Address__c).kwrc__Longitude__c;
                accAdd.kwrc__ZDM_Location__Longitude__s = mapAccIdToMapAddIdToBatchUpload.get(accAdd.rC_Bios__Account__c).get(accAdd.rC_Bios__Address__c).kwrc__ZDM_Location__Longitude__s;
                accAdd.kwrc__ZDM_Location__Latitude__s = mapAccIdToMapAddIdToBatchUpload.get(accAdd.rC_Bios__Account__c).get(accAdd.rC_Bios__Address__c).kwrc__ZDM_Location__Latitude__s;
                accAdd.ZDM_Processing_Status__c = 'To ZDM';
                lstAccountAddressToUpdate.add(accAdd);
            }
        }
        
        List<Database.SaveResult> opResults = new  List<Database.SaveResult>();
        if(!lstAccountAddressToUpdate.isEmpty()) {
            opResults = database.update(lstAccountAddressToUpdate, false);
        }
        Utilities.processResults(opResults, lstAccountAddressToUpdate, 'AcctAddressUpdateFAIL', '', 'execute error:: ');
        
    }
    
}