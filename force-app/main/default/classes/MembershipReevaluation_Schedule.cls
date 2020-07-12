/*
*
*Name  :  MembershipReevaluation_Schedule
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Feb 17, 2017
*Purpose : Scheduler Class For MembershipReevaluation_Batch Batch ApexClass
*
*/
global class MembershipReevaluation_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new MembershipReevaluation_Batch(), 50);
  }

}