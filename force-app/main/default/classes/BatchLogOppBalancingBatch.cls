/*This batch class is used to balance opportunity based on batch log*/
public class BatchLogOppBalancingBatch implements Database.Batchable<sObject>, Database.stateful {
   	public String query = '';
    public List<Id> batchLogIdSet = new List<Id>();
    public DateTime startDate;
    public DateTime endDate;
    //constructor takes dynamic query as parameter
    public BatchLogOppBalancingBatch(String query) {
        this.query = query;
    }
    //constructor takes set of batchLog ids as parameter
    public BatchLogOppBalancingBatch(List<Id> batchLogIdSet) {
        this.batchLogIdSet = batchLogIdSet;
        System.debug(batchLogIdSet);
      
        query = 'SELECT Id, rC_Connect__Giving_Giving_Amount__c, rC_Connect__Batch_Upload_Giving_Matched__c,'+
            	'rC_Connect__Batch_Upload_Giving_Matched__r.recordtypeid,rC_Connect__Batch_Upload_Giving_Matched__r.recordtype.name,'+
            	'Batch_Log__c, Batch_Log__r.Batch_Date__c,Batch_Log__r.Expected_Amount__c, Batch_Log__r.Expected_Count__c FROM rC_Connect__Batch_Upload__c'+ 
            	' WHERE Batch_Log__c IN :batchLogIdSet';
        
    }
    //constructor takes date range as parameter
    public BatchLogOppBalancingBatch(Date startDate , Date endDate) {
        this.batchLogIdSet = new List<Id>();
        this.startDate = datetime.newInstance(startDate, Time.newInstance(0,0,0,0));
        this.endDate =  datetime.newInstance(endDate, Time.newInstance(23,59,59,59));
        System.debug('this.startDate :: ' + this.startDate);
        System.debug('this.endDate :: ' + this.endDate);
        query = 'SELECT Id, rC_Connect__Giving_Giving_Amount__c, rC_Connect__Batch_Upload_Giving_Matched__c,'+
            	'Batch_Log__r.Batch_Date__c,rC_Connect__Batch_Upload_Giving_Matched__r.recordtypeid,rC_Connect__Batch_Upload_Giving_Matched__r.recordtype.name,'+
            	'Batch_Log__c, Batch_Log__r.Expected_Amount__c, Batch_Log__r.Expected_Count__c FROM rC_Connect__Batch_Upload__c'+ 
            	' WHERE Batch_Log__r.createdDate > = :startDate AND Batch_Log__r.createdDate <= :endDate';
    }
    //Start method to query the data
    public Database.QueryLocator start(Database.BatchableContext Bc ){
         system.debug(query);
         return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext Bc, List<rC_Connect__Batch_Upload__c > buList){
        Set<Id> buOppIds = new Set<Id>();
        Set<Id> blId = new Set<Id>();
       
        Map<String, rC_Connect__Batch_Upload__c> buMap = new Map<String, rC_Connect__Batch_Upload__c>(); 
        //Prepare a map of batchUploadId  Vs batchLogId
        Map<id,id> batchGivingIdMap = new Map<id,id>();
        //Prepare a map of batchId Vs batchDate
        Map<id,Date> batchLogMap = new Map<id,Date>();

        for(rC_Connect__Batch_Upload__c bu: buList) {
            batchGivingIdMap.put(bu.rC_Connect__Batch_Upload_Giving_Matched__c,bu.Batch_Log__c);
            if(bu.Batch_Log__r != null && bu.Batch_Log__r.Batch_Date__c != null) {
                batchLogMap.put(bu.Batch_Log__c,bu.Batch_Log__r.Batch_Date__c);
            }
        }

        //Get the list of opportunities
        List<Opportunity> opsToUpdate = new List<Opportunity>([SELECT Id
                                                                    , rC_Giving__Giving_Amount__c
                                                                    , batch_Log__c
                                                                    , recordTypeId
                                                                    , Amount
                                                                    , rC_Giving__Parent__c
                                                                    , recordtype.name 
                                                                    , Batch_Log__r.Batch_Date__c
                                                                 FROM Opportunity 
                                                                WHERE closedate IN :batchLogMap.values()
                                                                  AND ((RecordType.Name IN ('Pledge Payment','Transaction') 
                                         					      AND rC_Giving__Parent__c IN :batchGivingIdMap.keySet())
                                          						   OR (RecordType.Name IN ('Donation')
                                                                  AND ID IN :batchGivingIdMap.KeySet()))
                                                                  AND Batch_Log__c = null
                                                                LIMIT 49999]);
        
        //Popultae the batch log and batch date on opportunity
        for(Opportunity op :opsToUpdate) {
            if(op.recordtype.name == 'Donation') {
                System.debug('Dt' +batchGivingIdMap.get(op.Id) );
                op.Batch_Log__c  = batchGivingIdMap.get(op.Id);
                op.Batch_Date__c = batchLogMap.get(batchGivingIdMap.get(op.Id));
                batchLogIdSet.add(op.Batch_Log__c);
            }
            else if(op.recordtype.name == 'Transaction' ||
               op.recordtype.name == 'Pledge Payment') {
               op.Batch_Log__c  = batchGivingIdMap.get(op.rC_Giving__Parent__c);
               op.Batch_Date__c = batchLogMap.get(batchGivingIdMap.get(op.rC_Giving__Parent__c));
               batchLogIdSet.add(op.Batch_Log__c);
            }
        }

        //Update the opportunity
        if(opsToUpdate != null && opsToUpdate.size() > 0 ) {
            update opsToUpdate;
        }

        if(batchLogIdSet.size() > 0) {
            Recalculate_ActualAmountsCounts_BatchLog.calculateAmounts(batchLogIdSet);
        }

    }
    //Finsh method calls the batch class
    public void finish(Database.BatchableContext Bc){
        
    }
}