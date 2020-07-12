/*
*
*Name  :  BUP_Initiator
*Author:  Appirio India (Sai Krishna)
*Date  :  July 04, 2017
*Purpose : Scheduler Class for BUP_CreateNewMatchingEventSchedulable.
*
*/
global with sharing class BUP_Initiator implements Schedulable {
    
    global void execute(SchedulableContext SC) {
    	new rC_BUP.BUP_CreateNewMatchingEventSchedulable().execute(null);
    }
}