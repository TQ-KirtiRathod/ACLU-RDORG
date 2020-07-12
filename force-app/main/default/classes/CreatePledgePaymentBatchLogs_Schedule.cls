/*
*
*Name  :  CreatePledgePaymentBatchLogs_Schedule
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Jan 25, 2016
*Purpose : Scheduler Class to create Sustainer Pledge Payment Batch Logs Records.
*
*/
global class CreatePledgePaymentBatchLogs_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new CreatePledgePaymentBatchLogs_Batch(true), 50);
  }

}