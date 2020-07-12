/*
*
*Name  :  RevSharing_CMICalculator
*Author:  Appirio India (Sai Krishna )
*Date  :  Februvary 08, 2017
*Purpose :  This batch class sets the Revenue Sharing Caclulations for CMI Context the Affiliate Yearly object
            Batch queries opps and summarizes them based on the logic contained within.
*
* Modified by :: Salesforce.org :: 29-May-2019 :: Zendesk: #67674
* Modified by :: Salesforce.org :: 02-August-2019 :: Zendesk: #69266
* Description :: Affiliate Banked Revenue with Unexpected Calculations
*/
global class RevSharing_CMICalculator implements Database.Batchable<sObject>,Database.stateful {
    // RecordTypesIds
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    //Used in Query
    private static Set<String> setOfRequiredCodes;
    //private static set<String> setOfNationalCodes;
    private static Map<String,Id> affliateCodeToaffYearlyId;
    private List<Id> allAffiliateYearls;
    private  String fYear;
    private  String accAffiliationCode;
	public  List<String> sharingAffiliationEntitySet = new List<String>();//Zendesk: #69266
    static {
        // UBRI:'D009', 'D012', 'E013', 'E015', 'E016', 'E017'
        //UnSharedIncome: 'A001', 'A002', 'A003', 'B003', 'P002', 'P003', 'K165', 'C165', 'K161', 'C161'
        setOfRequiredCodes = new Set<String> {'D009', 'D012', 'E013', 'E015', 'E016', 'E017', 'A001', 'A002', 'A003', 'B003'
            , 'P002', 'P003', 'K165', 'C165', 'K161', 'C161', 'R121', 'E131', 'E151', 'E141', 'C171'
            , 'P001', 'C005', 'C008', 'C009', 'D010', 'D011', 'E121'};
        //setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};
    }

    //UBRI CMI Fields Variables
    private Double renewalDues = 0.0;
    private Double extraContribs = 0.0;
    private Integer renewalDuesCount = 0;
    private Integer extraContribsCount = 0;
    private String reportType ;

    //Unshared CMI Fields Variables
    private Double unsharedFirstRenew =0.0;
    private Double unsharedFirstRenewNational =0.0;
    private Double unsharedNew =0.0;
    private Double unsharedNewNational =0.0;
    private Double unsharedRecap =0.0;
    private Double unsharedRecapNational =0.0;
    private Integer unsharedFirstRenewCount =0;
    private Integer unsharedFirstRenewNationalCount =0;
    private Integer unsharedNewCount =0;
    private Integer unsharedNewNationalCount =0;
    private Integer unsharedRecapCount =0;
    private Integer unsharedRecapNationalCount =0;
    private Double unsolicitedEarmarked =0.0;
    private Double recogGrants =0.0;
    private Double memorial =0.0;
    private Double advertising =0.0;
    private Double generalIncentive =0.0;
    private Double solicitedEarmarked =0.0;
    private Double benefit =0.0;
    private Double unsolicitedEarmarkedNat =0.0;
    private Double recogGrantsNat =0.0;
    private Double memorialNat =0.0;
    private Double advertisingNat =0.0;
    private Double generalIncentiveNat =0.0;
    private Double solicitedEarmarkedNat =0.0;
    private Double benefitNat =0.0;

    public Double unionCostFactor;
    public Double foundationCostFactor;
    public Double iGMI = 0.0;
    public Boolean eligibleForGMI;
    public Double indemnificationFromToday;
    public Double affiliateActualIndeminification;
    public Double AffiliateYearlyAffiliateIndemnification;
    public Double nationalActualIndemnification;
    public Double nationalActualIndemnificationFromToday;
    public Date startDate_CMI ;
    public Date endDate_CMI ;

    private static final Date cutoffDate = Date.newInstance(2002,01,01);

    global RevSharing_CMICalculator(Set<Id> affiYearlyIds, String reportType) {

        this.allAffiliateYearls = new List<Id>(affiYearlyIds);
        Affiliate_Yearly__c aff = [SELECT Id, GMI_Amount__c, Incentive_National_Share__c, Union_Cost_Factor__c,  Foundation_Cost_Factor__c, Fiscal_Year__c
                                   , BRI_Affiliate_Share__c , Eligible_for_GMI__c , Account__r.Affiliation__c, Affiliate_Indemnification_Threshold__c
                                   , Affiliate_Actual_Indemnification_from_To__c, Affiliate_Actual_Indemnification__c
                                   , National_Actual_Indemnification_Today__c, National_Actual_Indemnification__c,
                                   CMI_stage_DateStart__c, CMI_stage_DateEnd__c
                                   FROM Affiliate_Yearly__c
                                   WHERE Id = : allAffiliateYearls[0]];
        this.accAffiliationCode = aff.Account__r.Affiliation__c;
        this.fYear = aff.Fiscal_Year__c;
        this.iGMI = (aff.Incentive_National_Share__c) == null ? 0: aff.Incentive_National_Share__c;
        this.eligibleForGMI = aff.Eligible_for_GMI__c;
        this.indemnificationFromToday = (aff.Affiliate_Actual_Indemnification_from_To__c == null) ? 0 : aff.Affiliate_Actual_Indemnification_from_To__c;
        this.affiliateActualIndeminification = (aff.Affiliate_Actual_Indemnification__c == null) ? 0 : aff.Affiliate_Actual_Indemnification__c;
        this.AffiliateYearlyAffiliateIndemnification = (aff.Affiliate_Indemnification_Threshold__c == null) ? 0 : aff.Affiliate_Indemnification_Threshold__c;
        this.nationalActualIndemnification  = (aff.National_Actual_Indemnification__c == null) ? 0: aff.National_Actual_Indemnification__c;
        this.nationalActualIndemnificationFromToday = (aff.National_Actual_Indemnification_Today__c == NULL) ? 0 : aff.National_Actual_Indemnification_Today__c;
        this.unionCostFactor = (aff.Union_Cost_Factor__c) == null ? 0: aff.Union_Cost_Factor__c;
        this.foundationCostFactor = (aff.Foundation_Cost_Factor__c) == null ? 0: aff.Foundation_Cost_Factor__c;
        this.reportType = reportType;
        this.startDate_CMI = aff.CMI_stage_DateStart__c;
        this.endDate_CMI = aff.CMI_stage_DateEnd__c;
    }

    global Database.QueryLocator start(Database.BatchableContext Bc ){
        //Zendesk: #69266 -- Get Deposit site from custom metadata Types
        sharingAffiliationEntitySet = Utilities.getDepositSiteSet(accAffiliationCode );
        //END:Zendesk: #69266

            return Database.getQueryLocator([SELECT Id, Amount, accountId, Sharing_Entity_Affiliation__c, Program_Type__c, Deposit_Site_Code__c,Exclude_Cost_Factors_in_RevShare__c, Exclude_from_Revenue_Sharing__c
                                             , Sharing_Entity__c, Sharing_Code__c, RecordTypeId, Cost_Factor__c, Use_Campaign_Cost__c, CloseDate
                                             FROM Opportunity
                                             WHERE Revenue_Affiliation__c IN :sharingAffiliationEntitySet//Zendesk: #69266
                                             AND stageName = 'Completed'
                                             AND CloseDate >=: startDate_CMI AND CloseDate <=: endDate_CMI
                                            ]);

        //('D009','D012','E013','E015','E016','E017','A001','A002','A003','B003','P002','P003','C165','C161','R121','E131','E151','E141','C171','P001','C005','C008','C009','D010','D011','E121')

    }

    global void execute(Database.BatchableContext Bc, List<Opportunity> scope){
        Date cDate = Date.newInstance(2002, 1, 1);
        Set<String> setOfValidRecordTypes = new Set<String> { OPPORTUNITY_RT_TRANSACTION_Id, OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, OPPORTUNITY_RT_SOFTCREDIT_Id };

        for(Opportunity theOpp : scope){
            System.debug(theOpp.id);
            if(!theOpp.Exclude_from_Revenue_Sharing__c && theOpp.Amount != null
                && setOfRequiredCodes.contains(theOpp.Sharing_Code__c)
                && setOfValidRecordTypes.contains(theOpp.RecordTypeId)    
            ){
                //Roll up UBRI CMI fields logic
                //  if(theOpp.Sharing_Code__c == 'D009' || theOpp.Sharing_Code__c == 'D012' || theOpp.Sharing_Code__c == 'E013'
                //      || theOpp.Sharing_Code__c == 'E015' || theOpp.Sharing_Code__c == 'E016' || theOpp.Sharing_Code__c == 'E017'
                //      || theOpp.Sharing_Code__c == 'D010' || theOpp.Sharing_Code__c == 'D011' ){

                if(theOpp.Sharing_Code__c == 'D009' || theOpp.Sharing_Code__c == 'D012' || theOpp.Sharing_Code__c == 'E017'
                   || theOpp.Sharing_Code__c == 'D010' || theOpp.Sharing_Code__c == 'D011'){

                       renewalDues = renewalDues + theOpp.Amount;
                       renewalDuesCount = renewalDuesCount + 1;
                       continue;
                   }
                else if (theOpp.Sharing_Code__c == 'E013' || theOpp.Sharing_Code__c == 'E015' || theOpp.Sharing_Code__c == 'E016' ||
                            (theOpp.Sharing_Code__c == 'C171' && theOpp.CloseDate >= cDate)){

                    extraContribs = extraContribs + theOpp.Amount;
                    extraContribsCount = extraContribsCount + 1;
                    continue;
                }
                //}

                // Roll up Unshared CMI fields logic
                //else if(theOpp.Sharing_Code__c == 'A001' || theOpp.Sharing_Code__c == 'A002' || theOpp.Sharing_Code__c == 'A003' || theOpp.Sharing_Code__c == 'B003' ||
                //  theOpp.Sharing_Code__c == 'C005' || theOpp.Sharing_Code__c == 'C008' || theOpp.Sharing_Code__c == 'C009' || theOpp.Sharing_Code__c == 'P001' ||
                //  theOpp.Sharing_Code__c == 'P002' || theOpp.Sharing_Code__c == 'P003' || theOpp.Sharing_Code__c == 'K165' || theOpp.Sharing_Code__c == 'C165' ||
                //  theOpp.Sharing_Code__c == 'K161' || theOpp.Sharing_Code__c == 'C161' || theOpp.Sharing_Code__c == 'E131' || theOpp.Sharing_Code__c == 'E141' ||
                //  theOpp.Sharing_Code__c == 'E151' || theOpp.Sharing_Code__c == 'E121' || theOpp.Sharing_Code__c == 'R121' || (theOpp.Sharing_Code__c == 'C171' && cutoffDate > theOpp.CloseDate) ){

                //FirstRenew Fields
                if(theOpp.Sharing_Code__c == 'P001' || theOpp.Sharing_Code__c == 'P002' || theOpp.Sharing_Code__c == 'P003'){
                    if(theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        unsharedFirstRenew = unsharedFirstRenew +  theOpp.Amount;
                        unsharedFirstRenewCount = unsharedFirstRenewCount + 1;
                    }
                    else{
                        unsharedFirstRenewNational = unsharedFirstRenewNational +  theOpp.Amount;
                        unsharedFirstRenewNationalCount = unsharedFirstRenewNationalCount + 1;
                    }
                    continue;
                }

                // UnsharedNew Fields
                if(theOpp.Sharing_Code__c == 'A001' || theOpp.Sharing_Code__c == 'A002' || theOpp.Sharing_Code__c == 'A003'
                   || theOpp.Sharing_Code__c == 'C005' || theOpp.Sharing_Code__c == 'C008' || theOpp.Sharing_Code__c == 'C009'){
                       if(theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                           unsharedNew = unsharedNew + theOpp.Amount;
                           unsharedNewCount = unsharedNewCount + 1;
                       }
                       else{
                           unsharedNewNational = unsharedNewNational + theOpp.Amount;
                           unsharedNewNationalCount = unsharedNewNationalCount + 1;
                       }
                       continue;
                   }

                // UnsharedRecap
                if(theOpp.Sharing_Code__c == 'B003'){
                    if(theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        unsharedRecap = unsharedRecap +  theOpp.Amount;
                        unsharedRecapCount = unsharedRecapCount +1;
                    }
                    else{
                        unsharedRecapNational = unsharedRecapNational +  theOpp.Amount;
                        unsharedRecapNationalCount = unsharedRecapNationalCount +1;
                    }
                    continue;
                }

                // Unshared UnSolEarmark
                if(theOpp.Sharing_Code__c == 'C161'){
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        unsolicitedEarmarkedNat = unsolicitedEarmarkedNat +  theOpp.Amount;
                    } else {
                        unsolicitedEarmarked = unsolicitedEarmarked + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }
                // Unshared RecogGifts
                if(theOpp.Sharing_Code__c == 'C165'){
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        recogGrantsNat = recogGrantsNat +  theOpp.Amount;
                    } else {
                        recogGrants = recogGrants + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }

                // Unshared Memorial
                if(theOpp.Sharing_Code__c == 'C171' && theOpp.CloseDate < cDate){
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        memorialNat = memorialNat +  theOpp.Amount;
                    } else {
                        memorial = memorial + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }

                // Advertising
                if(theOpp.Sharing_Code__c == 'R121' || theOpp.Sharing_Code__c == 'E121' ){
                    //advertising = advertising + calculateAffiliateShare(theOpp, mapAccountIdToAmount, costFactor, false );
                    //advertisingNat = advertisingNat + calculateNationalShare(theOpp, mapAccountIdToAmount, costFactor, false );
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        advertisingNat = advertisingNat +  theOpp.Amount;
                    } else {
                        advertising = advertising + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }

                // General Incentive Income
                if(theOpp.Sharing_Code__c == 'E131' ){
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        generalIncentiveNat = generalIncentiveNat +  theOpp.Amount;
                    } else {
                        generalIncentive = generalIncentive + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }

                // Benifit Income
                if(theOpp.Sharing_Code__c == 'E141' ){
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        benefitNat = benefitNat +  theOpp.Amount;
                    } else {
                        benefit = benefit + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }

                //SoliciateEarMarked
                if(theOpp.Sharing_Code__c =='E151'){
                    //Zendesk: #67674: Calculated in Nationals only when deposit site contains "NA" or no value
                    if(theOpp.Deposit_Site_Code__c == null || theOpp.Deposit_Site_Code__c.containsIgnoreCase('NA')){ // && theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                        solicitedEarmarkedNat = solicitedEarmarkedNat +  theOpp.Amount;
                    } else {
                        solicitedEarmarked = solicitedEarmarked + theOpp.Amount;                    
                    }
                    //END: Zendesk: #67674
                    continue;
                }

                //}
            }
        }
    }

    global void finish(Database.BatchableContext Bc){
        Revenue_Sharing_Sytem_Controls__c revenueSharingControls;

        Affiliate_Yearly__c updatedYearlyAffiliate = new Affiliate_Yearly__c(Id = allAffiliateYearls[0]
                                                                             , CMI_stage_UBRI_RenewalDues__c = renewalDues.round()
                                                                             , CMI_stage_UBRI_RenewalDues_Count__c = renewalDuesCount
                                                                             , CMI_stage_UBRI_ExtraContribs__c = extraContribs.round()
                                                                             , CMI_stage_UBRI_ExtraContribs_Count__c = extraContribsCount
                                                                             , CMI_stage_Unshared_FirstRenew__c = unsharedFirstRenew.round()
                                                                             , CMI_stage_Unshared_FirstRenew_Count__c = unsharedFirstRenewCount
                                                                             , CMI_stage_Unshared_New__c = unsharedNew.round()
                                                                             , CMI_stage_Unshared_New_Count__c = unsharedNewCount
                                                                             , CMI_stage_Unshared_Recap__c = unsharedRecap.round()
                                                                             , CMI_stage_Unshared_Recap_Count__c = unsharedRecapCount
                                                                             , CMI_stage_Unshared_FirstRenew_Nat__c = unsharedFirstRenewNational.round()
                                                                             , CMI_stage_Unshared_FirstRenew_Nat_Count__c = unsharedFirstRenewNationalCount
                                                                             , CMI_stage_Unshared_New_Nat__c = unsharedNewNational.round()
                                                                             , CMI_stage_Unshared_New_Nat_Count__c = unsharedNewNationalCount
                                                                             , CMI_stage_Unshared_Recap_Nat__c = unsharedRecapNational.round()
                                                                             , CMI_stage_Unshared_Recap_Nat_Count__c = unsharedRecapNationalCount

                                                                             , CMI_stage_UnsolicitedEarmarked__c = unsolicitedEarmarked.round()
                                                                             , CMI_stage_Nat_UnsolicitedEarmarked__c = unsolicitedEarmarkedNat.round()
                                                                             , CMI_stage_Nat_RecogGrants__c = recogGrantsNat.round()
                                                                             , CMI_stage_RecogGrants__c = recogGrants.round()
                                                                             , CMI_stage_Memorial__c = memorial.round()
                                                                             , CMI_stage_Nat_Memorial__c = memorialNat.round()

                                                                             , CMI_stage_Advertising__c = advertising.round()
                                                                             , CMI_stage_Nat_Advertising__c = advertisingNat.round()
                                                                             , CMI_stage_GeneralIncentive__c = generalIncentive.round()
                                                                             , CMI_stage_Nat_GeneralIncentive__c = generalIncentiveNat.round()
                                                                             , CMI_stage_SolicitedEarmarked__c = solicitedEarmarked.round()
                                                                             , CMI_stage_Nat_SolicitedEarmarked__c = solicitedEarmarkedNat.round()
                                                                             , CMI_stage_Benefit__c = benefit.round()
                                                                             , CMI_stage_Nat_Benefit__c = benefitNat.round()
                                                                            );

        try {
            update updatedYearlyAffiliate;
            allAffiliateYearls.remove(0);
            if(!allAffiliateYearls.IsEmpty()){
                //RevSharing_IndemnificationActuals_Batch batch = new RevSharing_IndemnificationActuals_Batch(new Set<Id> (allAffiliateYearls), true, reportType);
                RevSharing_CMICalculator batch = new RevSharing_CMICalculator(new Set<Id>(allAffiliateYearls), reportType);
                Database.executeBatch(batch,2000);
            }
            else {
                revenueSharingControls= Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0];
                RevSharing_StageReportCalculations.sendEmail(reportType, revenueSharingControls.Report_Request_Sender_Email__c, revenueSharingControls.Report_Request_Owner_Email__c, fYear);

                //update the Custom Setting.
                update new Revenue_Sharing_Sytem_Controls__c(Id = revenueSharingControls.Id, Report_Request_Owner_Email__c = null,
                                                             Report_Request_In_Progress__c = false, Last_End_Run_DateTime__c = System.now());
                /*Added field Last_End_Run_DateTim__c by Bhavesh for T-647039*/
            }

        }
        catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('RevSharing_CMICalculator','finish',e.getMessage());
            log.logException(e);
            log.saveLogs();

            //update the Custom Setting.
            update new Revenue_Sharing_Sytem_Controls__c(Id = revenueSharingControls.Id, Report_Request_In_Progress__c = false,
                                                         Last_Run_Details__c = 'Report Failed', Last_End_Run_DateTime__c = System.now());
            /*Added field Last_End_Run_DateTim__c by Bhavesh for T-647039*/
        }
    }


}