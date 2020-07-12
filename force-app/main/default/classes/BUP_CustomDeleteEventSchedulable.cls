/*
*
*Name  :  BUP_CustomDeleteEventSchedulable
*Author:  Niraj Shrikhande
*Date  :  Aug 22, 2017
*Purpose : This is a Schedulable class to schedule delete event batch
*
*/
global without sharing class BUP_CustomDeleteEventSchedulable implements Schedulable {
    global void execute(SchedulableContext SC) {
    	BUP_CustomDeleteEventSchedulerHandler.execute(SC);
    }
}