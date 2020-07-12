/*
*
*Name  :  Reconcile_UnionNonGMIReportController
*Author:  Appirio India (James Wasilewski)
*Date  :  June 09, 2017
*Purpose :  Controller class for Reconcile_UnionNonGMIReport Page
            This class queries opp data and rolls up the amounts in various categories to support the reconciliation output and format
* Modified By: SFDO :: 12-Jun-19 zenDesk : #68073
*/
public with sharing class Reconcile_UnionNonGMIReportController {
 
  public static String todayDate{get;set;}
  public String affiliate {get;set;}
  public String fiscalYear {get;set;}
  private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
  private static Set<String> setOfRequiredCodes;
  private static set<String> setOfNationalCodes;
  private static Organization orgInfo; 

  public Date startDate{get;set;}
  public Date endDate {get;set;}
  public String reportLink {get;set;}
  public String reportLink2 {get;set;}

  public Affiliate_Yearly__c ay {get;set;}

  //public Decimal costFactor {get;set;}
  //public Decimal nationalFoundationBRI {get;set;}
  //public Decimal foundationCostFactor {get;set;}

  // Page v
  //section 1
  public Double one_a{get;set;}
  //section 2
  public Map<String, ScheduleContainer> two_a {get;set;}
  public Map<String, ScheduleContainer> two_b {get;set;}
  public Double two_a_total {get;set;}
  public Double two_b_total {get;set;}
  public Double two_c {get;set;}
  //section 3
  public Double three_a {get;set;}
  public Double three_b {get;set;}
  public Double three_c {get;set;}
  public Double three_d {get;set;}
  public Double three_e {get;set;}
  public Double three_g {get;set;}
  public Double three_h {get;set;}
  public Double three_i {get;set;}
  public Double three_j {get;set;}
  public Double three_k {get;set;}
  //section 4
  public Double four_j {get;set;}
  //section 5
  public Map<String, ITContainer> five {get;set;}
  public Double five_Total {get;set;}
  //section 6 - none
  public  static List<String> sharingAffiliationEntitySet;
  // Page w
  //Summary Affiliate Revenue Report
  //section A
  public Double a_1 {get;set;}
  public Double a_2 {get;set;}
  public Double a_3 {get;set;}
  public Double a_4 {get;set;}
  //section B
  public Double b_1 {get;set;}
  public Double b_2 {get;set;}
  //section C - none

  //schedule 1 mega gifts
  public Map<String, MegaGifts> s1_megaSched {get;set;}
  public Double s1_megaSchedTotal {get;set;}
  //schedule 2 affiliate benefit income
  public Double s2_totalE141 {get;set;}
  public Double s2_totalManualFields {get;set;}
  public List<Income_Type_Distribution__c> s2 {get;set;}
  //schedule III Affiliate Solicited Earmarked Gifts 
  public Map<String, ScheduleContainer> s3_SolEarmarked {get;set;}
  public Double s3_Total {get;set;}
  //schedule IV Affiliate In-Kind Gifts
  public List<Opportunity> s4_InKindGifts {get;set;}
  public Double s4_Total {get;set;}
  //schedule V Recognized Foundation
  public Map<String,ScheduleContainer> s5_AffilGifts {get;set;} // zenDesk : #68073
  public Double s5_Total {get;set;}
  //schedule VI Affiliate Unsolicited Earmarked Gifts
  public List<Opportunity> s6_UnsolGift {get;set;}
  public Double s6_Total {get;set;}
  //schedule VII Bequests and Planned Gifts
  public List<Opportunity> s7_u001 {get;set;}
  public Double s7_u001Total {get;set;}
  public List<Opportunity> s7_u002 {get;set;}
  public Double s7_u002Total {get;set;}
  public List<Opportunity> s7_u003 {get;set;}
  public Double s7_u003Total {get;set;}
  public List<Opportunity> s7_u004 {get;set;}
  public Double s7_u004Total {get;set;}
  public List<Opportunity> s7_u005 {get;set;}
  public Double s7_u005Total {get;set;}

  //page x
  //schedule 1 mega gifts without GMI
  public Map<String, MegaGifts> s1_megaSched_woGMI {get;set;}
  public Double s1_megaSchedTotal_woGMI {get;set;}
  //schedule 2 National Solicited Earmarked Gifts without GMI
  public Map<String, ScheduleContainer> s2_SolEarmarked_woGMI {get;set;}
  public Double s2_Total_woGMI {get;set;}
  //schedule 3 National Unsolicited Earmarked Gifts without GMI
  public Map<String,ScheduleContainer> s3_UnsolGift_woGMI {get;set;} // zenDesk: #68073
  public Double s3_Total_woGMI {get;set;}
  //schedule 4 Bequests and Planned Gifts without GMI
  public List<Opportunity> s4_u001_woGMI {get;set;}
  public Double s4_u001Total_woGMI {get;set;}
  public List<Opportunity> s4_u002_woGMI {get;set;}
  public Double s4_u002Total_woGMI {get;set;}
  public List<Opportunity> s4_u003_woGMI {get;set;}
  public Double s4_u003Total_woGMI {get;set;}
  public List<Opportunity> s4_u004_woGMI {get;set;}
  public Double s4_u004Total_woGMI {get;set;}
  public List<Opportunity> s4_u005_woGMI {get;set;}
  public Double s4_u005Total_woGMI {get;set;}
  //schedule IV National Foundation In-Kind Gifts
  public Map<String, ScheduleContainer> xs5_woGMI {get;set;}
  public Double xs5_Total_woGMI {get;set;}
  //schedule V National benefit income
  public Double xs6_totalR141 {get;set;}
  public Double xs6_totalManualFields {get;set;} 
  public Double xs6_totalAmount {get;set;} 
  public List<Income_Type_Distribution__c> xs6 {get;set;}



  static{
    Datetime myDatetime = Datetime.now();
    todayDate = myDatetime.format('MM/dd/yyyy hh:MM a');
    setOfRequiredCodes = new Set<String> {'E121','E131','E141','E151','E181','E191',
                                          'C161','C165',
                                          'U001','U002', 'U003', 'U004', 'U005' };

    setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};

    //Determine current fiscal year
    orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
               FROM Organization
               WHERE id=:Userinfo.getOrganizationId()
              ];
      sharingAffiliationEntitySet = new List<String>();
  }


  //contstuctor
  public Reconcile_UnionNonGMIReportController() {
    String afID = ApexPages.currentPage().getParameters().get('afid');
    ay = getAffiliateYearlyRecord(afID);
    affiliate = ay.Account__r.Affiliation__c;
    fiscalYear = ay.Fiscal_Year__c;
    
    //system.debug('affiliate '+affiliate);

    //set selection based on fiscal year
    integer endDateLastDay = Date.daysInMonth(integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1);
    startDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c)-1, orgInfo.FiscalYearStartMonth, 01);
    endDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1, endDateLastDay);
    system.debug('startDate:: '+startDate+' endDate::'+ endDate );
      
    //Zendesk: #68203 -- Get Deposit site from custom metadata Types
      sharingAffiliationEntitySet = Utilities.getDepositSiteSet(affiliate);
        
    //END:Zendesk: #68203

    List<Opportunity> listOfOpps = queryOpportunity(sharingAffiliationEntitySet,affiliate);//Zendesk: #68203

    If(listOfOpps.size()<7000){  
      reportLink = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=UnionNonGMI'
                    +'&startDate='+dateFormatter(startDate)+'&endDate='+dateFormatter(endDate)+'&affiliate='+affiliate;
    } else {
      Date splitDate = startDate.addMonths(6);
      reportLink = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=UnionNonGMI'
                    +'&startDate='+dateFormatter(startDate)+'&endDate='+dateFormatter(splitDate)+'&affiliate='+affiliate;

      reportLink2 = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=UnionNonGMI'
                    +'&startDate='+dateFormatter(splitDate.addDays(1))+'&endDate='+dateFormatter(endDate)+'&affiliate='+affiliate;
    }                     
    
    //costFactor = (ay.BRI_Affiliate_Share__c != null)?ay.BRI_Affiliate_Share__c:0;
    //nationalFoundationBRI = (ay.Incentive_National_Share__c != null)?ay.Incentive_National_Share__c:0;  
    //foundationCostFactor = (ay.Foundation_Cost_Factor__c != null)?ay.Foundation_Cost_Factor__c:0;    

    //one_a = (ay.ReconGeneralIncentiveAff__c != Null && ay.ReconGeneralIncentiveAff__c > 0)?ay.ReconGeneralIncentiveAff__c : 0;
    //one_b = (ay.ReconGeneralIncentiveNat__c !=Null && ay.ReconGeneralIncentiveNat__c > 0)? ay.ReconGeneralIncentiveNat__c : 0;
    //b_1 = (ay.ReconGrant__c != Null && ay.ReconGrant__c > 0)?ay.ReconGrant__c : 0;
    //b_2 = (ay.ReconUnsolEar__c != Null && ay.ReconUnsolEar__c > 0)?ay.ReconUnsolEar__c : 0;

    //page v
    one_a = 0;
    two_a = new Map<String, ScheduleContainer>();
    two_b = new Map<String, ScheduleContainer>();    
    two_a_total = two_b_total = two_c  = 0;
    three_a = three_b = three_c = three_d = three_e = 0;
    three_g = three_h = three_i = three_j = three_k = 0;
    four_j = 0;
    five = new Map<String, ITContainer>();
    five_Total = 0.0;

    //page w
    a_1 = a_2 = a_3 = a_4 = 0;
    b_1 = b_2 = 0;
    s1_megaSched = new Map<String, MegaGifts>();
    s1_megaSchedTotal = 0.0;    
    s2_totalE141 = 0;
    s2_totalManualFields = 0;
    s2 = new List<Income_Type_Distribution__c>();
    s3_SolEarmarked = new Map<String, ScheduleContainer>();
    s3_Total = 0.0;
    s4_InKindGifts = new List<Opportunity>();
    s4_Total = 0.0;   
    s5_AffilGifts = new Map<String,ScheduleContainer>();
    s5_Total = 0;
    s6_UnsolGift = new List<Opportunity>();
    s6_Total = 0.0;
    s7_u001 = new List<Opportunity>();
    s7_u002 = new List<Opportunity>();
    s7_u003 = new List<Opportunity>();
    s7_u004 = new List<Opportunity>();
    s7_u005 = new List<Opportunity>();
    s7_u001Total = 0.0;
    s7_u002Total = 0.0;
    s7_u003Total = 0.0;
    s7_u004Total = 0.0;
    s7_u005Total = 0.0;

    //page x
    s1_megaSched_woGMI = new Map<String, MegaGifts>();
    s1_megaSchedTotal_woGMI = 0.0;
    s2_SolEarmarked_woGMI = new Map<String, ScheduleContainer>();
    s2_Total_woGMI = 0.0;    
    s3_UnsolGift_woGMI = new Map<String, ScheduleContainer>();
    s3_Total_woGMI = 0;
    s4_u001_woGMI = new List<Opportunity>();
    s4_u002_woGMI = new List<Opportunity>();
    s4_u003_woGMI = new List<Opportunity>();
    s4_u004_woGMI = new List<Opportunity>();
    s4_u005_woGMI = new List<Opportunity>();
    s4_u001Total_woGMI = 0.0;
    s4_u002Total_woGMI = 0.0;
    s4_u003Total_woGMI = 0.0;
    s4_u004Total_woGMI = 0.0;
    s4_u005Total_woGMI = 0.0;
    xs5_woGMI = new Map<String, ScheduleContainer>();
    xs5_Total_woGMI = 0;
    xs6_totalR141 = 0;
    xs6_totalManualFields = xs6_totalAmount = 0;
    xs6 = new List<Income_Type_Distribution__c>();

    String depositSite = '';
    String packageCode = '';
    String key = '';

    if(listOfOpps.size() > 0){
      for(Opportunity o: listOfOpps){

        //system.debug('in loop '+'o.Sharing_Code__c '+ o.Sharing_Code__c + ' o.Deposit_Site__c '+ o.Deposit_Site__c + ' :: '+o.RPT_Package_Code__c+Campaign.Package_Code__c);
        o.rC_Giving__Source_Code__c = makeEmptyString(o.rC_Giving__Source_Code__c);
        if(o.Exclude_from_Revenue_Sharing__c == False && o.Amount !=null 
           && o.Deposit_Site__c != null && o.Deposit_Site__c != 'COS*' && o.Deposit_Site__c != 'NAE'
           && o.rC_Giving__Source_Code__c.left(3) != 'ENT' &&  o.Sharing_Code__c != 'T400' && o.Campaign_Type__c != 'T'
           ){
          packageCode = '';
          depositSite = '';

          //NOTE: by default all Sharing Entity matches affiliate
          depositSite = o.Deposit_Site__c.subString(0,2);
          if (o.RPT_Package_Code__c != null && o.RPT_Package_Code__c.length() >= 4 
              && o.RPT_Package_Code__c.subString(2, 4) == 'CP'){
            packageCode = o.RPT_Package_Code__c.subString(2, 4);
          } 
          if(( (o.Sharing_Code__c == 'E121' || o.Sharing_Code__c == 'E181')
               || (o.Sharing_Code__c == 'E131' && packageCode != 'CP') 
             ) && depositSite =='NA'){
            one_a += o.Amount;
          }
          if( (o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode == 'CP') )
              && depositSite =='NA' ){
            key = '';
            key = o.Restriction__c+' - '+o.Sharing_Code__c+' - '+packageCode;
            two_a_total += o.Amount;
            if ( !two_a.isEmpty() && two_a.containsKey(key) ) {
              two_a.get(key).amount += (o.Amount * 0.5);
              two_a.get(key).total += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.donor = ' @ 50% ' + o.Restriction__c;
              s.sharingCode = o.Sharing_Code__c;
              s.lffCampaign = packageCode;
              s.total = o.Amount;
              s.amount = (o.Amount * 0.5);
              two_a.put(key, s);
            }
          }
           //Zendesk: #68203 - Compare deposit site with opp's deposit site
            Boolean isDepositSiteSameAsAffiliate = false;
            isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(o
                                                          ,  sharingAffiliationEntitySet
                                                          ,  depositSite);
            //END:Zendesk: #68203
          //system.debug('jw OUT::  '+ o.id+' '+o.name +' '+o.Sharing_Code__c+' '+packageCode+' '+affiliate);
          if( (o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode == 'CP') ) 
              && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            key = '';
            key = o.Restriction__c+' - '+o.Sharing_Code__c+' - '+packageCode;
            two_b_total += o.Amount;
            if ( !two_b.isEmpty() && two_b.containsKey(key) ) {
              two_b.get(key).amount += (o.Amount * 0.5);
              two_b.get(key).total += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.donor = ' @ 50% ' + o.Restriction__c;
              s.sharingCode = o.Sharing_Code__c;
              s.lffCampaign = packageCode;
              s.total = o.Amount;
              s.amount = (o.Amount * 0.5);
              two_b.put(key, s);
            }
          }
          if(( o.Sharing_Code__c == 'E121' || (o.Sharing_Code__c == 'E131' && packageCode != 'CP') 
             ) && isDepositSiteSameAsAffiliate  ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            a_1 += o.Amount;
          }
          if(( o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode == 'CP') 
             ) && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            a_3 += o.Amount;
          }
          if( o.Sharing_Code__c == 'E181'  && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            a_4 += o.Amount;
          }
          if(o.Sharing_Code__c == 'C165' && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            b_1 += o.Amount;
          }
          if(o.Sharing_Code__c == 'C161' && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            b_2 += o.Amount;
          }
          //schedule I megaSched
          if(o.Sharing_Code__c == 'E191' && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            key = '';
            key = o.accountId +' - '+ packageCode;
            s1_megaSchedTotal += o.Amount;
            if(!s1_megaSched.isEmpty() && s1_megaSched.containsKey(key) ) {
              s1_megaSched.get(key).amount += o.Amount;
            } else {
              MegaGifts m = new MegaGifts();
              m.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              m.lffCampaign = packageCode;
              m.amount = o.Amount;
              s1_megaSched.put(key, m);
            }
          } 
          //schedule II
          if(o.Sharing_Code__c == 'E141' &&  isDepositSiteSameAsAffiliate  ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s2_totalE141 += o.Amount;
          }
          //schedule III Affiliate Solicited Earmarked Gifts
          if(o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode == 'CP') 
            && (isDepositSiteSameAsAffiliate ) ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            key = '';
            // Zendesk:  #68073 - Added extra restriction key
            key = o.accountId + ' - '+ o.Restriction__c + ' - '+packageCode;
            // Zendesk:  #68073
            s3_Total += o.Amount;
            if(!s3_SolEarmarked.isEmpty() && s3_SolEarmarked.containsKey(key) ) {
              s3_SolEarmarked.get(key).amount += o.Amount;
            } else {
              ScheduleContainer s = new ScheduleContainer();
              s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              s.sharingCode = o.Sharing_Code__c;
              s.depLoc = o.Deposit_Site__c;
              s.lffCampaign = packageCode;
              s.restriction = o.Restriction__c;
              s.amount = o.Amount;
              s3_SolEarmarked.put(key, s);
            }
          }
          //schedule IV Affiliate In-Kind Gifts
          if(o.Sharing_Code__c == 'E181' && isDepositSiteSameAsAffiliate  ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s4_InKindGifts.add(o);
            s4_Total += o.Amount;
          }
          System.debug('In this line');
          System.debug(o.id);
          //schedule V Affiliate Gifts
          // Zendesk:  #68073 - Created a map to show each row aggregated by Donor+Restriction+PackageCode
          if(o.Sharing_Code__c == 'C165' && (isDepositSiteSameAsAffiliate ) ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            key = '';
            key = o.accountId + ' - '+ o.Restriction__c+' - '+ packageCode;
            
            s5_Total += o.Amount;
            if(!s5_AffilGifts.isEmpty() && s5_AffilGifts.containsKey(key) ) {
              s5_AffilGifts.get(key).amount += o.Amount;
            } else {
              ScheduleContainer s = new ScheduleContainer();
              s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              s.lffCampaign = packageCode;
              s.restriction = o.Restriction__c;
              s.amount = o.Amount;
              s5_AffilGifts.put(key, s);
            }
            System.debug('s5_AffilGifts -->'+s5_AffilGifts);
          }
          // Zendesk:  #68073
          //schedule VI Affiliate Unsolicited Earmarked Gifts
          if(o.Sharing_Code__c == 'C161' && isDepositSiteSameAsAffiliate  ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s6_UnsolGift.add(o);
            s6_Total += o.Amount;
          }          
          //schedule VII Bequests and Planned Gifts
          if(o.Sharing_Code__c == 'U001' && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s7_u001.add(o);
            s7_u001Total += o.Amount;
            three_a += o.Amount;
          }
          if(o.Sharing_Code__c == 'U002' && isDepositSiteSameAsAffiliate){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s7_u002.add(o);
            s7_u002Total += o.Amount;
            three_b += o.Amount;
          }    
          if(o.Sharing_Code__c == 'U003' && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s7_u003.add(o);
            s7_u003Total += o.Amount;
            three_c += o.Amount;
          }    
          if(o.Sharing_Code__c == 'U004' && isDepositSiteSameAsAffiliate  ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s7_u004.add(o);
            s7_u004Total += o.Amount;
            three_d += o.Amount;
          }    
          if(o.Sharing_Code__c == 'U005' && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 - Added isDepositSiteSameAsAffiliate 
            s7_u005.add(o);
            s7_u005Total += o.Amount;
            three_e += o.Amount;
          }

          // page x
          //schedule I megaSched w/o gmi
          if(o.Sharing_Code__c == 'E191' && depositSite == 'NA' ){
            key = '';
            key = o.accountId +' - '+ packageCode;
            s1_megaSchedTotal_woGMI += o.Amount;
            if(!s1_megaSched_woGMI.isEmpty() && s1_megaSched_woGMI.containsKey(key) ) {
              s1_megaSched_woGMI.get(key).amount += o.Amount;
            } else {
              MegaGifts m = new MegaGifts();
              m.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              m.lffCampaign = packageCode;
              m.amount = o.Amount;
              s1_megaSched_woGMI.put(key, m);
            }
          }
          //schedule II National Solicited Earmarked Gifts w/o gmi
          if( (o.Sharing_Code__c == 'E151' 
              || (o.Sharing_Code__c == 'E131' && packageCode=='CP') ) && depositSite == 'NA' ){
            key = '';
            //zenDesk: #68073 - Added extra restrcition key 
            key = o.accountId +' - '+ o.Restriction__c+' - '+packageCode;
            //zenDesk: #68073    
            s2_Total_woGMI += o.Amount;
            if(!s2_SolEarmarked_woGMI.isEmpty() && s2_SolEarmarked_woGMI.containsKey(key) ) {
              s2_SolEarmarked_woGMI.get(key).amount += o.Amount;
            } else {
              ScheduleContainer s = new ScheduleContainer();
              s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              s.sharingCode = o.Sharing_Code__c;
              s.depLoc = o.Deposit_Site__c;
              s.lffCampaign = packageCode;
              s.restriction = o.Restriction__c;
              s.amount = o.Amount;
              s2_SolEarmarked_woGMI.put(key, s);
            }
          }
          //schedule III National Foundation Unsolicited Earmarked Gifts w/o GMI
          //zenDesk : #68073 - Created a map to show each row should be aggregated by Donor+Restriction+PackageCode
          System.debug(o.id);
          if(o.Sharing_Code__c == 'C161' && depositSite == 'NA' ){
                key = '';
                key = o.accountId +' - '+ o.Restriction__c +' - '+ packageCode;
                s3_Total_woGMI += o.Amount;
                if(!s3_UnsolGift_woGMI.isEmpty() && s3_UnsolGift_woGMI.containsKey(key) ) {
                  s3_UnsolGift_woGMI.get(key).amount += o.Amount;
                } else {
                  ScheduleContainer s = new ScheduleContainer();
                  s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
                  s.lffCampaign = packageCode;
                  s.restriction = o.Restriction__c;
                  s.amount = o.Amount;
                  s3_UnsolGift_woGMI.put(key, s);
                }
                
          }
          //schedule IV Bequests and Planned Gifts w/o GMI
          if(o.Sharing_Code__c == 'U001' && depositSite == 'NA' ){
            s4_u001_woGMI.add(o);
            s4_u001Total_woGMI += o.Amount;
            three_g += o.Amount;
          }
          if(o.Sharing_Code__c == 'U002' && depositSite == 'NA' ){
            s4_u002_woGMI.add(o);
            s4_u002Total_woGMI += o.Amount;
            three_h += o.Amount;
          }
          if(o.Sharing_Code__c == 'U003' && depositSite == 'NA' ){
            s4_u003_woGMI.add(o);
            s4_u003Total_woGMI += o.Amount;
            three_i += o.Amount;
          }
          if(o.Sharing_Code__c == 'U004' && depositSite == 'NA' ){
            s4_u004_woGMI.add(o);
            s4_u004Total_woGMI += o.Amount;
            three_j += o.Amount;
          }
          if(o.Sharing_Code__c == 'U005' && depositSite == 'NA' ){
            s4_u005_woGMI.add(o);
            s4_u005Total_woGMI += o.Amount;
            three_k += o.Amount;
          }
          //schedule V National Foundation In-Kind Gifts w/o GMI
          if(o.Sharing_Code__c == 'E181' && depositSite == 'NA' ){
            key = '';
            key = o.accountId +' - '+ packageCode;
            xs5_Total_woGMI += o.Amount;
            if(!xs5_woGMI.isEmpty() && xs5_woGMI.containsKey(key) ) {
              xs5_woGMI.get(key).amount += o.Amount;
            } else {
              ScheduleContainer s = new ScheduleContainer();
              s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              s.description = o.Description;
              s.amount = o.Amount;
              xs5_woGMI.put(key, s);
            }
          }
          //schedule VI National Foundation Benefit Income w/o GMI
          if(o.Sharing_Code__c == 'E141' && depositSite == 'NA' ){
            xs6_totalR141 += o.Amount;
          }
        }
      }//end o for
    }
    two_c = (two_a_total*0.5)-(two_b_total*0.5);


    List<Income_Type_Distribution__c> incomeTypes = getIncomeTypeDistRecords(afID);

    if(incomeTypes.size() > 0){
      for(Income_Type_Distribution__c it: incomeTypes){
        it.Amount_National_to_Affiliate__c=makeOperandable(it.Amount_National_to_Affiliate__c);
        it.Amount_Affiliate_to_National__c=makeOperandable(it.Amount_Affiliate_to_National__c);
        it.Expense__c = makeOperandable(it.Expense__c);
        it.Income__c = makeOperandable(it.Income__c);
        it.Amount__c = makeOperandable(it.Amount__c);

        if( (it.Income_Type__c =='Unrestricted Bequest / Planned Gift' || it.Income_Type__c =='Earmarked Bequest') 
            && it.Fund_Type__c=='Union' && it.Shared_in_Advance__c==True
          ){
         four_j += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c); 
        } else if (it.Fund_Type__c=='Union' && it.recordtype.name=='Other Income Types'){
            key = '';
            key = it.Description__c+it.Fund_Type__c;
            five_Total += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
            if(!five.isEmpty() && five.containsKey(key) ) {
              five.get(key).amount += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
            } else {
              ITContainer x = new ITContainer();
              x.description = it.Description__c;
              x.amount = (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
              five.put(key, x);
            }
        }
        //section II affiliate benefit income
        if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Union' && it.Event_Hosted_By__c=='Affiliate' ){
          a_2 += it.Amount__c;
          s2_totalManualFields += it.Income__c;
          s2.add(it);
        }
        //schedule VI National Foundation Benefit Income w/o GMI
        if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Foundation' && it.Event_Hosted_By__c=='National'){
          xs6.add(it);
          xs6_totalManualFields += it.Income__c;
          xs6_totalAmount += it.Amount__c;
        }
      }//end it for
    }
    xs6_totalManualFields=(xs6_totalManualFields>0)?xs6_totalManualFields:0;
    a_2 = (a_2>0)?a_2:0;
    one_a += xs6_totalAmount;

  }// end constructor



  public class MegaGifts {
    public String donor {get;set;}
    public String lffCampaign {get;set;}
    public Double amount {get;set;}
  }
  public class ScheduleContainer{
    public Double total {get;set;}
    public String donor {get;set;}
    public String sharingCode {get;set;}
    public String depLoc {get;set;}
    public String lffCampaign {get;set;}
    public String restriction {get;set;}
    public String description {get;set;}
    public Double amount {get;set;}
  }
  public class ITContainer {
    public String description {get;set;}
    //public String lffCampaign {get;set;}
    public Double amount {get;set;}
  }

  private String dateFormatter(Date d) {
    DateTime dt = datetime.newInstance(d.year(), d.month(),d.day());
    return(dt.format('yyyy-MM-dd'));
  }
  private Decimal makeOperandable(Decimal input) { return (input == null) ? 0 : input; }
  private String makeEmptyString(String input) { return (input == null) ? '' : input; }
  
