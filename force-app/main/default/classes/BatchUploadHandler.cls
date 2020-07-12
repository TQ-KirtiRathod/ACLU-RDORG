/*
*
*Name  :  BatchUploadHandler
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 24, 2016
*Purpose :  BatchUploadHandler is the handler class for the BatchUploadTrigger.
            This class enhances NGOC BUP processing with additional ACLU Custom Logic.
            Logic includes but not limited to
            - advancement of record through several preprocessing logic, See BUP diagram
            - BU record field enrichment
            - New record creation, Phone, Email, Preference, Soft Credits
            - Specialized Hard Credit/Soft Credit logic
            - Sets Apex Sharing for new records
            - City State Country Code Population, sets Preferred Billing/Shipping
            - Duplicate Payment resolution
            - specific error retry logic
* Change Log  :: Traction(Mounica V), January 31,2020-Ticket:BGE-02 : Included the logic to eliminate creation of duplicate preferences from BUP.
                 Tracyion(Nchandwani), June 1 2020: Link Child Opportunities to BUP 
* Sr.   Ticket#       Modified By       Modified Date       Description
*  1   ZD:#57270    roundCorner Inc.     24-Aug-2018        
*  2   ZD:#62462    roundCorner Inc.     22-Jan-2019
*  3   ZD:#67681    roundCorner Inc.     22-Jan-2019        Mark batchLogs HasError to False or True based on related BUs Status
*  4   ZD:#68427       SFDO              08-Dec-2019        Preferred Billing being set as False
*/
public without sharing class BatchUploadHandler {

  public static String ACCOUNT_ADDRESS_PREFIX = rC_Bios__Account_Address__c.sobjecttype.getDescribe().getKeyPrefix();
  public static String CONTACT_ADDRESS_PREFIX = rC_Bios__Contact_Address__c.sobjecttype.getDescribe().getKeyPrefix();
  public static String ACCOUNT_PREFIX = Account.sobjecttype.getDescribe().getKeyPrefix();
  public static String CONTACT_PREFIX = Contact.sobjecttype.getDescribe().getKeyPrefix();
  public static String ADDRESS_PREFIX = rC_Bios__Address__c.sobjecttype.getDescribe().getKeyPrefix();
  public static Set<String> batchUploadErrorStatus = new Set<String> {'Flagged', 'Matching Error'};
  public static integer oppAsyncBatchMax; //Zendesk :: #67681 :: Added the new Variable
  public static Boolean enableOppAffiliation = false;//Zendesk :: #67681 :: Added the new Variable
   static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            oppAsyncBatchMax = integer.ValueOf(q.Opportunity_Batch_Size__c);
            enableOppAffiliation = q.Enable_Affiliation_Change__c;
        } else {
            oppAsyncBatchMax = 50;
        }
    }
  /*
  *
  *Method mainEntry
  *@description : defining all trigger events
  *
  */
  public static void mainEntry(List<rC_Connect__Batch_Upload__c> newList, List<rC_Connect__Batch_Upload__c> oldList,
    Map<Id, rC_Connect__Batch_Upload__c> newMap, Map<Id, rC_Connect__Batch_Upload__c> oldMap, Boolean isInsert,
    Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {

    //if trigger is active
    if (TriggerState.isActive('BatchUpload_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) ) {

      // It is called on after insert
      if (isAfter) {
        if (isInsert) {
          onAfterInsert(newList);

        }
      }

      // It is called on after update
      if (isAfter) {
        if (isUpdate) {
          onAfterUpdate(newList, oldMap);
        }

      }
      if (isBefore) {
        if (isInsert) {
          beforeInsert(newList);
        }
      }
      if (isBefore) {
        if (isUpdate) {
          beforeUpdate(newMap, oldMap);

        }
      }
    }

  }

  private static void beforeInsert(List<rC_Connect__Batch_Upload__c> newList) {
    Set<Id> batchLogIds = new Set<Id>();
    Set<String> countryNameSet = new Set<String>();//Added by Bhavesh, T-647439
    autoPopulateCityAndState(newList);
    //populate Custom Address fields
    for (rC_Connect__Batch_Upload__c objBU : newList) {

      // Set Has Errors Checkbox on Batch Upload
      if (objBU.rC_Connect__Batch_Upload_Status__c != null
          && batchUploadErrorStatus.contains(objBU.rC_Connect__Batch_Upload_Status__c)
          && objBU.Batch_Log__c != null) {
        batchLogIds.add(objBU.Batch_Log__c);
      }

      //Set Giving Paid true for the "Cash/Check" Payment method
      if (objBU.rC_Connect__Payment_Method_Payment_Type__c == 'Cash/Check') {
        objBU.rC_Connect__Giving_Paid__c = true;
      }

      // Default status
      if (objBU.rC_Connect__Batch_Upload_Status__c != 'Suspend') {
        if (objBU.rC_Connect__Batch_Upload_Source_File__c == Label.Source_SpringBoard) {
          objBU.rC_Connect__Batch_Upload_Status__c = Label.Status_New_SpringBoard;
        } else {
          objBU.rC_Connect__Batch_Upload_Status__c = Label.Status_New_Non_Springboard;
        }
      }

      // Handle First and Last Name defaulting
      // Only applies if we're getting a new email subscriber, which comes in with no name or ID lookup fields populated.
      // If and only if the ID lookups are blank, we check the name fields.
      // If the Last Name field is empty (required field), we fill it.
      // If the First Name and Last Name fields are both blank, we also fill the first name.
      // If the First Name field is blank and the Last Name field is Unknown, we apply defaulting anyway.
      // This is a Springboard feature.

      if (String.isBlank(objBU.rC_Connect__Batch_Upload_Account_Matched__c)
          && String.isBlank(objBU.rC_Connect__Batch_Upload_Contact_1_Matched__c)) {
        if (String.isBlank(objBU.rC_Connect__Contact_1_Last_Name__c) ||
            objBU.rC_Connect__Contact_1_Last_Name__c == 'Unknown') {
          objBU.rC_Connect__Contact_1_Last_Name__c = Label.Default_Contact_Last_Name;

          if (String.isBlank(objBU.rC_Connect__Contact_1_First_Name__c)) {
            objBU.rC_Connect__Contact_1_First_Name__c = Label.Default_Contact_First_Name;
          }
        }

      }

      // Apply Advocacy address source for addresses coming in through specific Springboard sources.
      if (objBU.SB_Content_Type__c == 'springboard_petition' ||
          objBU.SB_Content_Type__c == 'sba_message_action' ||
          objBU.SB_Content_Type__c == 'sba_social_action' ||
          objBU.SB_Content_Type__c == 'webform' ||
          objBU.SB_Content_Type__c == 'volunteer_form' ||
          objBU.SB_Content_Type__c == 'signup_form') {
        objBU.Address_Source__c = 'Advocacy';
      }

      //Street Line 1 is null and the Postal code is not null
      if (String.IsBlank(objBU.rC_Connect__Address_Street_Line_1__c)
          && !String.IsBlank(objBU.rC_Connect__Address_Postal_Code__c)) {

        objBU.Custom_City__c = objBU.rC_Connect__Address_City__c;
        objBU.Custom_Country__c = objBU.rC_Connect__Address_Country__c ;
        objBU.Custom_State__c = objBU.rC_Connect__Address_State__c;
        objBU.Custom_Zip_Code__c = objBU.rC_Connect__Address_Postal_Code__c;
        objBU.rC_Connect__Address_City__c = null;
        objBU.rC_Connect__Address_Country__c = null;
        objBU.rC_Connect__Address_State__c = null;
        objBU.rC_Connect__Address_Postal_Code__c = null;
        objBU.rC_Connect__Address_Street_Line_2__c = null;
      }
      // Commented as this is shifted to BU_Intializer_SBDupIdentifier_batch Class
      /*if(!String.IsBlank(objBU.rC_Connect__Address_Postal_Code__c)  && !String.IsBlank(objBU.rC_Connect__Address_Street_Line_1__c)
          && (objBU.rC_Connect__Address_Country__c == null || objBU.rC_Connect__Address_Country__c == 'US'
              || objBU.rC_Connect__Address_Country__c == 'USA' || objBU.rC_Connect__Address_Country__c == 'United States') ){
          objBU.rC_Connect__Batch_Upload_Status__c = 'To ZDM';
      }*/

      //for issue I-288441
      if (objBU.rC_Connect__Address_Preferred_Billing__c == TRUE
          && (objBU.rC_Connect__Giving_Record_Type__c == 'Donation'
              || objBU.rC_Connect__Giving_Record_Type__c == 'Pledge')
              && !String.IsBlank(objBU.rC_Connect__Address_Postal_Code__c)) {

        objBU.Custom_Zip_Code__c = objBU.rC_Connect__Address_Postal_Code__c;
      }

      //T-647864 - Setting Shipping and Billing Preferences for non-donation/donation addresses - 11/20/2017 - KM
      Set<String> contentTypeSet = new Set<String>{'Advocacy Action', 'springboard_petition',
                                                   'sba_message_action', 'sba_social_action',
                                                   'webform', 'volunteer_form', 'Email Sign Up'};
      if (objBU.rC_Connect__Giving_Giving_Amount__c == null
            || contentTypeSet.contains(objBU.SB_Content_Type__c)) {

        objBU.rC_Connect__Address_Preferred_Billing__c = false;
        objBU.rC_Connect__Address_Preferred_Shipping__c = false;

     } else if(objBU.rC_Connect__Giving_Giving_Amount__c != null) {

         objBU.rC_Connect__Address_Preferred_Billing__c = true;
         objBU.rC_Connect__Address_Preferred_Shipping__c = true;
     }
     //Added below code by Bhavesh: Task: T-647439
     if ( objBU.rC_Connect__Address_Country__c != null )
        countryNameSet.add( objBU.rC_Connect__Address_Country__c );
     //End Task:T-647439

     //T-656819
     if(objBU.rC_Connect__Giving_Record_Type__c == 'Pledge' && objBU.rC_Connect__Giving_Paid__c) {
       objBU.Upgrade_Amount__c = objBU.rC_Connect__Giving_Giving_Amount__c;
     }
     
     /*Traction(Mounica V),January 31,2020 : BGE-02 :  Copy the Preference code (1,2,3) related NGOC fields to the custom fields*/
     //Preference code 1
     if(objBU.rC_Connect__Preferences_1_Code_Value__c <> null && objBU.rC_Connect__Preferences_1_Code_Value__c <> ''){
        objBU.Preferences_1_Code_Value__c = objBU.rC_Connect__Preferences_1_Code_Value__c;
        objBU.Preferences_1_Status__c = 'New';
        objBU.rC_Connect__Preferences_1_Code_Value__c ='';
       }
      if(objBU.rC_Connect__Preferences_1_End_Date__c <> null){
        objBU.Preferences_1_End_Date__c = objBU.rC_Connect__Preferences_1_End_Date__c;
        objBU.rC_Connect__Preferences_1_End_Date__c = null;
       }
       if(objBU.rC_Connect__Preferences_1_Start_Date__c <> null){
        objBU.Preferences_1_Start_Date__c = objBU.rC_Connect__Preferences_1_Start_Date__c;
        objBU.rC_Connect__Preferences_1_Start_Date__c = null;
       }
       //Preference Code 2
       if(objBU.rC_Connect__Preferences_2_Code_Value__c <> null && objBU.rC_Connect__Preferences_2_Code_Value__c <> ''){
        objBU.Preferences_2_Status__c = 'New';   
        objBU.Preferences_2_Code_Value__c = objBU.rC_Connect__Preferences_2_Code_Value__c;
        objBU.rC_Connect__Preferences_2_Code_Value__c ='';
       }
       if(objBU.rC_Connect__Preferences_2_End_Date__c <> null){
        objBU.Preferences_2_End_Date__c = objBU.rC_Connect__Preferences_2_End_Date__c;
        objBU.rC_Connect__Preferences_2_End_Date__c = null;
       }
       if(objBU.rC_Connect__Preferences_2_Start_Date__c <> null){
        objBU.Preferences_2_Start_Date__c = objBU.rC_Connect__Preferences_2_Start_Date__c;
        objBU.rC_Connect__Preferences_2_Start_Date__c = null;
       }
       //Preference Code 3
       if(objBU.rC_Connect__Preferences_3_Code_Value__c <> null && objBU.rC_Connect__Preferences_3_Code_Value__c <> ''){
        objBU.Preferences_3_Code_Value__c = objBU.rC_Connect__Preferences_3_Code_Value__c;
        objBU.Preferences_3_Status__c = 'New';
        objBU.rC_Connect__Preferences_3_Code_Value__c ='';
       }
       if(objBU.rC_Connect__Preferences_3_End_Date__c <> null){
        objBU.Preferences_3_End_Date__c = objBU.rC_Connect__Preferences_3_End_Date__c;
        objBU.rC_Connect__Preferences_3_End_Date__c = null;
       }
       if(objBU.rC_Connect__Preferences_3_Start_Date__c <> null){
        objBU.Preferences_3_Start_Date__c = objBU.rC_Connect__Preferences_3_Start_Date__c;
        objBU.rC_Connect__Preferences_3_Start_Date__c = null;
       }
       // Preference 4
        if(objBU.Preferences_4_Code_Value__c <> null && objBU.Preferences_4_Code_Value__c <> ''){
        objBU.Preferences_4_Status__c = 'New';
       }
       // Preference 5
        if(objBU.Preferences_5_Code_Value__c <> null && objBU.Preferences_5_Code_Value__c <> ''){
        objBU.Preferences_5_Status__c = 'New';
       }
       // Preference 1
        if(objBU.Preferences_1_Code_Value__c <> null && objBU.Preferences_1_Code_Value__c <> ''){
        objBU.Preferences_1_Status__c = 'New';
       }
       // Preference 2
        if(objBU.Preferences_2_Code_Value__c <> null && objBU.Preferences_2_Code_Value__c <> ''){
        objBU.Preferences_2_Status__c = 'New';
       }
         // Preference 3
       if(objBU.Preferences_3_Code_Value__c <> null && objBU.Preferences_3_Code_Value__c <> ''){
        objBU.Preferences_3_Status__c = 'New';
       }// BGE-02 END
     
    }
    Set<Id> committedbatchIds = new Set<Id>();
    if (!batchLogIds.isEmpty()) {
      updateHasErrorsCheckbox(batchLogIds, committedbatchIds );
    }
    //Added below code by Bhavesh: Task: T-647439
    if( countryNameSet.size()>0 ){
        updateCountryCode( newList, countryNameSet);//Added by Bhavesh, T-647439
    }
    //End Task:T-647439


    updatePreferredBillingAndShipping( newList, null );//added ByBHavesh I-304185
  }

  private static void beforeUpdate(Map<Id, rC_Connect__Batch_Upload__c> newMap, Map<Id, rC_Connect__Batch_Upload__c> oldMap) {
    List<rC_Connect__Batch_Upload__c> listOfAddress = new List<rC_Connect__Batch_Upload__c>();
    set<Id> batchLogIds = new Set<Id>();
    Map<Id, Set<Id>> accIdWithBUIdSetMap = new Map<Id, Set<Id>>();
    Map<String, Set<Id>> PaymentMethodWithBUIdSetMap = new Map<String, Set<Id>>();
    List< rC_Connect__Batch_Upload__c > newList = newMap.values();
    Set<Id> buRecordIdsToUpdatePaymentMethod = new Set<Id>();
    Set<String> countryNameSet = new Set<String>();//Added by Bhavesh, T-647439
    Set<String> duplicatePaymentMethodIdSet = new Set<String>();
    Set<id> batchCommittedIds = new Set<Id>();
    Set<id> batchUploadCommittedIds = new Set<id>();

    for (rC_Connect__Batch_Upload__c bu : newList) {
      //skip trigger logic for in progress batch uploads - I-318881
      if(bu.rC_Connect__Batch_Upload_Status__c == 'In Progress'){
        continue;
      }

      // updateHasErrorsCheckbox
      if (bu.rC_Connect__Batch_Upload_Status__c != null && bu.Batch_Log__c != null
          && batchUploadErrorStatus.contains(bu.rC_Connect__Batch_Upload_Status__c)
          && (bu.rC_Connect__Batch_Upload_Status__c != oldMap.get(bu.Id).rC_Connect__Batch_Upload_Status__c
              || bu.Batch_Log__c != oldMap.get(bu.Id).Batch_Log__c)) {
        batchLogIds.add(bu.Batch_Log__c);
      
      // Zendesk: #62462
      } else if(bu.Batch_Log__c != null
               && bu.rC_Connect__Batch_Upload_Status__c == 'Committed' 
               && bu.rC_Connect__Batch_Upload_Status__c != oldMap.get(bu.Id).rC_Connect__Batch_Upload_Status__c) {
                   batchCommittedIds.add(bu.Batch_Log__c);
                   batchUploadCommittedIds.add(bu.id);
      }//End#62462

      //Set Giving Paid true for the "Cash/Check" Payment method
      if (bu.rC_Connect__Payment_Method_Payment_Type__c != oldMap.get(bu.Id).rC_Connect__Payment_Method_Payment_Type__c
          && bu.rC_Connect__Payment_Method_Payment_Type__c == 'Cash/Check') {
        bu.rC_Connect__Giving_Paid__c = true;
      }

      if (bu.rC_Connect__Address_Postal_Code__c != null
          && bu.rC_Connect__Address_Postal_Code__c != oldMap.get(bu.Id).rC_Connect__Address_Postal_Code__c) {
        listOfAddress.add(bu);
      }
      //system.assert(false,bu.kwrc__KW_Error_Code__c+'>>>>'+oldMap.get(bu.Id).rC_Connect__Batch_Upload_Status__c);
      if (bu.kwrc__KW_Error_Code__c != null && oldMap.get(bu.Id).rC_Connect__Batch_Upload_Status__c == 'To ZDM' ) {
        if (bu.rC_Connect__Batch_Upload_Contact_1_Matched__c != null) {
          //bu.rC_Connect__Batch_Upload_Status__c = Label.Status_Ready;
          if (bu.rC_Connect__Giving_Giving_Amount__c != null && bu.rC_Connect__Giving_Giving_Amount__c > 0) {
            bu.rC_Connect__Batch_Upload_Status__c = Label.Status_New;
          } else {
            bu.rC_Connect__Batch_Upload_Status__c = Label.Status_Ready;
          }
        } else if (string.isBlank(bu.rC_Connect__Batch_Upload_Contact_1_Matched__c)) {
          bu.rC_Connect__Batch_Upload_Status__c = Label.Status_Ready_for_RoundData;
        } else {
          bu.rC_Connect__Batch_Upload_Status__c = Label.Status_New;
        }
      }

      /*****Start****************
       * Added by : Bhavesh, T-641622, 01/11/2017
       * ******************/
      //System.debug(bu.rC_Connect__Batch_Upload_Account_Matched__c);


      if ( bu.rC_Connect__Batch_Upload_Account_Matched__c != null
           && bu.rC_Connect__Payment_Method_Payment_Type__c != null
           && bu.rC_Connect__Batch_Upload_Status__c != null && bu.rC_Connect__Batch_Upload_Status__c == 'Matching Error'
           && ( ( oldMap.get(bu.id).rC_Connect__Batch_Upload_Status__c != NULL
                  && oldMap.get(bu.id).rC_Connect__Batch_Upload_Status__c != bu.rC_Connect__Batch_Upload_Status__c )
                || oldMap.get(bu.id).rC_Connect__Batch_Upload_Status__c == NULL )
           && bu.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c != null
           && bu.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.indexOf('Paymnet Method IDs:') >= 0
           && (( oldMap.get(bu.id).rC_Connect__Batch_Upload_Flagged_Technical_Reason__c != null
                 && oldMap.get(bu.id).rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.indexOf('Paymnet Method IDs:') < 0 )
               || oldMap.get(bu.id).rC_Connect__Batch_Upload_Flagged_Technical_Reason__c == null )
           && bu.rC_Connect__Batch_Upload_Flagged_Reason__c != null
           && bu.rC_Connect__Batch_Upload_Flagged_Reason__c == 'More than one match on Account'
           && (( oldMap.get(bu.id).rC_Connect__Batch_Upload_Flagged_Reason__c != null
                 && oldMap.get(bu.id).rC_Connect__Batch_Upload_Flagged_Reason__c != bu.rC_Connect__Batch_Upload_Flagged_Reason__c )
               || oldMap.get(bu.id).rC_Connect__Batch_Upload_Flagged_Reason__c == null)) {
        /*if( bu.rC_Connect__Batch_Upload_Status__c != null && bu.rC_Connect__Batch_Upload_Status__c == 'Matching Error'
            && bu.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c != null
            && bu.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.indexOf('Paymnet Method IDs:') >= 0
            && bu.rC_Connect__Batch_Upload_Flagged_Reason__c != null && bu.rC_Connect__Batch_Upload_Flagged_Reason__c == 'More than one match on Account' ){*/
        if ( !accIdWithBUIdSetMap.containsKey( bu.rC_Connect__Batch_Upload_Account_Matched__c ) ) {
          accIdWithBUIdSetMap.put( bu.rC_Connect__Batch_Upload_Account_Matched__c, new Set<Id>() );
        }

        //Modified by rC : 08-22-2018
        //ZD#57473/ABUP-1 :: Retrieved duplicate payment method ids and used to query the same
        String technicalReason = bu.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c;
        for(String paymentMethodId :technicalReason.substring(technicalReason.indexOf('{')+1, technicalReason.indexOf('}')).split(',')) {
            duplicatePaymentMethodIdSet.add(paymentMethodId.trim());
        }

        accIdWithBUIdSetMap.get( bu.rC_Connect__Batch_Upload_Account_Matched__c ).add(bu.id);
        if ( !PaymentMethodWithBUIdSetMap.containsKey( bu.rC_Connect__Payment_Method_Payment_Type__c ) ) {
          PaymentMethodWithBUIdSetMap.put( bu.rC_Connect__Payment_Method_Payment_Type__c, new Set<Id>() );
        }
        PaymentMethodWithBUIdSetMap.get( bu.rC_Connect__Payment_Method_Payment_Type__c ).add(bu.id);
        buRecordIdsToUpdatePaymentMethod.add(bu.id);
      }
      /*****End*T-641622***************/

      //for issue I-288441
      if (bu.rC_Connect__Address_Preferred_Billing__c == TRUE && (bu.rC_Connect__Giving_Record_Type__c == 'Donation'
          || bu.rC_Connect__Giving_Record_Type__c == 'Pledge')  ) {
        bu.Custom_Zip_Code__c = bu.rC_Connect__Address_Postal_Code__c;
      }

         //Added below code by Bhavesh: Task: T-647439
         if( oldMap.get(bu.id).rC_Connect__Address_Country__c != bu.rC_Connect__Address_Country__c ){
             if(bu.rC_Connect__Address_Country__c != null)
                countryNameSet.add( bu.rC_Connect__Address_Country__c );
             else {
                 bu.Country_Full_Name__c = NULL;
             }

         }

         //End Task:T-647439



    }
    //Added below code by Bhavesh: Task: T-647439
    if( countryNameSet.size()>0 ){
        updateCountryCode( newList, countryNameSet);//Added by Bhavesh, T-647439

    }
    //End Task:T-647439

    // Start -- Added by : Bhavesh, T-641622, 01/11/2017
    if ( accIdWithBUIdSetMap.size() > 0 && PaymentMethodWithBUIdSetMap.size() > 0 ) {
      resolveDuplicatePaymentMethod( accIdWithBUIdSetMap, PaymentMethodWithBUIdSetMap, newMap, buRecordIdsToUpdatePaymentMethod, duplicatePaymentMethodIdSet);
    }
    //End T-641622

    if (!listOfAddress.isEmpty()) {
      autoPopulateCityAndState(listOfAddress);
    }

    // Zendesk: #62462
      if(batchUploadCommittedIds.size() > 0 && batchCommittedIds.size() > 0) {
          List<Batch_Log__c> batchLogsToUpdate = new List<Batch_Log__c>();
          List<rC_Connect__Batch_Upload__c> batchUploads = [
            SELECT id
                 , Batch_Log__c 
              FROM rC_Connect__Batch_Upload__c 
             WHERE Batch_Log__c IN :batchCommittedIds
               AND rC_Connect__Batch_Upload_Status__c = 'Flagged'];

          for(rC_Connect__Batch_Upload__c bus:batchUploads){
              if(batchUploadCommittedIds.contains(bus.Id)) {                 
                    continue;
                }  
              if(batchCommittedIds.Contains(bus.Batch_Log__c)) {
                  batchCommittedIds.remove(bus.Batch_Log__c);
              }
         }
         
      }

    // Zendesk: #62462
    if (!batchLogIds.isEmpty() || !batchCommittedIds.isEmpty()) {
      updateHasErrorsCheckbox(batchLogIds,batchCommittedIds);
    }//END#62462

    updatePreferredBillingAndShipping(newMap.values(), oldMap);//Added by Bhavesh, T-647918

   //ACL-023 1June2020:Nchandwani, Traction on Demand: Assiocate Child Opps
    trac_BupOpportunityHelper.associateBupOpp( newMap.values(), oldMap );
  }

  /*
  *
  *Method onAfterUpdate
  *@description : Calls on onAfterUpdate.
  */

  public static void onAfterUpdate (List<rC_Connect__Batch_Upload__c> BatchUploads, Map<Id, rC_Connect__Batch_Upload__c> mapBatchUploads) {
      System.debug('After Update');
    //Method Variables
    set<String> setPhoneBatch = new set<String>();
    set<String> setExistingId = new Set<String>();
    List<PreferenceWrapper> lstPreferenceWrapper = new List<PreferenceWrapper>();
    list<rC_Connect__Batch_Upload__c> createBatchEmail = new list<rC_Connect__Batch_Upload__c>();
    list<String> listPhoneExternalId = new list<String>();
    list<rC_Connect__Batch_Upload__c> listbatchPhoneUpload = new list<rC_Connect__Batch_Upload__c>();

    map<String, rC_Connect__Batch_Upload__c> mapBatchOpt = new map<String, rC_Connect__Batch_Upload__c>();
    map<String, rC_Connect__Batch_Upload__c> mapPhoneBatches =  new  map<String, rC_Connect__Batch_Upload__c>();
    set<Id> setContactIds = new set<Id>();
    set<String> setPhone = new set<String>();

    Map<String, rC_Connect__Batch_Upload__c> batchUploadMap = new Map<String, rC_Connect__Batch_Upload__c>();
    list<rC_Connect__Batch_Upload__c> batchUploadsToUpdateLst = new list<rC_Connect__Batch_Upload__c>();
    Set<Id> matchedGivingIds = new Set<Id>();
    List<Contact> secondaryContactListToUpdate = new List<Contact>();
    Map<Id, Id> mapOfAccountIdWithSecondaryContactId = new Map<Id, Id>();
    Map<Id, Id> mapOfSecondaryToPrimaryContact = new Map<Id, Id>();
    Map<Id, String> oppIdWithExternalIdMap  = new Map<Id, String>();
    Set<Id> sofCreditOppToUpdateOpenStageSet = new Set<Id>();//T-656869, Bhavesh
    List<rC_Connect__Batch_Upload__c> listBatchUploadsToUpdate  = new List<rC_Connect__Batch_Upload__c>();
    String updatedRecordsDetails;
    apexLogHandler.apexLog batchUploadsLog;
    rC_Connect__Batch_Upload__c[] batchUploadAddressValidateList = new rC_Connect__Batch_Upload__c[]{ };
    Map<String, String> accountIdToContact1IdMap = new Map<String, String>();
    Map<String, String> accountIdToContact2IdMap = new Map<String, String>();
    List<AsyncRequest__c> customCommitAsyncRequestList = new List<AsyncRequest__c>();
    
    Map<Id, Date> givingIdToCloseDate = new Map<Id, Date>();//#67681

    for (rC_Connect__Batch_Upload__c btups : BatchUploads) {
      //skip trigger logic for in progress batch uploads - I-318881
      if(btups.rC_Connect__Batch_Upload_Status__c == 'In Progress'){
        continue;
      }

      // createPhoneRecord
      if (btups.rC_Connect__Batch_Upload_Contact_1_Matched__c != null && btups.rC_Connect__Contact_1_Phone_1__c != null) {

        if (mapBatchUploads.get(btups.Id).rC_Connect__Batch_Upload_Contact_1_Matched__c != btups.rC_Connect__Batch_Upload_Contact_1_Matched__c) {
          String strContact = String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
          String externalId = strContact.Substring(0, 15) + '_' + btups.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]', '');
          if (!mapPhoneBatches.containsKey(externalId)) {
            mapPhoneBatches.put(externalId, btups);
          }
          setContactIds.add(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
          setPhone.add(btups.rC_Connect__Contact_1_Phone_1__c);
          /*listPhoneExternalId.add(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+btups.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]',''));
          setPhoneBatch.add(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+btups.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]',''));
          listbatchPhoneUpload.add(btups);*/
        }
      }
        //Zendesk : #67681
      if(btups.rC_Connect__Batch_Upload_Giving_Matched__c!= null 
         && btups.rC_Connect__Batch_Upload_Account_Matched__c!= null 
         && (btups.rC_Connect__Batch_Upload_Address_Matched__c != null
            || btups.rC_Connect__Batch_Upload_Address_2_Matched__c != null)
         && btups.rC_Connect__Batch_Upload_Status__c != null 
         && btups.rC_Connect__Batch_Upload_Status__c.equalsIgnoreCase('Committed')
         && (enableOppAffiliation || Test.isRunningTest())) {
            givingIdToCloseDate.put(btups.rC_Connect__Batch_Upload_Giving_Matched__c, btups.rC_Connect__Giving_Close_Date__c);
      }
      //updateEmailRecord
      if (btups.rC_Connect__Batch_Upload_Contact_1_Matched__c != null && btups.Cont1_Email__c != null) {
        if (mapBatchUploads != null && (mapBatchUploads.get(btups.Id).rC_Connect__Batch_Upload_Contact_1_Matched__c != btups.rC_Connect__Batch_Upload_Contact_1_Matched__c)) {
          if (!setExistingId.contains(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + btups.Cont1_Email__c)) {
            setExistingId.add(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + btups.Cont1_Email__c);
            mapBatchOpt.put(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + btups.Cont1_Email__c, btups);
            createBatchEmail.add(btups);
          } else if (setExistingId.contains(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + btups.Cont1_Email__c)
                     && (btups.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_DONATION ||
                         btups.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_PLEDGE
                        )) {
            //setExistingId.add(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+btups.Cont1_Email__c);
            mapBatchOpt.put(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0, 15) + '_' + btups.Cont1_Email__c, btups);
            createBatchEmail.add(btups);
          }
        }
      }

      //Creat Preference records if the pref1,pref2,pref4,pref3 & pref5 fields are populated
      if ( mapBatchUploads.get(btups.Id).rC_Connect__Batch_Upload_Status__c != btups.rC_Connect__Batch_Upload_Status__c
           && btups.rC_Connect__Batch_Upload_Status__c == 'Committed'
           && !String.IsBlank(btups.rC_Connect__Batch_Upload_Account_Matched__c)
           && (!String.IsBlank(btups.Preferences_5_Code_Value__c) || !String.IsBlank(btups.Preferences_4_Code_Value__c) || !String.IsBlank(btups.Preferences_1_Code_Value__c) ||
           !String.IsBlank(btups.Preferences_2_Code_Value__c) || !String.IsBlank(btups.Preferences_3_Code_Value__c))
         ) {
           List<rC_Bios__Preference__c> preferenceCodes = new List<rC_Bios__Preference__c>();

        if (!String.IsBlank(btups.Preferences_5_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_5_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_5_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '5-'+btups.Preferences_5_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_5_End_Date__c));
          
        }
        if (!String.IsBlank(btups.Preferences_4_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_4_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_4_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '4-'+btups.Preferences_4_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_4_End_Date__c));
         
        }
        //BGE-02
        if (!String.IsBlank(btups.Preferences_3_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_3_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_3_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '3-'+btups.Preferences_3_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_3_End_Date__c));
         
        }
        if (!String.IsBlank(btups.Preferences_2_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_2_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_2_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '2-'+btups.Preferences_2_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_2_End_Date__c));
         
        }
        if (!String.IsBlank(btups.Preferences_1_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_1_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_1_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '1-'+btups.Preferences_1_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_1_End_Date__c));
         
        }//End BGE-02
        
         lstPreferenceWrapper.add(new PreferenceWrapper(preferenceCodes,btups.id,btups.rC_Connect__Batch_Upload_Account_Matched__c));
         
      }
       
      // updateSoftCreditBatchUploads
      if (mapBatchUploads.get(btups.Id).rC_Connect__Batch_Upload_Status__c != btups.rC_Connect__Batch_Upload_Status__c
          && btups.rC_Connect__Batch_Upload_Status__c == 'Committed' && btups.Has_Soft_Credit__c
          && btups.Batch_Upload_Reference_ID__c != '' ) {
        batchUploadMap.put(btups.Batch_Upload_Reference_ID__c, btups);
        if (btups.rC_Connect__Batch_Upload_Giving_Matched__c != null) {
          matchedGivingIds.add(btups.rC_Connect__Batch_Upload_Giving_Matched__c);
        }
      }

      // Assign Correct Preferred Contact to the Account Created
      // Modified by :: Amar (rC) :: 31-Aug-2018
      // Zendesk: #57475
      Boolean isCommitted = btups.rC_Connect__Batch_Upload_Status__c == 'Committed';
      if(isCommitted && btups.rC_Connect__Batch_Upload_Contact_1_Matched__c != NULL
                && btups.rC_Connect__Contact1_Status__c == 'Inserted' && btups.rC_Connect__Account_Status__c  != 'Inserted') {
          accountIdToContact1IdMap.put(btups.rC_Connect__Batch_Upload_Account_Matched__c, btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
      }

      if(isCommitted && btups.rC_Connect__Batch_Upload_Contact_2_Matched__c != NULL
                && btups.rC_Connect__Contact2_Status__c == 'Inserted' && btups.rC_Connect__Account_Status__c  != 'Inserted') {
          accountIdToContact2IdMap.put(btups.rC_Connect__Batch_Upload_Account_Matched__c, btups.rC_Connect__Batch_Upload_Contact_2_Matched__c);
      }
      
      //Modified by :roundCorner Inc. 05-Dec-18 :: Ticket#61850
      //The intetion here to create a async request is to update account billing address if its blank and 
      //BU has the value in custom address fields
      Boolean isCustomAddressPresent = false;
      isCustomAddressPresent = String.isNotBlank(btups.Custom_Zip_Code__c) || String.isNotBlank(btups.Custom_State__c) || String.isNotBlank(btups.Custom_City__c) || String.isNotBlank(btups.Custom_Country__c);
      if(isCommitted && isCustomAddressPresent && btups.rC_Connect__Batch_Upload_Account_Matched__c != null) {
          Map<String, String> buIdToAccountIdMap = new Map<String, String>();
          buIdToAccountIdMap.put(btups.Id, btups.rC_Connect__Batch_Upload_Account_Matched__c);
          
          customCommitAsyncRequestList.add(new AsyncRequest__c(AsyncType__c ='account_CustomCommitAddress', 
                                       Object_API_Name__c = 'Account',
                                       Params__c = JSON.serialize(buIdToAccountIdMap) ));
      }

      //T-652003-Bhavesh & I-317482 jw  I-323666 jw
      /*if( btups.rC_Connect__Batch_Upload_Status__c == 'Committed' && btups.rC_Connect__Batch_Upload_Contact_2_Matched__c != NULL
          && btups.rC_Connect__Batch_Upload_Contact_2_Matched__c != btups.rC_Connect__Batch_Upload_Contact_1_Matched__c){
          if( btups.rC_Connect__Account_Status__c  == 'Inserted' ){
              secondaryContactListToUpdate.add(new Contact(id = btups.rC_Connect__Batch_Upload_Contact_2_Matched__c, rC_Bios__Secondary_Contact__c = True));
          } else if( btups.rC_Connect__Account_Status__c == 'Updated' && btups.rC_Connect__Batch_Upload_Account_Matched__c != NULL ){
              mapOfAccountIdWithSecondaryContactId.put( btups.rC_Connect__Batch_Upload_Account_Matched__c, btups.rC_Connect__Batch_Upload_Contact_2_Matched__c);
              // new setting primary
              mapOfSecondaryToPrimaryContact.put(btups.rC_Connect__Batch_Upload_Contact_2_Matched__c,btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
          }
      }*/
      if( btups.rC_Connect__Batch_Upload_Status__c == 'Committed'
      && mapBatchUploads.get(btups.id).rC_Connect__Batch_Upload_Status__c != btups.rC_Connect__Batch_Upload_Status__c
      && btups.Transaction_External_Id__c != NULL && btups.isSoft_Credit__c == FALSE){
          oppIdWithExternalIdMap.put( btups.rC_Connect__Batch_Upload_Giving_Matched__c , btups.Transaction_External_Id__c);
      }

      //T-656869, Bhavesh
      if( btups.rC_Connect__Batch_Upload_Status__c == 'Committed'
         && mapBatchUploads.get(btups.id).rC_Connect__Batch_Upload_Status__c != btups.rC_Connect__Batch_Upload_Status__c
         && btups.TPA_Bypass__c == TRUE
         && btups.rC_Connect__Batch_Upload_Giving_Matched__c != NULL){
          sofCreditOppToUpdateOpenStageSet.add(btups.rC_Connect__Batch_Upload_Giving_Matched__c);
      }


      //Added by Aashita for issue I-309480
      if (btups.rC_Connect__Batch_Upload_Status__c == 'Flagged' && mapBatchUploads.get(btups.id).rC_Connect__Batch_Upload_Status__c != 'Flagged'
          && btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c != null
          && (btups.Error_Count__c == null || btups.Error_Count__c <= integer.valueof(System.Label.Batch_Upload_Error_Retry_Limit))
         ) {
        rC_Connect__Batch_Upload__c bu = new rC_Connect__Batch_Upload__c(Id = btups.Id);
        bu.Error_Count__c = (btups.Error_Count__c == null) ? 0 : btups.Error_Count__c;
        bu.Error_Count__c ++;
        if (btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.startsWith(System.Label.Batch_Upload_Flagged_Reason_For_SB_User_ID)
            && btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.contains(System.Label.Batch_Upload_Flagged_Reason_BUP_CommitDomain)) {
          bu.rC_Connect__Batch_Upload_Status__c = 'Ready for roundData';
          bu.rC_Connect__Batch_Upload_Account_Matched__c = null;
        }

        //I-291447 updated 'unable to access' to contains vs startswith
        //I-294347 added contains UNABLE_TO_LOCK_ROW
        // Modified by :: Amar (rC) :: 24-Aug-2018
        // Ticket: ABUP-2#57270
        Boolean isUnableToObtainError = btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.contains(System.Label.Unable_to_obtain_exclusive_access);
        Boolean isInsufficientAccessError = btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.startsWith(System.Label.Insufficient_access_rights_on);
        Boolean isUnableToLockRowError = btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.contains(System.Label.Unable_To_Lock_Row);
        Boolean isErrorOnAddressTopic = btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.contains( ACCOUNT_ADDRESS_PREFIX)
                  || btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.contains( CONTACT_ADDRESS_PREFIX)
                  || btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c.contains( ADDRESS_PREFIX );
        if(isUnableToObtainError || isUnableToLockRowError) {
            bu.rC_Connect__Batch_Upload_Status__c = 'Ready for roundData';
        }

        if(isInsufficientAccessError && isErrorOnAddressTopic) {
            batchUploadAddressValidateList.add(btups);
        }

        if ( btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c == System.Label.BUP_SFDC_Resources_Error ) {
          if ( btups.rC_Connect__Giving_Record_Type__c == 'Donation' || btups.rC_Connect__Giving_Record_Type__c == 'Pledge') {
            bu.rC_Connect__Batch_Upload_Status__c = 'New';
          } else {
            bu.rC_Connect__Batch_Upload_Status__c = 'Ready';
          }
        }

        /*if(updatedRecordsDetails == null) {
            updatedRecordsDetails = 'Batch upload ID: '+btups.ID+', Old Status: '+ mapBatchUploads.get(btups.Id).rC_Connect__Batch_Upload_Status__c+', Updated Status: '+ btups.rC_Connect__Batch_Upload_Status__c+', Batch Upload: Flagged Reason: '+btups.rC_Connect__Batch_Upload_Flagged_Reason__c+', Batch Upload: Flagged Technical Reason: '+btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c+', Batch Upload: Error Category: '+btups.rC_Connect__Batch_Upload_Error_Category__c;
        }else {*/
            updatedRecordsDetails = 'Batch upload ID: '+btups.ID+', Old Status: '+ mapBatchUploads.get(btups.Id).rC_Connect__Batch_Upload_Status__c+', Updated Status: '+ btups.rC_Connect__Batch_Upload_Status__c+', Batch Upload: Flagged Reason: '+btups.rC_Connect__Batch_Upload_Flagged_Reason__c+', Batch Upload: Flagged Technical Reason: '+btups.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c+', Batch Upload: Error Category: '+btups.rC_Connect__Batch_Upload_Error_Category__c;
        //}

        batchUploadsLog = new apexLogHandler.apexLog('BatchUploadHandler', 'afterUpdate', updatedRecordsDetails);
        listBatchUploadsToUpdate.add(bu);
      }

    }

    if(batchUploadsLog != null) {
        batchUploadsLog.saveLogs();
    }
    try {
          //Zendesk :: #67681 :: This logic is used to created multiple AsycRequest
        if(!givingIdToCloseDate.isEmpty()){//givingset != null && givingset.size() > 0) {
            List<Opportunity> opList = [SELECT  id
                                              , Account_Affiliation__c
                                              , Account.Affiliation__c 
                                              , AccountId
                                              , rC_Giving__Parent__c
                                              , Account.Lock_Affiliation__c
                                         FROM Opportunity
                                         WHERE rC_Giving__Parent__c IN :givingIdToCloseDate.keySet() //givingset
                                           AND CloseDate = :givingIdToCloseDate.values()
                                           AND StageName = 'Completed'];
           
            Set<Id> givingIds = new Set<Id>();
           
            for(Opportunity op :opList){
                if(op.Account_Affiliation__c != op.Account.Affiliation__c 
                   && !op.Account.Lock_Affiliation__c){
                       givingIds.add(op.id);
                }
            }
            //Zendesk :: #67681 :: This logic is used to created multiple AsycRequest
            if(givingIds.size() > 0) {
            System.debug(oppAsyncBatchMax);
                List<AsyncRequest__c> asyncRequestList = new List<AsyncRequest__c>();
                while(givingIds.size() > 0){
                    if(givingIds.size() >= oppAsyncBatchMax || Test.isRunningTest()){
                        list<String> idList = new list<String>();
                        Integer counter = 1;
                        for(Id oppId : givingIds) {
                          idList.add(oppId);
                          givingIds.remove(oppId);
                          counter++;
                        if(counter-1 ==oppAsyncBatchMax) break;
                    }
                    asyncRequestList.add(new AsyncRequest__c(AsyncType__c ='Opportunity_AffiliationSet', Object_API_Name__c = 'Opportunity',
                                          Params__c = String.join(idList,',')));
                    } else {
                      break;
                    }
                 }
                if(givingIds != null && givingIds.size() > 0) {
                    asyncRequestList.add( new AsyncRequest__c(AsyncType__c ='Opportunity_AffiliationSet', Object_API_Name__c = 'Opportunity',
                                                    Params__c = String.join(new List<Id>(givingIds),',')));
                }
                System.debug(asyncRequestList);
                insert asyncRequestList;
            }
           
        }
    }Catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'afterUpdate', e.getMessage());
            log.logException(e);
            log.saveLogs(); 
    } //Zendesk :: END #67681
    
    //Ticket#61850
    if(customCommitAsyncRequestList.size() > 0) {
        insert customCommitAsyncRequestList;
    }

    if(!listBatchUploadsToUpdate.isEmpty()) {
      try {
          update listBatchUploadsToUpdate;
        } catch (Exception e) {
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'afterUpdate', e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
    }

    // Retry addresses having insufficient priviledges
    // Modified by :: Amar (rC) :: 24-Aug-2018
    // Ticket: ABUP-2#57270
    if (batchUploadAddressValidateList.size() > 0) {
        BatchUploadHandler_RetryAddress.retryAddress(batchUploadAddressValidateList);
    }

    // Assign Correct Preferred Contact to the Account Created
    // Modified by :: Amar (rC) :: 31-Aug-2018
    // Zendesk: #57475
    Map<String, Contact[]> accountIdToContactsMap = new Map<String, Contact[]>();
    Contact[] contactUpdateableList = new Contact[] { };
    Set<String> accountIdSet = new Set<String>();
    accountIdSet.addAll(accountIdToContact1IdMap.keySet());
    accountIdSet.addAll(accountIdToContact2IdMap.keySet());
    if(!accountIdSet.isEmpty()) {
        for(Contact contact :[
            SELECT Id
                 , rC_Bios__Preferred_Contact__c
                 , rC_Bios__Secondary_Contact__c
                 , AccountId
              FROM Contact
             WHERE AccountId IN :accountIdSet
               AND (rC_Bios__Preferred_Contact__c = true
                OR rC_Bios__Secondary_Contact__c = true)
        ]) {
            if(!accountIdToContactsMap.isEmpty() && accountIdToContactsMap.containsKey(contact.AccountId)) {
                accountIdToContactsMap.get(contact.AccountId).add(contact);
            } else {
                accountIdToContactsMap.put(contact.AccountId, new Contact[] { contact });
            }
        }
        
        for(String accountId :accountIdSet) {
            Contact[] contactList = accountIdToContactsMap.get(accountId);
            if(contactList != null && contactList.size() > 1) {
                continue;
            }
            Contact contact = new Contact();
            Contact contact2 = new Contact();
            if(!accountIdToContact1IdMap.isEmpty() && accountIdToContact1IdMap.containsKey(accountId)) {
                contact = new Contact(Id = accountIdToContact1IdMap.get(accountId));
                if(contactList != null && contactList[0].rC_Bios__Preferred_Contact__c) {
                    contact.rC_Bios__Secondary_Contact__c = true;
                    contactUpdateableList.add(contact);
                } else if(contactList != null && contactList[0].rC_Bios__Secondary_Contact__c) {
                    contact.rC_Bios__Preferred_Contact__c = true;
                    contactUpdateableList.add(contact);
                } else if(contactList == null){
                    contact.rC_Bios__Preferred_Contact__c = true;
                    contactUpdateableList.add(contact);
                }
            }
            if(!accountIdToContact2IdMap.isEmpty() && accountIdToContact2IdMap.containsKey(accountId)) {
                contact2 = new Contact(Id = accountIdToContact2IdMap.get(accountId));
                if(contactList != null && contactList[0].rC_Bios__Preferred_Contact__c && contact.rC_Bios__Secondary_Contact__c == false) {
                    contact2.rC_Bios__Secondary_Contact__c = true;
                    contactUpdateableList.add(contact2);
                } else if(contactList != null && contactList[0].rC_Bios__Secondary_Contact__c && contact.rC_Bios__Preferred_Contact__c == false) {
                    contact2.rC_Bios__Preferred_Contact__c = true;
                    contactUpdateableList.add(contact2);
                } else if(contactList == null){
                    contact2.rC_Bios__Secondary_Contact__c = true;
                    contactUpdateableList.add(contact2);
                }
            }
        }//for
        
        if(contactUpdateableList.size() > 0) {
        /* Traction(Mounica v),Jan 27,2020 , BGE-14: Changed the update to database.update to allow partial success*/
         List<Database.SaveResult> updateResults = database.update(contactUpdateableList,false); 
        }
    }

    //system.debug('start');
    /*AK :: NOT REQUIRED
    if( mapOfAccountIdWithSecondaryContactId.size() > 0 ){
        for( Account acc : [SELECT id, rC_Bios__Secondary_Contact__c, rC_Bios__Preferred_Contact__c
                            FROM Account
                            WHERE Id IN: mapOfAccountIdWithSecondaryContactId.keySet() ]
        ){
            //system.debug('acc: '+ acc);system.debug('map:  '+ mapOfAccountIdWithSecondaryContactId.get(acc.Id));
            ID secondaryContactId = mapOfAccountIdWithSecondaryContactId.get(acc.Id);

            //system.debug('secondaryContactId::  '+ secondaryContactId);
            //compares BUP contact 2 to preferred and secondary Then
            //compares BUP contact 1 to preferred and secondary
            // if a match occurs dont do the switching
            if( (mapOfAccountIdWithSecondaryContactId.get(acc.Id) == acc.rC_Bios__Secondary_Contact__c
                 || mapOfAccountIdWithSecondaryContactId.get(acc.Id) == acc.rC_Bios__Preferred_Contact__c)
                &&
                ( mapOfSecondaryToPrimaryContact.get(secondaryContactId) == acc.rC_Bios__Secondary_Contact__c
                 || mapOfSecondaryToPrimaryContact.get(secondaryContactId) == acc.rC_Bios__Preferred_Contact__c )
              ){
              system.debug('bypassed');
              continue;
            }

            if( acc.rC_Bios__Secondary_Contact__c == NULL ){
                secondaryContactListToUpdate.add(new Contact(id = mapOfAccountIdWithSecondaryContactId.get(acc.Id),
                                                             rC_Bios__Secondary_Contact__c = True,
                                                             rC_Bios__Preferred_Contact__c = False
                                                             ));
            }
            //system.debug('testing: '+mapOfSecondaryToPrimaryContact);
            if( //acc.rC_Bios__Preferred_Contact__c == NULL
                //&& mapOfSecondaryToPrimaryContact.containsKey(acc.rC_Bios__Secondary_Contact__c)
                //account prefered contact != bup preferred contact then upate primary
                acc.rC_Bios__Preferred_Contact__c != mapOfSecondaryToPrimaryContact.get(secondaryContactId)
                )
            {
                //system.debug('out contact update::  '+ mapOfSecondaryToPrimaryContact.get(secondaryContactId) );
                secondaryContactListToUpdate.add(new Contact(id = mapOfSecondaryToPrimaryContact.get(secondaryContactId),
                                                             rC_Bios__Secondary_Contact__c = False,
                                                             rC_Bios__Preferred_Contact__c = True
                                                            ));
            }
        }
    }
    if( secondaryContactListToUpdate.size() > 0)
        update secondaryContactListToUpdate;
    */
    //END T-652003

    // createPhoneRecord
    if (mapPhoneBatches != null && mapPhoneBatches.keySet().size() > 0) {
      BatchUploadConstituentUpdater.createPhoneRecord(mapPhoneBatches, setContactIds, setPhone);
    }

    // updateEmailRecord
    if (setExistingId != null && !setExistingId.IsEmpty()) {
      BatchUploadConstituentUpdater.updateEmailRecord(setExistingId, createBatchEmail, mapBatchOpt);
    }

    // updateSoftCreditBatchUploads
    if (batchUploadMap != null && !batchUploadMap.isEmpty()) {
      batchUploadsToUpdateLst = updateSoftCreditBatchUploads(batchUploadMap, matchedGivingIds);
    }

    if( oppIdWithExternalIdMap.size() > 0 ||  sofCreditOppToUpdateOpenStageSet.size() > 0 ){
        updateOpptyExternalAndStageField( oppIdWithExternalIdMap, sofCreditOppToUpdateOpenStageSet);
    }

    //create preference Record
    if(!lstPreferenceWrapper.IsEmpty()) {
     CreatePreferences(lstPreferenceWrapper) ;
    }

    // Updates Soft credit BU Records
    if (!batchUploadsToUpdateLst.isEmpty()) {
      update batchUploadsToUpdateLst;
    }
  }

  /*
  *
  *Method onAfterInsert
  *@description : Creates ShareRecords based on Affiliation.
  */

  public static void onAfterInsert (List<rC_Connect__Batch_Upload__c> BatchUploads) {
    //Method Variables
    set<String> setPhoneBatch = new set<String>();
    list<String> listPhoneExternalId = new list<String>();
    list<rC_Connect__Batch_Upload__c> listbatchPhoneUpload = new list<rC_Connect__Batch_Upload__c>();
    map<String, rC_Connect__Batch_Upload__c> mapBatches =  new  map<String, rC_Connect__Batch_Upload__c>();
    map <Id, Id> mapBatchUploadIdToUserId = new map <Id, Id>();
    List<PreferenceWrapper> lstPreferenceWrapper = new List<PreferenceWrapper>();
    list<rC_Connect__Batch_Upload__c> listBatchUploads = new list<rC_Connect__Batch_Upload__c>();
    Map<Id, set<String>> mapOfContactIdAndSetOfEmails = new Map<Id, set<String>>();
    map<String, rC_Connect__Batch_Upload__c> mapPhoneBatches =  new  map<String, rC_Connect__Batch_Upload__c>();
    set<Id> setContactIds = new set<Id>();
    set<String> setPhone = new set<String>();
    Map<Id, rC_Connect__Batch_Upload__c> hardCreditBatchUploads =  new  Map<Id, rC_Connect__Batch_Upload__c>();

    for (rC_Connect__Batch_Upload__c btups : BatchUploads) {
      // CreateShareRecords Logic
      mapBatchUploadIdToUserId.put(btups.Id, btups.createdbyId);

      // createEmailRecord Logic
      if (btups.rC_Connect__Batch_Upload_Contact_1_Matched__c != null && btups.Cont1_Email__c != null) {
        String strContact = String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
        String externalId = strContact.Substring(0, 15) + '_' + btups.Cont1_Email__c;

        if (!mapBatches.containsKey(externalId)) {
          mapBatches.put(externalId, btups);
        } else if ((mapBatches.containsKey(externalId))
                   && (btups.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_DONATION
                       || btups.rC_Connect__Giving_Record_Type__c == ACLU_Constants.CONST_RCDTYPE_PLEDGE )
                  ) {
          mapBatches.put(externalId, btups);
        }

      }

      // createPhoneRecord
      if (btups.rC_Connect__Batch_Upload_Contact_1_Matched__c != null && btups.rC_Connect__Contact_1_Phone_1__c != null) {
        String strContact = String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
        String externalId = strContact.Substring(0, 15) + '_' + btups.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]', '');
        if (!mapPhoneBatches.containsKey(externalId)) {
          mapPhoneBatches.put(externalId, btups);
        }
        setContactIds.add(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c);
        setPhone.add(btups.rC_Connect__Contact_1_Phone_1__c);
        /*listPhoneExternalId.add(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+btups.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]',''));
        setPhoneBatch.add(String.valueOf(btups.rC_Connect__Batch_Upload_Contact_1_Matched__c).Substring(0,15)+'_'+btups.rC_Connect__Contact_1_Phone_1__c.replaceAll('[^0-9]',''));
        listbatchPhoneUpload.add(btups);*/
      }

      //Creat Preference records if the pref4 & pref5 fields are populated

      if (btups.rC_Connect__Batch_Upload_Status__c == 'Committed'
          && !String.IsBlank(btups.rC_Connect__Batch_Upload_Account_Matched__c)
          && (!String.IsBlank(btups.Preferences_5_Code_Value__c) || !String.IsBlank(btups.Preferences_4_Code_Value__c) || !String.IsBlank(btups.Preferences_1_Code_Value__c) ||
           !String.IsBlank(btups.Preferences_2_Code_Value__c) || !String.IsBlank(btups.Preferences_3_Code_Value__c))
         ) {
        List<rC_Bios__Preference__c> preferenceCodes = new List<rC_Bios__Preference__c>();

        if (!String.IsBlank(btups.Preferences_5_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_5_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_5_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '5-'+btups.Preferences_5_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_5_End_Date__c));
          
        }
        if (!String.IsBlank(btups.Preferences_4_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_4_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_4_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '4-'+btups.Preferences_4_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_4_End_Date__c));
         
        }
        //BGE-02
        if (!String.IsBlank(btups.Preferences_3_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_3_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_3_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '3-'+btups.Preferences_3_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_3_End_Date__c));
         
        }
        if (!String.IsBlank(btups.Preferences_2_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_2_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_2_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '2-'+btups.Preferences_2_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_2_End_Date__c));
         
        }
        if (!String.IsBlank(btups.Preferences_1_Code_Value__c)) {
          preferenceCodes.add(new rC_Bios__Preference__c (rC_Bios__Code_Value__c = btups.Preferences_1_Code_Value__c,
                              rC_Bios__Account__c = btups.rC_Connect__Batch_Upload_Account_Matched__c,
                              rC_Bios__Contact__c = btups.rC_Connect__Batch_Upload_Contact_1_Matched__c,
                              rC_Bios__Start_Date__c = btups.Preferences_1_Start_Date__c,
                              rC_Bios__Active__c = True,
                              rC_Bios__Status__c = 'Confirmed',
                              Bup_Sequence__c = '1-'+btups.Preferences_1_Code_Value__c+btups.rC_Connect__Batch_Upload_Account_Matched__c+btups.id,
                              rC_Bios__End_Date__c = btups.Preferences_1_End_Date__c));
         
        }//End BGE-02
        
         lstPreferenceWrapper.add(new PreferenceWrapper(preferenceCodes,btups.id,btups.rC_Connect__Batch_Upload_Account_Matched__c));
      }

      //I-273420
      /*if(btups.Payment_Method__c != null) {
          listBatchUploads.add(btups);
      }*/

      // Clones Hard Credit Batch Upload Records
      if (btups.Has_Soft_Credit__c
          && (btups.Batch_Upload_Reference_ID__c == '' || btups.Batch_Upload_Reference_ID__c == null)
          && btups.TPA_Bypass__c == FALSE ) {
        hardCreditBatchUploads.put(btups.Id, btups);
      }

    }

    // createPhoneRecord
    if (mapPhoneBatches != null && mapPhoneBatches.keySet().size() > 0) {
      BatchUploadConstituentUpdater.createPhoneRecord(mapPhoneBatches, setContactIds, setPhone);
    }

    // createEmailRecord
    if (mapBatches != null && mapBatches.size() > 0) {
      BatchUploadConstituentUpdater.createEmailRecord(mapBatches);
    }

    // CreateShare Records
    if (!mapBatchUploadIdToUserId.keyset().IsEmpty() && Utilities.CanUseFutureContext()) {
      try {
        createShareRecords(mapBatchUploadIdToUserId);
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'onAfterInsert', e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }

    /*if(!listBatchUploads.isEmpty()) {
        populateOppDepositSiteAndPaymentMerchant(listBatchUploads);
    }*/

    if (hardCreditBatchUploads != null && hardCreditBatchUploads.size() > 0) {
      cloneBatchUploadHardCredits(hardCreditBatchUploads);
    }

    //create preference Record
    if(!lstPreferenceWrapper.IsEmpty()) {
     CreatePreferences(lstPreferenceWrapper) ;
    }
  }

