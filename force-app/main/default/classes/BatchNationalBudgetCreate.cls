/*
*
*Name  :  BatchNationalBudgetCreate
*Author:  Appirio India (Sandeep Soni)
*Date  :  December 12, 2017
*Purpose :  This Batch class is used for creating National Budget records based custom opportunity summarizations
            Groupings based on Budget Category and Budget Groupings based on NationalBudgetUtility class
            Sends user an email on completion"
*
*/
public with sharing class BatchNationalBudgetCreate implements Database.Batchable<sobject>, Database.stateful {

  private static Map<String, Schema.RecordTypeInfo> opptyRTMap; //record type maps
  private static Map<String, Schema.RecordTypeInfo> nationBudgetRTMap;
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
  private static final String OPPORTUNITY_RT_TRANSACTION_Id;
  private static final String OPPORTUNITY_RT_PLEDGE_Id;
  private static final String OPPORTUNITY_RT_SOFT_CREDIT_Id;
  private static final String NATIONAL_RT_UNBUDGET_Id;
  private static final String NATIONAL_RT_SUMMARY_Id;
  private static Organization orgInfo;
  private static String currentFiscalYear;

  public Date current_YTD_StartDate {get; set;}
  public Date current_YTD_EndDate {get; set;}
  public Date prior_YTD_StartDate {get; set;}
  public Date prior_YTD_EndDate {get; set;}
  public Integer priorFiscalYear {get; set;}
  public Integer budgetFiscalYear {get; set;}

  private Date startDatePriorFY;
  private Date endDatePriorFY;
  private List<National_Budget__c> listUnbudgeted;
  private Map<String, National_Budget__c> mapUpdateNationBudget;
  private Map<String, National_Budget_Amounts__c> mapnationBudget;
  /*for report*/
  public String c3NationBudgetReport;
  public String c4NationBudgetReport;
  public String nationBudgetSummaryReport;
  public String nationBudgetUnbudgetGiftReport;

  static {
    /*fetch record types*/
    opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
    nationBudgetRTMap = Schema.SObjectType.National_Budget__c.getRecordTypeInfosByName();
    OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
    OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
    OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
    OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
    NATIONAL_RT_UNBUDGET_Id = nationBudgetRTMap.get('Unbudgeted Gifts').getRecordTypeId();
    NATIONAL_RT_SUMMARY_Id =  nationBudgetRTMap.get('Summary').getRecordTypeId();

    //Determine current fiscal year
    orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
               FROM Organization WHERE id = :Userinfo.getOrganizationId()];
    /*Date todayDate = system.today();
    if (todayDate.month() >= orgInfo.FiscalYearStartMonth) {
      currentFiscalYear = String.valueOf(todayDate.year() + 1);
    } else currentFiscalYear = String.valueOf(todayDate.year());
    */
    currentFiscalYear = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year'
                         AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name;

  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    //system.debug('current_YTD_StartDate=  ' + current_YTD_StartDate + ' ::current_YTD_EndDate = ' +  current_YTD_EndDate );
    //system.debug('prior_YTD_StartDate=  ' + current_YTD_StartDate + ' ::prior_YTD_EndDate = ' +  current_YTD_EndDate );

    listUnbudgeted = new List<National_Budget__c>();
    mapUpdateNationBudget = new Map<String, National_Budget__c>();

    //set selection based on fiscal year
    integer endDateLastDay = Date.daysInMonth(integer.valueof(priorFiscalYear), orgInfo.FiscalYearStartMonth - 1);
    startDatePriorFY = Date.newInstance( integer.valueof(priorFiscalYear) - 1, orgInfo.FiscalYearStartMonth, 01);
    endDatePriorFY = Date.newInstance( integer.valueof(priorFiscalYear), orgInfo.FiscalYearStartMonth - 1, endDateLastDay);
    //system.debug('startDatePriorFY:: ' + startDatePriorFY + ' endDatePriorFY::' + endDatePriorFY );

    /*
    system.debug('testing:  ' + current_YTD_StartDate);
    if (current_YTD_StartDate != null)
      current_YTD_StartDate = Date.valueOf(String.valueOf(current_YTD_StartDate).subString(0, 10));
    if (current_YTD_EndDate != null)
      current_YTD_EndDate =   Date.valueOf(String.valueOf(current_YTD_EndDate).subString(0, 10));
    if (prior_YTD_StartDate != null)
      prior_YTD_StartDate =   Date.valueOf(String.valueOf(prior_YTD_StartDate).subString(0, 10));
    if (prior_YTD_EndDate != null)
      prior_YTD_EndDate =     Date.valueOf(String.valueOf(prior_YTD_EndDate).subString(0, 10));
    system.debug('testing2:  ' + current_YTD_StartDate);
    */

    List<National_Budget_Amounts__c> budgets = [Select Id, Fiscal_Year__c, Department_Code__c, 
                                                Budget_Category__c, Budget_Group__c, Budget_Amount__c 
                                                from National_Budget_Amounts__c];
    mapnationBudget = new Map<String, National_Budget_Amounts__c>();
    if(budgets.size()>0){
      for(National_Budget_Amounts__c budget: budgets){
        String fy = (budget.Fiscal_Year__c == null)?'':budget.Fiscal_Year__c;
        String deptcode = (budget.Department_Code__c == null)?'':budget.Department_Code__c;
        String buGroup = (budget.Budget_Group__c == null)?'':budget.Budget_Group__c;
        String bujcat = (budget.Budget_Category__c == null)?'':budget.Budget_Category__c;
        //String ref = fy+'-'+deptcode+'-'+bujcat;
        String ref = fy+'-'+buGroup+'-'+bujcat+'-'+deptcode;
        //system.debug('mapnationBudget::  '+ref);
        mapnationBudget.put( ref, budget);
      }
    }
    
    return Database.getQueryLocator([
      Select Id, rC_Giving__Account_Name__c,Amount, Program_Type__c, rC_Giving__Account_Number__c, 
        CloseDate,  Campaign.Package_Code__c, RPT_Package_Code__c,Sharing_Code__c, rC_Giving__Source_Code__c, Fund__c,
        Restriction__c, AccountId,  rC_Giving__Giving_Amount__c, Deposit_Site__c, Fundraising_Department__c, 
        Sharing_Code_Description__c, Related_Transaction__r.Fund__c, RecordTypeId
      FROM Opportunity 
      Where StageName = 'Completed' 
        AND Deposit_Site__c Like 'NA%'
        AND Amount > 0
        AND Program_Type__c IN ('1','2','4') 
        AND (
              ( RecordTypeId IN (:OPPORTUNITY_RT_PLEDGE_PAYMENT_Id,:OPPORTUNITY_RT_TRANSACTION_Id) 
              AND Exclude_from_Revenue_Sharing__c = False AND Adjustment_Code__c IN ('D','N')
              ) 
              OR RecordTypeId = :OPPORTUNITY_RT_SOFT_CREDIT_Id
            )
            //AND (CloseDate >= 2016-04-01 AND CloseDate <= 2014-05-01)
        AND ((CloseDate >= :startDatePriorFY AND CloseDate <= :endDatePriorFY)
              OR (CloseDate >= :current_YTD_StartDate AND CloseDate <= :current_YTD_EndDate)
            )
    ]);
  }


  public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
    //system.debug('size ' + scope.size());
    National_Budget__c nb = new National_Budget__c();
    Map<String, String> mapc3StaticBudget = new Map<String, String>();
    Map<String, String> mapc4StaticBudget = new Map<String, String>();
    mapc3StaticBudget = NationalBudgetUtility.getC3StaticBudgetData();
    mapc4StaticBudget = NationalBudgetUtility.getC4StaticBudgetData();
    String c3budgetCategory = null, c4budgetCategory = null;

    for (Opportunity opp : scope) {
      nb = new National_Budget__c();
      nb.Report_Details__c = 'Current YTD Start Date = '+ current_YTD_StartDate.format()+
                             '\r\n Current YTD End Date = '+current_YTD_EndDate.format()+
                             '\r\n Prior YTD Start Date = '+prior_YTD_StartDate.format()+
                             '\r\n Prior YTD End Date = '+prior_YTD_EndDate.format()+
                             '\r\n Prior Fiscal Year = '+priorFiscalYear+
                             '\r\n Budget Fiscal Year = '+ budgetFiscalYear;
      if (opp.Program_Type__c != null) { //this should always be the case
        c3budgetCategory = null;
        c4budgetCategory = null;

        //this is a data fix
        if(string.isBlank(opp.RPT_Package_Code__c) && !string.isBlank(opp.Campaign.Package_Code__c)){
          opp.RPT_Package_Code__c = opp.Campaign.Package_Code__c ;
        }
        //fund data fix for soft credits, get related transactions value
        if(opp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id){
          opp.Fund__c = opp.Related_Transaction__r.Fund__c;
        }

        //Populate nb record
        if (opp.Program_Type__c == '4') {
          nb.Tax_Designation__c = 'Foundation';
          c3budgetCategory = NationalBudgetUtility.fetchC3BudgetCategory(opp);
          nb.Budget_Category__c = c3budgetCategory;
          nb.Budget_Grouping__c = mapc3StaticBudget.get(c3budgetCategory);
        }
        /*validate program code is 1 or 2*/
        if (opp.Program_Type__c == '1' || opp.Program_Type__c == '2') {
          /*update tax designation filed with 'Union' string*/
          nb.Tax_Designation__c = 'Union';
          /*fetch static budget category data that is in key(Budget Category
          ) value(Code Budget Group) format */
          c4budgetCategory = NationalBudgetUtility.fetchC4BudgetCategory(opp);
          nb.Budget_Category__c = c4budgetCategory;
          nb.Budget_Grouping__c = mapc4StaticBudget.get(c4budgetCategory);
        }

        /*update fundraising department from opp's fundraising department*/
        nb.Fundraising_Department__c = opp.Fundraising_Department__c;

        if (opp.Amount == null) {
          opp.Amount = 0;
        }
        //system.debug('current_YTD_StartDate=  ' + current_YTD_StartDate );
        //system.debug('prior_YTD_StartDate=  ' + prior_YTD_StartDate + ' ::prior_YTD_EndDate = ' +  prior_YTD_EndDate );
        //system.debug('startDatePriorFY=  ' + startDatePriorFY + ' ::endDatePriorFY = ' +  endDatePriorFY );
        //System.debug('opp**'+opp.CloseDate);
        if (opp.CloseDate < prior_YTD_EndDate && opp.CloseDate > prior_YTD_StartDate) {
          nb.Previous_Year_Year_To_Date_Actual__c = opp.Amount;
        } else nb.Previous_Year_Year_To_Date_Actual__c = 0;
        
        if (opp.CloseDate < current_YTD_EndDate && opp.CloseDate > current_YTD_StartDate) {
          nb.Current_Year_Year_to_Date_Actual__c = opp.Amount;
        } else nb.Current_Year_Year_to_Date_Actual__c = 0;
        
        if (opp.CloseDate <= endDatePriorFY && opp.CloseDate >= startDatePriorFY) {
          nb.Previous_Year_Total_Year_Actual__c = opp.Amount;
        } else nb.Previous_Year_Total_Year_Actual__c = 0;

        /*update summary label field of national budget object.*/
        nb = NationalBudgetUtility.getSummaryLabel(opp, nb);

        /*validate budget category is unbudget*/
        if (nb.Budget_Category__c.startsWith('Unbudgeted')) {
          nb.RecordTypeId = NATIONAL_RT_UNBUDGET_Id;
          nb.Giving__c = opp.Id;
          nb.Budget_Grouping__c ='Unbudgeted';
        } else {
          /*set 'summary' record type on national budget record*/
          nb.RecordTypeId = NATIONAL_RT_SUMMARY_Id;
        }

        
        //setting budget value
        if ( !mapnationBudget.isEmpty() && nb.Budget_Category__c != null && nb.Budget_Grouping__c != null
            && mapnationBudget.containsKey(budgetFiscalYear+'-'+nb.Budget_Grouping__c+'-'+nb.Budget_Category__c
                                           +'-'+nb.Fundraising_Department__c) 
            ) {
          //system.debug('map value: '+mapnationBudget.get(currentFiscalYear+'-'+nb.Fundraising_Department__c+'-'+nb.Budget_Category__c).Budget_Amount__c );
          //system.debug('key value:  '+ budgetFiscalYear+'-'+nb.Budget_Grouping__c+'-'+nb.Budget_Category__c);
          nb.Current_Year_Total_Year_Budget__c = Double.valueOf(mapnationBudget.get(budgetFiscalYear+'-'+
                                                                nb.Budget_Grouping__c+'-'+nb.Budget_Category__c+'-'+
                                                                nb.Fundraising_Department__c).Budget_Amount__c);
        }
        //end Populate nm record


        //merge nb into map
        String key = nb.Tax_Designation__c+' - '+nb.Budget_Category__c+' - '+nb.Fundraising_Department__c;

        if ( !mapUpdateNationBudget.isEmpty() && mapUpdateNationBudget.containsKey(key)
            && !nb.Budget_Category__c.startsWith('Unbudgeted')) {
          mapUpdateNationBudget.get(key).Current_Year_Year_to_Date_Actual__c += nb.Current_Year_Year_to_Date_Actual__c;
          mapUpdateNationBudget.get(key).Previous_Year_Year_To_Date_Actual__c += nb.Previous_Year_Year_To_Date_Actual__c;
          mapUpdateNationBudget.get(key).Previous_Year_Total_Year_Actual__c += nb.Previous_Year_Total_Year_Actual__c;

        } else {
          if (nb.Budget_Category__c.startsWith('Unbudgeted')) {
            listUnbudgeted.add(nb);
          } else {
            mapUpdateNationBudget.put(key, nb);
          }
        }
        //system.debug('end mapUpdateNationBudget:  ' + mapUpdateNationBudget.size() + '  listUnbudgeted::' + listUnbudgeted.size());
      }

      if(listUnbudgeted.size()>9500){  //in case there are lots of unbudgeted, write record and reset
        try {
          /*insert unbudgeted*/
          insert listUnbudgeted;
          listUnbudgeted = new List<National_Budget__c>(); 
        } catch (Exception e) {
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchNationalBudgetCreate', 'execute', e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
      }
    } // end for
  }


  public void finish(Database.BatchableContext bc) {
    if (mapUpdateNationBudget.size() > 0) {
      try {
        /*insert National Budget Record*/
        insert mapUpdateNationBudget.values();
        insert listUnbudgeted;

        National_Budget_Report_Status__c nbrs = National_Budget_Report_Status__c.getOrgDefaults();
        //System.debug('in BatchNationCreate flag: '+nbrs);
        User activeUser = [Select Email From User where Username = :UserInfo.getUserName() limit 1];
        String userEmail = activeUser.Email;

        if (nbrs.Report_Request_In_Progress__c && nbrs.Sender_Email__c != null && nbrs.Sender_Email__c != '') {
          String senderEmail = nbrs.Sender_Email__c;
          /*Sending an email to logged in user that request for National Budget Report*/
          sendNBEmail('National Budget Report', senderEmail, userEmail, currentFiscalYear);
          NationalBudgetUtility.updateReportStatus(false);
        }
      } catch (Exception e) {
        /*If there is any IO Exception then we will reset the custom setting*/
        NationalBudgetUtility.updateReportStatus(false);
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchNationalBudgetCreate', 'execute', e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }

    apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchNationalBudgetCreate FINISHED');
    log.saveLogs();
  }


  private void sendNBEmail(String reportType, String fromAddress, String toAddress, String fYear ) {
    List<String> sendTo = new List<String>();
    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    if (fromAddress != null && toAddress != null) {
      sendTo.add(toAddress);
      mail.setReplyTo(fromAddress);

      mail.setToAddresses(sendTo);
      mail.setSenderDisplayName('Report Request');
      fetchReportURL();
      mail.setSubject('National Budget Report');
      String body = 'National Budget Report processing has been completed ';
      body += '<html><body>Access the report from the URL:';
      body += '<br/><br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + c3NationBudgetReport + '">C3 National Budget Report</a>';
      body += '<br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + c4NationBudgetReport + '">C4 National Budget Report</a>';
      body += '<br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + nationBudgetSummaryReport + '">National Budget Summary Report</a>';
      body += '<br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + nationBudgetUnbudgetGiftReport + '">National Budget Unbudget Gift Report</a>';
      body += '<br/><br/>If the link is not accessible please copy the below url in browser:';
      body += '<br/><br/>C3 National Budget Report: <b>' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + c3NationBudgetReport + '</b>';
      body += '<br/>C4 National Budget Report: <b>' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + c4NationBudgetReport + '</b>';
      body += '<br/>National Budget Summary Report: <b>' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + nationBudgetSummaryReport + '</b>';
      body += '<br/>National Budget Unbudget Gift Report: <b>' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' + nationBudgetUnbudgetGiftReport + '</b>';
      body += '</body></html>';

      mail.setHtmlBody(body);
      mails.add(mail);

    }
    //System.debug('mails:' + mails);
    if (!mails.IsEmpty()) {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);
      //system.debug('Mail:' + results);
    }
  }

  public void fetchReportURL() {
    List<Report> reports = [SELECT Id, Name FROM Report
                            where Name = 'C3 National Budget Report'
                              OR Name = 'C4 National Budget Report'
                              OR Name = 'National Budget Summary Report'
                              OR Name = 'National Budget Unbudgeted Gifts Report'
                              Limit 4];
    for (Report r : reports) {
      if (r.Name == 'C3 National Budget Report') {
        c3NationBudgetReport = r.Id;
      }
      if (r.Name == 'C4 National Budget Report') {
        c4NationBudgetReport = r.Id;
      }
      if (r.Name == 'National Budget Summary Report') {
        nationBudgetSummaryReport = r.Id;
      }
      if (r.Name == 'National Budget Unbudgeted Gifts Report') {
        nationBudgetUnbudgetGiftReport = r.Id;
      }
    }
  }

}