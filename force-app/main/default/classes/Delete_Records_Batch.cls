/*
*Name  :  Delete_Records_Batch
*Author:  Appirio India (Sai Krishna )
*Date  :  April 03, 2017
*Purpose : Deletes the Account Address and Contact Address records whose MarkForDelete = true
*
*/
global with sharing class Delete_Records_Batch implements Database.Batchable<sObject>,Database.stateful{
    Public String query;
    Public Boolean isAccountAddress;
    //Constructor
    global Delete_Records_Batch(String query){
    	if(!String.IsBlank(query) && query.contains('rC_Bios__Account_Address__c')){
    		isAccountAddress = true;
    	}
    	else{
    		isAccountAddress = false;
    	}
        this.query = query;
    }//
    //Start
    global Database.QueryLocator start(Database.BatchableContext Bc ){
        return Database.getQueryLocator(query);
    }
    // Execute
    global void execute(Database.BatchableContext Bc, List<SObject> scope){
        List<Sobject> deleteAddress = new List<Sobject> ();
        for(Sobject obj: scope){
            deleteAddress.add(obj);
        }
        /*for(rC_Bios__Contact_Address__c obj: [SELECT Id FROM rC_Bios__Contact_Address__c WHERE Mark_For_Delete__c = true]){
            deleteAddress.add(obj);
        }*/
        
        if(!deleteAddress.IsEmpty() && deleteAddress != null){
            delete deleteAddress;
        }
    }
    
    // Finish 
     global void finish(Database.BatchableContext Bc){
        system.debug('Yes:'+isAccountAddress );
        if(isAccountAddress){
        	Database.executeBatch(new Delete_Records_Batch('SELECT Id FROM rC_Bios__Contact_Address__c WHERE Mark_For_Delete__c = true'));
        }
     }

}