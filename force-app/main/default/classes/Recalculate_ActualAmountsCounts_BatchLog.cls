/*
*
*Name  :  Recalculate_ActualAmountsCounts_BatchLog
*Author:  Appirio India (Sai Krishna)
*Date  :  July 14, 2017
*Purpose : Controller Class for Recalculate_ActualAmountsCounts_BatchLog.
*          Class recalculates the Actual Count and Amount on the Batch Log record, can pass in ID or query for open Batch Log records
*          Called from button on Batch Log record
*
*/
global class Recalculate_ActualAmountsCounts_BatchLog  implements Schedulable{
     
    global void execute(SchedulableContext SC) {
        Recalculate_ActualAmountsCounts_BatchLog.calculateAmounts(new List<Id>());
    }
    
    public static void calculateAmounts(Id batchLogId){
        List<Id> batchLogIdLst = new List<Id>();
        batchLogIdLst.add(batchLogId);
        calculateAmounts(batchLogIdLst);
    }
    public static void calculateAmounts(List<Id> batchLogIdLst){
         String query ;
         Map<String,Schema.RecordTypeInfo> batchLogRTMap =  Schema.SObjectType.batch_Log__c.getRecordTypeInfosByName();
         Id vendorRcdTypeId = batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_VENDOR).getRecordTypeId();
         Id OPP_RT_DONATION_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
         Id OPP_RT_PLEDGE_PAYMENT_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
         Map<Id,Batch_Log__c> batchLogMap = new Map<Id,Batch_Log__c>();
         if(batchLogIdLst.size() == 0){
               query = 'SELECT Id,rC_Giving__Giving_Amount__c,batch_Log__c, recordTypeId, Amount FROM Opportunity ';
                query += ' WHERE batch_Log__c != null AND Batch_Log__r.Batch_Log_Status__c = \'Open\''; 
                query += ' AND Batch_Log__r.recordTypeId =: vendorRcdTypeId';
                query += ' AND (RecordTypeId =: OPP_RT_DONATION_ID OR RecordTypeId =: OPP_RT_PLEDGE_PAYMENT_ID)';
         }
         else{
            query = 'SELECT Id,rC_Giving__Giving_Amount__c,batch_Log__c, recordTypeId, Amount FROM Opportunity ';
            query += ' WHERE batch_Log__c != null AND Batch_Log__r.Batch_Log_Status__c = \'Open\' AND Batch_Log__c IN:batchLogIdLst'; 
            query += ' AND Batch_Log__r.recordTypeId =: vendorRcdTypeId';
            query += ' AND (RecordTypeId =: OPP_RT_DONATION_ID OR RecordTypeId =: OPP_RT_PLEDGE_PAYMENT_ID)';
         }
        
        System.debug('batchLogIdLst' + batchLogIdLst);
        for(Opportunity objOpp: Database.query(query)){
                if((!batchLogMap.containsKey(objOpp.batch_Log__c))){ 
                    batch_log__c batchlogRec = new Batch_Log__c(id=objOpp.batch_Log__c, Actual_Amount__c = objOpp.RecordtypeId == OPP_RT_PLEDGE_PAYMENT_ID ? 
                                                                objOpp.Amount : objOpp.rC_Giving__Giving_Amount__c,Actual_Count__c = 1);
                    batchLogMap.put(objOpp.batch_Log__c, batchlogRec);
                }
                else{
                      
                    batch_log__c batchlogRec = batchLogMap.get(objOpp.batch_Log__c);
                    batchlogRec.Actual_Amount__c = (batchlogRec.Actual_Amount__c != null)?batchlogRec.Actual_Amount__c:0;
                    batchlogRec.Actual_Count__c = (batchlogRec.Actual_Count__c != null)?batchlogRec.Actual_Count__c:0;
                    if(objOpp.RecordtypeId != OPP_RT_PLEDGE_PAYMENT_ID) {
                        batchlogRec.Actual_Amount__c += (objOpp.rC_Giving__Giving_Amount__c != null)?objOpp.rC_Giving__Giving_Amount__c:0;
                    } else {
                        batchlogRec.Actual_Amount__c += (objOpp.Amount != null)?objOpp.Amount:0;
                    }
                    batchlogRec.Actual_Count__c += 1;
                    batchLogMap.put(objOpp.batch_Log__c, batchlogRec);
                }
        }
        if(!batchLogMap.values().IsEmpty()){
            try{
                update batchLogMap.values();
            }catch(exception e){
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('Recalculate_ActualAmountsCounts_BatchLog','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
            
        }
         
         
    }
    
    // Method to create Copy and Offsetting transaction records after Adjustment.
    webservice static void runAmountCalc(Id batchLogId) {
        Recalculate_ActualAmountsCounts_BatchLog.calculateAmounts(batchLogId);
    }
}