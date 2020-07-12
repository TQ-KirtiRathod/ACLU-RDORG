/*
*
*Name  :  CampaignSkewFinder_Schedule
*Author:  Appirio India (Sai Krishna)
*Date  :  June 12, 2017
*Purpose : Scheduler Class For CampaignSkewFinder_Batch ApexClass
*
*/
global class CampaignSkewFinder_Schedule implements Schedulable {
  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new CampaignSkewFinder_Batch(), 1);
  }
}