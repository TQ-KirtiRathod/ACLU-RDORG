/*
*
*Name  :  UpdateCountAndAmountOnBatchLog_Schedule
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  June 08, 2017
*Purpose : Scheduler Class to Update Count and Amount fields on Batch Log.
*
*/
global class UpdateCountAndAmountOnBatchLog_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new UpdateCountAndAmountOnBatchLog_Batch(), 200);
  }

}