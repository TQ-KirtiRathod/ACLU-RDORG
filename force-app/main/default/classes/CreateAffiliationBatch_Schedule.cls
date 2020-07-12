/*
*
*Name  :  CreateAffiliationBatch_Schedule
*Author:  Appirio India (Sai Krishna)
*Date  :  Oct 26, 2017
*Purpose : Scheduler Class to for CreateAffiliationBatch_Schedule
*
*/
global class CreateAffiliationBatch_Schedule implements Schedulable {
    
  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new CreateAffiliationBatch(), 200);
  }
}