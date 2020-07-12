//This is  scheduler to Schedule BUP Log Batch Class
public class BUPLogScheduler  implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Calling BUP Log Batch class
        rC_BUP__Batch_Upload_Framework_Settings__c bupFrameworkSetting = rC_BUP__Batch_Upload_Framework_Settings__c.getOrgDefaults();
        integer batchScope = 200;
        if(bupFrameworkSetting.BUPBatchLogBatchScope__c != null) {
           batchScope = integer.ValueOf(bupFrameworkSetting.BUPBatchLogBatchScope__c); 
        }
        Database.executeBatch(new BUPLogBatch(), batchScope); 
        
    } 
}