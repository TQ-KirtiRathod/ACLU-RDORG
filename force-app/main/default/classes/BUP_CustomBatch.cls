global class BUP_CustomBatch implements Database.Batchable<sObject>, rc_BUP.BUP_ProcessInterface {
	global Database.queryLocator start( Database.BatchableContext bc ) {
        String query = 'SELECT Id FROM Account LIMIT 10';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> eventList ) {
      system.debug('eventList :: ' + eventList);
    }
    
    global void finish( Database.batchableContext bc ) {
            
    }
    
    global void executeBatch(rC_BUP.BUF_BatchJobProcessor batchJobProcessor) {
        
    }
    
    global void start() {
        
    }
    
    global void initialize(List<rC_Connect__Batch_Upload__c> batchUploadList) {
        
    }
    
    global void preprocessQueue() {
        
    }
    
    global void invokeProcess() {
        
    }
    
    global void validate() {
        
    }
    
    global void updateQueue() {
        
    }
    
    
}