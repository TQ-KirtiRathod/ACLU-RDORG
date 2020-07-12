/*
*
*Name  :  CampaignLookupPageController
*Author:  Appirio India (Sai)
*Date  :  Feb 23, 2017
*Purpose : Custom controller for campaign lookup, popup page, used in BGE.
*
*/
public class CampaignLookupPageController
{
    public String query {get; set;}
    public Id accId {get;set;}
    public List<Campaign> campaigns{get; set;}
    Public  List<campaignWrapper> campaignProductsWrapper {get;set;}
    public Boolean showProducts {get;set;}
    public Id oppId {get;set;}
    public String selCmpProds {get;set;}
    public Boolean isAffiliateUser {get;set;}

    public campaignLookupPageController (){
        campaigns = new List<campaign>();
        String campaignQuery;
        Set<Id> campaignIds = new Set<Id>();
        showProducts = false;
        campaignProductsWrapper = new List<campaignWrapper>();
        selCmpProds = null;
        //Logged In User Affiliate /National User Based on isAffiliateUser checkbox
        isAffiliateUser = [SELECT Id, Is_Affiliate_User__c FROM User WHERE Id=: UserInfo.getUserId() LIMIT 1].Is_Affiliate_User__c;
        if(!String.IsBlank(ApexPages.currentPage().getParameters().get('accId'))){
            accId = ApexPages.currentPage().getParameters().get('accId');
            for(contact con: [SELECT Id, ( SELECT Id, campaignId FROM CampaignMembers ORDER BY campaign.rC_Giving__Drop_Date__c desc LIMIT 10) from contact where accountId =: accId AND rC_Bios__Preferred_Contact__c = true]){
                for(campaignMember cmp: con.CampaignMembers){
                    campaignIds.add(cmp.campaignId);
                }
            }
            // If the Batch Log Deposit Site not StartsWith NA, Then we need to retrieve the campaign records with Sub-Affiliation =
            if((ApexPages.currentPage().getParameters().get('deposit')!= null && ApexPages.currentPage().getParameters().get('deposit').StartsWith('NA'))){
                campaignQuery = 'SELECT Id, Name, rC_Giving__Source_Code__c, rC_Giving__Sub_Affiliation__c, (SELECT Id FROM rC_Connect__Campaign_Products__r) FROM Campaign WHERE Id =: campaignIds AND  Is_Overflow_Campaign__c = FALSE AND Is_Sustainer_Operational_Campaign__c = FALSE';
            }
            else{
                campaignQuery = 'SELECT Id, Name, rC_Giving__Source_Code__c, rC_Giving__Sub_Affiliation__c, (SELECT Id FROM rC_Connect__Campaign_Products__r) FROM Campaign WHERE Id =: campaignIds '; 
                campaignQuery =  campaignQuery +'AND (rC_Giving__Sub_Affiliation__c LIKE \'5%\' OR rC_Giving__Sub_Affiliation__c LIKE \'3%\') AND Is_Overflow_Campaign__c = FALSE AND Is_Sustainer_Operational_Campaign__c = FALSE';
            }

            for(Campaign cmp: (List<Campaign>)Database.query(campaignQuery)){
                campaigns.add(cmp);
            }
        }else{
            Set<Id> cmpId = new Set<Id>();
            for(RecentlyViewed rev: [SELECT Id, Name  FROM RecentlyViewed WHERE Type IN ('Campaign') AND LastViewedDate !=null ORDER BY LastViewedDate DESC LIMIT 100]){
                cmpId.add(rev.Id);
            }
            if(isAffiliateUser == false){
                campaigns=[SELECT Id, Name, rC_Giving__Source_Code__c, rC_Giving__Sub_Affiliation__c, (SELECT Id FROM rC_Connect__Campaign_Products__r) 
                                FROM Campaign 
                                WHERE Id=:cmpId 
                                AND  Is_Overflow_Campaign__c = FALSE 
                                AND Is_Sustainer_Operational_Campaign__c = FALSE 
                                ORDER BY LastViewedDate DESC  LIMIT 10];
            }
            else{
                campaigns=[SELECT Id, Name, rC_Giving__Source_Code__c, rC_Giving__Sub_Affiliation__c, (SELECT Id FROM rC_Connect__Campaign_Products__r) 
                FROM Campaign 
                WHERE Id=:cmpId 
                AND  Is_Overflow_Campaign__c = FALSE 
                AND (rC_Giving__Sub_Affiliation__c LIKE '3%' OR rC_Giving__Sub_Affiliation__c LIKE '5%') 
                AND Is_Sustainer_Operational_Campaign__c = FALSE 
                ORDER BY LastViewedDate DESC  LIMIT 10];
            }
       }


    }

