/*
*
*Name  :  RevenueSharingShareCodes
*Author:  Appirio India (Sai Krishna)
*Date  :  December 2, 2016
*Purpose : Purpose of class is a helper class to set revenue sharing related fields
           Class called from BatchLogTrigger, OpportuntiyCampaignManager, OpportunityTriggerHandler
           The main use case is from OpportunityTriggerHandler (which often invokes OpportuntiyCampaignManager)
           Contains methods to 
           1. Set sharing code and other sharing related fields on opportunities. (setShareCode calls additionalGCL and others)
           2. Set the Membership Expiration date on Accounts. (setExpirationDate)
           3. Flag Opportunities for MembershipShareCode reset. (flagMembershipShareCodeReset)

           Business logic for all these methods is within this document:
           https://www.acluloop.org/teamsites/ACLU_CRM_Shared/Shared%20Documents/Vendor%20Documentation/Appirio/Sharing%20Codes%2C%20Source%20Codes%2C%20Revenue%20Sharing%20for%20ACLU.xlsx?Web=1"
*Change Log : Traction(Mounica V), November 22,2019-Ticket:BGE-6 : Moved all the Sharing_Code_Description__c assigments inside the for loop.
*Change Log : Traction(Mounica V), November 25,2019-Ticket:BGE-71 : Added sharing entity override check in the setAccountAffiliation Method.
*	Ticket 		Modified Date		Modified by				Purpose
*   #74075        02/26/2020		SFDO (Kirti Rathod)     set the expiration date to null 
*   #75631        04/07/2020        SFDO                    Sharing Code Entity Override on campaign
*/
public with sharing class RevenueSharingShareCodes {
    public static Set<Id> flaggedOpptySet;
    static {
        flaggedOpptySet = new Set<Id>();
    }

    //public OpportunitiesAndAccountWrapper wrapperClass;
    
    /*
    *
    *Method setExpirationDate
    *sets the Expiration date to the related account.
    */
    public static OpportunitiesAndAccountWrapper setExpirationDate(List<Opportunity> opportunities, map<Id, Account> mapUpdateAccounts, map<Id, Opportunity> mapUpdateOpps ){
        OpportunitiesAndAccountWrapper wrapperClass = new OpportunitiesAndAccountWrapper();
        for(opportunity opp: opportunities){
            
            // TB added May 20, 2018 for zero or null amount
            if(opp.Amount == null || opp.Amount <= 0) continue;
            
            Account acc ;
            opportunity opp1;
            // Account record map
            if(mapUpdateAccounts.get(opp.accountId) != null){
                acc = mapUpdateAccounts.get(opp.accountId);
            }
            else{
                acc = new Account(Id = opp.accountId);
            }
            // Opportunity record map
            if(mapUpdateOpps.get(opp.Id) != null){
                opp1 = mapUpdateOpps.get(opp.Id);
            }
            else{
                opp1 = new Opportunity(Id = opp.Id);
            } 
            // in Kind or  General Incentive
            if(opp.Sharing_Code__c == 'E181' || opp.Sharing_Code__c == 'E131'){

                if(opp.account.Membership_Expiration_date__c == null || opp.account.Membership_Expiration_date__c < opp.closeDate){
                    acc.Membership_Expiration_date__c = addMonths(opp.closeDate, 12);

                }
                else if(opp.account.Membership_Expiration_date__c > opp.closeDate){
                    
                    acc.Membership_Expiration_date__c = addMonths(opp.account.Membership_Expiration_date__c, 12);
                 
                }
                
            }


            // Recapture
            else if(opp.Sharing_Code__c == 'B003'){
                acc.Membership_Expiration_date__c = addMonths(opp.closeDate, 12);
            }

            //Sustainers (Guardian of Liberty) Or Union Gifts
            else if(opp.Sharing_Code__c == 'A003'){
                acc.Membership_Expiration_date__c = addMonths(opp.closeDate, 11);
            }

            else if(opp.Sharing_Code__c == 'P003' || opp.Sharing_Code__c == 'D009' || opp.Sharing_Code__c == 'P002' || opp.Sharing_Code__c == 'D012'){
                if(opp.account.Membership_Expiration_date__c == null){
                    acc.Membership_Expiration_date__c = addMonths(opp.closeDate, 11);
                }
                else if(opp.closeDate < addMonths(opp.account.Membership_Expiration_date__c,3)){
                    acc.Membership_Expiration_date__c = addMonths(opp.account.Membership_Expiration_date__c, 12);
                }
                else if(opp.closeDate > addMonths(opp.account.Membership_Expiration_date__c, 3)){
                    acc.Membership_Expiration_date__c = addMonths(opp.closeDate, 12);
                }
            }
            // Life members
            else if(opp.Sharing_Code__c == 'A001' || opp.Sharing_Code__c == 'P001' || opp.Sharing_Code__c == 'D011'){
                acc.Membership_Expiration_date__c = Date.newInstance(4000,12,31);
                acc.rC_Giving__Lifetime_Is_Sustaining_Giver__c = true;
            }

            // Union Gifts
            else if(opp.Sharing_Code__c == 'A002'){
                acc.Membership_Expiration_date__c = addMonths(opp.closeDate, 11);
            }

            // Original join date
            if((opp.account.Original_Join_Date__c == null) && (opp.Sharing_Code__c  == 'A001' || opp.Sharing_Code__c  == 'A002' ||
               opp.Sharing_Code__c  == 'A003'|| opp.Sharing_Code__c  == 'E181' || opp.Sharing_Code__c  == 'E131')){
                   
                acc.Original_Join_Date__c = opp.closeDate;
            }
            // populates the Expiration date on to the giving record
            opp1.New_Membership_Set_To_Date__c = acc.Membership_Expiration_date__c;
            mapUpdateAccounts.put(acc.Id,acc);
            mapUpdateOpps.put(opp.Id,opp1);
        }
        
        wrapperClass.mapaccounts.putAll(mapUpdateAccounts);
        wrapperClass.mapOpportunities.putAll(mapUpdateOpps);
        return wrapperClass;
    }

    /*
    *
    *Method add12Months
    *adds the noOf months to the date.
    */
    public static date addMonths(date expDate, Integer months){
        Date d = expdate.addMonths(months);
        return Date.newInstance(d.Year(), d.month(), Date.daysInMonth(d.Year(), d.month()));
    }
    
    
    /*
        Additional CampaignTypes
    */
    public static List<Opportunity> additionalGCL(List<Opportunity> oppsListToProcess, Map<Id,Account> mapAccounts, 
                                                       map<String, Share_Source_Revenue_Codes__c> mapShareCodes,
                                                       map<Id,Boolean> mapAccountIdToANBoolean, map<Id,Boolean> mapAccountIdToALBoolean, 
                                                       Map<String,Schema.RecordTypeInfo> opptyRTMap, Map<Id, Campaign> mapCampaigns,
                                                       Map<Id,Opportunity> MapParentOpportunities){
                                                           
         
        List<Opportunity> oppsOfSharingEntityToAccountaffiliate = new List<Opportunity>();
        List<Opportunity> oppsOfSharingEntityToAccountchaper = new List<Opportunity>();
        List<Opportunity> returnOpportunitiesList = new List<Opportunity>();
        
        for(Opportunity opp: oppsListToProcess){
            Date expDate = mapAccounts.get(opp.accountId).Membership_Expiration_date__c ;
        
            if(opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'T'){
                    
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = 'T400';
                  opp.Sharing_Code_Description__c = 'Endowment C3 or C4';
                }
               
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
                
            }
            
            else if(opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == '1'){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = 'H100';
                  opp.Sharing_Code_Description__c = 'To Be Determined';
                }
                
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
                
            }
            
            else if(opp.Campaign_Type__c != NULL && String.valueOf(opp.Campaign_Type__c).substring(0,1) == 'D'){
                if(!opp.Sharing_Code_Override__c && opp.CampaignIdText__c != null && mapCampaigns.get(opp.CampaignIdText__c) != null){
                    
                    opp.Sharing_Code__c = mapCampaigns.get(opp.CampaignIdText__c).Bequest_Sharing_Code__c;
                    
                }
                
                 // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }
            }
            
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || opp.Program_Type__c == '3') 
                    && (MapParentOpportunities.containsKey(opp.rC_Giving__Parent__c) && 
                        MapParentOpportunities.get(opp.rC_Giving__Parent__c).rC_Giving__Is_Sustainer__c == true && 
                        opp.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId())){
                
                
                //Order 9
                if((mapAccounts.get(opp.accountId).Last_Membership_Gift__r.amount >5 )
                            && (mapAccounts.get(opp.accountId).Last_Membership_Gift__r.closeDate.monthsBetween(Date.Today()) >= 24)
                            && opp.Program_Type__c == '3'){
                
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('9').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('9').Share_Code_Description__c;
                    }
                    
                    // Set Sharing Entity field
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                
                else if((mapAccounts.get(opp.accountId).Last_Membership_Gift__r.amount >5 )
                                && (mapAccounts.get(opp.accountId).Last_Membership_Gift__r.closeDate.monthsBetween(Date.Today()) >= 24)
                                && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2')){
                    
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('9').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('9').Share_Code_Description__c;
                    }
                    
                    // Set Sharing Entity field
                    if(!opp.Sharing_Entity_Override__c) {
                      opp.Sharing_Entity__c = 'NAA';
                    }
                    
                    opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
    
                }
                
                //order 10
                /*else if(expDate != null){
                    
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('10').Share_Code__c;
                    }
                    
                    opp.Sharing_Code_Description__c = mapShareCodes.get('10').Share_Code_Description__c;
                    // Set Sharing Entity field
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }*/
                
                // Order 11
                else if(mapAccounts.get(opp.accountId).Last_Membership_Gift__c == null){
                    
                    if(!opp.Sharing_Code_Override__c) {
                        if(mapShareCodes.get('11').Share_Code__c != NULL){ 
                            opp.Sharing_Code__c = mapShareCodes.get('11').Share_Code__c;
                            opp.Sharing_Code_Description__c = mapShareCodes.get('11').Share_Code_Description__c;
                        }    
                    }
                    
                    
                    // Set Sharing Entity field
                    if(!opp.Sharing_Entity_Override__c) {
                      opp.Sharing_Entity__c = 'NAA';
                    }
                    
                    opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
                }
                
                
                // Order 12
                else if(expDate != null  && opp.Program_Type__c == '2'
                        && (opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == false)){
                    
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('12').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('12').Share_Code_Description__c;
                    }
                    
                    // Set Sharing Entity field
                    if(!opp.Sharing_Entity_Override__c) {
                      opp.Sharing_Entity__c = (mapAccounts.get(opp.accountId).Last_Membership_Gift__r != null) ? mapAccounts.get(opp.accountId).Last_Membership_Gift__r.Sharing_Entity__c: '';
                    }
                    
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2): '';
    
                }
                
                // Order 13
                else if(expDate != null && (opp.closeDate > addMonths(expDate, -4) 
                        && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == true)){
                    
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('13').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('13').Share_Code_Description__c;
                    }
                    
                    
                    // Set Sharing Entity field
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                
                // Order 14
                else if(expDate != null && (opp.closeDate <= addMonths(expDate, -4))){
                
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('14').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('14').Share_Code_Description__c;
                    }
                    
                    
                    // Set Sharing Entity field
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                
                // Order 15
                else if((mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && expDate == null)){
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('15').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('15').Share_Code_Description__c;
                    }
                    // Set Sharing Entity field
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else if((mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && expDate == null) ){
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('15').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('15').Share_Code_Description__c;
                    }
                    // Set Sharing Entity field
                    if(!opp.Sharing_Entity_Override__c) {
                      opp.Sharing_Entity__c = 'NAA';
                    }
                    opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
                }
                
                // Order 16
                else if(expDate != null  
                        && (mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == false)){
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('16').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('16').Share_Code_Description__c;
                    }
                    // Set Sharing Entity field
                    if(!opp.Sharing_Entity_Override__c) {
                      opp.Sharing_Entity__c = (mapAccounts.get(opp.accountId).Last_Membership_Gift__r != null) ? mapAccounts.get(opp.accountId).Last_Membership_Gift__r.Sharing_Entity__c: '';
                    }
                    
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2): '';
                }
                
                // Order 17
                else if(expDate != null  
                        && (mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && opp.closeDate > addMonths(expDate, -4) 
                        && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == true)){
                            
                    if(!opp.Sharing_Code_Override__c) {
                       
                      opp.Sharing_Code__c = mapShareCodes.get('17').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('17').Share_Code_Description__c;
                    }
                    // Set Sharing Entity field
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                
                // Order 20
                else if(expDate != null 
                        && ( opp.Program_Type__c == '1' || opp.Program_Type__c == '3')
                        && (opp.closeDate > addMonths(expDate, -4) 
                        && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == false && opp.amount >= 5)){
                            
                    if(!opp.Sharing_Code_Override__c) {
                      opp.Sharing_Code__c = mapShareCodes.get('20').Share_Code__c;
                      opp.Sharing_Code_Description__c = mapShareCodes.get('20').Share_Code_Description__c;
                    }
                    
                    // Set Sharing Entity field
                    if(!opp.Sharing_Entity_Override__c) {
                      opp.Sharing_Entity__c = (mapAccounts.get(opp.accountId).Last_Membership_Gift__r != null) ? mapAccounts.get(opp.accountId).Last_Membership_Gift__r.Sharing_Entity__c: '';
                    }
                    
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2): '';
                }

            }
            returnOpportunitiesList.add(opp);
            
        }
        
        if(!oppsOfSharingEntityToAccountaffiliate.IsEmpty()){
            //oppsToSetGLCodes.addAll(oppsOfSharingEntityToAccountaffiliate);
            setAccountAffiliation(oppsOfSharingEntityToAccountaffiliate);
        }

        if(!oppsOfSharingEntityToAccountchaper.IsEmpty()){
            //oppsToSetGLCodes.addAll(oppsOfSharingEntityToAccountchaper);
            setAccountChapter(oppsOfSharingEntityToAccountchaper);
        }
        
        for (Opportunity theOpp : oppsListToProcess) {
            if ( theOpp.Sharing_Entity_Affiliation__c == theOpp.Account_Affiliation__c || theOpp.Sharing_Entity_Affiliation__c == 'NA'){
                theOpp.Revenue_Affiliation__c = theOpp.Account_Affiliation__c;
            } else if( theOpp.Sharing_Entity_Affiliation__c != theOpp.Account_Affiliation__c || theOpp.Sharing_Entity_Affiliation__c != 'NA'){
                theOpp.Revenue_Affiliation__c = theOpp.Sharing_Entity_Affiliation__c;
            }
        }

        return returnOpportunitiesList;
        
    }
    
    /*
    *
    *Method setShareCode
    *populates the ShareCode,ShareCodeDescription,SharingEntity based on codes.
    */
    public static List<Opportunity> setShareCode(List<Opportunity> opportunities,Set<Id> oppIds){
        //Method Variables
        set<Id> accountIds = new set<Id>();
        List<Opportunity> oppsOfSharingEntityToAccountaffiliate = new List<Opportunity>();
        List<Opportunity> oppsOfSharingEntityToAccountchaper = new List<Opportunity>();
        List<Opportunity> oppsToProcessForAddl_GCLCodes = new List<Opportunity>();
        List<Opportunity> oppsToProcessForExisting = new List<Opportunity>();       
        //List<Opportunity> oppsToSetGLCodes = new List<Opportunity>();
        
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> parentOpps = new Set<Id>();
        Map<Id,Account> mapAccounts = new Map<Id,Account>();
        map<Id,Boolean> mapAccountIdToANBoolean = new map<Id,Boolean>();
        map<Id,Boolean> mapAccountIdToALBoolean = new map<Id,Boolean>();
        Map<String,Schema.RecordTypeInfo> opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        
        List<Opportunity> returnOpportunitiesList = new List<Opportunity>();
        
        for(opportunity opp: opportunities){
            if(opp.rC_Giving__Parent__c != null){
                parentOpps.add(opp.rC_Giving__Parent__c);
            }
            accountIds.add(opp.accountId);
            if(opp.CampaignIdText__c != null){
                campaignIds.add(opp.CampaignIdText__c);
            }
        }
        
        Map<Id,Opportunity> MapParentOpportunities =  new Map<Id,Opportunity>([SELECT Id, rC_Giving__Is_Sustainer__c,Account_Affiliation__c 
                                                                                            FROM Opportunity 
                                                                                            WHERE Id=: parentOpps]);
        
        Map<Id,Campaign> mapCampaigns = new Map<Id, Campaign>([SELECT Id, Bequest_Sharing_Code__c,Override_Sharing_Entity__c FROM Campaign WHERE Id=:campaignIds]);//Added the Override_Sharing_Entity__c field in the query

        for(Account acc: [SELECT Id, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c,
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Active__c = true AND (rC_Bios__Code_Value__c = 'AN' OR rC_Bios__Code_Value__c = 'AL'))
                            FROM Account WHERE Id=:accountIds]){
            mapAccounts.put(acc.Id,acc);
            mapAccountIdToANBoolean.put(acc.Id,false);
            mapAccountIdToALBoolean.put(acc.Id,false);
            for(rC_Bios__Preference__c obj: acc.rC_Bios__Preferences__r){
                if(obj.rC_Bios__Code_Value__c == 'AN')
                    mapAccountIdToANBoolean.put(acc.Id,true);
                if(obj.rC_Bios__Code_Value__c == 'AL')
                    mapAccountIdToALBoolean.put(acc.Id,true);
            }
        }

        
        for(Opportunity opp: opportunities){
            
            // TB added May 20, 2018 for zero or null amount
            if(opp.Amount == null || opp.Amount <= 0) continue;
            
            Date expDate = mapAccounts.get(opp.accountId).Membership_Expiration_date__c ;
            
            //Added by SFDO -#74075 Kirti Rathod 
            if(oppIds != null && oppIds.contains(opp.id)) {
                expDate = null;
            }

            //Additional GCL Codes T,1 etc.
            if(opp.Campaign_Type__c != NULL && (String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'T' ||
               String.ValueOf(opp.Campaign_Type__c).substring(0,1) == '1' || 
               (String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'D' && mapCampaigns.containsKey(opp.CampaignIdText__c) &&
                  mapCampaigns.get(opp.CampaignIdText__c).Bequest_Sharing_Code__c != null) ||
               ((opp.Program_Type__c != NULL && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || opp.Program_Type__c == '3')
               && (MapParentOpportunities.containsKey(opp.rC_Giving__Parent__c) && 
                   MapParentOpportunities.get(opp.rC_Giving__Parent__c).rC_Giving__Is_Sustainer__c == true || 
                   opp.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId()))))){
                   if(!opp.Sharing_Code_Override__c) // BGE-71     
                   opp.Sharing_Code__c = NULL;
                //Opportunity does match with GCL Intial Criteria
                oppsToProcessForAddl_GCLCodes.add(opp);
            }
            else{
                //Opportunity doesn't match with GCL Intial Criteria
                oppsToProcessForExisting.add(opp);
            }
        }
        
                
        
        if(!oppsToProcessForAddl_GCLCodes.isEmpty()){
            List<Opportunity> additionalCodeMatchedOpps = additionalGCL(oppsToProcessForAddl_GCLCodes, mapAccounts, mapShareCodes, mapAccountIdToANBoolean, 
                        mapAccountIdToALBoolean, opptyRTMap, mapCampaigns, MapParentOpportunities);
                        
            for(Opportunity opp: additionalCodeMatchedOpps){
                
                if(String.IsBlank(opp.Sharing_Code__c)){
                    // Opportunity Doesnot match with GCL Codes
                    oppsToProcessForExisting.add(opp);
                }
                else{
                    //add to the final List to return.
                    returnOpportunitiesList.add(opp);
                }
            }
                        
        }
        
        for(Opportunity opp: oppsToProcessForExisting){
        
            Date expDate = mapAccounts.get(opp.accountId).Membership_Expiration_date__c ;
            
            //Added by SFDO -#74075 Kirti Rathod 
            if(oppIds != null && oppIds.contains(opp.id)) {
                expDate = null;
            }
            
            // Order 1
            if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'B' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' )){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('1').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('1').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);

            }

            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'B' && (opp.Program_Type__c == '3')){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('1').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('1').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);

            }
            // Order 2
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'E' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2')){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('2').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('2').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'E' && (opp.Program_Type__c == '3')){
                
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('2').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('2').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);
            }

            // Order 3
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'K' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' )){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('3').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('3').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'K' && (opp.Program_Type__c == '3' )){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('3').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('3').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);
            }

            // Order 4
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'G' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' )){
                
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('4').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('4').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'G' && (opp.Program_Type__c == '3' )){
                
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('4').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('4').Share_Code_Description__c;
                }
               
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);
            }

            // Order 5
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'I' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2')){
                
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('5').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('5').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'I' && (opp.Program_Type__c == '3' )){
               
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('5').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('5').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);
            }

            // Order 6
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'C' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' )){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('6').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('6').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'C' && (opp.Program_Type__c == '3')){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('6').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('6').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);
            }

            // Order 7
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'Q' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' )){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('7').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('7').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'Q' && (opp.Program_Type__c == '3')){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('7').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('7').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountchaper.add(opp);
            }

            // Order 8
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'H' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2'|| opp.Program_Type__c == '3')){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('8').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('8').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 9
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '3' ) && (mapAccounts.get(opp.accountId).Last_Membership_Gift__r.amount >5 )
                            && (mapAccounts.get(opp.accountId).Last_Membership_Gift__r.closeDate.monthsBetween(Date.Today()) >= 24)){
                //
                 if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('9').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('9').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else  if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2') && (mapAccounts.get(opp.accountId).Last_Membership_Gift__r.amount >5 )
                            && (mapAccounts.get(opp.accountId).Last_Membership_Gift__r.closeDate.monthsBetween(Date.Today()) >= 24)){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('9').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('9').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = 'NAA';
                }
                opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);

            }
            // Order 10
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'S' && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || opp.Program_Type__c == '3') && (expDate != null)){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('10').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('10').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 11
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && (String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'V' || String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'U') && (opp.Program_Type__c == '2' ) && (mapAccounts.get(opp.accountId).Last_Membership_Gift__c == null)){
                //
                if(!opp.Sharing_Code_Override__c) {
                    if(mapShareCodes.get('11').Share_Code__c != NULL){ 
                        opp.Sharing_Code__c = mapShareCodes.get('11').Share_Code__c;
                        opp.Sharing_Code_Description__c = mapShareCodes.get('11').Share_Code_Description__c;
                    }    
                }
                
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = 'NAA';
                }
                opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
            }

            // Order 12
            
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && expDate != null && (String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'V' || String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'U') && (opp.Program_Type__c == '2' ) && (opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == false)){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('12').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('12').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = (mapAccounts.get(opp.accountId).Last_Membership_Gift__r != null) ? mapAccounts.get(opp.accountId).Last_Membership_Gift__r.Sharing_Entity__c: '';
                }
                opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2): '';

            }

            // Order 13
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && expDate != null && (String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'V' || String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'U') && (opp.Program_Type__c == '2') && (opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == true)){
                //
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('13').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('13').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 14
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && expDate != null 
                    && (String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'V' || String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'U') 
                    && (opp.Program_Type__c == '2') && (opp.closeDate <= addMonths(expDate, -4))){
                
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('14').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('14').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 15
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '3' ) && (mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && expDate == null)){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('15').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('15').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' ) && (mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && expDate == null) ){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('15').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('15').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = 'NAA';
                }
                opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
            }

            // Order 16
            else if(opp.Program_Type__c != NULL && expDate != null && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || opp.Program_Type__c == '3') && (mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 && opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == false)){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('16').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('16').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = (mapAccounts.get(opp.accountId).Last_Membership_Gift__r != null) ? mapAccounts.get(opp.accountId).Last_Membership_Gift__r.Sharing_Entity__c: '';
                }
                opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2): '';
            }
            // Order 17
            else if(opp.Program_Type__c != NULL && expDate != null && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || 
            opp.Program_Type__c == '3') && (mapAccountIdToALBoolean.get(opp.accountId) && opp.amount >= 1000 
            && opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == true)){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('17').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('17').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 18
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '3' ) && (expDate == null) && (mapAccountIdToANBoolean.get(opp.accountId) || opp.amount < 5)){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('18').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('18').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && (expDate == null) && (opp.Program_Type__c == '1' ) && (mapAccountIdToANBoolean.get(opp.accountId) || opp.amount < 5)){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('18').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('18').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = 'NAA';
                }
                opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
            }

            // Order 19
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '3' ) && (expDate == null)){
              if(!opp.Sharing_Code_Override__c) {
                opp.Sharing_Code__c = mapShareCodes.get('19').Share_Code__c;
                opp.Sharing_Code_Description__c = mapShareCodes.get('19').Share_Code_Description__c;
              }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            else if(opp.Program_Type__c != NULL && (opp.Program_Type__c == '1' ) && (expDate == null) && (opp!=null)){
              if(!opp.Sharing_Code_Override__c && mapShareCodes!=null && mapShareCodes.get('19')!=null) {
                opp.Sharing_Code__c = mapShareCodes.get('19').Share_Code__c;
                if(mapShareCodes!=null && mapShareCodes.get('19')!=null)
                opp.Sharing_Code_Description__c = mapShareCodes.get('19').Share_Code_Description__c;
              }
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = 'NAA';
                }
                opp.Sharing_Entity_Affiliation__c = String.ValueOf(opp.Sharing_Entity__c).substring(0,2);
            }

            // Order 20
            else if(opp.Program_Type__c != NULL && expDate != null && (opp.Program_Type__c == '1' || opp.Program_Type__c == '3') && (opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == false && opp.amount >= 5)){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('20').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('20').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!opp.Sharing_Entity_Override__c) {
                  opp.Sharing_Entity__c = (mapAccounts.get(opp.accountId).Last_Membership_Gift__r != null) ? mapAccounts.get(opp.accountId).Last_Membership_Gift__r.Sharing_Entity__c: '';
                }
                opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2): '';
            }

            // Order 21
            else if(opp.Program_Type__c != NULL && expDate != null && (opp.Program_Type__c == '1' || opp.Program_Type__c == '3') && (opp.closeDate > addMonths(expDate, -4) && (mapAccounts.get(opp.accountId).Has_Renewed_Before__c == true || opp.amount < 5) && (opp.amount < 5 || mapAccountIdToANBoolean.get(opp.accountId))) ){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('21').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('21').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 22
            else if(opp.Program_Type__c != NULL && expDate != null && (opp.Program_Type__c == '1' || opp.Program_Type__c == '3') && ((opp.closeDate > addMonths(expDate, -4) && mapAccounts.get(opp.accountId).Has_Renewed_Before__c == true) || opp.amount < 5 )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('22').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('22').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }

            // Order 23
            else if(opp.Program_Type__c != NULL && expDate != null && (opp.Program_Type__c == '1' || opp.Program_Type__c == '3') && (opp.closeDate <= addMonths(expDate, -4)) ){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('23').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('23').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                oppsOfSharingEntityToAccountaffiliate.add(opp);
            }
            
                
            // Order 24
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'E' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('24').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('24').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 25
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'K' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('25').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('25').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 26
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'F' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('26').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('26').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 27
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'G' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('27').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('27').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 28
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'C' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('28').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('28').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 29
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'S' && (opp.Program_Type__c == '4' ) && opp.amount < 2500){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('29').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('29').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }


            // Order 30
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'S' && (opp.Program_Type__c == '5' ) && opp.amount < 2500){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('30').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('30').Share_Code_Description__c;
                }
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 31
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'S' && opp.amount >= 2500 && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('31').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('31').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 32
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'H' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('32').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('32').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 33
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'I' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('33').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('33').Share_Code_Description__c;
                }
                
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 34
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'Q' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('34').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('34').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 35
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'B' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('35').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('35').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 36
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'M' && (opp.Program_Type__c == '4' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('36').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('36').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 37 * Mounica V Changed the code from 37 to 28 to keep the description consistent for R131
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'M' && (opp.Program_Type__c == '5' )){
                if(!opp.Sharing_Code_Override__c) {
                  opp.Sharing_Code__c = mapShareCodes.get('28').Share_Code__c;
                  opp.Sharing_Code_Description__c = mapShareCodes.get('28').Share_Code_Description__c;
                }
                
                // Set Sharing Entity field
                 if(!String.isBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
                    if(!opp.Sharing_Entity_Override__c) { 
                        opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                        opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
                    }
                    opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
                }
                else if(opp.Deposit_Site__c != NULL && (String.ValueOf(opp.Deposit_Site__c).startsWith('NA') || String.ValueOf(opp.Deposit_Site__c).startsWith('NN') || 
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('UN') || String.ValueOf(opp.Deposit_Site__c).startsWith('FN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PF') || String.ValueOf(opp.Deposit_Site__c).startsWith('EN')||
                                                    String.ValueOf(opp.Deposit_Site__c).startsWith('PU') || String.ValueOf(opp.Deposit_Site__c).startsWith('UA'))){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }
            
            returnOpportunitiesList.add(opp);
            // Commented below Orders as these rows sharing code will be manually Entered by the users.
            /*  
            
            // Order 38
            else if(opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'T' ){
                opp.Sharing_Code__c = mapShareCodes.get('38').Share_Code__c;
                opp.Sharing_Code_Description__c = mapShareCodes.get('38').Share_Code_Description__c;
                // Set Sharing Entity field
                if(opp.Deposit_Site__c != NULL && String.ValueOf(opp.Deposit_Site__c).startsWith('NA')){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 39
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'D' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' ) &&
                    (String.ValueOf(code).substring(code.length()-4,code.length()) == 'Q001' ||
                     String.ValueOf(code).substring(code.length()-4,code.length()) == 'Q002' ||
                     String.ValueOf(code).substring(code.length()-4,code.length()) == 'Q003' ||
                     String.ValueOf(code).substring(code.length()-4,code.length()) == 'Q004' )){
                // adding the 40 share code as 39,40 values are same
                opp.Sharing_Code__c = mapShareCodes.get('40').Share_Code__c;
                opp.Sharing_Code_Description__c = mapShareCodes.get('40').Share_Code_Description__c;
                // Set Sharing Entity field
                if(opp.Deposit_Site__c != NULL && String.ValueOf(opp.Deposit_Site__c).startsWith('NA')){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 40
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'D' && ( opp.Program_Type__c == '4'|| opp.Program_Type__c == '5') &&
                    (String.ValueOf(code).substring(code.length()-1,code.length()) == '1' ||
                     String.ValueOf(code).substring(code.length()-1,code.length()) == '2' ||
                     String.ValueOf(code).substring(code.length()-1,code.length()) == '3' ||
                     String.ValueOf(code).substring(code.length()-1,code.length()) == '4' )){
                opp.Sharing_Code__c = mapShareCodes.get('40').Share_Code__c;
                opp.Sharing_Code_Description__c = mapShareCodes.get('40').Share_Code_Description__c;
                // Set Sharing Entity field
                if(opp.Deposit_Site__c != NULL && String.ValueOf(opp.Deposit_Site__c).startsWith('NA')){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 41
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'D' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' ) &&
                    (String.ValueOf(code).substring(code.length()-4,code.length()) == 'U001' ||
                     String.ValueOf(code).substring(code.length()-4,code.length()) == 'U002' ||
                     String.ValueOf(code).substring(code.length()-4,code.length()) == 'U003' ||
                     String.ValueOf(code).substring(code.length()-4,code.length()) == 'U004' )){
                // adding the 42 share code as 41,42 values are same
                opp.Sharing_Code__c = mapShareCodes.get('42').Share_Code__c;
                opp.Sharing_Code_Description__c = mapShareCodes.get('42').Share_Code_Description__c;
                // Set Sharing Entity field
                if(opp.Deposit_Site__c != NULL && String.ValueOf(opp.Deposit_Site__c).startsWith('NA')){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }

            // Order 42
            else if(opp.Program_Type__c != NULL && opp.Campaign_Type__c != NULL && String.ValueOf(opp.Campaign_Type__c).substring(0,1) == 'D' && (opp.Program_Type__c == '4' || opp.Program_Type__c == '5' ) &&
                    (String.ValueOf(code).substring(code.length()-1,code.length()) == '1' ||
                     String.ValueOf(code).substring(code.length()-1,code.length()) == '2' ||
                     String.ValueOf(code).substring(code.length()-1,code.length()) == '3' ||
                     String.ValueOf(code).substring(code.length()-1,code.length()) == '4' )){
                opp.Sharing_Code__c = mapShareCodes.get('42').Share_Code__c;
                opp.Sharing_Code_Description__c = mapShareCodes.get('42').Share_Code_Description__c;
                // Set Sharing Entity field
                if(opp.Deposit_Site__c != NULL && String.ValueOf(opp.Deposit_Site__c).startsWith('NA')){
                    oppsOfSharingEntityToAccountaffiliate.add(opp);
                }
                else{
                    oppsOfSharingEntityToAccountchaper.add(opp);
                }

            }
            */
            
        }

        
        
       

        if(!oppsOfSharingEntityToAccountaffiliate.IsEmpty()){
            //oppsToSetGLCodes.addAll(oppsOfSharingEntityToAccountaffiliate);
            setAccountAffiliation(oppsOfSharingEntityToAccountaffiliate);
        }

        if(!oppsOfSharingEntityToAccountchaper.IsEmpty()){
            //oppsToSetGLCodes.addAll(oppsOfSharingEntityToAccountchaper);
            setAccountChapter(oppsOfSharingEntityToAccountchaper);
        }
        
        //If the SharingCode/SharingEntity is Blank then populates Error as value.
        for(Opportunity opp: opportunities){
            
            // TB added May 20, 2018 for zero or null amount
            if(opp.Amount == null || opp.Amount <= 0) continue;
            
            if(String.IsBlank(opp.Sharing_Code__c)){
                opp.Sharing_Code__c = 'ERROR';
               // opp.Sharing_Entity__c = ''; // BGE-71 
              //opp.Sharing_Entity_Affiliation__c = ''; // BGE-71 
            }
            if(String.IsBlank(opp.Sharing_Entity__c)){
                opp.Sharing_Entity__c = 'ERROR';
            }
            if(String.IsBlank(opp.Sharing_Entity_Affiliation__c)){
                opp.Sharing_Entity_Affiliation__c = 'ER';
            }
            
            if( opp.Sharing_Entity_Affiliation__c == opp.Account_Affiliation__c || opp.Sharing_Entity_Affiliation__c == 'NA') {
                opp.Revenue_Affiliation__c = opp.Account_Affiliation__c;
            } else if( opp.Sharing_Entity_Affiliation__c != opp.Account_Affiliation__c || opp.Sharing_Entity_Affiliation__c != 'NA') {
                opp.Revenue_Affiliation__c = opp.Sharing_Entity_Affiliation__c;
            }
            
            //ACLU #75631: Added by - Kirti Rathod(SFDO) - Sharing Code Entity Override on campaign
            if(mapCampaigns.get(opp.CampaignIdText__c) != null) {	
                String campOverrideSharingEntity = mapCampaigns.get(opp.CampaignIdText__c).Override_Sharing_Entity__c;	
                if(String.isNotBlank(campOverrideSharingEntity)) {	
                    opp.Sharing_Entity__c = campOverrideSharingEntity.contains('-')?campOverrideSharingEntity.split('-')[0]:campOverrideSharingEntity;	
                    opp.Sharing_Entity_Affiliation__c = campOverrideSharingEntity.substring(0,2);
                    opp.Revenue_Affiliation__c = campOverrideSharingEntity.substring(0,2);
                }
            }	
        
        /*if(!oppsToSetGLCodes.isEmpty()) {
            GLGivingHelper.nationalGLCodeAssigner(oppsToSetGLCodes);
        }*/
        
       
    	}
	return returnOpportunitiesList;
    }
    /*
    * Created By - SFDO - #74075 -Kirti Rathod
    *Method setShareCode
    *populates the ShareCode,ShareCodeDescription,SharingEntity based on codes.
    */
    public static List<Opportunity> setShareCode(List<Opportunity> opportunities){
       return setShareCode(opportunities,null);
    }
    /*
    *
    *Method giftAfterBeginningOfRenewal
    *True if giftDate after the beginning Of RenewalDate.
    */
    public static Boolean giftAfterBeginningOfRenewal(date giftDate, Date expDate){
        return giftDate > addmonths(expDate, -4);
    }

    /*
    *
    *Method setAccountAffiliation
    *populates the SharingEntity to Opportunity Accounts affiliation.
    */
    public static void setAccountAffiliation(List<opportunity> opportunities){
        // Method Variables
        Set<Id> accountIds = new Set<Id>();
        //map<String,Id> accBillingPostal = new map<String,Id>();
        map<Id,String> accIdToBillingPostal = new map<Id,String>();
        Map<Id,Account> mapAccount = new Map<Id,Account>();
        map<String, String> mapAccountIdToZipAffiliateChapter = new map<String, String>();
        map<Id, String> mapAccIDToChapterNoZipOrLocked = new map<Id, String>();
        map<Id, String> mapAccIDToChapterNoZipAffiliate = new map<Id, String>();
        set<ID> setAccIdWithoutChapterAndAffiliation = new set<id>();
        set<Id> setAccIdWithUSPostalCode = new set<Id>();
        set<Id> setAccIdWithNonUSPostalCode = new set<Id>();

        for(Opportunity opp: opportunities){
            if(opp.AccountId != null)
                accountIds.add(opp.accountId);
        }

        for(Account acc: [SELECT Id, BillingPostalCode, Affiliation__c,Chapter__c, Lock_Affiliation__c FROM Account where Id =: accountIds]){
            mapAccount.put(acc.Id,acc);
            if(acc.Lock_Affiliation__c == true) {
                if(acc.Chapter__c != null && acc.Affiliation__c != null) {
                    mapAccIDToChapterNoZipAffiliate.put(acc.Id, acc.Chapter__c);
                } else if(acc.Chapter__c == null && acc.Affiliation__c == null) {
                    setAccIdWithoutChapterAndAffiliation.add(acc.Id);
                }
                
            } 
            else if(acc.Lock_Affiliation__c == false) {
                if(acc.Affiliation__c == null && acc.Chapter__c == null && String.isBlank(acc.BillingPostalCode)) {
                    accIdToBillingPostal.put(acc.Id, '00000');
                }
                else if (acc.Affiliation__c != null && acc.Chapter__c != null && String.isBlank(acc.BillingPostalCode)) {
                    mapAccIDToChapterNoZipOrLocked.put(acc.Id, acc.Chapter__c);
                }
                else if(String.isNotBlank(acc.BillingPostalCode) && acc.Affiliation__c == null && acc.Chapter__c == null) {
                    accIdToBillingPostal.put(acc.Id, acc.BillingPostalCode);
                    if(checkValidUS_PostalCode(acc.BillingPostalCode)) {
                        setAccIdWithUSPostalCode.add(acc.Id);
                    }
                    else{
                        setAccIdWithNonUSPostalCode.add(acc.Id);
                    }
                }
                else if(String.isNotBlank(acc.BillingPostalCode) && acc.Affiliation__c != null && acc.Chapter__c != null) {
                    accIdToBillingPostal.put(acc.Id, acc.BillingPostalCode);
                    mapAccIDToChapterNoZipOrLocked.put(acc.Id, acc.Chapter__c);
                }
            }
        }

        for(Zip_Affiliate__c obj: [SELECT Id, Chapter__c, Name FROM Zip_Affiliate__c WHERE name =: accIdToBillingPostal.Values()]){
            mapAccountIdToZipAffiliateChapter.put(obj.Name, obj.Chapter__c);
        }

        for(opportunity opp: opportunities){
            String postalCode = accIdToBillingPostal.get(opp.accountId);
            /* Mounica V : BGE-71, Adding sharing entity override check */
            if(!opp.Sharing_Entity_Override__c){
            if(mapAccIDToChapterNoZipAffiliate.containsKey(opp.AccountId)){
                opp.Sharing_Entity__c = mapAccIDToChapterNoZipAffiliate.get(opp.AccountId).length() >= 3 ? mapAccIDToChapterNoZipAffiliate.get(opp.AccountId).substring(0,3) : mapAccIDToChapterNoZipAffiliate.get(opp.AccountId);
            }
            else if(setAccIdWithoutChapterAndAffiliation.contains(opp.AccountId) || (!mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && setAccIdWithUSPostalCode.contains(opp.AccountId))) {
                opp.Sharing_Entity__c = '';
            }
            else if(mapAccountIdToZipAffiliateChapter.containsKey(postalCode)) {
                opp.Sharing_Entity__c = String.ValueOf(mapAccountIdToZipAffiliateChapter.get(postalCode)).length() >= 3 ? String.ValueOf(mapAccountIdToZipAffiliateChapter.get(postalCode)).substring(0,3) : String.ValueOf(mapAccountIdToZipAffiliateChapter.get(postalCode));
            }
            /*else if(!mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && setAccIdWithUSPostalCode.contains(opp.AccountId)) {
                 opp.Sharing_Entity__c = '';
            }*/
            else if(!mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && setAccIdWithNonUSPostalCode.contains(opp.AccountId)) {
                 opp.Sharing_Entity__c = 'ZFA';
            }
            else if(mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && mapAccIDToChapterNoZipOrLocked.containsKey(opp.AccountId)) {
                 opp.Sharing_Entity__c = mapAccountIdToZipAffiliateChapter.get(postalCode).length() >=3 ? mapAccountIdToZipAffiliateChapter.get(postalCode).substring(0,3) : mapAccountIdToZipAffiliateChapter.get(postalCode);
            }
            else if(mapAccIDToChapterNoZipOrLocked.containsKey(opp.AccountId)) {
                opp.Sharing_Entity__c = mapAccIDToChapterNoZipOrLocked.get(opp.AccountId).length() >= 3 ? mapAccIDToChapterNoZipOrLocked.get(opp.AccountId).substring(0,3) : mapAccIDToChapterNoZipOrLocked.get(opp.AccountId);
            }
            }// BGE -71 END
            
            opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
        }
    }


    /*
    *
    *Method setAccountChapter
    *populates the SharingEntity to Opportunity Accounts Chapter/Affiliation with concatinate with'99'.
    */

    public static void setAccountChapter(List<opportunity> opportunities){
      // Method Variables
      Set<Id> accountIds = new Set<Id>();
      //map<String,Id> accBillingPostal = new map<String,Id>();
      map<Id,String> accIdToBillingPostal = new map<Id,String>();
      Map<Id,Account> mapAccount = new Map<Id,Account>();
      map<String, String> mapAccountIdToZipAffiliateChapter = new map<String, String>();
      
      map<Id, String> mapAccIDToChapterNoZipOrLocked = new map<Id, String>();
      map<Id, String> mapAccIDToChapterNoZipAffiliate = new map<Id, String>();
      set<ID> setAccIdWithoutChapterAndAffiliation = new set<id>();
      set<Id> setAccIdWithUSPostalCode = new set<Id>();
      set<Id> setAccIdWithNonUSPostalCode = new set<Id>();

      for(Opportunity opp: opportunities){
      accountIds.add(opp.accountId);
      }
      
      for(Account acc: [SELECT Id, BillingPostalCode, Affiliation__c,Chapter__c, Lock_Affiliation__c FROM Account where Id =: accountIds]){
        mapAccount.put(acc.Id,acc);
        if(acc.Lock_Affiliation__c == true) {
                if(acc.Chapter__c != null && acc.Affiliation__c != null) {
                    mapAccIDToChapterNoZipAffiliate.put(acc.Id, acc.Chapter__c);
                } else if(acc.Chapter__c == null && acc.Affiliation__c == null) {
                    setAccIdWithoutChapterAndAffiliation.add(acc.Id);
                }
                
            } 
            else if(acc.Lock_Affiliation__c == false) {
                if(acc.Affiliation__c == null && acc.Chapter__c == null && String.isBlank(acc.BillingPostalCode)) {
                    accIdToBillingPostal.put(acc.Id, '00000');
                }
                else if (acc.Affiliation__c != null && acc.Chapter__c != null && String.isBlank(acc.BillingPostalCode)) {
                    mapAccIDToChapterNoZipOrLocked.put(acc.Id, acc.Chapter__c);
                }
                else if(String.isNotBlank(acc.BillingPostalCode) && acc.Affiliation__c == null && acc.Chapter__c == null) {
                    accIdToBillingPostal.put(acc.Id, acc.BillingPostalCode);
                    if(checkValidUS_PostalCode(acc.BillingPostalCode)) {
                        setAccIdWithUSPostalCode.add(acc.Id);
                    }
                    else{
                        setAccIdWithNonUSPostalCode.add(acc.Id);
                    }
                }
                else if(String.isNotBlank(acc.BillingPostalCode) && acc.Affiliation__c != null && acc.Chapter__c != null) {
                    accIdToBillingPostal.put(acc.Id, acc.BillingPostalCode);
                    mapAccIDToChapterNoZipOrLocked.put(acc.Id, acc.Chapter__c);
                }
            }
      } 
      
      if(accIdToBillingPostal != null && accIdToBillingPostal.keyset() != null) {
        for(Zip_Affiliate__c obj: [SELECT Id, Chapter__c, Name FROM Zip_Affiliate__c WHERE name =: accIdToBillingPostal.Values()]){
          mapAccountIdToZipAffiliateChapter.put(obj.Name, obj.Chapter__c);
        }
      }
      
      for(Opportunity opp: opportunities){
        String affiliation = (String.ValueOf(mapAccount.get(opp.accountId).Affiliation__c) != null && String.ValueOf(mapAccount.get(opp.accountId).Affiliation__c) != '') ? String.valueOf(mapAccount.get(opp.accountId).Affiliation__c) : 'NN';
        if(String.isNotBlank(opp.Deposit_Site__c) && (opp.Deposit_Site__c).startsWith('NA_')){
            if(!opp.Sharing_Entity_Override__c) {
                opp.Sharing_Entity__c = (opp.Deposit_Site__c).substring(3, 5);
                opp.Sharing_Entity_Affiliation__c = (opp.Deposit_Site__c).substring(3, 5);
            }
            opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
        }
        else if(opp.Deposit_Site__c != null && String.ValueOf(opp.Deposit_Site__c).substring(0,2) == affiliation){
            String postalCode = accIdToBillingPostal.get(opp.accountId);
          if(!opp.Sharing_Entity_Override__c) {
            if(mapAccIDToChapterNoZipAffiliate.containsKey(opp.AccountId)){
                opp.Sharing_Entity__c = mapAccIDToChapterNoZipAffiliate.get(opp.AccountId).length() >= 3 ? mapAccIDToChapterNoZipAffiliate.get(opp.AccountId).substring(0,3) : mapAccIDToChapterNoZipAffiliate.get(opp.AccountId);
            }
            else if(setAccIdWithoutChapterAndAffiliation.contains(opp.AccountId) || (!mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && setAccIdWithUSPostalCode.contains(opp.AccountId))) {
                opp.Sharing_Entity__c = '';
            }
            else if(mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && !opp.Sharing_Entity_Override__c) {
                opp.Sharing_Entity__c = String.ValueOf(mapAccountIdToZipAffiliateChapter.get(postalCode)).length() >= 3 ? String.ValueOf(mapAccountIdToZipAffiliateChapter.get(postalCode)).substring(0,3) : String.ValueOf(mapAccountIdToZipAffiliateChapter.get(postalCode));
            }
            /*else if(!mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && setAccIdWithUSPostalCode.contains(opp.AccountId)) {
                 opp.Sharing_Entity__c = '';
            }*/
            else if(!mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && setAccIdWithNonUSPostalCode.contains(opp.AccountId)) {
                 opp.Sharing_Entity__c = 'ZFA';
            }
            else if(mapAccountIdToZipAffiliateChapter.containsKey(postalCode) && mapAccIDToChapterNoZipOrLocked.containsKey(opp.AccountId)) {
                 opp.Sharing_Entity__c = mapAccountIdToZipAffiliateChapter.get(postalCode).length() >= 3 ? mapAccountIdToZipAffiliateChapter.get(postalCode).substring(0,3) : mapAccountIdToZipAffiliateChapter.get(postalCode);
            }
            else if(mapAccIDToChapterNoZipOrLocked.containsKey(opp.AccountId)) {
                opp.Sharing_Entity__c = mapAccIDToChapterNoZipOrLocked.get(opp.AccountId).length() >= 3 ? mapAccIDToChapterNoZipOrLocked.get(opp.AccountId).substring(0,3) : mapAccIDToChapterNoZipOrLocked.get(opp.AccountId);
            }
          }
          opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null)  ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
        }
        else{
          if(!opp.Sharing_Entity_Override__c) {
            opp.Sharing_Entity__c = opp.Deposit_Site__c != null ? String.ValueOf(opp.Deposit_Site__c).substring(0,2) + '99': null;
          }
          opp.Sharing_Entity_Affiliation__c = (opp.Sharing_Entity__c!= '' && opp.Sharing_Entity__c != null) ? String.ValueOf(opp.Sharing_Entity__c).substring(0,2) : '';
        }
      }
    }

    
    public class OpportunitiesAndAccountWrapper {
        public map<Id, Account> mapaccounts = new map<Id, Account>();
        public map<Id, Opportunity> mapOpportunities = new map<Id, Opportunity>();
    }
    
    
    public static Boolean checkValidUS_PostalCode( String postalCode ){
        Boolean isValidUSPostalCode = false;
        if( postalCode.length() == 5 && postalCode.isNumeric() ){
            isValidUSPostalCode = true;
        } else if( postalCode.length() == 10 ){
            if( postalCode.substring(0,5).isNumeric() && postalCode.substring(5,6).equals('-') && postalCode.substring(6,10).isNumeric() ){
                isValidUSPostalCode = true;
            }
        }
        return isValidUSPostalCode;
    }
    
    public static List<Opportunity>  flagMembershipShareCodeReset ( List <Opportunity> oppList, Map<Id,Opportunity> oldMap) {
         List<Opportunity> oppListToExecuteSharingMethods = new List<Opportunity>();
         Set<String> sharingCodeSet = new Set<String>{'A001', 'A002', 'A003', 'B003', 'D009', 'D010', 'D011', 'D012', 
                                                        'P001', 'P002', 'P003', 'E131', 'E181'};
         String flaggedMembershipReset = 'Flagged for MembershipShareCode Reset';
         Set<String> batchLogIdsSet = new Set<String>();
         for( Opportunity opp : oppList ){
             if(opp.rC_Giving__External_ID__c != flaggedMembershipReset) {
                 if( !String.isBlank(oldMap.get(opp.Id).Sharing_Code__c) && sharingCodeSet.contains(opp.Sharing_Code__c)
                    && ( opp.Isclosed != oldMap.get(opp.Id).Isclosed || (opp.stageName != oldMap.get(opp.Id).stageName && opp.stageName == 'Completed')
                    || opp.accountId != oldMap.get(opp.Id).accountId || opp.Related_Transaction__c != oldMap.get(opp.Id).Related_Transaction__c
                    || opp.Deposit_Site__c != oldMap.get(opp.Id).Deposit_Site__c || opp.Amount != oldMap.get(opp.Id).Amount
                    || opp.Program_Type__c != oldMap.get(opp.Id).Program_Type__c || opp.Campaign_Type__c != oldMap.get(opp.Id).Campaign_Type__c
                    /*( opp.Deposit_Site__c != oldMap.get(opp.Id).Deposit_Site__c 
                            && ( opp.Sharing_Code__c == 'P001' || opp.Sharing_Code__c == 'P002' || opp.Sharing_Code__c == 'P003' )) 
                        || (
                            (opp.stageName != oldMap.get(opp.Id).stageName && opp.stageName == 'Completed' )
                            || opp.Isclosed != oldMap.get(opp.Id).Isclosed
                            || (opp.Amount != oldMap.get(opp.Id).Amount && opp.Amount < 1000 
                                && ( opp.Sharing_Code__c == 'D011' || opp.Sharing_Code__c == 'A001' || opp.Sharing_Code__c == 'P001' ) )
                            || (opp.Amount != oldMap.get(opp.Id).Amount && opp.Amount < 5 
                                && ( opp.Sharing_Code__c == 'B003' || opp.Sharing_Code__c == 'P002' ) )
                            || (opp.Amount != oldMap.get(opp.Id).Amount && opp.Amount > 5 && opp.Sharing_Code__c == 'D012' )
                            || (opp.Program_Type__c != oldMap.get(opp.Id).Program_Type__c 
                                && ( opp.Program_Type__c != '1' || opp.Program_Type__c != '3') && opp.Sharing_Code__c == 'P002' )
                            || (opp.Program_Type__c != oldMap.get(opp.Id).Program_Type__c && opp.Program_Type__c != '2' 
                                && ( opp.Sharing_Code__c == 'A003' || opp.Sharing_Code__c == 'P003' || opp.Sharing_Code__c == 'D009') )
                            || (opp.Campaign_Type__c != oldMap.get(opp.Id).Campaign_Type__c 
                                && (opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E181' ))
                            || (opp.accountId != oldMap.get(opp.Id).accountId)
                            || (opp.Related_Transaction__c != oldMap.get(opp.Id).Related_Transaction__c))*/
                        )
                ){
                     opp.rC_Giving__External_ID__c = flaggedMembershipReset;
                     flaggedOpptySet.add(opp.Id);
                     if(opp.Batch_Log__c != NULL )
                        batchLogIdsSet.add( opp.Batch_Log__c );
                 } else {
                     oppListToExecuteSharingMethods.add( opp );
                 }
             }
         }
         if( !batchLogIdsSet.isEmpty() ){
             Insert new AsyncRequest__c(AsyncType__c ='updateBatchLog_Status', Object_API_Name__c = 'Batch_Log__c',
                                        Params__c = String.join(new List<String>(batchLogIdsSet),','));
         }
         
         return oppListToExecuteSharingMethods;
         
     }
}