/*
*Name  :  RevSharing_IndemnificationActuals_Batch
*Author:  Appirio India (Sai Krishna )
*Date  :  December 25, 2016
*Purpose : Batch class to populate Affiliate_Actual_Indemnification_from_To__c and National_Actual_Indemnification_Today__c on 
*          Affiliate Yearly records by calculating amount from related opportunities. Invoked from Calculate Revenue Sharing button on Affiliate Yearly.
*
*/
global with sharing class RevSharing_IndemnificationActuals_Batch implements Database.Batchable<sObject>,Database.stateful{
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static final String OPPORTUNITY_RT_SOFT_CREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    private static Set<String> setOfRequiredCodes;
    private String reportType;
    static {
        setOfRequiredCodes = new Set<String> {'R112', 'R131', 'R113', 'R141', 'R151', 'R181', 'K171'};
    }

    public Id affiliateYearly;
    public String fiscalYear ;
    public Decimal affiliateTotal =0.00;
    public Decimal nationalTotal =0.00;
    public String accAffiliationCode;
    //public Boolean isPerformCMICalculation = false;
    public Set<Id> allAffiliateYearls;

    global RevSharing_IndemnificationActuals_Batch(Set<Id> affiliateYearlyIds, String reportType) {
        //isPerformCMICalculation = CMI_calculation;
        allAffiliateYearls = new Set<Id> (affiliateYearlyIds);
        Id  affiliateYearlyId = new List<Id>(affiliateYearlyIds)[0];
        Affiliate_Yearly__c obj = [SELECT Id, Fiscal_Year__c, Account__r.Affiliation__c
                                   FROM Affiliate_Yearly__c
                                   WHERE Id = : affiliateYearlyId];
        this.accAffiliationCode = obj.Account__r.Affiliation__c;
        this.affiliateYearly = obj.Id;
        this.fiscalYear = obj.Fiscal_Year__c;
        this.reportType = reportType != null ? reportType : '';
    }

    global Database.QueryLocator start(Database.BatchableContext Bc ){
        String accStartswith2Chars = accAffiliationCode.subString(0,2) + '%';
        Set<String> setOfValidRecordTypes = new Set<String> { OPPORTUNITY_RT_TRANSACTION_Id, OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, OPPORTUNITY_RT_SOFT_CREDIT_Id };
        return Database.getQueryLocator([SELECT Id, Amount, Deposit_Site__c, account.Affiliation__c, RecordTypeId, Sharing_Entity__c
                                     FROM Opportunity
                                     WHERE Sharing_Code__c IN : setOfRequiredCodes
                                     AND CloseDate  = TODAY
                                     AND RecordTypeId IN : setOfValidRecordTypes
                                     AND stageName = 'Completed'
                                     AND ( Deposit_Site__c LIKE: accStartswith2Chars OR Deposit_Site__c LIKE 'NA%' OR Sharing_Entity__c LIKE: accStartswith2Chars)
                                    ]);

    }

    global void execute(Database.BatchableContext Bc, List<Opportunity> scope){
        // Batch runs if the fiscalYear of the affiliateYearly record is the Current Year then Batch Runs Else not
        if(fiscalYear == String.valueOf(Date.today().Year()) && accAffiliationCode != null){
            for(Opportunity theOpp : scope){
                if(String.ValueOf(theOpp.Deposit_Site__c) != null && String.ValueOf(theOpp.Sharing_Entity__c) != null && String.ValueOf(theOpp.Deposit_Site__c).StartsWith('NA') && String.ValueOf(theOpp.Sharing_Entity__c).StartsWith(accAffiliationCode.subString(0,2))){
                    nationalTotal = nationalTotal +  theOpp.amount;
                }
                else if(String.ValueOf(theOpp.Sharing_Entity__c) != null && String.ValueOf(theOpp.Sharing_Entity__c).StartsWith(accAffiliationCode.subString(0,2))){
                    affiliateTotal = affiliateTotal + theOpp.amount;
                }
            }
        }
    }

    global void finish(Database.BatchableContext Bc){
        List<Affiliate_Yearly__c> affs = new List<Affiliate_Yearly__c>();
        // Either affiliateYearlyId or the Fiscal Year will be present based on that will update single/ all the affiliateYearly records

        if(affiliateYearly != null && fiscalYear == String.valueOf(Date.today().Year())){
            affs.add( new Affiliate_Yearly__c(Id = affiliateYearly, Affiliate_Actual_Indemnification_from_To__c = affiliateTotal, National_Actual_Indemnification_Today__c  = nationalTotal, National_Actual_Indemnification_for_day__c = DateTime.Now(), Affiliate_Actual_Indemnification_for_day__c = DateTime.Now()));
        }

        try {
          update affs;
          //if(!isPerformCMICalculation){
          RevSharing_Calc_Batch batch = new RevSharing_Calc_Batch(affiliateYearly);
          Database.executeBatch(batch,50);

        }
        catch(Exception e) {
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('RevSharing_IndemnificationActuals_Batch','updateIndemnificationTotal',e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
    }

    /*
    *Method updateIndemnificationTotal (webService)
    *@param : affiliateYearlyId
    *@description : Triggers the Batch class which perfoms the Indemnification calculation.
    */
    webservice static Boolean updateIndemnificationTotal(Id affiliateYearlyId) {
        try {
           RevSharing_IndemnificationActuals_Batch batch = new RevSharing_IndemnificationActuals_Batch(new Set<Id> {affiliateYearlyId}, null);
           Database.executeBatch(batch,200);
           return true;
         }
         catch(Exception e) {
           return false;
         }
         return true;
    }

}