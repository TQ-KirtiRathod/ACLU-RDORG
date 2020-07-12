/*
*
*Name  :  Cash_Receipt_ReportsController
*Author:  Appirio India (Sai Krishna)
*Date  :  February 14, 2017
*Purpose :  Controller for cashReceipts vf Page Generates xls file for output
            Reports Supported
            - Credit Card Summary, calls Batch_SummaryReportGenerations
            - Stock Gifts
            - Errors, Calls Batch_SummaryReportGenerations
            - 50K 
            - Pledge Payment and Bequest
*
*/
public with sharing class Cash_Receipt_ReportsController {
   private static final String OPPORTUNITY_RT_TRANSACTION_Id = 
         Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
   private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = 
         Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();

   public String reportType;
   public Date startDate;
   public Date endDate;
   public String fileName {get; set;}
   public List<reportWrapper> lstWrapperClass {get; set;}
   public map<String, Integer> mapsharingCodeToIncrement;
   public Set<string> bequestShareCodes = new Set<String> {'Q001', 'Q002', 'Q003', 'Q004', 'Q005', 
                                                           'U001', 'U002', 'U003', 'U004', 'U005'};
   // Booleans used to manage the Columns
   public Boolean batchSummary {get; set;}
   public Boolean StockGift {get; set;}
   public Boolean x50K {get; set;}
   public Boolean isConfirm {get; set;}

   public Void populateReportVariables (List<Batch_Log__c> bLS, map<Batch_Log__c, list<Opportunity>> batchLogToRelatedOpps) {
      system.debug('query size :: ' + bls.size() );
      map<String, Integer> mapOfGroupingVsgiftCount = new map<String, Integer>();
      map<String, Decimal> mapOfGroupingVsgifttotalAmount = new map<String, Decimal>();
      map<String, Integer> mapOfGroupingVs50KGiftCount = new map<String, Integer>();

      bLS = setSoftCreditSharingCode(bLS);

      if (reportType == 'batch_Credit_Card_summary') {
         Database.executeBatch(new Batch_SummaryReportGenerations(startDate, endDate, reportType), 1);
         isConfirm = true;
      }
      // Stock Gift Report Type
      else if (reportType == 'Stock_Gift') {
         for (Batch_Log__c objbl : bLS) {
            if (objbl.Opportunities__r.Size() > 0) {
               for (Opportunity opp : objbl.Opportunities__r) {
                  // not Bequest
                  if (!bequestShareCodes.Contains(opp.Sharing_Code__c)) {
                     Opportunity updatedOpp = (GLGivingHelper.nationalGLCodeAssigner(opp).Size() > 0) 
                                            ? GLGivingHelper.nationalGLCodeAssigner(opp)[0] 
                                            : null;
                     if (updatedOpp != null 
                      /* Removed per Shawn Mcdonald
                      && (updatedOpp.Fund_Code_National__c != null
                                                && updatedOpp.GL_Code_National__c != null
                                                && updatedOpp.Focus_Area_Code_National__c != null
                                                && updatedOpp.Responsibility_Center_Code_National__c != null)
                      */
                      ) {
                        lstWrapperClass.add(new reportWrapper(
                                               opp.Deposit_Site_Code__c,
                                               objbl.name,
                                               objbl.Batch_Date__c,
                                               opp.Bank_Date__c,
                                               opp.account.AccountNumber,
                                               opp.rC_Giving__Account_Name__c,
                                               String.ValueOf(opp.amount),
                                               opp.RecordType.Name,
                                               null,
                                               updatedOpp.Fund_Code_National__c,
                                               updatedOpp.GL_Code_National__c,
                                               updatedOpp.Focus_Area_Code_National__c,
                                               updatedOpp.Responsibility_Center_Code_National__c,
                                               Double.Valueof('0.0'), 0, 0, 0, null,
                                               String.ValueOf(opp.High_Amount__c), String.ValueOf(opp.Low_Amount__c),
                                               String.ValueOf(opp.Tax_Value__c),
                                               String.ValueOf(opp.Realized_Gain_Loss__c),
                                               opp.Tax_Date__c, opp.rC_Giving__Ticker_Symbol__c
                                            )
                                           );
                     }
                  }
                  //Bequest
                  else {
                     List<Opportunity> updatedOpps = (GLGivingHelper.nationalGLCodeAssigner(opp).Size() > 0) 
                                                   ? GLGivingHelper.nationalGLCodeAssigner(opp) 
                                                   : null;
                     if (updatedOpps != null) {
                        for (Opportunity splitedOpp : updatedOpps) {
                           /* Removed per Shawn Mcdonald
                           if ((splitedOpp.Fund_Code_National__c != null && splitedOpp.GL_Code_National__c != null
                                 && splitedOpp.Focus_Area_Code_National__c != null
                                 && splitedOpp.Responsibility_Center_Code_National__c != null)) {
                           */
                              lstWrapperClass.add(new reportWrapper(
                                                     opp.Deposit_Site_Code__c,
                                                     objbl.name,
                                                     objbl.Batch_Date__c,
                                                     opp.Bank_Date__c,
                                                     opp.account.AccountNumber,
                                                     opp.rC_Giving__Account_Name__c,
                                                     String.ValueOf(opp.amount),
                                                     opp.RecordType.Name,
                                                     null,
                                                     splitedOpp.Fund_Code_National__c,
                                                     splitedOpp.GL_Code_National__c,
                                                     splitedOpp.Focus_Area_Code_National__c,
                                                     splitedOpp.Responsibility_Center_Code_National__c,
                                                     Double.Valueof('0.0'), 0, 0, 0, null,
                                                     String.ValueOf(opp.High_Amount__c),
                                                     String.ValueOf(opp.Low_Amount__c),
                                                     String.ValueOf(opp.Tax_Value__c),
                                                     String.ValueOf(opp.Realized_Gain_Loss__c),
                                                     opp.Tax_Date__c,
                                                     opp.rC_Giving__Ticker_Symbol__c
                              ) );
                           //}
                        }
                     }
                  }
               }
            }
         }
      }

      // Error ReportType
      else if (reportType == 'Errors') {
          Database.executeBatch(new BatchLogSummariesDeleteBatch(startDate, endDate, reportType), 2000);
      }

      else {
         for (Batch_Log__c objbl : bLS) {
            if (objbl.Opportunities__r.Size() > 0) {
               for (Opportunity opp : objbl.Opportunities__r) {
                  // not Bequest
                  if (!bequestShareCodes.Contains(opp.Sharing_Code__c)) {

                     Opportunity updatedOpp = (GLGivingHelper.nationalGLCodeAssigner(opp).Size() > 0) 
                                            ? GLGivingHelper.nationalGLCodeAssigner(opp)[0] 
                                            : null;

                     if (updatedOpp != null 
                      /* Removed per Shawn Mcdonald
                      && (updatedOpp.GL_Code_National__c != null
                                                && updatedOpp.Focus_Area_Code_National__c != null
                                                && updatedOpp.Responsibility_Center_Code_National__c != null)
                      */
                                                ) {
                        lstWrapperClass.add(new reportWrapper(
                                               opp.Deposit_Site_Code__c,
                                               objbl.name,
                                               objbl.Batch_Date__c,
                                               opp.Bank_Date__c,
                                               opp.account.AccountNumber,
                                               opp.rC_Giving__Account_Name__c,
                                               String.ValueOf(opp.amount),
                                               opp.RecordType.Name,
                                               null,
                                               updatedOpp.Fund_Code_National__c,
                                               updatedOpp.GL_Code_National__c,
                                               updatedOpp.Focus_Area_Code_National__c,
                                               updatedOpp.Responsibility_Center_Code_National__c,
                                               Double.Valueof('0.0'),
                                               0,
                                               0,
                                               0,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null,
                                               Date.Today(),
                                               null
                        ) );
                     }
                  }
                  //Bequest
                  else {
                     List<Opportunity> updatedOpps = (GLGivingHelper.nationalGLCodeAssigner(opp).Size() > 0) 
                                                   ? GLGivingHelper.nationalGLCodeAssigner(opp) 
                                                   : null;
                     if (updatedOpps != null) {
                        for (Opportunity splitedOpp : updatedOpps) {
                           /* Removed per Shawn Mcdonald
                           if ((splitedOpp.Fund_Code_National__c != null && splitedOpp.GL_Code_National__c != null 
                                 && splitedOpp.Focus_Area_Code_National__c != null 
                                 && splitedOpp.Responsibility_Center_Code_National__c != null)) {
                           */
                              lstWrapperClass.add(new reportWrapper(
                                                     opp.Deposit_Site_Code__c,
                                                     objbl.name,
                                                     objbl.Batch_Date__c,
                                                     opp.Bank_Date__c,
                                                     opp.account.AccountNumber,
                                                     opp.rC_Giving__Account_Name__c,
                                                     String.ValueOf(splitedOpp.amount),
                                                     opp.RecordType.Name,
                                                     null,
                                                     splitedOpp.Fund_Code_National__c,
                                                     splitedOpp.GL_Code_National__c,
                                                     splitedOpp.Focus_Area_Code_National__c,
                                                     splitedOpp.Responsibility_Center_Code_National__c,
                                                     Double.Valueof('0.0'),
                                                     0,
                                                     0,
                                                     0,
                                                     null,
                                                     null,
                                                     null,
                                                     null,
                                                     null,
                                                     Date.Today(),
                                                     null
                              ) );
                           //}
                        }
                     }
                  }
               }
            }
         }
      }
      redirectToMonthlyCashReceipts();
   }

   public pageReference redirectToMonthlyCashReceipts() {
      return page.Monthly_Cash_Receipt_File;
   }


   // Controller
   public Cash_Receipt_ReportsController () {
      lstWrapperClass = new List<reportWrapper>();
      mapsharingCodeToIncrement = new map<String, Integer>();
      reportType = ApexPages.currentPage().getParameters().get('reportType');
      startDate = Date.ValueOf(ApexPages.currentPage().getParameters().get('startDate'));
      endDate = Date.ValueOf(ApexPages.currentPage().getParameters().get('endDate'));
      batchSummary = false;
      StockGift = false;
      x50K = false;
      isConfirm = false;
      fileName = reportType + ' [' + String.ValueOf(startDate.month()) + '/' 
               + String.ValueOf(startDate.Day()) + '/' + String.ValueOf(startDate.Year()) + ']' + '- [' 
               + String.ValueOf(endDate.month()) + '/' + String.ValueOf(endDate.Day()) + '/' 
               + String.ValueOf(endDate.Year())  + ']';
      //Manage Columns Controller
      if (reportType == 'Errors' || reportType == '50k' 
            || reportType == 'Pledge_Payment' || reportType == 'Bequest') {
         x50K = true;
      } else if (reportType == 'Stock_Gift') {
         StockGift = true;
         x50K = true;
      } else {
         batchSummary = true;
      }

      if (reportType == 'batch_Credit_Card_summary') {
         List<Batch_Log__c> bLs = new List<Batch_Log__C>();
         // Passing Empty list as the query is written in Batch Class.
         populateReportVariables(bLs, null);
      } else if (reportType == '50k') {
         List<Batch_Log__c> bLs = [
                                 SELECT Id, Batch_Log_Status__c, Deposit_Site__c, Name, Batch_Date__c,
                                    (
                                      SELECT Id, Name, X50k_Gift__c, Is_Pledge_Payment__c, Deposit_Site_Code__c, Bank_Date__c,
                                      Deposit_Site__c, Batch_Log__c, Restriction__c, Sharing_Code__c, StageName,
                                      Program_Type__c, accountId, account.AccountNumber, amount, RecordTypeId,
                                      RecordType.Name, Type, High_Amount__c, Low_Amount__c, Tax_Value__c, Tax_Date__c,
                                      rC_Giving__Account_Name__c, Realized_Gain_Loss__c, Stock_Gift__c, rC_Giving__Ticker_Symbol__c
                                      FROM Opportunities__r
                                      WHERE StageName = 'Completed'
                                        AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                        AND Sharing_Code__c != null
                                        AND Amount >= 50000  //doublecheck formula
                                        //AND X50k_Gift__c = 1
                                        AND Adjustment_Code__c IN ('N', 'D')
                                        AND CloseDate >= :startDate
                                        AND CloseDate < :endDate
                                        //ORDER BY Sharing_Code__c
                                     )
                                  FROM Batch_Log__c
                                  WHERE  Batch_Log_Status__c = 'Balanced'
                                    AND Name LIKE 'NA%'
                                    AND Batch_Date__c >= : startDate
                                    AND Batch_Date__c < : endDate
                                  ORDER BY Id
                                 ];
         populateReportVariables(bLs, null);
      }

      else if (reportType == 'Pledge_Payment') {
         List<Batch_Log__c> bLs = [
                                     SELECT Id, Batch_Log_Status__c, Deposit_Site__c, Name, Batch_Date__c,
                                     (
                                        SELECT Id, Name, X50k_Gift__c, Is_Pledge_Payment__c, Deposit_Site_Code__c, Bank_Date__c,
                                        Deposit_Site__c, Batch_Log__c, Restriction__c, Sharing_Code__c, StageName,
                                        Program_Type__c, accountId, account.AccountNumber, amount, RecordTypeId, RecordType.Name,
                                        Type, High_Amount__c, Low_Amount__c, Tax_Value__c, Tax_Date__c, rC_Giving__Account_Name__c,
                                        Realized_Gain_Loss__c, Stock_Gift__c, rC_Giving__Ticker_Symbol__c
                                        FROM Opportunities__r
                                        WHERE StageName = 'Completed'
                                          //AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                          AND RecordTypeId = :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
                                          AND Sharing_Code__c != null
                                          AND rC_Giving__Parent__r.rC_Giving__Is_Bookable__c = TRUE
                                          //AND Is_Pledge_Payment__c = 'Y'
                                          AND Adjustment_Code__c IN ('N', 'D')
                                          AND CloseDate >= :startDate
                                          AND CloseDate < :endDate
                                          //ORDER BY Sharing_Code__c
                                     )
                                     FROM Batch_Log__c
                                     WHERE  Batch_Log_Status__c = 'Balanced'
                                           AND Name LIKE 'NA%'
                                           AND Batch_Date__c >= : startDate
                                           AND Batch_Date__c < : endDate
                                           ORDER BY Id
                                  ];
         populateReportVariables(bLs, null);
      }

      else if (reportType == 'Stock_Gift') {
         List<Batch_Log__c> bLs = [
                                     SELECT Id, Batch_Log_Status__c, Deposit_Site__c, Name, Batch_Date__c,
                                     (
                                        SELECT Id, Name, X50k_Gift__c, Is_Pledge_Payment__c, Deposit_Site_Code__c, Bank_Date__c,
                                        Deposit_Site__c, Batch_Log__c, Restriction__c, Sharing_Code__c, StageName,
                                        Program_Type__c, accountId, account.AccountNumber, amount, RecordTypeId, RecordType.Name,
                                        Type, High_Amount__c, Low_Amount__c, Tax_Value__c, Tax_Date__c, rC_Giving__Account_Name__c,
                                        Realized_Gain_Loss__c, Stock_Gift__c, rC_Giving__Ticker_Symbol__c
                                        FROM Opportunities__r
                                        WHERE StageName = 'Completed'
                                          AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                          //commented below code and added new filter for issue I-320263
                                          AND (rC_Giving__Payment_Method__c = 'Securities'
                                              //OR (rC_Giving__Payment_Method_Selected__r.name = 'Stock' 
                                              //    AND rC_Giving__Payment_Method__c = 'Other' )
                                              )
                                          //END-Issue I-320263
                                          //AND Stock_Gift__c = 1
                                          AND Sharing_Code__c != null
                                          AND Adjustment_Code__c IN ('N', 'D')
                                          AND CloseDate >= :startDate
                                          AND CloseDate < :endDate
                                          //ORDER BY Sharing_Code__c
                                     )
                                     FROM Batch_Log__c
                                     WHERE  Batch_Log_Status__c = 'Balanced'
                                           AND Name LIKE 'NA%'
                                           AND Batch_Date__c >= : startDate
                                           AND Batch_Date__c < : endDate
                                           ORDER BY Id
                                  ];

         populateReportVariables(bLs, null);
      }

      else if (reportType == 'Bequest') {
         List<Batch_Log__c> bLs = [
                                     SELECT Id, Batch_Log_Status__c, Deposit_Site__c, Name, Batch_Date__c,
                                     (
                                        SELECT Id, Name, X50k_Gift__c, Is_Pledge_Payment__c, Deposit_Site_Code__c, Bank_Date__c,
                                        Deposit_Site__c, Batch_Log__c, Restriction__c, Sharing_Code__c, StageName,
                                        Program_Type__c, accountId, account.AccountNumber, amount, RecordTypeId, RecordType.Name,
                                        Type, High_Amount__c, Low_Amount__c, Tax_Value__c, Tax_Date__c, rC_Giving__Account_Name__c,
                                        Realized_Gain_Loss__c, Stock_Gift__c, rC_Giving__Ticker_Symbol__c
                                        FROM Opportunities__r
                                        WHERE StageName = 'Completed'
                                          AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                          AND Sharing_Code__c = : bequestShareCodes
                                          AND Sharing_Code__c != null
                                          AND Adjustment_Code__c IN ('N', 'D')
                                          AND CloseDate >= :startDate
                                          AND CloseDate < :endDate
                                          //ORDER BY Sharing_Code__c
                                     )
                                     FROM Batch_Log__c
                                     WHERE  Batch_Log_Status__c = 'Balanced'
                                           AND Name LIKE 'NA%'
                                           AND Batch_Date__c >= : startDate
                                           AND Batch_Date__c < : endDate
                                           ORDER BY Id
                                  ];
         populateReportVariables(bLs, null);
      }

      else if (reportType == 'Errors') {
          //Moved the below logic to Batch Class (Batch_SummaryReportGenearations)
         /*List<Batch_Log__c> bLs = [
                                     SELECT Id, Batch_Log_Status__c, Deposit_Site__c, Name, Batch_Date__c*//*,
                    (
                    SELECT id,Sharing_Code__c, Deposit_Site_Code__c, Name, Bank_Date__c,
                        rC_Giving__Account_Name__c,  amount, account.AccountNumber, RecordType.Name
                        //Id, Name, X50k_Gift__c, Is_Pledge_Payment__c, Deposit_Site_Code__c, Bank_Date__c,
                        //Deposit_Site__c, Batch_Log__c,Restriction__c, Sharing_Code__c, StageName, Program_Type__c,
                        //accountId, account.AccountNumber, amount, RecordTypeId, RecordType.Name, Type,
                        //High_Amount__c, Low_Amount__c, Tax_Value__c, Tax_Date__c, rC_Giving__Account_Name__c,
                        //Realized_Gain_Loss__c, Stock_Gift__c, rC_Giving__Ticker_Symbol__c
                    FROM Opportunities__r
                    WHERE StageName = 'Completed'
                        AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                        AND Sharing_Code__c != null
                        AND Adjustment_Code__c IN ('N','D')
                        AND CloseDate >= :startDate
                        AND CloseDate < :endDate
                    //ORDER BY Sharing_Code__c
                    )
                    *//*
                                     FROM Batch_Log__c
                                     WHERE  Batch_Log_Status__c = 'Balanced'
                                           AND Name LIKE 'NA%'
                                           AND Batch_Date__c >= : startDate
                                           AND Batch_Date__c < : endDate
                                           ORDER BY Id
                                  ];
         map<ID, Batch_Log__c> batchLogMap = new map<ID, Batch_Log__c>();
         for (Batch_Log__c b : bLs) {
            batchLogMap.put(b.id, b);
         }
         List<Opportunity> opps = [
                                     SELECT id, Sharing_Code__c, Deposit_Site_Code__c, Name, Bank_Date__c, Batch_Log__c,
                                     rC_Giving__Account_Name__c,  amount, account.AccountNumber, RecordType.Name,
                                     Restriction__c, Program_Type__c
                                     FROM Opportunity
                                     WHERE StageName = 'Completed'
                                       AND RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                       AND Sharing_Code__c != null
                                       AND Adjustment_Code__c IN ('N', 'D')
                                       AND Batch_Log__c IN :batchLogMap.keySet()
                                       AND CloseDate >= : startDate
                                       AND CloseDate < : endDate
                                  ];

         map<Batch_Log__c, list<Opportunity>> batchLogToRelatedOpps = new map<Batch_Log__c, list<Opportunity>>();
         for (Opportunity opp : opps) {
            if (!batchLogToRelatedOpps.containsKey(batchLogMap.get(opp.Batch_Log__c))) {
               batchLogToRelatedOpps.put(batchLogMap.get(opp.Batch_Log__c), new list<Opportunity>());
            }
            batchLogToRelatedOpps.get(batchLogMap.get(opp.Batch_Log__c)).add(opp);
         }*/
         List<Batch_Log__c> bLs = new List<Batch_Log__C>();
         // Passing Empty list as the query is written in Batch Class.
         populateReportVariables(bLs, null);
      }
   }


   public List<Batch_Log__c> setSoftCreditSharingCode(List<Batch_Log__c> bLS){
    //gets ids from opps that are contained within the batch logs
    List<Id> oppIds= new List<Id>();
    for(Batch_Log__c bl: bLS){
      if (bl.Opportunities__r.Size() > 0) {
        for (Opportunity opp : bl.Opportunities__r) {
          oppIds.add(opp.id);
        }
      }
    }

    //Gets soft credit records which contains the "real" sharing code
    String OPPORTUNITY_RT_SOFT_CREDIT_Id = 
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    List<Opportunity> SoftCreditSharingCodeOpps = [ 
              SELECT id, sharing_code__c,  Related_Transaction__c
              FROM Opportunity
              WHERE Related_Transaction__c IN :oppIds
                //AND RecordTypeId = :OPPORTUNITY_RT_SOFT_CREDIT_Id migrated data has issues w/ this
          ];
    //creates map of related trans to sharing code
    Map<ID, String> softCreditSharingCode = new Map<ID, String>();
    for(Opportunity o : SoftCreditSharingCodeOpps){
      softCreditSharingCode.put(o.Related_Transaction__c, o.sharing_code__c);
    }

    for(Batch_Log__c bl: bLS){
      if (bl.Opportunities__r.Size() > 0) {
        for (Opportunity opp : bl.Opportunities__r) {
          //Update the softcredit sharing code with actual sharing code
          if(opp.sharing_code__c == 'SOFTCREDIT' ){
            system.debug('jw 0 pre opp :: '+ opp.sharing_code__c);
            if(softCreditSharingCode.containsKey(opp.id) ){
              opp.sharing_code__c = softCreditSharingCode.get(opp.id);
            }
            system.debug('jw 0 post opp :: '+ opp.sharing_code__c);
          }
        }
      }
    }
    return bLS;
   }



   // Wrapper Class used to show the columns in the report
   public class reportWrapper {
      public String deposit_Site {get; set;}
      public String dD_Batch {get; set;}
      public Date effective_Date {get; set;}
      public Date bank_Date {get; set;}
      public String accountId {get; set;}
      public String accountName {get; set;}
      public String giving_Amount {get; set;}
      public String gift_Type {get; set;}
      public String deposit_Number {get; set;}
      public String fund_Code {get; set;}
      public String gL_Code {get; set;}
      public String focus_Area_Code {get; set;}
      public String res_Center_Code {get; set;}
      public Double total_Amount {get; set;}
      public Integer gift_Count {get; set;}
      public Integer X50K_Count {get; set;}
      public Integer stockGift_Count {get; set;}
      public String pledge_Payment {get; set;}
      public String high_amount {get; set;}
      public String low_amount {get; set;}
      public String tax_value {get; set;}
      public String realized_Gain_Loss {get; set;}
      public Date tax_Date {get; set;}
      public String stock_ticker {get; set;}

      public reportWrapper(String deposit_Site, String batchLogName, Date bL_BatchDate, Date giving_BankDate,
                           String accountNumber, String accountName, String amount,
                           String giving_RecordType, String depositNumber, String fundCode, String gL_Code,
                           String focusAreaCode, String resCenterCode, Double totalAmount,
                           Integer totalgift, Integer X50KCount, Integer stockGiftCount, String pledgePayment,
                           string highAmount, string lowAmount, string taxValue,
                           String realizedGainLoss, Date taxDate, String stockTicker) {
         this.deposit_Site = deposit_Site;
         this.dD_Batch = batchLogName;
         this.effective_Date = bL_BatchDate;
         this.bank_Date = giving_BankDate;
         this.accountId = accountNumber;
         this.accountName = accountName;
         this.giving_Amount = amount;
         this.gift_Type = (giving_RecordType == 'Transaction' ? 'Donation' : giving_RecordType);
         this.deposit_Number = depositNumber;
         this.fund_Code = fundCode;
         this.gL_Code = gL_Code;
         this.focus_Area_Code = focusAreaCode;
         this.res_Center_Code = resCenterCode;
         this.total_Amount = totalAmount;
         this.gift_Count = totalgift;
         this.X50K_Count = X50KCount;
         this.stockGift_Count = stockGiftCount;
         this.pledge_Payment = pledgePayment;
         this.high_amount = highAmount;
         this.low_amount = lowAmount;
         this.tax_value = taxValue;
         this.realized_Gain_Loss = realizedGainLoss;
         this.tax_Date = taxDate;
         this.stock_ticker = stockTicker;

      }
   }

}