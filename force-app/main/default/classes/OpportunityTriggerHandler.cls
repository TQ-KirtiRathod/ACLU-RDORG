/*
*
*Name  :  OpportunityTriggerHandler
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 15, 2016
*Purpose : OpportunityTriggerHandler is the handler class of OpportunityTrigger. 
           Contains all the trigger operations like insert, update, delete, before, after.  
           This class does call out to several helper classes which contains specific logic for field updates.  
           See supplemental documentation for info on the logic contained in this class."
*
*Modified By: Amar Kulkarni (rC) :: 09-Jul-18
*Desc: I-57114 - Operational Source Codes not applied to sustainer pledge payment charges
**Chnage Log: Traction(Mounica V)  BGE-22, 12/2/2019 : Commented the call to flagMembershipShareCodeReset method
              Traction(Nchandwani), ACL-25, 28May2020 Added method to assocaite payment/transaction with BUP
              Traction(Nchandwani), BGE-102/ACL-001: Removed existing logic to populate Market Source fields
              Traction(Nchandwani), BGE-6/ACL-64: Added after update logic to update Sharing_Code_Description__c
* Ticket#  Modified Date       Modified By      Description
* #67314    06-Feb-2020         SFDO            - Added the batchlog type = Vendor in the if condition
* #77940    24-June-2020        SFDO           - Added a if block to map batch log on transaction when it gets completed instead of open stage and Adjustment code != D
*/
public class OpportunityTriggerHandler {

    public static boolean fireChatterFeed{get;set;}
    private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static final String OPPORTUNITY_RT_SOFT_CREDIT_Id;
    private static final String OPPORTUNITY_RT_TRANSACTION_Id;
    private static final String OPPORTUNITY_RT_PROPOSAL_ID;
    private static final String OPPORTUNITY_RT_DONATION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_Id;
    private static final String OPPORTUNITY_RT_GRANT_Id;
    private static final String OPPORTUNITY_RT_ADJUSTMENT_Id;
    private static Set<String> setOfSharingCodesForMembershipCampaign;
    private static list<RSFUtility.fieldDefinition> portFieldDefinitions;//this is for portfolio object rollups
    private static list<RSFUtility.fieldDefinition> pGFieldDefinitions;
    private static list<RSFUtility.fieldDefinition> oppFieldDefinitionsExpectedAmt;
    private static list<RSFUtility.fieldDefinition> oppFieldDefinitionsClosedAmt;
    private static Boolean hasGLOverridePS = false;
    private static User loggedInUser;
    private static String currentUserProfileName;
    private static Set<String> unAllowedAffiliations = new Set<String>{'UN - Union National', 'FN - Foundation National', 
                                                                        'EN - Endowment Bequest National', 
                                                                        'National Acquisition'};
    private static Set<String> allowedCampaignLevels = new Set<String>{'K', 'G', 'D'};
    private static Date dateOfToday;
    private static Date dateForSetExpirationMethod;
    private static Map<String,List<String>> mapOfKeyVsDepositSiteValue = new Map<String,List<String>>();
    private static Schema.DescribeFieldResult fieldResult;
    private static String currentUserAffiliate;
    public static Boolean IsSourceCodeUpdatedFromDonation;
    public static Boolean calculateFeesAndNetAmount;
    public static Boolean donationConvertedToPledge;
    public static list<Id> listContact;

