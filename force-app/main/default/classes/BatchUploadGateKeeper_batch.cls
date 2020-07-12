/*
*
*Name  :  BatchUploadGateKeeper_batch
*Author:  Appirio India (Sai )
*Date  :  April 27, 2017
*Purpose : The Gatekeeper will prioritise the BatchUpload records and only advance a limited number of Batch Upload records to the BUP Flow.
*
*/
global class BatchUploadGateKeeper_batch implements Database.Batchable<sObject>, Database.stateful{

  private BatchUploadGateKeeper_Settings__c csValues;
  private Integer maxThrough ;
  private Set<Id> setBUIdsToAdvance;
  private Map<String,Boolean> mapUserSBId_DonPlgBoolean;
  private Map<String,Boolean> mapUserSBId_ActionBoolean;

  //Constructor
  global BatchUploadGateKeeper_batch() {
    setBUIdsToAdvance = new set<Id>();
    csValues = (BatchUploadGateKeeper_Settings__c.getInstance('Default') != null) 
             ? BatchUploadGateKeeper_Settings__c.getValues('Default') : null ;
    maxThrough = Integer.valueOf(csValues.Max_Number_Through__c);
    mapUserSBId_DonPlgBoolean = new Map<String,Boolean>();
    mapUserSBId_ActionBoolean = new Map<String,Boolean>();
  }


  global Database.QueryLocator start(Database.BatchableContext Bc ){
    List<String> batchUploadIntialStatuslst = new List<String>{Label.Status_New_Non_Springboard,Label.Status_New_SpringBoard};

    // Collect user Ids, BU records
    String Query = 'SELECT Id,rC_Connect__Address_Postal_Code__c,  rC_Connect__Batch_Upload_Source_File__c'
                 + ', rC_Connect__Batch_Upload_Contact_1_Matched__c, rC_Connect__Giving_Giving_Amount__c '
                 + ', rC_Connect__Address_Country__c, rC_Connect__Address_Street_Line_1__c, SB_User_Id__c'
                 + ', rC_Connect__Giving_Record_Type__c, Batch_Upload_Priority__c, Synthetic_Matching_Key__c '
                 + 'FROM rC_Connect__Batch_Upload__c '
                 + 'WHERE rC_Connect__Batch_Upload_Status__c=:batchUploadIntialStatuslst '
                 + 'ORDER BY Batch_Upload_Priority__c, CreatedDate ASC LIMIT '+ maxThrough;
    for(rC_Connect__Batch_Upload__c objBU: Database.Query(query)){
      setBUIdsToAdvance.add(objBU.Id);
      //KM-11/17/2017 - Replaced SB_User_Id__c field with Synthetic_Matching_Key__c to use it as key - T-647812
      if(string.isNotBlank(objBU.Synthetic_Matching_Key__c)){
        if((objBU.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_DONATION ||
          objBU.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_PLEDGE)){
          mapUserSBId_DonPlgBoolean.put(objBU.Synthetic_Matching_Key__c,false);
        } else {
          mapUserSBId_ActionBoolean.put(objBU.Synthetic_Matching_Key__c,false);
        }
      }

    }

    return Database.getQueryLocator([SELECT Id,rC_Connect__Address_Postal_Code__c, rC_Connect__Batch_Upload_Source_File__c
                                     , rC_Connect__Batch_Upload_Contact_1_Matched__c, rC_Connect__Address_State__c
                                     , rC_Connect__Address_Country__c, rC_Connect__Address_Street_Line_1__c, SB_User_Id__c
                                     , rC_Connect__Giving_Record_Type__c, Batch_Upload_Priority__c 
                                     , Synthetic_Matching_Key__c, rC_Connect__Giving_Giving_Amount__c
                                     FROM rC_Connect__Batch_Upload__c 
                                     WHERE rC_Connect__Batch_Upload_Status__c=:batchUploadIntialStatuslst]);
  }

  global void execute(Database.BatchableContext Bc, List<rC_Connect__Batch_Upload__c> scope){
      List<rC_Connect__Batch_Upload__c> updateBUStatus = new List<rC_Connect__Batch_Upload__c>();
      for(rC_Connect__Batch_Upload__c objBU: scope){

          if(setBUIdsToAdvance.contains(objBU.Id)){

              Boolean isAdvanceSBUserBU = false;
              //KM-11/17/2017 - Replaced SB_User_Id__c field with Synthetic_Matching_Key__c to use it as key - T-647812
              if(!String.IsBlank(objBU.Synthetic_Matching_Key__c)){

                  if(mapUserSBId_DonPlgBoolean.containsKey(objBU.Synthetic_Matching_Key__c)) {
                      if(mapUserSBId_DonPlgBoolean.get(objBU.Synthetic_Matching_Key__c)){
                          // do nothing and exit
                          continue;
                      } else {
                          mapUserSBId_DonPlgBoolean.put(objBU.Synthetic_Matching_Key__c,true);
                          isAdvanceSBUserBU = true;
                      }
                  } else if(mapUserSBId_ActionBoolean.containsKey(objBU.Synthetic_Matching_Key__c)){
                      if(mapUserSBId_ActionBoolean.get(objBU.Synthetic_Matching_Key__c)){
                          // do nothing and exit
                          continue;
                      } else {
                          mapUserSBId_ActionBoolean.put(objBU.Synthetic_Matching_Key__c,true);
                          isAdvanceSBUserBU = true;
                      }
                  }

              }

              if(String.IsBlank(objBU.SB_User_Id__c)
                  || (isAdvanceSBUserBU && !String.IsBlank(objBU.SB_User_Id__c))){

                  // Address is equals to US then Set status to ZDM
                  if(!String.IsBlank(objBU.rC_Connect__Address_Postal_Code__c)
                      && !String.IsBlank(objBU.rC_Connect__Address_Street_Line_1__c)
                      && !String.IsBlank(objBU.rC_Connect__Address_State__c)
                      && (objBU.rC_Connect__Address_Country__c == null 
                          || objBU.rC_Connect__Address_Country__c == 'US'
                          || objBU.rC_Connect__Address_Country__c == 'USA' 
                          || objBU.rC_Connect__Address_Country__c == 'United States') 
                  ){
                      objBU.rC_Connect__Batch_Upload_Status__c = Label.Status_To_ZDM;
                  }

                  // else If matchedContactId is not null then Set status to Ready and check if donation
                  else if(!String.IsBlank(objBU.rC_Connect__Batch_Upload_Contact_1_Matched__c)) {
                      //objBU.rC_Connect__Batch_Upload_Status__c = Label.Status_Ready;
                      if (objBU.rC_Connect__Giving_Giving_Amount__c != null && objBU.rC_Connect__Giving_Giving_Amount__c > 0) {
                          objBU.rC_Connect__Batch_Upload_Status__c = Label.Status_New;
                      } else {            
                          objBU.rC_Connect__Batch_Upload_Status__c = Label.Status_Ready;
                      }
                  }

                  // else send all to roundData
                  else{
                      objBu.rC_Connect__Batch_Upload_Status__c = Label.Status_Ready_for_RoundData;
                  }

                  updateBUStatus.add(objBU);
              }

          }
      }

      try{
          if(!updateBUStatus.IsEmpty()){
              update updateBUStatus;
          }
      }
      catch(Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadGateKeeper_batch','Execute method',e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
  }

  global void finish(Database.BatchableContext Bc){

    /* Need to know which class is correct  Tom added this
    Datetime sysTime = System.now().addSeconds( 30 );
    String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() 
                           + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
    String jobName = 'kwzd.KWD_ScheduledUpdates' + sysTime;
    // KnowWho Address only instance
    kwzd.KWD_ScheduledUpdates kws = new kwzd.KWD_ScheduledUpdates();
    System.schedule(jobName, chronExpression, kws);
    */

    Datetime sysTime = System.now().addSeconds( 30 );
    String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' 
                           + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
    String jobName = 'kwzd.KWD_ScheduledUpdatesAddress' + sysTime; 
    kwzd.KWD_ScheduledUpdatesAddress kws = new kwzd.KWD_ScheduledUpdatesAddress();
    System.schedule(jobName, chronExpression, kws);
  }
}