/*
*
*Name  :  AccountModifiedHelperBatch_Schedule
*Author:  ACLU (David Reed)
*Date  :  June 21, 2017
*Purpose : Schedulable class for AccountModifiedHelperBatch
*
*/
global class AccountModifiedHelperBatch_Schedule implements Schedulable {
  global void execute(SchedulableContext sc) {
    Id batchInstanceId = Database.executeBatch(new AccountModifiedHelperBatch(), 100);
  }
}