/*
*
*Name  :  SkewReducer_Batch
*Author:  Appirio India (Sai )
*Date  :  May 24, 2017
*Purpose : Clones the Campaign and Increments the Current  giving Segment
*Class used to limit Data Skew for campaigns with a large amount of Opportunities
*
*/

global class CampaignSkewReducer_Batch implements Database.Batchable<sObject>,Database.stateful {
    public Id campaignIdToProcess ;
    public Id clonecampaignIdToProcess;
    public List<Id> campaignIds;
    public List<campaign_skew_control__c> campaignSkewCs;
    public Integer thresholdLimit;
    public Integer OppsPerCampaign;
    public Integer oppsCountPerCampaign;
    public List<Campaign> parentCampaign;
    public Static String donationRCDTYPE;
    public Static String pledgeRCDTYPE;
    public List<String> setOfExcludedChannels ;
    public static Boolean doNotProcessCampaign;
    
    static{
        donationRCDTYPE = ACLU_Constants.CONST_RCDTYPE_DONATION;
        pledgeRCDTYPE = ACLU_Constants.CONST_RCDTYPE_PLEDGE;
        doNotProcessCampaign = false;
    }
    //Constructor
    global CampaignSkewReducer_Batch(Set<Id> campaignSetIds){
         campaignIds = new List<Id>();
         setOfExcludedChannels = new List<String>();  
         //clonecampaignIdToProcess = new List<Id>();
         campaignSkewCs = new List<campaign_skew_control__c>();
         thresholdLimit = 0;
         oppsCountPerCampaign =0;
         OppsPerCampaign =0;
         parentCampaign = new List<Campaign>();
         
         
         // Intialise the Campaign set
         if(campaignSetIds != null && !campaignSetIds.IsEmpty() && campaignSetIds.size()>0){
             campaignIds = new List<Id>(campaignSetIds);
            campaignIdToProcess = campaignIds[0];
         }
         //Get the Custom Setting records to get the Threshold limit
         campaignSkewCs = campaign_skew_control__c.getAll().values();
         if(campaignSkewCs != null && !campaignSkewCs.IsEmpty() && campaignSkewCs[0].Threshold_for_Skew_Reduction__c != null){
            thresholdLimit = Integer.ValueOf(campaignSkewCs[0].Threshold_for_Skew_Reduction__c);
            OppsPerCampaign = Integer.ValueOf(campaignSkewCs[0].Opps_per_Campain__c);
            setOfExcludedChannels = (campaignSkewCs[0].CSV_of_Excluded_Channels__c != null) ? String.ValueOf(campaignSkewCs[0].CSV_of_Excluded_Channels__c).Split('\\|') : null;
         }
         
        //Query the Campaign and Clone it

        //Select all Campaing fields
        String fields = '';
        for(Schema.SObjectField ft : Schema.getGlobalDescribe().get(String.ValueOf('Campaign').toLowerCase()).getDescribe().Fields.getMap().values()){
            Schema.DescribeFieldResult fd = ft.getDescribe();
            if (fd.isCreateable()&& fd.getName()!='External_ID__c'){
                fields+= fd.getName()+',';
            }
        }

        //No fields add Id
        if(string.IsBlank(fields)){fields = 'Id,';}
        //get Single Campaign with Opportunities
        parentCampaign = Database.query('SELECT '+fields+' Id FROM Campaign WHERE Id =:campaignIdToProcess AND rC_Giving__Channel__c NOT IN : setOfExcludedChannels LIMIT 1');
        List<Campaign> cloneCampaignsToCreate = new List<Campaign>();
        
        If(!parentCampaign.isEmpty() && parentCampaign != null){
            //Clone Campaign
            Campaign cloneCampaign = new Campaign();

            cloneCampaign = parentCampaign[0].Clone(false,true,false,false);
            cloneCampaign.Is_Overflow_Campaign__c = True;

            try{
                insert cloneCampaign;
                clonecampaignIdToProcess = cloneCampaign.Id;
            }catch(exception e){
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('SkewReducer_Batch','Controller',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        } else {
            doNotProcessCampaign = true;
        }
    }

    //Start Method
    global Database.QueryLocator start(Database.BatchableContext Bc ){
        Date previousTwoDay = Date.today() - 2;
        String query = '';
        query += 'SELECT Id  FROM Opportunity WHERE (recordType.name=:donationRCDTYPE OR recordType.name=:pledgeRCDTYPE)';
        query = query + 'AND campaignId =:campaignIdToProcess ';
        if(!test.isRunningTest()){
             query = query + ' AND CreatedDate < :previousTwoDay';
        }
        if(doNotProcessCampaign) {
            query += ' AND Id = null';
        } 
        
        return Database.getQueryLocator(query);
    }

    //Execute Method
    global void execute(Database.BatchableContext Bc, List<Opportunity> scope){

        Map<Integer,Campaign> newCloneCampaigns = new Map<Integer,Campaign>();
        List<Opportunity> OppsToUpdateCampaign = new List<Opportunity>();
        String pledgePaymentRCTYPE = ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT;
        String transactionRCTYPE = ACLU_Constants.CONST_RCDTYPE_TRANSACTION;
        String softCreditRCTYPE = ACLU_Constants.CONST_RCDTYPE_SOFTCREDIT;
        Map<Id,Integer> mapOfOppIdVsIndex = new Map<Id,Integer>();
        Campaign cloneCampaign = new Campaign();
        set<Id> parentOppIds = new Set<Id>();
        Integer ClonCampaignIdIndex=0;
        // Collect the Parent Opportunities Ids
        for(Opportunity  ObjOpp: scope){
            parentOppIds.add(objOpp.Id);
        }

        // Prepares the Map of ParentOppVsChildOpps List
        Map<Id,Set<Id>> childOppsPerParent = new Map<Id,set<Id>>();

        if(!parentOppIds.IsEmpty() && parentOppIds != null){
            for(Opportunity objOpp: [SELECT Id, rC_Giving__Parent__c FROM Opportunity WHERE rC_Giving__Parent__c=: parentOppIds AND (recordType.name=:transactionRCTYPE OR
                                                                                                recordType.name=:pledgePaymentRCTYPE OR
                                                                                                recordType.name=:softCreditRCTYPE )]){
                if(childOppsPerParent.containsKey(objOpp.rC_Giving__Parent__c)){
                    childOppsPerParent.get(objOpp.rC_Giving__Parent__c).add(objOpp.Id);
                }
                else{
                    childOppsPerParent.put(objOpp.rC_Giving__Parent__c,new set<Id>{objOpp.Id});
                }
            }
        }

        // Updating the Opps with the Clone Campaign.

        if(clonecampaignIdToProcess != null && scope.size()>0){
            cloneCampaign = new Campaign(Id=clonecampaignIdToProcess);
            newCloneCampaigns.put(0,cloneCampaign);
            // Iterate through parent Opps
            for(Opportunity  ObjOpp: scope){
                oppsCountPerCampaign = oppsCountPerCampaign +1;
                if(oppsCountPerCampaign > OppsPerCampaign){
                    cloneCampaign = new Campaign();
                    //integer index = newCloneCampaigns.keySet().size();
                    cloneCampaign = parentCampaign[0].Clone(false,true,false,false);
                    cloneCampaign.Is_Overflow_Campaign__c = True;
                    newCloneCampaigns.put(ClonCampaignIdIndex+1,cloneCampaign);
                    ClonCampaignIdIndex=ClonCampaignIdIndex+1;
                    //mapOfOppIdVsIndex.put(ObjOpp.Id,cloneCampaign);
                    /*try{
                        insert cloneCampaign;
                        clonecampaignIdToProcess = cloneCampaign.Id;
                    } catch(exception e){
                        apexLogHandler.apexLog log = new apexLogHandler.apexLog('SkewReducer_Batch','Execute method - Campaign Insert',e.getMessage());
                        log.logException(e);
                        log.saveLogs();
                    }
                    */
                    oppsCountPerCampaign =1;
                }

                /*if(clonecampaignIdToProcess != null){
                    OppsToUpdateCampaign.add(new Opportunity(Id=ObjOpp.Id, CampaignId=clonecampaignIdToProcess));
                    if(childOppsPerParent!=null && objOpp !=null && childOppsPerParent.get(objOpp.Id)!=null){
                    for(Id objId: childOppsPerParent.get(objOpp.Id)){
                        OppsToUpdateCampaign.add(new Opportunity(Id=objId, CampaignIdText__c=clonecampaignIdToProcess));
                    }
                   }
                } */
                mapOfOppIdVsIndex.put(objopp.Id, ClonCampaignIdIndex);

            }
        }

        if((newCloneCampaigns != null) && (newCloneCampaigns.Values() != null)) {
          try {
            upsert newCloneCampaigns.Values();
            clonecampaignIdToProcess = newCloneCampaigns.get(ClonCampaignIdIndex).Id;
          }
          catch(exception e){
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('SkewReducer_Batch','Execute method - Campaign Insert',e.getMessage());
            log.logException(e);
            log.saveLogs();
          }
        }
        if((mapOfOppIdVsIndex != null) && (mapOfOppIdVsIndex.Values() != null)) {
          for(String  ObjOppId: mapOfOppIdVsIndex.keySet()) {
              if(mapOfOppIdVsIndex.containsKey(ObjOppId) && mapOfOppIdVsIndex.get(ObjOppId) != null &&
                  newCloneCampaigns.containsKey(mapOfOppIdVsIndex.get(ObjOppId))  && newCloneCampaigns.get(mapOfOppIdVsIndex.get(ObjOppId)) != null){


                  Id CampId = newCloneCampaigns.get(mapOfOppIdVsIndex.get(ObjOppId)).Id;
                  OppsToUpdateCampaign.add(new Opportunity(Id=ObjOppId, CampaignId = CampId));
                  if(childOppsPerParent!=null && ObjOppId !=null && childOppsPerParent.get(ObjOppId)!=null){
                    for(Id objId: childOppsPerParent.get(ObjOppId)){
                      OppsToUpdateCampaign.add(new Opportunity(Id=objId, CampaignIdText__c = CampId));
                    }
                  }
              }
            }
        }


        if(!OppsToUpdateCampaign.isEmpty() && OppsToUpdateCampaign != null){
            try{
                List<Database.SaveResult> SR = database.update(OppsToUpdateCampaign, false);
            }
            catch(exception e){
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('SkewReducer_Batch','Execute method',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }

    //Finish Method
    global void finish(Database.BatchableContext Bc){
        Id CurrentcampaignId = campaignIds[0];
        campaignIds.remove(0);
        if(!campaignIds.IsEmpty() && campaignIds.size()>0 && !doNotProcessCampaign){
            CampaignSkewReducer_Batch batchObj = new CampaignSkewReducer_Batch(new set<Id>(campaignIds));
            Database.executeBatch(batchObj,50);
        }

    }

     /*
    *Method CampaignSkew (webService)
    *@param : CampaignId
    *@description : Triggers the CampaignSkewReducer_Batch class
    */
    webservice static Boolean CampaignSkew(Id campaignId) {
        try {
           Database.executeBatch(new CampaignSkewReducer_Batch(new Set<Id> {campaignId}), 200);
           return true;
         }
         catch(Exception e) {
           return false;
         }
         return true;
    }
}