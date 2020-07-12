/*
*
*Name  :  BatchUploadGateKeeperbatch_Schedule
*Author:  Appirio India (Sai)
*Date  :  April 27, 2017
*Purpose : Scheduler Class to Prioritise the Batch Upload records.
*
*/
global class BatchUploadGateKeeperbatch_Schedule implements Schedulable {
    /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    /* Modified By :: roundCorner Inc. :: 09/17/2018
     * Description :: Created a new GateKeeper batch to control the batch upload flow for processing. 
     * Here, using a switch to execute the old batch upload functionality vs modified GateKeeper Batch
     * Switch :: Custom Setting :: batchUploadGateKeeperSettings.Run_New_GateKeeper_Batch__c
     * If true execute new else older batch functionality
    */
    BatchUploadGateKeeper_Settings__c batchUploadGateKeeperSettings = (BatchUploadGateKeeper_Settings__c.getInstance('Default') != null) 
                        ? BatchUploadGateKeeper_Settings__c.getValues('Default') : null ;
    Integer batchScope = batchUploadGateKeeperSettings != null && batchUploadGateKeeperSettings.Gatekeeper_Batch_Scope__c != null 
                            ? (Integer) batchUploadGateKeeperSettings.Gatekeeper_Batch_Scope__c : 200;

    if (batchUploadGateKeeperSettings != null && batchUploadGateKeeperSettings.Run_New_GateKeeper_Batch__c == false) {
        Id batchInstanceId = Database.executeBatch(new BatchUploadGateKeeper_batch(), batchScope);
    } else if(batchUploadGateKeeperSettings != null && batchUploadGateKeeperSettings.Run_New_GateKeeper_Batch__c == true) {
        Id batchInstanceId = Database.executeBatch(new BatchUploadGateKeeperNew_batch(), batchScope);
    }
  }
}