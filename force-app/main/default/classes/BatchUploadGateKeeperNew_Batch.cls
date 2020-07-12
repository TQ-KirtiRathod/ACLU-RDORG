/*
*
*Name  :  BatchUploadGateKeeperNew_batch
*Author:  roundCorner Inc.
*Date  :  Sept 14, 2018
*Purpose : The Gatekeeper will prioritise the BatchUpload records and limit the number of Batch Upload records 
           in BUP Flow.
*
*/
global class BatchUploadGateKeeperNew_Batch  implements Database.Batchable<sObject>, Database.stateful {
    private static String BATCH_UPLOAD_STATUS_INPROGRESS = 'In Progress';
    private static Set<String> BATCH_UPLOAD_STATUS = new Set<String> {
        Label.Status_New,
        Label.Status_Ready,
        Label.Status_Ready_for_RoundData,
        'To ZDM'
        
    };
    private List<String> batchUploadInitialStatusList = new List<String> { 
        Label.Status_New_Non_Springboard,
        Label.Status_New_SpringBoard
    };
    private Integer batchSize;
    private Integer batchUploadMaxInProgressCount;
    private BatchUploadGateKeeper_Settings__c csValues;
    private Integer maxThrough ;
    private Integer batchUploadAdvanceCount;
    private Set<Id> batchUploadIdSetToAdvance;
    private Set<String> setBUSyntheticKeyToAdvance;
    private Map<String,Boolean> mapUserSBId_DonPlgBoolean;
    private Map<String,Boolean> mapUserSBId_ActionBoolean;
    private String query;
    private Boolean isBUPresentToAdvance;
    private rC_Connect__Batch_Upload__c[] duplicateBatchUploadList;

     //Constructor
    global BatchUploadGateKeeperNew_Batch() {
        // Initializing the variables
        initialize();
        // Construct the query
        this.query = prepareQuery(false);
        isBUPresentToAdvance = false;
    }

     //Constructor
    global BatchUploadGateKeeperNew_Batch(Set<String> setBUSyntheticKeyToAdvance, Integer batchUploadAdvanceCount, rC_Connect__Batch_Upload__c[] duplicateBatchUploadList) {
        // Initializing the variables
        initialize();
        isBUPresentToAdvance = false;
        // Get all buffered batch upload synthetic keys to avoid duplicates
        this.setBUSyntheticKeyToAdvance = setBUSyntheticKeyToAdvance;
        // Construct the query
        this.query = prepareQuery(false);
        this.batchUploadAdvanceCount = batchUploadAdvanceCount;
        this.duplicateBatchUploadList = duplicateBatchUploadList;
    }

    global Database.QueryLocator start(Database.BatchableContext Bc ){
        // Get batch upload records which are need to be advanced for processing, skipping duplicates. 
        filterBatchUploads();

        if(batchUploadIdSetToAdvance.size() == 0) {
            isBUPresentToAdvance = true;
        }

        // Contruct query to get only filtered batch upload records to proecss
        this.query = prepareQuery(true);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext Bc, List<rC_Connect__Batch_Upload__c> scope){
        // Get batch upload In Progress count to limit processing
        Integer batchUploadInProgressCount = batchUploadInProgressCount();
        System.debug('##batchUploadInProgressCount :: ' + batchUploadInProgressCount);
        if(batchUploadInProgressCount >= batchUploadMaxInProgressCount) {
            isBUPresentToAdvance = true; 
            return;
        }

        // Get batch upload records count which are ready to process tp avoid large chunk at a time and keep in control
        Integer batchUploadReadyCount = batchUploadReadyCount();
        // Calculate the batch upload count which are required to process max # of records
        Integer buToBeInProgressCount = 0;
        buToBeInProgressCount = batchUploadInProgressCount + batchUploadReadyCount;
		System.debug('##buToBeInProgressCount :: ' + buToBeInProgressCount);
        // Do not process if already exceeding the max in progress limit
        if(buToBeInProgressCount >= batchUploadMaxInProgressCount) {
            isBUPresentToAdvance = true; 
            return;
        }

        List<rC_Connect__Batch_Upload__c> updateBUStatus = new List<rC_Connect__Batch_Upload__c>();
        for(rC_Connect__Batch_Upload__c objBU: scope){

            Boolean isAdvanceSBUserBU = false;
            //KM-11/17/2017 - Replaced SB_User_Id__c field with Synthetic_Matching_Key__c to use it as key - T-647812
            if(!String.IsBlank(objBU.Synthetic_Matching_Key__c)){

                  // Checking if the limit is reached for Batch or overall
                  if(batchUploadAdvanceCount > maxThrough || buToBeInProgressCount > batchUploadMaxInProgressCount) {
                      isBUPresentToAdvance = true;
                      break;
                  }

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
                      System.debug('rC_Connect__Batch_Upload_Status__c :: ' + objBu.rC_Connect__Batch_Upload_Status__c);
                  }

                  batchUploadAdvanceCount++;
                  buToBeInProgressCount++;
                  updateBUStatus.add(objBU);
              }
        }

        try{
            if(!updateBUStatus.IsEmpty()){
                update updateBUStatus;
            }
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadGateKeeperNew_batch','Execute method',e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }

    global void finish(Database.BatchableContext Bc){
        
        if(!isBUPresentToAdvance && batchUploadAdvanceCount < maxThrough 
            && batchUploadInProgressCount() < batchUploadMaxInProgressCount
            && !isGateKeeperRunningAlready()) {
                Database.executeBatch(new BatchUploadGateKeeperNew_batch(setBUSyntheticKeyToAdvance, batchUploadAdvanceCount, duplicateBatchUploadList), batchSize);

        } else {
            System.debug('Reset deuplicate flags :: ' + duplicateBatchUploadList);
            // Update duplicate batch upload records
            if(duplicateBatchUploadList.size() > 0) {
                for(rC_Connect__Batch_Upload__c batchUpload :duplicateBatchUploadList) {
                    batchUpload.Is_Processing_Duplicate__c = false;
                }
                
                update duplicateBatchUploadList;
            }
            
            Datetime sysTime = System.now().addSeconds( 30 );
            String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' 
                           + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
            String jobName = 'kwzd.KWD_ScheduledUpdatesAddress' + sysTime; 
            kwzd.KWD_ScheduledUpdatesAddress kws = new kwzd.KWD_ScheduledUpdatesAddress();
            System.schedule(jobName, chronExpression, kws);
        }
    }

    // Initializing the variables
    private void initialize() {
        csValues = (BatchUploadGateKeeper_Settings__c.getInstance('Default') != null) 
                    ? BatchUploadGateKeeper_Settings__c.getValues('Default') : null ;

        batchUploadAdvanceCount = batchUploadAdvanceCount == null ? 0 : batchUploadAdvanceCount;
        batchUploadMaxInProgressCount =  csValues.Max_In_Progress_BU_Allowed__c == null ? 1000 : (Integer)csValues.Max_In_Progress_BU_Allowed__c;
        batchSize = csValues.Gatekeeper_Batch_Scope__c == null ? 200 : (Integer)csValues.Gatekeeper_Batch_Scope__c;

        maxThrough = Integer.valueOf(csValues.Max_Number_Through__c);
        mapUserSBId_DonPlgBoolean = new Map<String,Boolean>();
        mapUserSBId_ActionBoolean = new Map<String,Boolean>();
        batchUploadIdSetToAdvance = new Set<Id>();
        duplicateBatchUploadList = duplicateBatchUploadList == null ? new rC_Connect__Batch_Upload__c[] { } : duplicateBatchUploadList;
        if (setBUSyntheticKeyToAdvance == null) {
            setBUSyntheticKeyToAdvance = new Set<String>();
        }
    }

    // Contruct the query for processing batch uploads
    private String prepareQuery(Boolean isFinalQuery) {

        // Collect user Ids, BU records
        String query = 'SELECT Id,rC_Connect__Address_Postal_Code__c,  rC_Connect__Batch_Upload_Source_File__c'
                    + ', rC_Connect__Batch_Upload_Contact_1_Matched__c, rC_Connect__Giving_Giving_Amount__c '
                    + ', rC_Connect__Address_Country__c, rC_Connect__Address_Street_Line_1__c, SB_User_Id__c'
                    + ', rC_Connect__Giving_Record_Type__c, Batch_Upload_Priority__c, Synthetic_Matching_Key__c, rC_Connect__Address_State__c '
                    + ' FROM rC_Connect__Batch_Upload__c ';
        String whereCondition = ' WHERE rC_Connect__Batch_Upload_Status__c = :batchUploadInitialStatusList';
        whereCondition += ' AND Is_Processing_Duplicate__c = false';
        
        String orderClause = ' ORDER BY Batch_Upload_Priority__c, CreatedDate ASC LIMIT '+ maxThrough;

        // Do not pick duplicate batch upload records
        if (isFinalQuery) {
            whereCondition += ' AND Id IN :batchUploadIdSetToAdvance ';
        } 

        query += whereCondition + orderClause;
		System.debug('Query :: ' + query);
        return query;
    }

    // Get batch upload records which are need to be advanced for processing, skipping duplicates.
    private void filterBatchUploads() {
        Map<String, String> syntheticKeyToBUIdMap = new Map<String, String>(); 
        
        for(rC_Connect__Batch_Upload__c batchUpload :Database.Query(query)) {
            // Checking if the similar batch upload record is already in queue based on synthetic key
            if(setBUSyntheticKeyToAdvance.contains(batchUpload.Synthetic_Matching_Key__c)) {
                //mark batch upload as duplicate
                batchUpload.Is_Processing_Duplicate__c = true;
                duplicateBatchUploadList.add(batchUpload);
                continue;
            }

            batchUploadIdSetToAdvance.add(batchUpload.Id);

            if(string.isNotBlank(batchUpload.Synthetic_Matching_Key__c)){
                //
                setBUSyntheticKeyToAdvance.add(batchUpload.Synthetic_Matching_Key__c);
                syntheticKeyToBUIdMap.put(batchUpload.Synthetic_Matching_Key__c, batchUpload.Id);
                if((batchUpload.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_DONATION ||
                        batchUpload.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_PLEDGE)){
                    mapUserSBId_DonPlgBoolean.put(batchUpload.Synthetic_Matching_Key__c,false);
                } else {
                    mapUserSBId_ActionBoolean.put(batchUpload.Synthetic_Matching_Key__c,false);
                }
            }
        }
		
        System.debug('##duplicateBatchUploadList :: ' + duplicateBatchUploadList.size());        
        System.debug('##batchUploadIdSetToAdvance :: ' + batchUploadIdSetToAdvance.size());        
        //Update batch upload which are duplicate based on Synthetic matching key and do not pick then in final query
        if(duplicateBatchUploadList.size() > 0) {
            update duplicateBatchUploadList;
        }

        // Remove batch upload records which are already queued
        for(rC_Connect__Batch_Upload__c batchUpload :queuedBatchUploadRecords(setBUSyntheticKeyToAdvance)) {
            batchUploadIdSetToAdvance.remove(syntheticKeyToBUIdMap.get(batchUpload.Synthetic_Matching_Key__c));
        }

    }

     private rC_Connect__Batch_Upload__c[] queuedBatchUploadRecords(Set<String> syntheticKeySet) {
        return database.Query('SELECT Id, Synthetic_Matching_Key__c FROM rC_Connect__Batch_Upload__c WHERE Synthetic_Matching_Key__c = :syntheticKeySet AND rC_Connect__Batch_Upload_Status__c IN :BATCH_UPLOAD_STATUS');
    }
    

    // Get batch upload In Progress count 
    private Integer batchUploadInProgressCount() {
        return database.countQuery('SELECT count() FROM rC_Connect__Batch_Upload__c WHERE rC_Connect__Batch_Upload_Status__c = :BATCH_UPLOAD_STATUS_INPROGRESS');
    }

    // Get batch upload to process count
    private Integer batchUploadReadyCount() {
        return database.countQuery('SELECT count() FROM rC_Connect__Batch_Upload__c WHERE rC_Connect__Batch_Upload_Status__c IN :BATCH_UPLOAD_STATUS');
    }
 
    // Check if Gatekeeper is already running
    private Boolean isGateKeeperRunningAlready() {
        AsyncApexJob[] AsyncApexJobList = [
             SELECT ApexClassId
                  , Id
                  , Status
                  , JobType
               FROM AsyncApexJob  
              WHERE JobType IN ('BatchApexWorker','ScheduledApex') 
                AND Status IN ('Preparing', 'Queued', 'Processing','Holding') 
                                AND ApexClass.Name = 'BatchUploadGateKeeperNew_batch'
        ];
      
        return AsyncApexJobList == null || AsyncApexJobList.size() == 0 ? false : true;
    }

}