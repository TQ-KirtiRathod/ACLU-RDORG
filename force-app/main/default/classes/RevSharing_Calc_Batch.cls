/*
*
*Name  :  RevSharing_Calc_Batch
*Author:  Appirio India (Shikha Gupta)
*Date  :  March 01, 2017
*Purpose :  This batch class sets the Revenue Sharing Caclulations for the Affiliate Yearly object
            Batch queries opps and summarizes them based on the logic contained within.
*
*/
global class RevSharing_Calc_Batch implements Database.Batchable<sObject>, Database.stateful {
  private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
  private static final Set<String> setofIncomeTypes;
  private static Set<String> setOfRequiredCodes;
  private static set<String> setOfNationalCodes;
  private static final Set<String> setofIncomeTypesForIndemnification;
  private static Set<String> setOfRequiredCodesForIndemnification;
  private static Set<String> setOfRequiredCodesForUnshared;
  private static Set<String> setOfAllSharingCodesNeeded;

  static {
    setOfRequiredCodes = new Set<String> {'D009', 'D012', 'E013', 'E015', 'E016', 'E017', 'N111', 'R112', 'N175'};
    setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};
    setofIncomeTypes = new Set<String> {'UBRI', 'FBRI'};
    setOfRequiredCodesForIndemnification = new Set<String> {'R131', 'R113', 'K171', 'E131', 'R141', 
                                                            'E141', 'R151', 'E151', 'R181', 'C171'};
    setofIncomeTypesForIndemnification = new Set<String> {'Incentive', 'Benefit', 'Solicited Earmarked', 'In-Kind'};
    setOfRequiredCodesForUnshared = new Set<String> {'A001', 'A002', 'A003', 'B003', 'P002', 'P003', 'K165', 'C165', 
                                                     'K161', 'C161' };

    setOfAllSharingCodesNeeded = new Set<String> {'D009', 'D012', 'E013', 'E015', 'E016', 'E017', 'N111', 'R112', 
                                                  'N175', 'R131', 'R113', 'K171', 'E131', 'R141', 'E141', 'R151', 
                                                  'E151', 'R181', 'C171', 'A001', 'A002', 'A003', 'B003', 'P002', 
                                                  'P003', 'K165', 'C165', 'K161', 'C161'
                                                 };
  }

  public String accAffiliationCode;
  public Id affiliateYearly;
  public Boolean eligibleForGMI;
  public Double BRI_Percentage;
  public Double totalFBRI = 0.0;
  public Double totalUBRI = 0.0;
  public Double gmiSubsidy;
  public String fYear;
  public Date fiscalStartDate;
  public Date fiscalEndDate;
  public Double unionCostFactor;
  public Double foundationCostFactor;
  public Double incentiveTotal = 0.0;
  public Double iGMI = 0.0;
  public Double benifitTotal = 0.0;
  public Double totalIncentiveNationalAmount = 0.0;
  public Double totalBenifitNationalAmount = 0.0;
  public Double soliciateEarmarkedTotal = 0.0;
  public Double totalsoliciateEarmarkedNationalAmount = 0.0;
  public Double in_KindTotal = 0.0;
  public Double totalInkindNationalAmount = 0.0;
  public Double indemnificationFromToday;
  public Double affiliateActualIndeminification;
  public Double AffiliateYearlyAffiliateIndemnification;
  public Double NationalYearlyNationalIndemnification;
  public Double nationalActualIndemnification;
  public Double nationalActualIndemnificationFromToday;
  public Double unSharedIncomeTotal = 0.0;
  public Double unSharedIncomeTotalNational = 0.0;
  /*
  public Double reconGeneralIncentiveNat = 0.0;
  public Double reconGeneralIncentiveAff = 0.0;
  public Double reconGrant = 0.0;
  public Double reconUnrestrNonMem = 0.0;
  public Double reconUnsolEar = 0.0;
  public Double reconSolEar = 0.0;
  public Double reconInKind = 0.0;
  */
  public Boolean isReportRunning = false;

  global RevSharing_Calc_Batch(Id recordId) {
    Affiliate_Yearly__c obj = [SELECT Id, GMI_Amount__c, Incentive_National_Share__c, Union_Cost_Factor__c, 
                                  Foundation_Cost_Factor__c, Fiscal_Year__c, BRI_Affiliate_Share__c , 
                                  Eligible_for_GMI__c , Account__r.Affiliation__c, National_Actual_Indemnification_Today__c,
                                  Affiliate_Indemnification_Threshold__c, Affiliate_Actual_Indemnification_from_To__c, 
                                  Affiliate_Actual_Indemnification__c, National_Actual_Indemnification__c, 
                                  National_Indemnification_Threshold__c
                               FROM Affiliate_Yearly__c
                               WHERE Id = : recordId];
    this.accAffiliationCode = obj.Account__r.Affiliation__c;
    this.affiliateYearly = recordId;
    this.eligibleForGMI = obj.Eligible_for_GMI__c;
    this.BRI_Percentage = (obj.BRI_Affiliate_Share__c) == null ? 0 : obj.BRI_Affiliate_Share__c;
    this.iGMI = (obj.Incentive_National_Share__c) == null ? 0 : obj.Incentive_National_Share__c;
    this.gmiSubsidy = (obj.GMI_Amount__c) == null ? 0 : obj.GMI_Amount__c;
    this.fYear = obj.Fiscal_Year__c;
    this.fiscalStartDate = Date.newInstance(Integer.ValueOf(fYear) - 1, 4, 1);
    this.fiscalEndDate = Date.newInstance(Integer.ValueOf(fYear), 3, 31);
    this.unionCostFactor = (obj.Union_Cost_Factor__c) == null ? 0 : obj.Union_Cost_Factor__c;
    this.foundationCostFactor = (obj.Foundation_Cost_Factor__c) == null ? 0 : obj.Foundation_Cost_Factor__c;
    this.indemnificationFromToday = (obj.Affiliate_Actual_Indemnification_from_To__c == null) ? 0 : obj.Affiliate_Actual_Indemnification_from_To__c;
    this.affiliateActualIndeminification = (obj.Affiliate_Actual_Indemnification__c == null) ? 0 : obj.Affiliate_Actual_Indemnification__c;
    this.AffiliateYearlyAffiliateIndemnification = (obj.Affiliate_Indemnification_Threshold__c == null) ? 0 : obj.Affiliate_Indemnification_Threshold__c;
    this.NationalYearlyNationalIndemnification = (obj.National_Indemnification_Threshold__c == null) ? 0 : obj.National_Indemnification_Threshold__c;
    this.nationalActualIndemnification  = (obj.National_Actual_Indemnification__c == null) ? 0 : obj.National_Actual_Indemnification__c;
    this.nationalActualIndemnificationFromToday = (obj.National_Actual_Indemnification_Today__c == NULL) ? 0 : obj.National_Actual_Indemnification_Today__c;
  }

  global Database.QueryLocator start(Database.BatchableContext Bc ) {
    Set<String> setOfValidRecordTypes = new Set<String> { OPPORTUNITY_RT_TRANSACTION_Id, OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                                          OPPORTUNITY_RT_SOFTCREDIT_Id };
    set<String> BenifitCampaignIds = new Set<String>();
    // fetch all the Benifit Campaigns
    for (Campaign cmp : [SELECT Id, rC_Giving__Source_Code__c, rC_Giving__Campaign_Type__c 
                         FROM Campaign 
                         WHERE rC_Giving__Campaign_Type__c = 'B - Benefit' 
                          AND rC_Giving__Source_Code__c != null 
                          AND rC_Giving__End_Date_Time__c != null 
                          AND CALENDAR_YEAR(rC_Giving__End_Date_Time__c) = : Integer.ValueOf(fYear) ]) {
      BenifitCampaignIds.add(cmp.Id);
    }

    return Database.getQueryLocator([SELECT Id, Amount, Program_Type__c, Exclude_Cost_Factors_in_RevShare__c, 
                                        Use_Campaign_Cost__c, Cost_Factor__c, Sharing_Entity__c, Sharing_Code__c, 
                                        Exclude_from_Revenue_Sharing__c, RecordTypeId, Sharing_Entity_Affiliation__c,
                                        Account.Total_Gifts_Amount_Current_FY__c, Account.Total_Gifts_Amount_Prior_FY__c, 
                                        Deposit_Site__c
                                     FROM Opportunity
                                     WHERE RecordTypeId IN : setOfValidRecordTypes
                                     AND Sharing_Code__c IN :setOfAllSharingCodesNeeded
                                     AND (Sharing_Entity_Affiliation__c = : accAffiliationCode.subString(0, 2)
                                          OR (Account_Affiliation__c = : accAffiliationCode.subString(0, 2) 
                                          AND Sharing_Entity_Affiliation__c IN : setOfNationalCodes)
                                         )
                                     AND ((CloseDate >= :fiscalStartDate AND CloseDate <= :fiscalEndDate)
                                          OR  CampaignIdText__c IN :BenifitCampaignIds)
                                     AND stageName = 'Completed'
                                    ]);
  }

  global void execute(Database.BatchableContext Bc, List<Opportunity> scope) {

    Double bRI_gMI_Percentage;
    if (eligibleForGMI) {
      bRI_gMI_Percentage = ((iGMI / 100));
    } else {
      bRI_gMI_Percentage = ((BRI_Percentage / 100));
    }

    for (Opportunity theOpp : scope) {

      if (theOpp.Exclude_from_Revenue_Sharing__c) continue;

      //UBRI
      if (theOpp.Sharing_Code__c == 'D009' || theOpp.Sharing_Code__c == 'D012' 
          || theOpp.Sharing_Code__c == 'E013' || theOpp.Sharing_Code__c == 'E015'
          || theOpp.Sharing_Code__c == 'E016' || theOpp.Sharing_Code__c == 'E017') {
        if (theOpp.Use_Campaign_Cost__c == true) {
          totalUBRI = totalUBRI + (theOpp.Amount * (1 - theOpp.Cost_Factor__c / 100) * bRI_gMI_Percentage);
        } else if (theOpp.Use_Campaign_Cost__c == false && (theOpp.Program_Type__c == '1' 
                   || theOpp.Program_Type__c == '2' || theOpp.Program_Type__c == '3')
                  ) {
          totalUBRI = totalUBRI + (theOpp.Amount * (1 - unionCostFactor / 100) * bRI_gMI_Percentage);
        } else if (theOpp.Use_Campaign_Cost__c == false && (theOpp.Program_Type__c != '1' 
                   && theOpp.Program_Type__c != '2' && theOpp.Program_Type__c != '3')
                  ) {
          totalUBRI = totalUBRI + (theOpp.Amount * (1 - foundationCostFactor / 100) * bRI_gMI_Percentage);
        }
      }
      //FBRI
      if (theOpp.Sharing_Code__c == 'N111' || theOpp.Sharing_Code__c == 'R112' || theOpp.Sharing_Code__c == 'N175' ) {
        if (theOpp.Use_Campaign_Cost__c == true && theOpp.Sharing_Code__c != 'N175') {
          totalFBRI = totalFBRI + (theOpp.Amount * (1 - theOpp.Cost_Factor__c / 100) * bRI_gMI_Percentage);
        } else if (theOpp.Use_Campaign_Cost__c == false && (theOpp.Program_Type__c == '1' 
                   || theOpp.Program_Type__c == '2' || theOpp.Program_Type__c == '3') && theOpp.Sharing_Code__c != 'N175') {
          totalFBRI = totalFBRI + (theOpp.Amount * (1 - unionCostFactor / 100) * bRI_gMI_Percentage);
        } else if (theOpp.Use_Campaign_Cost__c == false && (theOpp.Program_Type__c != '1' 
                     && theOpp.Program_Type__c != '2' && theOpp.Program_Type__c != '3') 
                   && theOpp.Sharing_Code__c != 'N175') {
          totalFBRI = totalFBRI + (theOpp.Amount * (1 - foundationCostFactor / 100) * bRI_gMI_Percentage);
        } else if (theOpp.Sharing_Code__c == 'N175') {
          totalFBRI = totalFBRI + (theOpp.Amount * bRI_gMI_Percentage);
        }
      }

      Double costFactor;
      // CostFactor calculation
      if (theOpp.Use_Campaign_Cost__c == true ) {
        costFactor = (1 - theOpp.Cost_Factor__c / 100);
      } else if (theOpp.Use_Campaign_Cost__c == false && (theOpp.Program_Type__c == '1' || theOpp.Program_Type__c == '2' 
                 || theOpp.Program_Type__c == '3')) {
        costFactor = (1 - unionCostFactor / 100);
      } else if (theOpp.Use_Campaign_Cost__c == false && (theOpp.Program_Type__c != '1' && theOpp.Program_Type__c != '2' 
                 && theOpp.Program_Type__c != '3')) {
        costFactor = (1 - foundationCostFactor / 100);
      }

      // Incentive Income
      if (theOpp.Sharing_Code__c == 'R131' || theOpp.Sharing_Code__c == 'R113' || theOpp.Sharing_Code__c == 'K171' 
          || theOpp.Sharing_Code__c == 'E131' || theOpp.Sharing_Code__c == 'C171' ) {
        incentiveTotal = incentiveTotal + calculateAffiliateShare(theOpp, costFactor, false );
        totalIncentiveNationalAmount = totalIncentiveNationalAmount + calculateNationalShare(theOpp, costFactor, false );
      }

      // Benifit Income
      if (theOpp.Sharing_Code__c == 'R141' || theOpp.Sharing_Code__c == 'E141' ) {
        benifitTotal = benifitTotal + calculateAffiliateShare(theOpp, costFactor, true );
        totalBenifitNationalAmount = totalBenifitNationalAmount + calculateNationalShare(theOpp, costFactor, true );
      }

      //SoliciateEarMarked
      if (theOpp.Sharing_Code__c == 'R151' || theOpp.Sharing_Code__c == 'E151') {
        soliciateEarmarkedTotal = soliciateEarmarkedTotal + calculateAffiliateShare(theOpp, costFactor, false );
        totalsoliciateEarmarkedNationalAmount = totalsoliciateEarmarkedNationalAmount + calculateNationalShare(theOpp, costFactor, false );
      }

      //In-Kind
      if (theOpp.Sharing_Code__c == 'R181') {
        in_KindTotal = in_KindTotal + calculateAffiliateShare(theOpp, costFactor, false );
        totalInkindNationalAmount = totalInkindNationalAmount + calculateNationalShare(theOpp, costFactor, false );
      }

      //Unshared
      if (theOpp.Sharing_Code__c == 'A001' || theOpp.Sharing_Code__c == 'A002' || theOpp.Sharing_Code__c == 'A003' 
          || theOpp.Sharing_Code__c == 'B003' || theOpp.Sharing_Code__c == 'P002' || theOpp.Sharing_Code__c == 'P003' 
          || theOpp.Sharing_Code__c == 'K165' || theOpp.Sharing_Code__c == 'C165' || theOpp.Sharing_Code__c == 'K161'
          || theOpp.Sharing_Code__c == 'C161' ) {
        if (theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0, 2)) {
          unSharedIncomeTotal = unSharedIncomeTotal + theOpp.Amount;
        } else {
          unSharedIncomeTotalNational = unSharedIncomeTotalNational  + theOpp.Amount;
        }
      }

      /////////// Reconciliation Staging ///////////////////
      /*set<String> incentiveSet = new set<String> {'E131', 'C171'};
      if (incentiveSet.contains(theOpp.Sharing_Code__c)
          && (theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith( accAffiliationCode.subString(0, 2) ))) {
        reconGeneralIncentiveAff = reconGeneralIncentiveAff + theOpp.Amount;
      }
      if (incentiveSet.contains(theOpp.Sharing_Code__c)
          && (theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA'))) {
        reconGeneralIncentiveNat = reconGeneralIncentiveNat + theOpp.Amount;
      }

      set<String> unrestrNonMemSet = new set<String> {'E131', 'E121'};
      if (unrestrNonMemSet.contains(theOpp.Sharing_Code__c) ) {
        reconUnrestrNonMem = reconUnrestrNonMem + theOpp.Amount;
      }

      if (theOpp.Sharing_Code__c == 'E151') {
        reconSolEar = reconSolEar + theOpp.Amount;
      }

      if (theOpp.Sharing_Code__c == 'E181') {
        reconInKind = reconInKind + theOpp.Amount;
      }

      if (theOpp.Sharing_Code__c == 'C165') {
        reconGrant = reconGrant + theOpp.Amount;
      }

      if (theOpp.Sharing_Code__c == 'C161') {
        reconUnsolEar = reconUnsolEar + theOpp.Amount;
      }
      */


    }

  }

  global void finish(Database.BatchableContext Bc) {
    Double UBRI_total = totalUBRI;
    Double FBRI_total = totalFBRI;
    if (eligibleForGMI) {
      UBRI_total = gmiSubsidy;
    }

    Affiliate_Yearly__c updatedYearlyAffiliate = new Affiliate_Yearly__c(Id = affiliateYearly,
        Last_Calc_Time_of_Non_Manual_IncomeTypes__c = DateTime.Now(),
        UBRI_Total__c  = UBRI_total,
        FBRI_Total__c  = FBRI_total,
        Incentive_Income_Total__c  = incentiveTotal,
        Incentive_Income_Total_for_National__c = totalIncentiveNationalAmount,
        Benefit_Income_Total__c = benifitTotal,
        Benefit_Income_Total_for_National__c = totalBenifitNationalAmount,
        Soliciated_Income_Total__c = soliciateEarmarkedTotal,
        Soliciated_Income_Total_for_National__c = totalsoliciateEarmarkedNationalAmount,
        In_Kind_Income_Total__c = in_KindTotal,
        In_kind_Income_Total_for_National__c = totalInkindNationalAmount,
        Unshared_Total__c  = unSharedIncomeTotal,
        Unshared_Total_National__c = unSharedIncomeTotalNational
        /* ,
        ReconGeneralIncentiveNat__c = reconGeneralIncentiveNat,
        ReconGeneralIncentiveAff__c = reconGeneralIncentiveAff,
        ReconGrant__c = reconGrant,
        ReconUnrestrNonMem__c = reconUnrestrNonMem,
        ReconUnsolEar__c = reconUnsolEar,
        ReconInKind__c = reconInKind,
        ReconSolEar__c = reconSolEar
        */
         );
    try {
      update updatedYearlyAffiliate;
      /*sending an email with report link*/
      Calculate_Reconciliation_Report_Status__c crrs = Calculate_Reconciliation_Report_Status__c.getOrgDefaults();
      String userName = '', fromAddress = '', toAddress = '';
      if (crrs != null) {
        userName = crrs.Receiver_Name__c;
        fromAddress = crrs.Sender_Email__c;
        toAddress = crrs.Receiver_Email_Id__c;
        if (crrs.Report_Request_In_Progress__c) {
          System.debug('Sending an email to requested user');
          isReportRunning = true;
          sendEmail(userName, fromAddress, toAddress, affiliateYearly);
          /*Update custom setting after sent an email to user*/
          updateCalculateReconciliationReportStatus();
        }
      }
    } catch (Exception e) {
      if (isReportRunning) {
        updateCalculateReconciliationReportStatus();
      }
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('RevSharing_Calc_Batch', 'updateRevenue', e.getMessage());
      log.logException(e);
      log.saveLogs();
    }
  }

  /*
  *
  *Method calculateNationalShare
  *@param : theOpp, costFactor, isCostFactorApply
  *@description : calculates the national Share.
  *
  */
  public Double calculateNationalShare(Opportunity theOpp, Double costFactor, Boolean isCostFactorApply) {
    Double nationalShareAmount = 0.0;
    if (eligibleForGMI) {
      if ( theOpp.Account.Total_Gifts_Amount_Current_FY__c == null || (theOpp.Account.Total_Gifts_Amount_Current_FY__c + theOpp.amount < 10000) ) {
        nationalShareAmount = ((100 - iGMI) / 100) * theOpp.Amount;
      } else {
        nationalShareAmount = 0.5 * theOpp.Amount;
      }
    } else if ((theOpp.Program_Type__c == '1' || theOpp.Program_Type__c == '2' || theOpp.Program_Type__c == '3' 
                || theOpp.Program_Type__c == '5') 
              || (
               ((indemnificationFromToday + affiliateActualIndeminification) > AffiliateYearlyAffiliateIndemnification) &&
                 ((nationalActualIndemnificationFromToday + nationalActualIndemnification) > NationalYearlyNationalIndemnification))
              ) {
      nationalShareAmount = 0.5 * theOpp.Amount;
    }

    if (isCostFactorApply) {
      nationalShareAmount = (nationalShareAmount * costFactor);
    }

    return nationalShareAmount;
  }

  /*
  *
  *Method calculateAffiliateShare
  *@param : theOpp, costFactor, isCostFactorApply
  *@description : calculates the affilate Share.
  *
  */
  public Double calculateAffiliateShare(Opportunity theOpp, Double costFactor, Boolean isCostFactorApply) {
    Double affiliateShareAmount = 0.0;
    if (eligibleForGMI) {
      if ( theOpp.Account.Total_Gifts_Amount_Current_FY__c == null || (theOpp.Account.Total_Gifts_Amount_Current_FY__c + theOpp.amount < 10000) ) {
        affiliateShareAmount = (theOpp.Amount * (iGMI / 100));
      } else {
        affiliateShareAmount = (theOpp.Amount * 0.5);

      }
    } else if ((theOpp.Program_Type__c == '1' || theOpp.Program_Type__c == '2' || theOpp.Program_Type__c == '3' 
                || theOpp.Program_Type__c == '5') 
               || (
                 ((indemnificationFromToday + affiliateActualIndeminification) > AffiliateYearlyAffiliateIndemnification) &&
                 ((nationalActualIndemnificationFromToday + nationalActualIndemnification) > AffiliateYearlyAffiliateIndemnification)
                 )
              ){
      affiliateShareAmount = (theOpp.Amount * 0.5);
    }

    if (isCostFactorApply) {
      affiliateShareAmount = (affiliateShareAmount * costFactor);
    }

    return affiliateShareAmount;
  }

  webservice static Boolean updateRevenue(Id affiliateYearlyId) {
    try {
      RevSharing_Calc_Batch batch = new RevSharing_Calc_Batch(affiliateYearlyId);
      Database.executeBatch(batch, 200);
      return true;
    } catch (Exception e) {
      return false;
    }
    return true;
  }
  /*send email with report url link*/
  public void sendEmail(String userName, String fromAddress, String toAddress, String afid) {
    List<String> sendTo = new List<String>();
    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    if (fromAddress != null && toAddress != null) {
      sendTo.add(toAddress);
      mail.setReplyTo(fromAddress);

      mail.setToAddresses(sendTo);
      mail.setSenderDisplayName('Report Request');
      mail.setSubject('Affiliate Yearly Report');
      String body = 'Hi ' + userName + ',<br/><br/>Calculations have completed for your Affiliate Yearly report request.';
      body += '<html><body><br/>Access the report from the URL:';
      body += '<br/><br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' 
           + 'apex/ReconciliationReport_Union?afid=' + afid + '">ReconciliationReport_Union</a>';
      body += '<br/>' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' 
           + 'apex/ReconciliationReport_Foundation?afid=' + afid + '">ReconciliationReport_Foundation</a>';
      body += '<br/><br/>If the link is not accessible please copy the below url in browser:';
      body += '<br/><br/>ReconciliationReport_Union: <b>' + URL.getSalesforceBaseUrl().toExternalForm() + '/' 
           + 'apex/ReconciliationReport_Union?afid=' + afid + '</b>';
      body += '<br/><br/>ReconciliationReport_Foundation: <b>' + URL.getSalesforceBaseUrl().toExternalForm()  + '/' 
           + 'apex/ReconciliationReport_Foundation?afid=' + afid + '</b>';
      body += '<br/></body></html>';

      mail.setHtmlBody(body);
      mails.add(mail);

    }
    //System.debug('mails:' + mails);
    if (!mails.IsEmpty()) {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails);
      //system.debug('Mail:' + results);
    }
  }
  public void updateCalculateReconciliationReportStatus() {
    Calculate_Reconciliation_Report_Status__c crrs = Calculate_Reconciliation_Report_Status__c.getOrgDefaults();
    crrs.Receiver_Name__c = '';
    crrs.Receiver_Email_Id__c = '';
    crrs.Report_Request_In_Progress__c = false;
    upsert crrs;
  }
}