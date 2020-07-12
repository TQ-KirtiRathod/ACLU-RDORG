/*
*
*Name  :  Reconcile_FoundationNonGMIRptController
*Author:  Appirio India (James Wasilewski)
*Date  :  June 15, 2016
*Purpose :  Reconciliation Foundation Non-GMI report controller
            This class queries opp data and rolls up the amounts in various categories to support the reconciliation output and format
* Modified By: SFDO :: 12-Jun-19 zenDesk : #68073,#69055
* Modified By: SFDO :: 21-Jun-19 zenDesk : #68023,#70191
*/
public with sharing class Reconcile_FoundationNonGMIRptController {

    public static String todayDate{get;set;}
    public String affiliate {get;set;}
    public String fiscalYear {get;set;}
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    private static Set<String> setOfRequiredCodes;
    private static set<String> setOfNationalCodes;
    private static Organization orgInfo; 
    public  static List<String> sharingAffiliationEntitySet;
    public Date startDate {get;set;}
    public Date endDate {get;set;}
    public String reportLink {get;set;}
    public String reportLink2 {get;set;}
    //Zendesk : #70191 - Added two variables to hold links
    public String reportLink3 {get;set;}
    public String reportLink4 {get;set;}
    //Zendesk : END - #70191
    public Affiliate_Yearly__c ay {get;set;}

    //choosing multiple variables since it should be easier to maintain
    //not knowing references upon development leads to m ulitple changes
    //public Decimal costFactor {get;set;}
    public Decimal briAffiliateShare {get;set;}
    //public Decimal nationalFoundationBRI {get;set;} unused
    public Decimal foundationCostFactor {get;set;}

    // Page v
    //section 1
    public Double one_a {get;set;}
    public Double one_c {get;set;}
    //section 2
    public Double two_a {get;set;}
    public Double two_a_it {get;set;}
    //public Double two_b {get;set;}
    public Double two_d {get;set;}
    public Double two_e {get;set;}
    //section 3
    public Map<String, ScheduleContainer> three_a_inc {get;set;}
    public Map<String, ScheduleContainer> three_b_inc {get;set;}
    public Double three_a_total {get;set;}
    public Double three_b_total {get;set;}
    public Double three_c {get;set;}
    //section 4 
    //section 5
    public Double five_j {get;set;}
    //section 6
    public Map<String, ITContainer> six {get;set;}
    public Double six_Total {get;set;}

    // Page w
    //section A
    public Double a_1a {get;set;}
    public Double a_1b {get;set;}
    //section B
    public Double b_1 {get;set;}
    public Double b_2 {get;set;}
    public Double b_3 {get;set;}
    public Double b_4 {get;set;}
    //section C
    public Double c_1 {get;set;}
    public Double c_2 {get;set;}

    //schedule 1 mega gifts
    public Map<String, MegaGifts> s1_megaSched {get;set;}
    public Double s1_megaSchedTotal {get;set;}
    //schedule II affiliate benefit income
    public Double s2_totalR141 {get;set;}
    public Double s2_totalManualFields {get;set;}
    public List<Income_Type_Distribution__c> s2 {get;set;}
    //schedule III Affiliate Solicited Earmarked Gifts 
    public Map<String, ScheduleContainer> s3_SolEarmarked {get;set;}
    public Double s3_Total {get;set;}
    //schedule IV Affiliate In-Kind Gifts
    public List<Opportunity> s4_InKindGifts {get;set;}
    public Double s4_Total {get;set;}
    //schedule V Recognized Foundation
    public List<Opportunity> s5_FoundInstGifts {get;set;}
    public Double s5_Total {get;set;}
    //schedule VI Affiliate Unsolicited Earmarked Gifts
    public List<Opportunity> s6_UnsolGift {get;set;}
    public Double s6_Total {get;set;}
    //schedule VII Bequests and Planned Gifts
    public List<Opportunity> s7_q001 {get;set;}
    public Double s7_q001Total {get;set;}
    public List<Opportunity> s7_q002 {get;set;}
    public Double s7_q002Total {get;set;}
    public List<Opportunity> s7_q003 {get;set;}
    public Double s7_q003Total {get;set;}
    public List<Opportunity> s7_q004 {get;set;}
    public Double s7_q004Total {get;set;}
    public List<Opportunity> s7_q005 {get;set;}
    public Double s7_q005Total {get;set;}

    // Page x
    //schedule 1 mega gifts without GMI
    public Map<String, MegaGifts> xs1_megaSched_woGMI {get;set;}
    public Double xs1_megaSchedTotal_woGMI {get;set;}
    //schedule 2 National Solicited Earmarked Gifts without GMI
    public Map<String, ScheduleContainer> xs2_SolEarmarked_woGMI {get;set;}
    public Double xs2_Total_woGMI {get;set;}
    //schedule 3 National Unsolicited Earmarked Gifts without GMI
    public Map<String,ScheduleContainer> xs3_UnsolGift_woGMI {get;set;} //zenDesk: #68073 - Created a Map instead of List
    public Double xs3_Total_woGMI {get;set;}
    //schedule 4 Bequests and Planned Gifts without GMI
    public List<Opportunity> xs4_q001_woGMI {get;set;}
    public Double xs4_q001Total_woGMI {get;set;}
    public List<Opportunity> xs4_q002_woGMI {get;set;}
    public Double xs4_q002Total_woGMI {get;set;}
    public List<Opportunity> xs4_q003_woGMI {get;set;}
    public Double xs4_q003Total_woGMI {get;set;}
    public List<Opportunity> xs4_q004_woGMI {get;set;}
    public Double xs4_q004Total_woGMI {get;set;}
    public List<Opportunity> xs4_q005_woGMI {get;set;}
    public Double xs4_q005Total_woGMI {get;set;}    
    //schedule IV National Foundation In-Kind Gifts
    public Map<String, ScheduleContainer> xs5d_woGMI {get;set;}
    public Double xs5_Total_woGMI {get;set;}
    //schedule V National benefit income
    public Double xs6_totalR141 {get;set;}
    public Double xs6_totalManualFields {get;set;}
    public Double xs6_totalAmount {get;set;}
    public List<Income_Type_Distribution__c> xs6 {get;set;}

    static{
      Datetime myDatetime = Datetime.now();
      todayDate = myDatetime.format('MM/dd/yyyy hh:MM a');
      setOfRequiredCodes = new Set<String> {'R112', 'R113','R121','R131','R141','R151','R181','R191',
                                            'K161', 'K165','K171','N111','N175',
                                            'Q001','Q002','Q003','Q004','Q005'};

      setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};

      //Determine current fiscal year
      orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                 FROM Organization
                 WHERE id=:Userinfo.getOrganizationId()];
      sharingAffiliationEntitySet = new List<String>();

    }

    //contstuctor
    public Reconcile_FoundationNonGMIRptController() {
      String afID = ApexPages.currentPage().getParameters().get('afid');
      ay = getAffiliateYearlyRecord(afID);
      affiliate = ay.Account__r.Affiliation__c;
      fiscalYear = ay.Fiscal_Year__c;

      //system.debug('affiliate '+affiliate);

      //set date selection based on dynamic fiscal year
      integer endDateLastDay = Date.daysInMonth(integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1);
      startDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c)-1, orgInfo.FiscalYearStartMonth, 01);
      endDate = Date.newInstance( integer.valueof(ay.Fiscal_Year__c), orgInfo.FiscalYearStartMonth-1, endDateLastDay);
      
      //Zendesk: #68203 -- Get Deposit site from custom metadata Types
      sharingAffiliationEntitySet = Utilities.getDepositSiteSet(affiliate);
      System.debug(sharingAffiliationEntitySet );
      //END:Zendesk: #68203
      List<Opportunity> listOfOpps = queryOpportunity(sharingAffiliationEntitySet,affiliate);
      system.debug('listOfOpps size ' + listOfOpps.size());

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

      //costFactor = (ay.BRI_Affiliate_Share__c != null)?ay.BRI_Affiliate_Share__c:0;
      briAffiliateShare = (ay.BRI_Affiliate_Share__c != null)?ay.BRI_Affiliate_Share__c:0;
      //nationalFoundationBRI = (ay.Incentive_National_Share__c != null)?ay.Incentive_National_Share__c:0;  //unused
      foundationCostFactor = (ay.Foundation_Cost_Factor__c != null)?ay.Foundation_Cost_Factor__c:0;   

      //page v
      one_a = one_c = two_a = two_a_it = 0;
      two_d = (ay.National_Indemnification_Threshold__c != null)?ay.National_Indemnification_Threshold__c:0;
      two_e = (ay.Affiliate_Indemnification_Threshold__c != null)?ay.Affiliate_Indemnification_Threshold__c:0;
      three_a_total = three_b_total = 0;
      three_c = 0;
      three_a_inc = New Map<String, ScheduleContainer>();
      three_b_inc = New Map<String, ScheduleContainer>();
      five_j = 0;
      six = New Map<String, ITContainer>();
      six_Total = 0; 

      //page w
      a_1a = a_1b = 0;
      b_1 = b_2 = b_3 = b_4 = 0.0;
      c_1 = c_2 = 0.0;
      s1_megaSched = new Map<String, MegaGifts>();
      s2_totalR141 = 0;
      s2_totalManualFields = 0;
      s2 = new List<Income_Type_Distribution__c>();
      s3_SolEarmarked = new Map<String, ScheduleContainer>();
      s3_Total = 0.0;
      s4_InKindGifts = new List<Opportunity>();
      s4_Total = 0.0;      
      s5_FoundInstGifts = new List<Opportunity>();
      s5_Total = 0.0;      
      s6_UnsolGift = new List<Opportunity>();
      s6_Total = 0.0;      
      s7_q001 = new List<Opportunity>();
      s7_q002 = new List<Opportunity>();
      s7_q003 = new List<Opportunity>();
      s7_q004 = new List<Opportunity>();
      s7_q005 = new List<Opportunity>();
      s7_q001Total = s7_q002Total = s7_q003Total = s7_q004Total = s7_q005Total = 0.0;
      s1_megaSchedTotal = 0.0;

      //page x
      xs1_megaSched_woGMI = new Map<String, MegaGifts>();
      xs1_megaSchedTotal_woGMI = 0.0; 
      xs2_SolEarmarked_woGMI = new Map<String, ScheduleContainer>();
      xs2_Total_woGMI = 0.0; 
      xs3_UnsolGift_woGMI = new Map<String,ScheduleContainer>(); // zenDesk : #68073
      xs3_Total_woGMI = 0.0; 
      xs4_q001_woGMI = new List<Opportunity>();
      xs4_q001Total_woGMI = 0.0; 
      xs4_q002_woGMI = new List<Opportunity>();
      xs4_q002Total_woGMI = 0.0; 
      xs4_q003_woGMI = new List<Opportunity>();
      xs4_q003Total_woGMI = 0.0; 
      xs4_q004_woGMI = new List<Opportunity>();
      xs4_q004Total_woGMI = 0.0; 
      xs4_q005_woGMI = new List<Opportunity>();
      xs4_q005Total_woGMI = 0.0;  
      xs5d_woGMI = new Map<String, ScheduleContainer>();
      xs5_Total_woGMI = 0.0; 
      xs6_totalR141 = 0.0; 
      xs6_totalManualFields = xs6_totalAmount = 0.0; 
      xs6 = new List<Income_Type_Distribution__c>();

      String depositSite = '';
      String packageCode = '';
      String key = '';

      if(listOfOpps.size() > 0){
        for(Opportunity o: listOfOpps){
          o.rC_Giving__Source_Code__c = makeEmptyString(o.rC_Giving__Source_Code__c);
          if(o.Exclude_from_Revenue_Sharing__c == False  && o.Amount !=null
              && o.Deposit_Site__c != null && o.Deposit_Site__c != 'COS*' && o.Deposit_Site__c != 'NAE'
              && o.rC_Giving__Source_Code__c.left(3) != 'ENT' &&  o.Sharing_Code__c != 'T400' && o.Campaign_Type__c != 'T'
              ){
            //system.debug('here '+'o.Sharing_Code__c '+ o.Sharing_Code__c + ' o.Deposit_Site__c '+ o.Deposit_Site__c + ':: '+o.Name);
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
            if(( (o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' 
                 || o.Sharing_Code__c == 'K171' || o.Sharing_Code__c == 'R181'
                 ) || (o.Sharing_Code__c == 'R131' && packageCode != 'CP') 
               ) && depositSite =='NA'){
              two_a += o.Amount;
            }

            if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode == 'CP') )
                && depositSite =='NA' ){
              key= '';
              key = o.Restriction__c +' - '+packageCode;
              three_a_total += o.Amount;
              if ( !three_a_inc.isEmpty() && three_a_inc.containsKey(key) ) {
                three_a_inc.get(key).amount += (o.Amount * 0.50);
                three_a_inc.get(key).total += o.Amount;
              } else {
                ScheduleContainer s = New ScheduleContainer();
                s.total = o.Amount;
                s.donor = ' @ 50% ' + o.Restriction__c;
                s.sharingCode = o.Sharing_Code__c;
                s.lffCampaign = packageCode;
                s.amount = (o.Amount * 0.50);
                three_a_inc.put(key, s);
              }
            }
             //Zendesk: #68203 - Compare deposit site with opp's deposit site
            Boolean isDepositSiteSameAsAffiliate = false;
            isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(o
                                                          ,  sharingAffiliationEntitySet
                                                          ,  depositSite);
            //END:Zendesk: #68203
            if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode == 'CP') ) 
                && isDepositSiteSameAsAffiliate ){ //Zendesk: #68203 
              key= '';
              key = o.Restriction__c +' - '+ packageCode;
              three_b_total += o.Amount;
              if ( !three_b_inc.isEmpty() && three_b_inc.containsKey(key) ) {
                three_b_inc.get(key).amount += (o.Amount * 0.50);
                three_b_inc.get(key).total += o.Amount;
              } else {
                ScheduleContainer s = New ScheduleContainer();
                s.total = o.Amount;
                s.donor = ' @ 50% ' + o.Restriction__c;
                s.sharingCode = o.Sharing_Code__c;
                s.lffCampaign = packageCode;
                s.amount = (o.Amount * 0.50 );
                three_b_inc.put(key, s);
              }
            }

            if(o.Sharing_Code__c == 'R112' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              a_1a += o.Amount;
              continue;
            }
            if( ((o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' || o.Sharing_Code__c == 'K171')
                 || (o.Sharing_Code__c == 'R131' && packageCode != 'CP') ) && isDepositSiteSameAsAffiliate ){//Zendesk: #68203
              b_1 += o.Amount;
            }
            if( ((o.Sharing_Code__c == 'R151')
                 || (o.Sharing_Code__c == 'R131' && packageCode=='CP') ) && isDepositSiteSameAsAffiliate ){//Zendesk: #68203
              b_3 += o.Amount;
            }
            if(o.Sharing_Code__c == 'R181' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              b_4 += o.Amount;
            }
            if(o.Sharing_Code__c == 'K165' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              c_1 += o.Amount;
            }
            if(o.Sharing_Code__c == 'K161' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              c_2 += o.Amount;
            }
            //schedule I megaSched
            if(o.Sharing_Code__c == 'R191' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
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
            if(o.Sharing_Code__c == 'R141' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s2_totalR141 += o.Amount;
            }
            //schedule III Affiliate Solicited Earmarked Gifts
            if((o.Sharing_Code__c == 'R151'
                || (o.Sharing_Code__c == 'R131' && packageCode=='CP') ) && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              key = '';
              // Zendesk:  #68073 - Added extra restriction key 
              key = o.accountId +' - '+ o.Restriction__c +' - '+ packageCode;
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
            if(o.Sharing_Code__c == 'R181' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s4_InKindGifts.add(o);
              s4_Total += o.Amount;
            }
            //schedule V
            if(o.Sharing_Code__c == 'K165' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s5_FoundInstGifts.add(o);
              s5_Total += o.Amount;
            }
            //schedule VI Affil Found Usol Earmarked Gifts
            if(o.Sharing_Code__c == 'K161' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s6_UnsolGift.add(o);
              s6_Total += o.Amount;
            }
            //schedule VII Bequests and Planned Gifts
            if(o.Sharing_Code__c == 'Q001' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s7_q001.add(o);
              s7_q001Total += o.Amount;
            }
            if(o.Sharing_Code__c == 'Q002' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s7_q002.add(o);
              s7_q002Total += o.Amount;
            }    
            if(o.Sharing_Code__c == 'Q003' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s7_q003.add(o);
              s7_q003Total += o.Amount;
            }    
            if(o.Sharing_Code__c == 'Q004' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s7_q004.add(o);
              s7_q004Total += o.Amount;
            }    
            if(o.Sharing_Code__c == 'Q005' && isDepositSiteSameAsAffiliate){//Zendesk: #68203
              s7_q005.add(o);
              s7_q005Total += o.Amount;
            }
            /*if(o.Sharing_Code__c == 'R191' ){
                System.assert(false, depositSite);
            }*/
            //page x
            //schedule I megaSched w/o GMI
            if(o.Sharing_Code__c == 'R191' && depositSite =='NA' ){
              key = '';
              key = o.accountId +' - '+ packageCode;
              xs1_megaSchedTotal_woGMI += o.Amount;
              if(!xs1_megaSched_woGMI.isEmpty() && xs1_megaSched_woGMI.containsKey(key) ) {
                xs1_megaSched_woGMI.get(key).amount += o.Amount;
              } else {
                MegaGifts m = new MegaGifts();
                m.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
                m.lffCampaign = packageCode;
                m.amount = o.Amount;
                xs1_megaSched_woGMI.put(key, m);
              }
            }
            //schedule II National Foundation Solicited Earmarked Gifts w/o GMI
            if((o.Sharing_Code__c == 'R151' 
               || (o.Sharing_Code__c == 'R131' && packageCode=='CP') ) && depositSite == 'NA' ){
              key = '';
              //zenDesk : #68073 - Added restriction as key
              key = o.accountId +' - '+o.Restriction__c+ ' - '+ packageCode;
              //zenDesk : #68073
              xs2_Total_woGMI += o.Amount;
              if(!xs2_SolEarmarked_woGMI.isEmpty() && xs2_SolEarmarked_woGMI.containsKey(key) ) {
                xs2_SolEarmarked_woGMI.get(key).amount += o.Amount;
              } else {
                ScheduleContainer s = new ScheduleContainer();
                s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
                s.sharingCode = o.Sharing_Code__c;
                s.depLoc = o.Deposit_Site__c;
                s.lffCampaign = packageCode;
                s.restriction = o.Restriction__c;
                s.amount = o.Amount;
                xs2_SolEarmarked_woGMI.put(key, s);
              }
            }
            //schedule III National Foundation Unsolicited Earmarked Gifts w/o GMI
            //zenDesk : #68073 - Created a Map for schedule III
            if(o.Sharing_Code__c == 'K161' && depositSite == 'NA' ){
              key = '';
              key = o.accountId +' - '+ o.Restriction__c+' - '+packageCode;
              xs3_Total_woGMI += o.Amount;
              if(!xs3_UnsolGift_woGMI.isEmpty() && xs3_UnsolGift_woGMI.containsKey(key) ) {
                xs3_UnsolGift_woGMI.get(key).amount += o.Amount;
              } else {
                ScheduleContainer s = new ScheduleContainer();
                s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
                s.lffCampaign = packageCode;
                s.restriction = o.Restriction__c;
                s.amount = o.Amount;
                xs3_UnsolGift_woGMI.put(key, s);
              }
            }
            //zenDesk : #68073
            //schedule IV Foundation Bequests and Planned Gifts w/o GMI
            if(o.Sharing_Code__c == 'Q001' && depositSite == 'NA' ){
              xs4_q001_woGMI.add(o);
              xs4_q001Total_woGMI += o.Amount;
            }
            if(o.Sharing_Code__c == 'Q002' && depositSite == 'NA' ){
              xs4_q002_woGMI.add(o);
              xs4_q002Total_woGMI += o.Amount;
            }    
            if(o.Sharing_Code__c == 'Q003' && depositSite == 'NA' ){
              xs4_q003_woGMI.add(o);
              xs4_q003Total_woGMI += o.Amount;
            }    
            if(o.Sharing_Code__c == 'Q004' && depositSite == 'NA' ){
              xs4_q004_woGMI.add(o);
              xs4_q004Total_woGMI += o.Amount;
            }    
            if(o.Sharing_Code__c == 'Q005' && depositSite == 'NA' ){
              xs4_q005_woGMI.add(o);
              xs4_q005Total_woGMI += o.Amount;
            }
            //schedule V National Foundation In-Kind Gifts w/o GMI
            if(o.Sharing_Code__c == 'R181' && depositSite == 'NA' ){
              key = '';
              key = o.accountId +' - '+ packageCode;
              xs5_Total_woGMI += o.Amount;
              if(!xs5d_woGMI.isEmpty() && xs5d_woGMI.containsKey(key) ) {
                xs5d_woGMI.get(key).amount += o.Amount;
              } else {
                ScheduleContainer s = new ScheduleContainer();
                s.donor = o.account.name +' ('+ o.account.Account_Number__c +')';
                s.description = o.Description;
                s.amount = o.Amount;
                xs5d_woGMI.put(key, s);
              }
            }
            //schedule VI National Foundation Benefit Income w/o GMI
            if(o.Sharing_Code__c == 'R141' && depositSite == 'NA' ){
              xs6_totalR141 += o.Amount;
            }

          }
        }//end opps for
      }
      three_c = (three_a_total * 0.5) - (three_b_total * 0.5);

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
            five_j += (it.Amount_National_to_Affiliate__c - it.Amount_Affiliate_to_National__c);
          } else if (it.Fund_Type__c=='Foundation' && it.recordtype.name=='Other Income Types'){//Zendesk : #69055 - removed else if condition and six_a varibale
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
          //if(it.Income_Type__c =='Mega Gifts' && it.Fund_Type__c=='Foundation'){
          //  
          //}
          if(it.recordtype.name=='Affiliate Direct Mail'){
            a_1b += it.Expense__c;
          }
          //section II affiliate benefit income
          if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Foundation' && it.Event_Hosted_By__c=='Affiliate' ){
            b_2 += it.Amount__c;
            s2_totalManualFields += it.Income__c;

            s2.add(it);
          }
          //schedule VI National Foundation Benefit Income w/o GMI
          if(it.Income_Type__c =='Event/Benefit' && it.Fund_Type__c=='Foundation' && it.Event_Hosted_By__c=='National'){
            xs6.add(it);
            xs6_totalManualFields += it.Income__c;
            xs6_totalAmount += it.Amount__c;
          }
        }//end for income types 
      }
      a_1b = (a_1a*foundationCostFactor < a_1b)? a_1a*foundationCostFactor :a_1b;
      b_2 = (b_2>0)?b_2:0;
      xs6_totalManualFields=(xs6_totalManualFields>0)?xs6_totalManualFields:0;
      two_a = xs6_totalAmount+two_a;
      
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

    //get rid of: name, Program_Type__c, Exclude_Cost_Factors_in_RevShare__c, RecordTypeId, Cost_Factor__c,RPT_Revenue_Type__c,
    // Use_Campaign_Cost__c,CloseDate,
    private List<Opportunity> queryOpportunity(List<String> sharingAffiliationEntitySet,String accAffiliationCode ){
       
        return [SELECT Id, Amount, Name, accountId, account.name, account.Account_Number__c, Sharing_Entity_Affiliation__c,
                Exclude_from_Revenue_Sharing__c, Sharing_Code__c, Deposit_Site__c, Restriction__c, Description,
                 Sharing_Entity__c, rC_Giving__Source_Code__c, Campaign_Type__c,
                RPT_Package_Code__c //or add Campaign.Package_Code__c
               FROM Opportunity
               where RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                      :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                      :OPPORTUNITY_RT_SOFTCREDIT_Id)
               AND Sharing_Code__c IN :setOfRequiredCodes
               AND Amount > 0
               AND (Sharing_Entity_Affiliation__c =: sharingAffiliationEntitySet
                    OR (Account_Affiliation__c =: accAffiliationCode AND Sharing_Entity_Affiliation__c IN :setOfNationalCodes)
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

    private List<Income_Type_Distribution__c> getIncomeTypeDistRecords(String afID){
      return [SELECT id, Income_Type__c, Affiliate_Yearly__c, Amount__c,Description__c ,
              Shared_in_Advance__c, Gift__r.Name, Fund_Type__c, Expense__c, Income__c, //Gift__r.RPT_Revenue_Type__c,
              Gift__r.Deposit_Site__c, recordtype.name, Event_Hosted_By__c, 
              Amount_National_to_Affiliate__c, Amount_Affiliate_to_National__c

              FROM Income_Type_Distribution__c 
              WHERE Affiliate_Yearly__c =: afID];
    }

}