/*
*
*Name  :  Batch_SummaryReportGenerations
*Author:  Appirio India (Sai Krishna )
*Date  :  Februvary 16, 2017
*Purpose :  Generates the BatchSummary Report Data which is called from the Cash Reports tab for reports Credit Card Summary and Errors reports
            Class queries batch log and opportunity data, then summarizes them and writes the output to a Batch_Log_Summary__c object
*
*/
global class Batch_SummaryReportGenerations implements Database.Batchable<sObject>, Database.stateful {
  // RecordTypesIds
  private static final String OPPORTUNITY_RT_TRANSACTION_Id = 
        Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = 
        Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  private static final String OPPORTUNITY_RT_SOFT_CREDIT_Id = 
        Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();        
  private static final Map<String,Schema.RecordTypeInfo> batchLogSummaryRcdTypes = 
        Schema.SObjectType.Batch_Log_Summary__c.getRecordTypeInfosByName();
  
  public Set<string> bequestShareCodes = new Set<String> {'Q001', 'Q002', 'Q003', 'Q004', 'Q005', 
                                                          'U001', 'U002', 'U003', 'U004', 'U005'};

  private Date startDate;
  private Date endDate;
  private String selectedReportType;
  private List <Batch_Log_Summary__c> batchLogSummaries;
  //testing
  public Decimal testcounter;

  //Constructor
  global Batch_SummaryReportGenerations(Date StartDate, Date endDate, String selectedReportType) {
    this.startDate = startDate;
    this.endDate = endDate;
    this.selectedReportType = selectedReportType;
    batchLogSummaries = new List <Batch_Log_Summary__c>();
  }

  global Database.QueryLocator start(Database.BatchableContext Bc ) {
    testcounter = 0;
    return Database.getQueryLocator([
                                      SELECT Id, Batch_Log_Status__c, Deposit_Site__c, Name, Batch_Date__c, 
                                        Bank_Date__c, Payment_Subtype__c
                                      FROM Batch_Log__c
                                      WHERE Batch_Date__c >= : startDate
                                        AND Batch_Date__c <= : endDate
                                        AND Name LIKE 'NA%'
                                        //AND (Deposit_Site__c LIKE 'NA%' 
                                        //AND (name = 'NAFM130002' OR name = 'NAFM105006' OR name = 'NAUM115005' OR name = 'NAFM108006'
                                        //     OR name = 'NAFM125006' 
                                        //     OR name = 'NAFE1805240001')
                                        AND Batch_Log_Status__c = 'Balanced'
                                      ORDER BY Id
                                    ]);
  }

  global void execute(Database.BatchableContext Bc, List<Batch_Log__c> scope) {

    Map<Id, Set<Opportunity>> mapOfOppIdVsListOfOpportunity = new Map<Id, Set<Opportunity>>();
    Map<Id, Batch_Log__c> mapOfBatchLogIds = new Map<Id, Batch_Log__c>(scope);

    Map<Id, Opportunity> batchLogOpps = new Map<Id, Opportunity>([ 
        SELECT Id, Name, X50k_Gift__c, Is_Pledge_Payment__c, Deposit_Site_Code__c, rC_Giving__Payment_Method__c,
            Batch_Date__c, rC_Giving__Source_Code__c, Bank_Date__c, Deposit_Site__c, Batch_Log__c, Restriction__c,
            Sharing_Code__c, StageName, Program_Type__c, accountId, Campaign.rC_Giving__Channel__c, account.AccountNumber,
            rC_Giving__Parent__r.Program_Type__c, Batch_Log__r.Batch_Date__c, amount, RecordTypeId, RecordType.Name,
            Type, High_Amount__c, Low_Amount__c, Tax_Value__c, Tax_Date__c, rC_Giving__Account_Name__c, Payment_Subtype__c,
            Realized_Gain_Loss__c, Stock_Gift__c, rC_Giving__Ticker_Symbol__c, Account.Name
        FROM Opportunity
        WHERE StageName = 'Completed'
            AND Sharing_Code__c != null
            AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
            AND Adjustment_Code__c IN ('N', 'D')
            AND CloseDate >= :startDate
            AND CloseDate <= :endDate
            AND Amount > 0
            AND Batch_Log__c IN :mapOfBatchLogIds.KeySet()
        ]);
    //system.debug('batchLogOpps :: ' +batchLogOpps.size());

    //Gets soft credit records which contains the "real" sharing code
    List<Opportunity> SoftCreditSharingCodeOpps = [ 
              SELECT id, sharing_code__c,  Related_Transaction__c
              FROM Opportunity
              WHERE Related_Transaction__c IN :batchLogOpps.KeySet()
              //  AND RecordTypeId = :OPPORTUNITY_RT_SOFT_CREDIT_Id //not using due to migrated data
          ];
    //system.debug('SoftCreditSharingCodeOpps :: ' +SoftCreditSharingCodeOpps.size());

    Map<ID, String> softCreditSharingCode = new Map<ID, String>();
    for(Opportunity o : SoftCreditSharingCodeOpps){
      softCreditSharingCode.put(o.Related_Transaction__c, o.sharing_code__c);
    }

    for (Opportunity opp : batchLogOpps.values() ) {
      //Update the softcredit sharing code with actual sharing code
      if(opp.sharing_code__c == 'SOFTCREDIT' ){
        if(softCreditSharingCode.containsKey(opp.id) ){
          opp.sharing_code__c = softCreditSharingCode.get(opp.id);
        } else{
          Exceptionutils.createApexLog('Batch_SummaryReportGenerations','',null, 
            'SharingCode = SOFTCREDIT, missing Related Transaction :: '+ opp);
        }
      }

      if (!mapOfOppIdVsListOfOpportunity.containsKey(opp.Batch_Log__c)) {
        mapOfOppIdVsListOfOpportunity.put(opp.Batch_Log__c, new Set<Opportunity>());
      }
      mapOfOppIdVsListOfOpportunity.get(opp.Batch_Log__c).add(opp);
    }

    for (Batch_Log__c objbl : scope) {

      // variables collects based on groupings.
      map<String, Integer> mapsharingCodeToIncrement = new map<String, Integer> ();
      map<String, summaryWrapperClass> mapGroupingToWrapper = new map<String, summaryWrapperClass>();
      map<String, Integer> depositNumberToIncrement = new map<String, Integer>();
      String depositNumber;
      Opportunity updatedOpp;
      String depositSite = (objbl.Deposit_Site__c != null) ? String.ValueOf(objbl.Deposit_Site__c).subString(0, 3) : null;

      if (mapOfOppIdVsListOfOpportunity != null && mapOfOppIdVsListOfOpportunity.get(objbl.Id) != null) {
        integer i = 0;
        for (Opportunity opp : mapOfOppIdVsListOfOpportunity.get(objbl.Id)) {

          testcounter += opp.Amount;

          // not Bequest
          if (!bequestShareCodes.Contains(opp.Sharing_Code__c)) {
            //callout to GLGivingHelper for banking detail population
            updatedOpp = (GLGivingHelper.nationalGLCodeAssigner(opp).Size() > 0) ? GLGivingHelper.nationalGLCodeAssigner(opp)[0] : null;
            depositNumber = OpportunityGLedger.populateDepositNumber(opp).Deposit_Number__c;
            // this takes the grouping of BatchLogName, GLCode,FundCode, ResCode, FocusAreadCode and bank Date.
            String uniqueString = '';
            if (updatedOpp != null) {
              uniqueString = objbl.Name + '-' + depositNumber + '-' + updatedOpp.Fund_Code_National__c + '-' 
                           + updatedOpp.GL_Code_National__c + '-' + updatedOpp.Focus_Area_Code_National__c 
                           + '-' + updatedOpp.Responsibility_Center_Code_National__c + '-' 
                           + (opp.Bank_Date__c != null ? String.valueOf(Date.ValueOf((opp.Bank_Date__c)).Month()) : '');
            }

            if (updatedOpp != null && !String.isBlank(uniqueString) && !mapGroupingToWrapper.ContainsKey(uniqueString)) {
              mapGroupingToWrapper.put(uniqueString, 
                                       new summaryWrapperClass(opp.amount, 1, 
                                          Integer.ValueOf(opp.X50k_Gift__c), 
                                          Integer.ValueOf(opp.Stock_Gift__c), 
                                          opp.Is_Pledge_Payment__c,
                                          (opp.Campaign.rC_Giving__Channel__c == 'Canvassing'), 
                                          (opp.Payment_Subtype__c == 'Cash'),
                                          updatedOpp.Fund_Code_National__c, 
                                          updatedOpp.GL_Code_National__c, 
                                          updatedOpp.Focus_Area_Code_National__c,
                                          updatedOpp.Responsibility_Center_Code_National__c, 
                                          depositNumber, 
                                          updatedOpp.Bank_Date__c,
                                          updatedOpp.account.AccountNumber, 
                                          updatedOpp.Account.Name, 
                                          updatedOpp.recordType.Name,
                                          //field values are for the Error Report Hence these are null
                                          0.0, 0.0, 0.0, Date.Today(), null));
            } else if (!String.isBlank(uniqueString)) {
              summaryWrapperClass wrapRecord = mapGroupingToWrapper.get(uniqueString);
              wrapRecord.amount += opp.amount;
              wrapRecord.Count += 1;
              wrapRecord.X50KGifts += Integer.ValueOf(opp.X50k_Gift__c);
              wrapRecord.stockGifts += Integer.ValueOf(opp.Stock_Gift__c);
              if (opp.Is_Pledge_Payment__c == 'Y' && wrapRecord.Pledge == 'N') {
                wrapRecord.Pledge = 'Y';
              }

              if (opp.Campaign.rC_Giving__Channel__c == 'Canvassing' && wrapRecord.isCanvassing == false) {
                wrapRecord.isCanvassing = true;
              }

              if (opp.Payment_Subtype__c == 'Cash' && wrapRecord.isPaymentMethod == false) {
                wrapRecord.isPaymentMethod = true;
              }
              mapGroupingToWrapper.put(uniqueString, wrapRecord);
            }
          }
          //Bequest
          else {
            List<Opportunity> updatedOpps = (GLGivingHelper.nationalGLCodeAssigner(opp).Size() > 0) 
                                          ? GLGivingHelper.nationalGLCodeAssigner(opp) : null;
            if (updatedOpps != null) {
              for (Opportunity splitedOpp : updatedOpps) {
                depositNumber = OpportunityGLedger.populateDepositNumber(opp).Deposit_Number__c;
                // this takes the grouping of BatchLogName, GLCode,FundCode, ResCode, FocusAreadCode and bank Date.
                String uniqueString = objbl.Name + '-' + depositNumber + '-' + splitedOpp.Fund_Code_National__c + '-' 
                                    + splitedOpp.GL_Code_National__c + '-' + splitedOpp.Focus_Area_Code_National__c + '-' 
                                    + splitedOpp.Responsibility_Center_Code_National__c + '-' 
                                    + (opp.Bank_Date__c != null ? Date.ValueOf((opp.Bank_Date__c)).Month() : null);

                if (!mapGroupingToWrapper.ContainsKey(uniqueString)) {
                  mapGroupingToWrapper.put(uniqueString, 
                                           new summaryWrapperClass(splitedOpp.amount, 1, 
                                                                   Integer.ValueOf(Opp.X50k_Gift__c), 
                                                                   Integer.ValueOf(opp.Stock_Gift__c), 
                                                                   opp.Is_Pledge_Payment__c,
                                                                   (Opp.Campaign.rC_Giving__Channel__c == 'Canvassing'), 
                                                                   (opp.Payment_Subtype__c == 'Cash'),
                                                                   splitedOpp.Fund_Code_National__c, 
                                                                   splitedOpp.GL_Code_National__c, 
                                                                   splitedOpp.Focus_Area_Code_National__c,
                                                                   splitedOpp.Responsibility_Center_Code_National__c, 
                                                                   depositNumber, 
                                                                   opp.Bank_Date__c,
                                                                   splitedOpp.account.AccountNumber,
                                                                   splitedOpp.Account.Name,
                                                                   splitedOpp.recordType.Name,
                                           //field values are for the Error Report Hence these are null
                                                                   0.0, 0.0, 0.0, Date.Today(), null));

                } else {
                  summaryWrapperClass wrapRecord = mapGroupingToWrapper.get(uniqueString);
                  wrapRecord.amount += splitedOpp.amount;
                  wrapRecord.Count += 1;
                  wrapRecord.X50KGifts += Integer.ValueOf(opp.X50k_Gift__c);
                  wrapRecord.stockGifts += Integer.ValueOf(opp.Stock_Gift__c);
                  if (opp.Is_Pledge_Payment__c == 'Y' && wrapRecord.Pledge == 'N') {
                    wrapRecord.Pledge = 'Y';
                  }

                  if (opp.Campaign.rC_Giving__Channel__c == 'Canvassing' && wrapRecord.isCanvassing == false) {
                    wrapRecord.isCanvassing = true;
                  }

                  if (opp.Payment_Subtype__c == 'Cash' && wrapRecord.isPaymentMethod == false) {
                    wrapRecord.isPaymentMethod = true;
                  }
                  mapGroupingToWrapper.put(uniqueString, wrapRecord);
                }
              }
            }
          }
        }
      }

      // Preparing the records to store in Batch Summaries
      for (String str : mapGroupingToWrapper.KeySet()) {

        summaryWrapperClass wrapRecord = mapGroupingToWrapper.get(str);
        if (objbl.Batch_Date__c != null && wrapRecord.bankDate != null 
            && Date.ValueOf(objbl.Batch_Date__c).month() !=  Date.ValueOf(wrapRecord.bankDate).month()) {
          if (!depositNumberToIncrement.ContainsKey(wrapRecord.depositNumber)) {
            depositNumberToIncrement.put(wrapRecord.depositNumber, 1);
          } else {
            Integer inc = depositNumberToIncrement.get(wrapRecord.depositNumber) + 1;
            depositNumberToIncrement.put(wrapRecord.depositNumber, inc);
          }
          wrapRecord.depositNumber = wrapRecord.depositNumber + '-' 
                                   + depositNumberToIncrement.get(wrapRecord.depositNumber);
        }

        if (wrapRecord.isCanvassing == true) {
          wrapRecord.depositNumber = wrapRecord.depositNumber + 'C';
        }

        if (wrapRecord.isPaymentMethod == true) {
          wrapRecord.depositNumber = wrapRecord.depositNumber + 'S';
        }

        batchLogSummaries.add(new Batch_Log_Summary__c (Deposit_Site__c = depositSite, 
                                                        Name = objbl.Name, DD_Batch__c = objbl.Name, 
                                                        Batch_Date__c = objbl.Batch_Date__c, 
                                                        Bank_Date__c = wrapRecord.bankDate,
                                                        Deposit_Number__c = wrapRecord.depositNumber, 
                                                        Fund_Code__c = wrapRecord.fundCode, 
                                                        GL_Code__c = wrapRecord.glCode,
                                                        Focus_Area_Code__c = wrapRecord.focusAreaCode, 
                                                        Res_Center_Code__c = wrapRecord.resCode,
                                                        Gift_Amount__c = wrapRecord.amount, 
                                                        Gift_Count__c = wrapRecord.Count,
                                                        Stock_Gifts__c = wrapRecord.stockGifts, 
                                                        Pledge_Payment__c = wrapRecord.Pledge,
                                                        X50K_Gifts__c = wrapRecord.X50KGifts, 
                                                        AccountNumber__c = wrapRecord.accountNumber, 
                                                        Account_Name__c = wrapRecord.accountName,
                                                        Record_Type__c = wrapRecord.recordType, 
                                                        High_Amount__c = wrapRecord.highAmount, 
                                                        Low_Amount__c = wrapRecord.lowAmount, 
                                                        Tax_Date__c = wrapRecord.taxDate,
                                                        Tax_Value__c = wrapRecord.taxValue, 
                                                        Ticker_Symbol__c = wrapRecord.tickerSymbol,
                                                        recordTypeId = batchLogSummaryRcdTypes.get(selectedReportType).getrecordTypeId()));
      }
    }
  }

  global void finish(Database.BatchableContext Bc) {
    if (!batchLogSummaries.IsEmpty()) {
      try {
        insert batchLogSummaries;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('Batch_SummaryReportGenerations', 'finish', e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }
    // Notify the users with report Link
    Monthly_Cash_Receipts_Controls__c monthlyCasthReceipts = Monthly_Cash_Receipts_Controls__c.getAll().Values()[0];
    RevSharing_StageReportCalculations.sendEmail(selectedReportType, 
                                                 monthlyCasthReceipts.Report_Request_Sender_Email__c, 
                                                 monthlyCasthReceipts.Report_Request_Owner_Email__c, 
                                                 String.ValueOf(Date.valueOf(endDate).Year()));

  }

  /*
    *Class summaryWrapperClass
    *@description : WrapperClass holds the summary.
    */
  public class summaryWrapperClass {
    public Decimal amount;
    public Decimal highAmount;
    public Decimal lowAmount;
    public Decimal taxValue;
    public Integer Count;
    public Integer X50KGifts;
    public Integer stockGifts;
    public Boolean isCanvassing;
    public Boolean isPaymentMethod;
    public String Pledge;
    public String fundCode;
    public String glCode;
    public String focusAreaCode;
    public String resCode;
    public String depositNumber;
    public String accountNumber;
    public String accountName;
    public String recordType;
    public String tickerSymbol;
    public Date   bankDate;
    public Date   taxDate;

    public summaryWrapperClass(Decimal amount, Integer Count, Integer X50KGifts, Integer stockGifts, 
                               String PledgePayment, Boolean isCanvassing, Boolean isPaymentMethod,
                               String fundCode, String glCode, String focusAreaCode, String resCode, 
                               String depositNumber, Date bankDate, String accountNumber, string accountName,
                               String recordType, Decimal highAmount, Decimal lowAmount, Decimal taxValue,
                               Date taxDate, String tickerSymbol) {
      this.amount = amount;
      this.Count = Count;
      this.X50KGifts = X50KGifts;
      this.stockGifts = stockGifts;
      this.Pledge = PledgePayment;
      this.isCanvassing = isCanvassing;
      this.isPaymentMethod = isPaymentMethod;
      this.fundCode = fundCode;
      this.glCode = glCode;
      this.focusAreaCode = focusAreaCode;
      this.resCode = resCode;
      this.depositNumber = depositNumber;
      this.bankDate = bankDate;
      this.accountNumber = accountNumber;
      this.accountName = accountName;
      this.recordType = recordType;
      this.highAmount = highAmount;
      this.lowAmount = lowAmount;
      this.taxValue = taxValue;
      this.taxDate = taxDate;
      this.tickerSymbol = tickerSymbol;
    }

  }
}