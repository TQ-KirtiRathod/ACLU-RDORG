/*
*
*Name  :  AccountNewHelperBatch_Schedule
*Author:  Appirio India (Shikha Gupta)
*Date  :  April 26, 2017
*Purpose : Scheduler Class to update Acquisition Source On Account Records.
*
*/
global class AccountNewHelperBatch_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new AccountNewHelperBatch(), 100);
  }

}