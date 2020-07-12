/*
*
*Name  :  BatchLogAsyncProcess
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  Feb 27, 2018
*Purpose : Class to Update BatchLog status to "Membership and Revenue Sharing Resets Needed" called from QueueableCentralProcessor
*
*/
public class BatchLogAsyncProcess {
    public List<Id> batchLogIds;
    public BatchLogAsyncProcess(AsyncRequest__c request) {
        batchLogIds = request.Params__c.split(',');
    }
    
    public void updateBatchLogStatus(){
        List<Batch_Log__c> listBatchLog = new List<Batch_Log__c>();
        for(Batch_Log__c log : [Select id, Batch_Log_Status__c,Error_Details__c FROM Batch_Log__c where id IN: batchLogIds]){
            log.Batch_Log_Status__c = 'Membership and Revenue Sharing Resets Needed';
            log.Error_Details__c =  '';
            listBatchLog.add(log);
        }
        if( listBatchLog.size() > 0){
            update listBatchLog;
        }
    }
}