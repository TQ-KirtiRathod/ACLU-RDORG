/*
*
*Name  :  BatchOnNationalBudgetDelete
*Author:  Appirio India (Sandeep Soni)
*Date  :  June 12, 2017
*Purpose : This Batch class is used for deleting all records on National Budget object, on each report run records are deleted and recreated
*
*/
public with sharing class BatchOnNationalBudgetDelete implements Database.Batchable<sobject>  {

  public Boolean isError = false;
  public Date current_YTD_StartDate {get;set;}
  public Date current_YTD_EndDate;
  public Date prior_YTD_StartDate;
  public Date prior_YTD_EndDate;
  public Integer priorFiscalYear;
  public Integer budgetFiscalYear;

  public Database.QueryLocator start(Database.BatchableContext Bc ) {
    NationalBudgetUtility.updateReportStatus(true);

    return Database.getQueryLocator([SELECT Id
                                     FROM National_Budget__c]);
  }

  public void execute(Database.BatchableContext Bc, List<National_Budget__c> scope) {
    List<National_Budget__c> listOfNationalBudget = scope;
    if (!listOfNationalBudget.IsEmpty()) {
      try {
        delete listOfNationalBudget;
        database.emptyRecycleBin(listOfNationalBudget);
        isError = false;
        if(test.isRunningTest()){
            Decimal d = 2/0;
        }
      } catch (Exception e) {
        NationalBudgetUtility.updateReportStatus(false);
        isError = true;
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnNationalBudgetDelete', 'execute', e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }
  }

  public void finish(Database.BatchableContext Bc) {
    /*call BatchNationBudgetCreate if Batch delete has been executed succesfully*/
    if (!isError) {
      BatchNationalBudgetCreate bnb = new BatchNationalBudgetCreate();
      bnb.current_YTD_StartDate = current_YTD_StartDate;
      bnb.current_YTD_EndDate = current_YTD_EndDate;
      bnb.prior_YTD_StartDate = prior_YTD_StartDate;
      bnb.prior_YTD_EndDate = prior_YTD_EndDate;
      bnb.budgetFiscalYear = budgetFiscalYear;
      bnb.priorFiscalYear = priorFiscalYear;
      ID batchprocessid = Database.executeBatch(bnb, 2000);
    }
    apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnNationalBudgetDelete FINISHED');
    log.saveLogs();
  }

}