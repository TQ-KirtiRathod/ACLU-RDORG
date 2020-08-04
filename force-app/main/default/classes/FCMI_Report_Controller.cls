/*
*
*Name  :  FCMI_Report_Controller
*Author:  Appirio India (Shikha Gupta)
*Date  :  Feb 09, 2017
*Purpose : Controller Class for FCMI_Reports Page. This will pull the data from Affiliates Yearly for the FCMI eports
*Modified By : Kirti Rathod(SFDO) : 11-June-2020 #77016
*/
public with sharing class FCMI_Report_Controller {
  public transient List<Affiliate_Yearly__c> listOfRecords { get; set; }
  public AggregateResult result{get;set;}
  public static String  fiscalYear{get;set;}
  public static String todayDate{get;set;}
  public static String startDate {get;set;}
  public static String endDate {get;set;}
  public static Double totalAffBaseRenewableIncomeTotalColumn{get;set;}
  //public static Double totalNatAvgGift{get;set;}
  public static Double foundationCostFactor{get;set;}
  public String dateTimezone{get;set;}//#77016
  static {
    Datetime myDatetime = Datetime.now();
    todayDate = myDatetime.format('EEE MMM d,  yyyy');
    fiscalYear = ApexPages.currentPage().getParameters().get('fiscalYear');
    //totalAffBaseRenewableIncomeTotalColumn = 0;
    //totalNatAvgGift= 0;
    foundationCostFactor = 0;
  }
  public FCMI_Report_Controller() {
      listOfRecords = new List<Affiliate_Yearly__c>();
      totalAffBaseRenewableIncomeTotalColumn = 0;
      dateTimezone =  System.now().format() +' ' + Utilities.getTimeZone();
      listOfRecords =  [SELECT Id, Fiscal_Year__c, Account__r.Affiliation__c,FCMI_stage_DateStart__c,FCMI_stage_DateEnd__c,
                                            FCMI_NatDirectMailLess2500__c, FCMI_NatDirectMailLess2500_Count__c, FCMI_NatDirectMailLess2500_AvgGift__c,
                                            FCMI_NatDirectMailLess2500_NetAmount__c, FCMI_NatWorkplace__c, FCMI_TotalBRI__c, FCMI_NetBRI__c,
                                            FCMI_AFFInterim__c, FCMI_AFFIL_PAID__c, FCMI_NATL_PAID__c,
                                            FCMI_NatDirectMailGreater2500__c, FCMI_NatAdvertising__c, FCMI_NatGenIncentive__c, FCMI_NatBenefit__c,
                                            FCMI_NatSolEarmark__c, FCMI_NatInKind__c, FCMI_NatAffAmount__c, 
                                            FCMI_AffiliateBRI__c, FCMI_AffiliateBRI_Count__c,
                                            FCMI_DirectMailGreater2500__c, FCMI_Advertising__c, FCMI_GenIncentive__c, FCMI_Benefit__c,
                                            FCMI_SolEarmark__c, FCMI_InKind__c,
                                            FCMI_UnSolEarmark__c, FCMI_RecogGrant__c, FCMI_Memorial__c, FCMI_NatBanked__c, FCMI_AffBanked__c,
                                            FCMI_Endowment__c, FCMI_NatEndowment__c, FCMI_SpecialSharing__c,FCMI_EarlySharing__c, FCMI_NatSpecialSharing__c,
                                            FCMI_NatEarlySharing__c,Eligible_for_GMI__c, FCMI_NatUnSolEarmark__c, FCMI_NatRecogGrant__c, FCMI_NatMemorial__c,
                                            Foundation_Cost_Factor__c
                                     FROM Affiliate_Yearly__c
                                     WHERE Fiscal_Year__c = :fiscalYear
                                     AND FCMI_stage_DateStart__c  != NULL
                                     AND FCMI_stage_DateEnd__c != NULL
                                     ORDER BY Account__r.Affiliation__c ASC];
      if(listOfRecords.size() > 0 && !listOfRecords.isEmpty()) {
        result = [SELECT SUM(FCMI_NatDirectMailLess2500__c) totalNatDirectMail,
                        SUM(FCMI_NatDirectMailLess2500_Count__c) totalNatCount,
                        AVG(FCMI_NatDirectMailLess2500_AvgGift__c) totlNatAvgGift,
                        SUM(FCMI_NatDirectMailLess2500_NetAmount__c) totalNatNetamount,
                        SUM(FCMI_NatWorkplace__c) totalNatWorkPlace,
                        SUM(FCMI_TotalBRI__c) totalTotalBRI,
                        SUM(FCMI_NetBRI__c) totalNetBRI,
                        SUM(FCMI_AFFIL_PAID__c) totalaffilPaid,
                        SUM(FCMI_NatAffAmount__c) natAffAmount,
                        SUM(FCMI_NATL_PAID__c) totalNatlPaid,
                        SUM(FCMI_NatDirectMailGreater2500__c) totalDirMailGreater,
                        SUM(FCMI_NatAdvertising__c) toalFCMINatAdevrtising,
                        SUM(FCMI_NatGenIncentive__c) totalNatGenIncentive,
                        SUM(FCMI_NatBenefit__c) totalNatBenifit,
                        SUM(FCMI_NatSolEarmark__c) totalNatSolEarmarked,
                        SUM(FCMI_NatInKind__c) totalNatInKind,
                        SUM(FCMI_AffiliateBRI__c) totalAffBRI,
                        SUM(FCMI_AffiliateBRI_Count__c) totalAFFBRICount,
                        SUM(FCMI_DirectMailGreater2500__c) totalDirectMailGreater,
                        SUM(FCMI_Advertising__c) totalAdvertising,
                        SUM(FCMI_GenIncentive__c) totalGenIncentive,
                        SUM(FCMI_Benefit__c) totalBenifit,
                        SUM(FCMI_SolEarmark__c) totalSolEarmarked,
                        SUM(FCMI_InKind__c) totalInKind,
                        SUM(FCMI_UnSolEarmark__c) totalUnSolUnmarked,
                        SUM(FCMI_RecogGrant__c) totalFCMIRecogGrants,
                        SUM(FCMI_Memorial__c) totalFCMIMemorial,
                        SUM(FCMI_NatBanked__c) totalFCMINatBanked,
                        SUM(FCMI_AffBanked__c) totalFCMIAffBanked,
                        SUM(FCMI_Endowment__c) totalFCMIEndownment,
                        SUM(FCMI_NatEndowment__c) totalFCMINatEndownment,
                        SUM(FCMI_SpecialSharing__c) totalFCMISpecialSharing,
                        SUM(FCMI_EarlySharing__c) totalFCMIEarlySharing,
                        SUM(FCMI_NatSpecialSharing__c)totalFCMINatSpecialSharing,
                        SUM(FCMI_NatEarlySharing__c) totalFCMINatEarlySharing,
                        SUM(FCMI_NatUnSolEarmark__c) totalFCMINatUnsolEarmarked,
                        SUM(FCMI_NatRecogGrant__c) totalNatRecogGrants,
                        SUM(FCMI_NatMemorial__c) totalNatMemorial
        FROM Affiliate_Yearly__c
        WHERE Fiscal_Year__c = :fiscalYear
        AND FCMI_stage_DateStart__c  != NULL
        AND FCMI_stage_DateEnd__c != NULL
        GROUP BY Fiscal_Year__c
        LIMIT 1];
        totalAffBaseRenewableIncomeTotalColumn = listOfRecords.get(0).FCMI_AffiliateBRI__c != null && listOfRecords.get(0).FCMI_AffiliateBRI_Count__c != null && listOfRecords.get(0).FCMI_AffiliateBRI_Count__c!= 0
                                                   ? totalAffBaseRenewableIncomeTotalColumn + (listOfRecords.get(0).FCMI_AffiliateBRI__c / listOfRecords.get(0).FCMI_AffiliateBRI_Count__c)
                                                   : totalAffBaseRenewableIncomeTotalColumn;
        totalAffBaseRenewableIncomeTotalColumn = totalAffBaseRenewableIncomeTotalColumn/listOfRecords.size();
        //totalNatAvgGift = (listOfRecords.get(0).FCMI_NatDirectMailLess2500_Count__c != null
         //               && listOfRecords.get(0).FCMI_NatDirectMailLess2500_Count__c != 0
         //               && listOfRecords.get(0).FCMI_NatDirectMailLess2500__c != null)
         //                                          ? (totalNatAvgGift + (listOfRecords.get(0).FCMI_NatDirectMailLess2500__c / listOfRecords.get(0).FCMI_NatDirectMailLess2500_Count__c ))
         //                                          : totalNatAvgGift;
        foundationCostFactor = listOfRecords.get(0).Foundation_Cost_Factor__c != null ? listOfRecords.get(0).Foundation_Cost_Factor__c : 0;
        startDate = listOfRecords.get(0).FCMI_stage_DateStart__c != null ? (Datetime.newInstance(listOfRecords.get(0).FCMI_stage_DateStart__c,Time.newInstance(12, 0, 0, 0))).format('d-MMM-yy') : '';
        endDate = listOfRecords.get(0).FCMI_stage_DateEnd__c != null? (Datetime.newInstance(listOfRecords.get(0).FCMI_stage_DateEnd__c,Time.newInstance(12, 0, 0, 0))).format('d-MMM-yy') :'';

      }

    }

  }