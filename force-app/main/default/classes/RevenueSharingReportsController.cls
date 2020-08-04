/*
*
*Name  :  RevenueSharingReportsController
*Author:  Appirio India (Shikha Gupta)
*Date  :  Jan 30, 2017
*Purpose : Controller Class for CMI_Reports page
* Ticket 		Modified Date		Modified by				Purpose
* #75941        03/04/2020		 SFDO (Kirti Rathod)    Added BRI Affiliate Share field check*
* #77016        11/06/2020       SFDO (Kirti Rathod)    Added a timezone on the report*/
global with sharing class RevenueSharingReportsController {
  public transient List<Affiliate_Yearly__c> listOfRecords { get; set; }
  public AggregateResult result{get;set;}
  public static String startDate {get;set;}
  public static String endDate {get;set;}
  public static String  fiscalYear{get;set;}
  public static String todayDate{get;set;}
  public static Double totalAffiliateBRI{get;set;}
  public static Double totalNationalBRI{get;set;}
  public String dateTimezone{get;set;}//#77016
  static {
    Datetime myDatetime = Datetime.now();
    todayDate = myDatetime.format('EEE MMM d,  yyyy');
    fiscalYear = ApexPages.currentPage().getParameters().get('fiscalYear');
  }
  public RevenueSharingReportsController() {
      listOfRecords = new List<Affiliate_Yearly__c>();
      dateTimezone = System.now().format() +' ' + Utilities.getTimeZone();//#77016
      listOfRecords = [SELECT Id, Fiscal_Year__c, CMI_stage_DateStart__c, CMI_stage_DateEnd__c,Account__r.Affiliation__c, CMI_stage_Unshared_New__c,
                            CMI_stage_Unshared_New_Count__c, CMI_stage_Unshared_Recap__c, CMI_stage_Unshared_Recap_Count__c, CMI_stage_Unshared_FirstRenew__c,
                            CMI_stage_Unshared_FirstRenew_Count__c, Total_Unshared_Affiliate__c,
                            CMI_stage_Unshared_New_Nat__c, CMI_stage_Unshared_New_Nat_Count__c, CMI_stage_Unshared_Recap_Nat__c, CMI_stage_Unshared_Recap_Nat_Count__c,
                            CMI_stage_Unshared_FirstRenew_Nat__c, CMI_stage_Unshared_FirstRenew_Nat_Count__c,Unshared_National_Total_Count__c,
                            CMI_stage_UBRI_RenewalDues__c,CMI_stage_UBRI_RenewalDues_Count__c,Average_Of_Renewable_Dues__c,CMI_stage_UBRI_ExtraContribs__c,
                            CMI_stage_UBRI_ExtraContribs_Count__c, FCMI_NatAffAmount__c, Ration_of_Extra_Contributions__c, Total_BRI__c, NET_BRI__c, Eligible_for_GMI__c, BRI_Affiliate_Share__c,
                            Affil_Paid__c, Nat_l_Paid__c, Unshared_Total__c, UBRI_Total__c, UBRI_Total_for_National__c, Sum_Of_Unshared_and_UBRI_National_Total__c,
                            CMI_stage_UnsolicitedEarmarked__c, CMI_stage_RecogGrants__c, CMI_stage_Memorial__c, CMI_stage_Advertising__c, CMI_stage_GeneralIncentive__c,
                            CMI_stage_SolicitedEarmarked__c, CMI_stage_Benefit__c, Sum_Of_Unshared_and_UBRI_total__c,Incentive_Income_Total_for_National__c,
                            CMI_stage_Nat_Benefit__c, CMI_stage_Nat_SolicitedEarmarked__c, CMI_stage_Nat_GeneralIncentive__c,
                            Union_Cost_Factor__c, Incentive_Income_Total__c, Non_Membership_Nat_Unshared_Income_Total__c, CMI_stage_Nat_Memorial__c, Non_Membership_Unshared_Income_Total__c,
                            CMI_stage_Nat_UnsolicitedEarmarked__c, CMI_stage_Nat_RecogGrants__c, CMI_stage_Nat_Advertising__c
                            ,Total_Unshared_National__c,Unshared_NationalTotal__c, CMI_Stage_IncentiveAffilTotal__c, CMI_Stage_IncentiveNatTotal__c
                     FROM Affiliate_Yearly__c
                     WHERE Fiscal_Year__c = :fiscalYear
                     AND CMI_stage_DateStart__c  != NULL
                     AND CMI_stage_DateEnd__c != NULL
                     ORDER BY Account__r.Affiliation__c ASC];
      if(listOfRecords.size() > 0 && (!listOfRecords.isEmpty())) {
          result = [SELECT SUM(CMI_stage_Advertising__c) advertisingTotal, SUM(CMI_stage_GeneralIncentive__c) genIncentiveTotal, SUM(CMI_stage_SolicitedEarmarked__c) solicitedEnmarked,
                   SUM(CMI_stage_Benefit__c) benefit, SUM(Incentive_Income_Total__c) incentiveTotal, SUM(CMI_stage_Nat_Advertising__c) natAdvertising,
                   SUM(CMI_stage_Nat_GeneralIncentive__c) natGeneralIncentive, SUM(CMI_stage_Nat_SolicitedEarmarked__c) natSolicitedEnmarked,
                   SUM(CMI_stage_Nat_Benefit__c) natBenefit, SUM(Incentive_Income_Total_for_National__c) natIncentiveTotal,
                   SUM(Total_Unshared_National__c)unsharedNationalTotal, SUM(CMI_stage_UnsolicitedEarmarked__c) unsolicitedEarmarked, SUM(CMI_stage_RecogGrants__c) recogGrants, SUM(CMI_stage_Memorial__c) memorial,
                   SUM(CMI_Stage_IncentiveAffilTotal__c) stageIncentiveAffTotal, SUM(Non_Membership_Unshared_Income_Total__c) nonMembUnshIncTotal, SUM(CMI_stage_Nat_UnsolicitedEarmarked__c) natUnsolicitedEarmarked,
                   SUM(CMI_stage_Nat_RecogGrants__c) natRecoGrants, SUM(CMI_stage_Nat_Memorial__c) natMemorial,
                   SUM(Non_Membership_Nat_Unshared_Income_Total__c) nonMemNatUnsharedIncomeTotal,
                   SUM(FCMI_NatAffAmount__c) natAffAmount, SUM(Unshared_Total__c) unsharedTotal, SUM(UBRI_Total__c) UBRITotal, SUM(Sum_Of_Unshared_and_UBRI_total__c) unsharedAndUBRI,
                   SUM(CMI_Stage_IncentiveNatTotal__c) stageNationalIncentiveTotal, SUM(UBRI_Total_for_National__c) UBRITOtalForNat, SUM(Sum_Of_Unshared_and_UBRI_National_Total__c) totalOfSumOfUnsharedAndUBRI,
                   SUM(CMI_stage_UBRI_RenewalDues__c) renewableDues, SUM(CMI_stage_UBRI_RenewalDues_Count__c) renewableDuesCount,
                   AVG(Average_Of_Renewable_Dues__c) avgOfRenewableDues, SUM(CMI_stage_UBRI_ExtraContribs__c) extraContribs,
                   SUM(CMI_stage_UBRI_ExtraContribs_Count__c) extraContibsCount, AVG(Ration_of_Extra_Contributions__c) ratioOfExtraContribs,
                   SUM(Total_BRI__c) toalBRI, SUM(NET_BRI__c) netBRI, SUM(Affil_Paid__c) affilPaid, SUM(Nat_l_Paid__c) natPaid,
                   SUM(CMI_stage_Unshared_New__c) unsharedNew, SUM(CMI_stage_Unshared_New_Count__c) unsharedCount, SUM(CMI_stage_Unshared_Recap__c) unsharedRecap,
                   SUM(CMI_stage_Unshared_Recap_Count__c) unsharedRecapCount, SUM(CMI_stage_Unshared_FirstRenew__c) unsharedFirstRenew, SUM(CMI_stage_Unshared_FirstRenew_Count__c) renewCount,
                   SUM(Total_Unshared_Affiliate__c) unsharedAffiliate, SUM(CMI_stage_Unshared_New_Nat__c) unsharedNewNat, SUM(CMI_stage_Unshared_New_Nat_Count__c) unsharedNewNatcount,
                   SUM(CMI_stage_Unshared_Recap_Nat__c) unsharedRecapNat, SUM(CMI_stage_Unshared_Recap_Nat_Count__c) unsharedRecapNatCount,
                   SUM(CMI_stage_Unshared_FirstRenew_Nat__c) firstRenewNat, SUM(CMI_stage_Unshared_FirstRenew_Nat_Count__c) firstRenewNatCount,
                   SUM(Unshared_National_Total_Count__c) unsharedNationalCount,
                   SUM(Unshared_NationalTotal__c) totalUnsharedNational
            FROM Affiliate_Yearly__c
            WHERE Fiscal_Year__c = :fiscalYear
            AND CMI_stage_DateStart__c  != NULL
            AND CMI_stage_DateEnd__c != NULL
            GROUP BY Fiscal_Year__c
            LIMIT 1];
            startDate = listOfRecords.get(0).CMI_stage_DateStart__c != null ? (Datetime.newInstance(listOfRecords.get(0).CMI_stage_DateStart__c,Time.newInstance(12, 0, 0, 0))).format('d-MMM-yy') : '';
            endDate = listOfRecords.get(0).CMI_stage_DateEnd__c != null? (Datetime.newInstance(listOfRecords.get(0).CMI_stage_DateEnd__c,Time.newInstance(12, 0, 0, 0))).format('d-MMM-yy') :'';
      }
      totalAffiliateBRI = 0;
      totalNationalBRI = 0;
      for(Affiliate_Yearly__c aff : listOfRecords) {    
            if(aff.BRI_Affiliate_Share__c !=0 && aff.BRI_Affiliate_Share__c != null){//#75941 :: Added by - Kirti Rathod(SFDO)- Calculates the value only if BRI_Affiliate_Share__c is not null and 0       
                if(aff.Eligible_for_GMI__c) {   
                    totalAffiliateBRI += aff.NET_BRI__c;    
                } else {    
                    totalAffiliateBRI += aff.Affil_Paid__c; 
                    totalNationalBRI += aff.Nat_l_Paid__c;  
                }   
            }   
        }   
        
    }   
}