/*
*
*Name  :  BatchProcessOnEmail_Schedule
*Author:  Appirio India (Aashita Sharma)
*Date  :  March 09, 2018
*Purpose : Scheduler Class for BatchProcessOnEmail.
*
*/
global class BatchProcessOnEmail_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new BatchProcessOnEmail(), 200);
  }

}