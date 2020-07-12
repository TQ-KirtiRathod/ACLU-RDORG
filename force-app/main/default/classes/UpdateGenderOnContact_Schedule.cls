/*
*
*Name  :  UpdateGenderOnContact_Schedule
*Author:  Appirio India (Shikha Gupta)
*Date  :  April 19, 2017
*Purpose : Scheduler Class to update Gender On Contact Records.
*
*/
global class UpdateGenderOnContact_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new UpdateGenderOnContact_Batch(), 100);
  }

}