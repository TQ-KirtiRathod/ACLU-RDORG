/*
*
*Name  :  OpportunityCampaignManager
*Author:  Appirio India (Harshita)
*Date  :  Jan 11, 2017
*Purpose : Contains static methods related to Campaign and Opportunity. Used as a helper for OpportunityTriggerHandler
*
*Change Log : Oct 2017 - GH-38 - Not all campaign fields being set on adjustment for Donation, Transaction (D)
							   - Note three commented-out methods; attempt to refactor for cleaner code, but resulting errors
                                 and time constraints led those to remain as future TO-DO items
*Chnage Log: Traction(Mounica V)  BGE-22, 12/2/2019 : Commented the call to flagMembershipShareCodeReset method                                
*/
public class OpportunityCampaignManager {
    private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static final String OPPORTUNITY_RT_TRANSACTION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_Id;
    private static final String OPPORTUNITY_RT_DONATION_Id;
    public static Set<Id> shareCodeLogicProcessedSet;
    public static Map<String,Campaign> mapOfCampaignIdVsCampaign;
    public static List<Opportunity> listOfOpps;
    public static List<Opportunity> listOfOppsToInsert;
    private static Boolean isInsert;
        
    static {
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        shareCodeLogicProcessedSet = new Set<Id>();
        mapOfCampaignIdVsCampaign = new Map<String,Campaign>();
        listOfOpps = new List<Opportunity>();
        listOfOppsToInsert = new List<Opportunity>();
    }
    
