/*
*
*Name  :  PopulateBatchLogOnTransactions_Schedule
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  Aug 17, 2017
*Purpose : Scheduler Class to for PopulateBatchLogOnTransactions_Batch
*
*/
global class PopulateBatchLogOnTransactions_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new PopulateBatchLogOnTranscations_Batch(), 50);
  }

}