/*
*
*Name  :  OpportunityModifiedHelperBatch
*Author:  Appirio India (Lalit Bohra)
*Date  :  June 08, 2017
*Purpose : Batch class to populate RPT_Revenue_Type__c on Opportunity using PopulateRevenueType class. Currently not being used
*
*/
global class OpportunityModifiedHelperBatch implements Database.Batchable<sObject>{
    
   private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
   private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
   private static final String OPPORTUNITY_RT_TRANSACTION_Id;
   private static final String OPPORTUNITY_RT_PLEDGE_Id;
   private static final Set<String> setOfProgrmTypes = new Set<String>{'1','2','3','4','5'};
   static {
    opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
    OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
    OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
	OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
   }
   
   global OpportunityModifiedHelperBatch() {
   } 
   
   global Database.QueryLocator start(Database.BatchableContext Bc ){
    DateTime lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('OpportunityModifiedHelperBatch') != null && Last_Run_Time_Of_Batch__c.getValues('OpportunityModifiedHelperBatch').Last_Run_Time__c != null?
                           Last_Run_Time_Of_Batch__c.getValues('OpportunityModifiedHelperBatch').Last_Run_Time__c :
                           Date.Today();
     if( Last_Run_Time_Of_Batch__c.getInstance('OpportunityModifiedHelperBatch') == null) {
       Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'OpportunityModifiedHelperBatch',Last_Run_Time__c=System.now());
       insert cs;
     }
     else {
       Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('OpportunityModifiedHelperBatch');
       cs.Last_Run_Time__c = system.now();
       update cs;
     }
     
     return Database.getQueryLocator([Select Id, rC_Giving__Source_Code__c, Amount, RPT_Package_Code__c,Populate_Revenue_Type__c,
                                             RPT_Revenue_Type__c,Program_Type__c, Deposit_Site__c, Sharing_Code__c
                                      FROM Opportunity
                                      WHERE (RecordtypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id OR RecordtypeId =: OPPORTUNITY_RT_TRANSACTION_Id
                                             OR RecordtypeId =: OPPORTUNITY_RT_PLEDGE_Id)
                                      AND LastModifiedDate >: lastRunTime
                                      ]);
   }
   global void execute(Database.BatchableContext Bc, List<Opportunity> scope){
     List<Opportunity> listOfOpportunities = new List<Opportunity>();
     for(Opportunity opp : scope) {
       if(opp.Populate_Revenue_Type__c) {
         listOfOpportunities.add(opp);  
       }
     }
     List<Opportunity> listOfUpdatedOpportunity = PopulateRevenueType.populateRevenueType(listOfOpportunities);
       if(!listOfUpdatedOpportunity.IsEmpty()){
           try{
             update listOfUpdatedOpportunity;
           } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('OpportunityModifiedHelperBatch','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
       }

   }
   global void finish(Database.BatchableContext Bc){
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('OpportunityModifiedHelperBatch FINISHED');
      log.saveLogs();
   }
}