        public static void copyCampaignFieldsAndPopulateSharingFields(List<opportunity> listOfOppsToProcess, Set<String> campaignIds, boolean isInsert, Map<Id, Opportunity> oldMap) {
        	Map<String,Campaign> mapOfCampaignIdVsCampaign = new Map<String,Campaign>();
       		List<Opportunity> listOfOpps = new List<Opportunity>();
        	List<Opportunity> listOfOppsToInsert = new List<Opportunity>();
            if(campaignIds != null) {
                for(Campaign theCampaign : [SELECT Id, rC_Giving__GAU__r.Name, Restriction__c, Actual_Cost_Factor__c, Use_Campaign_Cost__c,
                                            rC_Giving__Source_Code__c,Account_Code__c,Fund__c, Fundraising_Department__c, Package_Code__c,
                                            Exclude_Cost_Factors_in_RevShare__c, rC_Giving__Campaign_Type__c, rC_Giving__Sub_Affiliation__c,
                                            Acknowledgment_Code__c, Name, rC_Giving__Affiliation__c, rc_Giving__Channel__c
                                            FROM Campaign
                                            WHERE Id IN : campaignIds]) {
                                                mapOfCampaignIdVsCampaign.put(theCampaign.Id,theCampaign);  
                                            }
            }
            for(Opportunity opp : listOfOppsToProcess) {
                //Added per GH-38
                Opportunity oldOpp = (oldMap != null)
                                    ? oldMap.get(opp.Id)
                                    : opp;
                Boolean isCampaignChanged = (!isInsert) && (opp.Campaignid != oldOpp.Campaignid);
    
                // updateOppCampaignFields(opp, oldOpp, isCampaignChanged);  TO-DO: FUTURE REFACTOR OPPORTUNITY
             	String campaignId = opp.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id
                                  ? opp.CampaignIdText__c
                                  : opp.campaignId;

                // Populate Package Code From Campaign for All Opportunities
                opp.RPT_Package_Code__c = mapOfCampaignIdVsCampaign != null && mapOfCampaignIdVsCampaign.containsKey(campaignId)
                                                && mapOfCampaignIdVsCampaign.get(campaignId).Package_Code__c != null
                                            ? mapOfCampaignIdVsCampaign.get(campaignId).Package_Code__c
                                            : opp.RPT_Package_Code__c;
            
                // Populate Fundraising Department for Sustainer Pledges
                if((opp.RecordTypeId != OPPORTUNITY_RT_TRANSACTION_Id || opp.RecordTypeId != OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                    && (campaignId != null && mapOfCampaignIdVsCampaign.containsKey(campaignId) && mapOfCampaignIdVsCampaign.get(campaignId) != null 
                        && mapOfCampaignIdVsCampaign.get(campaignId).Fundraising_Department__c != null
                        && campaignId == opp.CampaignId)) {
                            opp.Fundraising_Department__c = mapOfCampaignIdVsCampaign.get(campaignId).Fundraising_Department__c;    
                }
                                    
                // Copy Campaign Fields from Campaign for All Opportunties
                if(campaignId != null && mapOfCampaignIdVsCampaign.get(campaignId) != null){
                    if(isInsert && opp.Restriction__c == null) {
                        opp.Restriction__c = (mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c != null)
                                        ? mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c
                                        : 'UNDEFINED - Undefined';
                    }
                    else if(!isInsert && (opp.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id)) {
                        opp.Restriction__c = mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c != null
                                            ? mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c
                                            : 'UNDEFINED - Undefined';
                                            
                    }
                    if(isInsert && opp.Acknowledgment_Code__c == null) {
                        opp.Acknowledgment_Code__c = mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c != null
                                                    ? mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c
                                                    : opp.Acknowledgment_Code__c;
                    }
                    else if((isCampaignChanged) && (opp.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id)
                                && (opp.rC_Giving__Acknowledged_Date__c == null) && (opp.Acknowledgment_Status__c != 'A - Acknowledged')) {
                        opp.Acknowledgment_Code__c = mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c != null
                                                    ? mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c
                                                    : opp.Acknowledgment_Code__c;
                                            
                    }
                    // copying the first Letter from camapign.rC_Giving__Sub_Affiliation__c to opportunity.Program_Type__c
                    if(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Sub_Affiliation__c != null) {
                        opp.Program_Type__c = String.ValueOf(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Sub_Affiliation__c).Substring(0,1);
                    }
                    // copying the first Letter from camapign.rC_Giving__Campaign_Type__c to opportunity.Campaign_Type__c            
                    if(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Campaign_Type__c != null) {
                        opp.Campaign_Type__c = String.ValueOf(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Campaign_Type__c).Substring(0,1);
                    }            
                    
                    opp.Exclude_Cost_Factors_in_RevShare__c = mapOfCampaignIdVsCampaign.get(campaignId).Exclude_Cost_Factors_in_RevShare__c;
                    opp.Use_Campaign_Cost__c = mapOfCampaignIdVsCampaign.get(campaignId).Use_Campaign_Cost__c;
                    opp.Cost_Factor__c = mapOfCampaignIdVsCampaign.get(campaignId).Actual_Cost_Factor__c;
                    
                    //Added per GH-38
                    opp.rc_Giving__Affiliation__c = (String.ISBlank(opp.rc_Giving__Affiliation__c) || isCampaignChanged)
                                        ? mapOfCampaignIdVsCampaign.get(campaignId).rc_Giving__Affiliation__c: opp.rc_Giving__Affiliation__c;
                    opp.rc_Giving__Campaign_Channel__c = (String.ISBlank(opp.rc_Giving__Campaign_Channel__c) || isCampaignChanged)
                                        ? mapOfCampaignIdVsCampaign.get(campaignId).rc_Giving__Channel__c: opp.rc_Giving__Campaign_Channel__c;
        
                    //Fund Fields
                    opp.Fund__c = (String.ISBlank(opp.Fund__c) || isCampaignChanged)
                                        ? mapOfCampaignIdVsCampaign.get(campaignId).Fund__c: opp.Fund__c;
                    opp.Fundraising_Department__c = (String.ISBlank(opp.Fundraising_Department__c))
                                                    ? mapOfCampaignIdVsCampaign.get(campaignId).Fundraising_Department__c
                                                    : opp.Fundraising_Department__c ;
                    opp.Account_Code__c = (String.ISBlank(opp.Account_Code__c) || isCampaignChanged)
                                        ? mapOfCampaignIdVsCampaign.get(campaignId).Account_Code__c
                                        : opp.Account_Code__c;
        
                    //Populate Rpt_Campaign_Name__c  on the basis of CampaignIdText__c on child - I-322221
                    if(opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) {
                        opp.Rpt_Campaign_Name__c = mapOfCampaignIdVsCampaign.get(campaignId).Name;
                    }
       		    }
                // populateListOfOpps(opp); TO-DO: Future refactor opportunity
                // Populate the ListOfOpportunities to pass to the method SetShareCode, it will include Pledge Payments and Transactions and
                // also the Parent Donation and Parent Pledge of Pledge Payments and Transactions.
                if((opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) && (opp.stageName == 'Completed') && (opp.Manual_Sharing_Code__c == False) 
                   && (opp.Program_Type__c != Null) && (opp.accountId != Null) && (opp.Isclosed == True) && (((!isInsert) && (!opp.Exclude_from_Revenue_Sharing__c)) || (isInsert))) {
                       listOfOpps.add(opp); 
                       shareCodeLogicProcessedSet.add(opp.Id);
                       if(opp.rC_Giving__External_Id__c != 'Flagged for MembershipShareCode Reset') {
                           listOfOppsToInsert.add(opp);
                       }
                } 
                //  setShareCodes(listOfOpps);  TO-DO: Future refactor opportunity
                if(!listOfOpps.isEmpty()) {
                    if(oldMap != null && listOfOpps.size() > 0) { // Opportunity Update Scenario
                      /* Traction(Mounica V): BGE-22, 12/2/2019 : Removing the logic to flag a batch to 'Membership and Revenue Sharing Resets Needed' 
                          listOfOpps = RevenueSharingShareCodes.flagMembershipShareCodeReset(listOfOpps, oldMap);*/
                            RevenueSharingShareCodes.setShareCode(listOfOpps);
                       
                    } else if(oldMap == null && listOfOppsToInsert.size() > 0) { // Opportunity Insert Scenario
                        RevenueSharingShareCodes.setShareCode(listOfOppsToInsert);
                    }    
                }
        }
    }

   /* private static void updateOppCampaignFields(Opportunity opp, Opportunity oldOpp, Boolean isCampaignChanged) {
        String campaignId = opp.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id
                              ? opp.CampaignIdText__c
                              : opp.campaignId;

        // Populate Package Code From Campaign for All Opportunities
        opp.RPT_Package_Code__c = mapOfCampaignIdVsCampaign != null && mapOfCampaignIdVsCampaign.containsKey(campaignId)
                                        && mapOfCampaignIdVsCampaign.get(campaignId).Package_Code__c != null
                                    ? mapOfCampaignIdVsCampaign.get(campaignId).Package_Code__c
                                    : opp.RPT_Package_Code__c;
            
        // Populate Fundraising Department for Sustainer Pledges
        if((opp.RecordTypeId != OPPORTUNITY_RT_TRANSACTION_Id || opp.RecordTypeId != OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
            && (campaignId != null && mapOfCampaignIdVsCampaign.containsKey(campaignId) && mapOfCampaignIdVsCampaign.get(campaignId) != null 
                && mapOfCampaignIdVsCampaign.get(campaignId).Fundraising_Department__c != null
                && campaignId == opp.CampaignId)) {
                    opp.Fundraising_Department__c = mapOfCampaignIdVsCampaign.get(campaignId).Fundraising_Department__c;    
        }
                            
        // Copy Campaign Fields from Campaign for All Opportunties
        if(campaignId != null && mapOfCampaignIdVsCampaign.get(campaignId) != null){
            if(isInsert && opp.Restriction__c == null) {
                opp.Restriction__c = (mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c != null)
                                ? mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c
                                : 'UNDEFINED - Undefined';
            }
            else if(!isInsert && (opp.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id)) {
                opp.Restriction__c = mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c != null
                                    ? mapOfCampaignIdVsCampaign.get(campaignId).Restriction__c
                                    : 'UNDEFINED - Undefined';
                                    
            }
            if(isInsert && opp.Acknowledgment_Code__c == null) {
                opp.Acknowledgment_Code__c = mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c != null
                                            ? mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c
                                            : opp.Acknowledgment_Code__c;
            }
            else if((isCampaignChanged) && (opp.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id)
                        && (opp.rC_Giving__Acknowledged_Date__c == null) && (opp.Acknowledgment_Status__c != 'A - Acknowledged')) {
                opp.Acknowledgment_Code__c = mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c != null
                                            ? mapOfCampaignIdVsCampaign.get(campaignId).Acknowledgment_Code__c
                                            : opp.Acknowledgment_Code__c;
                                    
            }
            // copying the first Letter from camapign.rC_Giving__Sub_Affiliation__c to opportunity.Program_Type__c
            if(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Sub_Affiliation__c != null) {
                opp.Program_Type__c = String.ValueOf(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Sub_Affiliation__c).Substring(0,1);
            }
            // copying the first Letter from camapign.rC_Giving__Campaign_Type__c to opportunity.Campaign_Type__c            
            if(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Campaign_Type__c != null) {
                opp.Campaign_Type__c = String.ValueOf(mapOfCampaignIdVsCampaign.get(campaignId).rC_Giving__Campaign_Type__c).Substring(0,1);
            }            
            
            opp.Exclude_Cost_Factors_in_RevShare__c = mapOfCampaignIdVsCampaign.get(campaignId).Exclude_Cost_Factors_in_RevShare__c;
            opp.Use_Campaign_Cost__c = mapOfCampaignIdVsCampaign.get(campaignId).Use_Campaign_Cost__c;
            opp.Cost_Factor__c = mapOfCampaignIdVsCampaign.get(campaignId).Actual_Cost_Factor__c;
            
            //Added per GH-38
            opp.rc_Giving__Affiliation__c = (String.ISBlank(opp.rc_Giving__Affiliation__c) || isCampaignChanged)
                                ? mapOfCampaignIdVsCampaign.get(campaignId).rc_Giving__Affiliation__c: opp.rc_Giving__Affiliation__c;
            opp.rc_Giving__Campaign_Channel__c = (String.ISBlank(opp.rc_Giving__Campaign_Channel__c) || isCampaignChanged)
                                ? mapOfCampaignIdVsCampaign.get(campaignId).rc_Giving__Channel__c: opp.rc_Giving__Campaign_Channel__c;

            //Fund Fields
            opp.Fund__c = (String.ISBlank(opp.Fund__c) || isCampaignChanged)
                                ? mapOfCampaignIdVsCampaign.get(campaignId).Fund__c: opp.Fund__c;
            opp.Fundraising_Department__c = (String.ISBlank(opp.Fundraising_Department__c))
                                            ? mapOfCampaignIdVsCampaign.get(campaignId).Fundraising_Department__c
                                            : opp.Fundraising_Department__c ;
            opp.Account_Code__c = (String.ISBlank(opp.Account_Code__c) || isCampaignChanged)
                                ? mapOfCampaignIdVsCampaign.get(campaignId).Account_Code__c
                                : opp.Account_Code__c;

            //Populate Rpt_Campaign_Name__c  on the basis of CampaignIdText__c on child - I-322221
            if(opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) {
                opp.Rpt_Campaign_Name__c = mapOfCampaignIdVsCampaign.get(campaignId).Name;
            }
        }
    }

    private static void populateListOfOpps(Opportunity opp) {
        // Populate the ListOfOpportunities to pass to the method SetShareCode, it will include Pledge Payments and Transactions and
        // also the Parent Donation and Parent Pledge of Pledge Payments and Transactions.
        if((opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) && (opp.stageName == 'Completed') && (opp.Manual_Sharing_Code__c == False) 
            && (opp.Program_Type__c != Null) && (opp.accountId != Null) && (opp.Isclosed == True) && (((!isInsert) && (!opp.Exclude_from_Revenue_Sharing__c)) || (isInsert))) {
            listOfOpps.add(opp); 
            shareCodeLogicProcessedSet.add(opp.Id);
            if(opp.rC_Giving__External_Id__c != 'Flagged for MembershipShareCode Reset') {
                listOfOppsToInsert.add(opp);
            }
        } 
    }

    private static void setShareCodes(List<Opportunity> listOfOpps) {
        // Call SetShareCode method
        if(!listOfOpps.isEmpty()) {
            if(oldMap != null && listOfOpps.size() > 0) { // Opportunity Update Scenario
                listOfOpps = RevenueSharingShareCodes.flagMembershipShareCodeReset(listOfOpps, oldMap);
                if(listOfOpps.size() > 0) {
                    RevenueSharingShareCodes.setShareCode(listOfOpps);
                }
            } else if(oldMap == null && listOfOppsToInsert.size() > 0) { // Opportunity Insert Scenario
                RevenueSharingShareCodes.setShareCode(listOfOppsToInsert);
            }    
        }
    }
*/

}