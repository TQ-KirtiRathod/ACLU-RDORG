/*
*
*Name  :  MatchBatchLogViaBatchUpload_Schedule
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  July 18, 2017
*Purpose : Scheduler Class to for MatchBatchLogViaBatchUpload_Batch
*
*/
global class MatchBatchLogViaBatchUpload_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new MatchBatchLogViaBatchUpload_Batch(), 50);
  }

}