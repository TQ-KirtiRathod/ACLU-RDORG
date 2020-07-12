/*
*
*Name  :  CampaignRollUpBatch
*Author:  Appirio India (Shikha Gupta)
*Date  :  April 27, 2017
*Purpose :  Centennial Report batch create summary records.  
            Called from CampaignRollUpDeleteBatch
            Logic includes the creation of custom summary records based on opportunities over a multi year span.
*
*/

global class CampaignRollUpBatch implements Database.Batchable<sObject>, Database.stateful {
  private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
  private static Map<String,Schema.RecordTypeInfo> campaignRollUpRTMap;
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
  private static final String OPPORTUNITY_RT_TRANSACTION_Id;
  private static final String OPPORTUNITY_RT_PLEDGE_Id;
  private static final Id CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP;
  private static final Id CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP;
  private static Set<String> setOfShareCodes = new Set<String>{'A001','A002','A003','B003','C005','C006','C008','C009',
                                                               'C161','C165','K161','K165','P001','P002','P003','U004',
                                                               'Q004'};
  private static Set<String> setOfRevenueType = new Set<String>{'TRANSFORMATIONAL','ANNUAL FUND','MEMBERSHIP',
                                                                'PLANNED GIVING CASH'};
  private static String currentFiscalYear;
  private static Organization orgInfo;
  private Map<String, Campaign_Roll_Up__c> revenueRollUp;
  private String currentAccountId;
  private Map<String, Campaign_Roll_Up__c> currentAccountsMap;

  static {
    opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
    campaignRollUpRTMap = Schema.SObjectType.Campaign_Roll_Up__c.getRecordTypeInfosByName();
    OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
    OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
    OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
    CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP = campaignRollUpRTMap.get('Revenue Type Yearly Roll Up').getRecordTypeId();
    CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP =  campaignRollUpRTMap.get('Account Detail Yearly Roll Up').getRecordTypeId();

    //Determine current fiscal year
    orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
               FROM Organization
               WHERE id=:Userinfo.getOrganizationId()];
    Date todayDate = system.today();
    if (todayDate.month() >= orgInfo.FiscalYearStartMonth) {
        currentFiscalYear = String.valueOf(todayDate.year() + 1);
    } else currentFiscalYear = String.valueOf(todayDate.year());
  }
     
  global CampaignRollUpBatch() { 
  }
   
  global Database.QueryLocator start(Database.BatchableContext Bc ){
    currentAccountsMap = new map<String, Campaign_Roll_Up__c>();
    revenueRollUp = new Map<String, Campaign_Roll_Up__c>();
    
    //closeDateStartDate based on custom setting fy or custom setting fy -1 on saturdays
    Date closeDateStartDate = CampaignRollUpDeleteBatch.getStartDate();
    Date closeDateEndDate = Opportunity_Start_End_Date_To_Process__c.getValues('Run Range').End_Date__c;

    //system.debug('closeDateStartDate:: '+closeDateStartDate+'  closeDateEndDate::'+closeDateEndDate );
    //unused variables
    //Opportunity_Start_End_Date_To_Process__c objGame = Opportunity_Start_End_Date_To_Process__c.getValues('CloseDate');
    //Opportunity_Start_End_Date_To_Process__c objGame1 = Opportunity_Start_End_Date_To_Process__c.getValues('Tax_Date__c');
    //Date taxDateStartDate = objGame1.Start_Date__c;
    //Date taxDateEndDate = objGame1.End_Date__c;

    return Database.getQueryLocator([
        Select Id, rC_Giving__Account_Name__c, Adjustment_Code__c, CloseDate, Tax_Date__c, rC_Giving__Is_Bookable__c, 
               RPT_Revenue_Type__c, rC_Giving__Pipeline_Amount__c,  Amount, Account_Affiliation__c, Fiscal_Year__c,
               Deposit_Site__c, Sharing_Code__c, rC_Giving__Source_Code__c, Program_Type__c, Sharing_Entity__c,AccountId,
               RecordTypeId
               //remvoed Account.Name, rC_Giving__Closed_Amount__c,RecordType.Name
        FROM Opportunity
        WHERE RPT_Revenue_Type__c IN :setOfRevenueType
        AND ( (RecordTypeId IN (:OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, :OPPORTUNITY_RT_TRANSACTION_Id) 
                //AND Adjustment_Code__c IN ('D','N') 
                AND StageName='Completed')
            OR (RecordTypeId =: OPPORTUNITY_RT_PLEDGE_Id)
            )
        AND ((CloseDate >=: closeDateStartDate AND CloseDate <=: closeDateEndDate)
              //OR (Tax_Date__c >=: taxDateStartDate AND Tax_Date__c <=: taxDateEndDate)
            )
        //AND Account.ID = '001W000000Odkoc'  //isolated to one account for testing purposes
        ORDER BY  AccountId //CloseDate,
        ]);
    }

    global void execute(Database.BatchableContext Bc, List<Opportunity> scope){

     Map<String,Id> mapOfAccountNameVsAccountId = new Map<String,Id>();
     Map<String,Double> mapOfRevenueTypeKeyVsOutstandingPledge = new Map<String,Double>();
     Map<String,Double> mapOfRevenueTypeKeyVsCashToDate = new Map<String,Double>();
     Map<String,Double> mapOfAccountYearlyKeyVsOutstandingPledge = new Map<String,Double>();
     Map<String,Double> mapOfAccountYearlyKeyVsCashToDate = new Map<String,Double>();
     Set<String> setOfRevenueTypeYearlyKeys = new Set<String>();
     Set<String> setOfAccountYearlyTypeKeys = new Set<String>();
     Set<String> setOfCampaignRollUpNameKeys = new Set<string>();
     Map<String,List<Double>> mapOfKeyVsCYFCashToDateAndOutstandingPledge = new map<String,List<Double>>();
     List<Campaign_Roll_Up__c> listOfRecords = new List<Campaign_Roll_Up__c>();
     
     String fiscalYear;
     String affiliation;
     Double value;
     Double outstandingPledgeTotal;
     Double cashToDateValue;
     String key1;
     
     /* This For loop processes the opps in scope and populate the key and value in maps,
        where the key is the unique combination of fields (like Account, Revnue Type, Fiscal Year)
        and the Amount is the sum of all oppties corrosponing to that combination
     */
     for(Opportunity theOpp : scope) {
       String key = '';
       key1 = '';
       outstandingPledgeTotal = 0.0;
       value = 0.0;
       cashToDateValue = 0.0;
       affiliation = '';
       fiscalYear = '';
       
       // logic to populate map which will be use to popualte  Account on  Campaign Roll Up reocrds (Account Yearly Roll Up type ).
       if(theOpp.AccountId != null && theOpp.rC_Giving__Account_Name__c != null) 
       mapOfAccountNameVsAccountId.put(theOpp.rC_Giving__Account_Name__c, theOpp.AccountId);
       
       //logic to populate affilaition on Campaign Roll Up reocrds,
       //if sharing entity is NA use Affiliation otheriwse use sharing entity
       affiliation = ((theOpp.Sharing_Entity__c != null) && ((theopp.Sharing_Entity__c).length() >=2) 
                      && (theOpp.Sharing_Entity__c.subString(0,2) == 'NA')
                      && (theOpp.Account_Affiliation__c != null) && (theOpp.Account_Affiliation__c.length() >=2)
                     )
                     ? theOpp.Account_Affiliation__c.subString(0,2) :
                     (theOpp.Sharing_Entity__c != null && theOpp.Sharing_Entity__c.length() >= 2 
                        ? theOpp.Sharing_Entity__c.subString(0,2) : '');
       //System.debug('theOpp.Account_Affiliation__c'+theOpp.Account_Affiliation__c);
       //System.debug('affiliation'+affiliation);
       //System.debug('oppsharingEntity:'+theOpp.Sharing_Entity__c);

       // logic to populate fiscal year on Campaign Roll Up reocrds
       // if bookable use tax date otherise use close date
       //NOTE: if no tax date then use close date, record will allways have close date, a blank value would have dollars 
       // uncalculated
       fiscalYear = theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id 
                                        ? (theOpp.rC_Giving__Is_Bookable__c 
                                          ? (theOpp.Tax_Date__c != null ? getFiscalYear(theOpp.Tax_Date__c) : '') 
                                          : (theOpp.CloseDate != null ? getFiscalYear(theOpp.CloseDate) : '')) 
                                        : (theOpp.CloseDate != null ? getFiscalYear(theOpp.CloseDate) : '');
       //system.debug(fiscalYear);


       ///- Calcualtion For Revenue Type Yearly Roll Up Records Begins-///
       
       /*Oppty records will be summarized on Camapign Yearly Roll Up reocrds based on unique combination of 
        (Revenue Type and Fiscal Year) Each Combination will have two different records one for National one for 
        Affiliate, i.e. each opp will be manipulated twice
        For Revneue Type Yearly Roll Up, Pledges and Transaction/PP will be manipulated differently
       */

       // staring calculation for Pledges,
       //if oppty is a Pledge we will take the Pipeline Amount field and add the value in 
       //Outstanding Pledge field of Campaign Roll Up Record
       //system.debug('opps'+theOpp);
       if(theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id && fiscalYear!= '') {
        //system.debug('pledge');
        if(theOpp.RPT_Revenue_Type__c == 'TRANSFORMATIONAL' || theOpp.RPT_Revenue_Type__c == 'ANNUAL FUND') {
          // For National
          key = theOpp.RPT_Revenue_Type__c + '=>' +  fiscalYear;
          setOfRevenueTypeYearlyKeys.add(key);
          theOpp.rC_Giving__Pipeline_Amount__c = theOpp.rC_Giving__Pipeline_Amount__c != null 
                                               ? theOpp.rC_Giving__Pipeline_Amount__c 
                                               : 0.0;
          
          value = mapOfRevenueTypeKeyVsOutstandingPledge!= null && mapOfRevenueTypeKeyVsOutstandingPledge.containsKey(key)
                       ? (mapOfRevenueTypeKeyVsOutstandingPledge.get(key) + theOpp.rC_Giving__Pipeline_Amount__c)
                       : theOpp.rC_Giving__Pipeline_Amount__c;
          if(!mapOfRevenueTypeKeyVsOutstandingPledge.containsKey(key)) {
            mapOfRevenueTypeKeyVsOutstandingPledge.put(key,0);
          }
          mapOfRevenueTypeKeyVsOutstandingPledge.put(key,value);
            
          // For all the oppties where Fiscal Year = currentFiscalYear
          if(fiscalYear == currentFiscalYear) {
            Double CFYOutstandingPledge = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) != null
                                        ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) + theOpp.rC_Giving__Pipeline_Amount__c
                                        : theOpp.rC_Giving__Pipeline_Amount__c;
           //system.debug('Pledge RY'+CFYOutstandingPledge);
           if(!mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)) {
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.put(key,new List<Double>());
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(0.0);
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYOutstandingPledge);
           }else {
             Double tempValue =  mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).size() >= 1 
                              ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(0) 
                              : 0.0; 
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).clear();  
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(tempValue);
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYOutstandingPledge);
           }
           //system.debug('Pledge RY'+mapOfKeyVsCYFCashToDateAndOutstandingPledge);
         }
          
          // For Affiliate
          if(theOpp.Sharing_Code__c != null && (!setOfShareCodes.contains(theOpp.Sharing_Code__c)) && affiliation != '') {
            key = theOpp.RPT_Revenue_Type__c + '=>' + affiliation + '=>' + fiscalYear;
            setOfRevenueTypeYearlyKeys.add(key);
            value = mapOfRevenueTypeKeyVsOutstandingPledge != null && mapOfRevenueTypeKeyVsOutstandingPledge.containsKey(key) 
                  ? mapOfRevenueTypeKeyVsOutstandingPledge.get(key) + theOpp.rC_Giving__Pipeline_Amount__c 
                  : theOpp.rC_Giving__Pipeline_Amount__c;
            if(!mapOfRevenueTypeKeyVsOutstandingPledge.containsKey(key)) {
              mapOfRevenueTypeKeyVsOutstandingPledge.put(key,0);
            }
            mapOfRevenueTypeKeyVsOutstandingPledge.put(key,value);
            
          // For all the oppties where Fiscal Year = currentFiscalYear
          if(fiscalYear == currentFiscalYear) {
            Double CFYOutstandingPledge = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) != null
                                        ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) 
                                            + theOpp.rC_Giving__Pipeline_Amount__c
                                        : theOpp.rC_Giving__Pipeline_Amount__c;
           if(!mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)) {
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.put(key,new List<Double>());
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(0.0);
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYOutstandingPledge);
           }else {
             Double tempValue =  mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).size() >= 1 
                              ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(0) 
                              : 0.0; 
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).clear();
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(tempValue);
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYOutstandingPledge);
           }
         }
       }

          
        }
       } 
       //end calculation for pledge and starting for Pledge Payments/Transactions,
       // if oppty is a Pledge-Payment/Transaction we will take the Amount field and add the value 
       // in Cash to Date field of Campaign Roll Up Record
       else if((theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id 
                || theOpp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) && fiscalYear!= ''
               && (theOpp.Adjustment_Code__c == 'D' || theOpp.Adjustment_Code__c =='N')) {
         if(theOpp.RPT_Revenue_Type__c == 'TRANSFORMATIONAL' || theOpp.RPT_Revenue_Type__c == 'ANNUAL FUND' || 
            theOpp.RPT_Revenue_Type__c == 'PLANNED GIVING CASH' || theOpp.RPT_Revenue_Type__c == 'MEMBERSHIP') {
             //system.debug('pledge pay tran');
           // For National
           key = theOpp.RPT_Revenue_Type__c + '=>' + fiscalYear;
           setOfRevenueTypeYearlyKeys.add(key);
           theOpp.Amount = theOpp.Amount!= null ? theOpp.Amount : 0.0;
           value = mapOfRevenueTypeKeyVsCashToDate!= null && mapOfRevenueTypeKeyVsCashToDate.containsKey(key)
                 ? mapOfRevenueTypeKeyVsCashToDate.get(key) + theOpp.Amount
                 : theOpp.Amount;
           if(!mapOfRevenueTypeKeyVsCashToDate.containsKey(key)) {
             mapOfRevenueTypeKeyVsCashToDate.put(key,0);
           }
           mapOfRevenueTypeKeyVsCashToDate.put(key,value);
           
          // For all the oppties where Fiscal Year = currentFiscalYear
          if(fiscalYear == currentFiscalYear) {
            Double CFYCashToDate = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                    && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(0) + theOpp.Amount
                                : theOpp.Amount;
                        //system.debug('Other RY'+CFYCashToDate);
            if(!mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)) {
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.put(key,new List<Double>());
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYCashToDate);
              Double tempValue =  mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).size() >= 2 
                               ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) 
                               : 0.0;
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(tempValue);
             }else {
               Double tempValue =  mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).size() >= 2 
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) 
                                : 0.0;
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).clear();
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYCashToDate);
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(tempValue);
             }
             //system.debug('other RY'+mapOfKeyVsCYFCashToDateAndOutstandingPledge);
           }
           //System.debug(theOpp.Sharing_Code__c+':setOfShareCodes::'+setOfShareCodes);
           //System.debug('affiliation::'+affiliation);
           // For Affiliate
           if(theOpp.Sharing_Code__c != null && (!setOfShareCodes.contains(theOpp.Sharing_Code__c)) && affiliation != '') {
             key = theOpp.RPT_Revenue_Type__c + '=>' + affiliation + '=>' + fiscalYear;
             setOfRevenueTypeYearlyKeys.add(key);
             value = mapOfRevenueTypeKeyVsCashToDate!= null && mapOfRevenueTypeKeyVsCashToDate.containsKey(key)
                   ? mapOfRevenueTypeKeyVsCashToDate.get(key) + theOpp.Amount
                   : theOpp.Amount;
             if(!mapOfRevenueTypeKeyVsCashToDate.containsKey(key)) {
               mapOfRevenueTypeKeyVsCashToDate.put(key,0);
             }
             mapOfRevenueTypeKeyVsCashToDate.put(key,value);
          // For all the oppties where Fiscal Year = currentFiscalYear
          if(fiscalYear == currentFiscalYear) {
            Double CFYCashToDate = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                  && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(0) + theOpp.Amount
                                : theOpp.Amount;
            if(!mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key)) {
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.put(key,new List<Double>());
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYCashToDate);
              Double tempValue =  mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).size() >= 2  
                               ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) 
                               : 0.0;
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(tempValue);
             }else {
               Double tempValue =  mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).size() >= 2 
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) 
                                : 0.0;
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).clear();
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(CFYCashToDate);
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).add(tempValue);
             }
           }
           }
         }      
       }

        ///- Calcualtion For Revenue Type Yearly Roll Up Records Ends-///
        /// - Calculation For Account Yearly Roll Up Record Begins - ///
       
       /*Oppty records will be summarized on Camapign Yearly Roll Up reocrds based on unique combination 
          of (Account Name, Revenue Type and Fiscal Year)
        Each Combination will have two different records one for National one for Affiliate, i.e. each opp will be 
          manipulated twice
        All of the Pledges and Transaction & Pledge Payments will be manipulated in the same way
         and each opp will correspond to Outsanding Pledge as well as Cash To Date field irresepcetive of Record type.
       */
       if(( ((theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id 
              || theOpp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) 
            && (theOpp.Adjustment_Code__c == 'D' || theOpp.Adjustment_Code__c =='N') 
            )
          || theOpp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_Id) &&
            (theOpp.RPT_Revenue_Type__c == 'TRANSFORMATIONAL' || theOpp.RPT_Revenue_Type__c == 'ANNUAL FUND')
            && theOpp.AccountId != null && fiscalYear != '') 
       {
         //system.debug('account pl, pp, tr');
         key1 = theOpp.rC_Giving__Account_Name__c + '=>' + theOpp.RPT_Revenue_Type__c + '=>' + fiscalYear;
         setOfAccountYearlyTypeKeys.add(key1);
         // -- For National Begins --
         theOpp.rC_Giving__Pipeline_Amount__c = theOpp.rC_Giving__Pipeline_Amount__c != null 
                                              ? theOpp.rC_Giving__Pipeline_Amount__c 
                                              : 0.0;
         outstandingPledgeTotal = mapOfAccountYearlyKeyVsOutstandingPledge != null && mapOfAccountYearlyKeyVsOutstandingPledge.containsKey(key1)
                                ? mapOfAccountYearlyKeyVsOutstandingPledge.get(key1) + theOpp.rC_Giving__Pipeline_Amount__c
                                : theOpp.rC_Giving__Pipeline_Amount__c;
         if(!mapOfAccountYearlyKeyVsOutstandingPledge.containsKey(key1)) {
           mapOfAccountYearlyKeyVsOutstandingPledge.put(key1,0.0);   
         }
         mapOfAccountYearlyKeyVsOutstandingPledge.put(key1,outstandingPledgeTotal);
         
         theOpp.Amount = theOpp.Amount != null ? theOpp.Amount : 0.0;
         cashToDateValue = mapOfAccountYearlyKeyVsCashToDate != null && mapOfAccountYearlyKeyVsCashToDate.containsKey(key1) 
                         ? mapOfAccountYearlyKeyVsCashToDate.get(key1) + theOpp.Amount
                         : theOpp.Amount;
         if(!mapOfAccountYearlyKeyVsCashToDate.containsKey(key1)) {
           mapOfAccountYearlyKeyVsCashToDate.put(key1,0.0);
         }
         mapOfAccountYearlyKeyVsCashToDate.put(key1,cashToDateValue);
         
         // For all the oppties where Fiscal Year = currentFiscalYear
         if(fiscalYear == currentFiscalYear) {
           Double CFYCashToDate = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                    && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key1)
                                    && mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).get(0) != null
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).get(0) + theOpp.Amount
                                : theOpp.Amount;
            Double CFYOutstandingPledge = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key1)
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).get(1) != null
                                        ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).get(1) + theOpp.rC_Giving__Pipeline_Amount__c
                                        : theOpp.rC_Giving__Pipeline_Amount__c;
           //system.debug('AY '+CFYCashToDate);
           //system.debug('AY '+CFYOutstandingPledge);
           if(!mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key1)) {
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.put(key1,new List<Double>());
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYCashToDate);
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYOutstandingPledge);
           }else {
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).clear();
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYCashToDate);
             mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYOutstandingPledge);
           }
            //system.debug(' AY'+mapOfKeyVsCYFCashToDateAndOutstandingPledge);
         }
         // -- For National Ends -- 
         
         // -- For Affiliate Begins --
         if(affiliation != '' && theOpp.Sharing_Code__c != null && (!setOfShareCodes.contains(theOpp.Sharing_Code__c))) {
           key1 = theOpp.rC_Giving__Account_Name__c + '=>' + affiliation + '=>' + theOpp.RPT_Revenue_Type__c + '=>' + fiscalYear;
           setOfAccountYearlyTypeKeys.add(key1);
           outstandingPledgeTotal = mapOfAccountYearlyKeyVsOutstandingPledge!= null 
                                    && mapOfAccountYearlyKeyVsOutstandingPledge.containsKey(key1) 
                                  ? mapOfAccountYearlyKeyVsOutstandingPledge.get(key1) + theOpp.rC_Giving__Pipeline_Amount__c
                                  : theOpp.rC_Giving__Pipeline_Amount__c;
         if(!mapOfAccountYearlyKeyVsOutstandingPledge.containsKey(key1)) {
           mapOfAccountYearlyKeyVsOutstandingPledge.put(key1,0.0);   
         }
         mapOfAccountYearlyKeyVsOutstandingPledge.put(key1,outstandingPledgeTotal);
         
         cashToDateValue = mapOfAccountYearlyKeyVsCashToDate != null && mapOfAccountYearlyKeyVsCashToDate.containsKey(key1)
                         ? mapOfAccountYearlyKeyVsCashToDate.get(key1) + theOpp.Amount
                         : theOpp.Amount;
         if(!mapOfAccountYearlyKeyVsCashToDate.containsKey(key1)) {
           mapOfAccountYearlyKeyVsCashToDate.put(key1,0.0);
         }
         mapOfAccountYearlyKeyVsCashToDate.put(key1,cashToDateValue);
          
          // For all the oppties where Fiscal Year = currentFiscalYear
          if(fiscalYear == currentFiscalYear) {
            Double CFYCashToDate = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                    && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key1)
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).get(0) + theOpp.Amount
                                : theOpp.Amount;
            Double CFYOutstandingPledge = mapOfKeyVsCYFCashToDateAndOutstandingPledge!= null 
                                          && mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key1)
                                        ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).get(1) + theOpp.rC_Giving__Pipeline_Amount__c
                                        : theOpp.rC_Giving__Pipeline_Amount__c;
            if(!mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key1)) {
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.put(key1,new List<Double>());
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYCashToDate);
              mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYOutstandingPledge);
             }else {
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).clear();
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYCashToDate);
               mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key1).add(CFYOutstandingPledge);
             }
           }
         }
         // -- For Affiliate Ends --
       }
       // - Calculation For Account Yearly Roll Up Record Ends - //
     }
     
     setOfCampaignRollUpNameKeys.addAll(setOfRevenueTypeYearlyKeys);
     setOfCampaignRollUpNameKeys.addAll(setOfAccountYearlyTypeKeys);
     // Returning Map Of Campaign Yearly Roll Up Reocrds
     listOfRecords = processMapToSummarizeRecordsBasedOnGrouping(mapOfAccountNameVsAccountId,
                                                                 mapOfRevenueTypeKeyVsOutstandingPledge,
                                                                 mapOfRevenueTypeKeyVsCashToDate,
                                                                 mapOfAccountYearlyKeyVsOutstandingPledge,
                                                                 mapOfAccountYearlyKeyVsCashToDate,
                                                                 mapOfKeyVsCYFCashToDateAndOutstandingPledge,
                                                                 setOfCampaignRollUpNameKeys,
                                                                 setOfRevenueTypeYearlyKeys,
                                                                 setOfAccountYearlyTypeKeys);
     // Inserting Campaign Yearly Roll Up Records in Database
     insertRecordsInDatabase(listOfRecords);
   } // end execute



   
  /*This Method processes the maps based on keys and returns the list of Campaign Yearly Roll Up Reocrds
       If the key is present in setOfRevenueTypeYearlyKeys set, it means it is Revenue Type Yearly type of record.
        For National key = Revenue_Type=>Fiscal_Year
        For Affiliate key = Revenue_Type=>Affiliation=>Fiscal_Year
       If the key is present in setOfAccountYearlyTypeKeys set, it means it is Account Yearly Type type of records.
        For National key = Account_Name=>Revenue_Type=>Fiscal_Year
        For Affiliate key = Account_Name=>Affiliation=>Revenue_Type=>Fiscal_Year
  */
  private List<Campaign_Roll_Up__c> processMapToSummarizeRecordsBasedOnGrouping(   
        Map<String,Id> mapOfAccountNameVsAccountId,
        Map<String,Double> mapOfRevenueTypeKeyVsOutstandingPledge,
        Map<String,Double> mapOfRevenueTypeKeyVsCashToDate,
        Map<String,Double> mapOfAccountYearlyKeyVsOutstandingPledge,
        Map<String,Double> mapOfAccountYearlyKeyVsCashToDate,
        Map<String,List<Double>> mapOfKeyVsCYFCashToDateAndOutstandingPledge,
        Set<String> setOfCampaignRollUpNameKeys,
        Set<String> setOfRevenueTypeYearlyKeys,
        Set<String> setOfAccountYearlyTypeKeys) 
  {
    Campaign_Roll_Up__c newRecord = new Campaign_Roll_Up__c();
    List<Campaign_Roll_Up__c> listOfRecords = new List<Campaign_Roll_Up__c>();
    for(String key : setOfCampaignRollUpNameKeys) {
      String name = '';
      for(String subName : key.split('=>')) {
        name += subName + ' - ';    
      }
         
      name = name.subString(0,name.Length()-3);
      Integer size = key.split('=>').size();
      String recordTypeId = setOfRevenueTypeYearlyKeys.contains(key) 
                          ? CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP 
                          : CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP;
      Double outstandingPledge = setOfRevenueTypeYearlyKeys.contains(key) 
                               ? mapOfRevenueTypeKeyVsOutstandingPledge.get(key) 
                               : mapOfAccountYearlyKeyVsOutstandingPledge.get(key);
      Double cashToDate = setOfRevenueTypeYearlyKeys.contains(key) 
                        ? mapOfRevenueTypeKeyVsCashToDate.get(key) 
                        : mapOfAccountYearlyKeyVsCashToDate.get(key);
      String aff = setOfRevenueTypeYearlyKeys.contains(key) ? (size == 2 ? 'NA' : key.split('=>')[1]) : (size == 3 ? 'NA' : key.split('=>')[1]);
      String revnueType = setOfRevenueTypeYearlyKeys.contains(key) ? key.split('=>')[0] : (size == 3 ? key.split('=>')[1] : key.split('=>')[2]);
      Id accountId = mapOfAccountNameVsAccountId.containsKey( key.split('=>')[0] ) ? mapOfAccountNameVsAccountId.get( key.split('=>')[0] ) : null;

      newRecord = new Campaign_Roll_Up__c(
            Name = name,
            RecordTypeId = recordTypeId,
            Account_ID__c = accountId,
            Outstanding_Pledges__c = outstandingPledge,
            Cash_To_Date__c = cashToDate,
            Fiscal_Year__c = key.right(4),
            Affiliation__c = aff,
            Revenue_Type__c = revnueType,
            CFY_Outstanding_Pledges__c = mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key) 
                                         && mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1) != null
                                       ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(1)
                                       : 0.0, 
            CFY_Cash_To_Date__c = mapOfKeyVsCYFCashToDateAndOutstandingPledge.containsKey(key) 
                                    && mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(0) != null
                                ? mapOfKeyVsCYFCashToDateAndOutstandingPledge.get(key).get(0)
                                : 0.0
            );
      if (newRecord.Outstanding_Pledges__c < 0 || newRecord.Outstanding_Pledges__c == null ) {
        newRecord.Outstanding_Pledges__c = 0;
      }
      if (newRecord.Cash_To_Date__c < 0 || newRecord.Cash_To_Date__c == null ) {
        newRecord.Cash_To_Date__c = 0;
      }
      if (newRecord.CFY_Outstanding_Pledges__c < 0 || newRecord.CFY_Outstanding_Pledges__c == null ) {
        newRecord.CFY_Outstanding_Pledges__c = 0;
      }
      if (newRecord.CFY_Cash_To_Date__c < 0 || newRecord.CFY_Cash_To_Date__c == null ) {
        newRecord.CFY_Cash_To_Date__c = 0;
      }
   
      //section determines what records will actually be created
      if(newRecord.RecordTypeId == CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP){
        if(!revenueRollUp.isEmpty() && revenueRollUp.containsKey(newRecord.name) ){
          revenueRollUp.get(newRecord.name).Outstanding_Pledges__c  += newRecord.Outstanding_Pledges__c;
          revenueRollUp.get(newRecord.name).Cash_To_Date__c  += newRecord.Cash_To_Date__c;
          revenueRollUp.get(newRecord.name).CFY_Outstanding_Pledges__c  += newRecord.CFY_Outstanding_Pledges__c;
          revenueRollUp.get(newRecord.name).CFY_Cash_To_Date__c  += newRecord.CFY_Cash_To_Date__c;
        } else {
          revenueRollUp.put(newRecord.name, newRecord);
        }
      } else if (newRecord.Revenue_Type__c == 'Annual Fund') {
        if(String.isBlank(currentAccountId))  currentAccountId =  newRecord.Account_ID__c; //sets id first time
          
          String namekey = newRecord.Account_ID__c+' - '+newRecord.Affiliation__c 
                           +' - '+newRecord.Revenue_Type__c +' - '+ newRecord.Fiscal_Year__c;

          if(currentAccountId == newRecord.Account_ID__c && currentAccountsMap != null ){ //building account list  
            if(currentAccountsMap.containsKey(namekey)){ //summing exising record
              currentAccountsMap.get(namekey).Outstanding_Pledges__c += newRecord.Outstanding_Pledges__c;
              currentAccountsMap.get(namekey).Cash_To_Date__c += newRecord.Cash_To_Date__c;
              currentAccountsMap.get(namekey).CFY_Outstanding_Pledges__c += newRecord.CFY_Outstanding_Pledges__c;
              currentAccountsMap.get(namekey).CFY_Cash_To_Date__c += newRecord.CFY_Cash_To_Date__c;
            } else{ //adding new to list
              currentAccountsMap.put(namekey,newRecord);
            }
          } else { //processing map once account id has changed
            if(currentAccountsMap != null){
              for(Campaign_Roll_Up__c ru : currentAccountsMap.values() ){
                if(ru.Outstanding_Pledges__c + ru.Cash_To_Date__c >= integer.valueof(Label.Campaign_Roll_Up_Annual_Fund_Include_Value)){
                  listOfRecords.add(ru);
                }
              }
            }
            //reset values for next iteration
            currentAccountsMap = new Map<String, Campaign_Roll_Up__c>();
            currentAccountsMap.put(namekey,newRecord);
            currentAccountId =  newRecord.Account_ID__c;
          }
        } else{
          listOfRecords.add(newrecord);
        }
      }
      return listOfRecords;
    } 
   
   
  /* This method will check if the values are null in any of the Campaign Roll Up reocrds and  will put 0.0 if found
     And based on the criteria the records will be inserted into the system.
  */
  private static void insertRecordsInDatabase(List<Campaign_Roll_Up__c> listOfRecords) {
    List<Campaign_Roll_Up__c> listOfCampaignRollUps = new List<Campaign_Roll_Up__c>();
    if(listOfRecords != null){
      for(Campaign_Roll_Up__c rollUp : listOfRecords) {
        if(rollUp.RecordTypeId == CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP 
          && (rollUp.Cash_To_Date__c + rollUp.Outstanding_Pledges__c 
              >= integer.valueof(Label.Campaign_Roll_Up_Annual_Fund_Include_Value))) {

          rollUp.Outstanding_Pledges__c =  rollUp.Outstanding_Pledges__c == null ? 0.0 : rollUp.Outstanding_Pledges__c;
          rollUp.Cash_To_Date__c =  rollUp.Cash_To_Date__c == null ? 0.0 : rollUp.Cash_To_Date__c;
          rollUp.CFY_Outstanding_Pledges__c = rollUp.CFY_Outstanding_Pledges__c == null ? 0.0 : rollUp.CFY_Outstanding_Pledges__c;
          rollUp.CFY_Cash_To_Date__c = rollUp.CFY_Cash_To_Date__c == null ? 0.0 : rollUp.CFY_Cash_To_Date__c;
          listOfCampaignRollUps.add(rollUp);    
        }
      }
      try{
        if(!listOfCampaignRollUps.isEmpty()) {
          insert listOfCampaignRollUps;
        }
      }
      catch(Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignRollUpBatch','execute',e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }      
  }


  global void finish(Database.BatchableContext Bc){
    if(revenueRollUp.size() > 0){
      insert(revenueRollUp.values() );
    }
    //processes last account detail records
    List<Campaign_Roll_Up__c> finalAnnualFundAccountDetailRollUps = new List<Campaign_Roll_Up__c>();
    if(currentAccountsMap != null){
      for(Campaign_Roll_Up__c ru : currentAccountsMap.values() ){
        if(ru.Outstanding_Pledges__c + ru.Cash_To_Date__c >= integer.valueof(Label.Campaign_Roll_Up_Annual_Fund_Include_Value)){
          finalAnnualFundAccountDetailRollUps.add(ru);
        }
      }
    }
    if(finalAnnualFundAccountDetailRollUps.size() != null){
      insert(finalAnnualFundAccountDetailRollUps );
    }

    Id batchInstanceId = Database.executeBatch(new PlannedGivingIntentionBatch(), 200);
    apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignRollUpBatch FINISHED');
    log.saveLogs();
  }
  
  @TestVisible
  private static Double setCFYdollars(String fy, Double dollars){
    Double currentFYDollars = 0;
    if(fy == currentFiscalYear){
      currentFYDollars = dollars;
    } else{
      currentFYDollars = 0;
    }
    return currentFYDollars;
  }

  @TestVisible
  private String getFiscalYear(Date d){
    if (d.month() >= orgInfo.FiscalYearStartMonth) {
      return String.valueOf(d.year() + 1);
    } else 
      return String.valueOf(d.year());
  }

}