/*
*
*Name  :  OpportunityManager
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  January 20, 2017
*Purpose :  Helper class for OpportunityTriggerHandler. 
            Logic includes but not limited to
            - Stock Calculations
            - Merchant Name Updates based on the deposit site
            - sets Fiscal Year
            - Sets fields on Opp and child Opps (multiple methods)
            - Creates Preference Record based on related Campaign
            - Sends Email if expected amount changes
            - Populate Pledge Source Codes
            - Resets Sharing Records
            - Creates Tasks
* Ticket#    Modified Date       Modified By	 Description
*  #77940    24-June-2020          SFDO            Added a method that can map the batchlog details from child list to parent list           
*/
public class OpportunityManager {
    //public static Map<String, Sustainer_Source_Code_Setting__c> sustainerSourceCodeSetting;
    public static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    public static final String ALLACLU = Label.All_ACLU; 
    public static final String National = Label.National;
    public static final Map<Id,Opportunity> mapOfParentOppIdVsParentOpportunity = new Map<Id,Opportunity>();
    private static User loggedInUser;
    private static final String OPPORTUNITY_RT_SOFT_CREDIT_Id;
    private static final String OPPORTUNITY_RT_TRANSACTION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static final String OPPORTUNITY_RT_DONATION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_Id;
    public static map<String, Campaign> mapFiscalMonthYearToCampaign;
    static {
        //sustainerSourceCodeSetting = Sustainer_Source_Code_Setting__c.getAll();
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        loggedInUser = [select Profile.Name, Is_Affiliate_User__c from User where id = :Userinfo.getUserId()];
        OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        mapFiscalMonthYearToCampaign = new map<String, Campaign>();
        //Query campaigns for current fiscal year and create map for month+year to Campaign
        String year = String.valueOf(system.today().year());
        for(Campaign c : [SELECT Id, rC_Giving__Sub_Affiliation__c, rC_Giving__Affiliation__c,
                            rC_Giving__Source_Code__c, Sustainer_Operational_Year__c, Sustainer_Operational_Month__c, rC_Giving__Campaign_Type__c,
                            Fund__c, Account_Code__c, Restriction__c, Acknowledgment_Code__c
                            FROM Campaign 
                            WHERE Sustainer_Operational_Year__c = :year
                            AND rC_Giving__Affiliation__c != null
                            AND rC_Giving__Sub_Affiliation__c != null
                            AND Is_Sustainer_Operational_Campaign__c = TRUE]) {
            String month = c.Sustainer_Operational_Month__c != null && c.Sustainer_Operational_Month__c.subString(0,1) == '0' ? c.Sustainer_Operational_Month__c.subString(1,2) : c.Sustainer_Operational_Month__c;
            String key = month + '~' + c.Sustainer_Operational_Year__c + '~' + c.rC_Giving__Sub_Affiliation__c.subString(0,1) + '~' + c.rC_Giving__Affiliation__c;
            if(!mapFiscalMonthYearToCampaign.containsKey(key)) {
                mapFiscalMonthYearToCampaign.put(key, c);
            }
        }
    } 
    
    public static Map<Id, Opportunity>  opptyStockCalculation(Map<Id, Opportunity> parentOpptiesForStock, Map<Id, Opportunity> mapUpdateOpportunities) {
        Opportunity oppObj,parOppObj;
        for(Opportunity objOppty : [    SELECT  Id, Net_Amount__c, Fees__c, rC_Giving__Parent__r.Net_Amount__c, rC_Giving__Parent__r.Fees__c,
                                                rC_Giving__Parent__r.rC_Giving__Giving_Amount__c, rC_Giving__Giving_Amount__c
                                        FROM    Opportunity 
                                        WHERE   rC_Giving__Parent__c IN: parentOpptiesForStock.keySet()
                                        AND     (RecordTypeId =: OPPORTUNITY_RT_TRANSACTION_Id
                                                or RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)]
        ) {
            if( objOppty.rC_Giving__Parent__r.Net_Amount__c != null && objOppty.rC_Giving__Parent__r.Fees__c == NULL 
                && objOppty.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c != NULL){
                objOppty.Fees__c = objOppty.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c - objOppty.rC_Giving__Parent__r.Net_Amount__c;
                objOppty.Net_Amount__c = objOppty.rC_Giving__Parent__r.Net_Amount__c;
                parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Fees__c = objOppty.Fees__c;
            } 
            //If "Fees" is populated and Net Amount NULL on save: calculate and populate Net Amount field where Giving Amount - Fees = Net Amount
            else if( objOppty.rC_Giving__Parent__r.Net_Amount__c == null && objOppty.rC_Giving__Parent__r.Fees__c != NULL 
                && objOppty.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c != NULL){
                objOppty.Net_Amount__c = objOppty.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c - objOppty.rC_Giving__Parent__r.Fees__c;
                objOppty.Fees__c = objOppty.rC_Giving__Parent__r.Fees__c;
                parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Net_Amount__c = objOppty.Net_Amount__c;
            } 
            //If BOTH "Net Amount" and "Fees" are populated on save: defer to Giving Amount - Net Amount = Fees and override user input
            else if( objOppty.rC_Giving__Parent__r.Net_Amount__c != null && objOppty.rC_Giving__Parent__r.Fees__c != NULL 
                && objOppty.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c != NULL){
                objOppty.Fees__c = objOppty.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c - objOppty.rC_Giving__Parent__r.Net_Amount__c;
                objOppty.Net_Amount__c = objOppty.rC_Giving__Parent__r.Net_Amount__c;
                parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Net_Amount__c = objOppty.Net_Amount__c;
                parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Fees__c = objOppty.Fees__c;
            }
            //If user removes populated amounts for both Net Amount and Fees fields, after user clicks Save and row refreshes, allow user to override and fields remain blank.
            else if( objOppty.rC_Giving__Parent__r.Net_Amount__c == null && objOppty.rC_Giving__Parent__r.Fees__c == NULL){
                objOppty.Net_Amount__c = null;
                objOppty.Fees__c = null;
            }
            //updated for Issue-I-303579
            /*parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Net_Amount__c = null;
            parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Fees__c = null;*/
            if( mapUpdateOpportunities.containsKey( objOppty.id )){
                oppObj = mapUpdateOpportunities.get( objOppty.id );
                oppObj.Fees__c = objOppty.Fees__c;
                oppObj.Net_Amount__c = objOppty.Net_Amount__c;
                mapUpdateOpportunities.put(oppObj.Id,oppObj);
            } else {
                mapUpdateOpportunities.put(objOppty.Id,objOppty);
            }
            if( mapUpdateOpportunities.containsKey( parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Id )){
                parOppObj = mapUpdateOpportunities.get( parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Id );
                parOppObj.Fees__c = parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Fees__c;
                parOppObj.Net_Amount__c = parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Net_Amount__c;
                mapUpdateOpportunities.put(parOppObj.Id,parOppObj);
            } else {
                mapUpdateOpportunities.put(parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c).Id, parentOpptiesForStock.get(objOppty.rC_Giving__Parent__c));
            }
            
            
        }
        
