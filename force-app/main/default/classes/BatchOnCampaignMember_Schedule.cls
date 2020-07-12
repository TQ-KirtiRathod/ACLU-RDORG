/*
*
*Name  :  BatchOnCampaignMember_Schedule
*Author:  Appirio India (Aashita Sharma)
*Date  :  March 2018
*Purpose : Scheduler Class for BatchOnCampaignMember.
*
*/
global class BatchOnCampaignMember_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new BatchOnCampaignMember(), 100);
  }

}