/*
*
*Name  :  PlannedGivingIntentionBatch
*Author:  Appirio India (James Wasilewski)
*Date  :  August 27, 2017
*Purpose :  Batch class for the Centential Report based on Planned Giving Records
            Creates Campaign_Roll_Up__c summary records summarized from Planned Giving
            Batch chained from CampaignRollUpBatch
*
*/

global class PlannedGivingIntentionBatch implements Database.Batchable<sObject> {
   private static Map<String, Schema.RecordTypeInfo> campaignRollUpRTMap;
   private static final Id CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP;
   private static final Id CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP;
   private static final Set<String> setOfrecordtypeNames;
   private static Opportunity_Start_End_Date_To_Process__c objGame;
   private static final Date contractDateStartDate;
   private static String currentFiscalYear;
   private static Organization orgInfo;

   static {
      campaignRollUpRTMap = Schema.SObjectType.Campaign_Roll_Up__c.getRecordTypeInfosByName();
      CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP = campaignRollUpRTMap.get('Revenue Type Yearly Roll Up').getRecordTypeId();
      CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP =  campaignRollUpRTMap.get('Account Detail Yearly Roll Up').getRecordTypeId();
      setOfrecordtypeNames = new Set<String> {'Charitable Gift Annuity', 'Charitable Gift Annuity - Southern Calif', 
                                              'Deferred Gift Annuity', 'Pooled Income Fund', 
                                              'Pooled Income Fund - Southern California'};
      currentFiscalYear = [SELECT FiscalYearSettings.Name 
                           FROM Period WHERE Type = 'Year' 
                           AND StartDate <= TODAY 
                           AND EndDate >= TODAY].FiscalYearSettings.Name;

      //objGame = Opportunity_Start_End_Date_To_Process__c.getValues('Gift_Date__c');
      //Date contractDateStartDate = getPGDate(objGame.Start_Date__c);
      //contractDateStartDate based on custom setting date or custom setting date-1Year on saturdays
      Datetime dt = CampaignRollUpDeleteBatch.getStartDate(); 
      contractDateStartDate = date.newinstance(dT.year(), dT.month(), dT.day());
      orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                 FROM Organization
                 WHERE id = :Userinfo.getOrganizationId()];
   }

   global PlannedGivingIntentionBatch() {

   }

   global Database.QueryLocator start(Database.BatchableContext Bc ) {

      return Database.getQueryLocator([
           Select Id, rC_Giving__Stage__c, Gift_Date__c, rC_Giving__Account__c, rC_Giving__Account__r.Name,
                  rC_Giving__Giving_Amount__c, Proposal__r.CloseDate, Account_Affiliation__c, rC_Giving__Bequest_Type__c,
                  RecordType.Name
           FROM rC_Giving__Planned_Giving__c
           WHERE rC_Giving__Stage__c = 'Active'
                 AND Gift_Date__c >= : contractDateStartDate
                 ORDER BY rC_Giving__Account__c]);
   }

   global void execute(Database.BatchableContext Bc, List<rC_Giving__Planned_Giving__c> scope) {
      Map<String, Double> mapOfKeyVsSumOfOutstandingPledge = new Map<String, Double>();
      Map<String, Double> mapOfKeyVsCFYSumOfOutstandingPledge = new Map<String, Double>();
      List<Campaign_Roll_Up__c> listOfCampaignRollUps = new List<Campaign_Roll_Up__c>();
      Map<String, Id> mapOfAccountNameVsId = new Map<String, Id>();
      String fiscalYear = '';
      String affiliation = '';
      String revenueType = 'Planned Giving Intentions';
      Double value = 0.0;

      Integer orgFiscalMonth = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth;
      Date orgFiscalYear = Date.newinstance(system.today().year(), orgFiscalMonth, 1);
      String currentFiscalYear = String.valueOf(orgFiscalYear.year());

      for (rC_Giving__Planned_Giving__c plannedGiving : scope) {
         if (plannedGiving.rC_Giving__Account__c != null && plannedGiving.rC_Giving__Account__r.Name != null)
            mapOfAccountNameVsId.put(plannedGiving.rC_Giving__Account__r.Name, plannedGiving.rC_Giving__Account__c);
         String key = '';

         fiscalYear = plannedGiving.Gift_Date__c != null
                      ? getFiscalYear(plannedGiving.Gift_Date__c)
                      : '';
         affiliation = ((plannedGiving.Account_Affiliation__c != null ) && (plannedGiving.Account_Affiliation__c.length() >= 2))
                       ? plannedGiving.Account_Affiliation__c : '';

         key = revenueType + '=>' +  fiscalYear + '=>PN';//This '-PN' means it is for National
         Double estimate = 0.0;
         if (plannedGiving.rC_Giving__Stage__c != null && plannedGiving.rC_Giving__Stage__c == 'Active' &&
               plannedGiving.Gift_Date__c != null && plannedGiving.Gift_Date__c >= contractDateStartDate &&
               (plannedGiving.rC_Giving__Bequest_Type__c != 'Contingent' || plannedGiving.rC_Giving__Bequest_Type__c == NULL) &&
               plannedGiving.rC_Giving__Giving_Amount__c  != null && plannedGiving.rC_Giving__Giving_Amount__c == 0 &&
               ((!setOfrecordtypeNames.contains(plannedGiving.RecordType.Name)) || plannedGiving.RecordType.Name != NULL)
            ) {
            if (plannedGiving.Gift_Date__c >= Date.valueOf('2014-04-01') 
                  && plannedGiving.Gift_Date__c <= Date.valueOf('2015-03-31')) {
               estimate = 161248.91;
            } else if (plannedGiving.Gift_Date__c >= Date.valueOf('2015-04-01') 
                  && plannedGiving.Gift_Date__c <= Date.valueOf('2016-03-31')) {
               estimate =  176617.70;
            } else if (plannedGiving.Gift_Date__c >= Date.valueOf('2016-04-01') 
                  && plannedGiving.Gift_Date__c <= Date.valueOf('2017-03-31')) {
               estimate = 168221.64;
            } else if (plannedGiving.Gift_Date__c >= Date.valueOf('2017-04-01') 
                  && plannedGiving.Gift_Date__c <= Date.valueOf('2018-03-31')) {
               estimate =  163177.95;
            } else {
               estimate =  0.0;
            }
         }
         plannedGiving.rC_Giving__Giving_Amount__c = plannedGiving.rC_Giving__Giving_Amount__c != null 
                                                     ? plannedGiving.rC_Giving__Giving_Amount__c : 0.0;

         if (fiscalYear != '') {
            value = mapOfKeyVsSumOfOutstandingPledge != null && mapOfKeyVsSumOfOutstandingPledge.containsKey(key)
                    ? mapOfKeyVsSumOfOutstandingPledge.get(key) + plannedGiving.rC_Giving__Giving_Amount__c + estimate
                    : plannedGiving.rC_Giving__Giving_Amount__c + estimate;
            if (!mapOfKeyVsSumOfOutstandingPledge.containsKey(key)) {
               mapOfKeyVsSumOfOutstandingPledge.put(key, 0);
            }
            mapOfKeyVsSumOfOutstandingPledge.put(key, value);
         }
         if (affiliation != '' && fiscalYear != '') {
            key = revenueType + '=>' + affiliation + '=>' + fiscalYear + '=>PA';//This '-PA' means it is for Affiliate
            value = mapOfKeyVsSumOfOutstandingPledge != null && mapOfKeyVsSumOfOutstandingPledge.containsKey(key)
                    ? mapOfKeyVsSumOfOutstandingPledge.get(key) + plannedGiving.rC_Giving__Giving_Amount__c + estimate
                    : plannedGiving.rC_Giving__Giving_Amount__c + estimate;
            if (!mapOfKeyVsSumOfOutstandingPledge.containsKey(key)) {
               mapOfKeyVsSumOfOutstandingPledge.put(key, 0);
            }
            mapOfKeyVsSumOfOutstandingPledge.put(key, value);
         }

         // Calculations for Account Yearly Roll Up records
         if (plannedGiving.rC_Giving__Account__c != null && fiscalYear != '') {
            key = plannedGiving.rC_Giving__Account__r.Name + '=>' + revenueType + '=>' + fiscalYear + '=>AN';
            value = mapOfKeyVsSumOfOutstandingPledge != null && mapOfKeyVsSumOfOutstandingPledge.containsKey(key)
                    ? mapOfKeyVsSumOfOutstandingPledge.get(key) + plannedGiving.rC_Giving__Giving_Amount__c + estimate
                    : plannedGiving.rC_Giving__Giving_Amount__c + estimate;
            if (!mapOfKeyVsSumOfOutstandingPledge.containsKey(key)) {
               mapOfKeyVsSumOfOutstandingPledge.put(key, 0.0);
            }
            mapOfKeyVsSumOfOutstandingPledge.put(key, value);
            if (fiscalYear == currentFiscalYear) {
               Double CFYTotal = mapOfKeyVsCFYSumOfOutstandingPledge != null && mapOfKeyVsCFYSumOfOutstandingPledge.containsKey(key)
                                 ? mapOfKeyVsCFYSumOfOutstandingPledge.get(key) + plannedGiving.rC_Giving__Giving_Amount__c
                                 : plannedGiving.rC_Giving__Giving_Amount__c;
               if (!mapOfKeyVsCFYSumOfOutstandingPledge.containsKey(key)) {
                  mapOfKeyVsCFYSumOfOutstandingPledge.put(key, 0.0);
               }
               mapOfKeyVsCFYSumOfOutstandingPledge.put(key, CFYTotal);
            }

            if (affiliation != '') {
               key = plannedGiving.rC_Giving__Account__r.Name + '=>' + affiliation + '=>' + revenueType + '=>' + fiscalYear + '=>AA';
               value = mapOfKeyVsSumOfOutstandingPledge != null && mapOfKeyVsSumOfOutstandingPledge.containsKey(key)
                       ? mapOfKeyVsSumOfOutstandingPledge.get(key) + plannedGiving.rC_Giving__Giving_Amount__c
                       : plannedGiving.rC_Giving__Giving_Amount__c;
               if (!mapOfKeyVsSumOfOutstandingPledge.containsKey(key)) {
                  mapOfKeyVsSumOfOutstandingPledge.put(key, 0.0);
               }
               mapOfKeyVsSumOfOutstandingPledge.put(key, value);
               if (fiscalYear == currentFiscalYear) {
                  Double CFYTotal = mapOfKeyVsCFYSumOfOutstandingPledge.containsKey(key)
                                    ? mapOfKeyVsCFYSumOfOutstandingPledge.get(key) + plannedGiving.rC_Giving__Giving_Amount__c
                                    : plannedGiving.rC_Giving__Giving_Amount__c;
                  if (!mapOfKeyVsCFYSumOfOutstandingPledge.containsKey(key)) {
                     mapOfKeyVsCFYSumOfOutstandingPledge.put(key, 0.0);
                  }
                  mapOfKeyVsCFYSumOfOutstandingPledge.put(key, CFYTotal);
               }
            }
         }
      } //end scope for loop

      for (String key : mapOfKeyVsSumOfOutstandingPledge.keySet()) {
         Campaign_Roll_Up__c newRecord = new Campaign_Roll_Up__c();
         if (key.split('=>')[2] == 'PN') {
            newRecord = new Campaign_Roll_Up__c(Name = key.split('=>')[0] + ' - ' + key.split('=>')[1],
                                                RecordTypeId = CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP,
                                                Outstanding_Pledges__c = mapOfKeyVsSumOfOutstandingPledge.get(key),
                                                CFY_Outstanding_Pledges__c = setCFYdollars( (key.split('=>')[1]), mapOfKeyVsSumOfOutstandingPledge.get(key) ),
                                                Fiscal_Year__c = (key.split('=>')[1]),
                                                Affiliation__c = 'NA',
                                                Revenue_Type__c = key.split('=>')[0]);
         } else if (key.split('=>')[3] == 'PA') {
            newRecord = new Campaign_Roll_Up__c(Name = key.split('=>')[0] + ' - ' + key.split('=>')[1] + ' - ' + key.split('=>')[2],
                                                RecordTypeId = CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP,
                                                Outstanding_Pledges__c = mapOfKeyVsSumOfOutstandingPledge.get(key),
                                                CFY_Outstanding_Pledges__c = setCFYdollars( (key.split('=>')[2]), mapOfKeyVsSumOfOutstandingPledge.get(key) ),
                                                Fiscal_Year__c = (key.split('=>')[2]),
                                                Revenue_Type__c = key.split('=>')[0],
                                                Affiliation__c = (key.split('=>')[1]));

         } else if (key.split('=>')[3] == 'AN') {
            String accountId = mapOfAccountNameVsId != null && mapOfAccountNameVsId.get(key.split('=>')[0]) != null
                               ? mapOfAccountNameVsId.get(key.split('=>')[0]) : '';
            newRecord = new Campaign_Roll_Up__c(Name = key.split('=>')[0] + ' - ' + key.split('=>')[1] + ' - ' + key.split('=>')[2],
                                                RecordTypeId = CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP,
                                                Outstanding_Pledges__c = mapOfKeyVsSumOfOutstandingPledge.get(key),
                                                Fiscal_Year__c = (key.split('=>')[2]),
                                                Revenue_Type__c = (key.split('=>')[1]),
                                                CFY_Outstanding_Pledges__c = mapOfKeyVsCFYSumOfOutstandingPledge.get(key),
                                                Affiliation__c = 'NA',
                                                Account_ID__c = accountId);
         } else if (key.split('=>')[4] == 'AA') {
            String accountId = mapOfAccountNameVsId != null && mapOfAccountNameVsId.get(key.split('=>')[0]) != null
                               ? mapOfAccountNameVsId.get(key.split('=>')[0]) : '';
            newrecord = new Campaign_Roll_Up__c(Name = key.split('=>')[0] + ' - ' + key.split('=>')[1] + ' - ' 
                                                     + key.split('=>')[2] + ' - ' + key.split('=>')[3],
                                                RecordTypeId = CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP,
                                                Outstanding_Pledges__c = mapOfKeyVsSumOfOutstandingPledge.get(key),
                                                Fiscal_Year__c = key.split('=>')[3],
                                                Revenue_Type__c = key.split('=>')[2],
                                                CFY_Outstanding_Pledges__c = mapOfKeyVsCFYSumOfOutstandingPledge.get(key),
                                                Affiliation__c = key.split('=>')[1],
                                                Account_ID__c = accountId);
         }
         listOfCampaignRollUps.add(newRecord);
      }
      if (!listOfCampaignRollUps.IsEmpty()) {
         try {
            insert listOfCampaignRollUps;
         } catch (Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('PlannedGivingIntentionBatch', 'execute', e.getMessage());
            log.logException(e);
            log.saveLogs();
         }
      }
   }

   global void finish(Database.BatchableContext Bc) {
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('PlannedGivingIntentionBatch FINISHED');
      log.saveLogs();
   }

   private Double setCFYdollars(String fy, Double dollars) {
      Double currentFYDollars = 0;
      if (fy == currentFiscalYear) {
         currentFYDollars = dollars;
      } else {
         currentFYDollars = 0;
      }
      return currentFYDollars;
   }

   private static Date getPGDate(Date d) {
      //run one additional year for saturday
      if (System.now().format('EEEE') == 'Saturday') {
         return d.addYears(-1);
      } else {
         return d;
      }
   }

   private String getFiscalYear(Datetime d) {
      if (d.month() >= orgInfo.FiscalYearStartMonth) {
         return String.valueOf(d.year() + 1);
      } else
         return String.valueOf(d.year());
   }

}