        return mapUpdateOpportunities;
    }
    
     /*
    Method updateMerchantName
    @description : Merchant name of the paymentMethod record updates based on deposit site . 
    */
    public static Map<Id,rC_Giving__Payment_Method__c> updateMerchantName(List<Opportunity> oppsToUpdateMerchantName) {
        Map<Id,rC_Giving__Payment_Method__c> paymentMethods = new Map<Id, rC_Giving__Payment_Method__c>(); 
        for(Opportunity opp: oppsToUpdateMerchantName){
            if(opp.Deposit_Site__c != null && (opp.rC_Giving__Payment_Method__c == 'Charge Card' || opp.rC_Giving__Payment_Method__c == 'EFT')){
                paymentMethods.put(opp.rC_Giving__Payment_Method_Selected__c, new rC_Giving__Payment_Method__c(Id = opp.rC_Giving__Payment_Method_Selected__c, rC_Connect__Merchant_Name__c = opp.Deposit_Site__c));
            }
            else{
                paymentMethods.put(opp.rC_Giving__Payment_Method_Selected__c, new rC_Giving__Payment_Method__c(Id = opp.rC_Giving__Payment_Method_Selected__c, rC_Connect__Merchant_Name__c = null));
            }
        }
        
        return paymentMethods;
    }
    
    public static Map<Id, Opportunity> setRevenueFiscalYear(List<Opportunity> listOfChildOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity theOpp : listOfChildOpps) {
        theOpp.Revenue_Fiscal_Year__c = theOpp.rC_Giving__Parent__r.Revenue_Fiscal_Year__c;
        mapUpdateOpportunities.put(theOpp.Id,theOpp);
      } 
      return mapUpdateOpportunities;
    }
    
    public static Map<Id, Opportunity> updateFieldsonChildOpps(List<Opportunity> listOfChildOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity theOpp : listOfChildOpps) {
        theOpp.Restriction__c = theOpp.rC_Giving__Parent__r.Restriction__c;
        theOpp.Account_Code__c = theOpp.rC_Giving__Parent__r.Account_Code__c;
        theOpp.Fundraising_Department__c = theOpp.rC_Giving__Parent__r.Fundraising_Department__c;
        if(theOpp.rC_Giving__Acknowledged_Date__c == null && theOpp.Acknowledgment_Status__c != 'A - Acknowledged') {
        theOpp.Acknowledgment_Code__c = theOpp.rC_Giving__Parent__r.Acknowledgment_Code__c;
        }
        /*Commented below code : S-553223, Populate SB_Donation_Id__c from parent only when child record is updating to Complete stage and SB_Donation_Id__c is null.*/
        /*//T-688679 Bhavesh
        if( theOpp.StageName == 'Completed' && theOpp.rC_Giving__Parent__r.SB_Donation_Id__c != null 
            && theOpp.SB_Donation_Id__c == NULL){
            theOpp.SB_Donation_Id__c =  theOpp.rC_Giving__Parent__r.SB_Donation_Id__c;
        }*/
        
        theOpp.Fund__c = theOpp.rC_Giving__Parent__r.Fund__c;
        if((theOpp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) || (theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && theOpp.StageName != 'Completed' && OpportunityTriggerHandler.IsSourceCodeUpdatedFromDonation == false)) {
          theOpp.rC_Giving__Source_Code__c =  theOpp.rC_Giving__Parent__r.rC_Giving__Source_Code__c != null
                                           ?   theOpp.rC_Giving__Parent__r.rC_Giving__Source_Code__c
                                           :   theOpp.rC_Giving__Source_Code__c;
          theOpp.CampaignIdText__c = theOpp.rC_Giving__Parent__r.CampaignId != null ? theOpp.rC_Giving__Parent__r.CampaignId : theOpp.CampaignIdText__c; 
        }
        mapUpdateOpportunities.put(theOpp.Id,theOpp);
      } 
      return mapUpdateOpportunities;
    }
     
     /*
    Method byPassCalculationsOnChild
    @description : Update By pass calculation on all child Oppty records when Parent byPassCalculation flag is set to true.
    */
     public static Map<Id, Opportunity> byPassCalculationsOnChild(List<Opportunity> parentByPassCalculationGivingRecord, Map<Id, Opportunity> mapUpdateOpportunities){
        for(Opportunity opp: parentByPassCalculationGivingRecord){
            mapUpdateOpportunities.put(opp.Id, new Opportunity(Id = opp.Id, Bypass_Calculations__c = true));
            
        }
        
        return mapUpdateOpportunities;
     }
     
     /*Method to update the Deposit Site
     */
     
    public static Map<Id, Opportunity> updateDepositSiteOnChildOpps(List<Opportunity> listOfOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity theOpp : listOfOpps) {
        mapUpdateOpportunities.put(theOpp.Id, new Opportunity(Id = theOpp.Id, Deposit_Site__c = theOpp.rC_Giving__Parent__r.Deposit_Site__c));      
      }
      return mapUpdateOpportunities;
    }
    
    public static Map<Id, Opportunity> updateTaxDateOnChildOpps(List<Opportunity> listOfOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity theOpp : listOfOpps) {
        mapUpdateOpportunities.put(theOpp.Id, new Opportunity(Id = theOpp.Id, Tax_Date__c = theOpp.rC_Giving__Parent__r.Tax_Date__c));      
      }
      return mapUpdateOpportunities;
    }
    
     /*
	*
	*Method pushSourceFieldsToFirstChild
	*@param : parentOpp
    *@param : childOpp
	*Author:  ACLU (Dave Seidman)
	*Date  :  August 31, 2018
	*Purpose : AI-8: Market source fields needs to sync from parent Giving record to
	*       		the first and only the first child pledge payment record. This had
	*				previously been implemented for SB_Donation_Id, but the first-child-payment
	*				criteria was not used
	*Modifications :
    *          GH-66: Add Market_Source_Other__c, Payment_Subtype__c, SB_Gateway_Transaction_Id__c
	*Future TODO: Store these field mappings in a custom setting for easy reconfiguration
	*
	*/
	public static void pushParentSourceFieldsToFirstPayment(Opportunity childOpp) {
    	childOpp.rC_Giving__Source_Code__c = childOpp.rC_Giving__Parent__r.rC_Giving__Source_Code__c;
    	childOpp.sb_donation_id__c = childOpp.rC_Giving__Parent__r.sb_donation_id__c;
    	childOpp.Market_Source_Date__c = childOpp.rC_Giving__Parent__r.Market_Source_Date__c;
    	childOpp.Form_Internal_Name__c = childOpp.rC_Giving__Parent__r.Form_Internal_Name__c;
        childOpp.SB_Gateway_Transaction_ID__c = childOpp.rc_Giving__Parent__r.SB_Gateway_Transaction_ID__c;
    	childOpp.SB_Originating_Form_ID__c = childOpp.rC_Giving__Parent__r.SB_Originating_Form_ID__c;
    	childOpp.Initial_Market_Source_Affiliation__c = childOpp.rC_Giving__Parent__r.Initial_Market_Source_Affiliation__c;
    	childOpp.Initial_Market_Source_Channel__c = childOpp.rC_Giving__Parent__r.Initial_Market_Source_Channel__c;
    	childOpp.Initial_Market_Source_External__c = childOpp.rC_Giving__Parent__r.Initial_Market_Source_External__c;
    	childOpp.Initial_Market_Source_Other__c = childOpp.rC_Giving__Parent__r.Initial_Market_Source_Other__c;
    	childOpp.Market_Source_External__c = childOpp.rC_Giving__Parent__r.Market_Source_External__c;
    	childOpp.Market_Source_Affiliation__c = childOpp.rC_Giving__Parent__r.Market_Source_Affiliation__c;
    	childOpp.Market_Source_Channel__c = childOpp.rC_Giving__Parent__r.Market_Source_Channel__c;
        childOpp.Market_Source_Other__c = childOpp.rC_Giving__Parent__r.Market_Source_Other__c;
    	childOpp.Payment_Subtype__c = childOpp.rc_Giving__Parent__r.Payment_Subtype__c;
        childOpp.SB_Originating_Form_Name__c = childOpp.rC_Giving__Parent__r.SB_Originating_Form_Name__c;
    	childOpp.SB_Originating_Form_ID__c = childOpp.rC_Giving__Parent__r.SB_Originating_Form_ID__c;
    	childOpp.Referral_URL__c = childOpp.rC_Giving__Parent__r.Referral_URL__c;
    	childOpp.Initial_Referral_URL__c = childOpp.rC_Giving__Parent__r.Initial_Referral_URL__c;
    	childOpp.Search_Engine__c = childOpp.rC_Giving__Parent__r.Search_Engine__c;
    	childOpp.Search_String__c = childOpp.rC_Giving__Parent__r.Search_String__c;
    } 
       
     /*
    *
    *Method createPreferenceOffIssues
    *@param : newlistOpps 
    *@param : oldMapOpps
    *It creates a preference record 
    *based on a preference code when an Opportunity is updated with a campaign 
    *where that campaign has an issue with that preference code associated with it.
    *
    */    
    public static PageReference createPreferenceOffIssues(Map<Id, Id> mapCampaignAccount){
        Set<Id> setOfPledgeOpportunityIds = new Set<Id>();
        Map<Id, Set<String>> mapAccountPrefCode = new Map<Id, Set<String>>();
        List<rC_Bios__Preference__c> listPreference = new List<rC_Bios__Preference__c>();
        
        //To make sure, preference with a given code should only be added to the account 
        //if the account does not already have a preference code with that value
        for(rC_Bios__Preference__c accpr : [SELECT Id,rC_Bios__Code_Value__c,rC_Bios__Account__c FROM rC_Bios__Preference__c WHERE rC_Bios__Account__c IN: mapCampaignAccount.values()]){
            if(!mapAccountPrefCode.containsKey(accpr.rC_Bios__Account__c)){
                mapAccountPrefCode.put(accpr.rC_Bios__Account__c,new set<String>{});
            }
            mapAccountPrefCode.get(accpr.rC_Bios__Account__c).add(accpr.rC_Bios__Code_Value__c);    
        }
        
        for(Campaign_Issue__c camIss : [SELECT Id,Pref_Code__c,Campaign__c FROM Campaign_Issue__c WHERE Campaign__c IN: mapCampaignAccount.keyset()] ){
            //check if Campaign Issue consist of Preference Code    
            if(camIss.Pref_Code__c != null){
                    //check if Account has existing preference code with that value.
                    if(mapAccountPrefCode.isEmpty() || (mapAccountPrefCode.containsKey(mapCampaignAccount.get(camIss.Campaign__c)) && (!mapAccountPrefCode.get(mapCampaignAccount.get(camIss.Campaign__c)).contains(camIss.Pref_Code__c)))){
                        //Creates a new Preference Record on that Account
                        rC_Bios__Preference__c pc = new rC_Bios__Preference__c();
                        pc.rC_Bios__Account__c = mapCampaignAccount.get(camIss.Campaign__c);
                        pc.rC_Bios__Code_Value__c = camIss.Pref_Code__c;
                        pc.rC_Bios__Status__c = 'Implied';
                        listPreference.add(pc);
                    }      
             }
        }       
        
        if(listPreference.size()>0){
            try {
                insert listPreference; 
            } catch (DMLException e) {
                
                for (Opportunity oppty : (List<Opportunity>)trigger.new) {
                    oppty.addError(e.getDmlMessage(0));
                }
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('OpportunityManager','createPreferenceOffIssues',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
            catch (Exception e) {
                for (Opportunity oppty : (List<Opportunity>)trigger.new) {
                    oppty.addError(e.getMessage());
                }
            }
            
        }
        return null;
    }
    
     /*
    *
    *Method sendEmailToOpportunityOwner
    *@param : newlistOpp, oldMapOpp
    *To send a chatter note to record owner
    *if an expected amount changes on
    *Opportunity.
    *
    */ 
    public static void sendEmailToOpportunityOwner(List<Opportunity> listOfOpportunity){
        
        String oppNote = Label.Opportunity_Chatter_note;  
        String url = Label.Salesforce_URL; 
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        Id userId = UserInfo.getUserId() ;
        for(Opportunity opp : listOfOpportunity) {
            //if opportunity is of pledge record type and its sustainer is false
            if(opp.RecordTypeId == opptyRTMap.get('Pledge').getRecordTypeId() && opp.rC_Giving__Is_Sustainer__c == false) {
                
                //send a chatter note to its record owner if expected amount changes
                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                ConnectApi.LinkSegmentInput linksegment = new ConnectApi.LinkSegmentInput(); 
                ConnectApi.MarkupBeginSegmentInput markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
                ConnectApi.MarkupEndSegmentInput markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                mentionSegmentInput.id = opp.OwnerId;
                messageBodyInput.messageSegments.add(mentionSegmentInput);
                markupBeginSegment.markupType = ConnectApi.MarkupType.Code;
                messageBodyInput.messageSegments.add(markupBeginSegment);
                textSegmentInput.text = +' '+oppNote;
                messageBodyInput.messageSegments.add(textSegmentInput);
                markupEndSegment.markupType = ConnectApi.MarkupType.Code;
                messageBodyInput.messageSegments.add(markupEndSegment);
                linksegment.url = 'Click here : '+url+opp.Id;
                messageBodyInput.messageSegments.add(linksegment);
                feedItemInput.body = messageBodyInput;
                feedItemInput.subjectId = opp.OwnerId;
                feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                batchInputs.add(batchInput);
            }         
        } 
       
        if(batchInputs.size()>0){
          if(!test.isRunningTest()) {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
          }
        }   
    }
    
    /*    
    *
    *Method populateSourceCodeValues
    *@param : Set<Id> (relationshipIds)
    *@param : List<String> OldAffiliations
    *A Method to Populate Source Code on Pledge Payment and Pledge Opportunitites.
    *
    */
    public static Map<Id, Opportunity> populateSourceCodeValues(Map<Id, Opportunity> opptyMapToUpdate, List<Opportunity> listOfChildOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
        set<Id> setParentIdsCovered = new set<Id>();
        if(opptyMapToUpdate != null && !opptyMapToUpdate.isEmpty()) {
            mapUpdateOpportunities.putAll(opptyMapToUpdate);
        }
        
        if(!listOfChildOpps.isEmpty()) {
            for(Opportunity objOppty : listOfChildOpps) {
               if(objOppty.StageName == 'Open' && objOppty.rC_Giving__Parent__c != null) {
                   if(!objOppty.rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c) {
                       if(mapUpdateOpportunities.containsKey(objOppty.Id)) {
                           mapUpdateOpportunities.get(objOppty.Id).rC_Giving__Source_Code__c = !OpportunityTriggerHandler.IsSourceCodeUpdatedFromDonation ? objOppty.rC_Giving__Parent__r.rC_Giving__Source_Code__c : objOppty.rC_Giving__Source_Code__c;
                       } else {
                           objOppty.rC_Giving__Source_Code__c = !OpportunityTriggerHandler.IsSourceCodeUpdatedFromDonation ? objOppty.rC_Giving__Parent__r.rC_Giving__Source_Code__c : objOppty.rC_Giving__Source_Code__c;
                           mapUpdateOpportunities.put(objOppty.Id,objOppty);
                       }
                       if(!Utilities.IsUpsert) { 
                           Utilities.IsUpsert = true;
                       }
                   } else if(!setParentIdsCovered.contains(objOppty.rC_Giving__Parent__c)) {
                       if(mapUpdateOpportunities.containsKey(objOppty.Id)) {
                           mapUpdateOpportunities.get(objOppty.Id).Sustainer_First_Payment__c = true;
                       } else {
                           objOppty.Sustainer_First_Payment__c = true;
                           mapUpdateOpportunities.put(objOppty.Id,objOppty);
                       }
                       setParentIdsCovered.add(objOppty.rC_Giving__Parent__c);
                       if(!Utilities.IsUpsert) {
                           Utilities.IsUpsert = true;
                       }
                   }
               }
           }
        }
        return mapUpdateOpportunities;
    }
    
    public static Map<Id, Opportunity> updateFieldsOnSoftCredits(List<Opportunity> listOfChildOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity child : listOfChildOpps) {
              child.rC_Giving__Source_Code__c = child.Related_Transaction__r.rC_Giving__Source_Code__c != null
                                              ? child.Related_Transaction__r.rC_Giving__Source_Code__c
                                              : child.rC_Giving__Source_Code__c;
              child.Deposit_Site__c = child.Related_Transaction__r.Deposit_Site__c != null
                                    ? child.Related_Transaction__r.Deposit_Site__c
                                    : child.Deposit_Site__c;
              child.RPT_Package_Code__c = child.Related_Transaction__r.RPT_Package_Code__c != null
                                        ? child.Related_Transaction__r.RPT_Package_Code__c
                                        : child.RPT_Package_Code__c;
              child.Restriction__c = child.Related_Transaction__r.Restriction__c != null
                                    ? child.Related_Transaction__r.Restriction__c
                                    : child.Restriction__c;
              child.Program_Type__c = child.Related_Transaction__r.Program_Type__c != null
                                    ? child.Related_Transaction__r.Program_Type__c 
                                    : child.Program_Type__c;
              child.Campaign_Type__c =  child.Related_Transaction__r.Campaign_Type__c != null ?
                                        child.Related_Transaction__r.Campaign_Type__c
                                        : child.Campaign_Type__c;
              child.Fund__c =  child.Related_Transaction__r.Fund__c != null ?
                               child.Related_Transaction__r.Fund__c
                               : child.Fund__c;
              child.Fundraising_Department__c =  child.Related_Transaction__r.Fundraising_Department__c != null ?
                                                  child.Related_Transaction__r.Fundraising_Department__c 
                                                : child.Fundraising_Department__c;
              child.Account_Code__c =  child.Related_Transaction__r.Account_Code__c != null
                                    ? child.Related_Transaction__r.Account_Code__c
                                    : child.Account_Code__c;
              child.CampaignIdText__c = child.Related_Transaction__r.CampaignIdText__c != null
                                      ? child.Related_Transaction__r.CampaignIdText__c
                                    : child.CampaignIdText__c;
              if(child.rC_Giving__Acknowledged_Date__c == null && child.Acknowledgment_Status__c != 'A - Acknowledged') {
                child.Acknowledgment_Code__c = child.Related_Transaction__r.Acknowledgment_Code__c != null
                                           ? child.Related_Transaction__r.Acknowledgment_Code__c 
                                           : child.Acknowledgment_Code__c;
              }
              mapUpdateOpportunities.put(child.Id,child);
      } 
      return mapUpdateOpportunities;
    }
    
    /*    
    *
    *Method retrieveSourceCode
    *@param : String year
    *@param : String month
    *A Method to retrieve source code from Custom setting
    *
    */
    /*public static String retrieveSourceCode(String year, String month) {
        String sourceCode = '';
        
        if(sustainerSourceCodeSetting != null) {
            for(Sustainer_Source_Code_Setting__c srccode : sustainerSourceCodeSetting.values()) {
                if(srccode.Month__c == month && srccode.Year__c == year) {
                    
                    sourceCode = srccode.Source_Code__c;
                }
            }
        }
        return sourcecode;
    }*/
    public static Opportunity retrieveSourceCode(Opportunity opp) {
        Campaign cmp;
        if(opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || opp.Program_Type__c == '3') {
            if(mapFiscalMonthYearToCampaign.containsKey(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + '1' + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c)) {
                cmp = mapFiscalMonthYearToCampaign.get(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + '1' + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c);
                opp.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
                opp.CampaignIdText__c = cmp.Id;
                //T-648918 - Mapping more fields from Campaign to Opportunity - KM - 11/23/2017
                if(!String.isBlank(cmp.rC_Giving__Campaign_Type__c)) {
                    opp.Campaign_Type__c = (cmp.rC_Giving__Campaign_Type__c).subString(0,1);
                }
                opp.Fund__c = cmp.Fund__c;
                opp.Account_Code__c = cmp.Account_Code__c;
                opp.Restriction__c = cmp.Restriction__c;
                opp.Acknowledgment_Code__c = cmp.Acknowledgment_Code__c;
                //I-305155 - Map Program Type
                if(!String.isBlank(cmp.rC_Giving__Sub_Affiliation__c)) {
                    opp.Program_Type__c = (cmp.rC_Giving__Sub_Affiliation__c).subString(0,1);
                }
            } else if(mapFiscalMonthYearToCampaign.containsKey(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + '2' + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c)) {
                cmp = mapFiscalMonthYearToCampaign.get(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + '2' + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c);
                opp.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
                opp.CampaignIdText__c = cmp.Id;
                //T-648918 - Mapping more fields from Campaign to Opportunity - KM - 11/23/2017
                if(!String.isBlank(cmp.rC_Giving__Campaign_Type__c)) {
                    opp.Campaign_Type__c = (cmp.rC_Giving__Campaign_Type__c).subString(0,1);
                }
                opp.Fund__c = cmp.Fund__c;
                opp.Account_Code__c = cmp.Account_Code__c;
                opp.Restriction__c = cmp.Restriction__c;
                opp.Acknowledgment_Code__c = cmp.Acknowledgment_Code__c;
                if(!String.isBlank(cmp.rC_Giving__Sub_Affiliation__c)) {
                    opp.Program_Type__c = (cmp.rC_Giving__Sub_Affiliation__c).subString(0,1);
                }
            } else if(mapFiscalMonthYearToCampaign.containsKey(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + '3' + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c)) {
                cmp = mapFiscalMonthYearToCampaign.get(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + '3' + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c);
                opp.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
                opp.CampaignIdText__c = cmp.Id;
                //T-648918 - Mapping more fields from Campaign to Opportunity - KM - 11/23/2017
                if(!String.isBlank(cmp.rC_Giving__Campaign_Type__c)) {
                    opp.Campaign_Type__c = (cmp.rC_Giving__Campaign_Type__c).subString(0,1);
                }
                opp.Fund__c = cmp.Fund__c;
                opp.Account_Code__c = cmp.Account_Code__c;
                opp.Restriction__c = cmp.Restriction__c;
                opp.Acknowledgment_Code__c = cmp.Acknowledgment_Code__c;
                if(!String.isBlank(cmp.rC_Giving__Sub_Affiliation__c)) {
                    opp.Program_Type__c = (cmp.rC_Giving__Sub_Affiliation__c).subString(0,1);
                }
            }
        } else if(opp.Program_Type__c == '4') {
            if(mapFiscalMonthYearToCampaign.containsKey(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + opp.Program_Type__c + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c)) {
                cmp = mapFiscalMonthYearToCampaign.get(String.ValueOf(opp.CloseDate.month()) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + opp.Program_Type__c + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c);
                opp.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
                opp.CampaignIdText__c = cmp.Id;
                //T-648918 - Mapping more fields from Campaign to Opportunity - KM - 11/23/2017
                if(!String.isBlank(cmp.rC_Giving__Campaign_Type__c)) {
                    opp.Campaign_Type__c = (cmp.rC_Giving__Campaign_Type__c).subString(0,1);
                }
                opp.Fund__c = cmp.Fund__c;
                opp.Account_Code__c = cmp.Account_Code__c;
                opp.Restriction__c = cmp.Restriction__c;
                opp.Acknowledgment_Code__c = cmp.Acknowledgment_Code__c;
                if(!String.isBlank(cmp.rC_Giving__Sub_Affiliation__c)) {
                    opp.Program_Type__c = (cmp.rC_Giving__Sub_Affiliation__c).subString(0,1);
                }
            }
        } else if(opp.Program_Type__c == '5') {
            String key = null + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + opp.Program_Type__c + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c;
            if(mapFiscalMonthYearToCampaign.containsKey(key)) {
                cmp = mapFiscalMonthYearToCampaign.get(key);
                opp.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
                opp.CampaignIdText__c = cmp.Id;
                //T-648918 - Mapping more fields from Campaign to Opportunity - KM - 11/23/2017
                if(!String.isBlank(cmp.rC_Giving__Campaign_Type__c)) {
                    opp.Campaign_Type__c = (cmp.rC_Giving__Campaign_Type__c).subString(0,1);
                }
                opp.Fund__c = cmp.Fund__c;
                opp.Account_Code__c = cmp.Account_Code__c;
                opp.Restriction__c = cmp.Restriction__c;
                opp.Acknowledgment_Code__c = cmp.Acknowledgment_Code__c;
                if(!String.isBlank(cmp.rC_Giving__Sub_Affiliation__c)) {
                    opp.Program_Type__c = (cmp.rC_Giving__Sub_Affiliation__c).subString(0,1);
                }
            } else {
                for(Integer i = 1; i<13; i++) {
                    key = String.ValueOf(i) + '~' + String.ValueOf(opp.CloseDate.year()) + '~' + opp.Program_Type__c + '~' + opp.rC_Giving__Parent__r.rC_Giving__Affiliation__c;
                    if(mapFiscalMonthYearToCampaign.containsKey(key)) {
                        cmp = mapFiscalMonthYearToCampaign.get(key);
                        opp.rC_Giving__Source_Code__c = cmp.rC_Giving__Source_Code__c;
                        opp.CampaignIdText__c = cmp.Id;
                        //T-648918 - Mapping more fields from Campaign to Opportunity - KM - 11/23/2017
                        if(!String.isBlank(cmp.rC_Giving__Campaign_Type__c)) {
                            opp.Campaign_Type__c = (cmp.rC_Giving__Campaign_Type__c).subString(0,1);
                        }
                        opp.Fund__c = cmp.Fund__c;
                        opp.Account_Code__c = cmp.Account_Code__c;
                        opp.Restriction__c = cmp.Restriction__c;
                        opp.Acknowledgment_Code__c = cmp.Acknowledgment_Code__c;
                        if(!String.isBlank(cmp.rC_Giving__Sub_Affiliation__c)) {
                            opp.Program_Type__c = (cmp.rC_Giving__Sub_Affiliation__c).subString(0,1);
                        }
                        break;
                    }
                }
            }
        }
        
        return opp;
    }
    public static Map<Id,Opportunity> setExcludeFromRevenuesharingField(List<Opportunity> listOfParentOppty, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity parentTransaction : listOfParentOppty) {
        parentTransaction.Exclude_from_Revenue_Sharing__c = True;
        parentTransaction.Sharing_Code__c = 'SOFTCREDIT';
        mapUpdateOpportunities.put(parentTransaction.Id,parentTransaction);
      }
      return mapUpdateOpportunities;
    }
    
    public static Map<Id,Opportunity> setStageToOpenIfPendingFailed(List<Opportunity> listOfParentOppty, Map<Id, Opportunity> mapUpdateOpportunities) {
      for(Opportunity parentOpp : listOfParentOppty) {
        parentOpp.StageName = 'Open';
        mapUpdateOpportunities.put(parentOpp.Id,parentOpp);
      }
      return mapUpdateOpportunities;
    }
    
    public static Map<Id,Opportunity> updateRollUpGivingOnGrantAndProposal(List<Opportunity> listOfProposlsAndGrant, Map<Id,Opportunity> mapUpdateOpportunities) {
      for(Opportunity opp : listOfProposlsAndGrant) {
        opp.rC_Giving__Rollup_Giving__c = null;
        mapUpdateOpportunities.put(opp.Id,opp); 
      } 
      return mapUpdateOpportunities;
    }

    /*    
    *
    *Method resetNGOCSharingRecords
    *@param : set<Id> accountIds
    *@param : List<String> OldAffiliations
    *It resets the Preference,Salutation,Relationship,ActionPlan share Records if present.
    *
    */
    public static void resetNGOCSharingRecords( set<Id> opportunityIds, List<String> OldAffiliations){
        Set<Id> actionPlanIds = new Set<Id> ();
        Set<Id> relationshipIds = new Set<Id>();
        Set<Id> confidentialIds = new Set<Id>();
        
        //Relationship
        for(rC_Bios__Relationship__c rl: [SELECT Id, rC_Bios__Opportunity__c FROM rC_Bios__Relationship__c WHERE  rC_Bios__Opportunity__c =: opportunityIds]){
            relationshipIds.add(rl.Id);
        }
        
        //ActionPlan
        for(rC_Bios__Action_Plan__c ap: [SELECT Id, rC_Bios__Opportunity__c FROM rC_Bios__Action_Plan__c WHERE  rC_Bios__WhatId__c =: opportunityIds ]){
            actionPlanIds.add(ap.Id);
        }
        
        //ConfidentialIds
        for(Confidential_Data__c cnf: [SELECT Id, Name, Opportunity__c, Opportunity__r.Account.Affiliation__c, Opportunity__r.Account.Restricted_Account__c FROM Confidential_Data__c where Opportunity__c =: opportunityIds]){
            confidentialIds.add(cnf.Id);
        }
        
        // Re-calculate the sharing rules in a future method .
        if((!relationshipIds.IsEmpty() || !actionPlanIds.IsEmpty() || !confidentialIds.IsEmpty()) && Utilities.CanUseFutureContext())
            OpportunityManager.resetNGOCShareRecordsFutureHandler(actionPlanIds, relationshipIds, confidentialIds, OldAffiliations);  
    }
    
    /*    
    *
    *Method resetActionPlanShareRecords
    *@param : Set<Id> (preferenceIds)
    *@param : Set<Id> (salutationIds)
    *@param : Set<Id> (actionPlanIds)
    *@param : Set<Id> (relationshipIds)
    *@param : List<String> OldAffiliations
    *It resets the share records based on the their account Affiliation.
    *
    */
    //@future
    public static void resetNGOCShareRecordsFutureHandler(Set<Id> actionPlanIds, Set<Id> relationshipIds,  Set<Id> confidentialIds, List<String> OldAffiliations){
        
        if(!relationshipIds.IsEmpty())
            OpportunityManager.resetRelationshipShareRecords(relationshipIds, OldAffiliations);
        
        if(!actionPlanIds.IsEmpty())
            OpportunityManager.resetActionPlanShareRecords(actionPlanIds, OldAffiliations);
            
        if(!confidentialIds.IsEmpty())
            OpportunityManager.resetConfidential(confidentialIds, OldAffiliations);
        
    }
    
    /*    
    *
    *Method resetActionPlanShareRecords
    *@param : Set<Id> (actionPlanIds)
    *@param : List<String> OldAffiliations
    *It resets the share records based on the their account Affiliation.
    *
    */
    public static void resetActionPlanShareRecords(Set<Id> actionPlanIds, List<String> OldAffiliations){
        Map<Id,String> mapActionPlanIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapActionPlanIdToRestricted = new map<Id,Boolean> ();
        Map<Id,Id> mapActionPlanIdToopportunityId = new Map<Id,Id>();
        map<Id,Opportunity> mapOpportunityIdToOpportunity = new map<Id,Opportunity>();
        map<Id,rC_Bios__Action_Plan__c> mapActionPlan = new map<Id,rC_Bios__Action_Plan__c>();
        
        // Collect the ActionPlanIdToAffiliation
        for(rC_Bios__Action_Plan__c mapAcp: [SELECT Id, rC_Bios__WhatId__c, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Opportunity__c, rC_Bios__Opportunity__r.accountId, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Account__r.Affiliation__c, rC_Bios__Contact__r.account.Affiliation__c FROM rC_Bios__Action_Plan__c WHERE Id =: actionPlanIds]){
            if(mapAcp.rC_Bios__WhatId__c != null && string.ValueOf(mapAcp.rC_Bios__WhatId__c).startsWith('006')){
                mapActionPlanIdToopportunityId.put(mapAcp.Id,mapAcp.rC_Bios__WhatId__c);
                mapActionPlan.put(mapAcp.Id,mapAcp);
            }
            
        }
        
        
        if(!mapActionPlanIdToopportunityId.Keyset().IsEmpty()){
            for(Opportunity opp: [SELECT id, account.Affiliation__c, account.Restricted_Account__c FROM Opportunity where id=: mapActionPlanIdToopportunityId.Values()]){
                if(opp.account.Affiliation__c != null){
                    mapOpportunityIdToOpportunity.put(opp.Id,opp);
                }
            }
        }
        
        for(Id acPId: mapActionPlanIdToopportunityId.KeySet()){
            if(mapActionPlan.get(acpId) != null && mapOpportunityIdToOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c) != null){
                mapActionPlanIdToAffiliate.put(acPId,mapOpportunityIdToOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c).account.Affiliation__c);
                mapActionPlanIdToRestricted.put(acPId,mapOpportunityIdToOpportunity.get(mapActionPlan.get(acpId).rC_Bios__WhatId__c).account.Restricted_Account__c);
            }
        }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapActionPlanIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: National]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deleteActionPlanSharingRecords (mapActionPlanIdToAffiliate.keySet(), OldAffiliations, mapGroupNameToId, mapActionPlanIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertActionPlanSharingRecords (mapActionPlanIdToAffiliate, mapGroupNameToId, mapActionPlanIdToRestricted);
    }
    
    /*    
    *
    *Method resetRelationshipShareRecords
    *@param : Set<Id> (relationshipIds)
    *@param : List<String> OldAffiliations
    *It resets the share records based on the their account Affiliation.
    *
    */
    public static void resetRelationshipShareRecords(Set<Id> relationshipIds, List<String> OldAffiliations){
        List<String> groupNames = new List<String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        Map<Id,rC_Bios__Relationship__c> mapRelationshipIdToRelationship = new Map<Id,rC_Bios__Relationship__c>();
        Map<Id,Boolean> mapRelationshipIdToRestricted = new Map<Id,Boolean>(); 
        
        // Collect the RelationshipIdToRelationship and collect the affiliations
        for(rC_Bios__Relationship__c mapRe: [SELECT Id, rC_Bios__Opportunity__r.account.Restricted_Account__c, rC_Bios__Contact_1__r.Account.Restricted_Account__c, rC_Bios__Contact_2__r.Account.Restricted_Account__c, rC_Bios__Account_1__r.Restricted_Account__c, rC_Bios__Account_2__r.Restricted_Account__c,
                                             rC_Bios__Opportunity__c, rC_Bios__Account_1__c, rC_Bios__Account_2__c, rC_Bios__Account_1__r.Affiliation__c, rC_Bios__Opportunity__r.account.Affiliation__c, rC_Bios__Contact_2__r.accountId, rC_Bios__Contact_2__r.account.Affiliation__c, rC_Bios__Contact_1__r.accountId, rC_Bios__Contact_1__r.account.Affiliation__c, rC_Bios__Account_2__r.Affiliation__c FROM rC_Bios__Relationship__c WHERE Id =: relationshipIds]){
                                                 mapRelationshipIdToRelationship.put(mapRe.Id,mapRe);
                                                 if(mapRe.rC_Bios__Account_1__c != null && mapRe.rC_Bios__Account_1__r.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Account_1__r.Affiliation__c);
                                                 if(mapRe.rC_Bios__Account_2__c != null && mapRe.rC_Bios__Account_2__r.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Account_2__r.Affiliation__c);
                                                 if(mapRe.rC_Bios__Contact_1__c != null && mapRe.rC_Bios__Contact_1__r.account.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Contact_1__r.account.Affiliation__c);
                                                 if(mapRe.rC_Bios__Contact_2__c != null &&  mapRe.rC_Bios__Contact_2__r.account.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Contact_2__r.account.Affiliation__c);
                                                 if(mapRe.rC_Bios__Opportunity__c != null && mapRe.rC_Bios__Opportunity__r.account.Affiliation__c != null)
                                                     groupNames.add(mapRe.rC_Bios__Opportunity__r.account.Affiliation__c);
                                                 
                                                 if(mapRe.rC_Bios__Account_1__r.Restricted_Account__c == true || mapRe.rC_Bios__Account_2__r.Restricted_Account__c == true ||
                                                    mapRe.rC_Bios__Contact_1__r.Account.Restricted_Account__c == true || mapRe.rC_Bios__Contact_2__r.Account.Restricted_Account__c == true ||
                                                    mapRe.rC_Bios__Opportunity__r.account.Restricted_Account__c == true){
                                                        
                                                        mapRelationshipIdToRestricted.put(mapRe.Id,true);
                                                    }
                                                 else{
                                                     mapRelationshipIdToRestricted.put(mapRe.Id,false);
                                                 }
                                             }
        
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: groupNames OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: National]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        RecordAccessUtility.deleteRelationshipSharingRecords (mapRelationshipIdToRelationship, OldAffiliations, mapGroupNameToId, mapRelationshipIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertRelationshipSharingRecords (mapRelationshipIdToRelationship, mapGroupNameToId, mapRelationshipIdToRestricted);
    }
    
    /*    
    *
    *Method createDocumentAttachmentTask 
    *@param : List<Opportunity> (Oppties)
    *It creates tasks for Document Attachment on Opportunity
    *
    */
    public static void createDocumentAttachmentTask(Map<Id, Opportunity> opptyLstToCreateDocAttachTask) {
        List<Task> tsksToInsert = new List<Task>();
        Map<Id, Id> opptyToTskMap = new Map<Id, Id>();
        for(Task objTsk : [SELECT Id, Subject, WhatId FROM Task WHERE WhatId IN: opptyLstToCreateDocAttachTask.KeySet()]) {
            if(objTsk.WhatId.getSobjectType() == Opportunity.SobjectType && objTsk.Subject == Label.Donation_Backup_Documentation_Subject) {
                opptyToTskMap.put(objTsk.WhatId, objTsk.Id);
            }
        }
        
        for(Opportunity objOppty : opptyLstToCreateDocAttachTask.values()) {
            if(!opptyToTskMap.containsKey(objOppty.Id)) {
                Task newTsk = new Task();
                newTsk.OwnerId = objOppty.OwnerId;
                newTsk.Subject = Label.Donation_Backup_Documentation_Subject;
                newTsk.WhatId = objOppty.Id;
                newTsk.Description = Label.Donation_Backup_Documentation_Desc1+ '<br/>'+Label.Donation_Backup_Documentation_Desc2;
                tsksToInsert.add(newTsk);
            }
        }
        
        if(!tsksToInsert.isEmpty()) {
            try{
                insert tsksToInsert;
            } catch(Exception e) {
                    apexLogHandler.apexLog log = new apexLogHandler.apexLog('OpportunityManager','createDocumentAttachmentTask',e.getMessage());
                    log.logException(e);
                    log.saveLogs();
                }
        }
    }
    
    
    public static Map<Id,Opportunity> updateChildOpportunityFromBatchLog(List<Opportunity> opptyLst, Map<Id, Opportunity> oldMap,
                  List<Opportunity> listOfChildOpps, Map<Id,Opportunity> mapUpdateOpportunities) {
        map<Id, list<Opportunity>> parentToChildOpportunities = new map<Id, list<Opportunity>>();
        for(Opportunity opp : listOfChildOpps) {
            if(!parentToChildOpportunities.containsKey(opp.rC_Giving__Parent__c)) {
                parentToChildOpportunities.put(opp.rC_Giving__Parent__c, new list<Opportunity>()); 
            }
            parentToChildOpportunities.get(opp.rC_Giving__Parent__c).add(opp);                                
        }

        list<Opportunity> tempOppList = new list<Opportunity>();
        for(Opportunity objOppty : opptyLst) {
            if(parentToChildOpportunities.containsKey(objOppty.Id)) {
                tempOppList = parentToChildOpportunities.get(objOppty.Id);
                for(Opportunity opp : tempOppList) {
                    if(objOppty.Batch_Log__c != null && objOppty.stageName.equalsIgnoreCase('Completed')) {//ACLU:77940 :: Added a condition to check stagename = completed
                        opp.Batch_Log__c = objOppty.Batch_Log__c;
                    }
                    if(objOppty.Deposit_Site__c != null) {
                        opp.Deposit_Site__c = objOppty.Deposit_Site__c;
                    }
                    if(objOppty.Batch_Sequence__c != null) {
                        opp.Batch_Sequence__c = objOppty.Batch_Sequence__c;
                    }
                    if(objOppty.Batch_Date__c != null) {
                        opp.Batch_Date__c = objOppty.Batch_Date__c;
                    }
                    if(objOppty.Bank_Date__c != null) {
                        opp.Bank_Date__c = objOppty.Bank_Date__c;
                    }
                    if(objOppty.Payment_Subtype__c != null) {
                        opp.Payment_Subtype__c = objOppty.Payment_Subtype__c;
                    }
                    mapUpdateOpportunities.put(opp.Id,opp);
                }
                //childOpportunitiesToUpdate.addAll(tempOppList);
            }
        }
        /*if(!childOpportunitiesToUpdate.isEmpty()) {
            try{
                update childOpportunitiesToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('OpportunityManager','updateChildOpportunityFromBatchLog',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }*/
        return mapUpdateOpportunities;
    }

    public static void getTransactionMappedFromParent(Opportunity child,Opportunity parentOpp) {
            if(parentOpp.Batch_Log__c != null) {//ACLU:77940 :: Added a condition to check stagename = completed
                child.Batch_Log__c = parentOpp.Batch_Log__c;
            }if(parentOpp.Batch_Sequence__c != null) {
                child.Batch_Sequence__c = parentOpp.Batch_Sequence__c;
            }if(parentOpp.Batch_Date__c != null) {
                child.Batch_Date__c = parentOpp.Batch_Date__c;
            }if(parentOpp.Deposit_Site__c != null) {
                child.Deposit_Site__c =parentOpp.Deposit_Site__c;
            }if(parentOpp.Bank_Date__c != null) {
                child.Bank_Date__c = parentOpp.Bank_Date__c;
            }if(parentOpp.Payment_Subtype__c != null) {
                child.Payment_Subtype__c = parentOpp.Payment_Subtype__c;
            }
    }
    
     /*
    *
    *Method: resetConfidential
    *@param : Map<Id,String> confidentialIdsToOldAffiliations
    *@description : Method which recalculates as per the respective Affiliation__c
    *
    */ 
    
    public static void resetConfidential(Set<Id> confidentialIds, List<String> OldAffiliations){
        map<Id,String> mapConfidentialIdToOldAffiliation = new map<Id,String> ();
        map<Id,String> mapConfidentialIdToNewAffiliation = new map<Id,String> ();
        map<Id,Boolean> mapProspectIdToRestricted = new map<Id,Boolean>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        
        for(Confidential_Data__c cnf: [SELECT Id, Name, Opportunity__c, Opportunity__r.Account.Affiliation__c, Opportunity__r.Account.Restricted_Account__c FROM Confidential_Data__c where Id =: confidentialIds]){
            mapConfidentialIdToNewAffiliation.put(cnf.Id, cnf.Opportunity__r.Account.Affiliation__c);
            mapProspectIdToRestricted.put(cnf.Id, cnf.Opportunity__r.Account.Restricted_Account__c);
        }
        
        // Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapConfidentialIdToNewAffiliation.values() OR Name =:OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        //Delete the Old affiliations records.
        ConfDataTriggerHandler.deleteConfidentialSharingRecords (mapConfidentialIdToNewAffiliation.KeySet(), OldAffiliations, mapGroupNameToId, mapProspectIdToRestricted);
        // Insert the new Affiliations records.
        ConfDataTriggerHandler.InsertConfidentialShareRecords (mapConfidentialIdToNewAffiliation, mapGroupNameToId, mapProspectIdToRestricted);
    }
    
    public static void populateDepositSite(list<Opportunity> listOfOppsFromGivingWizard, map<String, ProgramType_DepositSite_Defaults__c> depositSiteCustomSettingMap) {
        Map<String, String> depositSiteMap = new Map<String, String>();
        for(String str : depositSiteCustomSettingMap.keySet()) {
            depositSiteMap.put(depositSiteCustomSettingMap.get(str).Program_Type__c + '~' + depositSiteCustomSettingMap.get(str).Payment_Method__c, depositSiteCustomSettingMap.get(str).Deposit_Site__c);
        }
        for(Opportunity opp : listOfOppsFromGivingWizard) {
            if(!String.isBlank(opp.Program_Type__c) && opp.rC_Giving__Payment_Method__c != null && depositSiteMap.containsKey(opp.Program_Type__c + '~' + opp.rC_Giving__Payment_Method__c)) {
                opp.Deposit_Site__c = depositSiteMap.get(opp.Program_Type__c + '~' + opp.rC_Giving__Payment_Method__c);
            }
        }
    }
    
    public static void setOpportunityName(list<Opportunity> listOfOpportunitiesForNameUpdate) {
        for(Opportunity opp : listOfOpportunitiesForNameUpdate) {
            String name = opp.rC_Giving__Account_Name__c + ': ';
            if(opp.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) {
                name += opp.RecordTypeId == OPPORTUNITY_RT_DONATION_Id ? ACLU_Constants.CONST_RCDTYPE_DONATION : ACLU_Constants.CONST_RCDTYPE_PLEDGE;
                if(opp.rC_Giving__Is_Sustainer__c) {
                    name += ' Sustainer';
                }
                name += ' ' + opp.CloseDate.year();
            } else if(opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) {
                name += opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id ? ACLU_Constants.CONST_RCDTYPE_DONATION : ACLU_Constants.CONST_RCDTYPE_PLEDGE;
                if(opp.rC_Giving__Parent_Name__c.contains('Sustainer')) {
                    name += ' Sustainer';
                }
                name += ' ' + opp.CloseDate.year();
                name += ' ' + opp.rC_Giving__Transaction_Type__c;
                name += ' • ' + Datetime.newInstance(opp.CloseDate.year(), opp.CloseDate.month(), opp.CloseDate.day()).format('yyyy-MM-dd');
            } else if(opp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) {
                name += ACLU_Constants.CONST_RCDTYPE_SOFTCREDIT + ' ' + opp.CloseDate.year();
            }
            opp.Name = name;
        }
        
    }

    
    /*
    *
    *Method: setBypassCalculationsPerCampaign
    *@param : (List<Opportunity> opps, List<String> campaignIds
    *@description : Update Bypass Calculations field if opportunity's campaign matches provided criteria
    *
    */ 

    public static void setBypassCalculationsPerCampaign (List<Opportunity> opps, Set<String> campaignIds) {
        List<Id> campaignIdsToByPass = new List<Id>();
        Set<String> affiliatesToBypass = new Set<String>{'FN - Foundation National','UN - Union National'};
        
        List<Campaign> byPassCampaigns = [Select Id from Campaign where Id in :campaignIds and rC_Giving__Affiliation__c in :affiliatesToBypass and rC_Giving__Campaign_Type__c = 'B - Benefit'];
        if (!byPassCampaigns.isEmpty()) {
            for (Campaign camp : byPassCampaigns) {
                campaignIdsToByPass.add(camp.Id);
            }
        }
		
	    if (!campaignIdsToByPass.isEmpty()) {
            for (Opportunity opp : opps) {
                if (opp.campaignId != null && campaignIdsToByPass.contains(opp.campaignId) || 
                    opp.CampaignIdText__c != null && campaignIdsToByPass.contains(opp.CampaignIdText__c)) {
                        opp.Bypass_Calculations__c = TRUE;
                }
            }
	    }
    }
    //ACLU:77940 :: Update batchlog details of child list from a parent list
    public static void setTransactionBatchFieldsFromParent(Set<Opportunity> childOppList,Map<id,Opportunity> parentOppMap) {
        for(Opportunity child :childOppList) { 
            Opportunity parentOpp;
            if(parentOppMap.containsKey(child.rC_Giving__Parent__c)) {
                parentOpp = parentOppMap.get(child.rC_Giving__Parent__c);
            }if(parentOpp!= null) {
                if(parentOpp.Batch_Log__c != null) {
                child.Batch_Log__c = parentOpp.Batch_Log__c;
                }if(parentOpp.Batch_Sequence__c != null) {
                    child.Batch_Sequence__c = parentOpp.Batch_Sequence__c;
                }if(parentOpp.Batch_Date__c != null) {
                    child.Batch_Date__c = parentOpp.Batch_Date__c;
                }if(parentOpp.Deposit_Site__c != null) {
                    child.Deposit_Site__c =parentOpp.Deposit_Site__c;
                }if(parentOpp.Bank_Date__c != null) {
                    child.Bank_Date__c = parentOpp.Bank_Date__c;
                }if(parentOpp.Payment_Subtype__c != null) {
                    child.Payment_Subtype__c = parentOpp.Payment_Subtype__c;
                } 
            }
        }
    } 
}