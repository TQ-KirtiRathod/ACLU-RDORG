/*
*
*Name  :  SkewFinder_Batch
*Author:  Appirio India (Sai )
*Date  :  May 24, 2017
*Purpose : Finds all the Campaigns whose Opportunities Count greater than Threshold
*          creates incremented Campaign preventing data skew issues
*
*/

global class CampaignSkewFinder_Batch implements Database.Batchable<sObject>,Database.stateful {
    public campaign_skew_control__c campaignSkewCs;
    public Integer thresholdLimit;
    public Set<Id> campaingIdsToClone;
    public List<String> setOfExcludedChannels ;
    global CampaignSkewFinder_Batch (){
         campaingIdsToClone = new Set<Id>();
         campaignSkewCs = new campaign_skew_control__c();
         setOfExcludedChannels = new List<String>();  
         thresholdLimit = 0;
         //Get the Custom Setting records to get the Threshold limit
         campaignSkewCs = (campaign_skew_control__c.getInstance('Default') != null) ? campaign_skew_control__c.getValues('Default') : null ;
        if(campaignSkewCs != null && campaignSkewCs.Threshold_for_Skew_Reduction__c != null){
             thresholdLimit = Integer.ValueOf(campaignSkewCs.Threshold_for_Skew_Reduction__c);
             setOfExcludedChannels = (campaignSkewCs.CSV_of_Excluded_Channels__c != null) ? String.ValueOf(campaignSkewCs.CSV_of_Excluded_Channels__c).Split('|') : null; 
         }
    }
    
    //Start Method
    global Database.QueryLocator start(Database.BatchableContext Bc ){
        return Database.getQueryLocator('SELECT Id,NumberOfOpportunities FROM Campaign WHERE IsActive = true AND NumberOfOpportunities >=:thresholdLimit AND Is_Overflow_Campaign__c = false AND rC_Giving__Channel__c NOT IN : setOfExcludedChannels');
    }
    
    //Execute Method
    global void execute(Database.BatchableContext Bc, List<Campaign> scope){

        /*for(Campaign cmp: scope){
            if(cmp.Opportunities != null && cmp.Opportunities.Size()>thresholdLimit){
                campaingIdsToClone.add(cmp.Id);
            }
        }*/
        for(Campaign cmp: scope){
            campaingIdsToClone.add(cmp.Id); 
        }
       
    }
    
    //Finish Method
    global void finish(Database.BatchableContext Bc){
        //Call the SkewReducer_Batch
        if(!campaingIdsToClone.IsEmpty()){
            Database.executeBatch(new CampaignSkewReducer_Batch(campaingIdsToClone), 50);
        }
    }
}