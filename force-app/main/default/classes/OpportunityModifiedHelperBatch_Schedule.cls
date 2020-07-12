/*
*
*Name  :  OpportunityModifiedHelperBatch_Schedule
*Author:  Appirio India (Shikha Gupta)
*Date  :  June 14, 2017
*Purpose : Scheduler Class to update Revenue Type On Opportunity Records.
*
*/
global class OpportunityModifiedHelperBatch_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new OpportunityModifiedHelperBatch(), 200);
  }

}