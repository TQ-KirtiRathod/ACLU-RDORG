/*
*Name  :  Recalculate_Opps_Cost_Factor_Batch
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  August 08, 2017
*Purpose : Batch Class to Calculate Cost factor fields on Opportunity from Campaign
*          Run by button on Campaign Recalc_Opps_Cost_Factor
*
*/
global class Recalculate_Opps_Cost_Factor_Batch implements Database.Batchable<sObject>,Database.stateful {
    global Id campaignId;
    global Campaign campaignRec;
    public static Id transactionOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    public static Id pledgePaymentOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    
    global Recalculate_Opps_Cost_Factor_Batch(Id cmpId) {
        campaignId = cmpId;
        campaignRec = [SELECT rC_Giving__Source_Code__c, Exclude_Cost_Factors_in_RevShare__c,
                                        ActualCost, AmountAllOpportunities, Actual_Cost_Factor__c
                                        FROM Campaign WHERE Id = :cmpId];
    }
    global Database.QueryLocator start(Database.BatchableContext Bc ){
        return Database.getQueryLocator([SELECT Id, Name, Exclude_Cost_Factors_in_RevShare__c, rC_Giving__Source_Code__c 
                                            FROM Opportunity
                                            WHERE rC_Giving__Source_Code__c =: campaignRec.rC_Giving__Source_Code__c
                                            AND (recordTypeId =: transactionOppRecordTypeId OR recordTypeId =: pledgePaymentOppRecordTypeId)
                                            ]);
    }
    
    global void execute(Database.BatchableContext Bc, List<Opportunity> opptyList){
        //list<Opportunity> oppsToUpdate
        for(Opportunity opp : opptyList) {
            opp.Exclude_Cost_Factors_in_RevShare__c = campaignRec.Exclude_Cost_Factors_in_RevShare__c;
            opp.Cost_Factor__c = campaignRec.Actual_Cost_Factor__c;
            opp.Recalculate_Revenue_Share__c = true;
        }
        
        if(!opptyList.isEmpty()) {
            try{
                update opptyList;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('Recalculate_Opps_Cost_Factor_Batch','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    global void finish(Database.BatchableContext Bc){
    }
    
    /*
    *Method updateCostFactor (webService)
    *@param : campaignId
    *@description : Triggers the Batch class which perfoms the Cost Factor calculation.
    */
    webservice static Boolean updateCostFactor(Id campaignId) {
    	Boolean hasAccess = false;
    	set<Id> publicGroupIds = new set<Id>();
        system.debug(campaignId);
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        if(p.Id != userInfo.getProfileId()) {
	        list<CampaignShare> campaignShareRec = [SELECT Id, UserOrGroupId FROM CampaignShare WHERE CampaignId = :campaignId 
	                                                                                    AND (CampaignAccessLevel = 'Edit'
	                                                                                    OR CampaignAccessLevel = 'All')];
	        system.debug(campaignShareRec);
	        for(CampaignShare cs : campaignShareRec) {
	        	if(String.valueOf(cs.UserOrGroupId).startsWith('005') && cs.UserOrGroupId == userInfo.getUserId()) {
	        		hasAccess = true;
	        		break;
	        	}
	        	if(String.valueOf(cs.UserOrGroupId).startsWith('00G')) {
	        		publicGroupIds.add(cs.UserOrGroupId);
	        	}
	        }
	        if(hasAccess == false && !publicGroupIds.isEmpty()) {
	        	for(GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN :publicGroupIds]) {
	        		if(gm.UserOrGroupId == userInfo.getUserId()) {
	        			hasAccess = true;
	        			break;
	        		}
	        	}
	        }
        } else {
        	hasAccess = true;
        }
        if(hasAccess == false)  return false;
        try {
           Recalculate_Opps_Cost_Factor_Batch batch = new Recalculate_Opps_Cost_Factor_Batch(campaignId);
           Database.executeBatch(batch,50);
           return true;
         }
         catch(Exception e) {
           return false;
         }
         return true;
    }
}