/*
*
*Name  :  WarmCacheForSomeReports_Schedule
*Author:  Appirio India (Tom Burre)
*Date  :  March 11, 2018
*Purpose : Scheduler Class to WarmCacheForSomeReports.
*
*/
global class WarmCacheForSomeReports_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    Id batchInstanceId = Database.executeBatch(new WarmCacheForSomeReports(Date.newInstance(2015,04,01)),1000);
  }

}