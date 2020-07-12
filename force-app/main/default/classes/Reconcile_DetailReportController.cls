/*
*
*Name  :  Reconcile_DetailReportController
*Author:  Appirio India (James Wasilewski)
*Date  :  November 09, 2017
*Purpose :  Controller for the detail reports called from Foundation GMI, Foundation Non-GMI, Union GMI, Union Non-GMI reconciliation reports
            The Detail report outputs the source opportunity data based on the report that calls this class in an excel spreadsheet output"
* Modifield by :the changes by SFDO #66998 3/05/2019
* Modified by :: Salesforce.org :: 21-June-2019 :: Zendesk: #68203
* Description :: The change is made configurable to allow multiple deposit sites (falling under same category) as part of report 
*
*/
public with sharing class Reconcile_DetailReportController {

  private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
  private static Set<String> setOfFoundationCodes;
  private static Set<String> setOfUnionCodes;
  private static set<String> setOfNationalCodes;
  private static List<String> sharingAffiliationEntitySet; //#68203
  
  public List<WrapperClass> wrapperClassList {get;set;}
  public String affiliate {get;set;}
  public Date startDate {get;set;}
  public Date endDate {get;set;}

  static{
    setOfFoundationCodes = new Set<String> {'R112', 'R113','R121','R131','R141','R151','R181','R191',
                                          'K161', 'K165','K171','N111','N175',
                                          'Q001','Q002','Q003','Q004','Q005'};
    
    setOfUnionCodes = new Set<String> {'E121','E131','E141','E151','E181','E191',
                                       'C161','C165',
                                       'U001','U002', 'U003', 'U004', 'U005' };

    setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};
    //#68203
    sharingAffiliationEntitySet = new List<String>();

  }

    public Reconcile_DetailReportController() {      
        wrapperClassList = new List<WrapperClass>();

        affiliate = ApexPages.currentPage().getParameters().get('affiliate');

        startDate = Date.valueOf(ApexPages.currentPage().getParameters().get('startDate'));
        endDate = Date.valueOf(ApexPages.currentPage().getParameters().get('endDate'));

        String reportType = ApexPages.currentPage().getParameters().get('report');

        //Zendesk: #68203 -- Get Deposit site from custom metadata Types
        sharingAffiliationEntitySet = Utilities.getDepositSiteSet(affiliate);
        //END:Zendesk: #68203

        List<Opportunity> listOfOpps = new List<Opportunity>();
        if(reportType != null && (reportType == 'FoundationNonGMI' || reportType == 'FoundationGMI') ){
            //#68203
            //listOfOpps = queryFoundation(affiliate, startDate, endDate);
            listOfOpps = queryOpportunity(affiliate, sharingAffiliationEntitySet, startDate, endDate, setOfFoundationCodes);
        } else{
            //#68203
            //listOfOpps = queryUnion(affiliate, startDate, endDate);
            listOfOpps = queryOpportunity(affiliate, sharingAffiliationEntitySet, startDate, endDate, setOfUnionCodes);
        }


        String sharingCategory;
        String packageCode;
        String recordTypeName;
        String depositSite;

        for(Opportunity opp: listOfOpps){
            opp.rC_Giving__Source_Code__c = makeEmptyString(opp.rC_Giving__Source_Code__c);
            if(opp.Exclude_from_Revenue_Sharing__c == False && opp.Amount !=null
               && opp.Deposit_Site__c != null && opp.Deposit_Site__c != 'COS*' && opp.Deposit_Site__c != 'NAE'
               && opp.rC_Giving__Source_Code__c.left(3) != 'ENT' &&  opp.Sharing_Code__c != 'T400' 
               && opp.Campaign_Type__c != 'T'
              ){
                sharingCategory = '';
                packageCode = '';
                recordTypeName = '';
                depositSite = '';
                
                if (opp.RPT_Package_Code__c !=null && opp.RPT_Package_Code__c.length()>=4  
                    && opp.RPT_Package_Code__c.subString(2, 4) == 'CP'){
                  packageCode = opp.RPT_Package_Code__c.subString(2, 4);
                } 

                if(opp.Deposit_Site__c != null) depositSite = opp.Deposit_Site__c.subString(0,2);

                //Zendesk: #68203
                Boolean isDepositSiteSameAsAffiliate = false;
                isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(opp
                                                      ,  sharingAffiliationEntitySet
                                                      ,  depositSite);
                //END:Zendesk: #68203

                //System.assert(false, [Select id, Sharing_Entity_Affiliation__c from Opportunity]);
                if(reportType == 'FoundationNonGMI'){
                    sharingCategory = getFoundationNonGMISharingCategory(opp, packageCode, depositSite, affiliate, isDepositSiteSameAsAffiliate );
                } else if(reportType == 'FoundationGMI'){
                    /*//todo*/  sharingCategory = getFoundationGMISharingCategory(opp, packageCode, depositSite, affiliate, isDepositSiteSameAsAffiliate );
                } else if(reportType == 'UnionNonGMI'){
                    sharingCategory = getUnionNonGMISharingCategory(opp, packageCode, depositSite, affiliate, isDepositSiteSameAsAffiliate);
                } else if(reportType == 'UnionGMI'){
                    /*//todo*/  sharingCategory = getUnionGMISharingCategory(opp, packageCode, depositSite, affiliate, isDepositSiteSameAsAffiliate);
                }

                if(OPPORTUNITY_RT_TRANSACTION_Id == opp.RecordTypeId){
                    recordTypeName = 'Transaction';
                } else if (OPPORTUNITY_RT_PLEDGE_PAYMENT_Id == opp.RecordTypeId){
                    recordTypeName = 'Pledge Payment';
                } else if (OPPORTUNITY_RT_SOFTCREDIT_Id == opp.RecordTypeId){
                    recordTypeName = 'Soft Credit';
                }

                wrapperClassList.add(new WrapperClass(opp, sharingCategory, packageCode, recordTypeName));
            }
        }
        
    }
    
    private String getFoundationNonGMISharingCategory(Opportunity o, String packageCode, String depositSite, String affiliate, Boolean isDepositSiteSameAsAffiliate){
        String sharingCategory;
        //System.assert(false, o.Sharing_Code__c+'===='+depositSite+'===='+affiliate);
        if(o.Sharing_Code__c == 'R112' && isDepositSiteSameAsAffiliate){ //#68203
            sharingCategory = 'w_A1_Affiliate Direct Mail';
        }
        else if( ((o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' 
                   || o.Sharing_Code__c == 'K171' || o.Sharing_Code__c == 'R181'
                   ) || (o.Sharing_Code__c == 'R131' && packageCode != 'CP') )
                 && isDepositSiteSameAsAffiliate ){//#68203:depositSite == affiliate
            sharingCategory = 'w_B1_Affiliate Banked Unrestricted Incentive Income';
        }
        else if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode != 'CP'))
                && isDepositSiteSameAsAffiliate ){//#68203
            sharingCategory = 'w_B3_Affiliate Banked Solicited Earmarked';
        }
        else if(o.Sharing_Code__c == 'R181' && isDepositSiteSameAsAffiliate){//#68203
            sharingCategory = 'w_B4_Affiliate In-Kind Gifts';
        }
        else if(o.Sharing_Code__c == 'K165' && isDepositSiteSameAsAffiliate){//#68203
            sharingCategory = 'w_C1_Affiliate Banked Unshared Recognized Foundation Grants';
        }
        else if(o.Sharing_Code__c == 'K161' && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_C2_Affiliate Banked Unshared Unsolicited Earmarked';
        }
        else if(o.Sharing_Code__c == 'Q001' && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_D1_Affiliate Banked Shared Bequest';
        }
        else if(o.Sharing_Code__c == 'Q002' && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_D2_Affiliate Banked Directed Bequest';
        }
        else if(o.Sharing_Code__c == 'Q003' && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_D3_Affiliate Banked Earmarked Bequest';
        }
        else if(o.Sharing_Code__c == 'Q004' && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_D4_Affiliate Banked Unshared Bequest';
        }
        else if(o.Sharing_Code__c == 'Q005' && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_D5_Affiliate Banked other Bequest';
        }
        else if(o.Sharing_Code__c == 'Q001' && depositSite == 'NA'){
            sharingCategory = 'v_4g_National Banked Shared Bequest';
        }
        else if(o.Sharing_Code__c == 'Q002' && depositSite == 'NA'){
            sharingCategory = 'v_4h_National Banked Directed Bequest';
        }
        else if(o.Sharing_Code__c == 'Q003' && depositSite == 'NA'){
            sharingCategory = 'v_4i_National Banked Earmarked Bequest';
        }
        else if(o.Sharing_Code__c == 'Q004' && depositSite == 'NA'){
            sharingCategory = 'v_4j_National Banked Unshared Bequest';
        }
        else if(o.Sharing_Code__c == 'Q005' && depositSite == 'NA'){
            sharingCategory = 'v_4k_National Banked Other Bequest';
        }
        else if(o.Sharing_Code__c == 'R191' && isDepositSiteSameAsAffiliate ){
            sharingCategory = 'Special Sharing and Mega Gift Affiliate';
        }
        else if(o.Sharing_Code__c == 'R191'  && depositSite == 'NA' ){
            sharingCategory = 'Special Sharing and Mega Gift National';
        }  
        else if(o.Sharing_Code__c == 'R141' && (depositSite == 'NA' || isDepositSiteSameAsAffiliate)){
            sharingCategory = 'w_Schedule2_header_Benefit Income';
        }
        else if(o.Sharing_Code__c == 'N111' && depositSite == 'NA'){
            sharingCategory = 'v_1A_Gross National Foundation Banked BRI';
        }
        else if(o.Sharing_Code__c == 'N175' && depositSite == 'NA'){
            sharingCategory = 'v_1C_National Banked Net Workplace Giving';
        }
        else if( ((o.Sharing_Code__c == 'R131' && packageCode != 'CP') ||
                  (o.Sharing_Code__c == 'R113' || o.Sharing_Code__c == 'R121' 
                     || o.Sharing_Code__c == 'K171' ) )  && depositSite == 'NA'){
            sharingCategory = 'v_2A_National Banked Unrestricted Incentive Income';
        }
        else if(o.Sharing_Code__c == 'K165' && depositSite == 'NA'){
            sharingCategory = 'x_National Banked Unshared Recognized Foundation Grants';
        }
        else if(o.Sharing_Code__c == 'K161' && depositSite == 'NA'){
            sharingCategory = 'x_National Banked Unshared Unsolicited Earmarked';
        }
        else if( (o.Sharing_Code__c == 'R151' || (o.Sharing_Code__c == 'R131' && packageCode == 'CP') )
                  && depositSite == 'NA'){
            sharingCategory = 'v_3A_National Banked Solicited Earmarked, x_Shedule 2_National Banked Solicited Earmarked';
        }
        else if(o.Sharing_Code__c == 'Q005' && depositSite == 'NA'){
            sharingCategory = 'x_Schedule 4 Q005 Not Sharing Entity of Affiliate';
        }
        return sharingCategory;
    }

    private String makeEmptyString(String input) { return (input == null) ? '' : input; }

    
    public class WrapperClass{
        public Opportunity objOpp {get;set;}
        public String Sharing_Category {get;set;}
        public String cp {get;set;}
        public String recordTypeName {get;set;}
        
        public WrapperClass(Opportunity objOpp, String sharing_Category, String packageCode, String recName ){
            this.objOpp = objOpp;
            this.Sharing_Category = sharing_Category;
            this.cp = packageCode;
            this.recordTypeName = recName;
        }
    }
    
    //#68203:: Commenting the redundant code and created a new method queryOpportunity
    //Name, account.Affiliation__c, batch_Log__r.name, packageCodeaign.rC_Giving__Source_Code__c,rC_Giving__Campaign_Source_Code__c
    /*private List<Opportunity> queryFoundation(String accAffiliationCode, Date startDate, Date endDate){
        //ZenDesk - #66998 // Added Batch_Log__r.Name field in query
        return [SELECT Id,accountId, account.name,account.Account_Number__c,account.Chapter__c,Auto_Giving_Number__c,
                Batch_Date__c,Amount, RPT_Package_Code__c, Batch__c, rC_Giving__Source_Code__c, //campaign.Name, 
                Deposit_Site__c,Sharing_Code__c, Sharing_Code_Description__c, Sharing_Entity__c,  Restriction__c, 
                Fund__c, Chapter__c, Program_Type__c, RecordTypeId, Sharing_Entity_Affiliation__c,Batch_Log__r.Name,
                Exclude_from_Revenue_Sharing__c,//rC_Giving__Campaign_Source_Code__c,
                account.Affiliation__c, Campaign_Type__c
             FROM Opportunity
             where RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                    :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                    :OPPORTUNITY_RT_SOFTCREDIT_Id)
             AND Sharing_Code__c IN :setOfFoundationCodes
             AND Amount > 0
             AND (Sharing_Entity_Affiliation__c =: accAffiliationCode
                  OR (Account_Affiliation__c =: accAffiliationCode AND Sharing_Entity_Affiliation__c IN :setOfNationalCodes)
                 )
             AND stageName = 'Completed'
             AND CloseDate >= :startDate AND CloseDate <= :endDate Limit 10000];
    }

    private List<Opportunity> queryUnion(String accAffiliationCode, Date startDate, Date endDate){
        //ZenDesk - #66998 // Added Batch_Log__r.Name field in query
        return [SELECT Id,accountId, account.name,account.Account_Number__c,account.Chapter__c,Auto_Giving_Number__c,
                Batch_Date__c,Amount, RPT_Package_Code__c, Batch__c, rC_Giving__Source_Code__c, //campaign.Name, 
                Deposit_Site__c,Sharing_Code__c, Sharing_Code_Description__c, Sharing_Entity__c,  Restriction__c, 
                Fund__c, Chapter__c, Program_Type__c, RecordTypeId, Sharing_Entity_Affiliation__c,Batch_Log__r.Name,
                Exclude_from_Revenue_Sharing__c,//rC_Giving__Campaign_Source_Code__c,
                account.Affiliation__c
             FROM Opportunity
             where RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                    :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                    :OPPORTUNITY_RT_SOFTCREDIT_Id)
             AND Sharing_Code__c IN :setOfUnionCodes
             AND Amount > 0
             AND (Sharing_Entity_Affiliation__c =: accAffiliationCode
                  OR (Account_Affiliation__c =: accAffiliationCode AND Sharing_Entity_Affiliation__c IN :setOfNationalCodes)
                 )
             AND stageName = 'Completed'
             AND CloseDate >= :startDate AND CloseDate <= :endDate Limit 10000];
    }*///END::68203:: Code Comment

    //#68203 
    private List<Opportunity> queryOpportunity(String accAffiliationCode, List<String> accAffiliationCodeSet, Date startDate, Date endDate, Set<String> sharingCodeSet){
        //ZenDesk - #66998 // Added Batch_Log__r.Name field in query
        return [SELECT Id,accountId, account.name,account.Account_Number__c,account.Chapter__c,Auto_Giving_Number__c,
                Batch_Date__c,Amount, RPT_Package_Code__c, Batch__c, rC_Giving__Source_Code__c, //campaign.Name, 
                Deposit_Site__c,Sharing_Code__c, Sharing_Code_Description__c, Sharing_Entity__c,  Restriction__c, 
                Fund__c, Chapter__c, Program_Type__c, RecordTypeId, Sharing_Entity_Affiliation__c,Batch_Log__r.Name,
                Exclude_from_Revenue_Sharing__c,//rC_Giving__Campaign_Source_Code__c,
                account.Affiliation__c, Campaign_Type__c
             FROM Opportunity
             where RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, 
                                    :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, 
                                    :OPPORTUNITY_RT_SOFTCREDIT_Id)
             AND Sharing_Code__c IN :sharingCodeSet
             AND Amount > 0
             AND (Sharing_Entity_Affiliation__c IN :accAffiliationCodeSet//#68203::accAffiliationCode
                  OR (Account_Affiliation__c = :accAffiliationCode AND Sharing_Entity_Affiliation__c IN :setOfNationalCodes)
                 )
             AND stageName = 'Completed'
             AND CloseDate >= :startDate AND CloseDate <= :endDate Limit 10000];
    }
    
    private String getUnionGMISharingCategory(Opportunity o, String packageCode, String depositSite, String affiliate, Boolean isDepositSiteSameAsAffiliate){
        String sharingCategory;

        String sharing_entity;
        
        if( ((o.Sharing_Code__c == 'E131' || o.Sharing_Code__c == 'E121') 
              || (o.Sharing_Code__c == 'E131' && packageCode != 'CP'))
            && isDepositSiteSameAsAffiliate){//#68203:depositSite == affiliate
            sharingCategory = 'v_1 or v_2b Affiliate Total Incentive Income';
        }  
        else if( (o.Sharing_Code__c == 'E151'
                   || (o.Sharing_Code__c == 'E131' && packageCode == 'CP'))
                 && isDepositSiteSameAsAffiliate ){
            sharingCategory = 'v_1 or v_3b Affiliate Solicited Earmarked';
        }
        else if( ((o.Sharing_Code__c == 'E131' || o.Sharing_Code__c == 'E121') 
                   || (o.Sharing_Code__c == 'E131' && packageCode != 'CP'))
                 && depositSite == 'NA' ){
            sharingCategory = 'Total Incentive national';
        }else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'E181' ){
            sharingCategory = 'Affiliate In-Kind Gifts';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'C165' ){
            sharingCategory = 'Affiliate Unshared Grants';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'C161' ){
            sharingCategory = 'Affiliate Unshared Earmarks';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U001' ){
            sharingCategory = 'v_4affiliate Banked Shared Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U002' ){
            sharingCategory = 'v_4b_Affiliate Banked Directed Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U003' ){
            sharingCategory = 'v_4c_Affiliate Banked Earmarked Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U004' ){
            sharingCategory = 'v_4d_Affiliate Banked Unshared Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U005' && sharing_entity == affiliate ){
            sharingCategory = 'v_4e_Affiliate Banked Other Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U005' && sharing_entity != affiliate ){
            sharingCategory = 'v_4f_Not Affiliate for Sharing Entity';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U001' ){
            sharingCategory = 'v_4g_National Banked Shared Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U002' ){
            sharingCategory = 'v_4h_National Banked Directed Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U003' ){
            sharingCategory = 'v_4i_National Banked Earmarked Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U004' ){
            sharingCategory = 'v_4j_National Banked Unshhared Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U005' && sharing_entity != affiliate ){
            sharingCategory = 'x Sched 3 U005 Not Affiliate for Sharing Entity';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U005' && sharing_entity == affiliate){
            sharingCategory = 'v_4k_National Banked Other Bequest';
        }
        else if( (o.Sharing_Code__c == 'E141' && ( isDepositSiteSameAsAffiliate) || depositSite == 'NA' )){
            sharingCategory = 'w_Schedule3_header_Benefit Income';
        }
        else if( o.Sharing_Code__c == 'E191' && isDepositSiteSameAsAffiliate ){
            sharingCategory = 'Special Sharing and Mega Gift Affiliate';
        }
        else if( o.Sharing_Code__c == 'E191' && depositSite == 'NA' ){
            sharingCategory = 'Special Sharing and Mega Gift National';
        }
        return sharingCategory;
    }
    
    private String getUnionNonGMISharingCategory(Opportunity o, String packageCode, String depositSite, String affiliate, Boolean isDepositSiteSameAsAffiliate){
        String sharingCategory;

        if( ((o.Sharing_Code__c == 'E131' || o.Sharing_Code__c == 'E121') 
             || (o.Sharing_Code__c == 'E131' && packageCode != 'CP'))
            && isDepositSiteSameAsAffiliate){//#68203:depositSite == affiliate
            sharingCategory = 'w_A1_Affiliate Banked Unrestricted Incentive Income';
        }
        else if( (o.Sharing_Code__c == 'E151'
                  || (o.Sharing_Code__c == 'E131' && packageCode == 'CP'))
                 && isDepositSiteSameAsAffiliate){
            sharingCategory = 'w_A3_Affiliate Banked Solicited Earmarked';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'E181'){
            sharingCategory = 'w_A4_Affiliate In-Kind Gifts';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'C165'){
            sharingCategory = 'w_B1_Affiliate Banked Unshared Recognized Foundation Grants';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'C161'){
            sharingCategory = 'w_B2_Affiliate Banked Unshared Unsolicited Earmarked';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U001'){
            sharingCategory = 'v_3a_Affiliate Banked Shared Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U002'){
            sharingCategory = 'v_3b_Affiliate Banked Directed Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U003'){
            sharingCategory = 'v_3c_Affiliate Banked Earmarked Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U004'){
            sharingCategory = 'v_3d_Affiliate Banked Unshared Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'U005'){
            sharingCategory = 'v_3e_ or v_3f_Affiliate Banked Other Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U001'){
            sharingCategory = 'v_3g_National Banked Shared Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U002'){
            sharingCategory = 'v_3h_National Banked Directed Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U003'){
            sharingCategory = 'v_3i_National Banked Earmarked Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U004'){
            sharingCategory = 'v_3j_National Banked Unshhared Bequest';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'U005'){
            sharingCategory = 'v_3k_National Banked Other Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'E191'){
            sharingCategory = 'Special Sharing and Mega Gift Affiliate';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'E191'){
            sharingCategory = 'Special Sharing and Mega Gift National';
        }
        else if( isDepositSiteSameAsAffiliate && o.Sharing_Code__c == 'E141'){
            sharingCategory = 'w_Schedule2_header_Benefit Income';
        }
        else if( depositSite == 'NA' && (o.Sharing_Code__c == 'E121'
                 || (o.Sharing_Code__c == 'E131' && packageCode != 'CP'))
               ){
            sharingCategory = 'v_1A_National Banked Unrestricted Incentive Income';
        }
        else if( depositSite == 'NA' && o.Sharing_Code__c == 'C161'){
            sharingCategory = 'x_Schedule 3_National Banked Unshared Unsolicited Earmarked';
        }
        else if( depositSite == 'NA' && (o.Sharing_Code__c == 'E151'
                 || (o.Sharing_Code__c == 'E131' && packageCode == 'CP'))
               ){
            sharingCategory = 'v_2A_National Banked Solicited Earmarked';
        }
        else if( depositSite == 'NA' && (o.Sharing_Code__c == 'E151'
                 || (o.Sharing_Code__c == 'E131' && packageCode == 'CP'))
               ){
            sharingCategory = 'x_Shedule 2_National Banked Solicited Earmarked';
        }
        else if( depositSite == 'NA' && (o.Sharing_Code__c == 'U005'
                 || (o.Sharing_Code__c == 'E131' && packageCode == 'CP'))
               ){
            sharingCategory = 'x_Schedule 4 Q005 Not Sharing Entity of Affiliate';
        }
        return sharingCategory;
    }
    private static String getFoundationGMISharingCategory(Opportunity opp, String packageCode, String depositSite, String affiliate, Boolean isDepositSiteSameAsAffiliate ){
        String sharingCategory;
        String sharingEntity = opp.Sharing_Entity__c;
        
        if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'R112' ){
            sharingCategory = 'w_A1a_Affiliate Direct Mail';
        }
        else if( (opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121' || opp.Sharing_Code__c == 'K171') 
            && isDepositSiteSameAsAffiliate && !(opp.Sharing_Code__c == 'R131' && packageCode == 'CP' && isDepositSiteSameAsAffiliate )){
            sharingCategory = 'v_2 or v_3b Affiliate Total Incentive Income';
        }
        else if( (opp.Sharing_Code__c == 'R151' && isDepositSiteSameAsAffiliate) || (opp.Sharing_Code__c == 'R131' && packageCode == 'CP' && isDepositSiteSameAsAffiliate) ){
            sharingCategory = 'v_2 or v_4b Affiliate Solicited Earmarked';
        }
        else if( (opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121' || opp.Sharing_Code__c == 'K171' ) 
            && depositSite == 'NA' && !(opp.Sharing_Code__c == 'R131' && packageCode == 'CP' && depositSite == 'NA')){
             sharingCategory = 'v_2 or v_3a National Total Incentive Income';
        }
        else if( (opp.Sharing_Code__c == 'R151' && depositSite == 'NA') || (packageCode == 'CP' && opp.Sharing_Code__c == 'R131' && depositSite == 'NA') ){
            sharingCategory = 'v_2 or v_4a National Solicited Earmarked';
        } 
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'R181'){
            sharingCategory = 'w_B4_Affiliate In-Kind Gifts';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'K165'){
            sharingCategory = 'w_C1_Affiliate Banked Unshared Recognized Foundation Grants';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'K161'){
            sharingCategory = 'w_C2_Affiliate Banked Unshared Unsolicited Earmarked';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'K165'){
            sharingCategory = 'x_National Banked Unshared Recognized Foundation Grants';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'K161'){
            sharingCategory = 'x_National Banked Unshared Unsolicited Earmarked';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'Q001'){
            sharingCategory = 'w_D1_Affiliate Banked Shared Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'Q002'){
            sharingCategory = 'w_D2_Affiliate Banked Directed Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'Q003'){
            sharingCategory = 'w_D3_Affiliate Banked Earmarked Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'Q004'){
            sharingCategory = 'w_D4_Affiliate Banked Unshared Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'Q005' && sharingEntity == affiliate ){
            sharingCategory = 'w_D5_Affiliate Banked Other Bequest';
        }
        else if( isDepositSiteSameAsAffiliate && opp.Sharing_Code__c == 'Q005' && sharingEntity != affiliate ){
            sharingCategory = 'w_D5 Not Affiliate for Sharing Entity';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'Q001'){
            sharingCategory = 'v_5g_National Banked Shared Bequest';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'Q002'){
            sharingCategory = 'v_5h_National Banked Directed Bequest';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'Q003'){
            sharingCategory = 'v_5i_National Banked Earmarked Bequest';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'Q004'){
            sharingCategory = 'v_5j_National Banked Unshhared Bequest';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'Q005' && sharingEntity != affiliate){
            sharingCategory = 'x Sched 3 Q005 Not Affiliate for Sharing Entity';
        }
        else if( depositSite == 'NA' && opp.Sharing_Code__c == 'Q005' && sharingEntity == affiliate){
            sharingCategory = 'v_5k_National Banked Other Bequest';
        }
        else if( opp.Sharing_Code__c == 'R141' && (isDepositSiteSameAsAffiliate || depositSite == 'NA') ){
            sharingCategory = 'w_Schedule3_header_Benefit Income';
        }
        else if( opp.Sharing_Code__c == 'N111' && sharingEntity == affiliate && depositSite == 'NA'){
            sharingCategory = 'v_1A_Gross National Foundation Banked BRI';
        }
        else if( opp.Sharing_Code__c == 'N175' && sharingEntity == affiliate && depositSite == 'NA'){
            sharingCategory = 'v_1C_National Banked Net Workplace Giving';
        }
        else if( opp.Sharing_Code__c == 'R191'){
            sharingCategory = 'Special Sharing and Mega Gift Affiliate';
        }
        else if( opp.Sharing_Code__c == 'R191'){
            sharingCategory = 'Special Sharing and Mega Gift National';
        }
        return sharingCategory;
    }
}