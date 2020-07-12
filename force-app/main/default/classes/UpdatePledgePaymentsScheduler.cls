/*
*
*Name  :  UpdatePledgePaymentsScheduler
*Author:  Kirti Rathod(Salesforce.com) 
*Date  :  November 11, 2019
*Purpose : Scheduler Class to update pledge payments
*
*/
public with sharing class UpdatePledgePaymentsScheduler implements Schedulable{
/****************************************************************************
   //Schedule batch class
/***************************************************************************/
public void execute(SchedulableContext SC) {
    integer batchSize = Integer.ValueOf(System.Label.UpdatePledgePaymentsBatchScope);
    if(batchSize == null || batchSize == 0) {
        batchSize = 50;
    }
    Id batchInstanceId = Database.executeBatch(new UpdatePledgePaymentsBatch(), batchSize);
  }

}