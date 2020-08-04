/*
*
*Name  :  Reconcile_UnionGMIReportController
*Author:  Appirio India (James Wasilewski)
*Date  :  June 16, 2017
*Purpose :  Controller class for Reconcile_UnionGMIReport Page
            This class queries opp data and rolls up the amounts in various categories to support the reconciliation output and format"
* Modified by :: Salesforce.org :: 08-July-2019 :: Zendesk: #68792
* Modified by :: Salesforce.org :: 18-June-2019 :: Zendesk: #68203,#63855
* Modified by :: Salesforce.org :: 14-July-2020 :: ACLU: #78235
* Description :: the reports contain gifts within the 2 old KM Deposit Sites only (KM_Kansas and KMW_Kansas_web) - it is missing KS and KSW
*/
public with sharing class Reconcile_UnionGMIReportController {

  public static String todayDate{get;set;}
  public String affiliate {get;set;}
  public static List<String> sharingAffiliationEntitySet;
  private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
  private static Set<String> setOfRequiredCodes;
  private static set<String> setOfNationalCodes;
  private static Organization orgInfo;
  public String fiscalYear {get;set;}

  public Date startDate{get;set;}
  public Date endDate {get;set;}
  public String reportLink {get;set;}
  public String reportLink2 {get;set;}
  
  public Affiliate_Yearly__c ay {get;set;}
  public Decimal briAffiliateShare {get;set;}
  //public Decimal nationalFoundationBRI {get;set;}
  //public Decimal foundationCostFactor {get;set;}  

  //tab v
  public List<Donors_Over_10K__c> one {get;set;}
  public Double one_c2Total {get;set;}
  public Double one_c3Total {get;set;}
  public Double one_c4Total {get;set;}
  public Double one_c5Total {get;set;}
  public Double one_c6Total {get;set;}
  public Double one_c7Total {get;set;}
  public Double one_c8Total {get;set;}
  
  public Double two_a {get;set;}
  public Double two_b {get;set;}

  public Map<String, ScheduleContainer> three_a {get;set;}
  public Double three_aTotal {get;set;}
  public Map<String, ScheduleContainer> three_b {get;set;}
  public Double three_bTotal {get;set;}

  public Double five_j {get;set;}

  public Map<String, ITContainer> six {get;set;}
  public Double six_Total {get;set;}


  //tab w
  public Double a_1a {get;set;}
  public Double a_1b {get;set;}

  //schedule 1 mega gifts
  public Map<String, ScheduleContainer> s1_megaSched {get;set;}
  public Double s1_megaSchedTotal {get;set;}
  //schedule II Affiliate Unrestricted & Earmarked Gifts 
  public List<Opportunity> s2_UnresEarmarked {get;set;}
  public Double s2_Total {get;set;}
  //schedule 3 affiliate benefit income
  public Double s3_TotalE141 {get;set;}
  public Double s3_TotalMaual {get;set;}
  public Double s3_TotalAmount {get;set;}
  public List<Income_Type_Distribution__c> s3 {get;set;}
  //schedule IV Affiliate Solicited Earmarked Gifts 
  public List<Opportunity> s4_SolEarmarked {get;set;}
  public Double s4_Total {get;set;}
  //schedule V Affiliate In-Kind Gifts
  public List<Opportunity> s5_InKindGifts {get;set;}
  public Double s5_Total {get;set;}
  //schedule VI Affiliate Recognized Institutional Grants
  public List<Opportunity> s6_RecInstGrants {get;set;}
  public Double s6_Total {get;set;}
  //schedule VII Affiliate Unsolicited Earmarked Gifts
  public List<Opportunity> s7_UnsolGift {get;set;}
  public Double s7_Total {get;set;}
  //schedule VIII Bequests and Planned Gifts
  public List<Opportunity> s8_u001 {get;set;}
  public Double s8_u001Total {get;set;}
  public List<Opportunity> s8_u002 {get;set;}
  public Double s8_u002Total {get;set;}
  public List<Opportunity> s8_u003 {get;set;}
  public Double s8_u003Total {get;set;}
  public List<Opportunity> s8_u004 {get;set;}
  public Double s8_u004Total {get;set;}
  public List<Opportunity> s8_u005 {get;set;}
  public Double s8_u005Total {get;set;}

  //tab x
  //schedule 1 mega gifts without GMI
  public Map<String, ScheduleContainer> s1_megaSched_woGMI {get;set;}
  public Double s1_megaSchedTotal_woGMI {get;set;}
  //schedule 2 National Unrestricted and Earmarked Gifts over $10k without GMI
  public List<Opportunity> s2_Unrestricted_woGMI {get;set;}
  public Double s2_Total_woGMI {get;set;}
  //schedule 3 National Solicited Earmarked Gifts without GMI
  public List<Opportunity> s3_SolEarmarked_woGMI {get;set;}
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
  //schedule 5 National In-Kind Gifts
  public List<Opportunity> xs5_InKindGifts {get;set;}
  public Double xs5_Total {get;set;}
  //schedule 6 National benefit income
  public Double xs6_TotalE141 {get;set;}
  public Double xs6_TotalMaual {get;set;} 
  public Double xs6_TotalAmount {get;set;}
  public List<Income_Type_Distribution__c> xs6 {get;set;}

  //#63855
  private static Set<String> sharingEntitySet;


  static{
    Datetime myDatetime = Datetime.now();
    todayDate = myDatetime.format('EEE MMM d,  yyyy');
  
    setOfRequiredCodes = new Set<String> {'E121','E131','E141','E151','E181','E191',
                                          'C161','C165',
                                          'U001','U002', 'U003', 'U004', 'U005' };

    setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};
    sharingAffiliationEntitySet = new List<String>();

    //Determine current fiscal year
    orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
               FROM Organization
               WHERE id=:Userinfo.getOrganizationId()
               ];
  }



    //constructor
  public Reconcile_UnionGMIReportController() {
        String afID = ApexPages.currentPage().getParameters().get('afid');
    ay = getAffiliateYearlyRecord(afID);
    affiliate = ay.Account__r.Affiliation__c;
    fiscalYear = ay.Fiscal_Year__c;
    
    //Zendesk: #68203 -- Get Deposit site from custom metadata Types
    sharingAffiliationEntitySet = Utilities.getDepositSiteSet(affiliate);
    //END:Zendesk: #68203

    // Changed by: Amar Kulkarni [rC] Date: 06/25/2018
    // I-330079 : [Revenue Reconciliation] Union GMI report missing Incentive Share (GMI) in calculation for v1b
    // Changed the formula to National Share from BRI Affiliate Share
    //briAffiliateShare = (ay.BRI_Affiliate_Share__c != null)?ay.BRI_Affiliate_Share__c:0;
    briAffiliateShare = (ay.Incentive_National_Share__c != null)?ay.Incentive_National_Share__c:0;
    //nationalFoundationBRI = (ay.Incentive_National_Share__c != null)?ay.Incentive_National_Share__c:0;
    //foundationCostFactor = (ay.Foundation_Cost_Factor__c != null)?ay.Foundation_Cost_Factor__c:0; 

    //set selection based on fiscal year
    integer endDateLastDay = Date.daysInMonth(integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1);
    startDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c)-1, orgInfo.FiscalYearStartMonth, 01);
    endDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1, endDateLastDay);
    


    List<Opportunity> listOfOpps = queryOpportunity(affiliate);
    
    If(listOfOpps.size()<7000){
      reportLink = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=UnionGMI'
                    +'&startDate='+dateFormatter(startDate)+'&endDate='+dateFormatter(endDate)+'&affiliate='+affiliate;
    } else {
      Date splitDate = startDate.addMonths(6);
      reportLink = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=UnionGMI'
                    +'&startDate='+dateFormatter(startDate)+'&endDate='+dateFormatter(splitDate)+'&affiliate='+affiliate;

      reportLink2 = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=UnionGMI'
                    +'&startDate='+dateFormatter(splitDate.addDays(1))+'&endDate='+dateFormatter(endDate)+'&affiliate='+affiliate;
    }


    //tab v
    one = new List<Donors_Over_10K__c>();
    one = getDonorsOver10K(afid);
    one_c2Total = one_c3Total = one_c4Total = one_c5Total = one_c6Total = one_c7Total = one_c8Total = 0;
    Set<Id> donorsOver10KAccountIds = new Set<Id>();

    for(Donors_Over_10K__c d : one){
      Id donorID = d.Account__c;
      donorsOver10KAccountIds.add(donorID);
      one_c2Total += makeOperandable(d.Banked_by_Affiliate_Fdn__c);
      one_c3Total += makeOperandable(d.Banked_by_National_Fdn__c);
      one_c4Total += makeOperandable(d.Total_Banked__c);
      one_c5Total += makeOperandable(d.Base_Amount__c);
      one_c6Total += makeOperandable(d.Excess_Over_10K__c);
      one_c7Total += makeOperandable(d.Affiliate_CP_and_Earmark_Info__c);
      one_c8Total += makeOperandable(d.National_CP_and_Earmark_Info__c);
    }
    
    two_a = two_b = 0;
    three_a = new Map<String, ScheduleContainer>();
    three_b = new Map<String, ScheduleContainer>();
    three_aTotal = three_bTotal = 0;
    five_j = 0;
    six_Total = 0;
    six = new Map<String, ITContainer>();
    
    //tab w
    a_1a = a_1b = 0;
    //init variables logic in if/loop
    s1_megaSched = new Map<String, ScheduleContainer>();
    s1_megaSchedTotal = 0;
    s2_UnresEarmarked = new List<Opportunity>();
    s2_Total = 0;
    s3_TotalE141 = 0;
    s3_TotalMaual = s3_TotalAmount= 0;
    s3 = new List<Income_Type_Distribution__c>();
    s4_SolEarmarked= new List<Opportunity>();
    s4_Total = 0;
    s5_InKindGifts= new List<Opportunity>();
    s5_Total = 0;
    s6_RecInstGrants = new List<Opportunity>();
    s6_Total = 0;
    s7_UnsolGift = new List<Opportunity>();
    s7_Total = 0;
    s8_u001 = new List<Opportunity>();
    s8_u001Total = 0;
    s8_u002 = new List<Opportunity>();
    s8_u002Total = 0;
    s8_u003 = new List<Opportunity>();
    s8_u003Total = 0;
    s8_u004 = new List<Opportunity>();
    s8_u004Total = 0;
    s8_u005 = new List<Opportunity>();
    s8_u005Total = 0;

    //tab x
    s1_megaSched_woGMI = new Map<String, ScheduleContainer>();
    s1_megaSchedTotal_woGMI = 0;
    s2_Unrestricted_woGMI = new List<Opportunity>();
    s2_Total_woGMI = 0;
    s3_SolEarmarked_woGMI = new List<Opportunity>();
    s3_Total_woGMI = 0;
    s4_u001_woGMI = new List<Opportunity>();
    s4_u001Total_woGMI = 0;
    s4_u002_woGMI = new List<Opportunity>();
    s4_u002Total_woGMI = 0;
    s4_u003_woGMI = new List<Opportunity>();
    s4_u003Total_woGMI = 0;
    s4_u004_woGMI = new List<Opportunity>();
    s4_u004Total_woGMI = 0;
    s4_u005_woGMI = new List<Opportunity>();
    s4_u005Total_woGMI = 0;
    xs5_InKindGifts = new List<Opportunity>();
    xs5_Total = 0;
    xs6_TotalE141 = xs6_TotalMaual = xs6_TotalAmount = 0;
    xs6 = new List<Income_Type_Distribution__c>();

    String depositSite = '';
    String packageCode = '';
    String key = '';

    if(listOfOpps.size() > 0){
      for(Opportunity o: listOfOpps){
        
        o.rC_Giving__Source_Code__c = makeEmptyString(o.rC_Giving__Source_Code__c);
        if(o.Exclude_from_Revenue_Sharing__c == False && o.Amount !=null
           && o.Deposit_Site__c != null && o.Deposit_Site__c != 'COS*' && o.Deposit_Site__c != 'NAE'
           && o.rC_Giving__Source_Code__c.left(3) != 'ENT' &&  o.Sharing_Code__c != 'T400' && o.Campaign_Type__c != 'T'
           ){
          packageCode = '';
          depositSite = '';

          //NOTE: by default all Sharing Entity matches affiliate
          depositSite = o.Deposit_Site__c.subString(0,2);
          if (o.RPT_Package_Code__c !=null && o.RPT_Package_Code__c.length()>=4 
              && o.RPT_Package_Code__c.subString(2, 4) == 'CP'){
            packageCode = o.RPT_Package_Code__c.subString(2, 4);
          }
            //Zendesk: #68203
          
            Boolean isDepositSiteSameAsAffiliate = false;
            isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(o
                                                          ,  sharingAffiliationEntitySet
                                                          ,  depositSite);
            //END:Zendesk: #68203

          /* Modified by: Amar Kulkarni(rC) : 28th Jun'18
          *  Case: I-330516:: Union GMI report v2a Gross National-Banked union incentive income from donors under 10K is not calculating correctly
          *  Change > packageCode <> 'CP'
          */
          if( (o.Sharing_Code__c == 'E121'  || o.Sharing_Code__c == 'E181' 
               || (o.Sharing_Code__c == 'E131' && packageCode !='CP') )
              && depositSite == 'NA' && !donorsOver10KAccountIds.contains(o.AccountId)
              ){
            two_a += o.Amount;
          }
          if( (o.Sharing_Code__c == 'E121' || o.Sharing_Code__c == 'E181' 
               || (o.Sharing_Code__c == 'E131') )//ACLU: #78235:: Removed package code from the condition
              && isDepositSiteSameAsAffiliate  
              && !donorsOver10KAccountIds.contains(o.AccountId)){
            two_b += o.Amount;
          }
          if( (o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode =='CP'))
              && depositSite == 'NA'  && !donorsOver10KAccountIds.contains(o.AccountId)){
            key= '';
            key = o.Restriction__c+' - '+o.Sharing_Code__c +' - '+packageCode;
            three_aTotal += o.Amount;
            if ( !three_a.isEmpty() && three_a.containsKey(key) ) {
              three_a.get(key).amount += (o.Amount * briAffiliateShare)/100;
              three_a.get(key).total += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.total = o.Amount;
              s.amount = (o.Amount * briAffiliateShare)/100;
              s.donor =  ' @ 74.00% '+ o.Restriction__c;
              s.campaign = packageCode;
              s.sharingCode = o.Sharing_Code__c;
              three_a.put(key, s);
            }
          }
          if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'E131' && packageCode =='CP'))
              && isDepositSiteSameAsAffiliate && !donorsOver10KAccountIds.contains(o.AccountId)){
            key= '';
            key = o.Restriction__c+' - '+o.Sharing_Code__c +' - '+packageCode;
            three_bTotal += o.Amount;
            if ( !three_b.isEmpty() && three_b.containsKey(key) ) {
              three_b.get(key).amount += (o.Amount * (100-briAffiliateShare)/100);
              three_b.get(key).total += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.total = o.Amount;
              s.amount = (o.Amount * (100-briAffiliateShare)/100);
              s.donor =  ' @ 26.00% '+ o.Restriction__c;
              s.campaign = packageCode;
              s.sharingCode = o.Sharing_Code__c;
              three_b.put(key, s);
            }
          }
          if( (o.Sharing_Code__c == 'E151' || o.Sharing_Code__c == 'E131' || o.Sharing_Code__c == 'E121' )
            && isDepositSiteSameAsAffiliate && donorsOver10KAccountIds.contains(o.AccountId)){
            a_1a += o.Amount;
            //continue;
          }
          if( (o.Sharing_Code__c == 'E121' || (o.Sharing_Code__c == 'E131' && packageCode != 'CP') )
              && isDepositSiteSameAsAffiliate  && !donorsOver10KAccountIds.contains(o.AccountId)){
            a_1b += o.Amount;
          }
          //schedule 1 mega gifts
          if(o.Sharing_Code__c == 'E191' && isDepositSiteSameAsAffiliate){
            key= '';
            key = o.AccountId +' - '+packageCode;
            s1_megaSchedTotal += o.Amount;
            if ( !s1_megaSched.isEmpty() && s1_megaSched.containsKey(key) ) {
              s1_megaSched.get(key).amount += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.amount = o.Amount;
              s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              s.campaign = packageCode;
              s1_megaSched.put(key, s);
            }
          }
          //schedule II Affiliate Unrestricted & Earmarked Gifts 
          if( (o.Sharing_Code__c == 'E151' || o.Sharing_Code__c == 'E131' || o.Sharing_Code__c == 'E121')
             && isDepositSiteSameAsAffiliate && donorsOver10KAccountIds.contains(o.AccountId) ){
            s2_UnresEarmarked.add(o);
            s2_Total = 0;
          }
          //schedule 3 affiliate benefit income
          if(o.Sharing_Code__c == 'E141' && isDepositSiteSameAsAffiliate ){
            s3_TotalE141 += o.Amount;
          }
          //schedule IV Affiliate Solicited Earmarked Gifts 
          if( (o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode == 'CP') )
             && isDepositSiteSameAsAffiliate && donorsOver10KAccountIds.contains(o.AccountId) ){
            s4_SolEarmarked.add(o);
            s4_Total += o.Amount;
          }
          //schedule V Affiliate In-Kind Gifts
          if(o.Sharing_Code__c == 'E181' && isDepositSiteSameAsAffiliate ){
            s5_InKindGifts.add(o);
            s5_Total += o.Amount;
          }
          //schedule VI Affiliate Recognized Institutional Grants
          if(o.Sharing_Code__c == 'C165' && isDepositSiteSameAsAffiliate ){
            s6_RecInstGrants.add(o);
            s6_Total += o.Amount;
          }
          //schedule VI Affiliate Recognized Institutional Grants
          if(o.Sharing_Code__c == 'C161' && isDepositSiteSameAsAffiliate ){
            s7_UnsolGift.add(o);
            s7_Total += o.Amount;
          }
          //schedule VII Bequests and Planned Gifts
          if(o.Sharing_Code__c == 'U001' && isDepositSiteSameAsAffiliate ){
            s8_u001.add(o);
            s8_u001Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'U002' && isDepositSiteSameAsAffiliate ){
            s8_u002.add(o);
            s8_u002Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'U003' && isDepositSiteSameAsAffiliate ){
            s8_u003.add(o);
            s8_u003Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'U004' && isDepositSiteSameAsAffiliate ){
            s8_u004.add(o);
            s8_u004Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'U005' && isDepositSiteSameAsAffiliate ){
            s8_u005.add(o);
            s8_u005Total += o.Amount;
          }

          //TAB X
          //schedule 1 mega gifts without GMI
          if(o.Sharing_Code__c == 'E191' && depositSite =='NA' ){
            key= '';
            key = o.AccountId +' - '+packageCode;
            s1_megaSchedTotal_woGMI += o.Amount;
            if ( !s1_megaSched_woGMI.isEmpty() && s1_megaSched_woGMI.containsKey(key) ) {
              s1_megaSched_woGMI.get(key).amount += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.amount = o.Amount;
              s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
              s.campaign = packageCode;
              s1_megaSched_woGMI.put(key, s);
            }
          }
          /* Modified by: Amar Kulkarni(rC) : 28th Jun'18
          *  Case: I-330516:: Union GMI report v2a Gross National-Banked union incentive income from donors under 10K is not calculating correctly
          *  Change > Added a condition donorsOver10KAccountIds.contains(o.AccountId) so that it should not work for < 10K scenarios
          */
          //National Unrestricted and Earmarked for Total Incentive Gifts over $10k
          if((o.Sharing_Code__c == 'E151' || o.Sharing_Code__c == 'E131' || o.Sharing_Code__c == 'E121')
             && depositSite =='NA' && donorsOver10KAccountIds.contains(o.AccountId)){
            s2_Unrestricted_woGMI.add(o);
            s2_Total_woGMI += o.Amount;
          }
          //schedule 3 National Solicited Earmarked Gifts without GMI
          if( (o.Sharing_Code__c == 'E151' || (o.Sharing_Code__c == 'E131' && packageCode == 'CP'))
             && depositSite =='NA' ){
            s3_SolEarmarked_woGMI.add(o);
            s3_Total_woGMI += o.Amount;
          }
          //schedule 4 Bequests and Planned Gifts without GMI
          if(o.Sharing_Code__c == 'U001' && depositSite =='NA' ){
            s4_u001_woGMI.add(o);
            s4_u001Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'U002' && depositSite =='NA' ){
            s4_u002_woGMI.add(o);
            s4_u002Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'U003' && depositSite =='NA' ){
            s4_u003_woGMI.add(o);
            s4_u003Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'U004' && depositSite =='NA' ){
            s4_u004_woGMI.add(o);
            s4_u004Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'U005' && depositSite =='NA' ){
            s4_u005_woGMI.add(o);
            s4_u005Total_woGMI += o.Amount;
          }
          //schedule V Affiliate In-Kind Gifts
          if(o.Sharing_Code__c == 'E181' && depositSite =='NA' ){
            xs5_InKindGifts.add(o);
            xs5_Total += o.Amount;
          }
          //schedule III affiliate benefit income
          if(o.Sharing_Code__c == 'E141' && depositSite =='NA' ){
            xs6_TotalE141 += o.Amount;
          }
        }
      } // END FOR
    }


      List<Income_Type_Distribution__c> incomeTypes = getIncomeTypeDistRecords(afID);
      if(incomeTypes.size() > 0){
        for(Income_Type_Distribution__c it: incomeTypes){
          it.Amount_National_to_Affiliate__c=makeOperandable(it.Amount_National_to_Affiliate__c);
          it.Amount_Affiliate_to_National__c=makeOperandable(it.Amount_Affiliate_to_National__c);
          it.Expense__c = makeOperandable(it.Expense__c);
          it.Income__c = makeOperandable(it.Income__c ); //ZenDesk : #68792 - Assigned Income instead of Expense
          it.Amount__c = makeOperandable(it.Amount__c);

          if( (it.Income_Type__c =='Unrestricted Bequest / Planned Gift' || it.Income_Type__c =='Earmarked Bequest') 
              && it.Fund_Type__c=='Union' && it.Shared_in_Advance__c==True
            ){
            five_j += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c) *-1;
          //} else if (it.Fund_Type__c=='Union' && it.recordtype.name=='Other Income Types' &&
          //             it.Income_Type__c =='Multi-Year Mega-Gifts' ){
          //  seven_a += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
          } else if (it.Fund_Type__c=='Union' && it.recordtype.name=='Other Income Types'){
            key = '';
            key = it.Description__c;
            six_Total += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
            if(!six.isEmpty() && six.containsKey(key) ) {
              six.get(key).amount += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
            } else {
              ITContainer x = new ITContainer();
              x.description = it.Description__c;
              x.amount = (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
              six.put(key, x);
            }
          }
          //schedule III affiliate benefit income
          if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Union' && it.Event_Hosted_By__c=='Affiliate'){//Zendesk : #68792  Changed Income type from Event_Benefit to Event/Benefit
            s3_TotalMaual += it.Income__c;
            s3_TotalAmount += it.Amount__c;
            s3.add(it);
          }
          //schedule VI foundation benefit income
          if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Union'  && it.Event_Hosted_By__c=='National'){ //Zendesk : #68792  Changed Income type from Event_Benefit to Event/Benefit
            xs6_TotalMaual += it.Income__c;
            xs6_TotalAmount += it.Amount__c;
            xs6.add(it);
          }
        }//end it for
      }
      s3_TotalMaual = (s3_TotalMaual>0)?s3_TotalMaual:0;
      two_b += s3_TotalAmount;
      two_a += xs6_TotalAmount;

    }


  public class ScheduleContainer{
    public Double total {get;set;}
    public String donor {get;set;}
    public String sharingCode {get;set;}
    public String depLoc {get;set;}
    public String campaign {get;set;}
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
  private List<Opportunity> queryOpportunity(String accAffiliationCode){
    

    return [SELECT Id, Amount, Name, accountId, account.name, account.Account_Number__c, Sharing_Entity_Affiliation__c,
                     Exclude_from_Revenue_Sharing__c, Sharing_Code__c, Deposit_Site__c, Restriction__c, Description,
                     Sharing_Entity__c, RPT_Package_Code__c, rC_Giving__Source_Code__c, Campaign_Type__c 
             FROM Opportunity
             where RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                      :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                      :OPPORTUNITY_RT_SOFTCREDIT_Id)
             AND Sharing_Code__c IN :setOfRequiredCodes
             //AND Amount != NULL
             AND (Sharing_Entity_Affiliation__c IN :sharingAffiliationEntitySet // #63855
                  OR (Account_Affiliation__c =: accAffiliationCode AND Sharing_Entity_Affiliation__c IN : setOfNationalCodes)
                 )
             AND stageName = 'Completed'
             AND CloseDate >= :startDate AND CloseDate <= :endDate];
  }

  private Affiliate_Yearly__c getAffiliateYearlyRecord(String accAffiliationCode){
    return [select Misc_Affiliate_Costs_Total__c, Foundation_Cost_Factor__c, Account__r.Affiliation__c, Fiscal_Year__c,
            National_Indemnification_Threshold__c, Affiliate_Indemnification_Threshold__c, Incentive_National_Share__c,
            BRI_Affiliate_Share__c
          FROM Affiliate_Yearly__c
          WHERE id= :accAffiliationCode LIMIT 1];
  }

  private List<Income_Type_Distribution__c> getIncomeTypeDistRecords(String afID){
    return [SELECT id, Income_Type__c, Affiliate_Yearly__c, Amount__c,Description__c ,
              Shared_in_Advance__c, Gift__r.Name, Fund_Type__c, Expense__c, Income__c, //Gift__r.RPT_Revenue_Type__c,
              Gift__r.Deposit_Site__c, recordtype.name, Event_Hosted_By__c, 
              Amount_National_to_Affiliate__c, Amount_Affiliate_to_National__c
            FROM Income_Type_Distribution__c 
            WHERE Affiliate_Yearly__c =: afID];
  }

  private List<Donors_Over_10K__c> getDonorsOver10K(String afId){
    return [SELECT Id, Affiliate_Yearly__c, Affiliate_CP_and_Earmark_Info__c, Banked_by_Affiliate_Fdn__c, Donor__c,
             Banked_by_National_Fdn__c, Base_Amount__c, Excess_Over_10K__c, National_CP_and_Earmark_Info__c, 
             Total_Banked__c, Account__c 
            FROM Donors_Over_10K__c
            WHERE Affiliate_Yearly__c = :afId
              AND Fund_Type__c='Union'];
  }

}