    //public static list<AsyncRequest__c> newAsyncRequest = new list<AsyncRequest__c>();
    public static double oppAsyncBatchMax;
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            oppAsyncBatchMax = q.Batch_Size_Email__c;
        } else {
            oppAsyncBatchMax = 100;
        }
    }
    
    static {
        calculateFeesAndNetAmount = TRUE;
        donationConvertedToPledge = false;
        dateOfToday = System.today();
        IsSourceCodeUpdatedFromDonation = false;
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        OPPORTUNITY_RT_PROPOSAL_ID = opptyRTMap.get('Proposal').getRecordTypeId();
        OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        OPPORTUNITY_RT_GRANT_Id = opptyRTMap.get('Grant').getRecordTypeId();
        OPPORTUNITY_RT_ADJUSTMENT_Id = opptyRTMap.get('Adjustment').getRecordTypeId();

        fieldResult = Opportunity.Deposit_Site__c.getDescribe();
        setOfSharingCodesForMembershipCampaign = new Set<String>();
        dateForSetExpirationMethod = Date.newInstance(4000,12, 31);
        for(Sharing_Codes_For_Membership_Campaign__c shareCode : Sharing_Codes_For_Membership_Campaign__c.getAll().values()) {
            setOfSharingCodesForMembershipCampaign.add(shareCode.Code_Value__c);
        }
        for( Schema.PicklistEntry f : fieldResult.getPicklistValues()) {
            String key = (f.getValue()).contains('_') && ((f.getValue()).split('_')[0]).length() == 2
                       ? (f.getValue()).split('_')[0]
                       : '';
            
            if(key != '') {
               
              if(!mapOfKeyVsDepositSiteValue.containsKey(key)) {
                mapOfKeyVsDepositSiteValue.put(key,new List<String>());
                 
              }
              mapOfKeyVsDepositSiteValue.get(key).add(f.getValue());
            }
        }
        portFieldDefinitions = new list<RSFUtility.fieldDefinition> {
          new RSFUtility.fieldDefinition('SUM', 'rC_Giving__Requested_Amount__c','Sum_of_Requested_Amount__c'),
          new RSFUtility.fieldDefinition('SUM', 'rC_Giving__Projected_Amount__c','Sum_of_Projected_Amount__c'),
          new RSFUtility.fieldDefinition('SUM', 'Projected_Additional__c','Sum_of_the_Projected_Additional_Amount__c'),
          new RSFUtility.fieldDefinition('SUM', 'Closed_Amount_Total__c','Sum_of_Closed_Amount__c'),
          new RSFUtility.fieldDefinition('SUM', 'Outstanding_Pledge_Amount__c','Sum_of_Outstanding_Pledge_Amount__c'),
          new RSFUtility.fieldDefinition('SUM', 'Expected_Giving_Amount_Total__c','Sum_of_Expected_Giving_Amount__c')
        };
          
        pGFieldDefinitions = new list<RSFUtility.fieldDefinition> {
          new RSFUtility.fieldDefinition('SUM', 'rC_Giving__Expected_Giving_Amount__c','rC_Giving__Giving_Amount__c')
        };
        oppFieldDefinitionsExpectedAmt = new list<RSFUtility.fieldDefinition> {
          new RSFUtility.fieldDefinition('SUM', 'Amount','Expected_Giving_Amount_Payments__c')
        };
        oppFieldDefinitionsClosedAmt = new list<RSFUtility.fieldDefinition> {
          new RSFUtility.fieldDefinition('SUM', 'Amount','Closed_Amount_Payments__c')
        };
        
        loggedInUser = [select Id, Profile.Name, Is_Affiliate_User__c,Primary_Affiliate__c from User where id = :Userinfo.getUserId()];
        currentUserProfileName = loggedInUser.Profile.Name;
        currentUserAffiliate = loggedInUser.Primary_Affiliate__c != null ? (loggedInUser.Primary_Affiliate__c).subString(0,2) : '';
        for(PermissionSetAssignment psa: [SELECT Id, PermissionSet.Name,AssigneeId
                                         FROM PermissionSetAssignment
                                         WHERE AssigneeId = :loggedInUser.Id]) {
            if(psa.PermissionSet.Name == 'GL_Override') {
                hasGLOverridePS = True;
                break;
            }
        }
    }

    public OpportunityTriggerHandler(){
        fireChatterFeed = false;
    }

    /*
    *Method mainEntry
    *@description : defining all trigger events
    */
    public static void mainEntry(List<opportunity> newList, List<opportunity> oldList, Map<Id,opportunity> newMap, 
                                 Map<Id,opportunity> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, 
                                 Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //If Trigger is active
        if(TriggerState.isActive('Opportunity_Trigger')
          && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) ) {

             if(isBefore) {
                if(isInsert) {
                    beforeInsert(newList);
                }
                if(isUpdate
                ) {
                    beforeUpdate(newMap, oldMap);
                }
            }

            if(isAfter){
                if(isInsert){
                    fireChatterFeed = true;
                    afterInsert(newList);
                }
                if(isUpdate) {
                  afterUpdate(newList, oldMap);
                }
                if(isDelete) {
                    afterDelete(oldList);
                }

                if(isUndelete) {
                    afterUndelete(newList);
                }
            }
        }
    }

    /*
    *
    *Method beforeInsert
    *@param : newlistOpp
    *@description : calls on beforeInsert
    *
    */
    public static void beforeInsert( List<opportunity> newlistOpp ){
        Set<String> campaignIds = new Set<String>();
        Set<Id> setOfParentOrRelatedTransactionIds = new Set<Id>();
        Set<Id> setOfAccountIds= new Set<Id>();
        Set<Id> setOfPaymentMethodIds = new Set<Id>();
        Map<Id,Opportunity> mapOfParentOppIdVsParentOpportunity = new Map<Id,Opportunity>();
        Map<Id,Account> mapOfAccountIdVsAccount = new Map<Id,Account>();
        Map<Id,rC_Giving__Payment_Method__c> mapOfPaymentMethodIdVsPaymentMethod = new Map<Id,rC_Giving__Payment_Method__c>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Opportunity> listOfSoftCredits = new List<Opportunity>();
        List<Opportunity> listOfOppsFromGivingWizard = new List<Opportunity>();
        List<Opportunity> listOfOpportunities = new List<Opportunity>();
        Map<String, ProgramType_DepositSite_Defaults__c> depositSiteCustomSettingMap = new Map<String, ProgramType_DepositSite_Defaults__c>();
        rC_Giving__Opportunity_Setting__c oppSetting = rC_Giving__Opportunity_Setting__c.getInstance();
        list<Opportunity> listOfOpportunitiesForNameUpdate = new list<Opportunity>();
        Set<Opportunity> childOppList = new Set<Opportunity>();
        //Set<Id> parentOppIdSet = new Set<Id>();
        
        //Added as part of BGE-06/ACL-064 
        Map<String,String> mapSharecodetoDescription = getSharingCodeMap();
        for(Opportunity objOppty: newlistOpp) {
            
            //Start: BGE-06/ACL-064: Nchandwani, Update sharing Description based on share code
            if( objOppty.StageName == 'Completed' && String.isNotBlank( objOppty.Sharing_Code__c ) ){
            
                objOppty.Sharing_Code_Description__c =  mapSharecodetoDescription.get(objOppty.Sharing_Code__c);    
                            
            }//BGE-06/ACL-064: END
        
            //Default Acknowledgement status I-315069
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id || 
                objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || 
                objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) && String.isBlank(objOppty.Acknowledgment_Status__c) ) {
                objOppty.Acknowledgment_Status__c = 'N - Not Acknowledged';
            }
            /*if( objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id){
                parentOppIdSet.add(objOppty.rC_Giving__Parent__c);
            }*/

          // Setting Review Status to Pending Submission.  
          objOppty.Review_Status__c = 'Pending Submission';
          if( objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id){
              System.debug(LoggingLevel.Error, '===========before isnert===='+objOppty.stagename);
          }
          // Popualte Record Type, Stage and Amount for Soft Credits
          if(objOppty.isSoft_Credit__c) {
            objOppty.RecordtypeId =  OPPORTUNITY_RT_SOFT_CREDIT_Id;
            //Removed from here and added this after the Prior Amount is getting set.
            //objOppty.Amount = objOppty.Prior_Amount__c!= null ? objOppty.Prior_Amount__c : objOppty.Amount; 
            objOppty.StageName = 'Completed';
          }

          if(objOppty.rC_Giving__Parent__c != null){
            setOfParentOrRelatedTransactionIds.add(objOppty.rC_Giving__Parent__c);
          }

          if(objOppty.accountId != null && objOppty.Isclosed) {
            setOfAccountIds.add(objOppty.accountId);
          }

          if(objOppty.Update_Payment_Method__c != null && objOppty.AccountId != null) {
            setOfPaymentMethodIds.add(objOppty.Update_Payment_Method__c);
          }

          if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.Related_Transaction__c!= null) {
            setOfParentOrRelatedTransactionIds.add(objOppty.Related_Transaction__c);
          }
          if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && objOppty.rC_Giving__Is_Sustainer__c) {
              listOfOppsFromGivingWizard.add(objOppty);
          }
          //Added by Bhavesh For T-647782
          if( objOppty.recordTypeId == OPPORTUNITY_RT_DONATION_Id ||  objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_Id
            || objOppty.recordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id
          ){
              if( objOppty.recordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id || 
                (objOppty.Low_Amount__c != null && objOppty.High_Amount__c != null 
                && objOppty.rC_Giving__Number_Of_Shares__c != null)
              ){
                    getTaxValueCalculations( objOppty, null);
              } else if( objOppty.Tax_Value__c == NULL 
                         || ( objOppty.Tax_Value__c != NULL && objOppty.Split_Sequence__c != NULL )//added OR condition by Bhavesh,I-305387
              ){
                  objOppty.Tax_Value__c = objOppty.rC_Giving__Giving_Amount__c;
              }
          }
          //End T-647782
          
          //start T-680911
          if(oppSetting.rC_Giving__Disable_UpdateName__c) {
            if((objOppty.recordTypeId == OPPORTUNITY_RT_DONATION_Id ||  objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_Id) && objOppty.rC_Giving__Is_Giving__c &&
                !objOppty.rC_Giving__Is_Giving_Transaction__c) {
                listOfOpportunitiesForNameUpdate.add(objOppty);
            } else if((objOppty.recordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                && !objOppty.rC_Giving__Is_Giving__c && objOppty.rC_Giving__Is_Giving_Transaction__c) {
                listOfOpportunitiesForNameUpdate.add(objOppty);
            } else if(objOppty.recordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) {
                listOfOpportunitiesForNameUpdate.add(objOppty);
            }
          }
          // end T-680911
          //ACLU #77940 : Added the condition - Maps parent's batch log to transaction batch log id
          if((objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
            || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)
            && objOppty.Adjustment_Code__c != 'D'
            && objOppty.StageName.equalsIgnoreCase('Completed')){
              childOppList.add(objOppty);
          }
        }
        //Set Opportunity Name
        if(!listOfOpportunitiesForNameUpdate.isEmpty()) {
            OpportunityManager.setOpportunityName(listOfOpportunitiesForNameUpdate);
        }
        // Populate Map For ParentOpportunities, common SOQl
        if(setOfParentOrRelatedTransactionIds.size() >0) {
          for(Opportunity opp : [SELECT Id, Bypass_Calculations__c, rC_Giving__Source_Code__c, Deposit_Site__c, rC_Giving__Ticker_Symbol__c,rC_Giving__Number_Of_Shares__c,High_Amount__c,Low_Amount__c,Types_of_shares__c,
                                    RPT_Package_Code__c, Restriction__c, Program_Type__c, Campaign_Type__c, Fund__c,
                                    Fundraising_Department__c, Account_Code__c, CampaignId, CampaignIdText__c,SB_Donation_Id__c,
                                    Acknowledgment_Code__c,Tax_Date__c,Tax_Value__c,rC_Giving__Giving_Amount__c,//T-647782-added tax value
                                    Batch_Log__c,Batch_Sequence__c,Batch_Date__c,Bank_Date__c,Payment_Subtype__c,Adjustment_Code__c //ACLU :#77940 - Added fields
                                 FROM Opportunity
                                 WHERE (Id IN : setOfParentOrRelatedTransactionIds)]) {
            mapOfParentOppIdVsParentOpportunity.put(opp.Id,opp);
          }
        }

        // Populate Maps For Account, common SOQL
        if(setOfAccountIds.size() > 0) {
          for(Account objAcc : [SELECT Id, Affiliation__c
                                FROM Account
                                where Id IN : setOfAccountIds]) {
            mapOfAccountIdVsAccount.put(objAcc.Id,objAcc);
          }
        }

        // Populate Maps For Payment Methods, common SOQL
        if(setOfPaymentMethodIds.size() > 0) {
          for(rC_Giving__Payment_Method__c paymentMethod : [SELECT Id, rC_Giving__Account__c
                                                            FROM rC_Giving__Payment_Method__c
                                                            WHERE Id IN : setOfPaymentMethodIds
                                                            AND rC_Giving__Account__c != NULL]) {
            mapOfPaymentMethodIdVsPaymentMethod.put(paymentMethod.Id,paymentMethod);
          }
        }

        //Populate map from Custom setting
        if(listOfOppsFromGivingWizard.size() > 0) {
            depositSiteCustomSettingMap = ProgramType_DepositSite_Defaults__c.getAll();
        }

        for(Opportunity objOppty: newlistOpp){
            // Populate the Campaign On Sustainer Pledges
            if(objOppty.Upgrade_Source__c != null && objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id 
                && (objOppty.rC_Giving__Is_Sustainer__c)) {
              objOppty.CampaignId = objOppty.Upgrade_Source__c;
            }
            
            //Populate Tax Date for Pledge Payments
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.Tax_Date__c == null 
                && objOppty.CloseDate != null) {
              objOppty.Tax_Date__c = objOppty.CloseDate; 
            }
            
            // Validate Opportunity is Not Updated When Posted to GL is True
            if(objOppty.Posted_to_GL_Checkbox__c && (!hasGLOverridePS &&  currentUserProfileName != 'System Administrator')) {
                objOppty.addError(Label.Error_On_Opportunity_When_It_Is_Updated_After_Posted_to_GL_Is_True);
            }
            
            //Populate the Acknowledgement Status and Acknowledgement Date
            if(objOppty.rC_Giving__Payment_Method__c != null && objOppty.rC_Giving__Payment_Method__c == 'Securities') {
              objOppty.Acknowledgment_Status__c = 'A - Acknowledged';
              objOppty.rC_Giving__Acknowledged_Date__c = objOppty.CloseDate != null ? objOppty.CloseDate : objOppty.rC_Giving__Acknowledged_Date__c ;
            }
            
            //Populate Source Code and  CampaignIdText and Restriction for Child Opportuntities
            if(objOppty.rC_Giving__Parent__c != null && objOppty.RecordTypeId != OPPORTUNITY_RT_SOFT_CREDIT_Id) {
              objOppty.rC_Giving__Source_Code__c = objOppty.rC_Giving__Source_Code__c == null &&
                                                   mapOfParentOppIdVsParentOpportunity!= null &&
                                                   mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                                                   mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).rC_Giving__Source_Code__c != null
                                                 ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).rC_Giving__Source_Code__c
                                                 : objOppty.rC_Giving__Source_Code__c;
              objOppty.CampaignIdText__c =  objOppty.CampaignIdText__c == null && mapOfParentOppIdVsParentOpportunity!= null &&
                                            mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                                            mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).CampaignId != null
                                         ?  mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).CampaignId
                                         :  objOppty.CampaignIdText__c;
              if(objOppty.Restriction__c == null) {
                objOppty.Restriction__c =  mapOfParentOppIdVsParentOpportunity!= null &&
                                           mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                                           mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Restriction__c != null
                                         ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Restriction__c
                                         : objOppty.Restriction__c;
              }
              if(objOppty.Acknowledgment_Code__c == null) {
                objOppty.Acknowledgment_Code__c = mapOfParentOppIdVsParentOpportunity!= null &&
                                                   mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                                                   mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Acknowledgment_Code__c != null
                                                 ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Acknowledgment_Code__c
                                                 : objOppty.Acknowledgment_Code__c;
              } 
              if(objOppty.Account_Code__c == null) { //BGE-61 
                objOppty.Account_Code__c = mapOfParentOppIdVsParentOpportunity!= null &&
                                                   mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                                                   mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Account_Code__c != null
                                                 ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Account_Code__c
                                                 : objOppty.Account_Code__c;
              } 
               if(objOppty.Fund__c == null) {
                objOppty.Fund__c = mapOfParentOppIdVsParentOpportunity!= null &&
                                                   mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                                                   mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Fund__c != null
                                                 ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Fund__c
                                                 : objOppty.Fund__c;
              } //BGE-61 END
            }
            else if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.Related_Transaction__c != null) {
              objOppty.rC_Giving__Source_Code__c = mapOfParentOppIdVsParentOpportunity != null &&
                                                   mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.Related_Transaction__c) &&
                                                   mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).rC_Giving__Source_Code__c != null
                                                 ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).rC_Giving__Source_Code__c
                                                 : objOppty.rC_Giving__Source_Code__c;
              objOppty.CampaignIdText__c =         objOppty.CampaignIdText__c == null && mapOfParentOppIdVsParentOpportunity != null &&
                                                   mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.Related_Transaction__c) &&
                                                   mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).CampaignIdText__c != null
                                                 ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).CampaignIdText__c
                                                 : objOppty.CampaignIdText__c;
            }

            // Populate Prior & Original Source Code and Prior
            objOppty.Prior_Source_Code__c = objOppty.rC_Giving__Source_Code__c != null ? objOppty.rC_Giving__Source_Code__c: objOppty.Prior_Source_Code__c ;
            objOppty.Original_Source_Code__c = objOppty.rC_Giving__Source_Code__c != null ? objOppty.rC_Giving__Source_Code__c : objOppty.Original_Source_Code__c;

            // Populate Deposit Site for Pledge Payments and Transactions
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) &&
                (objOppty.Deposit_Site__c == null)) {
              objOppty.Deposit_Site__c = mapOfParentOppIdVsParentOpportunity != null 
                                            && mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c)
                                            && mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Deposit_Site__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Deposit_Site__c
                                        : objOppty.Deposit_Site__c;
            }
            
            //Populate Tax Date for Transactions from Parent Donation
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) 
                && (objOppty.rC_Giving__Parent__c != null) && (objOppty.Tax_Date__c == null)) {
              objOppty.Tax_Date__c = mapOfParentOppIdVsParentOpportunity != null 
                                        && mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c)
                                        && mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Tax_Date__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Tax_Date__c
                                        : objOppty.Tax_Date__c; 
            }

            // Modified by :: roundCorner Inc. :: 22-Oct-2018
            // #60194: Rolling down information from Donation to Transaction
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                && objOppty.rC_Giving__Parent__c != null ) {
                    Opportunity parentOpportunity = mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c);
                    objOppty.rC_Giving__Ticker_Symbol__c = parentOpportunity.rC_Giving__Ticker_Symbol__c;
                    objOppty.rC_Giving__Number_Of_Shares__c = parentOpportunity.rC_Giving__Number_Of_Shares__c;
                    objOppty.High_Amount__c = parentOpportunity.High_Amount__c;
                    objOppty.Low_Amount__c = parentOpportunity.Low_Amount__c;
                    objOppty.Types_of_shares__c = parentOpportunity.Types_of_shares__c;
            }

            // When Child Oppties are inserted then set their by pass cal to true when Parent is true
            if(objOppty.rC_Giving__Parent__c != null && mapOfParentOppIdVsParentOpportunity!= null &&
                 mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) &&
                 mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Bypass_Calculations__c){
              objOppty.Bypass_Calculations__c = True;
            }

            // Populate the Opp Affiliation  field with the Account's affiliation
            if(objOppty.Isclosed == true && (objOppty.accountId != null) && mapOfAccountIdVsAccount != null &&
               (mapOfAccountIdVsAccount.containsKey(objOppty.accountId))
               && (mapOfAccountIdVsAccount.get(objOppty.accountId).Affiliation__c != null) ) {
              objOppty.Account_Affiliation__c = mapOfAccountIdVsAccount.get(objOppty.accountId).Affiliation__c != null ?
                                                mapOfAccountIdVsAccount.get(objOppty.accountId).Affiliation__c.subString(0,2) : '';
            }

            // Populate the Selected Payment Method
            if(objOppty.Update_Payment_Method__c != null && mapOfPaymentMethodIdVsPaymentMethod!= null &&
                mapOfPaymentMethodIdVsPaymentMethod.containsKey(objOppty.Update_Payment_Method__c) &&
                mapOfPaymentMethodIdVsPaymentMethod.get(objOppty.Update_Payment_Method__c).rC_Giving__Account__c != null &&
                mapOfPaymentMethodIdVsPaymentMethod.get(objOppty.Update_Payment_Method__c).rC_Giving__Account__c == objOppty.AccountId) {
              objOppty.rC_Giving__Payment_Method_Selected__c = objOppty.Update_Payment_Method__c;
            }

            // Populate Probability % on Proposals
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_Id && objOppty.Probability__c == null) {
              objOppty.Probability__c = objOppty.rC_Giving__Projected_Amount__c != null && objOppty.rC_Giving__Requested_Amount__c != null &&
                                        objOppty.rC_Giving__Requested_Amount__c != 0
                                      ? (objOppty.rC_Giving__Projected_Amount__c / objOppty.rC_Giving__Requested_Amount__c) * 100
                                      : objOppty.Probability__c;
                if(objOppty.Probability__c > 999) {
                    objOppty.Probability__c = 100;
                }
            }

            //Populate the Projected Amount on Proposals if null
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_Id && objOppty.rC_Giving__Projected_Amount__c == null) {
              objOppty.rC_Giving__Projected_Amount__c = objOppty.Probability__c != null && objOppty.rC_Giving__Requested_Amount__c != null ?
                                                         (objOppty.Probability__c * objOppty.rC_Giving__Requested_Amount__c)/100 :
                                                         objOppty.rC_Giving__Projected_Amount__c;
            }

            // Populate Giving Amount on Sustainer Pledges from Upgrade Amount
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && (objOppty.rC_Giving__Is_Sustainer__c) 
                && objOppty.Upgrade_Amount__c != null && objOppty.rC_Giving__Giving_Amount__c != objOppty.Upgrade_Amount__c) {
              objOppty.rC_Giving__Giving_Amount__c = objOppty.Upgrade_Amount__c;
            }

            // Populate the Original Amount and the Prior Amount
            objOppty.Original_Amount__c = objOppty.rC_Giving__Giving_Amount__c != null ? objOppty.rC_Giving__Giving_Amount__c : objOppty.Original_Amount__c;
            objOppty.Prior_Amount__c = objOppty.rC_Giving__Giving_Amount__c != null ? objOppty.rC_Giving__Giving_Amount__c : objOppty.Prior_Amount__c;

            if(objOppty.isSoft_Credit__c) {
                objOppty.Amount = objOppty.Prior_Amount__c!= null ? objOppty.Prior_Amount__c : objOppty.Amount;
            }
            
            //Populate the Fields For Soft Credits
            // Pledge Payments with RelatedTransaction != null can consider as SoftCredits
            if(objOppty.Related_Transaction__c != null &&   mapOfParentOppIdVsParentOpportunity!= null
                && mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.Related_Transaction__c)) {

               if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id){
                  if(objOppty.Acknowledgment_Code__c == null) {
                  objOppty.Acknowledgment_Code__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Acknowledgment_Code__c != null
                                          ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Acknowledgment_Code__c
                                          : objOppty.Acknowledgment_Code__c;
                  }
               }
               else if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id){
                   objOppty.Deposit_Site__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Deposit_Site__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Deposit_Site__c
                                            : objOppty.Deposit_Site__c;
                   objOppty.RPT_Package_Code__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).RPT_Package_Code__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).RPT_Package_Code__c
                                            : objOppty.RPT_Package_Code__c;
                  if(objOppty.Restriction__c == null) {
                  objOppty.Restriction__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Restriction__c != null
                                          ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Restriction__c
                                          : 'UNDEFINED - Undefined';
                  }
                  if(objOppty.Acknowledgment_Code__c == null) {
                  objOppty.Acknowledgment_Code__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Acknowledgment_Code__c != null
                                          ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Acknowledgment_Code__c
                                          : objOppty.Acknowledgment_Code__c;
                  }
                  objOppty.Program_Type__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Program_Type__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Program_Type__c
                                            : objOppty.Program_Type__c;
                  objOppty.Campaign_Type__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Campaign_Type__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Campaign_Type__c
                                            : objOppty.Campaign_Type__c;

                  objOppty.Fund__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fund__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fund__c
                                            : objOppty.Fund__c;
                  objOppty.Fundraising_Department__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fundraising_Department__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fundraising_Department__c
                                            : objOppty.Fundraising_Department__c;
                  objOppty.Account_Code__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Account_Code__c != null
                                            ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Account_Code__c
                                            : objOppty.Account_Code__c;
              }
              if((objOppty.Manual_Sharing_Code__c == False) && (objOppty.Program_Type__c != Null) && (objOppty.accountId != Null) &&
                 (objOppty.StageName == 'Completed')) {
                listOfSoftCredits.add(objOppty);
              }
            }

            // Set the Exclude from Revenue Sharing field where Deposit Site = Label.Cosmetic_Gift_Deposit_Site
            if(objOppty.Deposit_Site__c != null && objOppty.Deposit_Site__c == Label.Cosmetic_Gift_Deposit_Site) {
              objOppty.Exclude_from_Revenue_Sharing__c = True;
            }

            // Update the Stage last Changed Date
            if(objOppty.StageName != null) {
              objOppty.Stage_Last_Changed_Date__c = dateOfToday;
            }

            // Update the Soft Credit Name
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id ) {
              String closeDateYear = objOppty.closeDate != null ? String.valueOf(objOppty.closeDate.year()) : '';
              String accName = objOppty.rC_Giving__Account_Name__c != null ? objOppty.rC_Giving__Account_Name__c : '';
              objOppty.Name = accName + ': Soft Credit ' + closeDateYear;
            }

            // Populate variables to pass in copyCampaignFieldsAndPopulateSharingFieldsAndRevenueType Method
            if((objOppty.CampaignId != null || objOppty.CampaignIdText__c != null) && (objOppty.RecordTypeId != OPPORTUNITY_RT_SOFT_CREDIT_Id)){
              if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id) {
                campaignIds.add(objOppty.CampaignId);
              }
              else if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) {
                campaignIds.add(objOppty.CampaignIdText__c);
              }
              opportunities.add(objOppty);
            }
            
            //objOppty.RPT_Revenue_Type__c == null && 
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ||
                    objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)) {
                listOfOpportunities.add(objOppty);  //update revenue type
                opportunities.add(objOppty);  //update package code
                campaignIds.add(objOppty.CampaignId);  //needed for OpportunityCampaignManager
            }
            
            //populate RPT_Fund_is_Not_Gen__c - T-632803
            if(objOppty.Fund__c == null || !objOppty.Fund__c.startsWith('GEN')) {
                objOppty.RPT_Fund_is_Not_Gen__c = true;
            }
            
            //Added by Bhavesh For T-647782
            if( objOppty.Tax_Value__c == NULL && mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) 
                && mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Tax_Value__c != null 
            ){
                objOppty.Tax_Value__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).Tax_Value__c;
            }
            if( (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ||
                    objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) && (objOppty.RecordTypeId != OPPORTUNITY_RT_SOFT_CREDIT_Id)
                    && mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.rC_Giving__Parent__c) 
                    && objOppty.Amount != mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c).rC_Giving__Giving_Amount__c)
            {
                objOppty.Tax_Value__c = objOppty.Amount;
            }
            //END T-647782
                
        }
           
        // Method to  copy Fields from Campaign and populate Sharing and Revenue Type fields
        if(!opportunities.IsEmpty()){
            OpportunityCampaignManager.copyCampaignFieldsAndPopulateSharingFields(opportunities, campaignIds,true, null);
        }

        // Method to set Sharing on Soft Credits, as discussed Sharing Fields are populated irrespective of Stage of Soft Credits
        if(!listOfSoftCredits.isEmpty()) {
          RevenueSharingShareCodes.setShareCode(listOfSoftCredits);
        }

        //Method to populate Deposit site on Pledge/Donation
        if(!listOfOppsFromGivingWizard.isEmpty() && !depositSiteCustomSettingMap.keySet().isEmpty()) {
            OpportunityManager.populateDepositSite(listOfOppsFromGivingWizard, depositSiteCustomSettingMap); 
        }
        
        // Method to populate Revenue Type
        if(!listOfOpportunities.isEmpty()) {
          PopulateRevenueType.populateRevenueType(listOfOpportunities); 
        }

        // Method to set the Deposit Site For Pledges & Donations if Current User belongs to an Affiliate and Opp is created from Wizard
        // This will be call after the Program Type has been set by the 'copyCampaignFieldsAndPopulateSharingFields' method
        
        /*for(Opportunity objOppty : newlistOpp) {
          // Populate Deposit Site for Sustainer Pledges
          if(objOppty.Batch_Log__c == null && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id) &&
             objOppty.Program_Type__c == '5' && currentUserAffiliate != '' &&
             (objOppty.rC_Giving__Payment_Method__c == 'Charge Card' || objOppty.rC_Giving__Payment_Method__c == 'EFT'
                   || objOppty.rC_Giving__Payment_Method__c == 'Cash/Check')) {
            objOppty.Deposit_Site__c = mapOfKeyVsDepositSiteValue!= null && mapOfKeyVsDepositSiteValue.containsKey(currentUserAffiliate)
                                     ? mapOfKeyVsDepositSiteValue.get(currentUserAffiliate)[0]
                                     : objOppty.Deposit_Site__c;
          }
        }*/
        
        //T-648895 - Commented for block above to update deposit site according to related campaign's affiliation instead of user's - KM - 11/22/2017
        Set<Id> campaignIdSet = new Set<Id>();
        Map<Id, String> campaignIdToAffiliate = new Map<Id, String>();
        for(Opportunity objOppty : newlistOpp) {
            if(objOppty.CampaignId != null) {
                campaignIdSet.add(objOppty.CampaignId);
            }
        }
        
        if(!campaignIdSet.isEmpty()) {
            for(Campaign camp : [SELECT Id, rC_Giving__Affiliation__c
                                    FROM Campaign
                                    WHERE Id IN : campaignIdSet]) {
                if(!String.isEmpty(camp.rC_Giving__Affiliation__c)) {
                    campaignIdToAffiliate.put(camp.Id, camp.rC_Giving__Affiliation__c);
                }
            }
        }
        
        for(Opportunity objOppty : newlistOpp) {
            String affiliate;
            if(campaignIdToAffiliate.containsKey(objOppty.CampaignId)) {
                affiliate = campaignIdToAffiliate.get(objOppty.CampaignId).subString(0,2);
            }
            if(objOppty.Batch_Log__c == null 
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) && objOppty.rC_Giving__Is_Sustainer__c
                && objOppty.Program_Type__c == '5' && !String.isEmpty(affiliate) &&
                (objOppty.rC_Giving__Payment_Method__c == 'Charge Card' || objOppty.rC_Giving__Payment_Method__c == 'EFT'
                   || objOppty.rC_Giving__Payment_Method__c == 'Cash/Check')) {
                       
                       objOppty.Deposit_Site__c = mapOfKeyVsDepositSiteValue!= null && mapOfKeyVsDepositSiteValue.containsKey(affiliate)
                                     ? mapOfKeyVsDepositSiteValue.get(affiliate)[0]
                                     : objOppty.Deposit_Site__c;
                   }
        }

        OpportunityManager.setBypassCalculationsPerCampaign(newlistOpp,campaignIds);
        //ACLU :: #77940 ::Maps batchlog deatils on transactions
        if(childOppList.size() > 0 && mapOfParentOppIdVsParentOpportunity.size() >0){
            OpportunityManager.setTransactionBatchFieldsFromParent(childOppList,mapOfParentOppIdVsParentOpportunity);
        }
        //getStockGiftCalculations(newlistOpp, null, null);//Added by:Bhavesh:Task: T-647270  
    }  //end beforeInsert

    /*
    *
    *Method afterInsert
    *@param : newLst
    *@description : calls on afterInsert
    *
    */
   private static void afterInsert(List<Opportunity> newLst) {
        List<Account> listOfAccountsWithJointMembershipFlag = new list<Account>();
        List<Opportunity> listOfChildOpps= new List<Opportunity>();
        List<Opportunity> listOfChildOppsForSharingOverride = new List<Opportunity>();
        List<Opportunity> listOfOppsForBatchLog = new List<Opportunity>();
        list<Opportunity> parentOpportunities = new list<Opportunity>();
        Set<Id> accountNonRenewableIds = new Set<Id>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Opportunity> setExpirationDatesOpps = new List<Opportunity>();
        List<opportunity> revenuShareopportunities = new List<opportunity>();
        Set<Id> setToupdateFirstPaymentOnChild = new Set<Id>();
        Map<Id, Opportunity> opptyMapToUpdate = new Map<Id, Opportunity>();
        Map<Id,Id> mapCampaignAccount = new Map<Id,Id>();
        Map<Id,Id> mapAccIdTooppId = new map<Id,Id>();
        Map<Id, Account> mapUpdateAccounts = new map<Id, Account> ();
        Set<Id> portFolioIds = new Set<Id>();
        Set<Id> setOfAccountIdsToUpdate = new Set<Id>();
        Map<Id, Opportunity> mapUpdateOpportunities = new Map<ID, Opportunity>();
        Map<Id, Opportunity> opptyLstToCreateDocAttachTask = new Map<Id, Opportunity>();
        Set<Id> parentOpportunityIds = new Set<Id>();
        List<Opportunity> plannedGivingGifts = new List<Opportunity>();
        Map<Id, rC_Giving__Payment_Method__c> paymentMethods = new Map<Id, rC_Giving__Payment_Method__c>();
        List<Opportunity> oppsToUpdateMerchantName = new List<Opportunity>();
        Set<Id> setOfRelatedTransactionIds = new Set<Id>();
        List<Opportunity> listOfRelatedTransactions = new List<Opportunity>();
        Set<Id> setOfDonationsWithSharingFieldsUpdated = new Set<Id>();
        Set<Id> setOfParentOppIdsToProcess = new Set<Id>();
        List<Opportunity> listOfParentOpps = new List<Opportunity>();
        list<Opportunity> listOfTransactionsForExpectedAmt = new list<Opportunity>();
        list<Opportunity> listOfTransactionsForClosedAmt = new list<Opportunity>();
        Map<Id, Opportunity> parentOpptiesForStock = new Map<Id, Opportunity>();
        Set<String> idsForAsync_Opp = new Set<String>();
        
        //list<Id> idsForAsync_Opp = new list<Id>();
        Integer i=0;
        
        for(Opportunity objOppty :  [
            SELECT Id, closeDate, account.Original_Join_Date__c, account.Membership_Expiration_date__c, 
                  account.Has_Renewed_Before__c, StageName, rC_Giving__Source_Code__c, RecordTypeId, 
                    rC_Giving__Is_Sustainer__c,CampaignId, Sustainer_First_Payment__c, Prior_Source_Code__c, 
                    Original_Source_Code__c, rC_Giving__Parent__c, rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c, 
                    rC_Giving__Parent__r.Sustainer_First_Payment__c, rC_Giving__Parent__r.rC_Giving__Source_Code__c, 
                    LastModifiedDate, rC_Giving__Parent__r.CampaignId, rC_Giving__Planned_Giving__c,
                    rC_Giving__Giving_Amount__c, Original_Amount__c, Prior_Amount__c, Sharing_Code__c, IsClosed,
              accountId, amount,Portfolio__c, rC_Giving__Expected_Giving_Amount__c,
              Account_Affiliation__c, Set_Document_Attached__c, rC_Giving__Payment_Method__c, 
              rC_Giving__Payment_Method_Selected__c, rC_Giving__Payment_Method_Selected__r.rC_Connect__Merchant_Name__c, 
              OwnerId, Campaign_Type__c, Batch_Log__c, Tax_Date__c, 
              Batch_Log__r.Batch_Log_Type__c, Batch_Log__r.Batch_Date__c, Deposit_Site__c, Batch_Sequence__c, Sharing_Code_Override__c, Sharing_Entity__c,
              Sharing_Entity_Override__c, Batch_Date__c, Bank_Date__c , Payment_Subtype__c,
              Related_Transaction__c,RPT_Package_Code__c, Proposal__c, rC_Giving__Closed_Amount__c,
              Closed_Amount_Payments__c,Expected_Giving_Amount_Payments__c, Program_Type__c, Acknowledgment_Status__c,
              Expected_Giving_Amount_Total__c,Closed_Amount_Total__c, Net_Amount__c, Fees__c, rC_Giving__Parent__r.Net_Amount__c,
              rC_Giving__Parent__r.Fees__c, Has_Soft_Credits__c, Portfolio_2__c, Portfolio_3__c,rC_Giving__Parent__r.rC_Giving__Parent__c,SB_Donation_Id__c,
              rC_Giving__Parent__r.SB_Donation_Id__c
            FROM Opportunity
            WHERE Id IN : newLst ORDER BY LastModifiedDate ASC]) {
            
            // Populate variable to pass in createPreferenceOffIssues Method
            if(objOppty.CampaignId != null 
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id|| objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id)){
                mapCampaignAccount.put(objOppty.CampaignId,objOppty.AccountId);
            }
            if( objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id){
              System.debug(LoggingLevel.Error, '=============afterinsert=='+objOppty.stagename);
            }
            // Populate variable to pass in updateLastMembGiftOnAccount Method
            if(objOppty.AccountId != null 
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || 
                    objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) 
                && objOppty.IsClosed == true && objOppty.Sharing_Code__c!= null && objOppty.amount >= 5 
                && (String.ValueOf(objOppty.Sharing_Code__c) != null && (String.ValueOf(objOppty.Sharing_Code__c).Startswith('A')
                                 || String.ValueOf(objOppty.Sharing_Code__c).Startswith('B') 
                                 || String.ValueOf(objOppty.Sharing_Code__c).Startswith('D')
                                 || String.ValueOf(objOppty.Sharing_Code__c).Startswith('P')))){
                mapAccIdTooppId.put(objOppty.AccountId, objOppty.Id);
            }

            // Populate variable to pass in updateRenewableFieldonAccount Method
            if(objOppty.accountId != null 
                && objOppty.Sharing_Code__c!= null && objOppty.account.Has_Renewed_Before__c == false 
                    && (objOppty.Sharing_Code__c== 'P003' || objOppty.Sharing_Code__c== 'P009'
                            || objOppty.Sharing_Code__c== 'P001' || objOppty.Sharing_Code__c== 'P002')){
                accountNonRenewableIds.add(objOppty.accountId);
            }


            // Populate variable to pass in setExpirationDate Method
            if(objOppty.AccountId != null 
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id 
                    || objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id)
               && objOppty.Sharing_Code__c!= null && objOppty.StageName == 'Completed' &&
               objOppty.account.Membership_Expiration_date__c != dateForSetExpirationMethod
               && !objOppty.Has_Soft_Credits__c){
                setExpirationDatesOpps.add(objOppty);
            }

            // Populate variable to pass in populateSourceCodeValues Method
            if(objOppty.rC_Giving__Is_Sustainer__c && objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) {
                setToupdateFirstPaymentOnChild.add(objOppty.Id);
            }

            //Populate variable to pass in rollupTrigger Method
            if(objOppty.rC_Giving__Planned_Giving__c != null && objOppty.rC_Giving__Expected_Giving_Amount__c != null){
                plannedGivingGifts.add(objOppty);
            }

            // Populate variable to pass in rollUpTrigger Method
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_ID || objOppty.RecordTypeId == OPPORTUNITY_RT_GRANT_Id) 
                && (objOppty.Portfolio__c != null || objOppty.Portfolio_2__c != null || objOppty.Portfolio_3__c != null )) {
                if( objOppty.Portfolio__c != null )
                    portFolioIds.add(objOppty.Portfolio__c);
                if( objOppty.Portfolio__c != null )
                    portFolioIds.add(objOppty.Portfolio_2__c);
                if( objOppty.Portfolio__c != null )
                    portFolioIds.add(objOppty.Portfolio_3__c);
            }

            // Populate variable to pass in updateJointMembershipFlagonAccount Method
            if(objOppty.Amount >= 30 && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ||
                    objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) && objOppty.AccountId != null &&
                    setOfSharingCodesForMembershipCampaign.contains(objOppty.Sharing_Code__c) && objOppty.StageName == 'Completed') {
                setOfAccountIdsToUpdate.add(objOppty.AccountId);
            }

            //Populate list to pass in updateChildOpportunityFromBatchLog method
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) &&
                        (objOppty.Batch_Log__c != null || objOppty.Deposit_Site__c != null || objOppty.Batch_Sequence__c != null) &&
                        objOppty.Batch_Log__r.Batch_Log_Type__c == 'Manual' 
                        || objOppty.Batch_Log__r.Batch_Log_Type__c == 'Vendor') {//Zendesk: #67314 - Added the batchlog type = Vendor in the if condition
                parentOpportunityIds.add(objOppty.Id);
                 //parentOpportunities.add(objOppty); //ACLU:: #77940 :: This line is commented beacuse the 
                                                     //batchlog should populated when stagename = completed 
            }
            //populate Merchant Name
            if(objOppty.Deposit_Site__c != null && objOppty.rC_Giving__Payment_Method_Selected__c != null &&
                 (objOppty.rC_Giving__Payment_Method__c == 'Charge Card' || objOppty.rC_Giving__Payment_Method__c == 'EFT')){
                oppsToUpdateMerchantName.add(objOppty);
            }

            // Method to Bring Down Sharing Code, Sharing Entity, Sharing Code Override and Sharing Entitiy Override on Transactions from Parent Donations.
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id)
                    && (objOppty.Sharing_Entity_Override__c || objOppty.Sharing_Code_Override__c)) {
              setOfDonationsWithSharingFieldsUpdated.add(objOppty.Id);
            }

            //Populate variables to set setExcludeRevenueSharing field on parent Related Transaction of Soft Credits
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.Related_Transaction__c != null) {
              setOfRelatedTransactionIds.add(objOppty.Related_Transaction__c);
            }

            //Populate Variables to set StageName on Parent to Open if stage of child record is Pending Failed
            if(objOppty.StageName == 'Pending Failed' && objOppty.rC_Giving__Parent__c != null &&
               (objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id)) {
                setOfParentOppIdsToProcess.add(objOppty.rC_Giving__Parent__c);
            }

            // Populate variable to pass in rollUpTrigger Method for related transactions
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ||
                objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) && objOppty.Proposal__c != null) {
                if(objOppty.Amount != null) {
                    listOfTransactionsForExpectedAmt.add(objOppty);
                    if(objOppty.StageName == 'Completed') {
                        listOfTransactionsForClosedAmt.add(objOppty);
                    }
                }
            }
            
            // Stock Calculations
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ) && 
                (objOppty.rC_Giving__Parent__r.Net_Amount__c != null || objOppty.rC_Giving__Parent__r.Fees__c != null)) {
                parentOpptiesForStock.put(objOppty.rC_Giving__Parent__c, objOppty.rC_Giving__Parent__r);
            } 
            
            if( objOppty.Amount != null
                && objOppty.StageName == 'Completed'
                && (objOppty.Program_Type__c == '1' || objOppty.Program_Type__c == '2' || 
                    objOppty.Program_Type__c == '3' || objOppty.Program_Type__c == '4' || 
                    objOppty.Program_Type__c == '5' )
                && (
                    ((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)                        
                         && objOppty.rC_Giving__Parent__c != null && objOppty.rC_Giving__Parent__r.rC_Giving__Parent__c != null ) 
                    || (objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.Proposal__c != null) )
            ) {
                if( objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id ){
                    idsForAsync_Opp.add(objOppty.Proposal__c);
                } else {
                    idsForAsync_Opp.add(objOppty.rC_Giving__Parent__r.rC_Giving__Parent__c);
                }
            }
            
            
        }
        list<AsyncRequest__c> newAsyncRequest = new list<AsyncRequest__c>();
        // Controls the number of Ids passed into a single AsyncRequest__c record for async processing
        while(idsForAsync_Opp.size() > 0) {
            if(idsForAsync_Opp.size() >= oppAsyncBatchMax){
                list<String> idList = new list<String>();
                Integer counter = 1;
                for(String oppId : idsForAsync_Opp) {
                    idList.add(oppId);
                    idsForAsync_Opp.remove(oppId);
                    counter++;
                    if(counter==oppAsyncBatchMax) break;
                }
                newAsyncRequest.add( new AsyncRequest__c(
                                            AsyncType__c ='opp_rollToProposal', Object_API_Name__c = 'Opportunity',
                                            Params__c = String.join(idList,',')));
            } else {
                break;
            }
        }
        // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
        if(idsForAsync_Opp.size() > 0){
            newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='opp_rollToProposal', Object_API_Name__c = 'Opportunity',
                                    Params__c = String.join(new List<String>(idsForAsync_Opp),',')));
            /*try {*/
                  insert newAsyncRequest;
                  
            /*} catch(Exception ex){
                  // or suggest using our ApexLog Asset to record the fail!
            }*/
        }

        // Query for child as well as parent opp. info
        if(setToupdateFirstPaymentOnChild.size() > 0 || setOfDonationsWithSharingFieldsUpdated.size() > 0 || parentOpportunityIds.size() > 0 ||
            setOfRelatedTransactionIds.size() > 0 || setOfParentOppIdsToProcess.size() > 0) {
          Set<Id> setOfParentOppIds = new Set<Id>();
          Set<Id> setOfOppIds = new Set<Id>();
          setOfParentOppIds.addall(setToupdateFirstPaymentOnChild);
          setOfParentOppIds.addall(setOfDonationsWithSharingFieldsUpdated);
          setOfParentOppIds.addall(parentOpportunityIds);
          setOfOppIds.addAll(setOfRelatedTransactionIds);
          setOfOppIds.addAll(setOfParentOppIdsToProcess);
          for(Opportunity opp : [SELECT Id, rC_Giving__Source_Code__c, rC_Giving__Parent__r.rC_Giving__Source_Code__c, StageName,
                                             rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c, Auto_Giving_Number__c,
                                             rC_Giving__Parent__r.Sharing_Code_Override__c, rC_Giving__Parent__r.Sharing_Entity_Override__c,
                                             rC_Giving__Parent__r.Sharing_Code__c, rC_Giving__Parent__r.Sharing_Entity__c,
                                             rC_Giving__Parent__c, Batch_Sequence__c, Batch_Log__c, Deposit_Site__c,RecordTypeId,
                                             Exclude_from_Revenue_Sharing__c,RPT_Package_Code__c
                                      FROM Opportunity
                                      WHERE (rC_Giving__Parent__c IN : setOfParentOppIds OR Id IN : setOfOppIds)
                                      ORDER BY Auto_Giving_Number__c ASC]) {
            if(setToupdateFirstPaymentOnChild!= null &&
                setToupdateFirstPaymentOnChild.contains(opp.rC_Giving__Parent__c) && opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) {
              listOfChildOpps.add(opp);
            }
            if(setOfDonationsWithSharingFieldsUpdated!= null &&
                 setOfDonationsWithSharingFieldsUpdated.contains(opp.rC_Giving__Parent__c)) {
              listOfChildOppsForSharingOverride.add(opp);
            }
            if(parentOpportunityIds!= null && parentOpportunityIds.contains(opp.rC_Giving__Parent__c)
              && (opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id|| opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)) {
              listOfOppsForBatchLog.add(opp);
            }
            if(setOfRelatedTransactionIds!= null && setOfRelatedTransactionIds.contains(opp.Id) && (!opp.Exclude_from_Revenue_Sharing__c)) {
              listOfRelatedTransactions.add(opp);
            }
            if(setOfParentOppIdsToProcess!= null && setOfParentOppIdsToProcess.contains(opp.Id)) {
              listOfParentOpps.add(opp);
            }
          }
        }

        // Query for Account info.
        if(setOfAccountIdsToUpdate.size() > 0) {
          for(Account acc : [SELECT Id, Household_Count__c, Joint_Membership_Flag__c
                             FROM Account
                             WHERE Id IN: setOfAccountIdsToUpdate
                             AND Household_Count__c >=2
                             AND Joint_Membership_Flag__c = False]) {
            listOfAccountsWithJointMembershipFlag.add(acc);
          }
        }

        // Method to create preference records based on Pref Code
        if(mapCampaignAccount.size() > 0) {
            OpportunityManager.createPreferenceOffIssues(mapCampaignAccount);
        }

        //populate Merchant Name
        if(!oppsToUpdateMerchantName.IsEmpty()){
            paymentMethods = OpportunityManager.updateMerchantName(oppsToUpdateMerchantName);
        }

        // Method to update Last_Membership_Gift__c on Account
        if(!mapAccIdTooppId.Keyset().IsEmpty()){
            mapUpdateAccounts = OpportunityAccountManager.updateLastMembGiftOnAccount(mapAccIdTooppId, mapUpdateAccounts);
        }
        // Method to populate Source Code values on Oppties
        if(opptyMapToUpdate.size() > 0 || !listOfChildOpps.isEmpty()) {
            mapUpdateOpportunities = OpportunityManager.populateSourceCodeValues(opptyMapToUpdate,listOfChildOpps, mapUpdateOpportunities);
        }
        // Method to Update the Renewable on account
        if(!accountNonRenewableIds.isEmpty()){
            mapUpdateAccounts = OpportunityAccountManager.updateRenewableFieldonAccount(accountNonRenewableIds, mapUpdateAccounts);
        }

        // Method to Set Expiration Date on Related Account
        if(!setExpirationDatesOpps.Isempty()){
            RevenueSharingShareCodes.OpportunitiesAndAccountWrapper wrapper = RevenueSharingShareCodes.setExpirationDate(
                                                                setExpirationDatesOpps, mapUpdateAccounts, mapUpdateOpportunities);
            mapUpdateAccounts = wrapper.mapaccounts;
            mapUpdateOpportunities =  wrapper.mapOpportunities;
        }

        // Method to update Joint Membership Flag on Account
        if(!setOfAccountIdsToUpdate.isEmpty()) {
            mapUpdateAccounts = OpportunityAccountManager.updateJointMembershipFlagonAccount(listOfAccountsWithJointMembershipFlag, mapUpdateAccounts);
        }

        // Method to Bring Down Sharing Code Override and Sharing Entitiy Override from Parent.
        if(!listOfChildOppsForSharingOverride.isEmpty()) {
          mapUpdateOpportunities = bringSharingCodeAndEntityFieldToChild(listOfChildOppsForSharingOverride,mapUpdateOpportunities);
        }

        // Method to update child oppties from Batch Log
        if(!parentOpportunities.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.updateChildOpportunityFromBatchLog(parentOpportunities, null,
                                                      listOfOppsForBatchLog,mapUpdateOpportunities);
        }

        // Method to set setExcludeRevenueSharing field on parent Related Transaction of Soft Credits
        if(!listOfRelatedTransactions.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.setExcludeFromRevenuesharingField(listOfRelatedTransactions,mapUpdateOpportunities);
        }

        // Method to set StageName to Open if stage of child record is Pending Failed
        if(!listOfParentOpps.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.setStageToOpenIfPendingFailed(listOfParentOpps,mapUpdateOpportunities);
        }
        
        // stock Calculations
        if(!parentOpptiesForStock.isEmpty()) {
            mapUpdateOpportunities = OpportunityManager.opptyStockCalculation(parentOpptiesForStock, mapUpdateOpportunities);
        }
        
        // DML Operation On Account
        if(!mapUpdateAccounts.KeySet().IsEmpty()){
            calculateFeesAndNetAmount = FALSE;
            update mapUpdateAccounts.Values();
            calculateFeesAndNetAmount = TRUE;
        }
        Set<Id> parentOppIdSet = new Set<Id>();
        /*for(Opportunity objOppty: newlst) {
            if( objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id){
                parentOppIdSet.add(objOppty.rC_Giving__Parent__c);
            }
        }*/
        
       
        // DML Operation on Opportunity
        if(!mapUpdateOpportunities.isEmpty()) {
            upsert mapUpdateOpportunities.values();
        }

        // DML Operation on PaymentMetod
        if(!paymentMethods.IsEmpty()){
            update paymentMethods.Values();
        }

        // Rolls Up Values on Portfolio Object
        if(portFolioIds!= null) {
          RSFUtility.updatePortfolioRollUpRecords(portFolioIds);
        }
        // Rolls up Values on Planned Giving Object
        if(!plannedGivingGifts.IsEmpty()){
            RSFUtility.rollUpTrigger(pGFieldDefinitions, plannedGivingGifts, 'Opportunity', 'rC_Giving__Planned_Giving__c', 
              'rC_Giving__Planned_Giving__c','');
        }

        // Rolls up Values on Opportunity Object
        if(!listOfTransactionsForExpectedAmt.IsEmpty()){
            RSFUtility.rollUpTrigger(oppFieldDefinitionsExpectedAmt, listOfTransactionsForExpectedAmt, 'Opportunity', 
              'Proposal__c', 'Opportunity',' AND (RecordTypeId =\''+ OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''+
              OPPORTUNITY_RT_SOFT_CREDIT_Id+'\' OR RecordTypeId =\''+ OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+'\' )');
        }
        if(!listOfTransactionsForClosedAmt.IsEmpty()){
            RSFUtility.rollUpTrigger(oppFieldDefinitionsClosedAmt, listOfTransactionsForClosedAmt, 'Opportunity', 'Proposal__c', 
              'Opportunity',' AND (RecordTypeId =\''+ OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''+
              OPPORTUNITY_RT_SOFT_CREDIT_Id+'\' OR RecordTypeId =\''+ OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+
              '\' ) AND StageName = \'Completed\'');
        }
        
    }

    /*
    *
    *Method beforeUpdate
    *@param : newlistOpp, oldMap
    *@description : calls on beforeUpdate
    *
    */
    public static void beforeUpdate(Map<Id, opportunity> newMap, Map<Id,opportunity> oldMap) {
       /* User currentUser = [SELECT Id, Validation_Bypass__c FROM User WHERE ID = :UserInfo.getUserId()];
                    currentUser.Validation_Bypass__c = true;
                    update currentUser;*/
        List<opportunity> newlistOpp = newMap.values();
        Set<String> campaignIds = new Set<String>();
        Set<Id> setOfPaymentMethodIds =  new Set<Id>();
        Set<Id> setOfPledgePaymentIds =  new Set<Id>();
        List<opportunity> opportunities = new List<opportunity>();
        List<Opportunity> listOfCompletedChildOpps = new List<Opportunity>();
        List<Opportunity> listOfCompletedPledgeChildOpps = new List<Opportunity>();
        List<Opportunity> listOfCompletedTransactionChildOpps = new List<Opportunity>();
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> setOfRelatedTransactionIds = new Set<Id>();
        Map<Id,Account> mapOfAccountIdVsAccount = new Map<Id,Account>();
        Map<Id,rC_Giving__Payment_Method__c> mapOfPaymentMethodIdVsPaymentMethod = new Map<Id,rC_Giving__Payment_Method__c>();
        Map<Id,Opportunity> mapOfParentOppIdVsParentOpportunity = new Map<Id,Opportunity>();
        List<Opportunity> listOfOppsFromGivingWizard = new List<Opportunity>();
        Map<String, ProgramType_DepositSite_Defaults__c> depositSiteCustomSettingMap = new Map<String, ProgramType_DepositSite_Defaults__c>();
        List<Opportunity> listOfOpportunities = new List<Opportunity>();
        List<Opportunity> opptyLstForShareCodeUpdate = new List<Opportunity>();
        rC_Giving__Opportunity_Setting__c oppSetting = rC_Giving__Opportunity_Setting__c.getInstance();
        list<Opportunity> listOfOpportunitiesForNameUpdate = new list<Opportunity>();
        Set<Opportunity> childOppList = new Set<Opportunity>();//ACLU #77940: Added a variable
        System.debug('Before Update');
        /* Mounica V, Added as part of BGE-6 */
        Map<String,string> mapShareCodetoDescription = getSharingCodeMap();
        //BGE-6 END
        
        for(Opportunity objOppty: newlistOpp) {
            if( objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id){
              System.debug(LoggingLevel.Error, '=============before update=='+objOppty.stagename);
                setOfPledgePaymentIds.add(objOppty.rC_Giving__Parent__c);
                listOfCompletedPledgeChildOpps.add(objOppty);
            }
          if((oldMap.get(objOppty.Id).Isclosed != objOppty.Isclosed  || oldMap.get(objOppty.Id).accountId != objOppty.accountId)
              && objOppty.Isclosed == true && objOppty.accountId != null ) {
            setOfAccountIds.add(objOppty.accountId);
          }
          if(objOppty.Update_Payment_Method__c != null && objOppty.AccountId != null &&
             (oldMap.get(objOppty.Id).Update_Payment_Method__c != objOppty.Update_Payment_Method__c
                 || oldMap.get(objOppty.Id).AccountId != objOppty.AccountId)) {
            setOfPaymentMethodIds.add(objOppty.Update_Payment_Method__c);
          }
          if((objOppty.RecordtypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id || objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                && objOppty.Related_Transaction__c != oldMap.get(objOppty.Id).Related_Transaction__c
            && objOppty.Related_Transaction__c != null) {
            setOfRelatedTransactionIds.add(objOppty.Related_Transaction__c );
          }

          // Modified By :: roundCorner Inc. 
          // #60194: Rolling down information from Donation to Transaction
          if(objOppty.rC_Giving__Parent__c != null && objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id){
            listOfCompletedTransactionChildOpps.add(objOppty);
            setOfRelatedTransactionIds.add(objOppty.rC_Giving__Parent__c);
          }

          if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && objOppty.rC_Giving__Is_Sustainer__c 
            && oldMap.get(objOppty.Id).rC_Giving__Payment_Method_Selected__c != objOppty.rC_Giving__Payment_Method_Selected__c) {
              listOfOppsFromGivingWizard.add(objOppty);
          }
            
            
            System.debug(LoggingLevel.Error, '==before update recordtype=='+objOppty.RecordTypeID);

          //sets the OpportunityStage to Cancelled if the Force Cancelled is true.
          /*if((oldMap.get(objOppty.Id).rC_Giving__Is_Canceled__c != objOppty.rC_Giving__Is_Canceled__c) && objOppty.rC_Giving__Is_Canceled__c == true && objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id){
            objOppty.stageName = 'Canceled';
            objOppty.rC_Giving__Payment_End_Date__c = Date.today();
            //objOppty.Cancellation_Reason__c = 'Donor Requested';
          }*/
          //Stock Fields Caluculations
            /*if( ( objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id )
                && (objOppty.Net_Amount__c != oldMap.get(objOppty.Id).Net_Amount__c
                || objOppty.Fees__c != oldMap.get(objOppty.Id).Fees__c
                || objOppty.rC_Giving__Giving_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Giving_Amount__c)
                && calculateFeesAndNetAmount
            ){
                if( objOppty.rC_Giving__Giving_Amount__c != null ){
                    if( objOppty.Net_Amount__c != NULL ){
                        objOppty.Fees__c = objOppty.rC_Giving__Giving_Amount__c - objOppty.Net_Amount__c;
                    } else if( objOppty.Fees__c != NULL && objOppty.Net_Amount__c == NULL ){
                        objOppty.Net_Amount__c = objOppty.rC_Giving__Giving_Amount__c - objOppty.Fees__c;
                    }
                } else {
                    objOppty.Fees__c = NULL;
                    objOppty.Net_Amount__c = NULL;
                }
            }*/
              //T-647782
              if( objOppty.recordTypeId == OPPORTUNITY_RT_TRANSACTION_Id ||  objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
                || objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_Id ||  objOppty.recordTypeId == OPPORTUNITY_RT_DONATION_Id
                || objOppty.recordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id
              ){
                  getTaxValueCalculations( objOppty, oldMap.get(objOppty.id));
                  
              }
              
              //Update Original_Amount__c on Donations & Non-sustainer pledges
              if((objOppty.recordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_Id) 
                  && !objOppty.rC_Giving__Is_Sustainer__c 
                  && ((objOppty.rC_Giving__Giving_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Giving_Amount__c 
                     && objOppty.rC_Giving__Giving_Amount__c != objOppty.Original_Amount__c) 
                     || objOppty.StageName != 'Completed')
                  && objOppty.Adjustment_Sequence__c == null) {
                    objOppty.Original_Amount__c = objOppty.rC_Giving__Giving_Amount__c;
                }
                
                //set name on Opportunity when Close date changes
               if(objOppty.CloseDate != oldMap.get(objOppty.Id).CloseDate && oppSetting.rC_Giving__Disable_UpdateName__c) {
                    if((objOppty.recordTypeId == OPPORTUNITY_RT_DONATION_Id ||  objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_Id) && objOppty.rC_Giving__Is_Giving__c &&
                        !objOppty.rC_Giving__Is_Giving_Transaction__c) {
                        listOfOpportunitiesForNameUpdate.add(objOppty);
                    } else if((objOppty.recordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.recordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                        && !objOppty.rC_Giving__Is_Giving__c && objOppty.rC_Giving__Is_Giving_Transaction__c) {
                        listOfOpportunitiesForNameUpdate.add(objOppty);
                    } else if(objOppty.recordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) {
                        listOfOpportunitiesForNameUpdate.add(objOppty);
                    }
                }
            /*  Mounica V, Added as part of BEG-6 : When Sharing code is changed manually, the corresponding description must be populated */  
             if(objOppty.Sharing_Code__c <> null  && objOppty.Sharing_Code__c != oldMap.get(objOppty.Id).Sharing_Code__c && mapSharecodetoDescription.containsKey(objOppty.Sharing_Code__c)){
                 
                objOppty.Sharing_Code_Description__c =  mapSharecodetoDescription.get(objOppty.Sharing_Code__c);
             } //BGE-6 END
             //ACLU #77940 : Added the condition - Maps parent's batch log to transaction batch log id
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
              || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)
              && objOppty.Adjustment_Code__c != 'D'
              && objOppty.StageName.equalsIgnoreCase('Completed') 
              && objOppty.StageName!= oldMap.get(objOppty.id).StageName){
                childOppList.add(objOppty);
            }
            
        }
        
        if(!listOfOpportunitiesForNameUpdate.isEmpty()) {
            OpportunityManager.setOpportunityName(listOfOpportunitiesForNameUpdate);
        }
        
        if(setOfAccountIds.size() > 0) {
          for(Account objAcc : [SELECT Id, Affiliation__c
                                FROM Account
                                where Id IN : setOfAccountIds]) {
            mapOfAccountIdVsAccount.put(objAcc.Id,objAcc);
          }
        }

        if(setOfPaymentMethodIds.size() > 0) {
          for(rC_Giving__Payment_Method__c paymentMethod : [SELECT Id, rC_Giving__Account__c
                                                            FROM rC_Giving__Payment_Method__c
                                                            WHERE Id IN : setOfPaymentMethodIds
                                                            AND rC_Giving__Account__c != NULL]) {
            mapOfPaymentMethodIdVsPaymentMethod.put(paymentMethod.Id,paymentMethod);
          }
        }

        if(setOfRelatedTransactionIds.size() > 0) {
          for(Opportunity opp : [SELECT Id, rC_Giving__Source_Code__c,Deposit_Site__c,RPT_Package_Code__c,Restriction__c,rC_Giving__Ticker_Symbol__c,rC_Giving__Number_Of_Shares__c,High_Amount__c, Low_Amount__c,
                                        Types_of_shares__c,Tax_Value__c,Program_Type__c,Campaign_Type__c,Fund__c,Fundraising_Department__c,Account_Code__c, CampaignId, CampaignIdText__c,
                                        Acknowledgment_Code__c, batch_log__c, rC_Giving__Check_Date__c,rC_Giving__Check_Number__c, SB_Originating_Form_ID__c, SB_Form_Affiliation__c, SB_Donation_Id__c,
                                        Form_Internal_Name__c, rC_Giving__Acknowledged_Date__c, Acknowledgment_Status__c, rC_Giving__Acknowledged__c, Source_File__c, Form_URL__c,
                                        Batch_Sequence__c,Batch_Date__c,Bank_Date__c,Payment_Subtype__c,Adjustment_Code__c //ACLU :#77940 - Added fields 
                                 FROM Opportunity
                                 WHERE Id IN : setOfRelatedTransactionIds ]) {
            mapOfParentOppIdVsParentOpportunity.put(opp.Id,opp);
          }
        }

        //populate map parent to pledge
        if(setOfPledgePaymentIds.size() > 0 ) {
            System.debug('>>> build parent');
            for(Opportunity opp : [SELECT Id, rC_Giving__Source_Code__c,Deposit_Site__c,RPT_Package_Code__c,Restriction__c,rC_Giving__Ticker_Symbol__c,rC_Giving__Number_Of_Shares__c,High_Amount__c,Low_Amount__c,Types_of_shares__c,Tax_Value__c,
                    Program_Type__c,Campaign_Type__c,Fund__c,Fundraising_Department__c,Account_Code__c,
                    CampaignId,CampaignIdText__c,Acknowledgment_Code__c, batch_log__c, rC_Giving__Check_Date__c,rC_Giving__Check_Number__c,
                    SB_Originating_Form_ID__c, SB_Form_Affiliation__c, SB_Donation_Id__c, Form_Internal_Name__c, rC_Giving__Acknowledged_Date__c, Acknowledgment_Status__c,
                    rC_Giving__Acknowledged__c, Source_File__c, Form_URL__c, StageName, SB_Originating_Form_Name__c,
                    Batch_Sequence__c,Batch_Date__c,Bank_Date__c,Payment_Subtype__c,Adjustment_Code__c //ACLU :#77940 - Added fields 
            FROM Opportunity
            WHERE Id IN : setOfPledgePaymentIds ]) {
                mapOfParentOppIdVsParentOpportunity.put(opp.Id,opp);
            }
        }
        //Populate map from Custom setting
        if(listOfOppsFromGivingWizard.size() > 0) {
            depositSiteCustomSettingMap = ProgramType_DepositSite_Defaults__c.getAll();
        }
        for(Opportunity objOppty: newlistOpp) {
                         //GH-75 DEBUGGING
                            System.debug('==before update start id =='+objOppty.Id);
                            System.debug('==before update start rec type =='+objOppty.RecordTypeId);
            
            //GH-75 START
            //Prevent Adjustment recordtype from EVER being changed to Pledge Payment

            if (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && oldMap.get(objOppty.Id).RecordTypeId == OPPORTUNITY_RT_ADJUSTMENT_Id
                && objOppty.Adjustment_Code__c == 'N' && oldMap.get(objOppty.Id).Adjustment_Code__c == 'A') {
                Boolean adjCancellationInProgress = BatchLogDetailPageController.adjustmentCancellationInProgress;  
                if (!adjCancellationInProgress || adjCancellationInProgress == null) {
                    objOppty.RecordTypeID = OPPORTUNITY_RT_ADJUSTMENT_Id;
                    objOppty.Adjustment_Code__c = 'A';
                }
            }
            //GH-75 END

            //GH-38: Populate CampaignId for Child Opportunity
            if(objOppty.rC_Giving__Parent__c != null && objOppty.RecordTypeId != OPPORTUNITY_RT_SOFT_CREDIT_Id) {
                objOppty.CampaignId = objOppty.rC_Giving__Parent__c != null &&
                                                   objOppty.rC_Giving__Parent__r.CampaignId != null
                                                 ?  objOppty.rC_Giving__Parent__r.CampaignId
                                                 : objOppty.CampaignId;
            }

            // Populate the Campaign On Sustainer Pledges
            if(objOppty.Upgrade_Source__c != null 
               && objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && objOppty.rC_Giving__Is_Sustainer__c 
               && objOppty.Upgrade_Source__c != oldMap.get(objOppty.Id).Upgrade_Source__c) {
               objOppty.CampaignId = objOppty.Upgrade_Source__c;
            }
           
            // Validate Opportunity is Not Updated When Posted to GL is True
            if(objOppty.Posted_to_GL_Checkbox__c && (!hasGLOverridePS &&  currentUserProfileName != 'System Administrator')) {
              objOppty.addError(Label.Error_On_Opportunity_When_It_Is_Updated_After_Posted_to_GL_Is_True);
            }
            
           //Update the Acknowledgement Status and Acknowledgement Date
           if(objOppty.rC_Giving__Payment_Method__c != oldMap.get(objOppty.Id).rC_Giving__Payment_Method__c 
                && objOppty.rC_Giving__Payment_Method__c != null
                && objOppty.rC_Giving__Payment_Method__c == 'Securities') {
              objOppty.Acknowledgment_Status__c = 'A - Acknowledged';
              objOppty.rC_Giving__Acknowledged_Date__c = objOppty.CloseDate != null ? objOppty.CloseDate : objOppty.rC_Giving__Acknowledged_Date__c ;
           }

            // Update the Record Type, Stage and Record Amount for Soft Credits
            if(objOppty.isSoft_Credit__c && (objOppty.isSoft_Credit__c != oldMap.get(objOppty.Id).isSoft_Credit__c)) {
              objOppty.RecordtypeId = OPPORTUNITY_RT_SOFT_CREDIT_Id;
              objOppty.Amount = objOppty.Prior_Amount__c;
              objOppty.StageName = 'Completed';
            }

            // Populate Original Expected Giving Amount Field for Pledges. Will only run once when the Expected Giving Amount field is blank.
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && objOppty.rC_Giving__Expected_Giving_Amount__c != null
                && objOppty.Original_Expected_Giving_Amount__c == null) {
              objOppty.Original_Expected_Giving_Amount__c = objOppty.rC_Giving__Expected_Giving_Amount__c;
            }
            // Populate variables to pass in copyCampaignFieldsOnOpportunity Method
            // This will not update any Sharing fields as the Donation and Pledge are not included in sharing criteria and child records are not in Closed state
            if(
                (
                  (objOppty.RecordtypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_Id)
                  && (objOppty.CampaignId != oldMap.get(objOppty.Id).CampaignId)
                ) ||
                ( (objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id ||
                    (objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.Related_Transaction__c == null)
                  ) 
               // GH-75 FIX   && (objOppty.CampaignIdText__c != objOppty.campaignId)
               // OLD
               && (objOppty.CampaignIdText__c != oldMap.get(objOppty.Id).CampaignIdText__c)
               // 
                ) 
              ){
                opportunities.add(objOppty);

                String campaignId; 

                if ((objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)) {
                    campaignId = objOppty.CampaignIdText__c;
                    objOppty.campaignId = objOppty.CampaignIdText__c;
                }
                campaignId = objOppty.campaignId;
                campaignIds.add(campaignId);
            }
            else if((objOppty.RecordtypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id || objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                        && objOppty.Related_Transaction__c != null &&
                    mapOfParentOppIdVsParentOpportunity != null && mapOfParentOppIdVsParentOpportunity.containsKey(objOppty.Related_Transaction__c) &&
                    objOppty.Related_Transaction__c != oldMap.get(objOppty.Id).Related_Transaction__c) {
                objOppty.rC_Giving__Source_Code__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).rC_Giving__Source_Code__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).rC_Giving__Source_Code__c
                                        : objOppty.rC_Giving__Source_Code__c;
                objOppty.CampaignIdText__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).CampaignIdText__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).CampaignIdText__c
                                        : objOppty.campaignId;
                objOppty.Deposit_Site__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Deposit_Site__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Deposit_Site__c
                                        : objOppty.Deposit_Site__c;
                objOppty.RPT_Package_Code__c = mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).RPT_Package_Code__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).RPT_Package_Code__c
                                        : objOppty.RPT_Package_Code__c;
                objOppty.Restriction__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Restriction__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Restriction__c
                                        : 'UNDEFINED - Undefined';
                objOppty.Program_Type__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Program_Type__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Program_Type__c
                                        : objOppty.Program_Type__c;
                if((objOppty.rC_Giving__Acknowledged_Date__c == null) && (objOppty.Acknowledgment_Status__c != 'A - Acknowledged')) {
                objOppty.Acknowledgment_Code__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Acknowledgment_Code__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Acknowledgment_Code__c
                                        : objOppty.Acknowledgment_Code__c;
                }
                objOppty.Campaign_Type__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Campaign_Type__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Campaign_Type__c
                                        : objOppty.Campaign_Type__c;
                objOppty.Fund__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fund__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fund__c
                                        : objOppty.Fund__c;
                objOppty.Fundraising_Department__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fundraising_Department__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Fundraising_Department__c
                                        : objOppty.Fundraising_Department__c;
                objOppty.Account_Code__c =  mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Account_Code__c != null
                                        ? mapOfParentOppIdVsParentOpportunity.get(objOppty.Related_Transaction__c).Account_Code__c
                                        : objOppty.Account_Code__c;
            }
            //populate variables to pass in setShareCode method
            if( (((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
                    || (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.Related_Transaction__c == null))
                  && (!objOppty.Exclude_from_Revenue_Sharing__c))
                  || (objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id 
                  || (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.Related_Transaction__c != null)))
                  && (objOppty.Manual_Sharing_Code__c == False)
                  && (objOppty.Program_Type__c != Null)
                  && (objOppty.accountId != Null)
                  && (objOppty.stageName == 'Completed') 
                  && (objOppty.stageName != oldMap.get(objOppty.Id).stageName
                    || objOppty.Isclosed != oldMap.get(objOppty.Id).Isclosed
                    || objOppty.Deposit_Site__c != oldMap.get(objOppty.Id).Deposit_Site__c
                    || objOppty.Amount != oldMap.get(objOppty.Id).Amount
                    || objOppty.Program_Type__c != oldMap.get(objOppty.Id).Program_Type__c
                    || objOppty.Campaign_Type__c != oldMap.get(objOppty.Id).Campaign_Type__c
                    || (objOppty.accountId != oldMap.get(objOppty.Id).accountId)
                    || (objOppty.Related_Transaction__c != oldMap.get(objOppty.Id).Related_Transaction__c))
              ) {
              listOfCompletedChildOpps.add(objOppty);
            }


            // Update Account Affiliation Field OnOppty
            if((oldMap.get(objOppty.Id).Isclosed != objOppty.Isclosed  || oldMap.get(objOppty.Id).accountId != objOppty.accountId)
                 && objOppty.Isclosed == true && objOppty.accountId != null ) {
              objOppty.Account_Affiliation__c = mapOfAccountIdVsAccount.get(objOppty.accountId).Affiliation__c != null ?
                                                mapOfAccountIdVsAccount.get(objOppty.accountId).Affiliation__c.subString(0,2) : '';
            }

           // sets the Review status of Opportunity when Document is not attached.
           /*if(!objOppty.Set_Document_Attached__c && objOppty.Trigger_Attachment_Review_Process__c != null
                && objOppty.Trigger_Attachment_Review_Process__c != oldMap.get(objOppty.Id).Trigger_Attachment_Review_Process__c) {
             objOppty.Review_Status__c = 'Pending Submission';
           }*/

           // Update Probability % and Projected Amount On Opportunityon
           if(objOppty.rC_Giving__Projected_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Projected_Amount__c
                 && objOppty.RecordtypeId == OPPORTUNITY_RT_PROPOSAL_ID) {
             objOppty.Probability__c = objOppty.rC_Giving__Projected_Amount__c != null && objOppty.rC_Giving__Requested_Amount__c != null
                                        && objOppty.rC_Giving__Requested_Amount__c != 0
                                     ? (objOppty.rC_Giving__Projected_Amount__c/ objOppty.rC_Giving__Requested_Amount__c) * 100
                                     : objOppty.Probability__c;
             objOppty.Probability__c = objOppty.rC_Giving__Projected_Amount__c == null ? null : objOppty.Probability__c;
             if(objOppty.Probability__c > 999) {
                 objOppty.Probability__c = 100;
             }
           }
           else if(objOppty.Probability__c != oldMap.get(objOppty.Id).Probability__c) {
             objOppty.rC_Giving__Projected_Amount__c = objOppty.Probability__c != null && objOppty.rC_Giving__Requested_Amount__c != null
                                                     ? (objOppty.Probability__c * objOppty.rC_Giving__Requested_Amount__c)/100
                                                     : objOppty.rC_Giving__Projected_Amount__c;
           } else if(objOppty.rC_Giving__Requested_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Requested_Amount__c 
                && objOppty.RecordtypeId == OPPORTUNITY_RT_PROPOSAL_ID) {
             objOppty.rC_Giving__Projected_Amount__c = objOppty.Probability__c != null && objOppty.rC_Giving__Requested_Amount__c != null
                                                     ? (objOppty.Probability__c * objOppty.rC_Giving__Requested_Amount__c)/100
                                                     : objOppty.rC_Giving__Projected_Amount__c;
           }

           // Update the Stage last Changed Date
           if(objOppty.StageName != oldMap.get(objOppty.Id).StageName) {
             objOppty.Stage_Last_Changed_Date__c = dateOfToday;
           }


           // Set the Exclude from Revenue Sharing field where Deposit Site = Label.Cosmetic_Gift_Deposit_Site
           if(objOppty.Deposit_Site__c != oldMap.get(objOppty.Id).Deposit_Site__c && (objOppty.Deposit_Site__c == Label.Cosmetic_Gift_Deposit_Site)) {
              objOppty.Exclude_from_Revenue_Sharing__c = True;
           }

           // Set the Batch Log Update Date
           if(objOppty.Batch_Log__c != null && (objOppty.Batch_Log__c != oldMap.get(objOppty.Id).Batch_Log__c)) {
             objOppty.Batch_Log_Update_Date__c = dateOfToday;
           }

           // Update Soft Credit Name
           if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && (objOppty.rC_Giving__Account_Name__c != oldMap.get(objOppty.Id).rC_Giving__Account_Name__c
                || objOppty.CloseDate != oldMap.get(objOppty.Id).CloseDate || objOppty.Name == 'Dummy Name') ) {
             String closeDateYear = objOppty.closeDate != null ? String.valueOf(objOppty.closeDate.year()) : '';
             String accName = objOppty.rC_Giving__Account_Name__c != null ? objOppty.rC_Giving__Account_Name__c : '';
             objOppty.Name = accName + ': Soft Credit' + closeDateYear;
           }

           // Populate Giving Amount on Sustainer Pledges from Upgrade Amount
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && (objOppty.rC_Giving__Is_Sustainer__c)
                && objOppty.Upgrade_Amount__c != oldMap.get(objOppty.Id).Upgrade_Amount__c
                && objOppty.Upgrade_Amount__c != null && objOppty.Upgrade_Amount__c != objOppty.rC_Giving__Giving_Amount__c) {
              objOppty.rC_Giving__Giving_Amount__c = objOppty.Upgrade_Amount__c;
            }

            // Populate the Selected Payment Method
            if(objOppty.Update_Payment_Method__c != null && mapOfPaymentMethodIdVsPaymentMethod!= null &&
                objOppty.Update_Payment_Method__c != oldMap.get(objOppty.Id).Update_Payment_Method__c &&
                mapOfPaymentMethodIdVsPaymentMethod.containsKey(objOppty.Update_Payment_Method__c) &&
                mapOfPaymentMethodIdVsPaymentMethod.get(objOppty.Update_Payment_Method__c).rC_Giving__Account__c != null &&
                mapOfPaymentMethodIdVsPaymentMethod.get(objOppty.Update_Payment_Method__c).rC_Giving__Account__c == objOppty.AccountId) {
              objOppty.rC_Giving__Payment_Method_Selected__c = objOppty.Update_Payment_Method__c;
            }

            // Update Re-evaluate Membership Flag on Opportunity
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) &&
                (objOppty.Adjustment_Code__c != oldMap.get(objOppty.Id).Adjustment_Code__c) &&
                (oldMap.get(objOppty.Id).Adjustment_Code__c == 'N' || oldMap.get(objOppty.Id).Adjustment_Code__c == 'D'
                    || oldMap.get(objOppty.Id).Adjustment_Code__c== 'A')) {
              objOppty.Membership_Reevaluation_Needed__c = True;
            }
            
            //populate RPT_Fund_is_Not_Gen__c - T-632803
            if(objOppty.Fund__c != oldMap.get(objOppty.Id).Fund__c) {
                if(objOppty.Fund__c == null || !objOppty.Fund__c.startsWith('GEN')) {
                  objOppty.RPT_Fund_is_Not_Gen__c = true;
                } else {
                    objOppty.RPT_Fund_is_Not_Gen__c = false;
                }
            }

            // Modified by :: roundCorner Inc. :: 22-Oct-2018
            // #60194: Rolling down information from Donation to Transaction
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                && objOppty.rC_Giving__Parent__c != null ) {
                    Opportunity parentOpportunity = mapOfParentOppIdVsParentOpportunity.get(objOppty.rC_Giving__Parent__c);
                    if(parentOpportunity != null) {
                        objOppty.rC_Giving__Ticker_Symbol__c = parentOpportunity.rC_Giving__Ticker_Symbol__c;
                        objOppty.rC_Giving__Number_Of_Shares__c = parentOpportunity.rC_Giving__Number_Of_Shares__c;
                        objOppty.High_Amount__c = parentOpportunity.High_Amount__c;
                        objOppty.Low_Amount__c = parentOpportunity.Low_Amount__c;
                        objOppty.Types_of_shares__c = parentOpportunity.Types_of_shares__c;
                    }
            }

            /*if((((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) && objOppty.rC_Giving__Parent__c != null) 
              || (objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.Proposal__c != null ))
              && objOppty.StageName == 'Completed' && objOppty.Amount != null && (oldMap.get(objOppty.Id).StageName != objOppty.StageName || oldMap.get(objOppty.Id).Amount != objOppty.Amount)) {
            
                  User currentUser = [SELECT Id, Validation_Bypass__c FROM User WHERE ID = :UserInfo.getUserId()];
            currentUser.Validation_Bypass__c = true;
            update currentUser; 
              }
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) //&& objOppty.StageName.contains('Completed') && objOppty.Amount != null
               && oldMap.get(objOppty.Id).rC_Giving__Parent__c != objOppty.rC_Giving__Parent__c && objOppty.rC_Giving__Parent__c!= null) {
                
                
                User currentUser = [SELECT Id, Validation_Bypass__c FROM User WHERE ID = :UserInfo.getUserId()];
            currentUser.Validation_Bypass__c = true;
            update currentUser; 

            }
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.StageName == 'Completed' && objOppty.Amount != null
               && oldMap.get(objOppty.Id).Proposal__c != objOppty.Proposal__c) {
                
                User currentUser = [SELECT Id, Validation_Bypass__c FROM User WHERE ID = :UserInfo.getUserId()];
            currentUser.Validation_Bypass__c = true;
            update currentUser; 
            }*/
        } 
         
        //Method to  copy Fields from Campaign and populate Sharing and Revenue Type fields
        if(!opportunities.IsEmpty()) {
            OpportunityCampaignManager.copyCampaignFieldsAndPopulateSharingFields(opportunities, campaignIds,false, oldMap);
        }
        
        if(!OpportunityCampaignManager.shareCodeLogicProcessedSet.isEmpty()) {
            Set<Id> shareCodeLogicProcessedSet = OpportunityCampaignManager.shareCodeLogicProcessedSet;
            for(Opportunity oppty : listOfCompletedChildOpps) {
                if(!shareCodeLogicProcessedSet.contains(oppty.Id)) {
                    opptyLstForShareCodeUpdate.add(oppty);
                }

            }
        } else {
            opptyLstForShareCodeUpdate = listOfCompletedChildOpps;
        }
        
        if(!listOfCompletedChildOpps.isEmpty()) {
         /* Traction(Mounica V): BGE-22, 12/2/2019 : Removing the logic to flag a batch to 'Membership and Revenue Sharing Resets Needed' 
          listOfCompletedChildOpps = RevenueSharingShareCodes.flagMembershipShareCodeReset(opptyLstForShareCodeUpdate, oldMap);
          if(!listOfCompletedChildOpps.isEmpty()) */
              //DS 11-26-2018
              system.debug('calling RevenueSharingShareCode.setShareCode');
              //
              RevenueSharingShareCodes.setShareCode(listOfCompletedChildOpps);
        }
        
        //T-648895 - modified below block to update deposit site according to campaign's affiliation - KM - 11/22
        Set<Id> campaignIdSet = new Set<Id>();
        Map<Id, String> campaignIdToAffiliate = new Map<Id, String>();
        for(Opportunity objOppty : newlistOpp) {
            if(objOppty.CampaignId != null) {
                campaignIdSet.add(objOppty.CampaignId);
            }
        }
        
        if(!campaignIdSet.isEmpty()) {
            for(Campaign camp : [SELECT Id, rC_Giving__Affiliation__c
                                    FROM Campaign
                                    WHERE Id IN : campaignIdSet]) {
                if(!String.isEmpty(camp.rC_Giving__Affiliation__c)) {
                    campaignIdToAffiliate.put(camp.Id, camp.rC_Giving__Affiliation__c);
                }
            }
        }
        for(Opportunity objOppty : newlistOpp) {
            // Flag the OppsRecords for revenue Sharing
            if(objOppty.Recalculate_Revenue_Share__c == false && (oldMap.get(objOppty.Id).Sharing_Code__c != objOppty.Sharing_Code__c
                 || oldMap.get(objOppty.Id).Exclude_Cost_Factors_in_RevShare__c != objOppty.Exclude_Cost_Factors_in_RevShare__c)){
                objOppty.Recalculate_Revenue_Share__c = true;
            }
            
            // Method to set the Deposit Site For Dontations & Pledges if Current User belongs to an Affiliate and Opp created from Wizard
            String affiliate;
            if(campaignIdToAffiliate.containsKey(objOppty.CampaignId)) {
                affiliate = campaignIdToAffiliate.get(objOppty.CampaignId).subString(0,2);
            }
            if(objOppty.Batch_Log__c == null 
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) && objOppty.rC_Giving__Is_Sustainer__c &&
               objOppty.Program_Type__c == '5' &&  !String.isEmpty(affiliate) &&
               (objOppty.rC_Giving__Payment_Method__c == 'Charge Card' || objOppty.rC_Giving__Payment_Method__c == 'EFT' 
                || objOppty.rC_Giving__Payment_Method__c == 'Cash/Check') &&
               (oldMap.get(objOppty.Id).RecordTypeId !=  objOppty.RecordTypeId ||
                oldMap.get(objOppty.Id).rC_Giving__Payment_Method__c !=  objOppty.rC_Giving__Payment_Method__c ||
                oldMap.get(objOppty.Id).Program_Type__c !=  objOppty.Program_Type__c
               )) {
                
                objOppty.Deposit_Site__c = mapOfKeyVsDepositSiteValue!= null && mapOfKeyVsDepositSiteValue.containsKey(affiliate)
                                         ? mapOfKeyVsDepositSiteValue.get(affiliate)[0]
                                         : objOppty.Deposit_Site__c;
            }

            // Method to set the Revenue_Type field on Opportunity
            if(((objOppty.Deposit_Site__c != null && oldMap.get(objOppty.Id).Deposit_Site__c != objOppty.Deposit_Site__c) ||
                (objOppty.Program_Type__c != null && oldMap.get(objOppty.Id).Program_Type__c != objOppty.Program_Type__c) ||
                (objOppty.rC_Giving__Source_Code__c != null && oldMap.get(objOppty.Id).rC_Giving__Source_Code__c != objOppty.rC_Giving__Source_Code__c) ||
                (objOppty.RPT_Package_Code__c != null && oldMap.get(objOppty.Id).RPT_Package_Code__c != objOppty.RPT_Package_Code__c) ||
                (objOppty.Sharing_Code__c != null && oldMap.get(objOppty.Id).Sharing_Code__c != objOppty.Sharing_Code__c)
                ) && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ||
                    objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)) {
                listOfOpportunities.add(objOppty);  //update revenue type
            }
                                        System.debug('==before update start rec ID =='+objOppty.Id);                          //GH-75 DEBUGGING


            System.debug('==before update end recordtype=='+objOppty.RecordTypeId);                          //GH-75 DEBUGGING


        }
        //Method to populate Deposit site on Pledge/Donation
        if(!listOfOppsFromGivingWizard.isEmpty() && !depositSiteCustomSettingMap.keySet().isEmpty()) {
            OpportunityManager.populateDepositSite(listOfOppsFromGivingWizard, depositSiteCustomSettingMap);
        }
         // Method to populate Revenue Type
        if(!listOfOpportunities.isEmpty()) {
          PopulateRevenueType.populateRevenueType(listOfOpportunities); 
        }
        //ACLU : #77940 ::Maps the batchlog deatils on child records
        if(childOppList.size() > 0 && mapOfParentOppIdVsParentOpportunity.size() >0){
          OpportunityManager.setTransactionBatchFieldsFromParent(childOppList,mapOfParentOppIdVsParentOpportunity);
      }
    }  //end before update

    /*
    *
    *Method afterUpdate
    *@param : newLst, oldMap
    *@description : calls on afterUpdate
    *
    */
    private static void afterUpdate(List<Opportunity> newLst, Map<Id,Opportunity> oldMap) {
        System.debug('After update');
        List<Opportunity> listOfChildOpps = new List<Opportunity>();
        Set<Id> parentOpportunityIds = new Set<Id>();
        List<Opportunity> listOfOppsForBatchLog = new List<Opportunity>();
        List<Account> listOfAccountsForNGOCSharing = new List<Account>();
        List<Account> listOfAccountsWithJointMembershipFlag = new List<Account>();
        Set<Id> accountNonRenewableIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> opptyIdSet = new Set<Id>();
        Set<Id> setToupdateFirstPaymentOnChild = new Set<Id>();
        List<String> OldAffiliations = new List<String>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Opportunity> setExpirationDatesOpps = new List<Opportunity>();
        List<opportunity> revenuShareopportunities = new List<opportunity>();
        Map<Id, Opportunity> opptyMapToUpdate = new Map<Id, Opportunity>();
        Map<Id,Id> mapCampaignAccount = new Map<Id,Id>();
        Map<Id,Id> mapAccIdTooppId = new Map<Id,Id>();
        Map<Id, Account> mapUpdateAccounts = new Map<Id, Account> ();
        Map<Id, Opportunity> mapUpdateOpportunities = new Map<Id, Opportunity>();
        Set<Id> portFolioIds = new Set<Id>();
        List<Opportunity> plannedGivingGifts = new List<Opportunity>();
        Set<Id>setOfPortfolio = new Set<Id>();
        Set<Id> setOfAccountIdsToUpdate = new Set<Id>();
        Map<Id, Opportunity> opptyLstToCreateDocAttachTask = new Map<Id, Opportunity>();
        Map<Id, Opportunity> parentOpptyOldMap = new Map<Id, Opportunity>();
        list<Opportunity> parentOpportunities = new list<Opportunity>();
        Map<Id, rC_Giving__Payment_Method__c> paymentMethods = new Map<Id, rC_Giving__Payment_Method__c>();
        List<Opportunity> oppsToUpdateMerchantName = new List<Opportunity>();

        Set<Id> setOfRealtedTransactionIds = new Set<Id>();
        List<Opportunity> listOfChilfSoftCredits = new List<Opportunity>();
        Set<Id> setOfOppsForFieldUpdates = new set<Id>();
        List<Opportunity> listOfChildOppsForFieldUpdates = new List<Opportunity>();
        Set<Id> parentByPassCalculationGivingRecord = new Set<Id>();
        List<Opportunity> parentByPassCalculationGivingRecordList = new List<Opportunity>();
        Set<Id> setOfOpportunityIds = new Set<Id>();
        List<Opportunity> listOfOppToSendEmailToOwner = new List<Opportunity>();
        Set<Id> setOfDonationsWithSharingFieldsUpdated = new Set<Id>();
        List<Opportunity> listOfChildOppsForSharingOverride = new List<Opportunity>();
        Set<Id> setOfParentOppIdsToProcess = new Set<Id>();
        List<Opportunity> listOfParentOpps = new List<Opportunity>();
        Set<Id> setOfRelatedTransactionIds = new Set<Id>();
        List<Opportunity> listOfRelatedTransactions = new List<Opportunity>();
        Set<Id> setOfOppToPopulateRevenueFiscalYear = new set<Id>();
        List<Opportunity> ChildOppsToPopulateRevenueFiscalYear = new List<Opportunity>();
        Set<Id> setOfParentIdsWithModifiedDepositsite = new set<Id>();
        List<Opportunity> listOfOpenChildOpps = new List<Opportunity>();
        list<Opportunity> listOfTransactionsForExpectedAmt = new list<Opportunity>();
        list<Opportunity> listOfTransactionsForClosedAmt = new list<Opportunity>();
        set<Id> setOfProposals = new set<Id>();
        Set<Id> setOfIdsOfParentProposalAndGrant = new Set<Id>();
        List<Opportunity> listOfProposalandGrant = new List<Opportunity>();
        Set<Id> setOfIdsOfDonations = new Set<Id>();
        List<Opportunity> listOfTransactions = new List<Opportunity>();
        list<Opportunity> listOfPledgePayments = new list<Opportunity>();
        Map<Id, Opportunity> parentOpptiesForStock = new Map<Id, Opportunity>();
        Map<Id, Decimal> setOfParentIdWithTaxValueToQueryChildOpp = new Map<Id, Decimal>();//added by bhavesh  T-647782
        Set<String> idsForAsync_Opp = new Set<String>();
        Set<Id> setPledgeDeonationOppty = new Set<Id>();
        Set<Id> setOldPledgeDeonationOppty = new Set<Id>();
        List<Opportunity> opptiesForExpDateReset;
        
        for(Opportunity objOppty : [
            SELECT Id, Bypass_Calculations__c, closeDate, account.Original_Join_Date__c, account.Membership_Expiration_date__c, 
              account.Has_Renewed_Before__c, StageName, SB_Originating_Form_ID__c,  rC_Giving__Source_Code__c, RecordTypeId, rC_Giving__Is_Sustainer__c,
              Sustainer_First_Payment__c, Prior_Source_Code__c, Original_Source_Code__c, CampaignId, Related_Transaction__c,
              rC_Giving__Parent__c, rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c, rC_Giving__Parent__r.Sustainer_First_Payment__c,
              rC_Giving__Parent__r.rC_Giving__Source_Code__c,
              rC_Giving__Parent__r.SB_Originating_Form_ID__c,
              rC_Giving__Parent__r.Market_Source_Date__c,
              rC_Giving__Parent__r.Form_Internal_Name__c,
              rC_Giving__Parent__r.SB_Gateway_Transaction_ID__c,
              rC_Giving__Parent__r.SB_Originating_Form_Name__c,
              rC_Giving__Parent__r.Initial_Market_Source_Affiliation__c,
              rC_Giving__Parent__r.Initial_Market_Source_Channel__c,
              rC_Giving__Parent__r.Initial_Market_Source_External__c,
              rC_Giving__Parent__r.Initial_Market_Source_Other__c,
              rC_Giving__Parent__r.Market_Source_External__c,
              rC_Giving__Parent__r.Market_Source_Affiliation__c,
              rC_Giving__Parent__r.Market_Source_Channel__c,
              rC_Giving__Parent__r.Market_Source_Other__c,
              rC_Giving__Parent__r.Payment_Subtype__c,
              rC_Giving__Parent__r.Referral_URL__c,
              rC_Giving__Parent__r.Initial_Referral_URL__c,
              rC_Giving__Parent__r.Search_Engine__c,
              rC_Giving__Parent__r.Search_String__c,                            
              LastModifiedDate, rC_Giving__Parent__r.CampaignId, 
              Source_Code_Override__c,
              rC_Giving__Planned_Giving__c,rC_Giving__Giving_Amount__c, Original_Amount__c, Prior_Amount__c, Sharing_Code__c, 
              IsClosed,accountId, amount,Portfolio__c, rC_Giving__Projected_Amount__c,Projected_Additional__c, Batch_Date__c, 
              Bank_Date__c, rC_Giving__Closed_Amount__c, Outstanding_Pledge_Amount__c, rC_Giving__Expected_Giving_Amount__c, 
              Set_Document_Attached__c, rC_Giving__Payment_Method__c, rC_Giving__Payment_Method_Selected__c,
              rC_Giving__Payment_Method_Selected__r.rC_Connect__Merchant_Name__c, Trigger_Attachment_Review_Process__c, OwnerId,
              Batch_Log__c, Batch_Log__r.Batch_Log_Type__c, Deposit_Site__c, Batch_Sequence__c,Sharing_Entity__c, 
              Sharing_Entity_Override__c, Payment_Subtype__c, Sharing_Code_Override__c,RPT_Package_Code__c,Restriction__c,
              Campaign_Type__c,Fundraising_Department__c, Account_Code__c,Program_Type__c,Fund__c,Revenue_Fiscal_Year__c,
              CampaignIdText__c,Proposal__c,Closed_Amount_Payments__c, Expected_Giving_Amount_Payments__c, Closed_Amount_Total__c, 
              Expected_Giving_Amount_Total__c,Acknowledgment_Code__c, Tax_Date__c, rC_Giving__Parent__r.rC_Giving__Affiliation__c,
              Campaign.rC_Giving__Source_Code__c,Has_Soft_Credits__c, Net_Amount__c, Fees__c, Tax_Value__c, //T-647782-added tax value
              Portfolio_2__c, Portfolio_3__c,rC_Giving__Parent__r.rC_Giving__Parent__c,rC_Giving__External_ID__c,SB_Donation_Id__c, 
              rC_Giving__Parent__r.SB_Donation_Id__c, Adjustment_Code__c
            FROM Opportunity
            WHERE Id IN : newLst ORDER BY LastModifiedDate ASC
            ]) {
                                         //GH-75 DEBUGGING

                                            System.debug('==after update start id =='+objOppty.Id);

                            System.debug('==after update start recordtype=='+objOppty.RecordTypeId);

                 if( objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id){
                      System.debug(LoggingLevel.Error, '=============after update=='+objOppty.stagename);
                    }                       
            // Update field rC_Giving__Rollup_Transactions__c to Null
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) && 
                 (objOppty.rC_Giving__Parent__c == null) && (oldMap.get(objOppty.Id).rC_Giving__Parent__c != null)) {
              setOfIdsOfParentProposalAndGrant.add(oldMap.get(objOppty.Id).rC_Giving__Parent__c);
            }
            // Method to update fieds on Soft credits if any field is updated on Related Transaction.
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) &&
                   (objOppty.rC_Giving__Source_Code__c != oldMap.get(objOppty.Id).rC_Giving__Source_Code__c ||
                   objOppty.Deposit_Site__c != oldMap.get(objOppty.Id).Deposit_Site__c || 
                   objOppty.RPT_Package_Code__c != oldMap.get(objOppty.Id).RPT_Package_Code__c ||
                   objOppty.Restriction__c != oldMap.get(objOppty.Id).Restriction__c || 
                   objOppty.Program_Type__c != oldMap.get(objOppty.Id).Program_Type__c ||
                   objOppty.Campaign_Type__c != oldMap.get(objOppty.Id).Campaign_Type__c || 
                   objOppty.Fund__c != oldMap.get(objOppty.Id).Fund__c ||
                   objOppty.Fundraising_Department__c != oldMap.get(objOppty.Id).Fundraising_Department__c ||
                   objOppty.Account_Code__c != oldMap.get(objOppty.Id).Account_Code__c ||
                   objOppty.Acknowledgment_Code__c != oldMap.get(objOppty.Id).Acknowledgment_Code__c ||
                   objOppty.CampaignIdText__c != oldMap.get(objOppty.Id).CampaignIdText__c)) {
                   
                   setOfRealtedTransactionIds.add(objOppty.Id);
            }

            // Method to update the Account code, Restriction, Fundraising Department And Fund Field on child oppties if updated on Parent
            //T-688679 Bhavesh,add or condition for SB_Donation_Id__c field((S-553223))
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) &&
                (objOppty.Restriction__c != oldMap.get(objOppty.Id).Restriction__c  
                || objOppty.Account_Code__c != oldMap.get(objOppty.Id).Account_Code__c
                || objOppty.Fundraising_Department__c != oldMap.get(objOppty.Id).Fundraising_Department__c  ||
                objOppty.rC_Giving__Source_Code__c != oldMap.get(objOppty.Id).rC_Giving__Source_Code__c ||
                objOppty.Fund__c != oldMap.get(objOppty.Id).Fund__c || objOppty.campaignId != oldMap.get(objOppty.Id).campaignId ||
                objOppty.Acknowledgment_Code__c != oldMap.get(objOppty.Id).Acknowledgment_Code__c )) { 
              setOfOppsForFieldUpdates.add(objOppty.Id);
            }
            
            
            // Method to update the Open child Transactions and Pledge Payments when Deposit Site is changed on Parent Pledge and Donation
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) &&
                 objOppty.Deposit_Site__c != oldMap.get(objOppty.Id).Deposit_Site__c  ) {
              setOfParentIdsWithModifiedDepositsite.add(objOppty.Id);
            }
            
            // Method to update the Tax Date on Transactions if updated on Parent Donation
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id && objOppty.Tax_Date__c != oldMap.get(objOppty.Id).Tax_Date__c  ) {
              setOfIdsOfDonations.add(objOppty.Id); 
            }

            // Populate variables to pass in processRollUp Method
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_ID || oldMap.get(objOppty.Id).RecordTypeId == OPPORTUNITY_RT_PROPOSAL_ID || 
                objOppty.RecordTypeId == OPPORTUNITY_RT_GRANT_Id || oldMap.get(objOppty.Id).RecordTypeId == OPPORTUNITY_RT_GRANT_Id) &&
               (objOppty.Portfolio__c != null || oldMap.get(objOppty.Id).Portfolio__c != null || 
                objOppty.Portfolio_2__c != null || oldMap.get(objOppty.Id).Portfolio_2__c != null || 
                objOppty.Portfolio_3__c != null || oldMap.get(objOppty.Id).Portfolio_3__c != null)
               && (objOppty.Portfolio__c != oldMap.get(objOppty.Id).Portfolio__c
                   || objOppty.Portfolio_2__c != oldMap.get(objOppty.Id).Portfolio_2__c
                   || objOppty.Portfolio_3__c != oldMap.get(objOppty.Id).Portfolio_3__c
                   || objOppty.rC_Giving__Projected_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Projected_Amount__c
                   || objOppty.Projected_Additional__c != oldMap.get(objOppty.Id).Projected_Additional__c
                   || objOppty.Closed_Amount_Total__c != oldMap.get(objOppty.Id).Closed_Amount_Total__c
                   || objOppty.Outstanding_Pledge_Amount__c != oldMap.get(objOppty.Id).Outstanding_Pledge_Amount__c
                   || objOppty.Expected_Giving_Amount_Total__c != oldMap.get(objOppty.Id).Expected_Giving_Amount_Total__c)
               ) {
                if( objOppty.Portfolio__c != NULL )
                    portFolioIds.add( objOppty.Portfolio__c );
                if( objOppty.Portfolio_2__c != NULL )
                    portFolioIds.add(objOppty.Portfolio_2__c);
                if( objOppty.Portfolio_3__c != NULL )
                    portFolioIds.add( objOppty.Portfolio_3__c );
                if( oldMap.get(objOppty.Id).Portfolio__c != NULL )
                    portFolioIds.add( oldMap.get(objOppty.Id).Portfolio__c );
                if( oldMap.get(objOppty.Id).Portfolio_2__c != NULL )
                    portFolioIds.add( oldMap.get(objOppty.Id).Portfolio_2__c );
                if( oldMap.get(objOppty.Id).Portfolio_3__c  != NULL )
                    portFolioIds.add( oldMap.get(objOppty.Id).Portfolio_3__c );
            }

            // Populate variables to pass in Planned giving Process Rollup Method
            if((objOppty.rC_Giving__Planned_Giving__c != oldMap.get(objOppty.Id).rC_Giving__Planned_Giving__c 
                && objOppty.rC_Giving__Planned_Giving__c != null) ||
                objOppty.rC_Giving__Expected_Giving_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Expected_Giving_Amount__c){
                    plannedGivingGifts.add(objOppty);
            }

            // Populate variables to pass in byPassCalculationsOnChild Method
            if(oldMap.get(objOppty.Id).Bypass_Calculations__c != objOppty.Bypass_Calculations__c 
                && objOppty.Bypass_Calculations__c == true
                && objOppty.rC_Giving__Parent__c == null){
                parentByPassCalculationGivingRecord.add(objOppty.Id);
            }

            // Populate variable to pass in createPreferenceOffIssues Method
            if(objOppty.CampaignId != oldMap.get(objOppty.Id).CampaignId) {
                if(objOppty.CampaignId != null 
                    && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id)){
                    mapCampaignAccount.put(objOppty.CampaignId,objOppty.AccountId);

                }
            }

            // Populate variables to passin sendEmailToOpportunityOwner Method
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.rC_Giving__Parent__c != null
                && objOppty.Amount != oldMap.get(objOppty.Id).Amount && objOppty.Amount != null) {
                setOfOpportunityIds.add(objOppty.rC_Giving__Parent__c);
            }

            // Populate variables in resetNGOCSharingRecords Method
            if(oldMap.get(objOppty.Id).AccountId != objOppty.AccountId ){
                accountIds.add(oldMap.get(objOppty.Id).AccountId);
                opportunityIds.add(objOppty.Id);
            }
            // Populate variables to pass in updateLastMembGiftOnAccount Method
            if(oldMap.get(objOppty.Id).recordTypeId != objOppty.recordTypeId || oldMap.get(objOppty.Id).amount != objOppty.amount ||
              oldMap.get(objOppty.Id).Sharing_Code__c!= objOppty.Sharing_Code__c|| oldMap.get(objOppty.Id).IsClosed != objOppty.IsClosed){
                if(objOppty.AccountId != null
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ||
                   objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id)
                && objOppty.IsClosed == true && objOppty.Sharing_Code__c!= null && objOppty.amount >= 5
                && (String.ValueOf(objOppty.Sharing_Code__c) != null && (String.ValueOf(objOppty.Sharing_Code__c).Startswith('A')
                                 || String.ValueOf(objOppty.Sharing_Code__c).Startswith('B') || String.ValueOf(objOppty.Sharing_Code__c).Startswith('D')
                                 || String.ValueOf(objOppty.Sharing_Code__c).Startswith('P')))){
                    mapAccIdTooppId.put(objOppty.AccountId, objOppty.Id);
                }
            }

            // Populate variable to pass in updateRenewableFieldonAccount Method
            if(objOppty.accountId != null && objOppty.Sharing_Code__c!= null && objOppty.account.Has_Renewed_Before__c == false
                      && (objOppty.Sharing_Code__c== 'P003' || objOppty.Sharing_Code__c== 'P009'
                            || objOppty.Sharing_Code__c== 'P001' || objOppty.Sharing_Code__c== 'P002')){
                accountNonRenewableIds.add(objOppty.accountId);
            }

            // Populate variable to pass in updateJointMembershipFlagonAccount Method
            if((objOppty.Amount != oldMap.get(objOppty.Id).Amount || objOppty.AccountId != oldMap.get(objOppty.Id).AccountId ||
                     objOppty.RecordTypeId != oldMap.get(objOppty.Id).RecordTypeId || objOppty.Sharing_Code__c != oldMap.get(objOppty.Id).Sharing_Code__c
                     || objOppty.StageName != oldMap.get(objOppty.Id).StageName) && (objOppty.Amount >= 30)
                   && (objOppty.AccountId != null)
                      && (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)
                   && (setOfSharingCodesForMembershipCampaign.contains(objOppty.Sharing_Code__c))
                   && (objOppty.StageName == 'Completed')) {
              setOfAccountIdsToUpdate.add(objOppty.AccountId);
            }
            
            // Populate variables to pass in populateSourceCodeValues Method
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.StageName != oldMap.get(objOppty.Id).StageName
                && objOppty.StageName == 'Completed' &&
              objOppty.rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c) {
                  /* Changes for :: I-57114 - Operational Source Codes not applied to sustainer pledge payment charges                */
                  if(objOppty.Sustainer_First_Payment__c && objOppty.Adjustment_Code__c != 'D') {
                      objOppty.rC_Giving__Source_Code__c = objOppty.rC_Giving__Parent__r.rC_Giving__Source_Code__c;
                      opptyMapToUpdate.put(objOppty.Id,objOppty);
                  } 
                 else {
                      /* DS- GH-34 - put conditional around call to retrieveSoureCode */
                     if (objOppty.Source_Code_Override__c == null || objOppty.Source_Code_Override__c == FALSE) {
                         objOppty = OpportunityManager.retrieveSourceCode(objOppty);
                     }
                    
                     if (objOppty.rC_Giving__Source_Code__c == null) {
                          objOppty.rC_Giving__Source_Code__c = objOppty.rC_Giving__Parent__r.rC_Giving__Source_Code__c;
                      }
                      opptyMapToUpdate.put(objOppty.Id,objOppty);
                  }
              } else if(objOppty.rC_Giving__Source_Code__c != null 
                        && objOppty.rC_Giving__Source_Code__c != oldMap.get(objOppty.Id).rC_Giving__Source_Code__c) {
                  objOppty.Prior_Source_Code__c = oldMap.get(objOppty.Id).rC_Giving__Source_Code__c;
                  if(objOppty.rC_Giving__Is_Sustainer__c) {
                      setToupdateFirstPaymentOnChild.add(objOppty.Id);
                  }
                  opptyMapToUpdate.put(objOppty.Id,objOppty);
                  if(!objOppty.rC_Giving__Is_Sustainer__c) {
                      opptyIdSet.add(objOppty.Id);
                  }
              } else if(objOppty.rC_Giving__Giving_Amount__c != null 
                    && objOppty.rC_Giving__Giving_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Giving_Amount__c) {
                  objOppty.Prior_Amount__c = oldMap.get(objOppty.Id).rC_Giving__Giving_Amount__c;
                  //Set Sustainer First Payment when Amount changes - I-284351
                  if(objOppty.rC_Giving__Is_Sustainer__c) {
                      setToupdateFirstPaymentOnChild.add(objOppty.Id);
                  }
                  opptyMapToUpdate.put(objOppty.Id,objOppty);
              }

             // Populate variable to pass in createDocumentAttachmentTask Method
            if(!objOppty.Set_Document_Attached__c && objOppty.Trigger_Attachment_Review_Process__c != null
                 && oldMap.get(objOppty.Id).Trigger_Attachment_Review_Process__c != objOppty.Trigger_Attachment_Review_Process__c) {
                opptyLstToCreateDocAttachTask.put(objOppty.Id, objOppty);
            }

            //Populate old map to pass in updateChildOpportunityFromBatchLog method
            if(objOppty.Batch_Log__c != oldMap.get(objOppty.Id).Batch_Log__c
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id|| objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) &&
                        (objOppty.Batch_Log__c != null) &&
                        objOppty.Batch_Log__r.Batch_Log_Type__c == 'Manual' 
                        || objOppty.Batch_Log__r.Batch_Log_Type__c == 'Vendor') {//Zendesk: #67314 - Added the batchlog type = Vendor in the if condition
                parentOpportunities.add(objOppty);
                //parentOpportunityIds.add(objOppty.id);//added by Bhavesh, this should be there to run updateChildOpportunityFromBatchLog fn in OpportunityManager class, this list size is checked in below code.
                parentOpptyOldMap.put(objOppty.Id, oldMap.get(objOppty.Id));
            }

            //populate Merchant Name
            //removed the checking with paymentMethod field change  (objOppty.rC_Giving__Payment_Method__c != oldMap.get(objOppty.Id).rC_Giving__Payment_Method__c || )
            if(objOppty.Deposit_Site__c != null && objOppty.rC_Giving__Payment_Method_Selected__c != null
                && ((objOppty.rC_Giving__Payment_Method_Selected__c != oldMap.get(objOppty.Id).rC_Giving__Payment_Method_Selected__c) ||
                     (objOppty.Deposit_Site__c != oldMap.get(objOppty.Id).Deposit_Site__c &&
                     (objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id|| objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) &&
                     (objOppty.stageName == 'Open' || objOppty.StageName == 'Completed')))){
                oppsToUpdateMerchantName.add(objOppty);
            }
            // Method to bring down Sharing fields from Parent to Child if Override checkboxes are checked
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id)
                   && (objOppty.Sharing_Code__c != oldMap.get(objOppty.Id).Sharing_Code__c
                         || objOppty.Sharing_Code_Override__c != oldMap.get(objOppty.Id).Sharing_Code_Override__c ||
                objOppty.Sharing_Entity__c != oldMap.get(objOppty.Id).Sharing_Entity__c
                   || objOppty.Sharing_Entity_Override__c != oldMap.get(objOppty.Id).Sharing_Entity_Override__c)
                   && (objOppty.Sharing_Entity_Override__c || objOppty.Sharing_Code_Override__c)) {
              setOfDonationsWithSharingFieldsUpdated.add(objOppty.Id);
            }

            // Method to set StageName to Open if stage of child record is Pending Failed
            if(objOppty.StageName == 'Pending Failed' && objOppty.rC_Giving__Parent__c != null &&
               (objOppty.RecordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || objOppty.RecordtypeId == OPPORTUNITY_RT_TRANSACTION_Id) &&
               (objOppty.StageName != oldMap.get(objOppty.Id).StageName)) {
                setOfParentOppIdsToProcess.add(objOppty.rC_Giving__Parent__c);
            }

            // Method to set setExcludeFromRevenueSharing to True, if Related Transaction field is changed on Soft Credits
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                && objOppty.Related_Transaction__c != null &&
               objOppty.Related_Transaction__c != oldMap.get(objOppty.Id).Related_Transaction__c) {
              setOfRelatedTransactionIds.add(objOppty.Related_Transaction__c);
            }

            // Method to populate the Revenue Fiscal Year on Child Opps if its is updated on Parent
            if(objOppty.Revenue_Fiscal_Year__c != oldMap.get(objOppty.Id).Revenue_Fiscal_Year__c) {
              setOfOppToPopulateRevenueFiscalYear.add(objOppty.Id);
            }


            // Populate variable to pass in setExpirationDate Method
            if(objOppty.AccountId != null 
                &&  ((oldMap.get(objOppty.Id).Sharing_Code__c != objOppty.Sharing_Code__c && objOppty.StageName == 'Completed') ||
                (oldMap.get(objOppty.Id).StageName != 'Completed' && objOppty.StageName == 'Completed'))
                && (objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
                    || objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id)
                    && objOppty.Sharing_Code__c!= null
                    && objOppty.account.Membership_Expiration_date__c != dateForSetExpirationMethod
                    && !objOppty.Has_Soft_Credits__c){
                setExpirationDatesOpps.add(objOppty);
            }

            // Populate variables to pass in Transaction Rollup Method
            if((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
                || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id 
                || oldMap.get(objOppty.Id).RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
                || oldMap.get(objOppty.Id).RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
                || objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id 
                || oldMap.get(objOppty.Id).RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id ) &&
            (objOppty.Proposal__c != null || oldMap.get(objOppty.Id).Proposal__c != null)){
                if(objOppty.Proposal__c != oldMap.get(objOppty.Id).Proposal__c 
                    || objOppty.Amount != oldMap.get(objOppty.Id).Amount) {
                    listOfTransactionsForExpectedAmt.add(objOppty);
                    if(objOppty.Proposal__c != null) setOfProposals.add(objOppty.Proposal__c);
                    if(oldMap.get(objOppty.Id).Proposal__c != null) setOfProposals.add(oldMap.get(objOppty.Id).Proposal__c);
                }
                if((objOppty.Proposal__c != oldMap.get(objOppty.Id).Proposal__c 
                    || objOppty.Amount != oldMap.get(objOppty.Id).Amount 
                    || objOppty.StageName != oldMap.get(objOppty.Id).StageName) && (objOppty.StageName == 'Completed' 
                    || oldMap.get(objOppty.Id).StageName == 'Completed')) {
                    listOfTransactionsForClosedAmt.add(objOppty);
                    if(objOppty.Proposal__c != null) setOfProposals.add(objOppty.Proposal__c);
                    if(oldMap.get(objOppty.Id).Proposal__c != null) setOfProposals.add(oldMap.get(objOppty.Id).Proposal__c);
                }
                //setOfProposals.add(objOppty.Proposal__c);
                //setOfProposals.add(oldMap.get(objOppty.Id).Proposal__c);
            }
            
            
            //Update Tax Date for Pledge Payments
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.CloseDate != oldMap.get(objOppty.Id).CloseDate) {
              objOppty.Tax_Date__c = objOppty.CloseDate;
              mapUpdateOpportunities.put(objOppty.Id,objOppty);
            }
            
            //T-641623
            if(objOppty.CampaignId != oldMap.get(objOppty.Id).CampaignId && objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) {
              listOfPledgePayments.add(objOppty);
            }
            
            //Update SB_Donation_Id__c when child record Stagename is updating to Completed and SB_Donation_Id__c is null.
            //I-319181 (S-553223), bhavesh  Desc: giving records created from BUP, then SB_Donation_Id__c should be populated from parent
            //AI-8, dseidman sync numerous fields between Parent and Child
            //Add qualification that child should be sustainer first payment (this should have been part
            //of the SB Donation ID syncing
      
            if( objOppty.Stagename == 'Completed' && objOppty.Stagename != oldMap.get(objOppty.id).Stagename 
                && ((objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && objOppty.Related_Transaction__c == null && objOppty.sustainer_first_payment__c == TRUE)
                || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)) {
               //BGE-102: Nchandwani, Commented Source field population from parent
                //OpportunityManager.pushParentSourceFieldsToFirstPayment(objOppty);
                mapUpdateOpportunities.put(objOppty.Id,objOppty);
            }
            
            //Stock Fields Caluculations
            if( objOppty.Net_Amount__c != oldMap.get(objOppty.Id).Net_Amount__c
                || objOppty.Fees__c != oldMap.get(objOppty.Id).Fees__c
                || objOppty.rC_Giving__Giving_Amount__c != oldMap.get(objOppty.Id).rC_Giving__Giving_Amount__c
                || objOppty.Amount != oldMap.get(objOppty.Id).Amount
            ){
                
                if( objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id ){
                    parentOpptiesForStock.put(objOppty.Id, objOppty);
                } else if( (objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id 
                        || objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) && !donationConvertedToPledge){
                    if( objOppty.Amount != null ){
                        if( objOppty.Net_Amount__c != NULL ){
                            objOppty.Fees__c = objOppty.Amount - objOppty.Net_Amount__c;
                        } else if( objOppty.Fees__c != NULL && objOppty.Net_Amount__c == NULL ){
                            objOppty.Net_Amount__c = objOppty.Amount - objOppty.Fees__c;
                        }
                    } else {
                        objOppty.Fees__c = NULL;
                        objOppty.Net_Amount__c = NULL;
                    }
                    donationConvertedToPledge = false;
                    mapUpdateOpportunities.put(objOppty.Id,objOppty);
                }
                    
            }
            //Added by Bhavesh For T-647782
            if( objOppty.Tax_Value__c != oldMap.get( objOppty.id ).Tax_Value__c ){
                setOfParentIdWithTaxValueToQueryChildOpp.put(objOppty.id, objOppty.Tax_Value__c);
            }

            if( (
                  ((objOppty.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) 
                        && objOppty.rC_Giving__Parent__c != null && objOppty.rC_Giving__Parent__r.rC_Giving__Parent__c != null) 
                  || (objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.Proposal__c != null )
                )
                && (
                      (oldMap.get(objOppty.Id).StageName != objOppty.StageName 
                          && (oldMap.get(objOppty.Id).StageName == 'Completed'  || objOppty.StageName == 'Completed') )
                      || oldMap.get(objOppty.Id).Amount != objOppty.Amount 
                      || objOppty.Program_Type__c != oldMap.get(objOppty.id).Program_Type__c
                      || objOppty.Deposit_Site__c != oldMap.get(objOppty.id).Deposit_Site__c)
            ) {
                if( objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id ){
                    idsForAsync_Opp.add(objOppty.Proposal__c);
                } else {
                    idsForAsync_Opp.add(objOppty.rC_Giving__Parent__r.rC_Giving__Parent__c);
                }
                
            }
            if( (objOppty.RecordTypeId == OPPORTUNITY_RT_DONATION_Id || objOppty.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) 
                && oldMap.get(objOppty.Id).rC_Giving__Parent__c != objOppty.rC_Giving__Parent__c 
            ) {
                if(oldMap.get(objOppty.Id).rC_Giving__Parent__c != null) {
                    idsForAsync_Opp.add(oldMap.get(objOppty.Id).rC_Giving__Parent__c);
                }
                idsForAsync_Opp.add(objOppty.rC_Giving__Parent__c);

            }
            if(objOppty.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id && objOppty.StageName == 'Completed' 
               && objOppty.Amount != null
               && oldMap.get(objOppty.Id).Proposal__c != objOppty.Proposal__c
            ) {
              if(oldMap.get(objOppty.Id).Proposal__c != null) {
                    idsForAsync_Opp.add(oldMap.get(objOppty.Id).Proposal__c);
              }
              idsForAsync_Opp.add(objOppty.Proposal__c);
            }

                                     //GH-75 DEBUGGING

                System.debug('==after update end recordtype=='+objOppty.RecordTypeId);
                System.debug('==after update end id =='+objOppty.Id);


        }
        list<AsyncRequest__c> newAsyncRequest = new list<AsyncRequest__c>();
        // Controls the number of Ids passed into a single AsyncRequest__c record for async processing
        while(idsForAsync_Opp.size() > 0) {
            if(idsForAsync_Opp.size() >= oppAsyncBatchMax){
                list<String> idList = new list<String>();
                Integer i = 1;
                for(String oppId : idsForAsync_Opp) {
                    idList.add(oppId);
                    idsForAsync_Opp.remove(oppId);
                    i++;
                    if(i==oppAsyncBatchMax) break;
                }
                newAsyncRequest.add( new AsyncRequest__c(
                                            AsyncType__c ='opp_rollToProposal', Object_API_Name__c = 'Opportunity',
                                            Params__c = String.join(idList,',')));
            } else {
                break;
            }
        }

        
        // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
        if(idsForAsync_Opp.size() > 0){
            newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='opp_rollToProposal', Object_API_Name__c = 'Opportunity',
                                    Params__c = String.join(new List<String>(idsForAsync_Opp),',')));
            /*try {*/
                  insert newAsyncRequest;
                  newAsyncRequest.clear();
                  
            /*} catch(Exception ex){
                  // or suggest using our ApexLog Asset to record the fail!
            }*/ 
        }

        if(accountIds.size() > 0 || setOfAccountIdsToUpdate.size() > 0) {
          for(Account acc : [SELECT Id, Affiliation__c, Household_Count__c, Joint_Membership_Flag__c
                             FROM Account
                             WHERE Id IN: accountIds OR Id IN: setOfAccountIdsToUpdate]) {
            if(accountIds.contains(acc.Id)) {
              listOfAccountsForNGOCSharing.add(acc);
            }
            if(setOfAccountIdsToUpdate.contains(acc.Id) && acc.Household_Count__c >=2 && (!acc.Joint_Membership_Flag__c)) {
              listOfAccountsWithJointMembershipFlag.add(acc);
            }
          }
        }

        if( setToupdateFirstPaymentOnChild.size() > 0 || setOfDonationsWithSharingFieldsUpdated.size() > 0 
            || parentOpportunityIds.size() > 0 || opptyIdSet.size() > 0
            || setOfOpportunityIds.size() > 0 || parentByPassCalculationGivingRecord.size() > 0 
            || setOfParentIdsWithModifiedDepositsite.size() > 0 
            || setOfRelatedTransactionIds.size() > 0 || setOfParentOppIdsToProcess.size() > 0 
            || setOfOppToPopulateRevenueFiscalYear.size() > 0
            || setOfOppsForFieldUpdates.size() > 0 || setOfRealtedTransactionIds.size() > 0 
            || setOfIdsOfParentProposalAndGrant.size() > 0 || setOfIdsOfDonations.size() > 0
            || setOfParentIdWithTaxValueToQueryChildOpp.size()> 0 ) {
          Set<Id> setOfOppsIds = new Set<Id>();
          Set<Id> setOfParentOppIds = new Set<Id>();
          setOfOppsIds.addAll(setOfParentOppIdsToProcess);
          setOfOppsIds.addAll(setOfRelatedTransactionIds);
          setOfOppsIds.addAll(setOfOpportunityIds);
          setOfParentOppIds.addAll(setToupdateFirstPaymentOnChild);
          setOfParentOppIds.addAll(setOfDonationsWithSharingFieldsUpdated);
          setOfParentOppIds.addAll(opptyIdSet);
          setOfParentOppIds.addAll(parentOpportunityIds);
          setOfParentOppIds.addAll(parentByPassCalculationGivingRecord);
          setOfParentOppIds.addAll(setOfOppToPopulateRevenueFiscalYear);
          setOfParentOppIds.addAll(setOfOppsForFieldUpdates);
          setOfParentOppIds.addAll(setOfParentIdsWithModifiedDepositsite);
          setOfParentOppIds.addAll(setOfIdsOfDonations);
          setOfOppsIds.addAll(setOfIdsOfParentProposalAndGrant);
          setOfParentOppIds.addAll(setOfParentIdWithTaxValueToQueryChildOpp.keySet());//added by bhavesh  T-647782
          
          for(Opportunity opp : [
              SELECT Id, rC_Giving__Source_Code__c, rC_Giving__Parent__r.rC_Giving__Source_Code__c,rC_Giving__Is_Sustainer__c,
                rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c, Auto_Giving_Number__c, campaignId,
                rC_Giving__Parent__r.Sharing_Code_Override__c, rC_Giving__Parent__r.Sharing_Entity_Override__c,
                rC_Giving__Parent__c, Batch_Sequence__c, Batch_Log__c, Deposit_Site__c,RecordTypeId, StageName,
                Exclude_from_Revenue_Sharing__c, OwnerId, Name, rC_Giving__Parent__r.Deposit_Site__c,
                rC_Giving__Parent__r.Sharing_Entity__c,rC_Giving__Parent__r.Sharing_Code__c,
                Related_Transaction__r.rC_Giving__Source_Code__c,Related_Transaction__r.Deposit_Site__c,
                Related_Transaction__r.RPT_Package_Code__c,Related_Transaction__r.Restriction__c,
                Related_Transaction__r.Program_Type__c,Related_Transaction__r.Campaign_Type__c,
                Related_Transaction__r.Fund__c,rC_Giving__Parent__r.Restriction__c, rC_Giving__Parent__r.Account_Code__c,
                Related_Transaction__r.campaignId, rC_Giving__Parent__r.Fundraising_Department__c,rC_Giving__Parent__r.Fund__c,
                Related_Transaction__r.Account_Code__c,Related_Transaction__r.Fundraising_Department__c,
                Related_Transaction__r.CampaignIdText__c, rC_Giving__Parent__r.Revenue_Fiscal_Year__c,
                rC_Giving__Parent__r.CampaignId,rC_Giving__Parent__r.Acknowledgment_Code__c,
                rC_Giving__Acknowledged_Date__c,Acknowledgment_Status__c,rC_Giving__Parent__r.Tax_Date__c,
                Related_Transaction__r.Acknowledgment_Code__c,rC_Giving__Rollup_Giving__c,Tax_Value__c,//T-647782-added tax value
                rC_Giving__Giving_Amount__c, rC_Giving__Parent__r.rC_Giving__Giving_Amount__c,rC_Giving__External_ID__c,SB_Donation_Id__c,
                rC_Giving__Parent__r.SB_Donation_Id__c
              FROM Opportunity
              WHERE (rC_Giving__Parent__c IN : setOfParentOppIds
                OR Id IN : setOfOppsIds
                OR Related_Transaction__c IN : setOfRealtedTransactionIds
                )
              ORDER BY Auto_Giving_Number__c ASC
              ]) {
            if(setOfIdsOfParentProposalAndGrant != null && setOfIdsOfParentProposalAndGrant.contains(opp.Id) && opp.rC_Giving__Rollup_Giving__c != null &&
              (opp.RecordTypeId == OPPORTUNITY_RT_GRANT_Id || opp.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_Id)) {
              listOfProposalandGrant.add(opp);  
            }
            if((setToupdateFirstPaymentOnChild!= null && setToupdateFirstPaymentOnChild.contains(opp.rC_Giving__Parent__c))
                 || (opptyIdSet != null && opptyIdSet.contains(opp.rC_Giving__Parent__c))) {
              listOfChildOpps.add(opp);
            }
            if(setOfDonationsWithSharingFieldsUpdated!= null && setOfDonationsWithSharingFieldsUpdated.contains(opp.rC_Giving__Parent__c)) {
              listOfChildOppsForSharingOverride.add(opp);
            }
            if(parentOpportunityIds!= null && parentOpportunityIds.contains(opp.rC_Giving__Parent__c)
              && (opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id|| opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)) {
              listOfOppsForBatchLog.add(opp);
            }
            if(setOfOpportunityIds != null && setOfOpportunityIds.contains(opp.Id)) {
              listOfOppToSendEmailToOwner.add(opp);
            }
            if(setOfRealtedTransactionIds!= null && setOfRealtedTransactionIds.contains(opp.Related_Transaction__c)
                && ((opp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) 
                    || (opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && opp.Related_Transaction__c != null))) {
              listOfChilfSoftCredits.add(opp);
            }
            if(parentByPassCalculationGivingRecord!= null && parentByPassCalculationGivingRecord.contains(opp.rC_Giving__Parent__c)) {
              parentByPassCalculationGivingRecordList.add(opp);
            }
            if(setOfRelatedTransactionIds!= null && setOfRelatedTransactionIds.contains(opp.Id) && (!opp.Exclude_from_Revenue_Sharing__c)) {
              listOfRelatedTransactions.add(opp);
            }
            if(setOfParentOppIdsToProcess!= null && setOfParentOppIdsToProcess.contains(opp.Id)) {
              listOfParentOpps.add(opp);
            }
            if(setOfOppToPopulateRevenueFiscalYear!= null && setOfOppToPopulateRevenueFiscalYear.contains(opp.rC_Giving__Parent__c)) {
              ChildOppsToPopulateRevenueFiscalYear.add(opp);
            }
            if((setOfOppsForFieldUpdates != null) && (setOfOppsForFieldUpdates.contains(opp.rC_Giving__Parent__c)) && 
              ((opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && opp.Related_Transaction__c == null) 
                || (opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id))) {
              listOfChildOppsForFieldUpdates.add(opp);
              
            }
            if((setOfParentIdsWithModifiedDepositsite != null) && (setOfParentIdsWithModifiedDepositsite.contains(opp.rC_Giving__Parent__c))
                    && ((opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && opp.StageName != 'Completed' && opp.Related_Transaction__c == null) 
                            || (opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id))) {
              listOfOpenChildOpps.add(opp);
            }
            if(setOfIdsOfDonations != null && setOfIdsOfDonations.contains(opp.rC_Giving__Parent__c) && opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) {
              listOfTransactions.add(opp);  
            }
            //Added by Bhavesh For T-647782
            if( setOfParentIdWithTaxValueToQueryChildOpp.containsKey( opp.rC_Giving__Parent__c) 
                && ( opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                && opp.Tax_Value__c != setOfParentIdWithTaxValueToQueryChildOpp.get( opp.rC_Giving__Parent__c )
            ){
                opp.Tax_Value__c = setOfParentIdWithTaxValueToQueryChildOpp.get( opp.rC_Giving__Parent__c );
                mapUpdateOpportunities.put(opp.id, opp);
            }
          }
        }
        //Method to update Tax Date on Transactions if Updated On Donation
        if(!listOfTransactions.isEmpty()) {
            mapUpdateOpportunities = OpportunityManager.updateTaxDateOnChildOpps(listOfTransactions,mapUpdateOpportunities);
        }
        
        // Method to Null Out rC_Giving__Rollup_Giving__c field when Parent is blank out on Parrent or Donation
        if(!listOfProposalandGrant.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.updateRollUpGivingOnGrantAndProposal(listOfProposalandGrant, mapUpdateOpportunities); 
        }
        // Method to popualte fields for Soft Credits When any field on related transaction is modified
        if(!listOfChilfSoftCredits.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.updateFieldsOnSoftCredits(listOfChilfSoftCredits, mapUpdateOpportunities);
        }

        // Method to update the Account code, Restriction, Fundraising Department And Fund Field on child oppties if updated on Parent
        if(!listOfChildOppsForFieldUpdates.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.updateFieldsonChildOpps(listOfChildOppsForFieldUpdates,mapUpdateOpportunities);
        }

        // Method to update the Deposit Site on Open Childs When Updated On Parent
        if(!listOfOpenChildOpps.isEmpty()) {
            mapUpdateOpportunities = OpportunityManager.updateDepositSiteOnChildOpps(listOfOpenChildOpps,mapUpdateOpportunities);
        }
        
        // Method to update Last Membership Gift on Account
        if(!mapAccIdTooppId.KeySet().IsEmpty())
            mapUpdateAccounts = OpportunityAccountManager.updateLastMembGiftOnAccount(mapAccIdTooppId, mapUpdateAccounts);

        //populate Merchant Name
        if(!oppsToUpdateMerchantName.IsEmpty()){
            paymentMethods = OpportunityManager.updateMerchantName(oppsToUpdateMerchantName);
        }

        // Method to reset NGOC Sharing Codes
        if(!listOfAccountsForNGOCSharing.isEmpty()) {
            for(Account acc: listOfAccountsForNGOCSharing){
                if(acc.Affiliation__c != null)
                    OldAffiliations.add(acc.Affiliation__c);
            }

            if(!OldAffiliations.isEmpty()){
                OpportunityManager.resetNGOCSharingRecords(opportunityIds, OldAffiliations);
            }
        }
        // Method to create preference records based on Pref Code
        if(mapCampaignAccount.size() > 0) {
            OpportunityManager.createPreferenceOffIssues(mapCampaignAccount);
        }

        // Method to send Email to Opportunity Owners
        if(!listOfOppToSendEmailToOwner.isEmpty()) {
            OpportunityManager.sendEmailToOpportunityOwner(listOfOppToSendEmailToOwner);
        }
        // Method to populate Source Code on Oppties
        if(!opptyMapToUpdate.IsEmpty()){
            mapUpdateOpportunities = OpportunityManager.populateSourceCodeValues(opptyMapToUpdate, listOfChildOpps, mapUpdateOpportunities);
        }
        // Method to Update the Renewable on account
        if(!accountNonRenewableIds.isEmpty()){
            mapUpdateAccounts = OpportunityAccountManager.updateRenewableFieldonAccount(accountNonRenewableIds, mapUpdateAccounts);
        }

        // Method to set StageName to Open if stage of child record is Pending Failed
        if(!listOfParentOpps.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.setStageToOpenIfPendingFailed(listOfParentOpps,mapUpdateOpportunities);
        }

        // Method to set setExcludeFromRevenueSharing to True, if Related Transaction field is changed on Soft Credits
        if(!listOfRelatedTransactions.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.setExcludeFromRevenuesharingField(listOfRelatedTransactions,mapUpdateOpportunities);
        }

        // Method to populate the Revenue Fiscal Year on Child Opps if its is updated on Parent
        if(!ChildOppsToPopulateRevenueFiscalYear.isEmpty()) {
          mapUpdateOpportunities = OpportunityManager.setRevenueFiscalYear(ChildOppsToPopulateRevenueFiscalYear,mapUpdateOpportunities);
        }

        // Method to update child records By Pass Calculation Flag
        if(!parentByPassCalculationGivingRecordList.IsEmpty()){
            mapUpdateOpportunities = OpportunityManager.byPassCalculationsOnChild(parentByPassCalculationGivingRecordList, mapUpdateOpportunities);
        }
        
        // Method to populate Joint Membership Flag on Account
        if(!listOfAccountsWithJointMembershipFlag.isEmpty()) {
            mapUpdateAccounts = OpportunityAccountManager.updateJointMembershipFlagonAccount(listOfAccountsWithJointMembershipFlag, mapUpdateAccounts);
        }

        // Method to Bring Down Sharing Code, Sharing Entity, Sharing Code Override and Sharing Entitiy Override on Transactions from Parent Donations.
        if(!listOfChildOppsForSharingOverride.isEmpty()) {
          mapUpdateOpportunities = bringSharingCodeAndEntityFieldToChild(listOfChildOppsForSharingOverride, mapUpdateOpportunities);
        }
    
        // Method to populate Expiration Date on Account
        if(!setExpirationDatesOpps.Isempty()){
            
          /* Traction(Mounica V): BGE-22, 12/2/2019 : Removing the logic to flag a batch to 'Membership and Revenue Sharing Resets Needed' 
            opptiesForExpDateReset = new List<Opportunity>();
            
            if(!RevenueSharingShareCodes.flaggedOpptySet.isEmpty()) {
                for(Opportunity objOppty : setExpirationDatesOpps) {
                    if(!RevenueSharingShareCodes.flaggedOpptySet.contains(objOppty.Id)) {
                        opptiesForExpDateReset.add(objOppty);
                    }
                }
            } else {
                opptiesForExpDateReset = setExpirationDatesOpps;
            }
            
            
            setExpirationDatesOpps = RevenueSharingShareCodes.flagMembershipShareCodeReset(opptiesForExpDateReset, oldMap);
            if(!setExpirationDatesOpps.Isempty()){ */
                RevenueSharingShareCodes.OpportunitiesAndAccountWrapper wrapper = RevenueSharingShareCodes.setExpirationDate(setExpirationDatesOpps,
                                                                                            mapUpdateAccounts, mapUpdateOpportunities);
                mapUpdateAccounts = wrapper.mapaccounts;
                mapUpdateOpportunities =  wrapper.mapOpportunities;
           // }BGE -22 END
            
        }
        
        //Method to update Child Transaction and Pledge Payment
        if(!parentOpportunities.isEmpty()) {
            mapUpdateOpportunities = OpportunityManager.updateChildOpportunityFromBatchLog(parentOpportunities, parentOpptyOldMap,
                                                                                    listOfOppsForBatchLog,mapUpdateOpportunities);
        }
        
        //T-641623
        if(listOfPledgePayments.size() > 0) {
            for(Opportunity opp : listOfPledgePayments) {
                if(mapUpdateOpportunities.containsKey(opp.Id)) {
                    mapUpdateOpportunities.get(opp.Id).rC_Giving__Source_Code__c = opp.Campaign.rC_Giving__Source_Code__c;
                    mapUpdateOpportunities.get(opp.Id).CampaignIdText__c = opp.CampaignId;
                } else {
                    opp.rC_Giving__Source_Code__c = opp.Campaign.rC_Giving__Source_Code__c;
                    opp.CampaignIdText__c = opp.CampaignId;
                    mapUpdateOpportunities.put(opp.Id, opp);
                }
            }
        }
        
        
        
        // Stock Calucaltions
        if(!parentOpptiesForStock.isEmpty()) {
            mapUpdateOpportunities = OpportunityManager.opptyStockCalculation(parentOpptiesForStock, mapUpdateOpportunities); 
        }
        // Dml Operation on Account
        if(!mapUpdateAccounts.KeySet().IsEmpty()){
            calculateFeesAndNetAmount = FALSE;
            update mapUpdateAccounts.Values();
            calculateFeesAndNetAmount = TRUE;
        }
        
        // DML Operation on Opportunity
        if(!mapUpdateOpportunities.isEmpty()) {
            //Utilities.runOnce = true;
            update mapUpdateOpportunities.values();
        }
        
        // DML Operation on PaymentMetod
        if(!paymentMethods.IsEmpty()){
            update paymentMethods.Values();
        }

        // Rolls up Values On Portfolio
        if(portFolioIds != null) {
          RSFUtility.updatePortfolioRollUpRecords(portFolioIds);
        }

        // Rolls up Values on Planned Giving Object
        if(!plannedGivingGifts.IsEmpty()){
            RSFUtility.rollUpTrigger(pGFieldDefinitions, plannedGivingGifts, 'Opportunity', 'rC_Giving__Planned_Giving__c', 
              'rC_Giving__Planned_Giving__c','');
        }

        // Method to create Task for Document Attachment
        if(!opptyLstToCreateDocAttachTask.isEmpty()) {
            OpportunityManager.createDocumentAttachmentTask(opptyLstToCreateDocAttachTask);
        }
        // Rolls up Values on Opportunity Object
        if(!listOfTransactionsForExpectedAmt.IsEmpty()){
            RSFUtility.processRollUp(oppFieldDefinitionsExpectedAmt, listOfTransactionsForExpectedAmt, 'Opportunity', 'Proposal__c',
                                         'Opportunity',' AND (RecordTypeId =\''+ 
                                        OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''
                                        +OPPORTUNITY_RT_SOFT_CREDIT_Id
                                        +'\' OR RecordTypeId =\''+ 
                                        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+'\' )',
                                         setOfProposals);
        }
        if(!listOfTransactionsForClosedAmt.IsEmpty()){
            RSFUtility.processRollUp(oppFieldDefinitionsClosedAmt, listOfTransactionsForClosedAmt, 'Opportunity', 'Proposal__c',
                                        'Opportunity',' AND (RecordTypeId =\''+ 
                                        OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''+
                                        OPPORTUNITY_RT_SOFT_CREDIT_Id+'\' OR RecordTypeId =\''+ 
                                        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+
                                        '\' ) AND StageName = \'Completed\' ', setOfProposals);
        }
        
    }

    /*
    *
    *Method afterDelete
    *@param : oldList
    *@description : calls on afterDelete
    *
    */
    private static void afterDelete(List<Opportunity> oldList) {
        Set<Id> portFolioIds = new Set<Id>();
        List<Opportunity> plannedGivingGifts = new List<Opportunity>();
        //list<Id> idsForAsync_Opp = new list<Id>();
        list<Opportunity> listOfTransactionsForExpectedAmt = new list<Opportunity>();
        list<Opportunity> listOfTransactionsForClosedAmt = new list<Opportunity>();
        Set<Id> setOfRelatedTransactionIds = new Set<Id>();
        Set<Id> setOfRelatedTransactionsWithChilds = new Set<Id>();
        List<Opportunity> listOfRelatedTransactions = new List<Opportunity>();
        for(Opportunity theOpp : oldList) {
            if((theOpp.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_ID 
                || theOpp.RecordTypeId == OPPORTUNITY_RT_GRANT_Id) && ( theOpp.Portfolio__c != null 
                || theOpp.Portfolio_2__c != null  || theOpp.Portfolio_3__c != null )) {
                if( theOpp.Portfolio__c != NULL )
                    portFolioIds.add( theOpp.Portfolio__c );
                if( theOpp.Portfolio_2__c != NULL )
                    portFolioIds.add(theOpp.Portfolio_2__c);
                if( theOpp.Portfolio_3__c != NULL )
                    portFolioIds.add( theOpp.Portfolio_3__c );
            }
            //Planned Giving Rollup
            if(theOpp.rC_Giving__Planned_Giving__c != null && theOpp.rC_Giving__Expected_Giving_Amount__c != null){
                plannedGivingGifts.add(theOpp);
            }
            //Transactions Rollup
            if((theOpp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
                || theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) && theOpp.Proposal__c != null ) {
                listOfTransactionsForExpectedAmt.add(theOpp);
                if(theOpp.StageName == 'Completed') {
                    listOfTransactionsForClosedAmt.add(theOpp);
                }
            }
            if((theOpp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id 
                || theOpp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id) && theOpp.Related_Transaction__c != null) {
              setOfRelatedTransactionIds.add(theOpp.Related_Transaction__c);    
            }
        }
        RSFUtility.updatePortfolioRollUpRecords(portFolioIds);

        //Planned Giving Rollup
        RSFUtility.rollUpTrigger(pGFieldDefinitions, plannedGivingGifts, 'Opportunity', 'rC_Giving__Planned_Giving__c', 
          'rC_Giving__Planned_Giving__c','');

        if(!listOfTransactionsForExpectedAmt.isEmpty()) {
            RSFUtility.rollUpTrigger(oppFieldDefinitionsExpectedAmt, listOfTransactionsForExpectedAmt, 'Opportunity', 
              'Proposal__c', 'Opportunity',' AND (RecordTypeId =\''+ OPPORTUNITY_RT_TRANSACTION_Id+
              '\' OR RecordTypeId =\''+ OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+'\' )');
        }
        if(!listOfTransactionsForClosedAmt.isEmpty()) {
            RSFUtility.rollUpTrigger(oppFieldDefinitionsClosedAmt, listOfTransactionsForClosedAmt, 'Opportunity', 'Proposal__c', 
              'Opportunity',' AND (RecordTypeId =\''+ OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''+ 
              OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+'\' ) AND StageName = \'Completed\' ');
        }
        
        if(setOfRelatedTransactionIds != null ) {
          for(Opportunity opp : [SELECT Id, Related_Transaction__r.Exclude_from_Revenue_Sharing__c,Related_Transaction__c
                                 FROM Opportunity
                                 WHERE Related_Transaction__c IN : setOfRelatedTransactionIds
                                 AND (RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id OR RecordTypeId =: OPPORTUNITY_RT_SOFT_CREDIT_Id)]) {
            setOfRelatedTransactionsWithChilds.add(opp.Related_Transaction__c);
          }    
        }
        
        for(String oppId : setOfRelatedTransactionIds) {
          if(!setOfRelatedTransactionsWithChilds.contains(oppId)) {
            listOfRelatedTransactions.add(new Opportunity(Id = oppId, Exclude_from_Revenue_Sharing__c = False, Recalculate_Revenue_Share__c = True));
          }
        }    
        
        if(!listOfRelatedTransactions.isEmpty()) {
          update listOfRelatedTransactions; 
        }
    }

    /*
    *
    *Method afterUnDelete
    *@param : newList
    *@description : calls on afterUnDelete
    *
    */
    private static void afterUnDelete(List<Opportunity> newList) {
        Set<Id> portFolioIds = new Set<Id>();
        List<Opportunity> plannedGivingGifts = new List<Opportunity>();
        List<Opportunity> listOfTransactionsForExpectedAmt = new List<Opportunity>();
        List<Opportunity> listOfTransactionsForClosedAmt = new List<Opportunity>();

        for(Opportunity theOpp : newList) {
            if((theOpp.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_ID 
                || theOpp.RecordTypeId == OPPORTUNITY_RT_GRANT_Id) && ( theOpp.Portfolio__c != null 
                    || theOpp.Portfolio_2__c != NULL || theOpp.Portfolio_3__c != NULL )) {
                if( theOpp.Portfolio__c != NULL )
                    portFolioIds.add( theOpp.Portfolio__c );
                if( theOpp.Portfolio_2__c != NULL )
                    portFolioIds.add(theOpp.Portfolio_2__c);
                if( theOpp.Portfolio_3__c != NULL )
                    portFolioIds.add( theOpp.Portfolio_3__c );
            }
            //Planned Giving Rollup
            if(theOpp.rC_Giving__Planned_Giving__c != null && theOpp.rC_Giving__Expected_Giving_Amount__c != null){
                plannedGivingGifts.add(theOpp);
            }

            //Transcation Rollup
            if((theOpp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
                || theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) && theOpp.Proposal__c != null ) {
                listOfTransactionsForExpectedAmt.add(theOpp);
                if(theOpp.StageName == 'Completed') {
                    listOfTransactionsForClosedAmt.add(theOpp);
                }
            }
        }
        RSFUtility.updatePortfolioRollUpRecords(portFolioIds);

        //Planned Giving Rollup
        RSFUtility.rollUpTrigger(pGFieldDefinitions, plannedGivingGifts, 'Opportunity', 'rC_Giving__Planned_Giving__c', 
          'rC_Giving__Planned_Giving__c','');

        if(!listOfTransactionsForExpectedAmt.isEmpty()) {
            RSFUtility.rollUpTrigger(oppFieldDefinitionsExpectedAmt, listOfTransactionsForExpectedAmt, 'Opportunity', 
              'Proposal__c', 'Opportunity',' AND (RecordTypeId =\''+ OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''+ 
              OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+'\' )');
        }
        if(!listOfTransactionsForClosedAmt.isEmpty()) {
            RSFUtility.rollUpTrigger(oppFieldDefinitionsClosedAmt, listOfTransactionsForClosedAmt, 'Opportunity', 
              'Proposal__c', 'Opportunity',' AND (RecordTypeId =\''+ OPPORTUNITY_RT_TRANSACTION_Id+'\' OR RecordTypeId =\''+ 
              OPPORTUNITY_RT_PLEDGE_PAYMENT_Id+'\' ) AND StageName = \'Completed\' ');
        }
    }

    // Method to Bring Down Sharing Code, Sharing Entity, Sharing Code Override and Sharing Entitiy Override on Transactions from Parent Donations.
    private static Map<Id,Opportunity> bringSharingCodeAndEntityFieldToChild(List<Opportunity> listOfChildOpps, Map<Id, Opportunity> mapUpdateOpportunities) {
      List<Opportunity> listOfUpdatedChildOpps = new List<Opportunity>();
      for(Opportunity child : listOfChildOpps) {
        if(child.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || child.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) {
          if(child.rC_Giving__Parent__r.Sharing_Code_Override__c) {
            child.Sharing_Code_Override__c = True;
            child.Sharing_Code__c = child.rC_Giving__Parent__r.Sharing_Code__c != null
                                  ? child.rC_Giving__Parent__r.Sharing_Code__c
                                  : child.Sharing_Code__c ;
          }
          if(child.rC_Giving__Parent__r.Sharing_Entity_Override__c) {
            child.Sharing_Entity_Override__c = True;
            child.Sharing_Entity__c = child.rC_Giving__Parent__r.Sharing_Entity__c != null
                                    ? child.rC_Giving__Parent__r.Sharing_Entity__c
                                    : child.Sharing_Entity__c;
          } 
          mapUpdateOpportunities.put(child.Id,child);
        }
      }
      return mapUpdateOpportunities;
    }
    
    /**********************
     * Created by: Bhavesh malviya
     * Task: T-647782
     * *******************/
    public static Opportunity getTaxValueCalculations( Opportunity opt, Opportunity oldOpt ){
        if( ( oldOpt != NULL && oldOpt.Tax_Value__c != opt.Tax_Value__c ) || ( oldOpt == NULL && opt.Tax_Value__c != NULL ) ){
            //do nothing here.
        }
        else if( opt.recordTypeId != OPPORTUNITY_RT_SOFT_CREDIT_Id ){
            if( ( opt.Low_Amount__c != null && opt.High_Amount__c != null 
                && opt.rC_Giving__Number_Of_Shares__c != null ) 
                && ( oldOpt == NULL 
                    || opt.Low_Amount__c != oldOpt.Low_Amount__c || opt.High_Amount__c != oldOpt.High_Amount__c 
                    || opt.rC_Giving__Number_Of_Shares__c != oldOpt.rC_Giving__Number_Of_Shares__c)
            ){
                //Calculate the Tax Value. 
                // Tax value = ((High_Amount__c+Low_Amount__c)/2)*rC_Giving__Number_Of_Shares__c 
                opt.Tax_Value__c = ( (opt.Low_Amount__c + opt.High_Amount__c ) / 2) * opt.rC_Giving__Number_Of_Shares__c.setScale(2) ;
            }
            
            else if( opt.Tax_Value__c == NULL 
                || (oldOpt != NULL && (oldOpt.Amount != opt.Amount || oldOpt.rC_Giving__Giving_Amount__c != opt.rC_Giving__Giving_Amount__c))
            ){
                if( opt.recordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opt.recordTypeId == OPPORTUNITY_RT_TRANSACTION_Id ){
                    opt.Tax_Value__c = opt.Amount;
                }
                else {
                    opt.Tax_Value__c = opt.rC_Giving__Giving_Amount__c;
                } 
            }
        }
        else if( opt.recordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id ){
            if( oldOpt == NULL  ){ 
                opt.Tax_Value__c = opt.Amount;
            } else if( oldOpt.Tax_Value__c != opt.Tax_Value__c ){//Updated for I-305737, Bhavesh
                //Do Nothing 
            } else if( oldOpt.Amount != opt.Amount ){//Updated for I-305737, Bhavesh
                opt.Tax_Value__c = opt.Amount;
            }
            
        }
        return opt;
    }
     

    /**
     * @name getSharingCodeMap
     * @description Method to get Sharing code map with share_code and share_code_description
     * @date 19 June 2020
     */
    private static Map<String,string> getSharingCodeMap(){
        Map<String, Share_Source_Revenue_Codes__c> mapShareCodeTable = Share_Source_Revenue_Codes__c.getAll();
        Map<String,string> mapShareCodetoDescription = new Map<String,string>();
        for( String oShare : mapShareCodeTable.keyset() ){
            mapShareCodetoDescription.put(mapShareCodeTable.get(oshare).Share_Code__c,mapShareCodeTable.get(oshare).Share_Code_Description__c);
        }
        return mapShareCodetoDescription;
    }
     
     
    
}