/*
*
*Name  :  BUP_Initiator_Schedule
*Author:  Appirio India (Sai Krishna)
*Date  :  July 04, 2017
*Purpose : Scheduler Class to BUP_Initiator
*
*/
global class BUP_Initiator_Schedule implements Schedulable {

  /****************************************************************************
   //Schedule batch class
  /***************************************************************************/
  global void execute(SchedulableContext SC) {
    new BUP_Initiator().execute(null);
    //BUP_Initiator_Schedule BUP_Initiator = new BUP_Initiator_Schedule();
    //String sch = '0 */3 * * *';
    //system.schedule('BUP_Initiator every 3hrs', sch, BUP_Initiator);
  }

}