/*
  *
  *Method updateHasErrorsCheckbox
  *@description : Update Has Errors Checvkbox on Batch Logs
  */
  private static void updateHasErrorsCheckbox(Set<Id> batchLogIds,Set<id> committedBatchIds) {
    List<Batch_Log__c> logLst = new List<Batch_Log__c>();

    for (Batch_Log__c objLog : [SELECT Id, Has_Errors__c FROM Batch_Log__c WHERE Id IN: batchLogIds OR Id IN: committedBatchIds]) {
      if (batchLogIds.contains(objLog.Id) && !objLog.Has_Errors__c) {
        objLog.Has_Errors__c = true;
        logLst.add(objLog);
      }else if(committedBatchIds.contains(objLog.id) && objLog.Has_Errors__c) {
        objLog.Has_Errors__c = false;
        logLst.add(objLog);
      }
    }

    if (logLst.size() > 0) {
      update logLst;
    }
  }

  /*
  *
  *Method updateSoftCreditBatchUploads
  *@description : Update Soft Credit Batch Upload Records.
  */
  private static List<rC_Connect__Batch_Upload__c> updateSoftCreditBatchUploads(Map <String,
      rC_Connect__Batch_Upload__c> batchUploadMap,
      Set<Id> matchedGivingIds) {
    List<rC_Connect__Batch_Upload__c> softCreditBatchUploadLst = new List<rC_Connect__Batch_Upload__c>();
    Map<Id, Id> opptyIdMap = new Map<Id, Id>();

    if (!matchedGivingIds.isEmpty()) {
      for (Opportunity objOppty : [SELECT Id, rC_Giving__Parent__c FROM Opportunity
                                   WHERE rC_Giving__Parent__c IN: matchedGivingIds
                                   AND RecordType.DeveloperName = : ACLU_Constants.CONST_RCDTYPE_TRANSACTION
                                       ORDER BY CloseDate
                                       DESC]) {
        if (!opptyIdMap.containsKey(objOppty.rC_Giving__Parent__c)) {
          opptyIdMap.put(objOppty.rC_Giving__Parent__c, objOppty.Id);
        }
      }
    }

    if (batchUploadMap != null && !batchUploadMap.isEmpty()) {
      for (rC_Connect__Batch_Upload__c softCreditBU : [SELECT Id, rC_Connect__Batch_Upload_Parent_Giving_Matched__c,
           Related_Transaction__c
           FROM rC_Connect__Batch_Upload__c
           WHERE Id IN: batchUploadMap.keySet()]) {
        softCreditBU.rC_Connect__Batch_Upload_Parent_Giving_Matched__c =
          batchUploadMap.get(softCreditBU.Id).rC_Connect__Batch_Upload_Giving_Matched__c;
        if (opptyIdMap.containsKey(batchUploadMap.get(softCreditBU.Id).rC_Connect__Batch_Upload_Giving_Matched__c)) {
          softCreditBU.Related_Transaction__c =
            String.ValueOf(opptyIdMap.get(batchUploadMap.get(softCreditBU.Id).rC_Connect__Batch_Upload_Giving_Matched__c)).substring(0, 15);
        }
        softCreditBU.rC_Connect__Batch_Upload_Status__c = 'New';
        softCreditBatchUploadLst.add(softCreditBU);
      }
    }

    return softCreditBatchUploadLst;
  }

  /*
  *
  *Method cloneBatchUploadHardCredits
  *@description : Clones Hard Credit Batch Upload Records
  */
  private static void cloneBatchUploadHardCredits(Map <Id, rC_Connect__Batch_Upload__c> mapBatchUploadIdToUserId) {
    Map<Id, rC_Connect__Batch_Upload__c> clonedBUMap = new Map<Id, rC_Connect__Batch_Upload__c>();
    rC_Connect__Batch_Upload__c clonedBU;
    List<rC_Connect__Batch_Upload__c> updateBULst = new List<rC_Connect__Batch_Upload__c>();

    for (rC_Connect__Batch_Upload__c objBU : mapBatchUploadIdToUserId.values()) {
      clonedBU = objBU.clone(false, true, false, false);
      clonedBU.Has_Soft_Credit__c = false;
      clonedBU.isSoft_Credit__c = true;
      clonedBU.Soft_Credit_Type__c = ACLU_Constants.CONST_SCTYPE_GIFT_MEMBERSHIP;
      clonedBU.rC_Connect__Contact_1_First_Name__c = objBU.rC_Connect__Recipient_First_Name__c;
      clonedBU.rC_Connect__Contact_1_Last_Name__c = objBU.rC_Connect__Recipient_Last_Name__c;
      clonedBU.rC_Connect__Address_Street_Line_1__c = objBU.rC_Connect__Recipient_Street_Line_1__c;
      clonedBU.rC_Connect__Address_Street_Line_2__c = objBU.rC_Connect__Recipient_Street_Line_2__c;
      clonedBU.rC_Connect__Address_City__c = objBU.rC_Connect__Recipient_City__c;
      clonedBU.rC_Connect__Address_State__c = objBU.rC_Connect__Recipient_State_Province__c;
      clonedBU.rC_Connect__Address_Postal_Code__c = objBU.rC_Connect__Recipient_Postal_Code__c;
      clonedBU.rC_Connect__Address_Country__c = objBU.rC_Connect__Recipient_Country__c;
      clonedBU.Cont1_Email__c = objBU.rC_Connect__Recipient_Email__c;
      clonedBU.Cont1_EmailType__c = 'Home';
      clonedBU.Cont1_OptIn__c = false;
      clonedBU.rC_Connect__Batch_Upload_Status__c = 'New Springboard';
      clonedBU.rC_Connect__Batch_Upload_Account_Matched__c = null;
      clonedBU.rC_Connect__Batch_Upload_Contact_1_Matched__c = null;
      clonedBU.rC_Connect__Batch_Upload_Contact_2_Matched__c = null;
      clonedBU.rC_Connect__Batch_Upload_Giving_Matched__c = null;
      clonedBU.rC_Connect__Batch_Upload_Address_Matched__c = null;
      clonedBU.rC_Connect__Batch_Upload_Payment_Method_Matched__c = null;
      clonedBU.rC_Connect__Payment_Method_Payment_Type__c = null;
      clonedBU.rC_Connect__Payment_Method_Card_Issuer__c = null;
      clonedBU.rC_Connect__Payment_Method_Card_Last_Four_Digits__c = null;
      clonedBU.rC_Connect__Payment_Method_Card_Expiration_Year__c = null;
      clonedBU.rC_Connect__Payment_Method_Card_GUID__c = null;
      if (objBU.SB_Donation_Id__c != null) {
        // Modified by : roundCorner Inc. 29/11/2018 :: Removed SB donation Id as it was causing problem while matching
        clonedBU.SB_Donation_Id__c = '';//'SC' + objBU.SB_Donation_Id__c;
      }
      
      if (objBU.SB_User_Id__c != null) {
        // Modified by : roundCorner Inc. 29/11/2018 :: Removed SB User Id as it was causing problem while matching
        clonedBU.SB_User_Id__c = '';
      }
      clonedBU.rC_Connect__Payment_Method_Card_Expiration_Month__c = null;
      clonedBU.rC_Connect__Giving_Paid__c = false;
      clonedBUMap.put(objBU.Id, clonedBU);
    }

    if (clonedBUMap != null && clonedBUMap.size() > 0) {

      try {
        insert clonedBUMap.values();
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'onAfterInsert',
                                                      'cloneBatchUploadHardCredits Insert Failed::  '+ e.getMessage());
        log.logException(e);
        log.saveLogs();
      }

      for (rC_Connect__Batch_Upload__c objBU : [SELECT Id, Batch_Upload_Reference_ID__c
           FROM rC_Connect__Batch_Upload__c
           WHERE Id IN: mapBatchUploadIdToUserId.keyset()]) {
        objBU.Batch_Upload_Reference_ID__c = clonedBUMap.get(objBU.Id).Id;
        updateBULst.add(objBU);
      }

      if (updateBULst.size() > 0) {
        try {
          update updateBULst;
        } catch (Exception e) {
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'onAfterInsert',
                                                        'cloneBatchUploadHardCredits Update Failed:: '+ e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
      }
    }
  }

  /*
  *
  *Method createShareRecords
  *@description : Creates ShareRecords based on createdByUser present in the groups.
  */
  //@future
  public static void createShareRecords (map <Id, Id> mapBatchUploadIdToUserId) {
    Set<Id> userIds = new Set<Id>();
    List<rC_Connect__Batch_Upload__share> BatchUploadSharesToBeInsert = new List<rC_Connect__Batch_Upload__share>();
    map<Id, Set<Id>> mapUserIdToGroupId = new map<Id, Set<Id>>();

    // All Aclu groupId
    Id allACLUgroupId = [SELECT id FROM group WHERE developerName = 'All_ACLU' Limit 1].Id;
    // Collecting the createdByUserIds
    for (Id objId : mapBatchUploadIdToUserId.Values()) {
      userIds.add(objId);
    }

    // collect the GroupIds for a user
    for (groupmember obj : [SELECT GroupId, UserOrGroupId FROM groupmember WHERE UserOrGroupId = :userIds]) {
      if (!mapUserIdToGroupId.containsKey(obj.UserOrGroupId)) {
        mapUserIdToGroupId.put(obj.UserOrGroupId, new Set<Id> {obj.GroupId});
      } else {
        mapUserIdToGroupId.get(obj.UserOrGroupId).add(obj.GroupId);
      }
    }
    // create Share records for the batchUpload to all the groups where the createduser is part of it.
    for (Id objBUId : mapBatchUploadIdToUserId.KeySet()) {
      if (mapUserIdToGroupId.get(mapBatchUploadIdToUserId.get(objBuId)) != null) {
        for (Id objGroupId : mapUserIdToGroupId.get(mapBatchUploadIdToUserId.get(objBuId))) {
          // not sharing with the All_ACLU group as all the Affiliate users will be under it.
          if (objGroupId != allACLUgroupId) {
            rC_Connect__Batch_Upload__share bUShare = new rC_Connect__Batch_Upload__share();
            bUShare.AccessLevel = 'Edit';
            // assigns the groupId from BatchUpload Id via using the two maps we created above.
            bUShare.UserOrGroupId = objGroupId;
            bUShare.ParentId = objBUId;
            BatchUploadSharesToBeInsert.add(bUShare);
          }
        }
      }
    }
    // Insert batchUploadShare records.
    if (!BatchUploadSharesToBeInsert.IsEmpty()) {
      try {
        insert BatchUploadSharesToBeInsert;
      } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'createShareRecords', e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }

  }

  private static void autoPopulateCityAndState(List<rC_Connect__Batch_Upload__c> listOfAddressesToProcess) {
    Set<String> setOfZipCodes = new Set<String>();
    map<String, String> mapOfZipAndCityStateKey = new map<String, String>();
    for (rC_Connect__Batch_Upload__c address : listOfAddressesToProcess) {
      if (address.rC_Connect__Address_Postal_Code__c != null && (address.rC_Connect__Address_Postal_Code__c.length() >= 5)) {
        setOfZipCodes.add(address.rC_Connect__Address_Postal_Code__c.subString(0, 5));
      }
    }
    String key = '';
    String city = '';
    String state = '';
    for (Zip_Affiliate__c zipAffiliate : [SELECT Id, Name, City__c, State__c
                                          FROM Zip_Affiliate__c
                                          WHERE Name IN : setOfZipCodes
                                          AND (City__c != NULL OR State__c != NULL)]) {
      key = zipAffiliate.City__c != null ? key + zipAffiliate.City__c + '-' : key + '-';
      key = zipAffiliate.State__c != null ? key + zipAffiliate.State__c : key;
      mapOfZipAndCityStateKey.put(zipAffiliate.Name, key);
      key = '';
    }
    for (rC_Connect__Batch_Upload__c address : listOfAddressesToProcess) {
      if (mapOfZipAndCityStateKey.get(address.rC_Connect__Address_Postal_Code__c) != null) {
        city = mapOfZipAndCityStateKey.get(address.rC_Connect__Address_Postal_Code__c).startsWith('-')
               ? '' : (mapOfZipAndCityStateKey.get(address.rC_Connect__Address_Postal_Code__c)).split('-').get(0);
        state = mapOfZipAndCityStateKey.get(address.rC_Connect__Address_Postal_Code__c).endsWith('-')
                ? '' : (mapOfZipAndCityStateKey.get(address.rC_Connect__Address_Postal_Code__c)).split('-').get(1);
        address.rC_Connect__Address_City__c = city != '' ? city : address.rC_Connect__Address_City__c;
        address.rC_Connect__Address_State__c = state != '' ? state : address.rC_Connect__Address_State__c;
        city = '';
        state = '';
      }
    }
  }

  /***********************************************************
  *Funtion: resolveDuplicatePaymentMethod
  *Created By : Bhavesh
  *Date: 01/11/2017
  *Description: T-641622- Return first created PaymentMethodType ID and set other payment method as inactive and duplicate.
  ************************************************************/
  private static void resolveDuplicatePaymentMethod(Map<id, Set<Id>> accIdWithBUIdSetMap,
      Map<String, Set<Id>> PaymentMethodWithBUIdSetMap,
      Map<id, rC_Connect__Batch_Upload__c> newMap,
      Set<Id> buRecordIdsToUpdatePaymentMethod,
      Set<String> duplicatePaymentMethodIdSet ) {
    //System.assert(false, accIdWithBUIdSetMap + '==' + PaymentMethodWithBUIdSetMap + '==' + buRecordIdsToUpdatePaymentMethod);
    Set<String> alreadyProcessedBURecords = new Set<String>();//String in form - (matchedAccountId + paymentMethod)
    List<RC_Giving__Payment_Method__c> updatePaymentMethodToDuplicateAndInactive = new List< RC_Giving__Payment_Method__c> ();

    //Modified by rC : 08-22-2018
    //ZD#57473ABUP-1 :: Retrieved duplicate payment method ids and used to query the same
    //Also, getting payment methods which are latest and marking older to inactive
    for ( RC_Giving__Payment_Method__c pm : [
        SELECT id
             , rC_Giving__Account__c
             , rC_Giving__Payment_Type__c
             , Duplicate_Payment_Method__c
          FROM rC_Giving__Payment_Method__c
         WHERE rC_Giving__Is_Active__c = TRUE
           AND rC_Giving__Account__c in: accIdWithBUIdSetMap.keySet()
           AND Id IN :duplicatePaymentMethodIdSet
      ORDER BY CreatedDate DESC]) {

      //check if pm record is first, if first then it will not be available in alreadyProcessedBURecords.
      if ( !alreadyProcessedBURecords.contains( pm.rC_Giving__Account__c + '' + pm.rC_Giving__Payment_Type__c )) {
        Set<Id> bUIdSetFromAcc = accIdWithBUIdSetMap.get( pm.rC_Giving__Account__c );//BU ids associated with matched accounts.
        Set<Id> bUIdSetFromPaymentMethod = PaymentMethodWithBUIdSetMap.get( pm.rC_Giving__Payment_Type__c );//BU ids associated with Payment Methods.
        //System.assert(False, bUIdSetFromAcc + '==' + bUIdSetFromPaymentMethod);
        for ( Id buId : bUIdSetFromAcc ) {
          if (bUIdSetFromPaymentMethod.contains( buId ) && buRecordIdsToUpdatePaymentMethod.contains( buId )) {
            rC_Connect__Batch_Upload__c buRecord = newMap.get(buID);
            buRecord.rC_Connect__Batch_Upload_Payment_Method_Matched__c = pm.id;
            buRecord.rC_Connect__Batch_Upload_Status__c = 'Ready';
            buRecord.rC_Connect__Batch_Upload_Flagged_Technical_Reason__c = null;
            buRecord.rC_Connect__Batch_Upload_Flagged_Reason__c = null;
            buRecordIdsToUpdatePaymentMethod.remove(buId);
            //newMap.put(buRecord.id, buRecord);
          }
          alreadyProcessedBURecords.add( pm.rC_Giving__Account__c + '' + pm.rC_Giving__Payment_Type__c );
        }
      } else {
        //other payment methods records to udpate inactive and duplicate.
        pm.rC_Giving__Is_Active__c = false;
        pm.Duplicate_Payment_Method__c = true;
        updatePaymentMethodToDuplicateAndInactive.add(pm);
        pm.rC_Giving__Is_Default__c = false;
      }
    }
    if ( updatePaymentMethodToDuplicateAndInactive.size() > 0 ) {
      update updatePaymentMethodToDuplicateAndInactive;
    }
  }
  /***********************END*****T-641622***********/
  /**************************************************
  * Method: updateCountryCode
  * Desc: update countrycode value from countryname.
  * Created By: Bhavesh
  * Task: T-647439
  ***************************************************/

  private static void updateCountryCode( List<rC_Connect__Batch_Upload__c> newList, Set<String> countryNameSet ) {
    Map<String, Country_Codes__c> countryToCountryCodeMap = new Map<String, Country_Codes__c>();
    Map<String, Country_Codes__c> threeCharCountryCodeToAddressMap = new Map<String, Country_Codes__c>();
    List<rC_Connect__Batch_Upload__c> buListToUpdate = new List<rC_Connect__Batch_Upload__c>();
    String countryCode;
    countryToCountryCodeMap = ConvertCountryNames.returnCountryCodeFromCountryName(countryNameSet);
    for (String cc : countryToCountryCodeMap.keySet()) {
      threeCharCountryCodeToAddressMap.put(countryToCountryCodeMap.get(cc).Country_3_Char_Code__c , countryToCountryCodeMap.get(cc));
    }
    for ( rC_Connect__Batch_Upload__c bu : newList ) {
      if (bu.rC_Connect__Address_Country__c != null
          && (bu.rC_Connect__Address_Country__c.length() > 2 || bu.rC_Connect__Address_Country__c == 'US')) {
        if ( countryToCountryCodeMap.containsKey(bu.rC_Connect__Address_Country__c) ) {
          bu.rC_Connect__Address_Country__c = countryToCountryCodeMap.get(bu.rC_Connect__Address_Country__c).Country_Code__c;
          bu.Country_Full_Name__c = countryToCountryCodeMap.get(bu.rC_Connect__Address_Country__c).Name;
        } else if ( threeCharCountryCodeToAddressMap.containsKey(bu.rC_Connect__Address_Country__c) ) {
          countryCode = bu.rC_Connect__Address_Country__c;
          bu.rC_Connect__Address_Country__c = threeCharCountryCodeToAddressMap.get(countryCode).Country_Code__c;
          bu.Country_Full_Name__c = threeCharCountryCodeToAddressMap.get(countryCode).Name;
        }
        buListToUpdate.add(bu);
      }
    }
  }
  /***********************END*****T-647439***********/

  /**************************************************
  * Method: updatePreferredBillingAndShipping
  * Desc: update countrycode value from countryname.
  * Created By: Bhavesh
  * Task: T-647918
  * Update: updated by Bhavesh, I-304185, calling from before insert and for before insert do not check for status in if condition.
  ***************************************************/
  private static void updatePreferredBillingAndShipping(List<rC_Connect__Batch_Upload__c> newList,
                                                        Map<Id, rC_Connect__Batch_Upload__c> oldMap ) {
    Set<Id> accountIdSet = new Set<Id>();
    Map<id, Account> accountDetailMap;
    Account acct;
    for (rC_Connect__Batch_Upload__c bu : newList) {
      if ( oldMap == NULL || (bu.rC_Connect__Batch_Upload_Status__c != oldMap.get(bu.id).rC_Connect__Batch_Upload_Status__c
          && (bu.rC_Connect__Batch_Upload_Status__c == 'FromRDNew'
              || bu.rC_Connect__Batch_Upload_Status__c ==  'FromRDReady') )
         ) {
        if ( bu.rC_Connect__Batch_Upload_Account_Matched__c == null
             || (bu.rC_Connect__Address_Preferred_Billing__c == True
                 && bu.rC_Connect__Address_Preferred_Shipping__c == True)
           ) {
          if ( bu.rC_Connect__Batch_Upload_Status__c == 'FromRDNew' ) {
            bu.rC_Connect__Batch_Upload_Status__c = 'New';
          } else if ( bu.rC_Connect__Batch_Upload_Status__c ==  'FromRDReady' ) {
            bu.rC_Connect__Batch_Upload_Status__c = 'Ready';
          }
        } else {
          accountIdSet.add(bu.rC_Connect__Batch_Upload_Account_Matched__c);
        }
      }
    }

    if ( accountIdSet.size() > 0 ) {

      accountDetailMap = new Map<Id, Account>([Select id, BillingStreet,
                                              BillingCity, BillingPostalCode, ShippingStreet, ShippingCity, ShippingPostalCode
                                              FROM Account where ID in: accountIdSet]);
        for ( rC_Connect__Batch_Upload__c bu : newList ) {
            if ( bu.rC_Connect__Batch_Upload_Account_Matched__c != null
                 && accountDetailMap.containsKey(bu.rC_Connect__Batch_Upload_Account_Matched__c)) {
                    acct = accountDetailMap.get(bu.rC_Connect__Batch_Upload_Account_Matched__c); 
                    String accountBillingAddress = Acct.BillingStreet + Acct.BillingCity + Acct.BillingPostalCode;
                    accountBillingAddress = accountBillingAddress.replaceAll( '\\s+', '');
                    // Zendesk : #68427: Preferred Billing being set as False
                    setPrefferedBillingShippingFlags(accountBillingAddress,bu,'rC_Connect__Address_Preferred_Billing__c');
                    // Zendesk : END #68427: Preferred Billing being set as False
                    String accountShippingAddress = Acct.ShippingStreet + Acct.ShippingCity + Acct.ShippingPostalCode;
                    accountShippingAddress = accountShippingAddress.replaceAll( '\\s+', '');
                    // Zendesk : #68427: Preferred Shipping being set as False
                    setPrefferedBillingShippingFlags(accountShippingAddress,bu,'rC_Connect__Address_Preferred_Shipping__c');
                    // Zendesk : END #68427: Preferred Shipping being set as False
                    if ( bu.rC_Connect__Batch_Upload_Status__c.equalsIgnoreCase('FromRDNew' )) {
                        bu.rC_Connect__Batch_Upload_Status__c = 'New';
                    } else if ( bu.rC_Connect__Batch_Upload_Status__c.equalsIgnoreCase('FromRDReady' )) {
                        bu.rC_Connect__Batch_Upload_Status__c = 'Ready';
                    }
                }

        }
    }
  }
  /***********************END*****T-647918***********/



  public static void updateOpptyExternalAndStageField( Map<Id, String> oppIdWithExternalIdMap, Set<Id> sofCreditOppToUpdateOpenStageSet ){
      Id softCreditOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
      Id transactionRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
      List<Opportunity> opptyToUpdate = new List<Opportunity>();
      for( Opportunity oppty : [Select id, StageName, rC_Giving__Parent__c, External_ID__c FROM Opportunity
                                WHERE (rC_Giving__Parent__c IN: oppIdWithExternalIdMap.keySet() AND RecordTypeId =: transactionRecordTypeId )
                                    OR (id In:sofCreditOppToUpdateOpenStageSet AND recordTypeId =: softCreditOppRecordTypeId) ])
      {
          if(sofCreditOppToUpdateOpenStageSet.contains( oppty.id ) && oppty.stageName != 'Open'){
                oppty.stageName = 'Open';
                opptyToUpdate.add( oppty );
          } else {
              if( oppIdWithExternalIdMap.containsKey(oppty.rC_Giving__Parent__c) && oppty.External_ID__c != oppIdWithExternalIdMap.get(oppty.rC_Giving__Parent__c)){
                  oppty.External_ID__c = oppIdWithExternalIdMap.get(oppty.rC_Giving__Parent__c);
                  opptyToUpdate.add( oppty );
              }
          }

      }
      if( opptyToUpdate.size() > 0 )
        update opptyToUpdate;
  }
  
    // Zendesk : #68427: Preferred Billing being set as False
    public static void setPrefferedBillingShippingFlags(String accountShippingAddress,rC_Connect__Batch_Upload__c bu,String fieldName){
        String buAddress = (bu.rC_Connect__Address_Street_Line_1__c != NULl ? bu.rC_Connect__Address_Street_Line_1__c: '')//updated for I-304189, by Bhavesh
            + (bu.rC_Connect__Address_Street_Line_2__c != NULl ? bu.rC_Connect__Address_Street_Line_2__c: '')//updated for I-304189, by Bhavesh
            + bu.rC_Connect__Address_City__c
            + bu.rC_Connect__Address_Postal_Code__c;
        buAddress = buAddress.replaceAll( '\\s+', '');
        System.debug(buAddress);
        System.debug(accountShippingAddress);
        if (!Boolean.valueOf(bu.get(fieldName))
         && bu.rC_Connect__Giving_Giving_Amount__c != null 
         && (bu.rC_Connect__Batch_Upload_Address_Matched__c == null
          || buAddress.equalsIgnoreCase(accountShippingAddress) )) {
            bu.put(fieldName,true) ;
        }else if(Boolean.ValueOf(bu.get(fieldName))
         && bu.rC_Connect__Giving_Giving_Amount__c == null 
         && bu.rC_Connect__Batch_Upload_Address_Matched__c == null) {
            bu.put(fieldName,false) ;
        }else if(bu.rC_Connect__Giving_Giving_Amount__c == null
         && bu.rC_Connect__Batch_Upload_Address_Matched__c != null) {
             if(buAddress.equalsIgnoreCase(accountShippingAddress)) {
                bu.put(fieldName,true) ; 
             }else {
                 bu.put(fieldName,false) ;
             }
         }
    }
  
 /* Traction(Mounica V),January 31,2020 : BGE-02, Method to eliminate the insertion of duplictae preference on the Account */
 Public static List<PreferenceInsertWrapper> checkForDuplicate(list<PreferenceWrapper> WrapPreferences){
      
  Set<id> setAccountId = new Set<id>();
  Set<id> setBupIds = new Set<id>();
  List<PreferenceInsertWrapper> lstInsertPreferenceWrapper = new List<PreferenceInsertWrapper>();
  Map<id,List<rC_Bios__Preference__c>> mapAccPreference = new Map<id,List<rC_Bios__Preference__c>>();
  Map<string,String> MapFields = new Map<string,String>();
  List<String> lstAccCode = new List<String>();
  
  MapFields.put('1','Preferences_1_Status__c');
  MapFields.put('2','Preferences_2_Status__c');
  MapFields.put('3','Preferences_3_Status__c');
  MapFields.put('4','Preferences_4_Status__c');
  MapFields.put('5','Preferences_5_Status__c');
  
  for(PreferenceWrapper oWrap: WrapPreferences){
    setAccountId.add(oWrap.sAccountID) ; 
    setBupIds.add(oWrap.oBatchUploadId);
  }
  try{
  List<rC_Bios__Preference__c> lstAccPreference = [SELECT Id,rC_Bios__Active__c,rC_Bios__End_Date__c,rC_Bios__Contact__c,rC_Bios__Code_Value__c,rC_Bios__Account__c from rC_Bios__Preference__c
                                                          where rC_Bios__Account__c IN: setAccountId];
  Map<id,rC_Connect__Batch_Upload__c> mapBUPS = new Map<id,rC_Connect__Batch_Upload__c>([SELECT Id,Preferences_1_Code_Value__c,Preferences_2_Code_Value__c,Preferences_3_Code_Value__c,Preferences_4_Code_Value__c,Preferences_5_Code_Value__c,
                                                                                        Preferences_1_Status__c,Preferences_2_Status__c,Preferences_3_Status__c,Preferences_4_Status__c,Preferences_5_Status__c,rC_Connect__Batch_Upload_Account_Matched__c 
                                                                                        from rC_Connect__Batch_Upload__c where Id IN: setBupIds]);    
                                                          
  for(rC_Bios__Preference__c opre: lstAccPreference){
      
   if(mapAccPreference.containsKey(opre.rC_Bios__Account__c))
     {   
     mapAccPreference.get(opre.rC_Bios__Account__c).add(opre);
      }
    else 
     {   
     mapAccPreference.put(opre.rC_Bios__Account__c,new list<rC_Bios__Preference__c>{opre}); 
      }   
      
  }                                                        
                                                          
   for(PreferenceWrapper oWrap : WrapPreferences){
       
      Set<rC_Bios__Preference__c> setPreferences = new Set<rC_Bios__Preference__c>(); 
      List<rC_Bios__Preference__c> lstPreToInsert = new List<rC_Bios__Preference__c>();
      
      setPreferences.addALL(oWrap.oPreference);
      rC_Connect__Batch_Upload__c oBatch = mapBUPS.get(oWrap.oBatchUploadId);
      
        for(rC_Bios__Preference__c oPre: setPreferences) {
            
         String sAccCode = '';
         if(oPre.rC_Bios__End_Date__c == null) 
         sAccCode = oPre.rC_Bios__Code_Value__c+oPre.rC_Bios__Account__c+oPre.rC_Bios__Contact__c;
         if(sAccCode <> '' && !lstAccCode.contains(sAccCode))
         lstAccCode.add(sAccCode);
         else if(sAccCode <> '' && lstAccCode.contains(sAccCode)){
         setPreferences.remove(oPre);      
         oBatch.put(MapFields.get(oPre.Bup_Sequence__c.substringBefore('-')),'Duplicate on processing BUP list Identified - Preference not Inserted');  
         continue;
         }
         
         
         oBatch.put(MapFields.get(oPre.Bup_Sequence__c.substringBefore('-')),'Inserted');
         
         if(!mapAccPreference.isEmpty() && mapAccPreference.containskey(oPre.rC_Bios__Account__c)){
           for(rC_Bios__Preference__c oAcc : mapAccPreference.get(oPre.rC_Bios__Account__c)){

              if(oAcc.rC_Bios__Code_Value__c == oPre.rC_Bios__Code_Value__c){
                 
                if((oAcc.rC_Bios__Contact__c <> null && oPre.rC_Bios__Contact__c <> null && oAcc.rC_Bios__Contact__c == oPre.rC_Bios__Contact__c) || oPre.rC_Bios__Contact__c == null) { 
             
                if(oPre.rC_Bios__Active__c == True && oAcc.rC_Bios__Active__c == True && oPre.rC_Bios__End_Date__c == null && oAcc.rC_Bios__End_Date__c == null) {
                   setPreferences.remove(oPre);
                   oBatch.put(MapFields.get(oPre.Bup_Sequence__c.substringBefore('-')),'Duplicate On Account Identified - Preference not Inserted');
                   }
                  }
                 }
                } 
              }
           }
        if(!setPreferences.isempty())
          lstPreToInsert.AddALL(setPreferences);
          lstInsertPreferenceWrapper.add( New PreferenceInsertWrapper(lstPreToInsert,oBatch));
     }
     return lstInsertPreferenceWrapper;
   }catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'onAfterInsert',
                                                              'PreferenceCodeRecords Insert Failed:: '+ e.getMessage());
        log.logException(e);
        log.saveLogs();
        return null;
      }
  }
  
  public class PreferenceWrapper {
    public List<rC_Bios__Preference__c> oPreference;
    public id oBatchUploadId;
    public String  sAccountID;
    
    public PreferenceWrapper(List<rC_Bios__Preference__c> oPreference, Id oBatchUploadId,String sAccountID) {
      this.oPreference = oPreference;
      this.oBatchUploadId = oBatchUploadId;
      this.sAccountID = sAccountID;
     
    }
  }
  
  public class PreferenceInsertWrapper {
    public List<rC_Bios__Preference__c> lstPreference;
    public rC_Connect__Batch_Upload__c oBup;

    public PreferenceInsertWrapper(List<rC_Bios__Preference__c> lstPreference, rC_Connect__Batch_Upload__c oBup) {
      this.lstPreference = lstPreference;
      this.oBup = oBup;
    }
  }
  // Method to create preferences
  Public static void CreatePreferences(List<PreferenceWrapper> lstPreferenceWrapper){
  try{    
  List<PreferenceInsertWrapper> lstPreWrapper = checkForDuplicate(lstPreferenceWrapper) ; 
     List<rC_Bios__Preference__c> lstPrefCodes = new list<rC_Bios__Preference__c>();
     List<rC_Connect__Batch_Upload__c> lstBUPS = new list<rC_Connect__Batch_Upload__c>();
     Map<rC_Bios__Preference__c,String> MapSuccessIds = new Map<rC_Bios__Preference__c,String>(); 
     Boolean bError = false;
     for(PreferenceInsertWrapper owrap : lstPreWrapper)
     {
     lstPrefCodes.AddALL(owrap.lstPreference); 
     lstBUPS.Add(owrap.oBup);
     }  
      if(!lstPrefCodes.IsEmpty()){
      Map<String,Database.SaveResult> saveResultByField = new Map<String,Database.SaveResult>();    
     
      Database.SaveResult[] srList = Database.insert(lstPrefCodes, false);
     
        for(Integer i=0;i<srList.size();i++){
                    if (!srList[i].isSuccess()){
                        Database.Error error = srList.get(i).getErrors().get(0);
                        String failedDML = 'Reason : '+error.getStatusCode()+' - Error Message: '  +error.getMessage();
                        bError = True;
                        MapSuccessIds.put(lstPrefCodes[i],failedDML);
                    }
                }
       if(bError == True && MapSuccessIds.size() > 0){
        
       for(rC_Connect__Batch_Upload__c oBup : lstBUPS)    
        {
        String sPreference1 = oBup.Preferences_1_Code_Value__c <> null ? '1-'+oBup.Preferences_1_Code_Value__c+oBup.rC_Connect__Batch_Upload_Account_Matched__c+oBup.id : '';
        String sPreference2 = oBup.Preferences_2_Code_Value__c <> null ? '2-'+oBup.Preferences_2_Code_Value__c+oBup.rC_Connect__Batch_Upload_Account_Matched__c+oBup.id : '';
        String sPreference3 = oBup.Preferences_3_Code_Value__c <> null ? '3-'+oBup.Preferences_3_Code_Value__c+oBup.rC_Connect__Batch_Upload_Account_Matched__c+oBup.id : '';
        String sPreference4 = oBup.Preferences_4_Code_Value__c <> null ? '4-'+oBup.Preferences_4_Code_Value__c+oBup.rC_Connect__Batch_Upload_Account_Matched__c+oBup.id : '';
        String sPreference5 = oBup.Preferences_5_Code_Value__c <> null ? '5-'+oBup.Preferences_5_Code_Value__c+oBup.rC_Connect__Batch_Upload_Account_Matched__c+oBup.id : '';
         
         for(rC_Bios__Preference__c opre : MapSuccessIds.Keyset()){ 
            
            if(sPreference1 <> null && opre.Bup_Sequence__c == sPreference1){ 
            oBup.Preferences_1_Status__c = 'Failed to Insert - '+MapSuccessIds.get(opre);
            }
            if(sPreference2 <> null && opre.Bup_Sequence__c == sPreference2){
             oBup.Preferences_2_Status__c = 'Failed to Insert - '+MapSuccessIds.get(opre);
            }
           if(sPreference3 <> null && opre.Bup_Sequence__c == sPreference3){
             oBup.Preferences_3_Status__c = 'Failed to Insert - '+MapSuccessIds.get(opre);
            }
           if(sPreference4 <> null && opre.Bup_Sequence__c == sPreference4){
             oBup.Preferences_4_Status__c = 'Failed to Insert - '+MapSuccessIds.get(opre);
            }
           if(sPreference5 <> null && opre.Bup_Sequence__c == sPreference5){
             oBup.Preferences_5_Status__c = 'Failed to Insert - '+MapSuccessIds.get(opre);
            }
         }   
        }
       bError = False;
      }         
                   
      }

      if((!bError && !lstBUPS.isempty()) || (lstPrefCodes.IsEmpty() && !lstBUPS.isempty() ))  
      Database.SaveResult[] lstBupUpdate = Database.Update(lstBUPS, false); 
    } catch (Exception e) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUploadHandler', 'onAfterInsert',
                                                              'PreferenceCodeRecords Insert Failed:: '+ e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
  }// BGE-02 END
}