// using name, amount Exclude_Cost_Factors_in_RevShare__c RPT_Revenue_Type__c Restriction__c
  private List<Opportunity> queryOpportunity(List<String> sharingAffiliationEntitySet,String accAffiliationCode){
    return [SELECT Id, Amount, Name, accountId, account.name, account.Account_Number__c, Sharing_Entity_Affiliation__c, 
              Sharing_Entity__c, Description,
              Exclude_from_Revenue_Sharing__c, Sharing_Code__c, RecordTypeId, RPT_Revenue_Type__c ,Restriction__c,
              Deposit_Site__c,  CloseDate, RPT_Package_Code__c, rC_Giving__Source_Code__c, Campaign_Type__c
              //,Campaign.Package_Code__c
              //Use_Campaign_Cost__c,,   Cost_Factor__c, Exclude_Cost_Factors_in_RevShare__c,
              //Program_Type__c,
             FROM Opportunity
             WHERE RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                     :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                     :OPPORTUNITY_RT_SOFTCREDIT_Id)
             AND Sharing_Code__c IN :setOfRequiredCodes
             AND Amount > 0
             AND (Sharing_Entity_Affiliation__c =: sharingAffiliationEntitySet
                  OR (Account_Affiliation__c =: accAffiliationCode AND Sharing_Entity_Affiliation__c IN : setOfNationalCodes)
                 )
             AND stageName = 'Completed'
             AND CloseDate >= :startDate AND CloseDate <= :endDate];
  }

  private Affiliate_Yearly__c getAffiliateYearlyRecord(String accAffiliationCode){
    return [SELECT ReconGeneralIncentiveAff__c, ReconGeneralIncentiveNat__c, To_Be_Shared__c, Unshared_Total__c, 
            ReconUnrestrNonMem__c, ReconSolEar__c, ReconInKind__c, ReconGrant__c, ReconUnsolEar__c, 
            Misc_Affiliate_Costs_Total__c, Account__r.Affiliation__c, Fiscal_Year__c, BRI_Affiliate_Share__c,
            National_Indemnification_Threshold__c, Affiliate_Indemnification_Threshold__c, Incentive_National_Share__c,
            Foundation_Cost_Factor__c
            FROM Affiliate_Yearly__c 
            WHERE id= :accAffiliationCode LIMIT 1];
  }
//  Gift__c need to add revenue type to this record

  private List<Income_Type_Distribution__c> getIncomeTypeDistRecords(String afID){
    return [SELECT id, Income_Type__c, Affiliate_Yearly__c, Amount__c,Description__c ,
              Shared_in_Advance__c, Gift__r.Name, Fund_Type__c, Expense__c, Income__c, //Gift__r.RPT_Revenue_Type__c,
              Gift__r.Deposit_Site__c, recordtype.name, Event_Hosted_By__c, 
              Amount_National_to_Affiliate__c, Amount_Affiliate_to_National__c
            FROM Income_Type_Distribution__c 
            WHERE Affiliate_Yearly__c =: afID];
  }

}