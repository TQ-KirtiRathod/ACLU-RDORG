/*
*
*Name  :  IncomeTypeDistributionTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  January 23, 2016
*Purpose : Handler Class for Income Type Distribution Trigger
            Logic includes but not limited to
            - Income Type Distribution Rollups to Affiliate Yearly record
*/

public with sharing class IncomeTypeDistributionTriggerHandler {
    private static final String UNSOLICITED_ANNUAL_MEGA = 'Unsolicited Earmarked Annual Mega Incentive';
    private static final String UNRESTRICTED_ANNUAL_MEGA = 'Unrestricted Annual Mega Incentive';
    private static final String MULTI_YEAR_MEGA = 'Multi-Year Mega-Gifts';
    private static final String SOLICITED_EARMARKED_ANNUAL_MEGA = 'Solicited Earmarked Annual Mega Incentive';
    private static final String ENDOWMENT_GIFTS = 'Endowment Gifts';
    private static final String ENDOWMENT_MEGA_GIFTS =  'Endowment Mega Gifts';
    private static final String CAMPAIGN_MEGA_INCENTIVE = 'Centennial Campaign Annual Mega Gift';

    private static final String BEQUEST_UNRESTRICTED_PLANNED = 'Unrestricted Bequest / Planned Gift';
    private static final String BEQUEST_EARMARKED = 'Earmarked Bequest';
    private static final String BEQUEST_MEGA = 'Mega Bequest';

    private static final String MISC_AFFILIATE_COSTS = 'Misc Affiliate Costs';
/*
*
*Method mainEntry
*@description : defining all trigger events
*
*/
    public static void mainEntry(List<Income_Type_Distribution__c > newList, List<Income_Type_Distribution__c> oldList, Map<Id, Income_Type_Distribution__c> newMap, Map<Id, Income_Type_Distribution__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('IncomeTypeDistribution_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {

            // It is called on after insert and update
            if(isAfter){
                if(isInsert){
                    onAfterInsert(newList);
                }

                if(isUpdate){
                    onAfterUpdate(oldMap, newMap);
                }

                if(isDelete) {
                    onAfterDelete(oldList);
                }

                if(isUndelete) {
                    onAfterUndelete(newList);
                }
            }
            
            if(isBefore) {
                if(isDelete) {
                    onBeforeDelete(oldList);
                }
            }
        }
    }

    /*
    *
    *Method beforeDelete
    *@param : newLst
    *@description : calls on beforeDelete
    *
    */
    public static void onBeforeDelete(List<Income_Type_Distribution__c> oldList) {
        set<Id> affiliateYearlyIdSet = new set<Id>();
        for(Income_Type_Distribution__c income : oldList) {
            affiliateYearlyIdSet.add(income.Affiliate_Yearly__c);
        }
        map<Id, Affiliate_Yearly__c> affiliateYearlyMap = new map<Id, Affiliate_Yearly__c>([SELECT Id, Reconciled_and_Locked__c FROM Affiliate_Yearly__c
                                                            WHERE Id IN :affiliateYearlyIdSet]);
        for(Income_Type_Distribution__c inc : oldList) {
            if(affiliateYearlyMap.get(inc.Affiliate_Yearly__c).Reconciled_and_Locked__c) {
                inc.addError('Reconciled and Locked must be False for selected Affiliate Yearly record.');
            }
        }
    }
    
    /*
    *
    *Method afterInsert
    *@param : newLst
    *@description : calls on afterInsert
    *
    */
    public static void onAfterInsert(List<Income_Type_Distribution__c> newList) {
        List<Income_Type_Distribution__c> incomeTypeDistributions = new List<Income_Type_Distribution__c> ();
        for(Income_Type_Distribution__c incD: newList){
            if(incD.Amount__c != null && (incD.Income_Type__c != null)){
                incomeTypeDistributions.add(incD);
            }
        }

        if(!incomeTypeDistributions.isEmpty()){
            // UnRestricted Annual Mega Incentive
            list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', '  Amount__c','Unrestricted_Annual_Mega_Incentive__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNRESTRICTED_ANNUAL_MEGA+'\' ');

            // ​Unsolicited Earmarked Annual Mega Incentive
            list<RSFUtility.fieldDefinition> fieldDefinitions1 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unsolicited_Earmarked_Annual_Mega__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions1, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNSOLICITED_ANNUAL_MEGA+'\' ');

            // Multi-Year Mega-Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions2 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Multi_Year_Mega_Incentive_Income__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions2, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MULTI_YEAR_MEGA+'\' ');

            // Solicited Earmarked Annual Mega Incentive
            list<RSFUtility.fieldDefinition> fieldDefinitions3 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Solicited_Earmarked_Annual_MegaIncentive__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions3, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ SOLICITED_EARMARKED_ANNUAL_MEGA+'\' ');

            // Endowment Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions4 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Gifts__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions4, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_GIFTS+'\' ');

            // Endowment Mega Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions5 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Mega_Gifts__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions5, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_MEGA_GIFTS+'\' ');

            // Campaign Mega Incentive Income above 2M
            list<RSFUtility.fieldDefinition> fieldDefinitions6 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Campaign_Mega_Incentive_Income_Above_2M__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions6, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ CAMPAIGN_MEGA_INCENTIVE+'\' ');

            // BEQUEST_MEGA Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions7 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Mega_Bequest_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions7, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_MEGA+'\' ');

            // BEQUEST_EARMARKED Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions8 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Earmarked_Bequest_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions8, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_EARMARKED+'\' ');

            // BEQUEST_UNRESTRICTED_PLANNED Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions9 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unrestricted_Bequest_Planned_Gift_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions9, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_UNRESTRICTED_PLANNED+'\' ');

            // Misc Affiliate Costs
            list<RSFUtility.fieldDefinition> fieldDefinitions10 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Misc_Affiliate_Costs_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions10, incomeTypeDistributions, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MISC_AFFILIATE_COSTS+'\' ');

        }
    }

    /*
    *
    *Method afterUpdate
    *@param : oldMap, newMap
    *@description : calls on afterUpdate
    *
    */
    public static void onAfterUpdate(Map<Id,Income_Type_Distribution__c> oldMap, Map<Id,Income_Type_Distribution__c> newMap) {
        List<Income_Type_Distribution__c> newList = new List<Income_Type_Distribution__c> ();
        for(Income_Type_Distribution__c incD: newMap.Values()){
            if(oldMap.get(incD.Id).Amount__c != incD.Amount__c || oldMap.get(incD.Id).Income_Type__c != incD.Income_Type__c){
                newList.add(incD);
            }
        }

        if(!newList.isEmpty()){
            // UnRestricted Annual Mega Incentive
            list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', '  Amount__c','Unrestricted_Annual_Mega_Incentive__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNRESTRICTED_ANNUAL_MEGA+'\' ');

            // ​Unsolicited Earmarked Annual Mega Incentive
            list<RSFUtility.fieldDefinition> fieldDefinitions1 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unsolicited_Earmarked_Annual_Mega__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions1, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNSOLICITED_ANNUAL_MEGA+'\' ');

            // Multi-Year Mega-Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions2 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Multi_Year_Mega_Incentive_Income__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions2, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MULTI_YEAR_MEGA+'\' ');

            // Solicited Earmarked Annual Mega Incentive
            list<RSFUtility.fieldDefinition> fieldDefinitions3 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Solicited_Earmarked_Annual_MegaIncentive__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions3, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ SOLICITED_EARMARKED_ANNUAL_MEGA+'\' ');

            // Endowment Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions4 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Gifts__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions4, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_GIFTS+'\' ');

            // Endowment Mega Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions5 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Mega_Gifts__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions5, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_MEGA_GIFTS+'\' ');

            // Campaign Mega Incentive Income above 2M
            list<RSFUtility.fieldDefinition> fieldDefinitions6 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Campaign_Mega_Incentive_Income_Above_2M__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions6, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ CAMPAIGN_MEGA_INCENTIVE+'\' ');

            // BEQUEST_MEGA Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions7 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Mega_Bequest_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions7, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_MEGA+'\' ');

            // BEQUEST_EARMARKED Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions8 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Earmarked_Bequest_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions8, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_EARMARKED+'\' ');

            // BEQUEST_UNRESTRICTED_PLANNED Gifts
            list<RSFUtility.fieldDefinition> fieldDefinitions9 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unrestricted_Bequest_Planned_Gift_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions9, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_UNRESTRICTED_PLANNED+'\' ');

            // Misc Affiliate Costs
            list<RSFUtility.fieldDefinition> fieldDefinitions10 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Misc_Affiliate_Costs_Total__c')};
            RSFUtility.rollUpTrigger(fieldDefinitions10, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MISC_AFFILIATE_COSTS+'\' ');

        }
    }

    /*
    *
    *Method afterDelete
    *@param : oldList
    *@description : calls on afterDelete
    *
    */
    public static void onAfterDelete(List<Income_Type_Distribution__c> oldList) {
        // UnRestricted Annual Mega Incentive
        list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', '  Amount__c','Unrestricted_Annual_Mega_Incentive__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNRESTRICTED_ANNUAL_MEGA+'\' ');

        // ​Unsolicited Earmarked Annual Mega Incentive
        list<RSFUtility.fieldDefinition> fieldDefinitions1 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unsolicited_Earmarked_Annual_Mega__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions1, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNSOLICITED_ANNUAL_MEGA+'\' ');

        // Multi-Year Mega-Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions2 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Multi_Year_Mega_Incentive_Income__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions2, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MULTI_YEAR_MEGA+'\' ');

        // Solicited Earmarked Annual Mega Incentive
        list<RSFUtility.fieldDefinition> fieldDefinitions3 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Solicited_Earmarked_Annual_MegaIncentive__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions3, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ SOLICITED_EARMARKED_ANNUAL_MEGA+'\' ');

        // Endowment Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions4 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Gifts__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions4, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_GIFTS+'\' ');

        // Endowment Mega Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions5 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Mega_Gifts__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions5, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_MEGA_GIFTS+'\' ');

        // Campaign Mega Incentive Income above 2M
        list<RSFUtility.fieldDefinition> fieldDefinitions6 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Campaign_Mega_Incentive_Income_Above_2M__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions6, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ CAMPAIGN_MEGA_INCENTIVE+'\' ');

        // BEQUEST_MEGA Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions7 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Mega_Bequest_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions7, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_MEGA+'\' ');

        // BEQUEST_EARMARKED Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions8 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Earmarked_Bequest_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions8, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_EARMARKED+'\' ');

        // BEQUEST_UNRESTRICTED_PLANNED Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions9 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unrestricted_Bequest_Planned_Gift_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions9, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_UNRESTRICTED_PLANNED+'\' ');

        // Misc Affiliate Costs
        list<RSFUtility.fieldDefinition> fieldDefinitions10 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Misc_Affiliate_Costs_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions10, oldList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MISC_AFFILIATE_COSTS+'\' ');

    }

    /*
    *
    *Method afterUnDelete
    *@param : newList
    *@description : calls on afterUnDelete
    *
    */
    public static void onAfterUndelete(List<Income_Type_Distribution__c> newList) {
        // UnRestricted Annual Mega Incentive
        list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', '  Amount__c','Unrestricted_Annual_Mega_Incentive__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNRESTRICTED_ANNUAL_MEGA+'\' ');

        // ​Unsolicited Earmarked Annual Mega Incentive
        list<RSFUtility.fieldDefinition> fieldDefinitions1 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unsolicited_Earmarked_Annual_Mega__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions1, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ UNSOLICITED_ANNUAL_MEGA+'\' ');

        // Multi-Year Mega-Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions2 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Multi_Year_Mega_Incentive_Income__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions2, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MULTI_YEAR_MEGA+'\' ');

        // Solicited Earmarked Annual Mega Incentive
        list<RSFUtility.fieldDefinition> fieldDefinitions3 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Solicited_Earmarked_Annual_MegaIncentive__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions3, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ SOLICITED_EARMARKED_ANNUAL_MEGA+'\' ');

        // Endowment Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions4 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Gifts__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions4, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_GIFTS+'\' ');

        // Endowment Mega Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions5 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Endowment_Mega_Gifts__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions5, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ ENDOWMENT_MEGA_GIFTS+'\' ');

        // Campaign Mega Incentive Income above 2M
        list<RSFUtility.fieldDefinition> fieldDefinitions6 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Campaign_Mega_Incentive_Income_Above_2M__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions6, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ CAMPAIGN_MEGA_INCENTIVE+'\' ');

        // BEQUEST_MEGA Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions7 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Mega_Bequest_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions7, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_MEGA+'\' ');

        // BEQUEST_EARMARKED Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions8 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Earmarked_Bequest_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions8, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_EARMARKED+'\' ');

        // BEQUEST_UNRESTRICTED_PLANNED Gifts
        list<RSFUtility.fieldDefinition> fieldDefinitions9 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Unrestricted_Bequest_Planned_Gift_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions9, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ BEQUEST_UNRESTRICTED_PLANNED+'\' ');

        // Misc Affiliate Costs
        list<RSFUtility.fieldDefinition> fieldDefinitions10 = new list<RSFUtility.fieldDefinition> {new RSFUtility.fieldDefinition ('SUM', ' Amount__c','Misc_Affiliate_Costs_Total__c')};
        RSFUtility.rollUpTrigger(fieldDefinitions10, newList, 'Income_Type_Distribution__c', 'Affiliate_Yearly__c', 'Affiliate_Yearly__c', ' AND Income_Type__c =\''+ MISC_AFFILIATE_COSTS+'\' ');

    }
}