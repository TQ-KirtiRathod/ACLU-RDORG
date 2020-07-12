/*
*
*Name  :  Reconcile_FoundationGMIReportController
*Author:  Appirio India (James Wasilewski)
*Date  :  June 30, 2017
*Purpose :  Reconciliation Foundation GMI report controller
            This class queries opp data and rolls up the amounts in various categories to support the reconciliation output and format
* Modified by :: Salesforce.org :: 10-July-2020 :: ACLU: #78548
* Modified by :: Salesforce.org :: 21-June-2019 :: Zendesk: #68203,#69055,#70191
* Description :: the reports contain gifts within the 2 old KM Deposit Sites only (KM_Kansas and KMW_Kansas_web) - it is missing KS and KSW
*/
public with sharing class Reconcile_FoundationGMIReportController {

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
  //Zendesk : #70191 - Added two variables to hold links
  public String reportLink3 {get;set;}
  public String reportLink4 {get;set;}
  //Zendesk : END - #70191
  
  public Affiliate_Yearly__c ay {get;set;}
  //public Decimal costFactor {get;set;}
  //public Decimal briAffiliateShare {get;set;}
  //public Decimal nationalFoundationBRI {get;set;}
  public Decimal foundationCostFactor {get;set;}

  public Double one_a {get;set;}
  public Double one_c {get;set;}

  public List<Donors_Over_10K__c> two {get;set;}
  public Double two_c2Total {get;set;}
  public Double two_c3Total {get;set;}
  public Double two_c4Total {get;set;}
  public Double two_c5Total {get;set;}
  public Double two_c6Total {get;set;}
  public Double two_c7Total {get;set;}
  public Double two_c8Total {get;set;}

  public Double three_a {get;set;}
  public Double three_b {get;set;}

  public Map<String, ScheduleContainer> four_a {get;set;}
  public Double four_aTotal {get;set;}
  public Map<String, ScheduleContainer> four_b {get;set;}
  public Double four_bTotal {get;set;}

  public Double six_j {get;set;}

  public Double seven_Total {get;set;}
  public Map<String, ITContainer> seven {get;set;}
  
  //page w
  public Double a_1a {get;set;}
  public Double a_1b {get;set;}

  public Double b_1a {get;set;}
  public Double b_1b {get;set;}
  public Double b_3 {get;set;}
  public Double b_4 {get;set;}

  //schedule 1 mega gifts
  public Map<String, ScheduleContainer> s1_megaSched {get;set;}
  public Double s1_megaSchedTotal {get;set;}
  //schedule II Affiliate Unrestricted & Earmarked Gifts 
  public List<Opportunity> s2_UnresEarmarked {get;set;}
  public Double s2_Total {get;set;}
  //schedule 3 affiliate benefit income
  public Double s3_TotalR141 {get;set;}
  public Double s3_TotalMaual {get;set;}
  public Double s3_Amount {get;set;}
  public List<Income_Type_Distribution__c> s3 {get;set;}
  //schedule III Affiliate Solicited Earmarked Gifts 
  public List<Opportunity> s4_SolEarmarked {get;set;}
  public Double s4_Total {get;set;}
  //schedule V Affiliate In-Kind Gifts
  public List<Opportunity> s5_InKindGifts {get;set;}
  public Double s5_Total {get;set;}
  //schedule VI Affiliate Recognized Institutional Grants
  public List<Opportunity> s6_RecInstGrants {get;set;}
  public Double s6_Total {get;set;}
  //schedule VI Affiliate Unsolicited Earmarked Gifts
  public List<Opportunity> s7_UnsolGift {get;set;}
  public Double s7_Total {get;set;}
  //schedule VII Bequests and Planned Gifts
  public List<Opportunity> s8_q001 {get;set;}
  public Double s8_q001Total {get;set;}
  public List<Opportunity> s8_q002 {get;set;}
  public Double s8_q002Total {get;set;}
  public List<Opportunity> s8_q003 {get;set;}
  public Double s8_q003Total {get;set;}
  public List<Opportunity> s8_q004 {get;set;}
  public Double s8_q004Total {get;set;}
  public List<Opportunity> s8_q005 {get;set;}
  public Double s8_q005Total {get;set;}
  
  //page x
  //schedule 1 mega gifts without GMI
  public Map<String, ScheduleContainer> s1_megaSched_woGMI {get;set;}
  public Double s1_megaSchedTotal_woGMI {get;set;}
  //schedule 2 National Foundation Unrestricted Gifts over $10k without GMI
  public List<Opportunity> s2_Unrestricted_woGMI {get;set;}
  public Double s2_Total_woGMI {get;set;}
  //schedule 3 National Solicited Earmarked Gifts without GMI
  public List<Opportunity> s3_SolEarmarked_woGMI {get;set;}
  public Double s3_Total_woGMI {get;set;}
  //schedule 4 National UnSolicited Earmarked Gifts without GMI
  public List<Opportunity> s4_UnSolEarmarked_woGMI {get;set;}
  public Double s4_Total_woGMI {get;set;}    
  //schedule 5 Bequests and Planned Gifts without GMI
  public List<Opportunity> s5_q001_woGMI {get;set;}
  public Double s5_q001Total_woGMI {get;set;}
  public List<Opportunity> s5_q002_woGMI {get;set;}
  public Double s5_q002Total_woGMI {get;set;}
  public List<Opportunity> s5_q003_woGMI {get;set;}
  public Double s5_q003Total_woGMI {get;set;}
  public List<Opportunity> s5_q004_woGMI {get;set;}
  public Double s5_q004Total_woGMI {get;set;}
  public List<Opportunity> s5_q005_woGMI {get;set;}
  public Double s5_q005Total_woGMI {get;set;}
  //schedule 6 National In-Kind Gifts
  public List<Opportunity> xs6_InKindGifts {get;set;}
  public Double xs6_Total {get;set;}
  //schedule 7 National benefit income
  public Double xs7_TotalR141 {get;set;}
  public Double xs7_TotalMaual {get;set;}
  public Double xs7_Amount {get;set;}
  public List<Income_Type_Distribution__c> xs7 {get;set;}
  
    //#63855
    Set<String> sharingEntitySet = new Set<String> { 'KM', 'KS', 'KSW', 'KMW' };


  static{
    Datetime myDatetime = Datetime.now();
    todayDate = myDatetime.format('MM/dd/yyyy hh:MM a');

    setOfRequiredCodes = new Set<String> {'R112','R113','R121','R131','R141','R151','R181','R191',
                                          'K161','K165','K171','N111','N175',
                                          'Q001','Q002','Q003','Q004','Q005' };

    setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};

    //Determine current fiscal year
    orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
               FROM Organization
               WHERE id=:Userinfo.getOrganizationId()];

    sharingAffiliationEntitySet = new List<String>();
  }


  //constructor
    public Reconcile_FoundationGMIReportController() {
        String afID = ApexPages.currentPage().getParameters().get('afid');
    ay = getAffiliateYearlyRecord(afID);
    affiliate = ay.Account__r.Affiliation__c;
    fiscalYear = ay.Fiscal_Year__c;

    //Zendesk: #68203 -- Get Deposit site from custom metadata Types
    sharingAffiliationEntitySet = Utilities.getDepositSiteSet(affiliate);
    //END:Zendesk: #68203

    //costFactor = (ay.BRI_Affiliate_Share__c != null)?ay.BRI_Affiliate_Share__c:0;
    //briAffiliateShare = (ay.BRI_Affiliate_Share__c != null)?ay.BRI_Affiliate_Share__c:0;
    //nationalFoundationBRI = (ay.Incentive_National_Share__c != null)?ay.Incentive_National_Share__c:0;
    foundationCostFactor = (ay.Foundation_Cost_Factor__c != null)?ay.Foundation_Cost_Factor__c:0; 

    //set selection based on fiscal year
    integer endDateLastDay = Date.daysInMonth(integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1);
    startDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c)-1, orgInfo.FiscalYearStartMonth, 01);
    endDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1, endDateLastDay);
    
        
    List<Opportunity> listOfOpps = queryOpportunity(affiliate,sharingAffiliationEntitySet);
        
    If(listOfOpps.size()<7000){
      reportLink = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=FoundationNonGMI'
                    +'&startDate='+dateFormatter(startDate)+'&endDate='+dateFormatter(endDate)+'&affiliate='+affiliate;
    } else {
     //Zendesk : #70191 : Added more report links to get more details more givings. 
      reportLink = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=FoundationNonGMI'
                    +'&startDate='+dateFormatter(startDate)+'&endDate='+dateFormatter(startDate.addMonths(3).addDays(-1))+'&affiliate='+affiliate;
      
      reportLink2 = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=FoundationNonGMI'
                    +'&startDate='+dateFormatter(startDate.addMonths(3))+'&endDate='+dateFormatter(startDate.addMonths(6).addDays(-1))+'&affiliate='+affiliate;
      
      reportLink3 = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=FoundationNonGMI'
                    +'&startDate='+dateFormatter(startDate.addMonths(6))+'&endDate='+dateFormatter(startDate.addMonths(9).addDays(-1))+'&affiliate='+affiliate;
      
      reportLink4 = System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Reconcile_DetailReport?report=FoundationNonGMI'
                    +'&startDate='+dateFormatter(startDate.addMonths(9))+'&endDate='+dateFormatter(startDate.addMonths(12).addDays(-1))+'&affiliate='+affiliate;
    //Zendesk : END- #70191
    }
    




    one_a = one_c = 0;

    two_c2Total = two_c3Total = two_c4Total = two_c5Total = two_c6Total = two_c7Total = two_c8Total = 0; // need logic
    two = new List<Donors_Over_10K__c>();
    two = getDonorsOver10K(afId);
    Set<Id> donorsOver10KAccountIds = new Set<Id>();

    for(Donors_Over_10K__c d :two){
      Id donorID = d.Account__c;
      donorsOver10KAccountIds.add(donorID);
      two_c2Total += makeOperandable(d.Banked_by_Affiliate_Fdn__c);
      two_c3Total += makeOperandable(d.Banked_by_National_Fdn__c);
      two_c4Total += makeOperandable(d.Total_Banked__c);
      two_c5Total += makeOperandable(d.Base_Amount__c);
      two_c6Total += makeOperandable(d.Excess_Over_10K__c);
      two_c7Total += makeOperandable(d.Affiliate_CP_and_Earmark_Info__c);
      two_c8Total += makeOperandable(d.National_CP_and_Earmark_Info__c);
    }

    three_a = three_b = 0;

    four_a = new Map<String, ScheduleContainer>();
    four_b = new Map<String, ScheduleContainer>();
    four_aTotal = four_bTotal = 0;

    six_j = 0;

    seven_Total = 0;
    seven = new Map<String, ITContainer>();
    
    a_1a = a_1b = 0;
    b_1a = b_1b = b_3 = b_4 = 0;

    s1_megaSched = new Map<String, ScheduleContainer>();
    s1_megaSchedTotal = 0;
    s2_UnresEarmarked = new List<Opportunity>();
    s2_Total = 0;
    s3_TotalR141 = 0;
    s3_TotalMaual = s3_Amount = 0;
    s3 = new List<Income_Type_Distribution__c>();
    s4_SolEarmarked = new List<Opportunity>();
    s4_Total = 0;
    s5_InKindGifts = new List<Opportunity>();
    s5_Total = 0;
    s6_RecInstGrants = new List<Opportunity>();
    s6_Total = 0;
    s7_UnsolGift = new List<Opportunity>();
    s7_Total = 0;
    s8_q001 = new List<Opportunity>();
    s8_q001Total = 0;
    s8_q002 = new List<Opportunity>();
    s8_q002Total = 0;
    s8_q003 = new List<Opportunity>();
    s8_q003Total = 0;
    s8_q004 = new List<Opportunity>();
    s8_q004Total = 0;
    s8_q005 = new List<Opportunity>();
    s8_q005Total = 0;
    s1_megaSched_woGMI = new Map<String, ScheduleContainer>();
    s1_megaSchedTotal_woGMI = 0;
    s2_Unrestricted_woGMI = new List<Opportunity>();
    s2_Total_woGMI = 0;
    s3_SolEarmarked_woGMI = new List<Opportunity>();
    s3_Total_woGMI = 0;
    s4_UnSolEarmarked_woGMI = new List<Opportunity>();
    s4_Total_woGMI = 0;
    s5_q001_woGMI = new List<Opportunity>();
    s5_q001Total_woGMI = 0;
    s5_q002_woGMI = new List<Opportunity>();
    s5_q002Total_woGMI = 0;
    s5_q003_woGMI = new List<Opportunity>();
    s5_q003Total_woGMI = 0;
    s5_q004_woGMI = new List<Opportunity>();
    s5_q004Total_woGMI = 0;
    s5_q005_woGMI = new List<Opportunity>();
    s5_q005Total_woGMI = 0;
    xs6_InKindGifts = new List<Opportunity>();
    xs6_Total = 0;
    xs7_TotalR141 = xs7_TotalMaual = xs7_Amount =0;
    xs7 = new List<Income_Type_Distribution__c>();

    String depositSite = '';
    String packageCode = '';
    String key = '';

    Double three_x = 0.0;
    Double three_y = 0.0;

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
          if(o.Sharing_Code__c == 'N111' && depositSite =='NA'){
            one_a += o.Amount;
            continue;
          }
          if(o.Sharing_Code__c == 'N175' && depositSite =='NA'){
            one_c += o.Amount;
            continue;
          }
          /* old if( (o.Sharing_Code__c == 'R131' || o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' 
               ||o.Sharing_Code__c == 'K171' || o.Sharing_Code__c == 'R151' || o.Sharing_Code__c == 'R181')
              && depositSite == 'NA'  && !donorsOver10KAccountIds.contains(o.AccountId)){
            three_x += o.Amount;
          } */
          if( ((o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' || o.Sharing_Code__c == 'K171' 
                || o.Sharing_Code__c == 'R181') || (o.Sharing_Code__c == 'R131' && packageCode !='CP')) 
              && depositSite == 'NA' && !donorsOver10KAccountIds.contains(o.AccountId)){
            three_a += o.Amount;  //has additional value added below
          }          
          /*if( (o.Sharing_Code__c == 'R131' || o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' 
               ||o.Sharing_Code__c == 'K171' || o.Sharing_Code__c == 'R151' || o.Sharing_Code__c == 'R181')
              && depositSite == affiliate  && !donorsOver10KAccountIds.contains(o.AccountId)){
            three_y += o.Amount;
          }*/

        //Zendesk: #68203
        Boolean isDepositSiteSameAsAffiliate = false;
        isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(o
                                                      ,  sharingAffiliationEntitySet
                                                      ,  depositSite);
        //END:Zendesk: #68203
        if( ((o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' || o.Sharing_Code__c == 'K171' 
            || o.Sharing_Code__c == 'R181') || (o.Sharing_Code__c == 'R131' && packageCode !='CP'))
            && isDepositSiteSameAsAffiliate && !donorsOver10KAccountIds.contains(o.AccountId)){
                three_b += o.Amount;  //has additional value added below
        }
          if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode =='CP'))
              && depositSite == 'NA'  && !donorsOver10KAccountIds.contains(o.AccountId)){
            key= '';
            key = o.Restriction__c+' - '+o.Sharing_Code__c +' - '+packageCode;
            four_aTotal += o.Amount;
            if ( !four_a.isEmpty() && four_a.containsKey(key) ) {
              four_a.get(key).amount += (o.Amount * 0.74);
              four_a.get(key).total += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.total = o.Amount;
              s.amount = (o.Amount * 0.74);
              s.donor =  ' @ 74.00% '+ o.Restriction__c;
              s.campaign = packageCode;
              s.sharingCode = o.Sharing_Code__c;
              four_a.put(key, s);
            }
          }
          if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode =='CP'))
              && isDepositSiteSameAsAffiliate && !donorsOver10KAccountIds.contains(o.AccountId)){
            key= '';
            key = o.Restriction__c+' - '+o.Sharing_Code__c +' - '+packageCode;
            four_bTotal += o.Amount;
            if ( !four_b.isEmpty() && four_b.containsKey(key) ) {
              four_b.get(key).amount += (o.Amount * 0.26);
              four_b.get(key).total += o.Amount;
            } else {
              ScheduleContainer s = New ScheduleContainer();
              s.total = o.Amount;
              s.amount = (o.Amount * 0.26);
              s.donor =  ' @ 26.00% '+ o.Restriction__c;
              s.campaign = packageCode;
              s.sharingCode = o.Sharing_Code__c;
              four_b.put(key, s);
            }
          }
          if(o.Sharing_Code__c == 'R112'  && isDepositSiteSameAsAffiliate ){//ACLU : #78548 - Added isDepositSiteSameAsAffiliate condition instead of depositsite == affiliate 
            a_1a += o.Amount;
            continue;
          }
          if( (o.Sharing_Code__c == 'R151' || o.Sharing_Code__c == 'R131' || o.Sharing_Code__c == 'R113'
               || o.Sharing_Code__c == 'R121' ||o.Sharing_Code__c == 'K171' )
              && isDepositSiteSameAsAffiliate  && donorsOver10KAccountIds.contains(o.AccountId)){
            b_1a += o.Amount;
          }
          if( ((o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' || 
               o.Sharing_Code__c == 'K171' ) || (o.Sharing_Code__c == 'R131' && packageCode !='CP'))
              && isDepositSiteSameAsAffiliate  && !donorsOver10KAccountIds.contains(o.AccountId) ){
            b_1b += o.Amount;
            //continue;
          }
          if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode =='CP'))
              && isDepositSiteSameAsAffiliate  && !donorsOver10KAccountIds.contains(o.AccountId) ){
            b_3 += o.Amount;
          }
          if( o.Sharing_Code__c == 'R181' &&  isDepositSiteSameAsAffiliate ){//ACLU : #78548 - Added isDepositSiteSameAsAffiliate condition instead of depositsite == affiliate 
            b_4 += o.Amount;
          }
          //schedule 1 mega gifts
          if(o.Sharing_Code__c == 'R191' && isDepositSiteSameAsAffiliate ){//ACLU : #78548 - Added isDepositSiteSameAsAffiliate condition instead of depositsite == affiliate 
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
          if( (o.Sharing_Code__c == 'R151' || o.Sharing_Code__c == 'R131' || o.Sharing_Code__c == 'R113' 
               || o.Sharing_Code__c == 'R121' || o.Sharing_Code__c == 'K171')
              && isDepositSiteSameAsAffiliate && donorsOver10KAccountIds.contains(o.AccountId) ){
            s2_UnresEarmarked.add(o);
            s2_Total += o.Amount;
          }
          //schedule III affiliate benefit income
          if(o.Sharing_Code__c == 'R141' && isDepositSiteSameAsAffiliate ){//ACLU : #78548 - Added isDepositSiteSameAsAffiliate condition instead of depositsite == affiliate 
            s3_TotalR141 += o.Amount;
          }
          //schedule IV Affiliate Solicited Earmarked Gifts below 10k
          if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode =='CP'))
              && isDepositSiteSameAsAffiliate && !donorsOver10KAccountIds.contains(o.AccountId)){
            s4_SolEarmarked.add(o);
            s4_Total += o.Amount;
          }
          //schedule V Affiliate In-Kind Gifts
          if(o.Sharing_Code__c == 'R181' && isDepositSiteSameAsAffiliate ){
            s5_InKindGifts.add(o);
            s5_Total += o.Amount;
          }
          //schedule VI Affiliate Recognized Institutional Grants
          if(o.Sharing_Code__c == 'K165' && isDepositSiteSameAsAffiliate ){
            s6_RecInstGrants.add(o);
            s6_Total += o.Amount;
          }
          //schedule VII Affiliate Foundation Unsolicited Earmarked Gifts
          if(o.Sharing_Code__c == 'K161' && isDepositSiteSameAsAffiliate ){
            s7_UnsolGift.add(o);
            s7_Total += o.Amount;
          }
          //schedule VIII Bequests and Planned Gifts
          if(o.Sharing_Code__c == 'Q001' && isDepositSiteSameAsAffiliate ){
            s8_q001.add(o);
            s8_q001Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q002' && isDepositSiteSameAsAffiliate ){
            s8_q002.add(o);
            s8_q002Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q003' && isDepositSiteSameAsAffiliate ){
            s8_q003.add(o);
            s8_q003Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q004' && isDepositSiteSameAsAffiliate ){
            s8_q004.add(o);
            s8_q004Total += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q005' && isDepositSiteSameAsAffiliate ){
            s8_q005.add(o);
            s8_q005Total += o.Amount;
          }
          //schedule 1 mega gifts without GMI
          if(o.Sharing_Code__c == 'R191' && depositSite =='NA' ){
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
          //schedule 2 National Foundation Unrestricted Gifts over $10k without GMI
          if( (o.Sharing_Code__c == 'R151' || o.Sharing_Code__c == 'R131' || o.Sharing_Code__c == 'R113' 
               || o.Sharing_Code__c == 'R121' || o.Sharing_Code__c == 'K171')
              && depositSite == 'NA' && donorsOver10KAccountIds.contains(o.AccountId) ){
            s2_Unrestricted_woGMI.add(o);
            s2_Total_woGMI += o.Amount;
          }
          //schedule 3 National Solicited Earmarked Gifts without GMI
          if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode =='CP'))
              && depositSite =='NA' ){
            s3_SolEarmarked_woGMI.add(o);
            s3_Total_woGMI += o.Amount;
          }
          //schedule 4 National UnSolicited Earmarked Gifts without GMI
          if(o.Sharing_Code__c == 'K161' && depositSite =='NA' ){
            s4_UnSolEarmarked_woGMI.add(o);
            s4_Total_woGMI += o.Amount; 
          }          
          //schedule 5 Bequests and Planned Gifts without GMI
          if(o.Sharing_Code__c == 'Q001' && depositSite =='NA' ){
            s5_q001_woGMI.add(o);
            s5_q001Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q002' && depositSite =='NA' ){
            s5_q002_woGMI.add(o);
            s5_q002Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q003' && depositSite =='NA' ){
            s5_q003_woGMI.add(o);
            s5_q003Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q004' && depositSite =='NA' ){
            s5_q004_woGMI.add(o);
            s5_q004Total_woGMI += o.Amount;
          }
          if(o.Sharing_Code__c == 'Q005' && depositSite =='NA' ){
            s5_q005_woGMI.add(o);
            s5_q005Total_woGMI += o.Amount;
          }
          //schedule V Affiliate In-Kind Gifts
          if(o.Sharing_Code__c == 'R181' && depositSite =='NA' ){
            xs6_InKindGifts.add(o);
            xs6_Total += o.Amount;
          }
          //schedule III affiliate benefit income
          if(o.Sharing_Code__c == 'R141' && depositSite =='NA' ){
            xs7_TotalR141 += o.Amount;
          }                    
        }
      }//end opps for
    }


    List<Income_Type_Distribution__c> incomeTypes = getIncomeTypeDistRecords(afID);
    if(incomeTypes.size() > 0){
      for(Income_Type_Distribution__c it: incomeTypes){
        it.Amount_National_to_Affiliate__c=makeOperandable(it.Amount_National_to_Affiliate__c);
        it.Amount_Affiliate_to_National__c=makeOperandable(it.Amount_Affiliate_to_National__c);
        it.Expense__c = makeOperandable(it.Expense__c);
        it.Income__c = makeOperandable(it.Income__c);
        it.Amount__c = makeOperandable(it.Amount__c);

        if( (it.Income_Type__c =='Unrestricted Bequest / Planned Gift' || it.Income_Type__c =='Earmarked Bequest') 
            && it.Fund_Type__c=='Foundation' && it.Shared_in_Advance__c==True
          ){
          six_j += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
        }else if (it.Fund_Type__c=='Foundation' && it.recordtype.name=='Other Income Types'){//Zendesk : #69055 - removed else if condition and seven_a varibale 
          key = '';
          key = it.Description__c;
          seven_Total += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
          if(!seven.isEmpty() && seven.containsKey(key) ) {
            seven.get(key).amount += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
          } else {
            ITContainer x = new ITContainer();
            x.description = it.Description__c;
            x.amount = (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
            seven.put(key, x);
          }
        }
        if(it.recordtype.name=='Affiliate Direct Mail'){
          a_1b += it.Expense__c;
        }
        //schedule III affiliate benefit income
        if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Foundation' && it.Event_Hosted_By__c=='Affiliate'){
          s3_TotalMaual += it.Income__c;
          s3_Amount += it.Amount__c;
          s3.add(it);
        }
        //schedule VII foundation benefit income
        if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Foundation'  && it.Event_Hosted_By__c=='National'){
          xs7_TotalMaual += it.Income__c;
          xs7_Amount += it.Amount__c;
          xs7.add(it);
        }
      }//end for income types 
    }
    a_1b = (a_1a*foundationCostFactor/100 < a_1b)? a_1a*foundationCostFactor/100 :a_1b;
    s3_TotalMaual = (s3_TotalMaual>0)?s3_TotalMaual:0;
    three_a += xs7_Amount; 
    three_b += s3_Amount; 
    
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
    //SELECT Id, Amount, Name, accountId, Sharing_Entity_Affiliation__c, Program_Type__c, Exclude_Cost_Factors_in_RevShare__c, 
    //  Exclude_from_Revenue_Sharing__c, Sharing_Entity__c, Sharing_Code__c, RecordTypeId, Cost_Factor__c, 
    //  Deposit_Site__c, Use_Campaign_Cost__c, CloseDate, RPT_Revenue_Type__c, Restriction__c, Description
    private List<Opportunity> queryOpportunity(String accAffiliationCode,List<String> sharingAffiliationEntitySet){

      return [SELECT Id, Amount, Name, accountId, account.name, account.Account_Number__c, Sharing_Entity_Affiliation__c,
                     Exclude_from_Revenue_Sharing__c, Sharing_Code__c, Deposit_Site__c, Restriction__c, Description,
                     Sharing_Entity__c, RPT_Package_Code__c, rC_Giving__Source_Code__c, Campaign_Type__c 
               FROM Opportunity
               WHERE RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                      :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                      :OPPORTUNITY_RT_SOFTCREDIT_Id)
               AND Sharing_Code__c IN :setOfRequiredCodes
               //AND Amount != NULL
               AND (Sharing_Entity_Affiliation__c IN :sharingAffiliationEntitySet////Zendesk: #68203 //=: accAffiliationCode
                    OR (Account_Affiliation__c =: accAffiliationCode AND Sharing_Entity_Affiliation__c IN : setOfNationalCodes)
                   )
               AND stageName = 'Completed'
               AND CloseDate >= :startDate AND CloseDate <= :endDate];
    }

    private Affiliate_Yearly__c getAffiliateYearlyRecord(String accAffiliationCode){
      return [SELECT 
            //ReconGeneralIncentiveAff__c, ReconGeneralIncentiveNat__c, To_Be_Shared__c, Unshared_Total__c, 
            //ReconUnrestrNonMem__c, ReconSolEar__c, ReconInKind__c, ReconGrant__c, ReconUnsolEar__c, 
            Misc_Affiliate_Costs_Total__c, Foundation_Cost_Factor__c, Account__r.Affiliation__c, Fiscal_Year__c,
            National_Indemnification_Threshold__c, Affiliate_Indemnification_Threshold__c, Incentive_National_Share__c,
            BRI_Affiliate_Share__c
            FROM Affiliate_Yearly__c 
            WHERE id= :accAffiliationCode LIMIT 1];
    }

    private List<Income_Type_Distribution__c> getIncomeTypeDistRecords(String afId){
      return [SELECT id, Income_Type__c, Affiliate_Yearly__c, Amount__c,Description__c ,
              Shared_in_Advance__c, Gift__r.Name, Fund_Type__c, Expense__c, Income__c, //Gift__r.RPT_Revenue_Type__c,
              Gift__r.Deposit_Site__c, recordtype.name, Event_Hosted_By__c, 
              Amount_National_to_Affiliate__c, Amount_Affiliate_to_National__c
              FROM Income_Type_Distribution__c 
              WHERE Affiliate_Yearly__c =: afId];
    }

    private List<Donors_Over_10K__c> getDonorsOver10K(String afId){
      return [SELECT Id, Affiliate_Yearly__c, Affiliate_CP_and_Earmark_Info__c, Banked_by_Affiliate_Fdn__c, Donor__c,
               Banked_by_National_Fdn__c, Base_Amount__c, Excess_Over_10K__c, National_CP_and_Earmark_Info__c, 
               Total_Banked__c, Account__c 
              FROM Donors_Over_10K__c
              WHERE Affiliate_Yearly__c = :afId
                AND Fund_Type__c='Foundation'];
    }

}