    public PageReference runQuery()
    {
        String sQuery = '%'+query+'%';
        String campaignQuery;
        // If the Batch Log Deposit Site not StartsWith NA, Then we need to retrieve the campaign records with Sub-Affiliation =
        if((ApexPages.currentPage().getParameters().get('deposit')!= null && ApexPages.currentPage().getParameters().get('deposit').StartsWith('NA')) || (String.IsBlank(ApexPages.currentPage().getParameters().get('deposit')) && isAffiliateUser == false && String.IsBlank(ApexPages.currentPage().getParameters().get('accId')))){
            campaignQuery = 'SELECT Id, Name, rC_Giving__Source_Code__c, rC_Giving__Sub_Affiliation__c, (SELECT Id FROM rC_Connect__Campaign_Products__r) FROM Campaign WHERE  Is_Overflow_Campaign__c = FALSE AND (Name LIKE:sQuery OR rC_Giving__Source_Code__c LIKE: sQuery) AND Is_Sustainer_Operational_Campaign__c = FALSE LIMIT 1000';
        }
        else{
            campaignQuery = 'SELECT Id, Name, rC_Giving__Source_Code__c,rC_Giving__Sub_Affiliation__c, (SELECT Id FROM rC_Connect__Campaign_Products__r) FROM Campaign WHERE  Is_Overflow_Campaign__c = FALSE AND (Name LIKE:sQuery OR rC_Giving__Source_Code__c LIKE: sQuery) AND (rC_Giving__Sub_Affiliation__c LIKE \'5%\' OR rC_Giving__Sub_Affiliation__c LIKE \'3%\') AND Is_Sustainer_Operational_Campaign__c = FALSE LIMIT 1000';
        }
        campaigns=(List<Campaign>)Database.query(campaignQuery);
        if(campaigns.IsEmpty() && campaigns != null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'No matching campaigns found.');//Message changed as per I-275864
            ApexPages.addMessage(myMsg);
        }
        return null;
    }

    public void retrieveCampaignProducts (){

        Id campaignId = ApexPages.currentPage().getParameters().get('campaignId');
        Map<Id,rC_Connect__Campaign_Product__c> MapprodIds = new Map<Id,rC_Connect__Campaign_Product__c>();
        oppId = ApexPages.currentPage().getParameters().get('oppId');
        //oppId = '006W0000006t3ZTIAY';
        //campaignId= '701W000000043A4';
        campaignProductsWrapper = new List<campaignWrapper>();
        // Delete the Existing Opportunity Products under Opportunity
        List<OpportunityLineItem> oppDeleteProducts = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: oppId];
        if(!oppDeleteProducts.IsEmpty()){
            try{
                Delete oppDeleteProducts;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignLookupPageController','retrieveCampaignProducts',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
        // Fetch the Campaign Products
        List<rC_Connect__Campaign_Product__c> campaignProducts = [
          SELECT Id, rC_Connect__Product__c, rC_Connect__Product__r.Name
          FROM rC_Connect__Campaign_Product__c
          WHERE rC_Connect__Campaign__c =: campaignId];
        for(rC_Connect__Campaign_Product__c cmpPrd: [
            SELECT Id, rC_Connect__Product__c, rC_Connect__Product__r.Name
            FROM rC_Connect__Campaign_Product__c
            WHERE rC_Connect__Campaign__c =: campaignId]){
            MapprodIds.put(cmpPrd.rC_Connect__Product__c,cmpPrd);
        }
        for(PriceBookEntry prcBE: [
            SELECT Id, Product2Id
            FROM PriceBookEntry
            WHERE Product2Id IN: MapprodIds.KeySet()
              AND Pricebook2.Name ='Standard Price Book']){
            campaignProductsWrapper.add(new campaignWrapper(true, MapprodIds.get(prcBE.Product2Id)));
        }
        showProducts = true;
    }

    public class campaignWrapper {
        public Boolean isSelect {get;set;}
        public rC_Connect__Campaign_Product__c campaignProduct{get;set;}

        public campaignWrapper(Boolean isSelect, rC_Connect__Campaign_Product__c cmpProduct){
            this.isSelect = isSelect;
            this.campaignProduct = cmpProduct;
        }
    }

    public void createOpptyProducts(){
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        Map<Id,Id> mapProductIdToPriceBookEntryId = new Map<Id,Id>();
        set<Id> productIds = new Set<Id>();
        //Id priceBookId = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1].Id;
        //Collect the products
        for(campaignWrapper cmpWrapper: campaignProductsWrapper){
            productIds.add(cmpWrapper.campaignProduct.rC_Connect__Product__c);
        }
        // fetch the PricebookEntryId's
        for(PriceBookEntry pb: [SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id IN: productIds AND Pricebook2.Name ='Standard Price Book']){
            mapProductIdToPriceBookEntryId.put(pb.Product2Id, pb.Id);
        }
        // create OpptyLineItems
        for(campaignWrapper cmpWrapper: campaignProductsWrapper){
            if(cmpWrapper.isSelect == true && mapProductIdToPriceBookEntryId.get(cmpWrapper.campaignProduct.rC_Connect__Product__c) != null){
                if(!string.IsBlank(selCmpProds)){
                    selCmpProds += ':'+String.ValueOf(cmpWrapper.campaignProduct.rC_Connect__Product__c);
                }
                else{
                    selCmpProds = String.ValueOf(cmpWrapper.campaignProduct.rC_Connect__Product__c);
                }
                /*
                if(mapProductIdToPriceBookEntryId.get(cmpWrapper.campaignProduct.rC_Connect__Product__c) != null){
                    oppLineItems.add(new OpportunityLineItem(OpportunityId = oppId, PricebookEntryId  = mapProductIdToPriceBookEntryId.get(cmpWrapper.campaignProduct.rC_Connect__Product__c), UnitPrice = 10, Quantity = 10));
                }*/
            }
        }
        /*if(!oppLineItems.IsEmpty()){
            try{
                insert oppLineItems;
            }
            catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignLookupPageController','createOpptyProducts',e.getMessage());
                    log.logException(e);
                    log.saveLogs();
            }
        }*/

    }
}