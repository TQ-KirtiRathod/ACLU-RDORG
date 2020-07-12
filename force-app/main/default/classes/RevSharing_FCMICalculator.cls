/*
*
*Name  :  RevSharing_FCMICalculator
*Author:  Appirio India (Shikha Gupta, TBurre )
*Date  :  February 16, 2017
*Purpose :  This batch class sets the Revenue Sharing Caclulations for FCMI Context the Affiliate Yearly object
            Batch queries opps and summarizes them based on the logic contained within.
*Modified by :: Salesforce.org :: 30-May-2019 :: Zendesk: #67674
*Modified by :: Salesforce.org :: 02-August-2019 :: Zendesk: #69266
*/
global class RevSharing_FCMICalculator implements Database.Batchable<sObject>,Database.stateful {
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
        setOfRequiredCodes = new Set<String> {'N111','N175','R113', 'R112','R121','R131','K171','R141','R151','R181'
                                              ,'K161','K165','R191','R192','T400' };
        //setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};

// Why don't reports look at other National deposit sites besides 'NA%'?

    }

    //FCMI Fields Variables
    private String reportType;
    private Double natDirectMailLess = 0.0;
    private Integer natDirectMailLessCount = 0;
    private Double natWorkplace = 0.0;
    private Double natDirectMailGreater2500 = 0.0;
    private Double natAdvertising = 0.0;
    private Double natGenIncentive = 0.0;
    private Double natBenefit = 0.0;
    private Double natSolEarmark = 0.0;
    private Double natInKind = 0.0;
    private Double affiliateBRI = 0.0;
    private Integer affiliateBRICount = 0;
    private Double directMailGreater2500 = 0.0;
    private Double advertising = 0.0;
    private Double genIncentive = 0.0;
    private Double benefit = 0.0;
    private Double solEarmark = 0.0;
    private Double InKind = 0.0;
    private Double unSolEarmark = 0.0;
    private Double recogGrant = 0.0;
    private Double memorial = 0.0;
    private Double natBanked = 0.0;
    private Double natUnSolEarmark = 0.0;
    private Double natRecogGrant = 0.0;
    private Double natMemorial = 0.0;
    private Double affBanked = 0.0;
    private Double specialSharing = 0.0;
    private Double earlySharing = 0.0;
    private Double natSpecialSharing = 0.0;
    private Double natEarlySharing = 0.0;
    private Double endowment = 0.0;
    private Double natEndowment = 0.0;
    private Double fcmiNatAffAmount = 0.0;

    public Double unionCostFactor;
    public Double foundationCostFactor;
    public Double iGMI = 0.0;
    public Boolean eligibleForGMI;
    public Double indemnificationFromToday;
    public Double affiliateActualIndeminification;
    public Double AffiliateYearlyAffiliateIndemnification;
    public Double nationalActualIndemnification;
    public Double nationalActualIndemnificationFromToday;
    public Date startDate_FCMI;
    public Date endDate_FCMI;

    private static final Date y2kCutoff = Date.newInstance(2000,01,01);


    global RevSharing_FCMICalculator(Set<Id> affiYearlyIds, String reportType) {

        this.allAffiliateYearls = new List<Id>(affiYearlyIds);
        Affiliate_Yearly__c aff = [SELECT Id, GMI_Amount__c, Incentive_National_Share__c, Union_Cost_Factor__c,  Foundation_Cost_Factor__c, Fiscal_Year__c
                                            , BRI_Affiliate_Share__c , Eligible_for_GMI__c , Account__r.Affiliation__c, Affiliate_Indemnification_Threshold__c
                                            , Affiliate_Actual_Indemnification_from_To__c, Affiliate_Actual_Indemnification__c
                                            , National_Actual_Indemnification_Today__c, National_Actual_Indemnification__c,
                                            FCMI_stage_DateStart__c, FCMI_stage_DateEnd__c
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
      this.startDate_FCMI = aff.FCMI_stage_DateStart__c;
      this.endDate_FCMI = aff.FCMI_stage_DateEnd__c;
    }

    global Database.QueryLocator start(Database.BatchableContext Bc ){
		//Zendesk: #69266 -- Get Deposit site from custom metadata Types
        sharingAffiliationEntitySet = Utilities.getDepositSiteSet(accAffiliationCode );
        //END:Zendesk: #69266

        return Database.getQueryLocator([SELECT Id, Amount, accountId, Sharing_Entity_Affiliation__c, Program_Type__c, Exclude_Cost_Factors_in_RevShare__c, Exclude_from_Revenue_Sharing__c
                                      , Sharing_Entity__c, Sharing_Code__c, RecordTypeId, Cost_Factor__c, Deposit_Site__c, Use_Campaign_Cost__c, CloseDate
                                     FROM Opportunity
                                     WHERE Revenue_Affiliation__c IN :sharingAffiliationEntitySet//Zendesk: #69266
                                     AND stageName = 'Completed'
                                     AND CloseDate >=: startDate_FCMI AND CloseDate <=: endDate_FCMI
                                    ]);
    }

    global void execute(Database.BatchableContext Bc, List<Opportunity> scope){
      for(Opportunity theOpp : scope){
		  //Zendesk: #69266
          Boolean isDepositSiteSameAsAffiliate = false;
          if(theOpp.Deposit_Site__c != null) {
             String depositSite = theOpp.Deposit_Site__c.subString(0,2);
            isDepositSiteSameAsAffiliate = Utilities.getIsDepositSiteSameAsAffiliate(theOpp
                                                          ,  sharingAffiliationEntitySet
                                                          ,  depositSite);  
          }
           
            //END:Zendesk: #69266
          if(!theOpp.Exclude_from_Revenue_Sharing__c && theOpp.Amount != null
             && setOfRequiredCodes.contains(theOpp.Sharing_Code__c)
             &&
             (  theOpp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
             || theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
             || theOpp.RecordTypeId == OPPORTUNITY_RT_SOFTCREDIT_Id )             
          ){

    // FBRI less than 2500
               if(theOpp.Sharing_Code__c == 'N111'){
                natDirectMailLess = natDirectMailLess +  theOpp.Amount;
                natDirectMailLessCount = natDirectMailLessCount + 1;
               }
    // FBRI Workplace
               else if(theOpp.Sharing_Code__c == 'N175'){
                natWorkplace = natWorkplace +  theOpp.Amount;
               }


    // National Bank Incentive Income
               else if(theOpp.Sharing_Code__c == 'R113'){
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                  natDirectMailGreater2500 = natDirectMailGreater2500 +  theOpp.Amount;
                } else {
                  directMailGreater2500 = directMailGreater2500 + theOpp.Amount;
                }
                // Changes for using Deposit Site for ZD: #67674
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){// && (theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('35')){
                    fcmiNatAffAmount = fcmiNatAffAmount + theOpp.Amount;
                }
               }

               else if(theOpp.Sharing_Code__c == 'R121'){
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                  natAdvertising = natAdvertising +  theOpp.Amount;
                } else {
                  advertising  = advertising + theOpp.Amount;
                }
                // Changes for using Deposit Site for ZD: #67674
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){// && theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('35')) theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                    fcmiNatAffAmount = fcmiNatAffAmount + theOpp.Amount;
                }
               }

               else if(theOpp.Sharing_Code__c == 'R131' || (theOpp.Sharing_Code__c == 'K171' && (y2kCutoff <= theOpp.CloseDate)) ){
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                  natGenIncentive  = natGenIncentive +  theOpp.Amount;
                } else {
                  genIncentive  = genIncentive + theOpp.Amount;
                }
                // Changes for using Deposit Site for ZD: #67674
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){//&& theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('35') theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')
                    fcmiNatAffAmount = fcmiNatAffAmount + theOpp.Amount;
                }
               }

               else if(theOpp.Sharing_Code__c == 'R141'){
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                  natBenefit  = natBenefit +  theOpp.Amount;
                } else {
                  benefit = benefit + theOpp.Amount;
                }
                // Changes for using Deposit Site for ZD: #67674
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){//&& theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('35') {
                    fcmiNatAffAmount = fcmiNatAffAmount + theOpp.Amount;
                }
               }

               else if(theOpp.Sharing_Code__c == 'R151'){
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                  natSolEarmark  = natSolEarmark +  theOpp.Amount;
                } else {
                  solEarmark = solEarmark + theOpp.Amount;
                }
                // Changes for using Deposit Site for ZD: #67674
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){//&& theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('35') {
                    fcmiNatAffAmount = fcmiNatAffAmount + theOpp.Amount;
                }
              }

              else if(theOpp.Sharing_Code__c == 'R181'){
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                  natInKind   = natInKind +  theOpp.Amount;
                } else {
                  inKind = inKind + theOpp.Amount;
                }
                // Changes for using Deposit Site for ZD: #67674
                if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){//&& theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('35'){
                    fcmiNatAffAmount = fcmiNatAffAmount + theOpp.Amount;
                }
              }


    // Affiliate Banked Incentive Income
              else if((theOpp.Sharing_Code__c == 'R112' && (theOpp.CloseDate >= y2kCutoff))
                    || (theOpp.Sharing_Code__c == 'K171' && (theOpp.CloseDate < y2kCutoff)) ){
                //if(theOpp.Sharing_Entity_Affiliation__c == accAffiliationCode.subString(0,2)){
                if(theOpp.Deposit_Site__c != null && isDepositSiteSameAsAffiliate ){//Zendesk : #69266
                    affiliateBRI  = affiliateBRI + theOpp.Amount;
                    affiliateBRICount  = affiliateBRICount + 1;
                }
              }


    // Unshared Income
              else if(theOpp.Sharing_Code__c == 'K161'){
                  //if(theOpp.Sharing_Entity_Affiliation__c != accAffiliationCode.subString(0,2)){
                  if(theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('124')){ //if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                      natUnSolEarmark = natUnSolEarmark +  theOpp.Amount;
                  }
                  else {
                    unSolEarmark = unSolEarmark + theOpp.Amount;
                  }
                  if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.subString(0,2) == 'NA'){
                    natBanked = natBanked + theOpp.Amount;
                  } else if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.subString(0,2) != 'NA'){
                    affBanked = affBanked + theOpp.Amount;
                  }
              }
              else if(theOpp.Sharing_Code__c == 'K165'){
                  //if(theOpp.Sharing_Entity_Affiliation__c != accAffiliationCode.subString(0,2)){
                  if(theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('124')){ //if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                      natRecogGrant   = natRecogGrant +  theOpp.Amount;
                  }
                  else {
                     RecogGrant = RecogGrant + theOpp.Amount;
                  }
                  if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.subString(0,2) == 'NA'){
                    natBanked = natBanked + theOpp.Amount;
                  } else if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.subString(0,2) != 'NA'){
                    affBanked = affBanked + theOpp.Amount;
                  }
              }
              else if(theOpp.Sharing_Code__c == 'K171' && (y2kCutoff > theOpp.CloseDate) ){
                  //if(theOpp.Sharing_Entity_Affiliation__c != accAffiliationCode.subString(0,2)){
                  if(theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('124')){ //if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                      natMemorial  = natMemorial +  theOpp.Amount;
                  }
                  else {
                    memorial  = memorial + theOpp.Amount;
                  }
                  if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.subString(0,2) == 'NA'){
                    natBanked = natBanked + theOpp.Amount;
                  } else if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.subString(0,2) != 'NA'){
                    affBanked = affBanked + theOpp.Amount;
                  }
              }


              else if(theOpp.Sharing_Code__c == 'R191'){
                  //if(theOpp.Sharing_Entity_Affiliation__c != accAffiliationCode.subString(0,2)){
                  if(theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('124')){ //if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                      natSpecialSharing = natSpecialSharing +  theOpp.Amount;
                  }
                  else {
                    specialSharing = specialSharing + theOpp.Amount;
                  }
              }
              else if(theOpp.Sharing_Code__c == 'R192'){
                  //if(theOpp.Sharing_Entity_Affiliation__c != accAffiliationCode.subString(0,2)){
                  if(theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('124')){ //if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                      natEarlySharing = natEarlySharing +  theOpp.Amount;
                  }
                  else {
                    earlySharing   = earlySharing + theOpp.Amount;
                  }
              }
              else if(theOpp.Sharing_Code__c == 'T400'){
                  //if(theOpp.Sharing_Entity_Affiliation__c != accAffiliationCode.subString(0,2)){
                  if(theOpp.Program_Type__c != null && theOpp.Program_Type__c.containsAny('124')){ //if(theOpp.Deposit_Site__c != null && theOpp.Deposit_Site__c.startsWith('NA')){
                      natEndowment = natEndowment + theOpp.Amount;
                  }
                  else {
                    endowment = endowment + theOpp.Amount;
                  }
              }
            }
        }
     }

     global void finish(Database.BatchableContext Bc){
        Revenue_Sharing_Sytem_Controls__c revenueSharingControls;

        Affiliate_Yearly__c updatedYearlyAffiliate = new Affiliate_Yearly__c(Id = allAffiliateYearls[0]
                                                      , FCMI_NatDirectMailLess2500__c = natDirectMailLess.round()
                                                      , FCMI_NatDirectMailLess2500_Count__c = natDirectMailLessCount
                                                      , FCMI_NatWorkplace__c = natWorkplace.round()
                                                      , FCMI_NatDirectMailGreater2500__c = natDirectMailGreater2500.round()
                                                      , FCMI_NatAdvertising__c = natAdvertising.round()
                                                      , FCMI_NatGenIncentive__c = natGenIncentive.round()
                                                      , FCMI_NatBenefit__c = natBenefit.round()
                                                      , FCMI_NatSolEarmark__c = natSolEarmark.round()
                                                      , FCMI_NatInKind__c = natInKind.round()
                                                      , FCMI_AffiliateBRI__c = affiliateBRI.round()
                                                      , FCMI_AffiliateBRI_Count__c = affiliateBRICount
                                                      , FCMI_DirectMailGreater2500__c = directMailGreater2500.round()
                                                      , FCMI_Advertising__c = advertising.round()
                                                      , FCMI_GenIncentive__c = genIncentive.round()
                                                      , FCMI_Benefit__c = benefit.round()
                                                      , FCMI_SolEarmark__c = solEarmark.round()
                                                      , FCMI_InKind__c = InKind.round()
                                                      , FCMI_UnSolEarmark__c = unSolEarmark.round()
                                                      , FCMI_RecogGrant__c = recogGrant.round()
                                                      , FCMI_Memorial__c = memorial.round()
                                                      , FCMI_NatUnSolEarmark__c = natUnSolEarmarK.round()
                                                      , FCMI_NatRecogGrant__c = natRecogGrant.round()
                                                      , FCMI_NatMemorial__c = natMemorial.round()
                                                      , FCMI_SpecialSharing__c = specialSharing.round()
                                                      , FCMI_EarlySharing__c = earlySharing.round()
                                                      , FCMI_NatSpecialSharing__c = natSpecialSharing.round()
                                                      , FCMI_NatEarlySharing__c = natEarlySharing.round()
                                                      , FCMI_Endowment__c = endowment.round()
                                                      , FCMI_NatEndowment__c = natEndowment.round()
                                                      , FCMI_NatBanked__c = natBanked.round()
                                                      , FCMI_AffBanked__c = affBanked.round()
                                                      , FCMI_NatAffAmount__c = fcmiNatAffAmount.round()
                                                      );

        try {
            update updatedYearlyAffiliate;
            allAffiliateYearls.remove(0);

            if(!allAffiliateYearls.IsEmpty()){
                RevSharing_FCMICalculator batch = new RevSharing_FCMICalculator(new Set<Id>(allAffiliateYearls), reportType);
                Database.executeBatch(batch,2000);
            }
            else {

                revenueSharingControls= [SELECT Id, Report_Request_Owner_Email__c, Report_Request_Sender_Email__c FROM Revenue_Sharing_Sytem_Controls__c LIMIT 1];
                RevSharing_StageReportCalculations.sendEmail(reportType, revenueSharingControls.Report_Request_Sender_Email__c, revenueSharingControls.Report_Request_Owner_Email__c, fYear);

                //update the Custom Setting.
                update new Revenue_Sharing_Sytem_Controls__c(Id = revenueSharingControls.Id, Report_Request_Owner_Email__c = null,
                                                                Report_Request_In_Progress__c = false, Last_End_Run_DateTime__c = System.now());
                                                                /*Added field Last_End_Run_DateTim__c by Bhavesh for T-647039*/

            }

        }
        catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('RevSharing_FCMICalculator','finish',e.getMessage());
            log.logException(e);
            log.saveLogs();

            //update the Custom Setting.
            if( revenueSharingControls!= null ){
               update new Revenue_Sharing_Sytem_Controls__c(Id = revenueSharingControls.Id, Report_Request_In_Progress__c = false,
                                                            Last_Run_Details__c = 'Report Failed', Last_End_Run_DateTime__c = System.now());
                                                            /*Added field Last_End_Run_DateTim__c by Bhavesh for T-647039*/
            }
        }
     }
}