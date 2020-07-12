/*
*
*Name  :  CampaignRollUpDeleteBatch_Schedule
*Author:  Appirio India (Aashita Sharma)
*Date  :  Mar 09, 2017
*Purpose : Scheduler Class for CampaignRollUpDeleteBatch.
*
*/
global class CampaignRollUpDeleteBatch_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new CampaignRollUpDeleteBatch(), 1000);
  }

}