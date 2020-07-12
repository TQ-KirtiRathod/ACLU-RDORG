/*
*
*Name : BatchLogDetailPageController
*Author: Appirio India (Harshita Khandelwal)
*Date : February 08, 2017
*Purpose : BatchLogDetailPageController is the Controller Class for BatchLogDetailPage, also called BGE.
           Class contains the logic for the Gift entry, splits, adjustments, and soft credits.
           Release code runs in sync or async mode depending on the count of gifts attached.
           See supplemental documentation for info on each method contained in the class."
*Change Log: Traction(Mounica V), November 25,2019-Ticket:BGE-71 : Included validations for sharing code and sharing entity in opportunityIsValid method.
             Traction(Mounica V), November 28,2019-Ticket:BGE-63 : Assigned values to giving fields in updateParent method.
             Traction(Mounica V), November 28,2019-Ticket:BGE-63 : Assigned values to giving fields (that are getting wiped off) in updateParent method.
             Traction(Mounica V), December 6,2019-Ticket:BGE-61 : Added new defaults.
             Traction(Mounica V), December 12,2019-Ticket:BGE-41 : Added new section- Recognition Credit and the logic to insert credit record.
             Traction(Ana Carolina F), January 8,2019-Ticket:BGE-18 : Added improvement to avoid reach limits.
*/
global class BatchLogDetailPageController {
  public Batch_Log__c batchLog {get; set;}
  public String headers {get; set;}
  public String softCreditHeaders {get; set;}
  public static String MATCHING_COMPANY {get; set;}
  Public rC_Giving__Opportunity_Credit__c newCredit{get; set;}
  public static String WORKPLACE_GIVING {get; set;}
  public List<BatchPreferenceWrapper> BatchPrefWrapperLst {get; set;}
  public List<BatchPreferenceWrapper> selectedBatchPrefWrapperLst {get; set;}
  public Set<String> selectedFields;
  public List<String> warningsBatchLog{get; set;}
  public String warningsBatchLogString{get; set;}
  public Integer selectedOpptyForAdjustment;
  public List<OpportunityWrapper> opportunityWrapperLst {get; set;}
  public List<rC_Giving__Opportunity_Credit__c> credits {get; set;}
  public OpportunityWrapper activeOpportunity {get; set;}
  public String opportunityWrapperLstJSON {
    get {
      return JSON.serialize(opportunityWrapperLst);
    }
  }
  public List<OpportunityWrapper> opptyWrapperToDelete;
  public List<Schema.FieldSetMember> labelFieldSet {get; set;}
  public static Set<String> bgeRequiredFields;
  public Map<Id, CopyOpportunityWrapper> copyOpptyWrapperLst;
  public List<Schema.FieldSetMember> adjustmentFieldSet {get; set;}
  public List<Opportunity> adjustmentOpptyLst {get; set;}
  public List<OpportunityWrapper> childOppWrapperLst {get; set;} //change
  public Boolean isEdit {get; set;}
  public Boolean isActionEdit {get; set;}
  public Boolean isError {get; set;}
  public Boolean isReleased {get; set;}
  public Integer newSplitRowIndex {get; set;}
  public String relation;
  public Id batchLogId {get; set;}
  public String batchLogCampaignName {get; set;} //Sai-7/9: LabelChange
  public Map<String, Integer> colOrderMap {get; set;}
  public Set<Integer> updatedRows {get; set;}
  public String batchProgramType {get; set;}
  public String batchType {get; set;}
  public String affiliateCode {get; set;}
  public Integer count = 0, batchSeq = 0;
  public Opportunity originalTransaction{get; set;}
    public Opportunity originalDTransaction {get; set;}
  public String fieldSetName;
  public Integer selectdOpptyForImo;
  public List<Opportunity> adjustmentOpptyUpdateLst;
  public Opportunity parentOppty;
  public Opportunity newParentOppty;
  public static Map<String, String> batchTypeToFieldSetMap;
  public Map<Integer, Opportunity> opptyLst;
  public Map<Integer, Integer> mapOppRowCountVsListValue;
  public Map<Integer, String> mapOppRowCountVsCmpProdIds;
  public String campaignProdIds {get;set;}
  public Id activeOpportunityRecId;
  public Id activeOpportunityCampaignId;
  public Boolean activeOpportunityIsNew;
  public Id adjustedTransactionId {get; set;}
  public Set<Id> parentOpptyIds;
  public static Boolean isNational, isAffiliate;
  public static Map<String, Schema.RecordTypeInfo> opptyRtMap;
  public static Map<String, Schema.RecordTypeInfo> batchLogRtMap;
  public static User loggedInUser;
  public static String objPrefix;
  public static String paymentKeyPrefix;
  public static String destUrlToCreateAcc {get; set;}
  public static String destUrlToCreatePaymentMthd {get; set;}
  public static Opportunity temporaryOpportunity {get; set;}
  public String ImoaccountName {get; set;}
  public Boolean isAdjustBatch {get; set;}
  public static Boolean staticAdjustmentBatch ;
  public static final Id OPP_RT_DONATION_ID {get; set;}
  public static final Id OPP_RT_PLEDGE_PAYMENT_ID {get; set;}
  public static final Id OPP_RT_SOFT_CREDIT_ID {get; set;}
  public static final Id OPP_RT_TRANSACTION {get; set;}
  public static final Id OPP_RT_Adjustment {get; set;}
  public static final Id OPP_RT_PLEDGE_ID {get; set;}
  public static String accType {get; set;}
  public Id theAccountId {get; set;}
  public String sourceCde {get; set;}
  public String progtype {get; set;}
  public Boolean showPledges {get; set;}
  public static Boolean userHasPledgeAccess {get; set;}
  public Boolean hasClicked {get; set;}
  //private Map<Id, Opportunity> mapOfOppIdAndOpps;
  private Map<Id, Boolean> opptyToHasSoftCreditMap;
  public Boolean errorInBatchRow {get; set;}
  public String errorMsg;
  public Boolean saveHappened {get; set;}
  public Opportunity OppToUpdate {get; set;}
  public Set<Id> setAccountIds {get; set;}
  public Set<Id> setSoftCreditAccountIds {get; set;}
  private String batchSequenceInError {get; set;}
  public Id campaignId_Old {get; set;}
  public Double amount_Old {get; set;}
  public String listRetURL;
  public Boolean isAdjustementsCreated {get; set;}
  public Id adjustTransParentId {get;set;}
  public Boolean adjustmentCancelled {get;set;}
  public static Boolean adjustmentCancellationInProgress {get;set;}
  public Boolean recordsToCommit {get;set;}
  public Boolean showAdj_Save_Commit_btn {get; set;}
  public Boolean showAdj_CancelAdjust_btn {get; set;}
  public Boolean showAdj_Save_btn {get; set;}
  public Boolean showAdj_close_btn {get; set;}
  public Boolean AdjustmentCreatedOnce;
  public static Boolean showTPABypass{get;set;}
  public static String reportURL{get;set;}
  public static String reportAdjustURL{get;set;}
  Public static String reportCreditsURL{get;set;}
  Public static String reportOppURL{get;set;}
  public Boolean batchLogInvalid {get;set;}
  public Map<Id, List<rC_Giving__Opportunity_Credit__c>> oppCredits {get; set;}
  public Boolean isNew {
    get {
      return (batchLogId == null);
    }
  }
  public Boolean newOrEditing {
    get {
      return isNew || isEdit;
    }
  }
  public Boolean isCompleted {
    get {
      return isAdjustOrReleased
          || ( activeOpportunity != null
            && activeOpportunity.objOppty != null
            && activeOpportunity.objOppty.StageName == 'Completed');
    }
  }
  public Boolean isAffiliateOrReleased {
    get {
      return loggedInUser.Is_Affiliate_User__c
        || isReleased;
    }
  }

  public Boolean affiliateUser {
      get{
          return loggedInUser.Is_Affiliate_User__c;
      }
  }
  public Boolean isAdjustOrReleased {
    get {
      return isAdjustBatch
          || isReleased;
    }
  }
  public Boolean isAdjustOrSplit {
    get {
      return isAdjustOrReleased
          || ( activeOpportunity != null
            && activeOpportunity.isPartOfASplit);
    }
  }
  public Boolean isSplitOrCompleted {
    get {
      return isAdjustOrSplit
          || isCompleted;
    }
  }
  public Boolean hasPrimaryAffiliation {
    get {
      return isAffiliate
        && String.IsNotBlank(loggedInUser.Primary_Affiliate__c);
    }
  }
  public Boolean isUserNotAffiliate{get;set;}
  public Boolean psrequired{
        get{
            return (activeOpportunity != null && activeOpportunity.objOppty != null &&
            (isPsRequired(activeOpportunity.objoppty.rC_Giving__Payment_Method__c)));
        }
    }

  public Boolean isAdjustmentRcType{
      get{
          return(activeOpportunity != null &&
          activeOpportunity.objOppty.recordTypeId == OPP_RT_Adjustment);
      }
  }

  //Returns the LoggedInUserAffiliationsai-7/28:change
  public String userAffiliation{
      get{
            return ((loggedInUser.Primary_Affiliate__c != null)? (loggedInUser.Primary_Affiliate__c).substring(0,2):null);
      }
  }

  //Returns if the BatchLogItems are null sai-7/28:change
  public Boolean hasBatchLogItems{
        get{
            return (opportunityWrapperLst == null || opportunityWrapperLst.isEmpty())?true:false;
        }
  }

  //CustomIterable obj;

  // BATCH LOG Error Messages
  public static final String AMOUNT_ERROR = 'Expected Amount: You must enter a value';
  public static final String AMOUNT_MISMATCH_ERROR = 'Error: You cannot release a batch where the actual and expected amounts do not match.';
  public static final String COUNT_ERROR = 'Expected Count: You must enter a value';
  public static final String COUNT_MISMATCH_ERROR = 'Error: You cannot release a batch where the actual and expected counts do not match.';
  public static final String DEPOSIT_SITE_MISMATCH = 'Error: Batch Log Status cannot be set to Balanced or Released when Deposit Site on Giving and Batch Log do not match.';
  public static final String BANK_DATE_INVALID = 'Error: Batch Log Status cannot be set to Balanced or Released when Bank Date is less than Close Date.';
  public static final String BATCHLOGDEPOSIT_ERROR = 'Please select a Deposit Site';
  public static final String PROGRAMTYPE_ERROR = 'Please select a Program Type';

  // Gift Error Messages
  public static final String ACCOUNT_REQUIRED = 'Account field is required on all Gifts.';
  public static final String CAMPAIGN_REQUIRED = 'Campaign field is required on all Gifts.';
  public static final String PAYMENT_METHOD_REQUIRED = 'Payment Method field is required on all Gifts.';
  public static final String PAYMENT_SUBTYPE_REQUIRED = 'Payment Sub Type field is required on all Gifts.';
  public static final String AMOUNT_REQUIRED = 'Giving Amount field is required on all Gifts.';
  public static final String NO_ZERO_DOLLAR_GIFTS = 'You are not allowed to create $0 Gifts.';
  public static final String TRIBUTE_TYPE_REQUIRED = 'Tribute Type field is required';
  public static final String PLEDGE_PAYMENT_METHOD_ERROR = 'Error: Pledges should default to \'Other\' as Payment Method and \'Pledge\' as Payment Subtype';
  public static final String SHARECODE_REQUIRED = 'Please populate a value to override the sharing Code on this gift';
  public static final String SHAREENTITY_REQUIRED = 'Please select a value to override the sharing Entity on this gift';
  public static final String SHAREENTITYOVERRIDE_REQUIRED = 'Please check the Sharing Entity Override checkbox when a value is selected for Sharing Entity';
  public static final String SHARECODEOVERRIDE_REQUIRED = 'Please check the Sharing Code Override checkbox when a value is populated in Sharing Code';
  public static final String SOFTCREDITTYPE_REQUIRED = 'Recognition Credit Type is required when Recognition Credit Account is populated';
  public static final String SOFTCREDITACCOUNT_REQUIRED = 'Recognition Credit Account is required when Recognition Credit Type is populated';
  public static final String CREDITRECOGNITIONTYPE = 'This Recognition Credit Type requires a Payment Issuer';

  public List<SelectOption> getRecTypeValues() {
    List<SelectOption> recTypeOptions = new List<SelectOption>();
    recTypeOptions.add(new SelectOption('Donation', 'Donation'));
    recTypeOptions.add(new SelectOption('Pledge', 'Pledge'));
    return recTypeOptions;
  }

  public List<SelectOption> getProgramOptions() {
    List<SelectOption> prgmOptions = new List<SelectOption>();
    prgmOptions.add(new SelectOption('', '--None--'));
    prgmOptions.add(new SelectOption('U', 'Union'));
    prgmOptions.add(new SelectOption('F', 'Foundation'));
    return prgmOptions;
  }

  public List<SelectOption> getBatchTypeLst() {
    List<SelectOption> batchTypeOptns = new List<SelectOption>();
    batchTypeOptns.add(new SelectOption('Standard', 'Standard'));
    return batchTypeOptns;
  }

  public List<SelectOption> getAffiliateCodes() {

    List<SelectOption> affCodeOptions = new List<SelectOption>();
    for (Schema.PicklistEntry pfe : Batch_Log__c.Affiliation__c.getDescribe().getPicklistValues()) {
      if (String.IsBlank(loggedInUser.Primary_Affiliate__c)) {
        String code = pfe.getValue().substring(0, 2);
        affCodeOptions.add(new SelectOption(code, code));
      } else if (!String.IsBlank(loggedInUser.Primary_Affiliate__c) && String.ValueOf(loggedInUser.Primary_Affiliate__c).Substring(0, 2) == pfe.getValue().substring(0, 2)) {
        String code = pfe.getValue().substring(0, 2);
        affCodeOptions.add(new SelectOption(code, code));
      }
    }
    return affCodeOptions;
  }

  static {
    MATCHING_COMPANY = ACLU_Constants.CONST_ACCTYPE_MATCHING_COMPANY;
    WORKPLACE_GIVING = ACLU_Constants.CONST_ACCTYPE_WORKPLACE_GIVING_ORG;
    temporaryOpportunity = new Opportunity();
    //temporaryOpportunity.AccountId = '001W000000OcoT6';
    opptyRtMap = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName();
    OPP_RT_DONATION_ID = opptyRtMap.get('Donation').getRecordTypeId();
    OPP_RT_PLEDGE_ID = opptyRtMap.get('Pledge').getRecordTypeId();
    OPP_RT_PLEDGE_PAYMENT_ID = opptyRtMap.get('Pledge Payment').getRecordTypeId();
    OPP_RT_SOFT_CREDIT_ID = opptyRtMap.get('Soft Credit').getRecordTypeId();
    OPP_RT_TRANSACTION = opptyRtMap.get('Transaction').getRecordTypeId();
    OPP_RT_Adjustment = opptyRtMap.get('Adjustment').getRecordTypeId();
    isAffiliate = false;

    isNational = false;
    staticAdjustmentBatch = false;
    objPrefix = Batch_Log__c.sobjecttype.getDescribe().getKeyPrefix();
    batchTypeToFieldSetMap = new Map<String, String>();

    adjustmentCancellationInProgress = false;

    batchLogRtMap = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName();
    paymentKeyPrefix = rC_Giving__Payment_Method__c.sobjecttype.getDescribe().getKeyPrefix();
    destUrlToCreateAcc = System.URL.getSalesforceBaseUrl().toExternalForm() + '/setup/ui/recordtypeselect.jsp?ent=Account&retURL=%2F001%2Fo&save_new_url=%2F001%2Fe%3FretURL%3D%252F001%252Fo';
    // TODO: Is this query selective?
    loggedInUser = [SELECT Id, Profile.Name, Name, Is_Affiliate_User__c, Primary_Affiliate__c FROM User WHERE Id = : UserInfo.getUserId()];
    bgeRequiredFields = Batch_Log_Items_Required_Fields__c.getall().keySet();
    userHasPledgeAccess = BatchLogDetailPageController.hide_OpenProsposals();
    if (loggedInUser.Is_Affiliate_User__c) {
      isAffiliate = true;
    } else {
      // TODO: Is this query selective?
      for (GroupMember member : [SELECT groupId, group.name, UserOrGroupId from GroupMember where UserOrGroupId = : loggedInUser.Id AND group.name = 'National']) {
        isNational = true;
        break;
      }
    }
    Map<String, Batch_Type_To_Oppty_Field_Set_Mapping__c> fieldSetMapping = Batch_Type_To_Oppty_Field_Set_Mapping__c.getAll();
    if (fieldSetMapping != null) {
      for (Batch_Type_To_Oppty_Field_Set_Mapping__c cSetting : fieldSetMapping.values()) {
        batchTypeToFieldSetMap.put(cSetting.Batch_Type__c, cSetting.Field_Set_Name__c);
      }
    }

    list<PermissionSetAssignment> assignment = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :loggedInUser.Id AND PermissionSet.Name = 'ACLU_Batch_Log_TPA_Bypass'];
    if(!assignment.isEmpty()) {
        showTPABypass = true;
    } else {
        showTPABypass = false;
    }
  }

  // Get Relevant Deposit Site Values for Affiliates with a primary affiliation
  // For non-affiliates we use a standard inputField which respects
  // recordType - picklist selections
  public List<SelectOption> getAffiliateDepositSites() {
    List<SelectOption> affiliateOptions = new List<SelectOption>();
    if (hasPrimaryAffiliation) {
      for (Schema.PicklistEntry pfe : Batch_Log__c.Deposit_Site__c.getDescribe().getPicklistValues()) {
        if (
          String.ValueOf(pfe.getLabel())
            .startsWith(String.ValueOf(loggedInUser.Primary_Affiliate__c)
            .Substring(0, 2))) {
          affiliateOptions.add(new SelectOption(pfe.getLabel(), pfe.getValue()));
        }
      }
    }
    return affiliateOptions;
  }

  //get Relevant Acknowledgment Code
  public List<SelectOption> getAcknowledgementCodePicklist() {
    List<SelectOption> acknowledgementCodePicklist = new List<selectOption>();
    acknowledgementCodePicklist.add(new SelectOption('', 'None'));
    List<Acknowledgement_Code_Mapping__mdt> AckCodeMapping = new List<Acknowledgement_Code_Mapping__mdt>();
    if (!String.IsBlank(affiliateCode)) {
      String affiliationCode = String.ValueOf(affiliateCode).Substring(0, 2);
      // TODO: Is this query selective?
      AckCodeMapping = [
        SELECT Id, Acknowledgement_Code__c, Batch_Log_Affiliation_Code__c
        FROM Acknowledgement_Code_Mapping__mdt
        WHERE Batch_Log_Affiliation_Code__c = :affiliationCode
        LIMIT 1];
    }

    if (AckCodeMapping.size() > 0 && AckCodeMapping[0].Acknowledgement_Code__c != null && !AckCodeMapping.isEmpty()) {

      for (String str : String.ValueOf(AckCodeMapping[0].Acknowledgement_Code__c).Split(';')) {

        acknowledgementCodePicklist.add(new SelectOption(str, str));
      }
    }
    return acknowledgementCodePicklist;
  }

  // Get Opportunity FieldSet Fields
  public List<Schema.FieldSetMember> getFields(String fsName) {
    return SObjectType.Opportunity.FieldSets.getMap().get(fsName).getFields();
  }

  // Constructor
  public BatchLogDetailPageController(ApexPages.standardController controller) {
    headers = '';
    softCreditHeaders = '';
    AdjustmentCreatedOnce = false;
    hasClicked = False;
    errorInBatchRow = False;
    errorMsg = '';
    //mapOfOppIdAndOpps = new Map<Id, Opportunity>();
    opportunityWrapperLst = new List<OpportunityWrapper>();
    childOppWrapperLst = new List<OpportunityWrapper>();//change
    opptyLst = new Map<Integer, Opportunity>();
    mapOppRowCountVsListValue = new Map<Integer, Integer>();
    mapOppRowCountVsCmpProdIds = new Map<Integer, String>();
    opptyWrapperToDelete = new List<OpportunityWrapper>();
    BatchPrefWrapperLst = new List<BatchPreferenceWrapper>();
    credits = new List<rC_Giving__Opportunity_Credit__c>();
    selectedBatchPrefWrapperLst = new List<BatchPreferenceWrapper>();
    warningsBatchLog = new List<String>();
    copyOpptyWrapperLst = new Map<Id, CopyOpportunityWrapper>();
    selectedFields = new Set<String>();
    destUrlToCreatePaymentMthd = '';
    colOrderMap = new Map<String, Integer>();
    updatedRows = new Set<Integer>();
    setAccountIds = new Set<Id>();
    setSoftCreditAccountIds = new Set<Id>();
    isEdit = false;
    isAdjustBatch = false;
    isActionEdit = false;
    isError = false;
    batchLogId = (controller.getId() != null) ? controller.getId() : null;
    displayPopup = false;
    paymentMType = null;
    oppRow = 0;
    adjustmentCancelled = false;
    recordsToCommit = false;
    showPledges = BatchLogDetailPageController.hide_OpenProsposals();
    adjustedTransactionId = ApexPages.currentPage().getParameters().get('adjustedTransactionId') != null ?
                            ApexPages.currentPage().getParameters().get('adjustedTransactionId') : null;
     /* Mounica V: BGE-41,setting defaults to the Recognition Credit section*/
    if(!isAdjustBatch){
     newCredit = new rC_Giving__Opportunity_Credit__c();
     newCredit.rC_Giving__Distribution__c = 100.0;
     newCredit.rC_Giving__Type__c = 'Account Only';
    }//BGE-41 END

    isUserNotAffiliate = affiliateUser ? false : true;
    if (batchLogId != null) {
      // TODO: Is this query selective?
      batchLog = [
        SELECT Id, Name, Batch_Log_Type__c, Default_Campaign__r.rC_Giving__Sub_Affiliation__c,
          Batch_Type__c, Accounting_Date__c, Default_Campaign__c,
          Default_Campaign__r.rC_Giving__Source_Code__c, Default_Campaign__r.Name,
          Batch_Log_Status__c, Bank_Date__c, Deposit_Site__c,
          Default_Payment__c, Batch_Date__c, Actual_Amount__c, Expected_Amount__c,
          Actual_Count__c, Expected_Count__c, Tax_Date__c, Subcategory__c,
          Payment_Subtype__c, Program_Type__c, Affiliation__c, Days_Open__c,
          OwnerId, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate,
          Total_Fees__c, Total_Net_Amount__c, BatchLog_Has_Fees__c, TPA_Bypass__c, Has_Error_Details__c,Error_Details__c,Default_Account_Code__c,
          Default_Check__c,Default_Check_Date__c,Default_Gift_Amount__c,Default_Fund__c,Comments__c, Default_Payment_Issuer__c
        FROM Batch_Log__c
        WHERE Id = :batchLogId];
      batchProgramType = batchLog.Name.substring(2, 3);
      affiliateCode = batchLog.Name.substring(0, 2);
      batchLogCampaignName = batchLog.Default_Campaign__r.Name; //Sai-7/9: LabelChange
      sourceCde = batchLog.Default_Campaign__r.rC_Giving__Source_Code__c;
      progtype = batchLog.Default_Campaign__r.rC_Giving__Sub_Affiliation__c;
      reportURL ='/'+label.Batch_Log_Detail_Report+'?pv1='+batchLog.Name+'&pv3='+batchLog.Name;
      reportAdjustURL ='/'+label.Batch_Log_Detail_Adjust_Report+'?pv='+batchLog.Name+'&pv='+batchLog.Name;
    } else {
      createBatchLogRecord();
    }
    isAdjustBatch =  batchLog.Batch_Type__c == 'Adjustment' ? true : false;

    staticAdjustmentBatch = isAdjustBatch;

    if (isAdjustBatch) {
      adjustmentFieldSet = this.getFields('Adjustments_Field_Set');
    }


    // Check Released Status
    if (batchLog.Batch_Log_Status__c == 'Balanced') {
      isReleased = true;
    } else {
      isReleased = false;
    }

    if( batchLog.Has_Error_Details__c && batchLog.Error_Details__c != null ){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, batchLog.Error_Details__c));
        isError = true;
    }
    // Select Oppty Field Set based on Batch Type.
    if (!batchTypeToFieldSetMap.isEmpty() && batchTypeToFieldSetMap.containsKey(batchLog.Batch_Type__c)) {
      fieldSetName = batchTypeToFieldSetMap.get(batchLog.Batch_Type__c);
    }
    populateOpportunityWrapper();
    populateShowPledges();
  }

  // Method to populate Batch Preference Wrapper
  public void populateBatchPrefWrapper() {
    if (fieldSetName != null ) {
      Integer i = 0;

      for (Schema.FieldSetMember f : labelFieldSet) {
        BatchPrefWrapperLst.add(new BatchPreferenceWrapper(f.getFieldPath(), f.getLabel(), f.getType()));
        selectedBatchPrefWrapperLst.add(new BatchPreferenceWrapper(f.getFieldPath(), f.getLabel(), f.getType()));
        headers = headers == '' ? f.getLabel() : headers + ',' + f.getLabel();
        colOrderMap.put(f.getLabel(), i++);
      }
    }
  }

  public static Boolean hide_OpenProsposals() {
    Boolean isAccessToPledges = false;
    //Open Pledges Access
    // TODO: Is this query selective?
    for (User u : [SELECT Id, Denied_Access_to_Open_Givings__c, Profile.Name FROM User WHERE Id = : UserInfo.getuserId()]) {
      if (u.Denied_Access_to_Open_Givings__c == true ) {
        isAccessToPledges = true;
      }
    }

    return isAccessToPledges;
  }

  public void createBatchLogRecord() {
    batchLog = new Batch_Log__c();
    batchLog.Batch_Type__c = 'Standard';
    batchLog.Batch_Log_Status__c = 'Open';
    batchLog.Batch_Log_Type__c = 'Manual';
    batchLog.Accounting_Date__c = date.today();
    batchLog.Batch_Date__c = date.today();
    batchLog.RecordTypeId = batchLogRtMap.get('Manual').getRecordTypeId();
    batchLog.Affiliation__c = affiliateCode != null ? affiliateCode : 'NA';
    if (batchProgramType == 'U') {
      batchLog.Program_Type__c = '1';
    } else {
      batchLog.Program_Type__c = '4';
    }
  }

  public void populateOpportunityWrapper() {
    Boolean isSplit = false;
    Boolean isSplitParent = false;
    parentOpptyIds = new Set<Id>();
    opptyToHasSoftCreditMap = new Map<Id, Boolean>();
    Set<Id> opportunitiesIds = new Set<Id>();
    List<Opportunity> adjustmentParentOpptys= new List<Opportunity>();
    Map <Id, Opportunity> mapParentIdVsChildTrans_pp = new Map<Id, Opportunity>();
    Map<Id,Boolean> mapParentVsAdjustmentsCreated = new Map<Id,Boolean>();

    if(adjustedTransactionId != null){
       Opportunity AdjusteTransactionRec= [SELECT Id, RecordType.Name, rC_Giving__Parent__c FROM Opportunity WHERE Id=:adjustedTransactionId LIMIT 1];
       adjustTransParentId = AdjusteTransactionRec.rC_Giving__Parent__c;
     }

    if (fieldSetName != null ) {
      labelFieldSet = this.getFields(fieldSetName);
      if (batchLog.Id != null) {
        Integer i = 0;
        // TODO: Is this query selective?
        String queryString = 'SELECT ';
        String query = '';

        for (Schema.FieldSetMember f : labelFieldSet) {
          queryString += f.getFieldPath() + ', ';
          //colOrderMap.put(f.getLabel(),i++);
        }
        queryString += 'Id, Name, Account.Account_Type__c, Batch_Log__c, rC_Giving__Tribute_Type__c, Honoree_Title__c, Honoree_First_Name__c, Honoree_Middle_Name__c, Honoree_Last_Name__c, ';
        queryString += 'Honoree_Suffix__c, Non_Person__c, Tribute_Message_Body__c, Ack_Recipient_Account__c, Ack_Recipient_Account__r.Name, Ack_Recipient_Account__r.Account_Type__c, Ack_Recipient_Full_Name__c, Ack_Recipient_Street_Line_1__c,';
        queryString += 'Ack_Recipient_Street_Line_2__c, Posted_to_GL_Checkbox__c, rC_Giving__Transaction_Type__c, Ack_Recipient_City__c, Ack_Recipient_State__c, Campaign.Name, Ack_Recipient_Country__c, Ack_Recipient_Zip_Code__c, Recordtype.Name, ';
        queryString += ' Adjustment_Reason_Type__c, account.Name, account.Affiliation__c, Adjustment_Code__c, rC_Giving__Current_Giving_Amount__c, Recipient_Acknowledgment_Code__c, ';
        queryString += ' Ack_Recipient_Outside_Salutation__c, rC_Giving__Source_Code__c,Total_Credits__c,Proposal__r.name, rC_Giving__Payment_Method_Selected__r.Name, rC_Giving__Last_Giving_Amount_Adjustment_Date__c, Recipient_Acknowledgement_Status__c ';


        //START GH-75
        if (!queryString.contains(' ,Amount ') && !queryString.contains(' Amount,')) {
          queryString += ',Amount ';
        }
        //END GH-75
  system.debug('***QUERY STRING**' + queryString);
        if (!queryString.contains('rC_Giving__Is_Sustainer__c')) {
          queryString += ',rC_Giving__Is_Sustainer__c ';
        }

        if (!queryString.contains('Bypass_Calculations__c')) {
          queryString += ',Bypass_Calculations__c ';
        }

        if (!queryString.contains('rC_Giving__Parent_Name__c')) {
          queryString += ',rC_Giving__Parent_Name__c ';
        }

        if (!queryString.contains('Sharing_Entity_Affiliation__c')) {
          queryString += ',Sharing_Entity_Affiliation__c ';
        }

        if (!queryString.contains('CloseDate')) {
          queryString += ',CloseDate ';
        }
        if (!queryString.contains('Batch_Date__c')) {
          queryString += ',Batch_Date__c ';
        }
        if (!queryString.contains('Accounting_Date__c')) {
          queryString += ',Accounting_Date__c ';
        }
        if (!queryString.contains('Bank_Date__c')) {
          queryString += ',Bank_Date__c ';
        }
        if (!queryString.contains('Program_Type__c')) {
          queryString += ',Program_Type__c ';
        }
        if (!queryString.contains('Tax_Date__c')) {
          queryString += ',Tax_Date__c ';
        }
        if (!queryString.contains('rC_Giving__Giving_Years__c')) {
          queryString += ',rC_Giving__Giving_Years__c ';
        }
        if (!queryString.contains('rC_Giving__Payment_Frequency__c')) {
          queryString += ',rC_Giving__Payment_Frequency__c ';
        }
        if (!queryString.contains('Deposit_Site__c')) {
          queryString += ',Deposit_Site__c ';
        }
        if (!queryString.contains('Fundraising_Department__c')) {
          queryString += ',Fundraising_Department__c ';
        }
        if (!queryString.contains('rC_Giving__Is_Tribute__c')){
            queryString += ',rC_Giving__Is_Tribute__c ';
        }
        if (!queryString.contains('Description')){
            queryString += ',Description ';
        }
        if (!queryString.contains('rC_Giving__Comments__c')){
              queryString += ',rC_Giving__Comments__c ';
        }
        if(!queryString.contains('Proposal__c')){
            queryString+= ',Proposal__c ';
        }
        if(!queryString.contains('Has_Soft_Credits__c')){
            queryString+= ',Has_Soft_Credits__c ';
        }
        if(!queryString.contains('rC_Giving__Parent__c')){
            queryString+= ',rC_Giving__Parent__c';
        }
        if(!queryString.contains('IsCreatedFromBatchLog__c')){
            queryString+= ',IsCreatedFromBatchLog__c';
        }
        if(!queryString.contains('Related_Transaction__c')){
            queryString+= ',Related_Transaction__c';
        }
        if(!queryString.contains('Adjustment_Sequence__c ')){
            queryString+= ',Adjustment_Sequence__c';
        }


//        BGE-18 improve query to avoid reach limits
        if (isAdjustBatch) {
          query += queryString;
          query += ' ,Split_Sequence__c, Batch_Sequence__c ';
        if(AdjustmentCreatedOnce){
            query += ' FROM Opportunity WHERE Batch_Log__c = \'' + batchLog.Id + '\' ';
                        if(parentOpptyIds.size()>1) query += ' AND (amount != 0)';
        }
        else{
            query += ' FROM Opportunity WHERE Adjustment_Batch__c = \'' + batchLog.Id + '\' ';
                        if(parentOpptyIds.size()>1) query += ' AND (amount != 0)';
        }

        query += ' AND (RecordType.Name in (\'Transaction\', \'Pledge\') OR (RecordType.Name = \'Pledge Payment\' AND Related_Transaction__c = null))';
    } else {
          query += queryString + ',(SELECT id,rC_Giving__Distribution__c,rC_Giving__Type__c,Payment_Issuer__c,Ack_Fund_Name__c,rC_Giving__Opportunity__c,Comments__c,rC_Giving__Account__c,Soft_Credit_Type__c FROM rC_Giving__Opportunity_Credits__r limit 1) FROM Opportunity WHERE Batch_Log__c = \'' + batchLog.Id + '\'';

//          query += ' AND (RecordType.Name = \'Pledge\' OR RecordType.Name = \'Donation\' OR (RecordType.Name = \'Pledge Payment\' AND Related_Transaction__c = null) OR (RecordType.Name = \'Adjustment\' AND Adjustment_Code__c = \'A\'))';
          query += ' AND IsCreatedFromBatchLog__c = True ';
          query += ' AND (RecordType.Name in (\'Pledge\' , \'Donation\') OR (RecordType.Name = \'Pledge Payment\' AND Related_Transaction__c = null) OR (RecordType.Name = \'Adjustment\' AND Adjustment_Code__c = \'A\'))';
        }

        query += ' ORDER BY Batch_Sequence_Formula__c,Split_Sequence__c';
// BGE-18 improve query to avoid reach limits
        if(batchLog.TPA_Bypass__c) {
            query += ' LIMIT 1';
        } else {
            query += ' LIMIT 1000';
        }

        Decimal Total_Fees = 0;
        Decimal Total_Net_Amount = 0;
        batchLog.BatchLog_Has_Fees__c = false;
        //System.assert(false, Database.query(query)+'>>'+query+'===='+isAdjustBatch);

          system.debug('***QUERY STRING**' + query);

        for (Opportunity objOppty : Database.query(query)) {
          if (!isAdjustBatch) {

            //mapOfOppIdAndOpps.put(objOppty.Id, objOppty);
            isSplit = objOppty.Split_Sequence__c > 1 ? true : false;
            isSplitParent = objOppty.Split_Sequence__c == 1 ? true : false;
            parentOpptyIds.add(objOppty.Id);
            opportunityWrapperLst.add(new OpportunityWrapper(objOppty, count + 1, isSplit, isSplitParent, false, isAdjustBatch));
            setAccountIds.add(objOppty.accountId);
            opportunitiesIds.add(objOppty.Id);
            if (objOppty.Batch_Sequence__c != null && (objOppty.Split_Sequence__c == null || objOppty.Split_Sequence__c == 1)) {
              batchSeq = Math.max(Integer.valueOf(objOppty.Batch_Sequence__c), batchSeq); // Maintaining Batch Sequences.
            }
            copyOpptyWrapperLst.put(objOppty.Id, new CopyOpportunityWrapper(objOppty.rC_Giving__Matching_Account__c));
            count = count + 1; // Maintaining Total Record countsts.
            //T-654179, bhavesh

            if( objOppty.Fees__c != null ){
                batchLog.BatchLog_Has_Fees__c = true;
                Total_Fees += objOppty.Fees__c;
            }
            if( objOppty.Net_Amount__c != null ){
                Total_Net_Amount += objOppty.Net_Amount__c;
            }
          } else {
            if (objOppty.RecordType.Name == 'Pledge') {
              parentOpptyIds.add(objOppty.Id);
            }
            // START GH-75: Pledge Payments previously led to rendering if Parent in batch log table
            else if (objOppty.RecordType.Name == 'Pledge Payment') {
              opportunitiesIds.add(objOppty.Id);
            }
            // END GH-75
            else {
              parentOpptyIds.add(objOppty.rC_Giving__Parent__c);
            }
              List<Opportunity> parentParentId = [SELECT rC_Giving__Parent__c from Opportunity Where Id in :parentOpptyIds];
              if (parentParentId.size()>0 && parentParentId[0].rC_Giving__Parent__c != null)  parentOpptyIds.add(parentParentId[0].rC_Giving__Parent__c);
          }

        if( Total_Fees != 0 )
            batchLog.Total_Fees__c = Total_Fees;
        if( Total_Net_Amount != 0 )
            batchLog.Total_Net_Amount__c = Total_Net_Amount;
        }

        populateOpenPledges(opportunityWrapperLst, setAccountIds);

        if (isAdjustBatch) {
          String adjustQuery = queryString;
            String amountValidation = '';
            if(parentOpptyIds.size()>1)  amountValidation += ' AND rC_Giving__Current_Giving_Amount__c !=0 ';
          adjustQuery += ' ,Batch_Sequence__c, Split_Sequence__c,Account_Number_BGE__c, rC_Giving__Parent__r.rC_Giving__Parent__c, rC_Giving__Matching_Status__c, Account_Code__c, rC_Giving__Is_Anonymous__c, Related_Transaction__r.rC_Giving__Parent__c, ';//Sai-7/26:Change
          adjustQuery += ' rC_Giving__Matching_Account__c, Fund__c FROM Opportunity ' ; //Sai-7/6:Change
          adjustQuery += ' WHERE (rC_Giving__Parent__c IN: parentOpptyIds AND RecordType.Name = \'Soft Credit\')';
          //adjustQuery += ' OR (Adjustment_Batch__c = \'' + batchLog.Id + '\' )'; //BGE-84 get opportunities related with this adjustment batch
          adjustQuery += ' OR (Related_Transaction__r.rC_Giving__Parent__c IN: parentOpptyIds AND RecordType.Name = \'Soft Credit\') '; //Sai-7/26:Change
          // adjustQuery += ' OR((recordType.Name=\'Pledge Payment\' AND Related_Transaction__c!= null AND Related_Transaction__r.rC_Giving__Parent__c IN: parentOpptyIds))'; //Sai-7/26:Change
          adjustQuery += ' OR((recordType.Name=\'Pledge Payment\' AND Id IN :opportunitiesIds))';
          adjustQuery += ' OR (Id IN: parentOpptyIds AND (RecordType.Name = \'Pledge\' OR RecordTypeId = ' + '\'' + OPP_RT_DONATION_ID + '\'' + ')';
          adjustQuery += ' AND IsCreatedFromBatchLog__c = True '+ amountValidation +' ) ';
          adjustQuery += ' ORDER BY Adjustment_Sequence__c,Split_Sequence__c';
             SYSTEM.DEBUG('***adjustQuery*** ' + adjustQuery);
             SYSTEM.DEBUG('***parentOpptyIds*** ' + parentOpptyIds);
          List<Opportunity> adjustOpps = Database.query(adjustQuery);
                       SYSTEM.DEBUG('***adjustOpps*** ' + adjustOpps);

          for (Opportunity objOppty : adjustOpps) {

            if (!isSoftCreditRec(objOppty)) {
              isSplit = objOppty.Split_Sequence__c > 1 ? true : false;
              isSplitParent = objOppty.Split_Sequence__c == 1 ? true : false;

              opportunityWrapperLst.add(new OpportunityWrapper(objOppty, count + 1, isSplit, isSplitParent, false, false, isAdjustBatch));
                setAccountIds.add(objOppty.accountId);
              opportunitiesIds.add(objOppty.Id);
              adjustmentParentOpptys.add(objOppty);
              if (objOppty.Batch_Sequence__c != null &&
                  (objOppty.Split_Sequence__c == null
                  || objOppty.Split_Sequence__c == 1)) {
                batchSeq = Math.max(Integer.valueOf(objOppty.Batch_Sequence__c), batchSeq); // Maintaining Batch Sequences.
              }
              count = count + 1; // Maintaining Total Record countsts.
              //mapOfOppIdAndOpps.put(objOppty.Id, objOppty);
            } else if(isSoftCreditRec(objOppty)){
                if(objOppty.Related_Transaction__r.rC_Giving__Parent__c != null){
                    opptyToHasSoftCreditMap.put(objOppty.Related_Transaction__r.rC_Giving__Parent__c, true);
                }
              }
          }

        }

        if(isAdjustBatch){
            mapParentVsAdjustmentsCreated = AdjustementsCreated(opportunitiesIds);
        }
//        BGE-18 improve query to avoid reacg=h limits
        for(Opportunity ObjOppty: [SELECT Id, recordTypeId, rC_Giving__Parent__c, Sharing_Entity_Affiliation__c , Sharing_Code__c, Sharing_Entity__c FROM Opportunity
                                        WHERE (rC_Giving__Parent__c=:opportunitiesIds OR Id=:opportunitiesIds) AND
                                        (RecordType.Name IN ('Transaction','Pledge Payment'))]){
                    mapParentIdVsChildTrans_pp.put(objOppty.rC_Giving__Parent__c, objOppty);
                    if(ObjOppty.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID && opportunitiesIds.contains(ObjOppty.Id) ){
                        mapParentIdVsChildTrans_pp.put(objOppty.Id, objOppty);
                    }
                    else{
                        mapParentIdVsChildTrans_pp.put(objOppty.rC_Giving__Parent__c, objOppty);
                    }
        }

        if(isAdjustBatch){
            calculateActualCounts_Amounts_Adjustmet(false);
        }
          if(!isAdjustBatch && !batchLog.TPA_Bypass__c){//BGE-18
            batchLog.Actual_Amount__c = 0;
        }

        for (OpportunityWrapper wrapper : opportunityWrapperLst) {

            if(wrapper.objOppty.id != null && mapParentIdVsChildTrans_pp.containsKey(wrapper.objOppty.id)){

                wrapper.affiliation = mapParentIdVsChildTrans_pp.get(wrapper.objOppty.id).Sharing_Entity_Affiliation__c;
//                system.debug('*** WRAPPER OPPT SHARING CODE OVERRIDE : ' + wrapper.objOppty.Sharing_Code_Override__c);
                if(!wrapper.objOppty.Sharing_Code_Override__c){
                   wrapper.sharingCode = mapParentIdVsChildTrans_pp.get(wrapper.objOppty.id).Sharing_Code__c;
                }
                else{
                   wrapper.sharingCode = wrapper.objOppty.Sharing_Code__c;
                }

                if(!wrapper.objOppty.Sharing_Entity_Override__c){
                   wrapper.sharingEntity = mapParentIdVsChildTrans_pp.get(wrapper.objOppty.id).Sharing_Entity__c;
                }
                else{
                   wrapper.sharingEntity = wrapper.objOppty.Sharing_Entity__c;
                }
            }
            if (isAdjustBatch && opptyToHasSoftCreditMap.containsKey(wrapper.objOppty.Id) && opptyToHasSoftCreditMap.get(wrapper.objOppty.Id)) {
                    wrapper.hasSoftCredits = true;
            }

            if(isAdjustBatch){
                if( mapParentVsAdjustmentsCreated.containsKey(wrapper.objOppty.Id) && (adjustTransParentId != wrapper.objOppty.Id)){
                    wrapper.isAdjustementsCreated = mapParentVsAdjustmentsCreated.get(wrapper.objOppty.Id);
                }
                else if(AdjustmentCreatedOnce){
                    wrapper.isAdjustementsCreated = true;
                }
                else{
                    wrapper.isAdjustementsCreated = false;
                }
                wrapper.batchSequence = String.valueOf(wrapper.objOppty.Adjustment_Sequence__c);
            }else{
                wrapper.batchSequence = String.valueOf(wrapper.objOppty.Batch_Sequence__c);
                //batchLog.Actual_Amount__c += amount(wrapper, wrapper.isAdjustBatchType);
                //BGE-18
                if(!batchLog.TPA_Bypass__c)
                    batchLog.Actual_Amount__c += getOriginalAmount(wrapper.objOppty,isPledgePayment(wrapper), isAdjustBatch);
            }


        }
      }
      Boolean amtMatch = softCreditAmountsMatch(true);
    }
      if(!isAdjustBatch && !batchLog.TPA_Bypass__c){
        batchLog.Actual_Count__c = batchSeq;
    }

    if(!isAdjustBatch){
    /*
        BGE-41 - ASl-97
        Ana Ferreira - Add values from created credit
    */
        Set<Id>oppIds =  new Set<Id>();
        for(OpportunityWrapper wrapper : opportunityWrapperLst){
          oppIds.add(wrapper.objOppty.Id);
        }
        oppCredits = getopportunityCredits(oppIds);
    }

    if(batchLog.TPA_Bypass__c) {
        if(batchLog.Actual_Count__c == null || batchLog.Actual_Count__c != batchLog.Expected_Count__c || batchLog.Actual_Amount__c != batchLog.Expected_Amount__c) {
            Database.executeBatch(new UpdateCountAndAmountOnBatchLog_Batch(batchLog.Id, true));
            Batch_Log__c newValues = [
                  SELECT Actual_Count__c, Actual_Amount__c
                  FROM Batch_Log__c
                  WHERE Id = :batchLogId][0];
            batchLog.Actual_Count__c = newValues.Actual_Count__c;
            batchLog.Actual_Amount__c = newValues.Actual_Amount__c;
            }
        opportunityWrapperLst.clear();
    }

  }
  /*
    BGE-41 - ASl-97
    Ana Ferreira - Add values from created credit
 */
  public Map<Id,List<rC_Giving__Opportunity_Credit__c>> getopportunityCredits(Set<Id> opptyId){
      List<rC_Giving__Opportunity_Credit__c> credits =
        [select id , rC_Giving__Opportunity__c, rC_Giving__Account__c, Soft_Credit_Type__c, rC_Giving__Type__c, rC_Giving__Distribution__c, Comments__c, Payment_Issuer__c,     Ack_Fund_Name__c
            from rC_Giving__Opportunity_Credit__c where rC_Giving__Opportunity__c in : opptyId];
      Map<Id, List<rC_Giving__Opportunity_Credit__c>> oppToCreditMap = new Map<Id, List<rC_Giving__Opportunity_Credit__c>>();
      for(rC_Giving__Opportunity_Credit__c credit : credits){
          if (oppToCreditMap.ContainsKey(credit.rC_Giving__Opportunity__c)) {
              oppToCreditMap.get(credit.rC_Giving__Opportunity__c).add(credit);
          } else {
              oppToCreditMap.put(credit.rC_Giving__Opportunity__c, new List<rC_Giving__Opportunity_Credit__c>{credit});
          }
      }
      return oppToCreditMap;
  }
  //isSoftCreditRecord
  public Boolean isSoftCreditRec(Opportunity opp){
        return (opp.recordTypeId == OPP_RT_SOFT_CREDIT_ID ||
                    (opp.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID && opp.Related_Transaction__c != null)
               )?true:false;
  }

  //Delete batch LogId sai-7/28:Change
  public pageReference deleteBatchLog(){
        SavePoint beforeSaving = Database.setSavePoint();
        try{
            Delete batchLog;
            return new PageReference('/'+objPrefix);
        }
        Catch(exception e){
            Database.rollback(beforeSaving);
            Exceptionutils.createApexLog('BatchLogDetailPageController','deleteBatchLog',e);
            return null;
        }


  }

  //redirect to Report sai-7/28:Change
  /*public PageReference redirectToReport(){
        String url='/'+label.Batch_Log_Detail_Report+'?pv1='+batchLog.Name+'&pv3='+batchLog.Name;
        PageReference pageRef = new PageReference(url);
        pageRef.setRedirect(true);
        return pageRef;
  }*/

  public Map<Id, List<Opportunity>> opportunitiesByAccount(Set<Id> accountIds) {
    Map<Id, List<Opportunity>> opportunitiesByAccount = new Map<Id, List<Opportunity>>();
    // TODO: Is this query selective?
    for (Opportunity Opp : [
        SELECT Id, Name, AccountId, RecordTypeId, recordType.Name,
          rC_Giving__Giving_Amount__c, amount, closeDate, campaignId, campaign.Name,
          campaign.rC_Giving__Source_Code__c, StageName, rC_Giving__Parent__c
        FROM Opportunity
        WHERE AccountId = :accountIds
          AND (
            RecordTypeId = : opptyRTMap.get('Grant').getRecordTypeId()
            OR RecordTypeId = : opptyRTMap.get('Proposal').getRecordTypeId()
            OR (
              RecordTypeId = : opptyRTMap.get('Pledge Payment').getRecordTypeId()
              AND stageName = 'Open' AND IsCreatedFromBatchLog__c = false ))]) {

      if (opportunitiesByAccount.ContainsKey(opp.AccountId)) {
        opportunitiesByAccount.get(opp.AccountId).add(opp);
      } else {
        opportunitiesByAccount.put(opp.AccountId, new List<Opportunity> {opp});
      }
    }
    return opportunitiesByAccount;
  }

  public void populateShowPledges () {
    populatePledgeBooleanMap(false);
  }

  public void populatePledgeBooleanMap(Boolean isChild){
    Map<Id, List<Opportunity>> mapOpportunities = new Map<Id, List<Opportunity>>();
    List<OpportunityWrapper> opportunityWrappers = new List<OpportunityWrapper>();

    if(isChild){
            opportunityWrappers = childOppWrapperLst;
            mapOpportunities = opportunitiesByAccount(setAccountIds);
    }
    else{
            mapOpportunities = opportunitiesByAccount(setAccountIds);
            opportunityWrappers = opportunityWrapperLst;
    }

    for (opportunityWrapper objWrapper : opportunityWrappers) {
        if (mapOpportunities.containsKey(objWrapper.objOppty.accountId) && !mapOpportunities.get(objWrapper.objOppty.accountId).IsEmpty() ) {
            if (userHasPledgeAccess == false) {
                for (Opportunity obj : mapOpportunities.get(objWrapper.objOppty.accountId)) {
                    if (obj.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId()) {
                        objWrapper.showOpenPledgeIcon = true;
                        break;
                    }
                }
            }
            else{objWrapper.showOpenPledgeIcon = true;}
        }
    }
  }

  public void populateChildShowPledges () {
    populatePledgeBooleanMap(true);
  }

  public String parentOppId {get; set;} //change
  public void populateChildOpportunityWrapper() {//change
    hasClicked = true;
    childOppWrapperLst = new List<OpportunityWrapper>();

    parentOppId = String.valueOf(ApexPages.currentPage().getParameters().get('parentOppId'));
    // TODO: Is this query selective?
    String query = 'SELECT ';
    // 3-27 james commented this section out   SObjectType.Opportunity.FieldSets.Soft_Credit_FieldSet is not valid
    for (Schema.FieldSetMember f : SObjectType.Opportunity.FieldSets.Soft_Credit_FieldSet.getFields()) {
      query += f.getFieldPath() + ', ';
    }

    query += 'Id, Batch_Log__c, Account.Account_Type__c, Program_Type__c, Opportunity.rC_Giving__Campaign_Source_Code__c, rC_Giving__Tribute_Type__c, Honoree_Title__c, Honoree_First_Name__c, Honoree_Middle_Name__c, Honoree_Last_Name__c, ';
    query += 'Honoree_Suffix__c, Non_Person__c, Tribute_Message_Body__c, Ack_Recipient_Account__c, Ack_Recipient_Account__r.Name, Ack_Recipient_Full_Name__c, Ack_Recipient_Street_Line_1__c,';
    query += 'Ack_Recipient_Street_Line_2__c, Posted_to_GL_Checkbox__c, rC_Giving__Transaction_Type__c, Ack_Recipient_City__c, Ack_Recipient_State__c, Campaign.Name, Ack_Recipient_Country__c, Ack_Recipient_Zip_Code__c, Recordtype.Name, ';
    query += ' Adjustment_Reason_Type__c, account.Name, account.Affiliation__c, Adjustment_Code__c, rC_Giving__Parent__c, Related_Transaction__c, rC_Giving__Current_Giving_Amount__c, Recipient_Acknowledgment_Code__c, ';
    query += ' rC_Giving__Source_Code__c, rC_Giving__Last_Giving_Amount_Adjustment_Date__c, Recipient_Acknowledgement_Status__c, Proposal__r.Name, rC_Giving__Parent_Name__c';
    query += ' FROM Opportunity WHERE ((rC_Giving__Parent__c = \'' + parentOppId + '\' AND RecordType.Name = \'Soft Credit\') OR (RecordType.Name = \'Pledge Payment\' AND Related_Transaction__r.rC_Giving__Parent__c= \'' + parentOppId + '\' ))';

    if (isAdjustBatch) {
      //query += ' AND Related_Transaction__c = '+'\''+adjustedTransactionId+'\'';
      query += ' AND Adjustment_Code__c != \'A\'';
      query += ' AND Adjustment_Code__c != \'B\'';
    }
    Integer count = 0;
    for (Opportunity objOppty : Database.query(query)) {
      childOppWrapperLst.add(new OpportunityWrapper(objOppty, count + 1, false, false, false,isAdjustBatch));
      setSoftCreditAccountIds.add(objOppty.accountId);
      count = count + 1; // Maintaining Total Record countsts.
    }
    populateOpenPledges(childOppWrapperLst, null);

    populateChildShowPledges();
  }

  public pagereference  checkRecordType() {
    String recTypeId = ApexPages.currentPage().getParameters().get('RecordType') != null ? ApexPages.currentPage().getParameters().get('RecordType'): batchLogRtMap.get('Manual').getRecordTypeId();
    String retURL = ApexPages.currentPage().getParameters().get('retURL');
    String ent = ApexPages.currentPage().getParameters().get('ent') != null ? ApexPages.currentPage().getParameters().get('ent'): System.Label.BatchLogObjectId;
    String editMode = ApexPages.currentPage().getParameters().get('e');
    populateBatchPrefWrapper();

    if(recTypeId != batchLogRtMap.get('Manual').getRecordTypeId()) {
      return new PageReference('/' + objPrefix + '/e?nooverride=1&RecordType=' + recTypeId + '&retURL=' + retURL + '&ent=' + ent + 'id=');
    } else if (editMode == '1') {
      if (!isReleased) {
        editBatchLog();
      }
      isActionEdit = true;
      listRetURL = retURL;
    }
    return null;
  }

  // Method to Export Batch Item Rows through 'Export Batch Items' Button.
  public PageReference exportBatchItems() {
    String fieldValue;
    for (OpportunityWrapper opptyWrapper : opportunityWrapperLst) {
      fieldValue = '';
      for (BatchPreferenceWrapper prefWrapper : selectedBatchPrefWrapperLst) {
        if (prefWrapper.fieldApiName == Label.Opportunity_RecordType_API_Name) {
          fieldValue = opptyWrapper.selectedRT;
        } else if (prefWrapper.fieldApiName == Label.Opportunity_Account_API_Name) {
          fieldValue = opptyWrapper.accountName.escapeCsv();
        } else if (prefWrapper.fieldApiName == Label.Opportunity_Campaign_API_Name) {
          fieldValue = String.isNotBlank(opptyWrapper.campaignName) ? opptyWrapper.campaignName.escapeCsv(): opptyWrapper.campaignName;
        } else if (prefWrapper.fieldApiName == Label.Opportunity_Selected_Payment_Method_API_Name) {
          fieldValue = opptyWrapper.objOppty.rC_Giving__Payment_Method_Selected__r.Name;
        } else {
          fieldValue = String.ValueOf(opptyWrapper.objOppty.get(prefWrapper.fieldApiName));
        }
        opptyWrapper.csvRecord =
          (opptyWrapper.csvRecord == null || opptyWrapper.csvRecord == '')
          ? (fieldValue != null ? fieldValue : ' ')
          : opptyWrapper.csvRecord + ',' + (fieldValue != null ? fieldValue : '');
      }
    }

    return Page.BatchItemsCsvExportPage;
  }

  // Method To Add Opportunity Rows.
  public void addRows() {
    OpportunityWrapper objWrapper = new OpportunityWrapper(new Opportunity(RecordTypeId = OPP_RT_DONATION_ID), count + 1, batchSeq + 1, false, false, batchLog, true, sourceCde, progtype, isAdjustBatch);//Added RecordtypeId = Donation Id(I-300335)
    opportunityWrapperLst.add(objWrapper);
    ImoaccountName = null;
    count = count + 1;
    batchSeq = batchSeq + 1;
  }

  //Method used to prevent the default form submit on click of enter button
  public void dummy() {}

  // Method To Delete Opportunity Row.
  public PageReference deleteRow() {
    opptyWrapperToDelete.Clear();
    List<Opportunity> delOppRow = new List<Opportunity>();
    List<Opportunity> scDeleteLst = new List<Opportunity>();
    List<Opportunity> oppUpdateLst = new List<Opportunity>();
    Integer splitNum = 0;
    OpportunityWrapper parentOppWrapper;
    Boolean hasMoreChildren = false;
    Boolean reduceBatchSeq = true;
    Integer rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
    OpportunityWrapper opptyToDelete = opportunityWrapperLst.get(rowIndex - 1);
    Integer tempBatchSeq = Integer.valueOf(opptyToDelete.objOppty.Batch_Sequence__c);
    Integer tempSplitSeq = Integer.valueOf(opptyToDelete.objOppty.Split_Sequence__c);
    isError = false;

    opptyWrapperToDelete.add(opptyToDelete);
    opportunityWrapperLst.remove(rowIndex - 1);

    for (OpportunityWrapper opp : opportunityWrapperLst) {
      // Other rows in the current batch sequence, to reset their split sequences
      if (Integer.valueOf(opp.objOppty.Batch_Sequence__c) == tempBatchSeq ) {
        reduceBatchSeq = false;
        // Make sure the deleted row is not the split parent row
        if (tempSplitSeq != null && tempSplitSeq != 1) {
          // Get reference of the split parent wrapper
          if (opp.objOppty.Split_Sequence__c == null || opp.objOppty.Split_Sequence__c == 1) {
            parentOppWrapper = opp;
            splitNum = 1;
          }
          // Reset the split sequence for all the split children
          else {
            opp.objOppty.Split_Sequence__c = splitNum + 1;
            oppUpdateLst.add(opp.objOppty);
            splitNum = splitNum + 1;
            hasMoreChildren = true;
          }
        }
      }
      // For the batches after the current batch sequence, to reset their batch sequences, only if there are no more rows in the current batch sequence
      else if (reduceBatchSeq && Integer.valueOf(opp.objOppty.Batch_Sequence__c) > tempBatchSeq) {
        opp.objOppty.Batch_Sequence__c = String.valueOf(Integer.valueOf(opp.objOppty.Batch_Sequence__c) - 1);
        oppUpdateLst.add(opp.objOppty);
      }
    }

    // Update split sequence of the split parent of the row being deleted
    if (parentOppWrapper != null) {
      if (hasMoreChildren) {
        parentOppWrapper.objOppty.Split_Sequence__c = 1;
        parentOppWrapper.isSplitParent = true;
      } else {
        parentOppWrapper.objOppty.Split_Sequence__c = null;
        parentOppWrapper.isSplitParent = false;
      }
      oppUpdateLst.add(parentOppWrapper.objOppty);
    }

    // delete
    for (OpportunityWrapper wrapper : opptyWrapperToDelete) {
      wrapper.objOppty.Batch_Log__c = null;
      wrapper.objOppty.IsCreatedFromBatchLog__c = false;
      if (wrapper.objOppty.Id != null) {
        if (wrapper.objOppty.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID) {
          // IHO/IMO Information making null
          wrapper.objOppty.rC_Giving__Tribute_Type__c = null;
          wrapper.objOppty.Honoree_Title__c = null;
          wrapper.objOppty.Honoree_First_Name__c = null;
          wrapper.objOppty.Honoree_Middle_Name__c = null;
          wrapper.objOppty.Honoree_Last_Name__c = null;
          wrapper.objOppty.Honoree_Suffix__c = null;
          wrapper.objOppty.Non_Person__c = null;
          wrapper.objOppty.Recipient_Acknowledgment_Code__c = null;
          wrapper.objOppty.Recipient_Acknowledgement_Status__c = null;
          wrapper.objOppty.Tribute_Message_Body__c = null;
          wrapper.objOppty.Ack_Recipient_Full_Name__c = null;
          wrapper.objOppty.Ack_Recipient_Street_Line_1__c = null;
          wrapper.objOppty.Ack_Recipient_Street_Line_2__c = null;
          wrapper.objOppty.Ack_Recipient_City__c = null;
          wrapper.objOppty.Ack_Recipient_State__c = null;
          wrapper.objOppty.Ack_Recipient_Country__c = null;
          wrapper.objOppty.Ack_Recipient_Zip_Code__c = null;
          wrapper.objOppty.Ack_Recipient_Outside_Salutation__c = null;
          //wrapper.objOppty.Ack_Recipient_Account__c = null;
          wrapper.objOppty.Ack_Recipient_Account_Number__c = null;
        }

        delOppRow.add(wrapper.objOppty);
      }
    }

    if (delOppRow.isEmpty()) {
      refreshOppt();
    } else {
      Savepoint beforeSaving;
      try {
        // Create a savepoint to prevent partial DML updates
        beforeSaving = Database.setSavePoint();
        // DML to avoid StageOpenForUnreleasedBatchLog Validation Rule to fire.
        update delOppRow;

        // Soft Credit Delete
        // TODO: Is this query selective?
        for (Opportunity scOppty : [SELECT Id, Batch_Log__c FROM Opportunity WHERE rC_Giving__Parent__c = : opptyToDelete.objOppty.Id AND RecordTypeId = : OPP_RT_SOFT_CREDIT_ID]) {
          scDeleteLst.add(scOppty);
        }

        // Separate Delete DML for SC as deletion of this is updating parent and which cannot be deleted simulatenously in this dml
        if (scDeleteLst.size() > 0) {
          childOppWrapperLst.clear();
          delete scDeleteLst;
        }

        // DML to Delete Batch Line Item Row. shouldN't delete the PledgePayment Record.
        if (delOppRow[0].RecordTypeId != OPP_RT_PLEDGE_PAYMENT_ID) {
          delete delOppRow;
        }

        // DML to update the batch and split sequences of other rows
        if (!oppUpdateLst.isEmpty()) {
          update oppUpdateLst;
        }

        refreshOppt();

        batchLog.Actual_Count__c = batchSeq;
        batchLog.Actual_Amount__c = 0;
        for (OpportunityWrapper objWrapper : opportunityWrapperLst) {
          //batchLog.Actual_Amount__c += amount(objWrapper, isAdjustBatch);
          batchLog.Actual_Amount__c += getOriginalAmount(objWrapper.objOppty,isPledgePayment(objWrapper), isAdjustBatch);
        }
        setBatchLogStatus();
        update batchLog;

        return null;
      } catch (exception e) {
        Database.rollback(beforeSaving);
        // Todo: improve the error handling A LOT
        // Todo: show the error number in the message
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
        isError = true;
        Exceptionutils.createApexLog('BatchLogDetailPageController','deleteRow',e);
        return null;
      }
    }
    return null;
  }

  public void saveOneRow() {
    Boolean receivedError = saveOpportunities(new OpportunityWrapper[] {activeOpportunity});
  }

  //Updates the Recacalculation Boolean on Child records sai-7/28:change
  public void updateRecalcBooleanFlag(Set<Id> parentOppIds){
    List<Opportunity> childOpps = new List<Opportunity>();
    //LIMIT 10000 as Total no of records Processed is 10000.
    for(Opportunity opp: [SELECT Id FROM Opportunity WHERE rC_Giving__Parent__c=:parentOppIds OR Related_Transaction__r.rC_Giving__Parent__c =: parentOppIds LIMIT 10000]){
      opp.Recalculate_Revenue_Share__c = true;
      childOpps.add(opp);
    }
    if(!childOpps.IsEmpty()){
      update childOpps;
    }
  }

  // Method To Save Opportunity Rows.
  public Boolean saveOpportunities(OpportunityWrapper[] opportunityWrappers) {
    errorInBatchRow = isError = false;
    saveHappened = false;
    activeOpportunityIsNew = true;
    activeOpportunityRecId = null;
    activeOpportunityCampaignId = null;

    // Initialize variables
    Double actualCount;
    String accName;
    Set<Id> recalParentOppIds = new Set <Id>();
    Map<Integer, Opportunity> oppsForSelectedPayment = new Map<Integer, Opportunity>();
    List<Opportunity> opportunityLst = new List<Opportunity>();
    Map<Integer, Set<Id>> oppReccountvsCmpProducts = new Map<Integer, Set<Id>>();
    List<opportunity> updateAmountonChild = new List<Opportunity>();
    Set<Id> opptyToUpdate = new Set<Id>();
    Decimal totalFees = 0;
    Decimal totalNetAmount = 0;
    // Process each gift line
    for (OpportunityWrapper objWrapper : opportunityWrappers) {
        totalFees += objWrapper.objOppty.Fees__c == null ? 0 : objWrapper.objOppty.Fees__c;
        totalNetAmount += objWrapper.objOppty.Net_Amount__c == null ? 0 : objWrapper.objOppty.Net_Amount__c;
        opptyToUpdate.add(objWrapper.objOppty.id);
      setGivingFrequency(objWrapper);
      setBookableIfPledge(objWrapper);
      processOpportunityForSaving(objWrapper);
      if ( oppForSelectedPayment(objWrapper) ) {
        oppsForSelectedPayment.put(objWrapper.recCount, objWrapper.objOppty);
      } else {
        opptyLst.put(objWrapper.recCount, objWrapper.objOppty);
      }

      //Recalculate SharingCode sai-7/28:change.
      if(objWrapper.objOppty.campaignId != campaignId_Old || amount(objWrapper, isAdjustBatch) != amount_Old){
        if(! isPledgePayment(objWrapper) && objWrapper.objOppty.Id != null){
          recalParentOppIds.add(objWrapper.objOppty.Id);
        }
        else{
          if(objWrapper.objOppty.rC_Giving__Parent__c != null){
            recalParentOppIds.add(objWrapper.objOppty.rC_Giving__Parent__c);
          }
        }

        //Fund Fields re-Populate based on Updated Campaign
        if(!string.isempty(campaignId_Old) && objWrapper.objOppty.campaignId != campaignId_Old && (objWrapper.objOppty.id != null)){ //Mounica V : Added this check as part of BGE-61.
        objWrapper.objOppty.Fundraising_Department__c = null;
        objWrapper.objOppty.Account_Code__c = null;
        if(objWrapper.objOppty.Id != null) {//To override fund from campaign when campiagn is updated : I-298739
            objWrapper.objOppty.Fund__c = null;
           }
         }
      }

      // sets the amount to child record.
      if(amount(objWrapper, isAdjustBatch) != amount_Old && objWrapper.selectedRT == ACLU_Constants.CONST_RCDTYPE_DONATION && objWrapper.objOppty.Id != null){
        updateAmountonChild.add(objWrapper.objOppty);
      }

      //Calculate the Tax Value.
      // Tax value = ((High_Amount__c+Low_Amount__c)/2)*rC_Giving__Number_Of_Shares__c
      //Commented below code by Bhavesh, written this code in OpportunityTriggerHandler.T-647782
      /*if(objWrapper.objOppty.Low_Amount__c != null && objWrapper.objOppty.High_Amount__c != null
            && objwrapper.objOppty.rC_Giving__Number_Of_Shares__c != null && objwrapper.objOppty.Tax_Value__c == null){

          objWrapper.objOppty.Tax_Value__c = (((objWrapper.objOppty.High_Amount__c + objWrapper.objOppty.Low_Amount__c)/2)*objwrapper.objOppty.rC_Giving__Number_Of_Shares__c ).setScale(2);
      }*/

      //Populate Original Amount
      if(objWrapper.objOppty.Adjustment_Sequence__c == null) {
          objWrapper.objOppty.Original_Amount__c = objWrapper.objOppty.rC_Giving__Giving_Amount__c;
      }
    }

    List<rC_Bios__Relationship__c> relationships = extractRelationships(opportunityWrappers);

    Set<Id> paymentMethodIds = getPaymentMethods(opportunityWrappers);
    if (paymentMethodIds.size() > 0) {
      //setPaymentMethods(paymentMethodIds, opptyLst);
    }

    for( OpportunityWrapper objWrapper : opportunityWrapperLst ){
        if( !opptyToUpdate.contains(objWrapper.objOppty.id)){
            totalFees += objWrapper.objOppty.Fees__c == null ? 0 : objWrapper.objOppty.Fees__c;
            totalNetAmount += objWrapper.objOppty.Net_Amount__c == null ? 0 : objWrapper.objOppty.Net_Amount__c;
        }
    }
    //System.assert(false, '===='+totalNetAmount+totalFees);
    Savepoint beforeSaving;
    try {
      beforeSaving = Database.setSavePoint();
      if (oppsForSelectedPayment != null &&
        !oppsForSelectedPayment.IsEmpty()) {
        opptyLst.putAll( populateSelectedPaymentMethod(oppsForSelectedPayment) );
      }

      if ( !opportunityIsValid(opptyLst.values())) {
        return errorInBatchRow = isError = true;
      } else if ( !opptyLst.isEmpty() ) {
        upsert opptyLst.values();
        batchLog.Total_Net_Amount__c = totalNetAmount != 0 ? totalNetAmount : batchLog.Total_Net_Amount__c;
        batchLog.Total_Fees__c = totalFees != 0 ? totalFees : batchLog.Total_Fees__c;
        ImoaccountName=null;
        activeOpportunityRecId = opptyLst.values()[0].Id;
        activeOpportunityCampaignId = opptyLst.values()[0].campaignId;
        activeOpportunityIsNew = opportunityWrappers[0].isNew;

        if (relationships.size() > 0) {
          insert relationships;
        }
        /* Mounica v, BGE-41 : Inserting a credit record if the Account is populated and soft credit type is populated */
        if(activeOpportunityRecId <> null && !String.IsBlank(newCredit.rC_Giving__Account__c)&& !String.IsBlank(newCredit.Soft_Credit_Type__c)){

          if(newCredit.rC_Giving__Opportunity__c == null)
          newCredit.rC_Giving__Opportunity__c = activeOpportunityRecId;
          upsert newCredit;

          newCredit = new rC_Giving__Opportunity_Credit__c();
          newCredit.rC_Giving__Distribution__c = 100.0;
          newCredit.rC_Giving__Type__c = 'Account Only';
          newCredit.Payment_Issuer__c = batchLog.Default_Payment_Issuer__c;

        }//BGE-41 END
        Integer tempBatchSeq, tempSplitSeq;
        for (OpportunityWrapper objWrapper : opportunityWrappers) {
          if (objWrapper.isNew && objWrapper.objOppty.Split_Sequence__c > 1) {
            tempBatchSeq = Integer.ValueOf(objWrapper.objOppty.Batch_Sequence__c);
            tempSplitSeq = Integer.valueOf(objWrapper.objOppty.Split_Sequence__c);
          }
        }

        // Update the split parent to set its split sequence to 1 when the split parent doesn't have any other split children
        if (tempBatchSeq != null) {
          Boolean hasOtherChildren = false;
          Opportunity splitParent;
          for (OpportunityWrapper objWrapper : opportunityWrapperLst) {
            if (Integer.ValueOf(objWrapper.objOppty.Batch_Sequence__c) == tempBatchSeq && objWrapper.objOppty.Split_Sequence__c == 1) {
              splitParent = objWrapper.objOppty;
            }
            if (Integer.ValueOf(objWrapper.objOppty.Batch_Sequence__c) == tempBatchSeq
              && objWrapper.objOppty.Split_Sequence__c > 1 && objWrapper.objOppty.Split_Sequence__c != tempSplitSeq) {
              hasOtherChildren = true;
              break;
            }
          }
          if (splitParent != null && !hasOtherChildren) {
            update splitParent;
          }
        }

        if(!recalParentOppIds.IsEmpty()){
            updateRecalcBooleanFlag(recalParentOppIds);
        }

        if(!updateAmountonChild.isEmpty()){
            updateAmountOnChild(updateAmountonChild);
        }
            //copySharingFieldsToChild(opptyLst.values()[0]);

        opptyLst = new Map<Integer, Opportunity>();
        updatedRows = new Set<Integer>();
        saveHappened = true;
      }
      isEdit = false;
    }
   catch (exception e) {
      Database.rollback(beforeSaving);
      if (e.getTypeName() == 'System.DmlException') {
         if(string.ValueOf(e.getDmlMessage(0)).contains('Defined Payment Processor Litle') ||
            string.ValueOf(e.getDmlMessage(0)).contains('rC_Connect.PaymentMethod')){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
          Label.Deposit_Site_not_configured));
         }
         else if(string.ValueOf(e.getDmlMessage(0)).contains('You do not have permission to use a campaign')){
             // to hide this message on page. using debug statment
             // since this error is coming from trigger automatically showing on Page.
         }
         else{
            for (Integer row = 0; row < e.getNumDml(); row++) {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
                Label.Exception_error_message));
            }
         }
      } else {
        // Todo: improve the error handling A LOT
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
          Label.Exception_error_message));
      }
      Exceptionutils.createApexLog('BatchLogDetailPageController','saveRows',e);
      return errorInBatchRow = isError = true;
    }
    return errorInBatchRow;
  }

  public void updateAmountOnChild(List<opportunity> opps){
      List<opportunity> updateAmount = new List<Opportunity>();
      for(Opportunity opp: [SELECT Id,rC_Giving__Parent__c, rC_Giving__Parent__r.rC_Giving__Giving_Amount__c FROM Opportunity
                                            WHERE rC_Giving__Parent__c=:opps AND (recordtype.name = 'Transaction')]){
          opp.amount = opp.rC_Giving__Parent__r.rC_Giving__Giving_Amount__c;
          updateamount.add(new Opportunity( Id = opp.rC_Giving__Parent__c, rC_Giving__Expected_Giving_Amount__c = opp.rC_Giving__Giving_Amount__c));
          updateAmount.add(opp);
      }

      if(!updateAmount.isEmpty()){
          update updateAmount;
      }
  }

  //Set Bookable if Pledge
  public void setBookableIfPledge(OpportunityWrapper objOpptyWrapper){
    if(objOpptyWrapper.selectedRT == ACLU_Constants.CONST_RCDTYPE_PLEDGE){
      objOpptyWrapper.objOppty.rC_Giving__Is_Bookable__c = true;
    }
  }

  //Giving Frequency defualt to 'One Payment' if it is null for Donation/Pledge
  public void setGivingFrequency(OpportunityWrapper objOpptyWrapper){
     //if(String.IsBlank(objOpptyWrapper.objOppty.rC_Giving__Giving_Frequency__c) && !objOpptyWrapper.isPledgePaymentRecord){
    objOpptyWrapper.objOppty.rC_Giving__Giving_Frequency__c = 'One Payment';
     //}
  }

  //set batchLogStatus
  public void setBatchLogStatus(){
     //Set batchLog status
    if(batchLog.Expected_Count__c == batchLog.Actual_Count__c && batchLog.Expected_Amount__c == batchLog.Actual_Amount__c){
      batchLog.Batch_Log_Status__c = 'Pending';
    }
    else{
      batchLog.Batch_Log_Status__c = 'Open';
    }
  }

  // Method To Update CampaignId on SoftCredits
  public void updateCampaignOnSoftCredits(Id parentRecId, Id campaignIdToUpdate){
    List<Opportunity> updateSoftCredits = new List<Opportunity>();
    for(Opportunity objOppty: fetchSoftCreditRecs(parentRecId)){
      objOppty.campaignId = campaignIdToUpdate;
      updateSoftCredits.add(objOppty);
    }
    if(!updateSoftCredits.IsEmpty()){
      update updateSoftCredits;
    }
  }

  // Helper methods for Opportunity saving
  public static Boolean isPledgePayment(OpportunityWrapper objWrapper) {
    return objWrapper.selectedRT == ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT;
  }

  public static Boolean amountIsZero(OpportunityWrapper objWrapper, Boolean isadjustBatchType) {
    Boolean specificRecordType =
      isPledgePayment(objWrapper) ||
      objWrapper.selectedRT == ACLU_Constants.CONST_RCDTYPE_DONATION ||
      objWrapper.selectedRT == ACLU_Constants.CONST_RCDTYPE_PLEDGE;
    return specificRecordType && amount(objWrapper, isadjustBatchType) == 0;
  }

  public static Boolean amountIsZero(Opportunity objOppty, Boolean isadjustBatchType) {
    Boolean isPledgePayment =
      (objOppty.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID);
    return amount(objOppty, isPledgePayment, isadjustBatchType) == 0;
  }

  public static Double amount(OpportunityWrapper objWrapper, Boolean isadjustBatchType) {
    return amount(objWrapper.objOppty, isPledgePayment(objWrapper), isadjustBatchType);
  }

  public static Double amount(Opportunity opp, Boolean isPledgePayment, Boolean isadjustBatchType) {
    isPledgePayment = isPledgePayment || opp.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID;

    if(!isadjustBatchType){
        if (isPledgePayment) {
          return opp.amount == null
            ? 0.0
            : opp.amount;
        } else {
          return opp.rC_Giving__Giving_Amount__c == null
            ? 0.0
            : opp.rC_Giving__Giving_Amount__c;
        }
    }else{
        return opp.rC_Giving__Current_Giving_Amount__c;
    }
  }

  public static Double getOriginalAmount(Opportunity opp, Boolean isPledgePayment, Boolean isadjustBatchType) {
        isPledgePayment = isPledgePayment || opp.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID;

        if(!isadjustBatchType){
            if (isPledgePayment || opp.recordTypeId == OPP_RT_Adjustment) {
              return opp.amount == null
                ? 0.0
                : opp.amount;
            } else {
              return opp.Original_Amount__c == null
                ? 0.0
                : opp.Original_Amount__c;
            }
        }else{
            return opp.rC_Giving__Current_Giving_Amount__c;
        }
  }
  public static Set<Id> getPaymentMethods(OpportunityWrapper[] opportunityWrapperLst) {
    Set<Id> paymentMethodIds = new Set<Id>();
    //Code to populate Batch Payment Method
    for (OpportunityWrapper objWrapper : opportunityWrapperLst) {
      Id paymentMethod = objWrapper.objOppty.rC_Giving__Payment_Method_Selected__c;
      if (paymentMethod != null) {
        paymentMethodIds.add(paymentMethod);
      }
    }
    return paymentMethodIds;
  }

  public Boolean oppForSelectedPayment(OpportunityWrapper objWrapper) {
    return (objWrapper.objOppty.accountId != null
        &&  objWrapper.objOppty.rC_Giving__Payment_Method__c != null
        && (
          objWrapper.objOppty.rC_Giving__Payment_Method_Selected__c == null
          || (
            updatedRows.Contains(objWrapper.recCount)
            && objWrapper.objOppty.rC_Giving__Payment_Method__c != 'EFT'
            && objWrapper.objOppty.rC_Giving__Payment_Method__c != 'Charge Card')));
  }

  public void processOpportunityForSaving(OpportunityWrapper objWrapper) {
    if (objWrapper.isNew) {
      objWrapper.objOppty.RecordTypeId = opptyRTMap.get(objWrapper.selectedRT).getRecordTypeId();
      /*if (objWrapper.selectedRT == ACLU_Constants.CONST_RCDTYPE_PLEDGE) {
        objWrapper.objOppty.Bank_Date__c = null;
      }*///commented for I-302969

      if (amountIsZero(objWrapper, isAdjustBatch)) {
        // errors for the user interface are added later in opportunityIsValid()
        errorInBatchRow = isError = true;
        return;
      }
    }

    if (isPledgePayment(objWrapper)) {
      objWrapper.objOppty.rC_Giving__Transaction_Type__c = ACLU_Constants.CONST_TRANSACTYPE_PAYMENT;
    }

    //collectCampaignProducts(objWrapper);
  }

  public Boolean matchingAccount(Opportunity oppty) {
    return oppty.rC_Giving__Matching_Account__c != null
      && oppty.rC_Giving__Matching_Status__c == ACLU_Constants.CONST_MATCHING_STATUS_POTENTIAL
      && (!copyOpptyWrapperLst.containsKey(oppty.Id)
        || ( copyOpptyWrapperLst.get(oppty.Id).matchingAccId != oppty.rC_Giving__Matching_Account__c ));
  }

  public List<rC_Bios__Relationship__c> extractRelationships(OpportunityWrapper[] opportunityWrapperLst) {
    Map<String, Id> uniqueKeyToAccMap = new Map<String, Id>();
    Set<Id> matchingAccSet = new Set<Id>();
    List<rC_Bios__Relationship__c> relationships = new List<rC_Bios__Relationship__c>();
    Set<String> relationshipUniqueKey = new Set<String>();

    for (OpportunityWrapper objWrapper : opportunityWrapperLst) {
      // We are including the logic to loop through the opportunity again here to make the logic clearer
      Opportunity oppty = objWrapper.objOppty;
      if (matchingAccount(oppty)) {
        uniqueKeyToAccMap.put(oppty.AccountId + '-' + oppty.rC_Giving__Matching_Account__c, oppty.AccountId);
        matchingAccSet.add(oppty.rC_Giving__Matching_Account__c);
      }
    }

    // Create Relationship record for Matching Account
    if (!uniqueKeyToAccMap.isEmpty()) {
      // Is this query selective? Yes, Account_1 and Account_2 are indexed
      for (rC_Bios__Relationship__c objRelationp : [
        SELECT rC_Bios__Role_1__c, rC_Bios__Role_2__c,
            rC_Bios__Account_1__c, rC_Bios__Account_2__c
          FROM rC_Bios__Relationship__c
          WHERE rC_Bios__Role_1__c = :ACLU_Constants.CONST_ROLE1_EMPLOYEE
            AND rC_Bios__Role_2__c = :ACLU_Constants.CONST_ROLE2_EMPLOYER
            AND rC_Bios__Category__c = :ACLU_Constants.CONST_CATEGORY_EMPLOYMENT
            AND rC_Bios__Account_1__c IN :uniqueKeyToAccMap.values()
            AND rC_Bios__Account_2__c IN :matchingAccSet]) {
        relationshipUniqueKey.add(
          objRelationp.rC_Bios__Account_1__c + '-' +
          objRelationp.rC_Bios__Account_2__c);
      }

      for (String uKey : uniqueKeyToAccMap.keySet()) {
        if (!relationshipUniqueKey.contains(uKey)) {
          relationships.add(
            new rC_Bios__Relationship__c(
              rC_Bios__Account_1__c = uKey.substringBefore('-'),
              rC_Bios__Account_2__c = uKey.substringAfter('-'),
              rC_Bios__Role_1__c = ACLU_Constants.CONST_ROLE1_EMPLOYEE,
              rC_Bios__Role_2__c = ACLU_Constants.CONST_ROLE2_EMPLOYER,
              rC_Bios__Category__c = ACLU_Constants.CONST_CATEGORY_EMPLOYMENT));
        }
      }
    }
    return relationships;
  }

  // Method to Match Opportunity
  public void matchOpportunity() {
    List<Opportunity> opportunityLst = new List<Opportunity>();
    List<Opportunity> softCreditLst = new List<Opportunity>();
    Integer opptyIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('matchOpptyIndex'));
    Opportunity oppty = opportunityWrapperLst.get(opptyIndex - 1).objOppty;
    Opportunity relTransaction;

    ApexPages.currentPage().getParameters().put('parentOppId', oppty.Id);
    populateChildOpportunityWrapper();
    //populateChildShowPledges();
    Integer count = childOppWrapperLst.size();

    // Fetch Related Transaction Of Donation
    if (oppty.RecordTypeId == OPP_RT_DONATION_ID) {
      //Assuming Donation will always have 1 Transaction only.
      // TODO: Is this query selective?
      relTransaction = [SELECT Id FROM Opportunity WHERE RecordTypeId = : OPP_RT_TRANSACTION AND rC_Giving__Parent__c = : oppty.Id LIMIT 1];
    } else if (oppty.RecordTypeId == OPP_RT_PLEDGE_PAYMENT_ID) {
      relTransaction = oppty;
    }

    // TODO: Is this query selective?
    for (Opportunity objOppty : [
          SELECT Id, rC_Giving__Parent__c, AccountId, Amount, CampaignId, Campaign.Name,
            rC_Giving__Matching_Account__c, CloseDate, Account.Account_Type__c,
            RecordType.Name, rC_Giving__Giving_Amount__c
          FROM Opportunity
          WHERE rC_Giving__Matching_Account__c = : oppty.AccountId
            AND rC_Giving__Matching_Status__c = : ACLU_Constants.CONST_MATCHING_STATUS_POTENTIAL
            AND (RecordType.Name = : ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT
              OR RecordType.Name = : ACLU_Constants.CONST_RCDTYPE_DONATION)]) {
      OpportunityWrapper objWrapper = new OpportunityWrapper(new Opportunity(), count + 1, false, false, true,isAdjustBatch);
      objWrapper.objOppty.AccountId = objOppty.AccountId;
      objWrapper.objOppty.Name = 'Dummy Name';// Will be updated by Workflow Rule.
      objWrapper.objOppty.rC_Giving__Parent__c = oppty.Id;
      objWrapper.objOppty.rC_Giving__Hard_Credit_Account__c = oppty.AccountId;
      objWrapper.objOppty.CloseDate = oppty.CloseDate;
      objWrapper.objOppty.StageName = oppty.StageName;
      objWrapper.objOppty.RecordTypeId = OPP_RT_SOFT_CREDIT_ID;
      objWrapper.objOppty.Related_Transaction__c = relTransaction.Id;
      objWrapper.campaignName = objOppty.Campaign.Name;
      objWrapper.objOppty.CampaignId = objOppty.CampaignId;
      objWrapper.objOppty.IsCreatedFromBatchLog__c = true;
      objWrapper.objOppty.Amount =
        objOppty.RecordType.Name == ACLU_Constants.CONST_RCDTYPE_DONATION
        ? objOppty.rC_Giving__Giving_Amount__c
        : objOppty.Amount;
      if (oppty.Account.Account_Type__c == ACLU_Constants.CONST_ACCTYPE_MATCHING_COMPANY) {
        objWrapper.objOppty.Soft_Credit_Type__c = ACLU_Constants.CONST_SCTYPE_MATCHING_CONT;
      } else if (oppty.Account.Account_Type__c == ACLU_Constants.CONST_ACCTYPE_WORKPLACE_GIVING_ORG) {
        objWrapper.objOppty.Soft_Credit_Type__c = ACLU_Constants.CONST_SCTYPE_WORKPLACE_GIVING;
      }
      childOppWrapperLst.add(objWrapper);
      softCreditLst.add(objWrapper.objOppty);
      objOppty.rC_Giving__Matching_Status__c = ACLU_Constants.CONST_MATCHING_STATUS_MATCHED;
      objOppty.Has_Soft_Credits__c =true;
      opportunityLst.add(objOppty);
      count += 1;
    }
    populateOpenPledges(childOppWrapperLst, null);

    Savepoint beforeSaving;
    try{
        beforeSaving = Database.setSavePoint();
        if(!softCreditLst.isEmpty()){
            insert softCreditLst;
        }

        if (opportunityLst.size() > 0) {
          update opportunityLst;
        }

        hasClicked = true;
        refreshOppt();
    }catch(exception e){
        Database.rollback(beforeSaving);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
        Exceptionutils.createApexLog('BatchLogDetailPageController','matchOpportunity',e);
        errorInBatchRow = isError = true;
    }
  }

  public void setOpenPledgeIcon() {
      if( activeOpportunity != null ){
          activeOpportunity.showOpenPledgeIcon = true;
      }

  }

  // Verifies the Payment Method and Sub Payment Method fields are not null
  public Boolean opportunityIsValid (List<Opportunity> oppsToUpsert) {

    Boolean isValid = true;
    for (Opportunity opp : oppsToUpsert) {
      String rowName = '';
      if (rowName(opp) != rowName(activeOpportunity.objOppty)) {
        rowName = rowName(opp) + ': ';
      }
      if (String.IsBlank(opp.AccountId)) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + ACCOUNT_REQUIRED));
      }
       /* Mounica V: BGE -71, validation to make sure share code override is cheked when a value is populated in share code text box and Vice versa (applies for sharing Entity also) */
       if (String.IsBlank(opp.Sharing_Code__c) && opp.Sharing_Code_Override__c) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + SHARECODE_REQUIRED));
      }
       if (!String.IsBlank(opp.Sharing_Code__c) && !opp.Sharing_Code_Override__c) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + SHARECODEOVERRIDE_REQUIRED));
      }
       if (String.IsBlank(opp.Sharing_Entity__c) && opp.Sharing_Entity_Override__c) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + SHAREENTITY_REQUIRED));
      }
       if (!String.IsBlank(opp.Sharing_Entity__c) && !opp.Sharing_Entity_Override__c) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + SHAREENTITYOVERRIDE_REQUIRED));
      } // BGE -71 END
       /* Mounica V: BGE-41, validation to mandate soft credit type on credit object when soft credit account is popuated and vice versa*/
      if (!String.IsBlank(newCredit.rC_Giving__Account__c) && String.IsBlank(newCredit.Soft_Credit_Type__c)) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + SOFTCREDITTYPE_REQUIRED));
      }
       if (String.IsBlank(newCredit.rC_Giving__Account__c) && !String.IsBlank(newCredit.Soft_Credit_Type__c)) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + SOFTCREDITACCOUNT_REQUIRED));
      } // BGE-41 END
      if (opp.recordTypeId != OPP_RT_PLEDGE_PAYMENT_ID
          && String.IsBlank(opp.CampaignId)) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + CAMPAIGN_REQUIRED));

      }
      if (String.IsBlank(opp.rC_Giving__Payment_Method__c)) {
        isValid = false;
        opp.rC_Giving__Payment_Method__c.addError(rowName + PAYMENT_METHOD_REQUIRED);

      }
      if (isPsRequired(opp.rC_Giving__Payment_Method__c) &&
            String.IsBlank(opp.Payment_Subtype__c)) {
        isValid = false;
        opp.Payment_Subtype__c.addError(rowName + PAYMENT_SUBTYPE_REQUIRED);

      }
      if (amountIsZero(opp,isAdjustBatch)) {
        isValid = false;
        opp.rC_Giving__Giving_Amount__c.addError(rowName + NO_ZERO_DOLLAR_GIFTS);
        opp.Amount.addError(rowName + NO_ZERO_DOLLAR_GIFTS);

      }
      // TributeType Required if any of IMO fields are populated
      //Sai:7/6-Change
      if(String.IsBlank(opp.rC_Giving__Tribute_Type__c)) {
        String[] nonBlankFields = new String[]{};
        Boolean tributeValid = true;
        if (String.IsNotBlank(opp.Ack_Recipient_Account__c)) {
          nonBlankFields.add('Ack Recipient Account Number');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Honoree_Title__c)) {
          nonBlankFields.add('Honoree Title');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Honoree_First_Name__c)) {
          nonBlankFields.add('Honoree First Name');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Honoree_Middle_Name__c)) {
          nonBlankFields.add('Honoree Middle Name');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Honoree_Last_Name__c)) {
          nonBlankFields.add('Honoree Last Name');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Honoree_Suffix__c)) {
          nonBlankFields.add('Honoree Suffix');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Non_Person__c)) {
          nonBlankFields.add('Non-person');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Recipient_Acknowledgment_Code__c)) {
          nonBlankFields.add('Recipient Acknowledgement Code');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Recipient_Acknowledgement_Status__c)) {
          nonBlankFields.add('Recipient Acknowledgement Status');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Tribute_Message_Body__c)) {
          nonBlankFields.add('Tribute Message Body');
          tributeValid = false;
        }
        if (String.IsNotBlank(opp.Ack_Recipient_Full_Name__c)) {
          nonBlankFields.add('Ack Recipient Full Name');
          tributeValid = false;
        }

        if (!tributeValid) {
          isValid = false;
          String tributeError = rowName + TRIBUTE_TYPE_REQUIRED +
            ' since there are values in the field(s) ' +
            String.join(nonBlankFields,', ');
          opp.rC_Giving__Tribute_Type__c.addError(tributeError);

        }
      }
/* Ana Ferreira - Feb 18th
BGE-75 validate payment issuer's presence before save
 */
        List<String>recognitionCreditType = new List<String>();
        recognitionCreditType.add('Online Platform');
        recognitionCreditType.add('Matching Contribution');
        recognitionCreditType.add('Workplace Giving');

      if(recognitionCreditType.contains(newCredit.Soft_Credit_Type__c) &&  String.IsBlank(newCredit.payment_issuer__c) ){
          isValid = false;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rowName + CREDITRECOGNITIONTYPE));
      }
//        End - BGE-75

      if(opp.RecordTypeId == OPP_RT_PLEDGE_ID && (opp.rC_Giving__Payment_Method__c != 'Other' || opp.Payment_Subtype__c != 'Pledge')) {
        opp.rC_Giving__Payment_Method__c.addError(rowName + PLEDGE_PAYMENT_METHOD_ERROR);
        isValid = false;
      }
    }
    return isValid;
  }

  // Do Nothing.
  public void None() {

  }

  // Method To Save Batch Log Record.
  public PageReference saveBatchLog() {
    isError = false;
    /* Ana Ferreira Feb 5th
    BGE-57 populate Batch Date/ Bank Date/ Tax Date */
     if(batchLog.Bank_Date__c == null && batchLog.Tax_Date__c == null){
        batchLog.Batch_Date__c =   (batchLog.Batch_Date__c !=null) ? batchLog.Batch_Date__c : Date.today();
        batchLog.Tax_Date__c =  (batchLog.Batch_Date__c !=null) ? batchLog.Batch_Date__c : Date.today();
    }else
        if(batchLog.Tax_Date__c != null && batchLog.Bank_Date__c == null){
            batchLog.Bank_Date__c = null;
            batchLog.Tax_Date__c =  batchLog.Tax_Date__c;
        }
    if(batchLog.Tax_Date__c == null && batchLog.Bank_Date__c != null){
        batchLog.Tax_Date__c = batchLog.Batch_Date__c ;
    }
    if (batchLogInvalid) {
      return null;
    } else {
      try {
        if (batchLog.Id == null) {
          batchLog.Affiliation__c = affiliateCode;
          batchLog.Accounting_Date__c = batchLog.Batch_Date__c;
          batchLog.Batch_Type__c = batchType;
          if (batchProgramType == 'U') {
            batchLog.Program_Type__c = '1';
          } else {
            batchLog.Program_Type__c = '4';
          }
        }

        if (String.isBlank(String.ValueOf(batchLogCampaignName)) && (batchLog.Default_Campaign__c != null)) {//Sai-7/9: LabelChange
          batchLog.Default_Campaign__c = null;
        }
        if( batchLog.BatchLog_Has_Fees__c == FALSE ){
            if( batchLog.Total_Fees__c != NULL && batchLog.Total_Net_Amount__c != NULL ){
                batchLog.Total_Fees__c = batchLog.Expected_Amount__c - batchLog.Total_Net_Amount__c;
            } else if( batchLog.Total_Fees__c == NULL && batchLog.Total_Net_Amount__c != NULL ){
                batchLog.Total_Fees__c = batchLog.Expected_Amount__c - batchLog.Total_Net_Amount__c;
            } else if( batchLog.Total_Fees__c != NULL && batchLog.Total_Net_Amount__c == NULL ){
                batchLog.Total_Net_Amount__c = batchLog.Expected_Amount__c - batchLog.Total_Fees__c;
            }
        }
        upsert batchLog;

      } catch (DMLException e) {
        // Todo: improve the error handling A LOT
        // Todo: show the error number in the message
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
        isError = true;
        Exceptionutils.createApexLog('BatchLogDetailPageController','saveBatchLog',e);
        return null;
      }
      // TODO: there is a hard-coded ID here for "ent".
      // It doesn't seem to be used and won't work in other orgs
      PageReference pg = new PageReference('/apex/BatchLogDetailPage?RecordType=' + batchLogRtMap.get('Manual').getRecordTypeId() + '&retURL=' + '%2F' + objPrefix + '%2Fo' + '&ent=' + '01IW00000005Nmu' + '&id=' + batchLog.Id);
      pg.setRedirect(true);
      return pg ;
    }
  }

  // Method To Edit Batch Log Record.
  public PageReference editBatchLog() {
    isEdit = true;
    isActionEdit = false;
    return null;
  }
  /*
    Ana Ferreira - Traction - Feb 12
    BGE-58 Warning Message
   */
    public PageReference checkBatchLogWarning(){
        isError = false;
        batchLogInvalid = false;
        warningsBatchLogString = '';
        warningsBatchLog = new List<String>();

        if (batchLog.Expected_Count__c == null) {
            batchLog.Expected_Count__c.addError(COUNT_ERROR);
            batchLogInvalid = true;
        }
        if (batchLog.Expected_Amount__c == null) {
            batchLog.Expected_Amount__c.addError(AMOUNT_ERROR);
            batchLogInvalid = true;
        }
        if(batchLog.Deposit_Site__c == null){
            batchLogInvalid = true;
            batchLog.Deposit_Site__c.addError(BATCHLOGDEPOSIT_ERROR);
        }
        if(batchProgramType == null){
            batchLogInvalid = true;
            batchLog.Program_Type__c.addError(PROGRAMTYPE_ERROR);
        }

        if (!batchLogInvalid){

            if(batchProgramType == 'U' && batchLog.Deposit_Site__c.containsIgnoreCase('natf') ){
                warningsBatchLog.add('Program Type is incorrect for deposit site choosen');
            }
            if(batchProgramType == 'F' && batchLog.Deposit_Site__c.containsIgnoreCase('natu') ){
                warningsBatchLog.add('Program Type is incorrect for deposit site choosen');
            }
            if(!String.isBlank(affiliateCode) && affiliateCode.startsWithIgnoreCase('na') && !batchLog.Deposit_Site__c.startsWithIgnoreCase('na')  ){
                warningsBatchLog.add('You have chosen an Affiliate deposit site');
            }
            if(!String.isBlank(affiliateCode) && !affiliateCode.startsWithIgnoreCase('na') && batchLog.Deposit_Site__c.startsWithIgnoreCase('na')  ){
                warningsBatchLog.add('You have chosen a National deposit site');
            }

            if(!String.isBlank(batchLog.Default_Payment__c)&& batchLog.Deposit_Site__c.startsWithIgnoreCase('na')){
                if (String.valueof(batchLog.Default_Payment__c).equals('Cash/Check')&&
                   (!batchLog.Deposit_Site__c.containsIgnoreCase('chk') && !batchLog.Deposit_Site__c.containsIgnoreCase('cash') && !batchLog.Deposit_Site__c.containsIgnoreCase('check'))) {
                    warningsBatchLog.add('You have chosen a mismatched Payment Method');
                }
                if (batchLog.Default_Payment__c == 'Charge Card' && !batchLog.Deposit_Site__c.containsIgnoreCase('cc')) {
                    warningsBatchLog.add('You have chosen a mismatched Payment Method');
                }
                if (batchLog.Default_Payment__c == 'EFT' && !batchLog.Deposit_Site__c.containsIgnoreCase('eft')  ) {
                    warningsBatchLog.add('You have chosen a mismatched Payment Method');
                }
                if (batchLog.Default_Payment__c == 'Other' && batchLog.Payment_Subtype__c == 'Wire Transfer' && !batchLog.Deposit_Site__c.containsIgnoreCase('wiretransfer')) {
                    warningsBatchLog.add('You have chosen a mismatched Payment Method');
                }
                if (batchLog.Default_Payment__c == 'Other' && batchLog.Payment_Subtype__c == 'Apple Pay' && !batchLog.Deposit_Site__c.containsIgnoreCase('applepay')) {
                    warningsBatchLog.add('You have chosen a mismatched Payment Method');
                }
                if (batchLog.Default_Payment__c == 'Paypal' && !batchLog.Deposit_Site__c.containsIgnoreCase('paypal')) {
                    warningsBatchLog.add('You have chosen a mismatched Payment Method');
                }
            }
            for(String warning: warningsBatchLog){
                warningsBatchLogString += warning +'\\n';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, warning));
            }

        }
        return null;
    }
    // END BGE-58

  // Method To Cancel Edits on the Batch Log Screen.
  public PageReference cancelBatchLog() {
    if (isEdit || isError) {
      isEdit = false;
      isError = false;
      // TODO: there is a hard-coded ID here for "ent".
      // It doesn't seem to be used and won't work in other orgs
      if (isActionEdit && String.isNotBlank(listRetURL)) {
        return new PageReference(listRetURL);
      } else {
        PageReference pg = new PageReference('/apex/BatchLogDetailPage?RecordType=' + batchLogRtMap.get('Manual').getRecordTypeId() + '&retURL=' + '%2F' + objPrefix + '%2Fo' + '&ent=' + '01IW00000005Nmu' + '&id=' + batchLog.Id);
        pg.setRedirect(true);
        return pg ;
      }
    } else {
      if (String.isNotBlank(listRetURL)) {
        return new PageReference(listRetURL);
      } else {
        return new PageReference('/' + objPrefix);
      }
    }
  }

  //check validity for batch log release
  public Boolean checkBatchLogReleaseValidity(){
    Boolean isError = false;
    if (   batchLog.Actual_Count__c == null
        || batchLog.Expected_Count__c == null
        || batchLog.Actual_Count__c != batchLog.Expected_Count__c) {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, COUNT_MISMATCH_ERROR);
      ApexPages.addMessage(myMsg);
      isError = true;
    }
    if (   batchLog.Actual_Amount__c == null
        || batchLog.Expected_Amount__c == null
        || batchLog.Actual_Amount__c.setScale(2) != batchLog.Expected_Amount__c.setScale(2)) {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, AMOUNT_MISMATCH_ERROR);
      ApexPages.addMessage(myMsg);
      isError = true;
    }
    if (!depositSitesMatch()) {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, DEPOSIT_SITE_MISMATCH);
      ApexPages.addMessage(myMsg);
      isError = true;
    }
    if (!softCreditAmountsMatch(false)) {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.BGEFoct_Credit_Amount_Do_Not_Match.replace ( '#',batchSequenceInError));
      ApexPages.addMessage(myMsg);
      isError = true;
    }
    return isError;
  }
  // Method to Release Batch Log Record.
  public PageReference releaseBatchLog() {
    isError = checkBatchLogReleaseValidity();
    //String oppsWithBadBankDates = oppsWithBadBankDates();
    /*if ( String.isNotBlank(oppsWithBadBankDates) ) {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, BANK_DATE_INVALID +
        ' The following batch items have invalid dates: ' + oppsWithBadBankDates);
      ApexPages.addMessage(myMsg);
      isError = true;
    }*///commented for T-647275

    if ( !isError ) {
        Boolean asyncReq = IsAsyncProcessingRequired(batchLog.Actual_Count__c);
        if( asyncReq ){
            batchLog.Error_Details__c = 'Processing';
        } else {
            batchLog.Error_Details__c = null;
        }
        batchLog.Has_Error_Details__c = false;
      batchLog.Batch_Log_Status__c = 'Balanced';

      update batchLog;
      if( asyncReq ){
          DataBase.executeBatch(new ReleaseBatchLog_Batch(batchLog.Id, userInfo.getUserEmail()), 40);
      }
      isReleased = true;
      reportAdjustURL ='/'+label.Batch_Log_Detail_Adjust_Report+'?pv='+batchLog.Name+'&pv='+batchLog.Name;
       //BGE-84 Fix report adjustment detail link after release batch
       return new PageReference('/' + batchLog.Id);
    }

   return null;
  }

  // Method to update Error Detail when batch log is flagged.
  public PageReference updateErrorDetailToFlagged() {
    list<Opportunity> oppList = [SELECT Id, rC_Giving__External_ID__c , stagename
                                        FROM Opportunity
                                        WHERE Batch_Log__c = :batchLogId
                                        AND rC_Giving__External_ID__c = 'Flagged for MembershipShareCode Reset'];
    if(!oppList.isEmpty()) {
        batchLog.Error_Details__c = 'Processing status, please refresh the page.';
        update batchlog;
        //system.assert(false, batchLog.Batch_Log_Status__c);
    }

    return null;
    /*Batch_Log__c objLog = [Select Error_Details__c FROM Batch_Log__c where id =: batchLog.Id];
    batchLog.Error_Details__c = objLog.Error_Details__c;
    return null;*/
  }

  // Method to Re-Open Batch Log Record.
  public void reopenBatchLog() {
    if (isReleased) {
      batchLog.Batch_Log_Status__c = 'Open';
      update batchLog;
      isReleased = false;
    }
  }

  public void populateRecordType() {
    Integer recCount1 = Integer.ValueOf(
      Apexpages.currentPage().getParameters().get('recCount1'));
    Boolean isPledgePayment =
      (Apexpages.currentPage().getParameters().get('value') != null)
      ? Boolean.ValueOf(Apexpages.currentPage().getParameters().get('value'))
      : false;
    for (OpportunityWrapper wrapper : opportunityWrapperLst) {
      if (wrapper.recCount == recCount1) {
        wrapper.isPledgePaymentRecord = isPledgePayment;
        wrapper.objOppty.rC_Giving__Payment_Method__c = 'Other';
        wrapper.objOppty.Payment_Subtype__c = 'Pledge';
        if(wrapper.selectedRT == 'Pledge') {
          wrapper.objOppty.RecordTypeId = OPP_RT_PLEDGE_ID;
          checkProposalGrantsButton(wrapper.objOppty.accountId);
        }
      }
    }

  }

  //populate default ReciepientackStatusCode.
  public void defaultReciepientAckStatusCode (){
      if(activeOpportunity != null && activeOpportunity.objOppty.Ack_Recipient_Account__c != null
         && activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c == null){
          activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c = 'N - Not Acknowledged';
      }
  }

  // re-parents all soft Credits to the Pledge Payment Id
  public void reParentSoftCredits(Id parentRecId, Id pledgePaymentRecId){
      List<Opportunity> updateSoftCredits = new List<Opportunity>();
      for(Opportunity objOppty: fetchSoftCreditRecs(parentRecId)){

          objOppty.rC_Giving__Parent__c = pledgePaymentRecId;
          objOppty.Related_Transaction__c = pledgePaymentRecId;
          updateSoftCredits.add(objOppty);
      }

      if(!updateSoftCredits.IsEmpty()){
          update updateSoftCredits;
      }
  }

  // Fetch all Soft credit records. Max limit 50000 records
  public List<Opportunity> fetchSoftCreditRecs(Id parentRecId){
    return [
      SELECT Id,rC_Giving__Parent__c, Related_Transaction__c, campaignId
      FROM Opportunity
      WHERE
        (RecordType.Name = 'Soft Credit'
          AND rC_Giving__Parent__c =: parentRecId)
        OR(RecordType.Name = 'Soft Credit'
          AND rC_Giving__Parent__r.rC_Giving__Parent__c =: parentRecId)
        OR (RecordType.Name = 'Pledge Payment'
          AND Related_Transaction__r.rC_Giving__Parent__c=:parentRecId)
        OR (RecordType.Name = 'Pledge Payment'
          AND Related_Transaction__c=: parentRecId)
      LIMIT 50000];
  }

  // Updates the Parent Opp/changes the entire row
  public PageReference updateParent() {

    errorInBatchRow = isError = false;
    List<Opportunity> oppsToDel = new List<Opportunity>();
    Integer irow = Integer.ValueOf(Apexpages.currentPage().getParameters().get('row'));
    Id oppId = Id.valueOf(Apexpages.currentPage().getParameters().get('OpportId'));
    Boolean isOpenedFromSoftCreditTable = ApexPages.currentPage().getParameters().get('isOpenfromSft') != null ? Boolean.ValueOf(ApexPages.currentPage().getParameters().get('isOpenfromSft')) : false;
    Boolean isPledgePayment = Boolean.ValueOf(Apexpages.currentPage().getParameters().get('isPledgePayment'));
    Id parentRecId;
    Id pledgePaymentRecId = oppId;
    // TODO: Is this query selective?
    String dynamicQuery = 'SELECT ';
    List <Opportunity> oppsToUpdate = new List <Opportunity>();
    List <Opportunity> oppsToAdd = new List <Opportunity>();
    Id fetchOpp;

    // If PledgePayment then modify the current row as with the PledgePayment record
    if (isPledgePayment) {
      for (Schema.FieldSetMember f : labelFieldSet) {
        dynamicQuery += f.getFieldPath() + ', ';
      }
      dynamicQuery += 'Id, IsCreatedFromBatchLog__c, rC_Giving__Parent__r.rC_Giving__Source_Code__c, rC_Giving__Parent__r.CampaignIdText__c, rC_Giving__Parent__r.CampaignId ';
      dynamicQuery += 'FROM Opportunity WHERE Id=:oppId LIMIT 1';

      Opportunity childOpp = Database.query(dynamicQuery);
      for (OpportunityWrapper wrapper : opportunityWrapperLst) {
        if (wrapper.recCount == irow) {
          parentRecId = wrapper.objOppty.id;
          OpportunityTriggerHandler.IsSourceCodeUpdatedFromDonation = true;
          childOpp.Batch_Log__c = wrapper.objOppty.Batch_Log__c;
          childOpp.IsCreatedFromBatchLog__c = true;
          childOpp.Batch_Sequence__c = wrapper.objOppty.Batch_Sequence__c;
          childOpp.Split_Sequence__c = wrapper.objOppty.Split_Sequence__c;
          childOpp.Deposit_Site__c = batchLog.Deposit_Site__c;
          childOpp.CloseDate = (batchLog.Batch_Date__c != null) ? batchLog.Batch_Date__c : system.today();
          childOpp.Batch_Date__c = String.isBlank(String.ValueOf(wrapper.objOppty.Batch_Date__c)) ? batchLog.Batch_Date__c : wrapper.objOppty.Batch_Date__c;
          childOpp.Bank_Date__c = String.isBlank(String.ValueOf(wrapper.objOppty.Bank_Date__c)) ? batchLog.Bank_Date__c : wrapper.objOppty.Bank_Date__c;
          childOpp.Accounting_Date__c = String.isBlank(String.ValueOf(wrapper.objOppty.Accounting_Date__c)) ? batchLog.Accounting_Date__c : wrapper.objOppty.Accounting_Date__c;
          childOpp.rC_Giving__Payment_Method__c = wrapper.objOppty.rC_Giving__Payment_Method__c;
          childOpp.Payment_Subtype__c = wrapper.objOppty.Payment_Subtype__c;
          childOpp.rC_Giving__Payment_Method_Selected__c = wrapper.objOppty.rC_Giving__Payment_Method_Selected__c;
          childOpp.Tax_Date__c = wrapper.objOppty.Tax_Date__c;
          if(!String.isBlank(String.valueOf(wrapper.ObjOppty.CampaignId))) {
            childOpp.rC_Giving__Source_Code__c = [SELECT Id, rC_Giving__Source_Code__c FROM Campaign WHERE Id=: wrapper.objOppty.CampaignId LIMIT 1].rC_Giving__Source_Code__c;
            childOpp.CampaignIdText__c = wrapper.objOppty.CampaignId;
          } else if(String.isBlank(String.valueOf(childOpp.CampaignId))) {
            childOpp.rC_Giving__Source_Code__c = childOpp.rC_Giving__Parent__r.rC_Giving__Source_Code__c;
            childOpp.CampaignIdText__c = childOpp.rC_Giving__Parent__r.CampaignId;
          }
           /* Traction(Mounica V), BGE-63 : Assigning values to opportunity fields so that the values will not get wiped off on Attach Giving  */
          childOpp.rC_Giving__Check_Number__c = wrapper.objOppty.rC_Giving__Check_Number__c;
          childOpp.Description = wrapper.objOppty.Description;
          childOpp.rC_Giving__Check_Date__c = wrapper.objOppty.rC_Giving__Check_Date__c;
          childOpp.Account_Code__c = wrapper.objOppty.Account_Code__c;
          childOpp.Restriction__c = wrapper.objOppty.Restriction__c;
          childOpp.Fund__c = wrapper.objOppty.Fund__c;
          //BGE-63 END
          //Update the Pledge Payment record Payment Method .
          if (wrapper.ObjOppty.rC_Giving__Payment_Method__c == 'Cash/Check' && childOpp.rC_Giving__Payment_Method__c == 'Charge Card') {
            childOpp.rC_Giving__Payment_Method__c = wrapper.ObjOppty.rC_Giving__Payment_Method__c;
            childOpp.rC_Giving__Payment_Method_Selected__c = wrapper.ObjOppty.rC_Giving__Payment_Method_Selected__c;
          }
          // Ends
          //T-650370 start
          childOpp.Net_Amount__c = wrapper.objOppty.Net_Amount__c;
          childOpp.Fees__c = wrapper.objOppty.Fees__c;
          OpportunityTriggerHandler.donationConvertedToPledge = true;
          //T-650370 ends
          //I-305836 start
          //Populate Selected Payment Method on Pledge Payment if not set by donation (donation is not saved)
          if(childOpp.rC_Giving__Payment_Method_Selected__c == null) {
              populateSelectedPaymentMethod(new map<Integer, Opportunity>{wrapper.recCount => childOpp});
          }
          //I-305836 ends
          //GH-34 starts
          //system.debug('Source code override ' +  ActiveOpportunity.sourceCodeOverride);
          if ( ActiveOpportunity.sourceCodeOverride != null &&  ActiveOpportunity.sourceCodeOverride == TRUE) {
                childOpp.Source_Code_Override__c = TRUE;
          }
          //GH-34 ends
          wrapper.objOppty.Batch_Log__c = null;
          if (wrapper.objOppty.Id != null) {
            oppsToUpdate.add(wrapper.objOppty);
            oppsToDel.add(wrapper.objOppty);
          }
          wrapper.selectedRT = ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT;
          wrapper.objOppty = childOpp;
          wrapper.objOppty.recordTypeId = opptyRTMap.get(wrapper.selectedRT).getRecordTypeId();
          wrapper.isPledgePaymentRecord = true;
          //wrapper.objOppty = childOpp;
          oppsToUpdate.add(childOpp);
          fetchOpp = childOpp.Id;
        }
      }
    } else {
      for (OpportunityWrapper wrapper : opportunityWrapperLst) {
        if (wrapper.recCount == irow) {
          wrapper.objOppty.rC_Giving__Parent__c = oppId;
          if (wrapper.objOppty.Id != null) {
            oppsToUpdate.add(wrapper.objOppty);
          } else {
            oppsToAdd.add(wrapper.objOppty);
          }
        }
      }
    }
    //DML Operation
    Savepoint beforeSaving;
    try {
      beforeSaving = Database.setSavePoint();

      if(!oppsToAdd.IsEmpty()) {
        insert oppsToAdd;
      }

      if (!oppsToUpdate.IsEmpty()) {
          if(parentRecId != null && pledgePaymentRecId != null){
            reParentSoftCredits(parentRecId, pledgePaymentRecId);
          }
          system.debug('*** UPDATING OPPS TO UPDATE ***');
                    system.debug('*** oppsToUpdate Source_Code_Override__c  *** ' + oppsToUpdate[0]);

        update oppsToUpdate;
      }

      //update the Opportunities with batch Log field before Delete.
      if (!oppsToDel.isEmpty()) {
        delete oppsToDel;
      }

      refreshOppt();
      // Even if we're just saving one record we need to iterate through the
      // whole list to get the updated totals for the batchLog
      batchLog.Actual_Count__c = batchSeq;
      batchLog.Actual_Amount__c = 0;
      for (OpportunityWrapper objWrapper : opportunityWrapperLst) {
        //batchLog.Actual_Amount__c += amount(objWrapper, isAdjustBatch);
        batchLog.Actual_Amount__c += getOriginalAmount(objWrapper.objOppty,isPledgePayment(objWrapper), isAdjustBatch);
      }

      update batchLog;
      setBatchLogStatus();
    } catch (Exception e) {
      Database.rollback(beforeSaving);
      if (e.getTypeName() == 'System.DmlException') {
        for (Integer row = 0; row < e.getNumDml(); row++) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getDmlMessage(row)));
        }
      } else {
        // Todo: improve the error handling A LOT
        // Todo: show the error number in the message
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
      }
      Exceptionutils.createApexLog('BatchLogDetailPageController','updateParent',e);
      return null;
    }
    return null;
  }

  //Populate Fund Fields //5APR
  public void populateFund() {
    Integer campRow = Integer.ValueOf(Apexpages.currentPage().getParameters().get('campRow'));
    for (OpportunityWrapper wrapper : opportunityWrapperLst) {
      if (wrapper.recCount == (campRow + 1)) {
        // TODO: Is this query selective?
        List<Campaign> cmpRec = [SELECT Id, Fund__c, Fundraising_Department__c, Restriction__c FROM Campaign WHERE Id = : wrapper.objOppty.CampaignId LIMIT 1]; // This will run only once as we are matching with one OpportunityId in the List
        wrapper.objOppty.Restriction__c = String.IsNotBlank(wrapper.objOppty.Restriction__c)?cmpRec[0].Restriction__c:wrapper.objOppty.Restriction__c;
        wrapper.objOppty.Fundraising_Department__c = String.IsNotBlank(wrapper.objOppty.Fundraising_Department__c)?cmpRec[0].Fundraising_Department__c:wrapper.objOppty.Fundraising_Department__c;
        wrapper.objOppty.Fund__c = String.IsNotBlank(wrapper.objOppty.Fund__c)?cmpRec[0].Fund__c:wrapper.objOppty.Fund__c;
      }
    }
  }

  public void updatePaymentURL() {
    String accountId = ApexPages.currentPage().getParameters().get('accountId');
    String accId = opportunityWrapperLst.get(Integer.valueof(accountId) - 1).objOppty.AccountId;
    if (accId != null && accId != '' && accId != ' ') {

      // TODO: Is this query selective?
      Account acc = [SELECT Name FROM Account WHERE Id = :accId];
      String accName = acc.Name.replaceAll(' ', '+').replaceAll('&', '%26');
      destUrlToCreatePaymentMthd = System.URL.getSalesforceBaseUrl().toExternalForm() + '/setup/ui/recordtypeselect.jsp?' + 'CF' + System.Label.Payment_Method_Account_Field_Id
                                   + '=' + accName + '&CF' + System.Label.Payment_Method_Account_Field_Id + '_lkid=' + accId + '&ent=' + System.Label.PaymentMethodObjectId + '&retURL=%2F' + paymentKeyPrefix +
                                   '%2Fo&save_new_url=%2F' + paymentKeyPrefix + '%2Fe%3FretURL%3D%252F' + paymentKeyPrefix + '%252Fo';

    } else {
      destUrlToCreatePaymentMthd = System.URL.getSalesforceBaseUrl().toExternalForm() + '/setup/ui/recordtypeselect.jsp?ent=' + System.Label.PaymentMethodObjectId + '&retURL=%2F' + paymentKeyPrefix +
                                   '%2Fo&save_new_url=%2F' + paymentKeyPrefix + '%2Fe%3FretURL%3D%252F' + paymentKeyPrefix + '%252Fo';

    }
  }

  //Sai:7/6- change
  public void populateAckFields() {
    Map<Id, Account> billingAddressToAccMap = new Map<Id, Account>();
    String accNumber, accName ;
    if (activeOpportunity != null && activeOpportunity.objOppty != null && !String.isBlank(activeOpportunity.objOppty.Ack_Recipient_Account__c)) {
      // TODO: Is this query selective?
      for (Account acc : [SELECT Id, Name, Account_Number__c, rC_Bios__Preferred_Billing_Address__c, Formal_Outside_1__c
                          FROM Account
                          WHERE Id = : activeOpportunity.objOppty.Ack_Recipient_Account__c LIMIT 1]) {
        accNumber = acc.Account_Number__c;
        accName = acc.Name;
        if (!String.IsBlank(acc.rC_Bios__Preferred_Billing_Address__c)) {
          billingAddressToAccMap.put(acc.rC_Bios__Preferred_Billing_Address__c, acc);
        }
      }
      //If the account doesnt have Preferred Addres
      if (billingAddressToAccMap.keySet().ISEmpty() || billingAddressToAccMap.Keyset() == null) {
        activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = accName;
        activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c = null;
        activeOpportunity.objOppty.Ack_Recipient_Street_Line_2__c = null;
        activeOpportunity.objOppty.Ack_Recipient_City__c = null;
        activeOpportunity.objOppty.Ack_Recipient_State__c = null;
        activeOpportunity.objOppty.Ack_Recipient_Country__c = null;
        activeOpportunity.objOppty.Ack_Recipient_Zip_Code__c = null;
        activeOpportunity.objOppty.Ack_Recipient_Outside_Salutation__c = null;
        activeOpportunity.objOppty.Ack_Recipient_Account_Number__c = accNumber;
      }
      // TODO: Is this query selective?
      for (rC_Bios__Address__c objAddress : [SELECT Id, rC_Bios__Street_Line_1__c, rC_Bios__Street_Line_2__c, rC_Bios__City__c,
                                             rC_Bios__State__c, rC_Bios__Country__c, rC_Bios__Postal_Code__c
                                             FROM rC_Bios__Address__c
                                             WHERE Id = : billingAddressToAccMap.keySet()]) {
        activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = billingAddressToAccMap.get(objAddress.Id).Name;
        activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c = objAddress.rC_Bios__Street_Line_1__c;
        activeOpportunity.objOppty.Ack_Recipient_Street_Line_2__c = objAddress.rC_Bios__Street_Line_2__c;
        activeOpportunity.objOppty.Ack_Recipient_City__c = objAddress.rC_Bios__City__c;
        activeOpportunity.objOppty.Ack_Recipient_State__c = objAddress.rC_Bios__State__c;
        activeOpportunity.objOppty.Ack_Recipient_Country__c = objAddress.rC_Bios__Country__c;
        activeOpportunity.objOppty.Ack_Recipient_Zip_Code__c = objAddress.rC_Bios__Postal_Code__c;
        activeOpportunity.objOppty.Ack_Recipient_Outside_Salutation__c = billingAddressToAccMap.get(objAddress.Id).Formal_Outside_1__c;
        activeOpportunity.objOppty.Ack_Recipient_Account_Number__c = accNumber;
      }
    }
    defaultReciepientAckStatusCode();
  }

  public void deleteIHOValues() {
    if (activeOpportunity.objOppty != null ) {
      activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_2__c = null;
      activeOpportunity.objOppty.Ack_Recipient_City__c = null;
      activeOpportunity.objOppty.Ack_Recipient_State__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Country__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Zip_Code__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Outside_Salutation__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Account__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Account_Number__c = null;
      activeOpportunity.objOppty.rC_Giving__Tribute_Type__c = null;
      activeOpportunity.objOppty.Honoree_Title__c = null;
      activeOpportunity.objOppty.Honoree_First_Name__c = null;
      activeOpportunity.objOppty.Honoree_Middle_Name__c = null;
      activeOpportunity.objOppty.Honoree_Last_Name__c = null;
      activeOpportunity.objOppty.Honoree_Suffix__c = null;
      activeOpportunity.objOppty.Non_Person__c = null;
      activeOpportunity.objOppty.Recipient_Acknowledgment_Code__c = null;
      activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c = null;
      activeOpportunity.objOppty.Tribute_Message_Body__c = null;
      ImoaccountName = null;
    }
  }

  //AdjustementsCreated
  public Map<Id,Boolean> AdjustementsCreated(Set<Id> parentOpptyIds){
      Map<Id,Boolean> mapParentOpptyIdVsAdjustments = new  Map<Id,Boolean>();

      for(Opportunity  objOppty: [SELECT Id, rC_Giving__Parent__c FROM Opportunity WHERE (Adjustment_Code__c = 'A' OR Adjustment_Code__c = 'D') AND rC_Giving__Parent__c=: parentOpptyIds]){
        mapParentOpptyIdVsAdjustments.put(objOppty.rC_Giving__Parent__c, true );
      }
      return mapParentOpptyIdVsAdjustments;
  }

  public void adjustGivingProperties() {
    Map<String, Opportunity> codeToOpptyMap = new Map<String, Opportunity>();
    adjustmentOpptyUpdateLst = new List<Opportunity>();
    adjustmentOpptyLst = new List<Opportunity>();
    Opportunity AdjusteTransactionRec = new Opportunity();
    isAdjustementsCreated = false;
    parentOppty = null;
    OpportunityWrapper parentWrapper;
    Opportunity parentOpptyold = null;
    OpportunityWrapper parentWrapperold;
    Id adjustTransId;
    selectedOpptyForAdjustment = ApexPages.currentPage().getParameters().get('selectedOpptyForAdjustment') != null ?
                                 Integer.valueOf(ApexPages.currentPage().getParameters().get('selectedOpptyForAdjustment')) : 0;

     if (isAdjustBatch && selectedOpptyForAdjustment > 0) {
        parentWrapper = opportunityWrapperLst.get(selectedOpptyForAdjustment - 1);
        parentOppty = opportunityWrapperLst.get(selectedOpptyForAdjustment - 1).objOppty;
       // parentOppty.Adjustment__c = true;

        if(opportunityWrapperLst.size() > 1){
            parentWrapperold = opportunityWrapperLst.get(1);
            parentOpptyold = opportunityWrapperLst.get(1).objOppty;

        }
     }

    /* Modified By: Amar Kulkarni (rC) :: 07-Jun-18
     * Desc: TS-276/I-326264 - Adjustment Actual/Expected Count mismatch, cannot release
     * Problem: After refreshing the page user were not able to adjust but to create another D & B Transaction for the giving
    */
     if (!isAdjustementsCreated) {
        if(isTransactionAlreadyAdjusted()) {
            isAdjustementsCreated = true;
            AdjustmentCreatedOnce = true;
        }
     }
     //END: TS-276/I-326264
     system.debug('***adjustedTransactionId* '+  adjustedTransactionId); // the transaction we want to adjust
     system.debug('***adjustTransParentId* '+  adjustTransParentId);     // the donation
     system.debug('***parentOppty.Id* '+  parentOppty.Id);               // if a pledge payment, self; otherwise, the parent

     //GH-75: add OR condition of the parentOppty having been set to the transaction itself (Pledge Paymentd)
     if(adjustedTransactionId!= null &&
             (adjustTransParentId == parentOppty.Id || adjustedTransactionId == parentOppty.Id ||
             ( opportunityWrapperLst[0] != null &&  parentOppty.Id ==  opportunityWrapperLst[0].objOppty.id ))){
         if(!AdjustmentCreatedOnce){
            isAdjustementsCreated = false;
            showAdj_Save_Commit_btn = true;
            showAdj_CancelAdjust_btn = true;
            showAdj_Save_btn = false;
            showAdj_close_btn = false;
         }
         else{
            isAdjustementsCreated = true;
            showAdj_Save_Commit_btn = false;
            showAdj_CancelAdjust_btn = false;
            showAdj_Save_btn = true;
            showAdj_close_btn = true;
         }
     }
     else{
         if(opportunityWrapperLst.size() > 0 && opportunityWrapperLst.get(0).isAdjustementsCreated){
          isAdjustementsCreated = true;
          showAdj_CancelAdjust_btn = false;
          showAdj_Save_Commit_btn = false;
          showAdj_Save_btn = false;
          showAdj_close_btn = true;
       }else if(adjustedTransactionId == null) {
          isAdjustementsCreated = false;
          showAdj_CancelAdjust_btn = false;
          showAdj_Save_Commit_btn = false;
          showAdj_Save_btn = false;
          showAdj_close_btn = true;
       } else {
          isAdjustementsCreated = false;
          showAdj_CancelAdjust_btn = true;
          showAdj_Save_Commit_btn = false;
          showAdj_Save_btn = false;
          showAdj_close_btn = true;
       }
     }
/*   OLD
    if(!isAdjustementsCreated){
         Opportunity childOpp = [SELECT Id FROM Opportunity WHERE rC_Giving__Parent__c=:parentOppty.id
                                                            AND  (recordType.Name = 'Transaction' OR recordType.Name = 'Pledge Payment')
                                                            LIMIT 1];
         if(childOpp != null){
            adjustTransId = childOpp.Id;
         }
         if( adjustedTransactionId != NULL ){
             adjustTransId = adjustedTransactionId;
         }
     }
*/
     /* DS - GH-75 TRY   */
      if(!isAdjustementsCreated){
         List<Opportunity> childOpps = [SELECT Id FROM Opportunity WHERE rC_Giving__Parent__c=:parentOppty.id
                                                            AND  (recordType.Name = 'Transaction' OR recordType.Name = 'Pledge Payment')
                                                            LIMIT 1];
         if(childOpps.size() > 0){
            adjustTransId = childOpps[0].Id;
         }
         // FIX GH-75
         else if (parentOppty != null && parentOppty.Id != null) {
            adjustTransId = parentOppty.Id;
         }
         if( adjustedTransactionId != NULL ){
             adjustTransId = adjustedTransactionId;
         }
     }


     if(!isAdjustementsCreated && parentOppty != null && adjustTransId != null){

          String query = adjustmentQuery(batchLog.id, parentOppty.Id);
                 query+= ' WHERE Id =:adjustTransId LIMIT 1';

            List<Opportunity> objTransaction = database.query(query);
            system.debug('***DS*** objTrans ID ' + objTransaction[0].Id);
          for(Opportunity objOppty: BatchLogManager.createAdjustmentRecords(BatchLog, objTransaction[0])){
              if (objOppty.Adjustment_Code__c == 'D') {
                  campaignId_Old = objOppty.campaignIdText__c;
                  adjustmentOpptyUpdateLst.add(objOppty);
                  originalTransaction = objOppty;
              }
              objOppty.campaignId = objOppty.campaignIdText__c;
              adjustmentOpptyLst.add(objOppty);
          }
          recordsToCommit = true;

     }
     else{

        if (isAdjustBatch && parentOppty != null) {

            String query = 'SELECT ';
            for (Schema.FieldSetMember f : adjustmentFieldSet) {
                query += f.getFieldPath() + ', ';
            }
            query += ' Id, Name, Batch_Log__c, Campaign.Name, campaignIdText__c, Recordtype.Name, rC_Giving__Parent__c,Account.Original_Join_Date__c, Account.Last_Membership_Gift__r.CloseDate, Account.Last_Membership_Gift__c, ';
            query += ' rC_Giving__Source_Code__c , Batch_Sequence__c, Batch_Log__r.Name ';
            if(parentOpptyold ==  null){
                query += ' FROM Opportunity WHERE (Batch_log__c = ' + '\'' + batchLog.Id + '\' OR  Adjustment_Batch__c = ' + '\'' + batchLog.Id + '\' ) ' ;
            } else if (parentOpptyold != null){
                query += ' FROM Opportunity WHERE (Batch_log__c = ' + '\'' + batchLog.Id + '\' OR Adjustment_Batch__c = ' + '\'' + batchLog.Id + '\' ) AND (rC_Giving__Parent__c = ' + '\'' + parentOppty.Id + '\' OR rC_Giving__Parent__c = ' + '\'' + parentOpptyold.Id + '\')  ';
            query += ' AND (RecordType.Name = \'Pledge Payment\' OR RecordType.Name = \'Transaction\' OR RecordType.Name = \'Adjustment\')';
            query += ' AND (Adjustment_Code__c = \'A\' OR Adjustment_Code__c = \'B\' OR Adjustment_Code__c = \'D\')';
                query += ' ORDER BY LastModifiedDate DESC LIMIT 4';
            }
            for (Opportunity objOppty : Database.query(query)) {

                    if (objOppty.Adjustment_Code__c != 'D' || objOppty.amount > 0)
                        codeToOpptyMap.put(objOppty.Adjustment_Code__c, objOppty);
                    if (objOppty.Adjustment_Code__c == 'D' && objOppty.amount == 0) {
                        if(adjustTransParentId == parentOppty.Id){
                            adjustmentOpptyUpdateLst.add(objOppty);
                            codeToOpptyMap.put(objOppty.Adjustment_Code__c, objOppty);
                        } else {
                            originalDTransaction = objOppty.clone(true);
                            originalDTransaction.CampaignId = objOppty.CampaignId;
                            originalDTransaction.campaignIdText__c = objOppty.campaignIdText__c;
                        }
                    }
                    if (objOppty.Adjustment_Code__c == 'D' && objOppty.amount > 0) {
                       // objOppty.Adjustment__c = true;
                        objOppty.CampaignId = objOppty.campaignIdText__c;
                        adjustmentOpptyUpdateLst.add(objOppty);
                        originalTransaction = objOppty.clone(false, false, true, false);
                        originalTransaction.CampaignId = objOppty.CampaignId;
                    }else{
                        objOppty.campaignId = objOppty.campaignIdText__c;
                    }
                }

                // Creating Sorted List
                if (!codeToOpptyMap.isEmpty()) {
                    if(codeToOpptyMap.get('A')!= null)adjustmentOpptyLst.add(codeToOpptyMap.get('A'));
                    if(codeToOpptyMap.get('B')!= null) adjustmentOpptyLst.add(codeToOpptyMap.get('B'));
                    if(originalDTransaction!= null) adjustmentOpptyLst.add(originalDTransaction);
                    if(codeToOpptyMap.get('D')!= null) adjustmentOpptyLst.add(codeToOpptyMap.get('D'));
                }
        }
     }
  }

  //Calculate Actual Count and Amount for Adjustment batch
  public void calculateActualCounts_Amounts_Adjustmet(Boolean performDML){
      Integer Count= 0;
      Decimal totalAmount = 0;
      String query = '';
      Set<String> adjusmentCodList = new Set<String>{'B', 'D'};

      if(!performDML){
          adjusmentCodList.add('N');
      }

      query+= 'SELECT Id, Amount, rC_Giving__Giving_Amount__c, Adjustment_Code__c,IsCreatedFromBatchLog__c,Adjustment__c FROM Opportunity ';
      query+= ' WHERE (RecordType.Name = \'Transaction\' OR RecordType.Name = \'Pledge Payment\' OR RecordType.Name = \'Adjustment\' )';
      query+= ' AND (Adjustment_Code__c =:adjusmentCodList)';
      query+= ' AND (Adjustment_Batch__c =: batchLogId)';

      if(performDML || AdjustmentCreatedOnce){
        Integer lstSize = (opportunityWrapperLst!= null && !opportunityWrapperLst.isEmpty())?opportunityWrapperLst.size():0;
        count = (lstSize*2);
      }

      for(Opportunity oppty : Database.query(query)) {
          System.debug('>>>Query');
            Decimal amt = (oppty.Amount!= null)?oppty.Amount:0;
            if(!performDML && !AdjustmentCreatedOnce){
                count = count + 1;
            }
            totalAmount = totalAmount + amt;
        }
        batchLog.Expected_Count__c = Count;
        batchLog.Expected_Amount__c = totalAmount;
        if (isAdjustBatch){
            batchLog.Actual_Count__c = Count;
            batchLog.Actual_Amount__c = totalAmount;
        }
        if(performDML){
            batchLog.Actual_Count__c = Count;
            batchLog.Actual_Amount__c = totalAmount;

            update batchLog;
        }
  }

  public String adjustmentQuery(Id batchLogId, Id parentOpptyId){
        // TODO: Is this query selective?
      String query = 'SELECT ';
      for (Schema.FieldSetMember f : adjustmentFieldSet) {
        query += f.getFieldPath() + ', ';
      }
      query += ' Id, Name, Batch_Log__c, Campaign.Name, Recordtype.Name, RecordTypeId, ';

      if(!query.contains('Deposit_Site__c')){
        query+= ' Deposit_Site__c,';
      }
      if(!query.contains('campaignIdText__c')){
        query+= ' campaignIdText__c,';
      }
      if(!query.contains('Program_Type__c')){
        query+= ' Program_Type__c,';
      }
      if(!query.contains('Account_Affiliation__c')){
        query+= ' Account_Affiliation__c,';
      }
      if(!query.contains('rC_Giving__Giving_Amount__c')){
        query+= ' rC_Giving__Giving_Amount__c,';
      }
      if(!query.contains('Adjustment_Batch__c')){
        query+= ' Adjustment_Batch__c,';
      }
      if(!query.contains('IsCreatedFromBatchLog__c')){
        query+= ' IsCreatedFromBatchLog__c,';
      }
      if(!query.contains('Amount')){
        query+= ' Amount,';
      }
      if(!query.contains('CampaignId')){
        query+= ' CampaignId,';
      }
      if(!query.contains('rC_Giving__Payment_Method__c')){
        query+= ' rC_Giving__Payment_Method__c,';
      }
      if(!query.contains('AccountId')){
        query+= ' AccountId,';
      }
      if(!query.contains('StageName')){
        query+= ' StageName,';
      }
      if(!query.contains('CloseDate')){
        query+= ' CloseDate,';
      }
      if(query.contains('Last_Adjusted_Date__c')){
        query+= ' Last_Adjusted_Date__c,';
      }
      if(!query.contains('rC_Giving__Parent__c')){
        query+= ' rC_Giving__Parent__c,';
      }
      if(!query.contains('Adjustment_Sequence__c')){
        query+= ' Adjustment_Sequence__c,';
      }
      if(!query.contains('rC_Giving__Payment_Method_Selected__c')){
        query+= ' rC_Giving__Payment_Method_Selected__c,';
      }
      if(!query.contains('Adjustment_Code__c')){
        query+= ' Adjustment_Code__c,';
      }
      if(!query.contains('Adjustment__c')){
        query+= ' Adjustment__c,';
      }
      if(!query.contains('Batch_Sequence__c')){
        query+= ' Batch_Sequence__c,';
      }
      if(!query.contains('Batch_Date__c')){
        query+= ' Batch_Date__c,';
      }
      if(!query.contains('Sharing_Code__c')){
        query+= ' Sharing_Code__c,';
      }
      if(!query.contains('Sharing_Entity__c')){
        query+= ' Sharing_Entity__c,';
      }
      query += ' rC_Giving__Source_Code__c , Batch_Log__r.Name, Batch_Log__r.Id, Batch_Log__r.RecordTypeId  FROM Opportunity';

      return query;
  }

  //reset the AdjustmentBatch on child
  public void cancelAdjustment(){
      Id adjustTransId;
      Integer rowId ;
      if(!isAdjustementsCreated){
         if (parentOppty.Id != adjustedTransactionId) {
            Opportunity childOpp = [SELECT Id,rC_Giving__Parent__c,rC_Giving__Parent__r.Adjustment_Sequence__c FROM Opportunity WHERE rC_Giving__Parent__c=:parentOppty.id LIMIT 1];
            if(childOpp != null){
                adjustTransId = childOpp.Id;
            }

            rowId=Integer.ValueOf(childOpp.rC_Giving__Parent__r.Adjustment_Sequence__c);

            //Check whether the Parent record is already Adjusted/not.
            List<Opportunity> childOpps = [SELECT Id,rC_Giving__Parent__c,rC_Giving__Parent__r.Adjustment_Sequence__c FROM Opportunity WHERE rC_Giving__Parent__c=:parentOppty.id
                                                                AND  (Adjustment_Code__c = 'A')];
            if(childOpps != null && !childOpps.isEmpty() && childOpps.size()>0){
                isAdjustementsCreated = true;
            }
         }
         //GH-75: When adjusted Giving is a Pledge Payment, "parentOppty" is set to same as Oppty
         else {
            adjustTransId = adjustedTransactionId;
         }
      }
      Savepoint beforeSaving;
      if(adjustTransId != null){
          adjustmentCancellationInProgress = true;
          beforeSaving= Database.setSavePoint();
          try{
              update new Opportunity(Id=adjustTransId, Adjustment_Batch__c = null);
              if(isAdjustementsCreated && AdjustmentCreatedOnce == false){
                  AdjustmentCreatedOnce =true;
              }

              calculateActualCounts_Amounts_Adjustmet(false);
              //Should be call before the refreshOppty.
              recalculateAdjustSeq(rowId);
              refreshOppt();
              adjustmentCancellationInProgress = false;
              adjustmentCancelled = true;
              campaignId_Old = null;
          }
          catch(Exception e){
              Database.rollback(beforeSaving);

              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
              Exceptionutils.createApexLog('BatchLogDetailPageController','cancelAdjustment',e);
              errorInBatchRow = isError = true;
          }
      }
  }

  //recalculateAdjustSeq
  public void recalculateAdjustSeq(Integer rowIndex){
      List<Opportunity> updateAdjSeqOpps = new List<Opportunity>();
      for(OpportunityWrapper objWrapper: opportunityWrapperLst){

          if(objWrapper.objOppty.Adjustment_Sequence__c> rowIndex){
              Decimal adjSeqNo = objWrapper.objOppty.Adjustment_Sequence__c;
              objWrapper.objOppty.Adjustment_Sequence__c = (adjSeqNo!= null && adjSeqNo >0)?adjSeqNo-1:0;
              updateAdjSeqOpps.add(objWrapper.objOppty);
          }
      }

      if(!updateAdjSeqOpps.isEmpty()){
          update updateAdjSeqOpps;
      }
  }

    // Method To Check Errorsin Adjustment
    public void checkErrorInSaveAdjustment() {
        if( errorInBatchRow ){
            if( errorMsg != '' ){
                String errorMessage = errorMsg;
                Integer occurence;
                if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                    errorMessage = errorMessage.mid(occurence, errorMessage.length());
                    occurence = errorMessage.lastIndexOf(':');
                    errorMessage = errorMessage.mid(0, occurence);
                }
                else {
                    errorMessage = errorMsg;
                }
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
                ApexPages.addMessage(myMsg);
            }

        }

    }

  // Method To Save Giving Adjustment
  public void saveAdjustmentOppty() {
    errorMsg = '';
    List<Opportunity> softCreditsToUpdate = new List<Opportunity>();
    Boolean isUpdateSoftCredits = false;
    Double totalAmount = 0;
    Id updatedCampaignId = null, updatedAccountId = null;
    Integer Count = 0;
    Boolean reParentSoftCredits = false;
    errorInBatchRow = isError = false;
    Id updatedcampaignIdOnDRec = null;
    String sourceCodeUpdateCampaign;
    
      /* MV:BGE-107 Bypass the validation using custom setting */ 
            ByPassValidation__c oSkipValidation = ByPassValidation__c.getInstance();
            if(oSkipValidation == null) {
             oSkipValidation = new ByPassValidation__c();
             }
            oSkipValidation.Bypass__c = true;
             upsert oSkipValidation;
        
    for(Opportunity objOppty : adjustmentOpptyLst) {
        system.debug('*** DEBUG DS *** objOppty.ID ' + objOppty.ID);
        system.debug('*** DEBUG DS *** objOppty.Adjustment_Code__c ' + objOppty.Adjustment_Code__c);
        system.debug('*** DEBUG DS *** objOppty.recordtypeid ' + objOppty.recordtypeid);

       if(objOppty != null && objOppty.Adjustment_Code__c == 'D' && (String.isBlank(objOppty.Adjustment_Reason_Type__c) ||
        String.isBlank(objOppty.Adjustment_Notes__c))) {
            errorInBatchRow = true;
            errorMsg = 'Adjustment Reason Type and Adjustment Notes Required';
            return;
        }
    }
    // TODO: Is this query selective?
    if(adjustmentOpptyUpdateLst.get(0).Id == null && adjustmentOpptyUpdateLst.get(0).rC_Giving__Parent__c != null){
        softCreditsToUpdate = fetchSoftCreditRecs(adjustmentOpptyUpdateLst.get(0).rC_Giving__Parent__c);
        reParentSoftCredits = true;
    }
    else{
        softCreditsToUpdate = fetchSoftCreditRecs(adjustmentOpptyUpdateLst.get(0).Id);
    }


    for (Opportunity objOppty : adjustmentOpptyLst) {
      if (objOppty != null && objOppty.Adjustment_Code__c == 'B') {
        totalAmount = objOppty.Amount != null ? totalAmount + objOppty.Amount : totalAmount;
      } else if (objOppty != null && objOppty.Adjustment_Code__c == 'D') {
        totalAmount = objOppty.Amount != null ? totalAmount + objOppty.Amount : totalAmount;
      }

      // updating the parentOppty amount fields
      if(objOppty != null && objOppty.Adjustment_Code__c == 'D' ){
          //I-323040 - Change should NOT commit to the pledge parent record when isBookable = FALSE
          if (parentOppty.RecordType.Name == 'Donation' || (parentOppty.RecordType.Name == 'Pledge' && parentOppty.rC_Giving__Is_Bookable__c)) {
              parentOppty.rC_Giving__Current_Giving_Amount__c = objOppty.amount;
              parentOppty.rC_Giving__Expected_Giving_Amount__c = objOppty.amount;
              parentOppty.rC_Giving__Closed_Amount__c = objOppty.amount;
              parentOppty.rC_Giving__Giving_Amount__c = objOppty.amount;
              //Update the ParentCampaignId if the D record Campaign changes
              if(campaignId_Old  != objOppty.campaignId && objOppty.recordType.Name == ACLU_Constants.CONST_RCDTYPE_TRANSACTION){
                parentOppty.campaignId= objOppty.campaignId;
              }
              //Update Acknowledgement Fields on parent Oppty - I-313455
              parentOppty.Acknowledgment_Status__c = objOppty.Acknowledgment_Status__c != null ?
                                                        objOppty.Acknowledgment_Status__c :
                                                        parentOppty.Acknowledgment_Status__c;
              parentOppty.Acknowledgment_Code__c = objOppty.Acknowledgment_Code__c != null ?
                                                        objOppty.Acknowledgment_Code__c :
                                                        parentOppty.Acknowledgment_Code__c;
              parentOppty.rC_Giving__Acknowledged_Date__c = objOppty.rC_Giving__Acknowledged_Date__c != null ?
                                                        objOppty.rC_Giving__Acknowledged_Date__c :
                                                        parentOppty.rC_Giving__Acknowledged_Date__c;
              parentOppty.Restriction__c = objOppty.Restriction__c; //I-317317
          }
          if(campaignId_Old  != objOppty.campaignId && objOppty.recordType.Name == ACLU_Constants.CONST_RCDTYPE_TRANSACTION){
                updatedcampaignIdOnDRec = objOppty.campaignId;
          }
      }
      //I-323040 - Update source code if campaign is change on adjustment
      if(objOppty.campaignIdText__c != objOppty.campaignId) {
          sourceCodeUpdateCampaign = objOppty.campaignId;
      }
      //populate the campaignIdtext field and remove the campaignId.
      objOppty.campaignIdText__c = objOppty.campaignId;
  //    objOppty.campaignId = null;
    }
    //Will run only if Campaign is changed on adjustment - I-323040
    String srcCode;
    if(sourceCodeUpdateCampaign != null) {
        srcCode = [SELECT rC_Giving__Source_Code__c FROM Campaign WHERE Id = :sourceCodeUpdateCampaign].rC_Giving__Source_Code__c;
    }
    for (Opportunity objOppty : adjustmentOpptyLst) {
        system.debug('*** DEBUG DS *** objOppty.ID ' + objOppty.ID);
        system.debug('*** DEBUG DS *** objOppty.Adjustment_Code__c ' + objOppty.Adjustment_Code__c);
        system.debug('*** DEBUG DS *** objOppty.recordtypeid ' + objOppty.recordtypeid);
      if (objOppty != null && objOppty.Adjustment_Code__c == 'D' && srcCode != null) {
          objOppty.rC_Giving__Source_Code__c = srcCode;
      }
    }
    Savepoint beforeSaving;
    try {

      for (Opportunity objOppty : adjustmentOpptyUpdateLst) {
        for (Schema.FieldSetMember f : adjustmentFieldSet) {
          if (originalTransaction!= null && objOppty.get(f.getFieldPath()) != originalTransaction.get(f.getFieldPath()) &&
              (objOppty.RecordType.Name == ACLU_Constants.CONST_RCDTYPE_TRANSACTION || objOppty.RecordType.Name == ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT  || objOppty.RecordType.Name == ACLU_Constants.CONST_RCDTYPE_ADJUSTMENT)) {
            if (f.getFieldPath() == Label.Opportunity_Restriction_API_Name || f.getFieldPath() == Label.Opportunity_Campaign_API_Name) {
              for (Opportunity sCredit : softCreditsToUpdate) {
                sCredit.put(f.getFieldPath(), objOppty.get(f.getFieldPath()));
                isUpdateSoftCredits = true;
              }
            }
            if (parentOppty.RecordType.Name == 'Donation' || (parentOppty.RecordType.Name == 'Pledge' &&
                parentOppty.rC_Giving__Is_Bookable__c)) {
              if (f.getFieldPath() == Label.Opportunity_Record_Amount_API_Name) {
                parentOppty.put(Label.Opportunity_Giving_Amount_API_Name, Double.ValueOf(objOppty.get(f.getFieldPath())));
              } else {
                parentOppty.put(f.getFieldPath(), objOppty.get(f.getFieldPath()));
                if (f.getFieldPath() == Label.Opportunity_Campaign_API_Name) {
                  updatedCampaignId = (Id)objOppty.get(f.getFieldPath());
                } else if (f.getFieldPath() == Label.Opportunity_Account_API_Name) {
                  updatedAccountId = (Id)objOppty.get(f.getFieldPath());
                }
              }
            }
            originalTransaction.put(f.getFieldPath(), objOppty.get(f.getFieldPath()));
          }
        }
      }

      if (updatedCampaignId != null) {
        // TODO: Is this query selective?
        for (Campaign camp : [SELECT Id, Name FROM Campaign WHERE Id = : updatedCampaignId]) {
          opportunityWrapperLst.get(selectedOpptyForAdjustment - 1).campaignName = camp.Name;
        }
      }

      if (updatedAccountId != null) {
        // TODO: Is this query selective?
        for (Account acc : [SELECT Id, Name FROM Account WHERE Id = : updatedAccountId]) {
          opportunityWrapperLst.get(selectedOpptyForAdjustment - 1).accountName = acc.Name;
        }
      }

      parentOppty.Last_Adjusted_Date__c = system.today();


      if (isUpdateSoftCredits) {
        adjustmentOpptyUpdateLst.addAll(softCreditsToUpdate);
      }
       /*BGE-84 - Reparent Opportunity on adjustment - Ana Ferreira*/
       for(Opportunity opp: adjustmentOpptyLst){
            if(opp.Adjustment_Code__c == 'D'){
                //BGE-84 Set values to new parent on adjustment
                newParentOppty = new Opportunity();
                newParentOppty = parentOppty.clone();
                newParentOppty.AccountId = opp.accountId;
                newParentOppty.CloseDate = opp.CloseDate;
                newParentOppty.StageName = 'Open';
                newParentOppty.campaignId = opp.CampaignId;
                newParentOppty.campaignId = (opp.campaignId==null) ? opp.CampaignIdText__c : opp.CampaignId;
                newParentOppty.campaignIdText__c = opp.CampaignIdText__c;
                newparentOppty.name ='';
                newparentOppty.rC_Giving__Payment_Method__c = opp.rC_Giving__Payment_Method__c;
                newparentOppty.Payment_Subtype__c = opp.Payment_Subtype__c;
                newparentOppty.rC_Giving__Payment_Method_Selected__c = opp.rC_Giving__Payment_Method_Selected__c;
            }
        }
//        #############################################
      if(adjustmentOpptyUpdateLst.get(0).Id == null){
          for(Opportunity opp: adjustmentOpptyLst){
            if(opp.Adjustment_Code__c != 'D'){
                adjustmentOpptyUpdateLst.add(opp);
            }

            if(opp.Adjustment_Code__c == 'D'){
                opp.Sharing_Code__c = '';
                opp.Sharing_Entity__c = '';
                opp.rC_Giving__External_ID__c = '';
                opp.New_Membership_Set_To_Date__c = NULL;
                opp.Sharing_Entity_Affiliation__c  = NULL;
                opp.Revenue_Affiliation__c = NULL;

                new BatchLogManager().BatchResetMembershipMethod(opp, true);
            }
        }
      }

      // Set a savepoint to prevent partial DML updates
      beforeSaving = Database.setSavePoint();
      if (adjustmentOpptyUpdateLst.size() > 0) {
        //#######################################################
        /*Ana Ferreira - Traction on Demand - Nov 26, 2019
        ASL-28 BGE-84 Reparent when adjustment created*/
        if(newParentOppty.accountId != parentOppty.accountId){

              List<Opportunity> reparentOpportunities = new List<Opportunity>();

              newParentOppty.IsCreatedFromBatchLog__c = True;
              newParentOppty.rC_Giving__Affiliation__c = parentOppty.rC_Giving__Affiliation__c;
              newParentOppty.rC_Giving__Giving_Amount__c = parentOppty.rC_Giving__Giving_Amount__c;
              newParentOppty.CloseDate = parentOppty.CloseDate;
              newParentOppty.RecordTypeId = parentOppty.RecordTypeId;
              newParentOppty.campaignId = parentOppty.CampaignId;
              newParentOppty.Adjustment_Batch__c = null;
              newParentOppty.batch_log__c = batchLog.Id;
              newParentOppty.rC_Giving__Giving_Frequency__c= parentOppty.rC_Giving__Giving_Frequency__c;

              List<Opportunity> newParent = new List<Opportunity>();
              newParent.add(newParentOppty);
              List<Database.SaveResult> newParentOpp  = Database.Insert(newParent);

              Utilities.processResults(newParentOpp, reparentOpportunities,  'BatchLogDetailPageController','',
                      'saveAdjustmentOppty error::  ' );

              Opportunity childOpp = getNewChildOpp(newParentOppty.Id);
              Id originalTransactionId = null;
              Set<Id>transactionIds = new Set<Id>();
              for(Opportunity opp: adjustmentOpptyUpdateLst){
                  if(opp.Adjustment_Code__c == 'D'){
                      Integer dTransaction = adjustmentOpptyUpdateLst.indexOf(opp);
                      //SETUP VALUES IN NEW TRANSACTION

                      childOpp.Adjustment_Batch__c = opp.Adjustment_Batch__c;
                      childOpp.Batch_log__c = opp.Adjustment_Batch__c;
                      childOpp.Adjustment_Code__c = opp.Adjustment_Code__c;
                      childOpp.StageName = opp.StageName;
                      childOpp.Deposit_Site__c = parentOppty.Deposit_Site__c;
                      childOpp.Tax_Date__c = parentOppty.Tax_Date__c;
                      childOpp.Bank_Date__c = opp.Bank_Date__c;
                      childOpp.Batch_Date__c = parentOppty.Batch_Date__c;
                      childOpp.Accounting_Date__c = parentOppty.Batch_Date__c;
                      childOpp.Adjustment_Notes__c = opp.Adjustment_Notes__c;
                      childOpp.Adjustment_Reason_Type__c = opp.Adjustment_Reason_Type__c;
                      childOpp.Payment_Subtype__c = opp.Payment_Subtype__c;
                      childOpp.rC_Giving__Comments__c = opp.rC_Giving__Comments__c;
                      childOpp.Description = opp.Description;
                      childOpp.Account_Note__c = opp.Account_Note__c;
            childOpp.Acknowledgment_Status__c = opp.Acknowledgment_Status__c;
            childOpp.rC_Giving__Acknowledged_Date__c = opp.rC_Giving__Acknowledged_Date__c;
                      adjustmentOpptyUpdateLst.add(childOpp);
                      //Update values from original transaction
                      Opportunity dOpportunity =  adjustmentOpptyUpdateLst.get(dTransaction);
                      dOpportunity.Amount = 0;
                      dOpportunity.rC_Giving__Payment_Method_Selected__c = parentOppty.rC_Giving__Payment_Method_Selected__c;
                      dOpportunity.rC_Giving__Payment_Method__c = parentOppty.rC_Giving__Payment_Method__c;
                      dOpportunity.Payment_Subtype__c = parentOppty.Payment_Subtype__c;
                      dOpportunity.Adjustment_Batch__c = opp.Adjustment_Batch__c;
                      dOpportunity.Batch_Log__c = opp.Adjustment_Batch__c;
                      dOpportunity.AccountId = parentOppty.AccountId;

                      //Recalculate Transaction Values (+A+(-B)+D(0))
                      parentOppty.rC_Giving__Current_Giving_Amount__c = 0;
                      parentOppty.rC_Giving__Expected_Giving_Amount__c = 0;
                      parentOppty.rC_Giving__Closed_Amount__c = 0;
                      break;
                  }
              }

              List<Database.UpsertResult> reparentAccountOpp  = Database.upsert(adjustmentOpptyUpdateLst, false);

              processUpsertResults(reparentAccountOpp, adjustmentOpptyUpdateLst,  'BatchLogDetailPageController','',
                      'saveAdjustmentOppty error::  ' );

              for( Database.UpsertResult sr : reparentAccountOpp ){
                  if( !sr.isSuccess()){
                      Database.rollback(beforeSaving);
                      errorInBatchRow = true;
                      errorMsg = sr.getErrors()[0].getMessage();
                      return;
                  }
              }

              /*Ana Ferreira - Traction on Demand - Dec 30, 2019
              ASL-56 BGE-93 Reparent credits when adjustment created*/
              for(Opportunity opp: adjustmentOpptyUpdateLst){
                  if(opp.Adjustment_Code__c=='A'){
                      originalTransactionId = opp.id;
                      break;
                  }
              }
              transactionIds.add(originalTransactionId);
              transactionIds.add(parentOppty.id);
              credits = getCredits(transactionIds);
              Map<Id, List<rC_Giving__Opportunity_Credit__c>> oppToCredits = new Map<Id, List<rC_Giving__Opportunity_Credit__c>>();

              movingCredit(parentOppty.Id, childOpp.Id, newParentOppty.Id, originalTransactionId, transactionIds);
          }



         //Update old D transaction values
          if(isAdjustementsCreated ){
              if (originalDTransaction!= null) {
                  for(Opportunity opp : adjustmentOpptyUpdateLst){
                      if(opp.adjustment_code__c == 'D' ){
                          originalDTransaction.rC_Giving__Transaction_Type__c = opp.rC_Giving__Transaction_Type__c;
                          originalDTransaction.CloseDate = opp.CloseDate;
                          originalDTransaction.Bank_Date__c = opp.Bank_Date__c;
                          originalDTransaction.Adjustment_Reason_Type__c = opp.Adjustment_Reason_Type__c;
                          originalDTransaction.Adjustment_Notes__c = opp.Adjustment_Notes__c;
                          originalDTransaction.Acknowledgment_Status__c = opp.Acknowledgment_Status__c;
                          originalDTransaction.CampaignId = opp.CampaignId;
            originalDTransaction.campaignIdTexT__c = opp.campaignIdTexT__c;
                      }
                  }
                  adjustmentOpptyUpdateLst.add(originalDTransaction);
              }
                List<Database.UpsertResult> srUpOpp  = Database.upsert(adjustmentOpptyUpdateLst, false);
                processUpsertResults(srUpOpp, adjustmentOpptyUpdateLst,  'BatchLogDetailPageController','',
                                       'saveAdjustmentOppty error::  ' );
                for( Database.UpsertResult sr : srUpOpp ){
                    if( !sr.isSuccess()){
                         Database.rollback(beforeSaving);
                         errorInBatchRow = true;
                         errorMsg = sr.getErrors()[0].getMessage();
                         return;
                    }
                }
          }else{
              if(newParentOppty.accountId == parentOppty.accountId){
                  System.debug('>>>> Else from isAdjustementsCreated');
                  List<Database.UpsertResult> srUpOpp  = Database.upsert(adjustmentOpptyUpdateLst, false);
                  processUpsertResults(srUpOpp, adjustmentOpptyUpdateLst,  'BatchLogDetailPageController','',
                          'saveAdjustmentOppty error::  ' );
                  for( Database.UpsertResult sr : srUpOpp ){
                      if( !sr.isSuccess()){
                          Database.rollback(beforeSaving);
                          errorInBatchRow = true;
                          errorMsg = sr.getErrors()[0].getMessage();
                          return;
                      }
                  }
              }
          }
          // end update  old D transaction value

        // Separate DML on Parent Opportunity as updating child transaction above is also firing updates on
        // parent which is resulting into SELF_REFERENCE_TRIGGER_ERROR
        //update parentOppty;
        Database.SaveResult srParentOpp  = Database.update(parentOppty,false);
        Utilities.processResults(new List<Database.SaveResult>{srParentOpp}, new List<Opportunity>{parentOppty},  'BatchLogDetailPageController','',
                               'saveAdjustmentOppty error::  ' );
            if( !srParentOpp.isSuccess()){
                 Database.rollback(beforeSaving);
                 errorInBatchRow  = true;
                 errorMsg = srParentOpp.getErrors()[0].getMessage();
                return;
            }
      }

      //SoftCredit reparenting
      if(reParentSoftCredits){
          Id drecordId = null;
          for(Opportunity opp: adjustmentOpptyUpdateLst){
              if(opp.Adjustment_Code__c == 'D'){
                  drecordId = opp.Id;
                  break;
              }
          }
          for(Opportunity opp: softCreditsToUpdate){
              if(opp.rC_Giving__Parent__c == opp.Related_Transaction__c && drecordId != null){
                  opp.rC_Giving__Parent__c = drecordId;
              }
              opp.Related_Transaction__c = drecordId;
          }

          //update softCreditsToUpdate;
          List<Database.SaveResult> srSoftCreditOpp  = Database.update(softCreditsToUpdate);
        Utilities.processResults(srSoftCreditOpp, softCreditsToUpdate,  'BatchLogDetailPageController','',
                               'saveAdjustmentOppty error::  ' );
        for( Database.SaveResult sr : srSoftCreditOpp ){
            if( !sr.isSuccess()){
                 Database.rollback(beforeSaving);
                 errorInBatchRow = true;
                 errorMsg = sr.getErrors()[0].getMessage();
                 return;
            }
        }
      }

      if(updatedcampaignIdOnDRec != null){
          updateCampaignOnSoftCredits(parentOppty.Id, updatedcampaignIdOnDRec);
      }

      // update Actual Amount and Counts.
      calculateActualCounts_Amounts_Adjustmet(true);
      AdjustmentCreatedOnce = true;
      isAdjustementsCreated = true;
      campaignId_Old = null;
      //refreshOppt();
    } catch (DMLException e) {
      Database.rollback(beforeSaving);
      Exceptionutils.createApexLog('BatchLogDetailPageController','saveAdjustmentOppty',e);
      errorInBatchRow = isError = false;
    }
    
     oSkipValidation.Bypass__c = false;
     update oSkipValidation;
  }
   /*
    Ana Ferreira - March 17, 2020
    BGE-93 avoid reachin limits
    */
    @future
    public static void movingCredit(Id parentOpptyId, Id childOppId, Id newParentOpptyId, Id originalTransactionId, Set<id> transactionIds) {
        List<rC_Giving__Opportunity_Credit__c> listCredits = BatchLogDetailPageController.getCredits(transactionIds);
        if (listCredits.size() > 0) {
            Opportunity childOpp = [SELECT Id FROM Opportunity where id = :childOppId][0];
            Opportunity newParentOppty = [SELECT Id FROM Opportunity where id = :newParentOpptyId][0];

            Map<Id, List<rC_Giving__Opportunity_Credit__c>> oppToCredits = new Map<Id, List<rC_Giving__Opportunity_Credit__c>>();
            Map<Id, Opportunity> originalTransationToNewReparent = new Map<Id, Opportunity>();

            originalTransationToNewReparent.put(parentOpptyId, newParentOppty);
            originalTransationToNewReparent.put(originalTransactionId, childOpp);

            List<rC_Giving__Opportunity_Credit__c> newCredits = new List<rC_Giving__Opportunity_Credit__c>();
            for (rC_Giving__Opportunity_Credit__c credit : listCredits) {
                if (oppToCredits.containsKey(credit.rC_Giving__Opportunity__c)) {
                    oppToCredits.get(credit.rC_Giving__Opportunity__c).add(credit);
                } else {
                    oppToCredits.put(credit.rC_Giving__Opportunity__c, new List<rC_Giving__Opportunity_Credit__c>{
                            credit
                    });
                }
            }

            for (Id opp : oppToCredits.keySet()) {
                List<rC_Giving__Opportunity_Credit__c> credits = oppToCredits.get(opp);
                Opportunity newOwner = originalTransationToNewReparent.get(opp);
                newCredits.addAll(BatchLogDetailPageController.reparentCredits(credits, newOwner));
            }

            Savepoint beforeSaving;
            System.debug('******Before Upsert getcredits limits: ' + Limits.getQueries());
            List<Opportunity> opps = new List<Opportunity>();
            List<Database.UpsertResult> reparentCreditsOpp = Database.upsert(newCredits, false);
            processUpsertResults(reparentCreditsOpp, newCredits, 'BatchLogDetailPageController', '', 'saveAdjustmentOppty error::  ');
            for (Database.UpsertResult sr : reparentCreditsOpp) {
                if (!sr.isSuccess()) {
                    Database.rollback(beforeSaving);
                    //            BatchLogDetailPageController.errorInBatchRow = true;
                    //                BatchLogDetailPageController.errorMsg = sr.getErrors()[0].getMessage();
                    return;
                }
            }

        }
    }
  public static Opportunity getNewChildOpp(Id newParentOpptyId){
    return [SELECT Adjustment_Code__c, StageName, rC_Giving__Payment_Method__c, name, Deposit_Site__c, Tax_Date__c, Bank_Date__c, Batch_Date__c, Accounting_Date__c, Adjustment_Reason_Type__c, Adjustment_Notes__c  FROM Opportunity WHERE rC_Giving__Parent__c = :newParentOpptyId ][0];
    }
    /*Ana Ferreira - Traction on Demand - Dec 30, 2019
            ASL-56 BGE-93 Reparent credits when adjustment created*/
    public static List<rC_Giving__Opportunity_Credit__c> reparentCredits (List<rC_Giving__Opportunity_Credit__c> credits, Opportunity newOpp){
        List<rC_Giving__Opportunity_Credit__c> newCredits = new List<rC_Giving__Opportunity_Credit__c>();
        List<rC_Giving__Opportunity_Credit__c> oldCredits = new List<rC_Giving__Opportunity_Credit__c>();
        for(rC_Giving__Opportunity_Credit__c credit : credits){
            rC_Giving__Opportunity_Credit__c newCredit = new rC_Giving__Opportunity_Credit__c();
                newCredit = credit.clone();
                newCredit.rC_Giving__Opportunity__c = newOpp.Id;
                newCredits.add(newCredit);
                oldCredits.add(credit);

        }
        delete oldCredits;
        return newCredits;
    }
    /*Ana Ferreira - Traction on Demand - JAN 14, 2020
    ASL-56 BGE-93 Reparent credits when adjustment created*/
    public static List<rC_Giving__Opportunity_Credit__c> getCredits(Set<Id> oppId){
        List<rC_Giving__Opportunity_Credit__c> credits = [SELECT ID, rC_Giving__Account__c, rC_Giving__Opportunity__c,  rC_Giving__Distribution__c,
                rC_Giving__Type__c,rC_Giving__Archive_Flag__c, rC_Giving__Contact__c, Comments__c, Solicit_Date__c, Soft_Credit_Type__c, Ack_Fund_Name__c, Payment_Issuer__c
        FROM  rC_Giving__Opportunity_Credit__c WHERE rC_Giving__Opportunity__c in :oppId];
        return credits;
    }

  public boolean softCreditAmountsMatch(Boolean populateWrapper) {
    Map<Id, Double> opptyToSoftCreditMap = new Map<Id, Double>();
    Map<Id, Opportunity> opptyIdMap = new Map<Id, Opportunity>();
    Map<Id, Boolean> opptyIdToSftAmtMatch = new Map<Id,Boolean> ();
    Map<Id, Opportunity> transactionDAmount = new Map<Id, Opportunity>();
    Double oppAmount = 0;
    Boolean softCreditAmountMatched = true;
    String query = '';
    // TODO: Is this query selective?
    for (Opportunity opp : [SELECT Id, name, Amount, rC_Giving__Parent__c, rC_Giving__Parent__r.rC_Giving__Parent__c, rC_Giving__Giving_Amount__c, Related_Transaction__c,
                              Related_Transaction__r.rC_Giving__Parent__c, RecordTypeId, Batch_Sequence__c, RecordType.Name, account.Name
                            FROM Opportunity
                            WHERE (rC_Giving__Parent__c IN: parentOpptyIds AND RecordType.Name = 'Soft Credit')
                              OR (RecordType.Name = 'Pledge Payment' AND Related_Transaction__c IN: parentOpptyIds)
                              OR (RecordType.Name = 'Pledge Payment' AND Related_Transaction__r.rC_Giving__Parent__c IN: parentOpptyIds)
                              OR Id IN: parentOpptyIds]) {

      // Exceptional Case for the Adjustment batch
      if(parentOpptyIds.contains(opp.rC_Giving__Parent__r.rC_Giving__Parent__c) && opp.RecordType.Name == 'Soft Credit'){
          Double Amt = (opp.amount !=null)?opp.amount:0;
        if (!opptyToSoftCreditMap.containsKey(opp.rC_Giving__Parent__r.rC_Giving__Parent__c)) {
          opptyToSoftCreditMap.put(opp.rC_Giving__Parent__r.rC_Giving__Parent__c, 0);
        }
        opptyToSoftCreditMap.put(opp.rC_Giving__Parent__r.rC_Giving__Parent__c, opptyToSoftCreditMap.get(opp.rC_Giving__Parent__r.rC_Giving__Parent__c) + Amt);
      }
      // Soft Credit Records under the Donation/Pledge/Pledge Payment Records.
      else if (parentOpptyIds.contains(opp.rC_Giving__Parent__c) && opp.RecordType.Name == 'Soft Credit') {
        Double Amt = (opp.amount !=null)?opp.amount:0;
        if (!opptyToSoftCreditMap.containsKey(opp.rC_Giving__Parent__c)) {
          opptyToSoftCreditMap.put(opp.rC_Giving__Parent__c, 0);
        }
        opptyToSoftCreditMap.put(opp.rC_Giving__Parent__c, opptyToSoftCreditMap.get(opp.rC_Giving__Parent__c) + Amt);
      }
      // Pledge Payment records in Soft Credit Page under the Donation Records.
      else if (parentOpptyIds.contains(opp.Related_Transaction__r.rC_Giving__Parent__c) && opp.RecordType.Name == 'Pledge Payment') {
        Double Amt = (opp.Amount != null)?opp.Amount:0;
        if (!opptyToSoftCreditMap.containsKey(opp.Related_Transaction__r.rC_Giving__Parent__c)) {
          opptyToSoftCreditMap.put(opp.Related_Transaction__r.rC_Giving__Parent__c, 0);
        }
        opptyToSoftCreditMap.put(opp.Related_Transaction__r.rC_Giving__Parent__c, opptyToSoftCreditMap.get(opp.Related_Transaction__r.rC_Giving__Parent__c) + Amt);
      }
      // Pledge Payment records in soft Credit Page under the Pledge Payment.
      else if (parentOpptyIds.contains(opp.Related_Transaction__c) && opp.RecordType.Name == 'Pledge Payment') {
        Double Amt = (opp.Amount != null)?opp.Amount:0;
        if (!opptyToSoftCreditMap.containsKey(opp.Related_Transaction__c)) {
          opptyToSoftCreditMap.put(opp.Related_Transaction__c, 0);
        }
        opptyToSoftCreditMap.put(opp.Related_Transaction__c, opptyToSoftCreditMap.get(opp.Related_Transaction__c) + Amt);
      }
      else {
        opptyIdMap.put(opp.Id, opp);
      }
    }

    if(isAdjustBatch){
        for(Opportunity opp: [SELECT Id, rC_Giving__Parent__c, amount
                              FROM Opportunity
                              WHERE rC_Giving__Parent__c=: opptyToSoftCreditMap.keySet()
                              AND (Adjustment_Code__c = 'D' OR Adjustment_Code__c = 'N')]){
          transactionDAmount.put(opp.rC_Giving__Parent__c,opp);
        }
    }

    for (Id opptyId : opptyToSoftCreditMap.KeySet()) {
      softCreditAmountMatched = true;
      if(! isAdjustBatch){
        String rctype = opptyIdMap.get(opptyId).recordType.Name;
        oppAmount = amount(opptyIdMap.get(opptyId), (rctype == 'Pledge Payment'), isAdjustBatch);
      }
      else{
        oppAmount = transactionDAmount.get(opptyId).amount;
      }

      if (oppAmount != opptyToSoftCreditMap.get(opptyId)) {

        softCreditAmountMatched = false;
        opptyIdToSftAmtMatch.put(opptyId,softCreditAmountMatched);
        batchSequenceInError = opptyIdMap.get(opptyId).Batch_Sequence__c;
        if(!populateWrapper){
          break;
        }
      }
    }

    if(populateWrapper){
      for(OpportunityWrapper wrapper: opportunityWrapperLst){
        if(wrapper.objOppty.Id != null && opptyIdToSftAmtMatch.containsKey(wrapper.objOppty.Id)){
          wrapper.hasMatchingSoftCredit = opptyIdToSftAmtMatch.get(wrapper.objOppty.Id);
        }
        else{
          wrapper.hasMatchingSoftCredit = true;
        }
      }
    }
    return softCreditAmountMatched;
  }

  public boolean depositSitesMatch() {
    // TODO: Is this query selective?
    for (Opportunity opp : [SELECT Id, Deposit_Site__c
                            FROM Opportunity
                            WHERE Batch_Log__c = : batchLog.Id
                              AND (RecordTypeId = : OPP_RT_DONATION_ID
                                OR RecordTypeId = : OPP_RT_PLEDGE_PAYMENT_ID)]) {
      if (opp.Deposit_Site__c != batchLog.Deposit_Site__c) {
        return false;
      }
    }
    return true;
  }

  public String rowName(Opportunity opp) {
    String rowName;
    if (String.isBlank(opp.Batch_Sequence__c)) {
      rowName = 'New Row';
    } else {
      rowName = 'Batch ' + String.valueOf(opp.Batch_Sequence__c);
      rowName += (opp.Split_Sequence__c != null)
        ? ' Split ' + String.valueOf(opp.Split_Sequence__c)
        : '';
    }
    return rowName;
  }

  /*public String oppsWithBadBankDates() {
    String[] oppsWithBadBankDates = new String[]{};
    // TODO: Is this query selective?
    for (Opportunity opp : [SELECT Id, Batch_Sequence__c, Split_Sequence__c, Deposit_Site__c, Bank_Date__c, CloseDate
                            FROM Opportunity
                            WHERE Batch_Log__c = : batchLog.Id
                              AND (RecordTypeId = : OPP_RT_DONATION_ID OR RecordTypeId = : OPP_RT_PLEDGE_PAYMENT_ID)]) {
      if (opp.Bank_Date__c != null && opp.Bank_Date__c < opp.CloseDate) {
        String rowName = rowName(opp);
        oppsWithBadBankDates.add(rowName);
      }
    }
    return String.join(oppsWithBadBankDates, ', ');
  }*///commented for T-647275

  // populates the PaymentMethod if the BatchLog default payment Method is not equals to 'Charge Card/EFT'.
  public static List<rC_Giving__Payment_Method__c> createPaymentMethod(Map<Id, Opportunity> opps, Batch_Log__c bL) {
    Map<Id, Set<String> > paymentMethods = new Map<Id, Set<String> >();
    List<rC_Giving__Payment_Method__c> newPaymentMethods = new List<rC_Giving__Payment_Method__c>();
    for ( Opportunity opp : opps.values()) {
      if ( opp.AccountId != null && opp.rC_Giving__Payment_Method__c != null) {
        if ( !paymentMethods.containsKey(opp.AccountId)) {
          paymentMethods.put(opp.AccountId, new Set<String> {});
        }
        paymentMethods.get(opp.AccountId).add(opp.rC_Giving__Payment_Method__c);
      }
    }
    for (Opportunity opp : opps.Values()) {
      for (String paymentMethod : paymentMethods.get(opp.AccountId)) {
        newPaymentMethods.add(new rC_Giving__Payment_Method__c(
          rC_Giving__Account__c = opp.AccountId,
          All_Affiliate_Edit_Access__c = true,
          rC_Giving__Payment_Type__c = paymentMethod,
          recordTypeId = paymentRecordTypeMap.get(paymentMethod).getRecordTypeId(),
          rC_Giving__Is_Active__c = true,   //Sai-7/6: Change
          Name = paymentMethod));
      }
    }

    if (!newPaymentMethods.IsEmpty()) {

      insert newPaymentMethods;
      return newPaymentMethods;
    } else {
      return null;
    }
  }

  // Demo Modal Popup starts
  public boolean displayPopup {get; set;}
  public Integer oppRow {get; set;}
  public rC_Giving__Payment_Method__c paymentMethodRec {get; set;}
  public String paymentMType {get; set;}
  public Boolean required {get; set;}
  public static Map<String, Schema.RecordTypeInfo> paymentRecordTypeMap = Schema.SObjectType.rC_Giving__Payment_Method__c.getRecordTypeInfosByName();
  //Creates a paymentMethod Record via Popup
  public void createPayment() {

    try {
      paymentMethodRec.rC_Giving__Is_Active__c = true;
      paymentMethodRec.rC_Giving__Is_Default__c = true;
      paymentMethodRec.rC_Giving__Payment_Type__c = paymentMType;
      paymentMethodRec.All_Affiliate_Edit_Access__c = true;
      if (isValid(paymentMType, paymentMethodRec)) {
        // added for issue  - I-316457
        if(batchlog.Deposit_Site__c != null && (paymentMType == 'Charge Card'|| paymentMType == 'EFT')) {
          paymentMethodRec.rC_Connect__Merchant_Name__c = batchlog.Deposit_Site__c;
          paymentMethodRec.rC_Connect__Payment_Processor__c =
            rC_Connect__Payment_Method_Setting__c.getOrgDefaults().rC_Connect__Default_Payment_Processor__c;
        }
        insert paymentMethodRec;

        // disables the button
        paymentMType = null;
        for (OpportunityWrapper wrapper : opportunityWrapperLst) {
          if (wrapper.recCount == oppRow) {
            wrapper.objOppty.rC_Giving__Payment_Method_Selected__c = paymentMethodRec.Id;
          }
        }
        displayPopup = false;
      } else {
        ApexPages.Message myMsg;
        if (paymentMType == 'Charge Card') {
          myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide the Card Holder Name, Card Number, Card Expiration Month and Card Expiration Year and click Save');
        } else {
          myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide the Routing Number, Account Number and click Save');
        }
        ApexPages.addMessage(myMsg);
      }
    } catch (exception e) {
      // Todo: improve the error handling A LOT
      // Todo: show the error number in the message
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message);
      ApexPages.addMessage(myMsg);
      Exceptionutils.createApexLog('BatchLogDetailPageController','createPayment',e);
    }
  }

  // Removes the selected payment Method
  public void paymentMethodChanged() {
    paymentMethodRec = new rC_Giving__Payment_Method__c();
    if (oppRow != null) {
      updatedRows.add(oppRow);
    }
  }

  // Close the popup
  public void closePopup() {

    required = true;
    clearPaymentFields();
    displayPopup = false;
  }

  //clears the payment Method and Selected Payment method
  public void clearPaymentFields () {
    for (OpportunityWrapper wrapper : opportunityWrapperLst) {
      if (wrapper.recCount == oppRow) {
        wrapper.objOppty.rC_Giving__Payment_Method_Selected__c = null;
        wrapper.objOppty.rC_Giving__Payment_Method__c = null;
        paymentMType = null;
      }
    }
  }

  // Validate the Payment Method popup Fields
  public Boolean isValid(String paymentMType, rC_Giving__Payment_Method__c paymentMethodRec) {
    Boolean isValid = true;
    if (paymentMType == 'Charge Card'
      && paymentMethodRec.No_Charge__c == false
      && (
        String.isBlank(paymentMethodRec.rC_Giving__Card_Holder_Name__c)
        || String.isBlank(paymentMethodRec.rC_Giving__Card_Number__c  )
        || String.isBlank(paymentMethodRec.rC_Giving__Card_Expiration_Month__c)
        || String.isBlank(paymentMethodRec.rC_Giving__Card_Expiration_Year__c))) {
      isValid = false;
    } else if (paymentMType == 'EFT'
      && paymentMethodRec.No_Charge__c == false
      && (
        String.isBlank(paymentMethodRec.rC_Giving__Routing_Number__c )
        || String.isBlank(paymentMethodRec.rC_Giving__Account_Number__c))) {
      isValid = false;
    }

    return isValid;
  }

  // show the payment Method pop up
  public void togglePaymentMethod() {
    oppRow = Integer.ValueOf(Apexpages.currentPage().getParameters().get('oppRow')) + 1;
    if (displayPopup == false) {
      required = false;
      paymentMethodChanged();
      paymentMType = Apexpages.currentPage().getParameters().get('payType');
      paymentMethodRec = new rC_Giving__Payment_Method__c();
      if (!String.IsBlank(paymentMType)) {
        paymentMethodRec.recordTypeId = paymentRecordTypeMap.get(paymentMType).getRecordTypeId();
      }
      paymentMethodRec.rC_Giving__Account__c = Id.ValueOf(Apexpages.currentPage().getParameters().get('accId'));
      paymentMethodRec.Charge_Credit_Card_EFT__c = false;
      if(paymentMType == 'Charge Card' && isAffiliate){
          paymentMethodRec.No_Charge__c = true;
      }
      if (paymentMType == 'Charge Card' || paymentMType == 'EFT') {
        displayPopup = true;
      }
    }
  }

  // paymentsubtype field required?
  public Boolean isPsRequired(String paymentMethod){
      if(paymentMethod == 'EFT' || paymentMethod == 'Charge Card' || paymentMethod == 'Paypal'
      || paymentMethod == 'Voucher' || paymentMethod == 'Securities' || paymentMethod == 'Charge Card (No Charge)'){//Added condition for Charge Card (No Charge)-I-300335
          return false;
      }
      else{
          return true;
      }

  }

  //populates the selectedPaymentMethod field on giving record based on paymentMethod
  public Map<Integer, Opportunity> populateSelectedPaymentMethod(Map<Integer, Opportunity> opps) {
    Set<Id> parentAccounts = new Set<Id>();
    Set<String> paymentMethodType = new Set<String>();
    Map<Id, Opportunity> mapOppsToCreatePaymentMethods = new Map<Id, Opportunity>();
    List<rC_Giving__Payment_Method__c> newlyCreatedPaymentMethods = new List<rC_Giving__Payment_Method__c>();
    for (Opportunity opp : Opps.values()) {
      parentAccounts.add(opp.AccountId);
      paymentMethodType.add(opp.rC_Giving__Payment_Method__c);
    }

    Map<Id, Account> accountsById = new Map<Id, Account>();
    if (parentAccounts != null && paymentMethodType.Size() > 0) {
      // TODO: Is this query selective?
      accountsById = new Map<Id, Account>([
        SELECT id,
          (SELECT id, rC_Giving__Payment_Type__c
           FROM rC_Giving__Payment_Methods__r
           WHERE rC_Giving__Payment_Type__c != null
             AND rC_Giving__Payment_Type__c IN :paymentMethodType
           ORDER BY createdDate desc LIMIT 1)
        FROM Account
        WHERE Id IN: parentAccounts]);
    }

    for (Opportunity opp : opps.Values()) {
      if ( accountsById.ContainsKey(opp.AccountId)
           && accountsById.get(opp.AccountId) != null) {
        Account acc = accountsById.get(opp.AccountId);
        if (acc.rC_Giving__Payment_Methods__r.size() > 0) {
            if (acc.rC_Giving__Payment_Methods__r[0].rC_Giving__Payment_Type__c ==
                opp.rC_Giving__Payment_Method__c) {
              opp.rC_Giving__Payment_Method_Selected__c = acc.rC_Giving__Payment_Methods__r[0].Id;
          }
        } else if ( paymentMethodType.Contains(opp.rC_Giving__Payment_Method__c)
          && acc.rC_Giving__Payment_Methods__r.size() == 0
          && (
            opp.rC_Giving__Payment_Method__c != 'Charge Card'
            && opp.rC_Giving__Payment_Method__c != 'EFT') ) {
          mapOppsToCreatePaymentMethods.put(opp.Id, opp);
        }
      }
    }

    if (!mapOppsToCreatePaymentMethods.KeySet().IsEmpty()) {
      newlyCreatedPaymentMethods = createPaymentMethod(mapOppsToCreatePaymentMethods, batchLog);
    }

    //Populate SelectedPaymentMethod
    for (Opportunity opp : opps.Values()) {
      if (opp.rC_Giving__Payment_Method_Selected__c == null) {
        for (rC_Giving__Payment_Method__c payment : newlyCreatedPaymentMethods) {
          if (payment.rC_Giving__Account__c == opp.AccountId
              && payment.rC_Giving__Payment_Type__c == opp.rC_Giving__Payment_Method__c) {
            opp.rC_Giving__Payment_Method_Selected__c = payment.Id;
          }
        }
      }
    }
    return opps;
  }
  //Demo Modal Popup Ends

  //Remoting Function
  public Boolean accountNumberPopUp {get; set;}
  @RemoteAction
  global static List<String> populateAccountLookup(String row, String accNumber) {
    // TODO: Is this query selective?
    List<Account> accs = [Select Id, Name From Account WHERE Account_Number__c = : accNumber LIMIT 50000 ];
    if (accs.size() == 1 && !accs.IsEmpty()) {
      List<String> result = new List<String>();
      result.add('True');
      result.add(String.ValueOf(accs[0].Id));
      result.add(String.ValueOf(accs[0].Name));
      return result;
    } else {
      List<String> result = new List<String>();
      result.add('FaLsE');
      return result;
    }
  }

  @RemoteAction
  global static List<String> populateCampaignLookup(String row, String sourceCode, String depositSite) {
    String searchKey = (sourceCode != null) ? sourceCode.capitalize() : sourceCode;
    String campaignQuery;
    // If the Batch Log Deposit Site not StartsWith NA, Then we need to retrieve the campaign records with Sub-Affiliation = 5
    if (depositSite != null && depositSite.StartsWith('NA')) {
      // TODO: Is this query selective?
      campaignQuery = 'Select Id, Name, rC_Giving__Sub_Affiliation__c, rC_Giving__Source_Code__c From Campaign WHERE rC_Giving__Source_Code__c =: searchKey AND Is_Overflow_Campaign__c = False AND Is_Sustainer_Operational_Campaign__c = FALSE LIMIT 50000';//T-647559(Added condition for Is Sustainer Operational Campaign)
    } else {
      // TODO: Is this query selective?
      campaignQuery = 'Select Id, Name, rC_Giving__Sub_Affiliation__c,rC_Giving__Source_Code__c From Campaign WHERE  Is_Overflow_Campaign__c = False AND Is_Sustainer_Operational_Campaign__c = FALSE AND rC_Giving__Source_Code__c =: searchKey AND (rC_Giving__Sub_Affiliation__c LIKE \'3%\' OR rC_Giving__Sub_Affiliation__c LIKE \'5%\') LIMIT 50000';//T-647559
    }

    List<Campaign> cmps = (List<Campaign>)Database.query(campaignQuery);

    if (cmps.size() == 1 && !cmps.IsEmpty()) { //
      List<String> result = new List<String>();
      result.add('True');
      result.add(String.ValueOf(cmps[0].Id));
      result.add(String.ValueOf(cmps[0].Name));
      result.add(String.ValueOf(cmps[0].rC_Giving__Source_Code__c));
      result.add(String.ValueOf(cmps[0].rC_Giving__Sub_Affiliation__c));
      return result;
    } else {
      List<String> result = new List<String>();
      result.add('FaLsE');
      return result;
    }

  }

  // ******** Split Opportunity Methods Start ********* //

  // Method to add new Split row on Clicking Split Opportunity Icon.
  public void addSplitRow() {

    Integer splitRowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('splitRowIndex'));
    List<OpportunityWrapper> temWrapperLst = new List<OpportunityWrapper>();
    temWrapperLst.addAll(opportunityWrapperLst);
    opportunityWrapperLst.clear();
    Integer rCount = 0, splitNum = 0; // Local variables to maintain count and splits.
    Boolean isNotSplitted = true;
    OpportunityWrapper origWrapper = temWrapperLst.get(splitRowIndex - 1);
    Opportunity splitOppty = (origWrapper.objOppty).clone(false, false, true, false);

    // IHO/IMO Information not copied to Spit rows
    splitOppty.rC_Giving__Tribute_Type__c = null;
    splitOppty.Honoree_Title__c = null;
    splitOppty.Honoree_First_Name__c = null;
    splitOppty.Honoree_Middle_Name__c = null;
    splitOppty.Honoree_Last_Name__c = null;
    splitOppty.Honoree_Suffix__c = null;
    splitOppty.Non_Person__c = null;
    splitOppty.Recipient_Acknowledgment_Code__c = null;
    splitOppty.Recipient_Acknowledgement_Status__c = null;
    splitOppty.Tribute_Message_Body__c = null;
    splitOppty.Ack_Recipient_Full_Name__c = null;
    splitOppty.Ack_Recipient_Street_Line_1__c = null;
    splitOppty.Ack_Recipient_Street_Line_2__c = null;
    splitOppty.Ack_Recipient_City__c = null;
    splitOppty.Ack_Recipient_State__c = null;
    splitOppty.Ack_Recipient_Country__c = null;
    splitOppty.Ack_Recipient_Zip_Code__c = null;
    splitOppty.Ack_Recipient_Outside_Salutation__c = null;
    splitOppty.Ack_Recipient_Account__c = null;
    splitOppty.Ack_Recipient_Account_Number__c = null;
    splitOppty.Has_Soft_Credits__c = false;

    //Campaign Attributes not copied
    splitOppty.Exclude_Cost_Factors_in_RevShare__c = false;
    splitOppty.Fundraising_Department__c = null;
    splitOppty.Use_Campaign_Cost__c = false;
    splitOppty.Restriction__c = null;
    splitOppty.Program_Type__c = null;
    splitOppty.Campaign_Type__c = null;
    splitOppty.Cost_Factor__c = null;
    splitOppty.Account_Code__c = null;
    splitOppty.Fund__c = null;

    for (OpportunityWrapper objWrapper : temWrapperLst) {
      if (objWrapper.recCount >= splitRowIndex) {
        if (splitRowIndex == objWrapper.recCount) {
          objWrapper.objOppty.Split_Sequence__c = splitNum + 1;
          splitNum = splitNum + 1;
          objWrapper.isSplitParent = true;
        } else if (Integer.ValueOf(objWrapper.objOppty.Batch_Sequence__c) == Integer.ValueOf(splitOppty.Batch_Sequence__c)) {
          objWrapper.objOppty.Split_Sequence__c = splitNum + 1;
          splitNum = splitNum + 1;
        } else if (Integer.ValueOf(objWrapper.objOppty.Batch_Sequence__c) == (Integer.ValueOf(splitOppty.Batch_Sequence__c) + 1) && isNotSplitted) {
          splitOppty.Split_Sequence__c = splitNum + 1;
          opportunityWrapperLst.add(new OpportunityWrapper(splitOppty, origWrapper.selectedRT, origWrapper.accountName, origWrapper.campaignName, rCount + 1, Integer.ValueOf(splitOppty.Batch_Sequence__c), true, false, true,origWrapper.proposalName, isAdjustBatch));
          splitNum = 0;
          isNotSplitted = false;
          rCount = rCount + 1;
          count = count + 1;
          newSplitRowIndex = rCount;
        }
        objWrapper.recCount = rCount + 1;
      }
      rCount = rCount + 1;
      opportunityWrapperLst.add(objWrapper);
    }

    if (isNotSplitted) {
      splitOppty.Split_Sequence__c = splitNum + 1;
      opportunityWrapperLst.add(new OpportunityWrapper(splitOppty, origWrapper.selectedRT, origWrapper.accountName, origWrapper.campaignName, rCount + 1, Integer.ValueOf(splitOppty.Batch_Sequence__c), true, false, true,origWrapper.proposalName, isAdjustBatch));
      splitNum = 0;
      count = count + 1;
      newSplitRowIndex = rCount + 1;
    }
  }

  // ******** Split Opportunity Methods End ********* //

  //Changes the boolean Value
  public void populatePledgeBoolean() {

    Id selaccId = Id.ValueOf((Apexpages.currentPage().getParameters().get('selAccId') != null ? Apexpages.currentPage().getParameters().get('selAccId') : null ));
    Integer selRow = Integer.ValueOf(Apexpages.currentPage().getParameters().get('selRow'));
    if (selaccId != null) {
      for (OpportunityWrapper wrapper : opportunityWrapperLst) {
        if (wrapper.recCount == (selRow + 1)) {
          wrapper.showOpenPledgeIcon = checkOpenPledges( selaccId );
        }
      }
    }
  }

  public void populateOpenPledges(OpportunityWrapper[] opportunities, Set<Id> accountIds) {
    if (accountIds == null) {
      accountIds = new Set<Id>{};
      for (OpportunityWrapper opp : opportunities) {
        accountIds.add(opp.objOppty.AccountId);
      }
    }
    Map<Id, Boolean> openPledges = checkOpenPledges(accountIds, false);
    for (OpportunityWrapper opp : opportunities) {
      opp.showOpenPledgeIcon = openPledges.containsKey(opp.objOppty.AccountId);
    }
  }

  public static Boolean checkOpenPledges(Id accountId) {
    return checkOpenPledges(new Set<Id>{ accountId }, false).containsKey(accountId);
  }

  // Boolean value if the (Pledge, Open Pledge Payments, Proposals, Grants) are present under the AccountId.
  public static Map<Id, Boolean> checkOpenPledges(Set<Id> accountIds, Boolean pledgePaymentsOnly) {

    List<Opportunity> Opps = new List<Opportunity> ();
    Map<Id, Boolean> hasOpenPledges = new Map<Id, Boolean>();
    // Fetch Opportunites (Pledge, Open Pledge Payments, Proposals, Grants)
    // Is this query selective? Yes!
    Opps = [SELECT Id, AccountId, RecordTypeId
            FROM Opportunity
            WHERE accountId IN :accountIds
              AND (
                RecordTypeId = : opptyRTMap.get('Grant').getRecordTypeId()
                OR RecordTypeId = : opptyRTMap.get('Proposal').getRecordTypeId()
                OR (
                  RecordTypeId = : opptyRTMap.get('Pledge Payment').getRecordTypeId()
                  AND stageName = 'Open' AND IsCreatedFromBatchLog__c = false))];

    for (Opportunity opp : opps) {
      if (userHasPledgeAccess && !pledgePaymentsOnly) {
        hasOpenPledges.put(opp.AccountId, true);
      } else if (opp.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId()) {
        hasOpenPledges.put(opp.AccountId, true);
      }
    }

    return hasOpenPledges;
  }

  //setCampaignProductsIds
  public void setCampaignProductIds() {
      mapOppRowCountVsCmpProdIds = new Map<Integer, String>();
    Integer OppCampSelrow = Integer.valueOf(ApexPages.currentPage().getParameters().get('cmpRow'));
    String cmpProdIds = ApexPages.currentPage().getParameters().get('cmpProdIds');

    for (OpportunityWrapper wrapper : opportunityWrapperLst) {
      if (wrapper.recCount == (OppCampSelrow + 1)) {

        wrapper.campProductsIds = cmpProdIds;
        campaignProdIds = cmpProdIds;
        mapOppRowCountVsCmpProdIds.put(wrapper.recCount, cmpProdIds);
      }
    }
  }

  //create OpptyProducts
  public void createOpptyProducts() {
    List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
    Map<Id, Id> mapProductIdToPriceBookEntryId = new Map<Id, Id>();
    Set<Id> productIds = new Set<Id>();
    Set<Id> cmpProdIdsSet = new Set<Id>();
    Set<Id> oppIds = new Set<Id>();
    Map<Id, Set<Id>> MapcmpProductIds = new Map<Id, Set<Id>>();
    // TODO: Is this query selective?
    Id priceBookId = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1].Id;
    isError = errorInBatchRow = false;

      Set<Id> cmpProductIds = new Set<Id>();

      if ( String.isNotBlank( campaignProdIds) ) {
        List<String> cmpProdIds = campaignProdIds.split(':');
        for (String str : cmpProdIds) {
          if (!String.IsBlank(str)) {
            cmpProductIds.add(Id.ValueOf(str));
            cmpProdIdsSet.add(Id.ValueOf(str));
          }
        }
        if(MapcmpProductIds != null && activeOpportunityRecId != null){
            MapcmpProductIds.put(activeOpportunityRecId, cmpProductIds);
            oppIds.add(activeOpportunityRecId);
      }
    }
    // fetch the PricebookEntryId's
    // TODO: Is this query selective?
    for (PriceBookEntry pb : [SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id IN: cmpProdIdsSet AND  Pricebook2Id = :priceBookId]) {
      mapProductIdToPriceBookEntryId.put(pb.Product2Id, pb.Id);
    }
    for (Id objId : MapcmpProductIds.KeySet()) {
      for (Id prodId : MapcmpProductIds.get(objId)) {
        if (mapProductIdToPriceBookEntryId.get(prodId) != null) {
          oppLineItems.add(new OpportunityLineItem(OpportunityId = objId, PricebookEntryId  = mapProductIdToPriceBookEntryId.get(prodId), UnitPrice = 1, Quantity = 1));
        }
      }
    }

      Savepoint beforeSaving;
      try {
        // Keep this before savepoint, so it is not rolled back in case of a further exception to ensure that
        // actual count/amount is not incorrect even when further updates fail
        if (saveHappened != null && saveHappened) {
          saveHappened = false;
          refreshOppt();
          // Even if we're just saving one record we need to iterate through the
          // whole list to get the updated totals for the batchLog
          batchLog.Actual_Count__c = batchSeq;
          batchLog.Actual_Amount__c = 0;
          for (OpportunityWrapper objWrapper : opportunityWrapperLst) {
            //batchLog.Actual_Amount__c += amount(objWrapper,isAdjustBatch);
            batchLog.Actual_Amount__c += getOriginalAmount(objWrapper.objOppty,isPledgePayment(objWrapper), isAdjustBatch);
          }
          setBatchLogStatus();
          update batchLog;
        }

        // Set a savepoint to prevent partial DML operations
        beforeSaving = Database.setSavePoint();
        if (!oppLineItems.IsEmpty()) {
        // Is this query selective? Yes.
            Delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppIds];
            insert oppLineItems;
        }

        if(activeOpportunityIsNew != null && !activeOpportunityIsNew  && campaignId_Old != activeOpportunityCampaignId && campaignId_Old != null &&
            activeOpportunityRecId != null && activeOpportunityCampaignId != null){
            updateCampaignOnSoftCredits(activeOpportunityRecId,activeOpportunityCampaignId);
        }
        campaignId_Old = null;
      } catch (exception e) {
        Database.rollback(beforeSaving);
        errorInBatchRow = True;
        // Todo: improve the error handling A LOT
        // Todo: show the error number in the message
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Campaign Products are not Created due to ' + Label.Exception_error_message));
        isError = true;
        Exceptionutils.createApexLog('BatchLogDetailPageController','createOpptyProducts',e);
      }

  }

  // Opportunity Wrapper Class
  global class OpportunityWrapper {
    public Opportunity objOppty {get; set;}
    public Integer recCount {get; set;}
    public String selectedRT {get; set;}
    public Boolean isNew {get; set;}
    public String campaignName {get; set;}
    public Boolean isSplitParent {get; set;}
    public Boolean isSplit {get; set;}
    public String accountName {get; set;}
    public String affiliation {get;set;}
    public String proposalName {get;set;}
    public String accountNumber {get; set;}
    public String SourceCode {get; set;}
    public Boolean showOpenPledgeIcon {get; set;}
    public Boolean hasSoftCredits {get; set;}
    public String csvRecord {get; set;}
    public String accountType {get; set;}
    public String campProductsIds {get; set;}
    public String hiddenSourceCode {get; set;}
    public String programType {get; set;}
    public String sharingCode {get; set;}
    public String sharingEntity {get; set;}
    public Boolean hasMatchingSoftCredit {get; set;}
    public Boolean isAdjustementsCreated {get;set;}
    public String batchSequence {get;set;}
    public Boolean isAdjustBatchType {get;set;}
    public String accountNameError {get; set;}
    // DS 10-8-2018 GH-34
    public Boolean sourceCodeOverride {get; set;}

    //public String ackCode{get;set;}

    public Boolean isPledgePaymentRecord {
      get {
        if (isPledgePaymentRecord == null) {
          isPledgePaymentRecord = (this.selectedRT == 'Pledge Payment');
        }
        return isPledgePaymentRecord;
      }
      set;
    }
    public Boolean accountSelected {
      get {
        return String.IsNotBlank(objOppty.accountId);
      }
    }
    public Boolean isPartOfASplit {
      get {
        return this.isSplit
            || this.isSplitParent;
      }
    }
    public Boolean isDonationOrUnsplitPledge {
      get {
        return this.selectedRT == 'Donation'
            || !isPartOfASplit;
      }
    }
    public Decimal amount {
      get {
        return amount(objOppty, isPledgePaymentRecord, this.isAdjustBatchType);
      }
    }
    public Boolean hasPledgeDetails{
      get{
          return (objOppty != null &&
            (objOppty.rC_Giving__Giving_Frequency__c != 'One Payment'));
      }
    }
    public Boolean hasSharingValues{
        get{
            return (objOppty != null &&
               (objOppty.Sharing_Code_Override__c != false ||
                objOppty.Sharing_Entity_Override__c != false ||
                objOppty.Bypass_Calculations__c != false ||
                String.isNotBlank(objOppty.Sharing_Entity__c) ||
                String.isNotBlank(objOppty.Sharing_Code__c)));
        }
    }
    public Boolean hasStockValues{
        get{
            return (objOppty !=null &&
            (objOppty.rC_Giving__Number_Of_Shares__c != null ||
            String.isNotBlank(objOppty.rC_Giving__Ticker_Symbol__c) ||
            String.isNotBlank(objOppty.Types_of_shares__c) ||
            objOppty.High_Amount__c !=null ||
            objOppty.Low_Amount__c !=null ||
            objOppty.Tax_Value__c != null ||
            objOppty.Net_Amount__c != null ||//T-647269
            objOppty.Fees__c != null ));
        }
    }
    public Boolean hasMatchingValues{
        get{
            return (objOppty !=null &&
            (String.isNotBlank(objOppty.rC_Giving__Matching_Account__c) ||
            String.isNotBlank(objOppty.rC_Giving__Matching_Status__c)));
        }
    }

    public Boolean hasFundraisingValues{
        get{
            return (objOppty !=null &&
            (String.isNotBlank(objOppty.Fundraising_Department__c)));
        }
    }
    public Boolean hasImoValues{
        get{
            return(objOppty != null &&
            (String.isNotBlank(objOppty.rC_Giving__Tribute_Type__c) || String.IsNotBlank(objOppty.Ack_Recipient_Full_Name__c) || String.IsNotBlank(objOppty.Tribute_Message_Body__c) ||
                String.IsNotBlank(objOppty.Ack_Recipient_Account__c) || String.IsNotBlank(objOppty.Honoree_Title__c) || String.IsNotBlank(objOppty.Honoree_First_Name__c) ||
                String.IsNotBlank(objOppty.Honoree_Middle_Name__c) || String.IsNotBlank(objOppty.Honoree_Last_Name__c) || String.IsNotBlank(objOppty.Honoree_Suffix__c) ||
              String.IsNotBlank(objOppty.Non_Person__c) || String.IsNotBlank(objOppty.Recipient_Acknowledgment_Code__c) || String.IsNotBlank(objOppty.Recipient_Acknowledgement_Status__c)));
        }
    }



    public void initialize(Opportunity objOppty, Integer recCount, Boolean isSplit, Boolean isSplitParent, Boolean isNew) {
      // Common commands for all constructors
      this.objOppty = objOppty;
      this.recCount = recCount;
      this.isSplit = isSplit;
      this.isSplitParent = isSplitParent;
      this.isNew = isNew;
      this.showOpenPledgeIcon = false;
      this.csvRecord = '';
      this.accountNumber = objOppty.Account_Number_BGE__c;
    }

    private void initializeCampaignRTAndAccount() {
      this.campaignName = this.objOppty.Campaign.Name;
      this.selectedRT = this.objOppty.RecordType.Name;
      this.accountName = this.objOppty.Account.Name;
      this.proposalName = (this.objOppty.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID) ? this.objOppty.Proposal__r.Name:this.objOppty.rC_Giving__Parent_Name__c;
      //this.affiliation = this.objOppty.Account.Affiliation__c;
    }

    private void initializeTypeSourceAndProgram() {
      this.accountType = this.objOppty.Account.Account_Type__c;
      this.hiddenSourceCode = this.objOppty.rC_Giving__Campaign_Source_Code__c;
      this.programType = this.objOppty.Program_Type__c;
    }

    // Called from Add Rows Method
    public OpportunityWrapper(Opportunity objOppty, Integer recCount, Integer batchSeq, Boolean isSplit, Boolean isSplitParent, Batch_Log__c batchLogRec, Boolean isNew, String sourceCde, String progtype, Boolean isadjustBatchType) {
      initialize(objOppty, recCount, isSplit, isSplitParent, isNew);
      objOppty.Batch_Log__c = batchLogRec.Id;
      objOppty.IsCreatedFromBatchLog__c = True;

      if (batchLogRec.Batch_Date__c != null) {
        objOppty.Batch_Date__c = batchLogRec.Batch_Date__c;
        /* Ana Ferreira Feb 5th
        BGE-57 populate Batch Date/ Bank Date/ Tax Date */
        objOppty.Bank_Date__c = batchLogRec.Bank_Date__c;
      }

      if (batchLogRec.Default_Campaign__c != null) {
        objOppty.CampaignId = batchLogRec.Default_Campaign__c;
      }
      if (batchLogRec.Default_Payment__c != 'Charge Card' && batchLogRec.Default_Payment__c != 'EFT') {
        objOppty.rC_Giving__Payment_Method__c = batchLogRec.Default_Payment__c;
      }

      if (batchLogRec.Payment_Subtype__c != null && !isSplit) {
        objOppty.Payment_Subtype__c = batchLogRec.Payment_Subtype__c;
      }
      /* Traction(Mounica V) BGE-61, 12/6/2019 : Added new defaults */
       if (batchLogRec.Default_Check__c != null) {
        objOppty.rC_Giving__Check_Number__c = batchLogRec.Default_Check__c;
      }
      if (batchLogRec.Default_Check_Date__c != null) {
        objOppty.rC_Giving__Check_Date__c = batchLogRec.Default_Check_Date__c;
      }
       if (batchLogRec.Default_Fund__c != null) {
        objOppty.Fund__c = batchLogRec.Default_Fund__c;
      }
      if (batchLogRec.Default_Gift_Amount__c != null) {
        objOppty.rC_Giving__Giving_Amount__c = batchLogRec.Default_Gift_Amount__c;
      }
      if (batchLogRec.Default_Account_Code__c != null) {
        objOppty.Account_Code__c = batchLogRec.Default_Account_Code__c;
      }// BGE-61 END

      if (!isNew) {
        this.hiddenSourceCode = objOppty.rC_Giving__Campaign_Source_Code__c;
        this.programType = objOppty.Program_Type__c;
        this.sourceCodeOverride = false;
      } else {
        this.hiddenSourceCode = sourceCde;
        this.programType = progtype;
        this.sourceCodeOverride = false;
      }

      objOppty.CloseDate = (batchLogRec.Batch_Date__c != null) ? batchLogRec.Batch_Date__c : system.today();
      objOppty.StageName = 'Open';
      objOppty.Deposit_Site__c = batchLogRec.Deposit_Site__c;
      objOppty.Batch_Sequence__c = String.ValueOf(batchSeq);
      this.batchSequence = String.ValueOf(batchSeq);
      objOppty.rC_Giving__Giving_Frequency__c = 'One Payment';
      objOppty.Tax_Date__c = batchLogRec.Tax_Date__c != null ? batchLogRec.Tax_Date__c : batchLogRec.Batch_Date__c;
      objOppty.Acknowledgment_Status__c = 'N - Not Acknowledged';
      objOppty.Accounting_Date__c = batchLogRec.Batch_Date__c;

      this.isadjustBatchType = isadjustBatchType;
      this.campaignName = batchLogRec.Default_Campaign__r.Name;
      this.selectedRT = objOppty.RecordType.Name;
      this.accountName = objOppty.account.Name;
      this.proposalName = (this.objOppty.recordTypeId == OPP_RT_PLEDGE_PAYMENT_ID) ? this.objOppty.Proposal__r.Name:this.objOppty.rC_Giving__Parent_Name__c;
      //this.affiliation = this.objOppty.Account.Affiliation__c;
    }

    // Called from addSplitRow method
    public OpportunityWrapper(Opportunity objOppty, String selectedRT, String accountName, String campaignName, Integer recCount, Integer batchSeq, Boolean isSplit, Boolean isSplitParent, Boolean isNew, String proposalName, Boolean isadjustBatchType) {
      initialize(objOppty, recCount, isSplit, isSplitParent, isNew);
      this.isadjustBatchType = isadjustBatchType;
      this.campaignName = campaignName;
      this.selectedRT = selectedRT;
      this.accountName = accountName;
      this.proposalName = proposalName;
      this.batchSequence = String.ValueOf(batchSeq);
      initializeTypeSourceAndProgram();

      objOppty.IsCreatedFromBatchLog__c = True;
    }

    // Called from PopulateOpportunityWrapper (non-adjust batches),
    // SoftCredit populateChildOpportunityWrapper,addChildRows, matchOpportunity Methods
    public opportunityWrapper(Opportunity objOppty, Integer recCount, Boolean isSplit, Boolean isSplitParent, Boolean isNew, Boolean isadjustBatchType) {
      this.isadjustBatchType = isadjustBatchType;
      initialize(objOppty, recCount, isSplit, isSplitParent, isNew);
      initializeCampaignRTAndAccount();
      initializeTypeSourceAndProgram();
    }

    // Called from PopulateOpportunityWrapper Method (for Adjust batches only)
    public opportunityWrapper(Opportunity objOppty, Integer recCount, Boolean isSplit, Boolean isSplitParent, Boolean hasSoftCredits, Boolean isNew, Boolean isadjustBatchType) {
      this.isadjustBatchType = isadjustBatchType;
      initialize(objOppty, recCount, isSplit, isSplitParent, isNew);
      initializeCampaignRTAndAccount();
      initializeTypeSourceAndProgram();

      this.hasSoftCredits = hasSoftCredits;
      this.isadjustBatchType = isadjustBatchType;
    }
  }

  public class CopyOpportunityWrapper {
    public Id matchingAccId;
    public CopyOpportunityWrapper(Id matchingAccId) {
      this.matchingAccId = matchingAccId;
    }
  }

  // Wrapper Class to Store Batch Preference Information
  public class BatchPreferenceWrapper {
    public String fieldApiName {get; set;}
    public String label {get; set;}
    public Schema.DisplayType fieldtype {get;set;}

    public BatchPreferenceWrapper(String fieldApiName, String fieldLabel, Schema.DisplayType fieldType) {
      this.fieldApiName = fieldApiName;
      this.label = fieldLabel;
      this.fieldtype = fieldType;
    }
  }

  public void changeActiveOppt() {
    Integer activeOpptyIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('activeOpptyIndex'));
    if (opportunityWrapperLst.size() > activeOpptyIndex) {
      activeOpportunity = opportunityWrapperLst[activeOpptyIndex];
      ImoaccountName = activeOpportunity.objOppty.Ack_Recipient_Account__r.name;
      campaignId_Old = activeOpportunity.objOppty.campaignId;
      amount_Old = amount(activeOpportunity, isAdjustBatch); //sai-7/28:Change

      if(activeOpportunity.selectedRT == 'Pledge' && !activeOpportunity.isNew){
          checkProposalGrantsButton(activeOpportunity.objOppty.accountId);
      }
     // bge-41
     if(activeOpportunity.objOppty.rC_Giving__Opportunity_Credits__r.size() >0 )  {
          newCredit = activeOpportunity.objOppty.rC_Giving__Opportunity_Credits__r;
      }
      else
      if(activeOpportunity.objOppty.rC_Giving__Opportunity_Credits__r.size() == 0 || activeOpportunity.objOppty.Id ==  NULL ){
          newCredit = new rC_Giving__Opportunity_Credit__c();
          newCredit.rC_Giving__Distribution__c = 100.0;
          newCredit.rC_Giving__Type__c = 'Account Only';
          newCredit.Payment_Issuer__c = batchLog.Default_Payment_Issuer__c;

      }
      //bge-41 ends
    }
  }

  // If the Opportunity is Pledge, then button will show only If Propsals/Grants are present
  public void checkProposalGrantsButton(Id accountId){
    List<Opportunity> Opps = new List<Opportunity> ();
    Map<Id, Boolean> hasOpenPledges = new Map<Id, Boolean>();
    // Fetch Opportunites (Pledge, Open Pledge Payments, Proposals, Grants)
    // Is this query selective? Yes!
    Opps = [SELECT Id, AccountId, RecordTypeId
            FROM Opportunity
            WHERE accountId  =:accountId
              AND (
                RecordTypeId = : opptyRTMap.get('Grant').getRecordTypeId()
                OR RecordTypeId = : opptyRTMap.get('Proposal').getRecordTypeId()
                OR (
                  RecordTypeId = : opptyRTMap.get('Pledge Payment').getRecordTypeId()
                  AND stageName = 'Open' AND IsCreatedFromBatchLog__c = false))];

    activeOpportunity.showOpenPledgeIcon = false;
    for (Opportunity opp : opps) {
      if (userHasPledgeAccess && opp.RecordTypeId != opptyRTMap.get('Pledge Payment').getRecordTypeId()) {
        activeOpportunity.showOpenPledgeIcon = true;
        break;
      }
    }

  }

  public void cancelRowChange() {
    refreshOppt();
  }

  public void refreshOppt() {
    count = 0;
    batchSeq = 0;
    //mapOfOppIdAndOpps = new Map<Id, Opportunity>();
    setAccountIds = new Set<Id>();
    opportunityWrapperLst = new List<OpportunityWrapper>();
    copyOpptyWrapperLst = new Map<Id, CopyOpportunityWrapper>();
    populateOpportunityWrapper();
    activeOpportunity = null;
    populateShowPledges();
  }

  public void resetExternalId() {
      Boolean error = checkBatchLogReleaseValidity();
      if(!error){
          list<Opportunity> oppList = [SELECT Id, rC_Giving__External_ID__c
                                        FROM Opportunity
                                        WHERE Batch_Log__c = :batchLogId
                                        AND rC_Giving__External_ID__c = 'Flagged for MembershipShareCode Reset'];
          for(Opportunity opp : oppList) {
              opp.rC_Giving__External_ID__c = null;
          }
          try {
                update oppList;
                //BatchLogTriggerHandler.skipSharingCodeCalucation = true;
                update new Batch_Log__c(Id = batchLogId, Batch_Log_Status__c = 'Balanced');
          } catch(Exception e) {
              Exceptionutils.createApexLog('BatchLogDetailPageController','resetExternalId',e);
          }
      }
  }
  public void callApexBatchResetMembership() {
      Boolean error = checkBatchLogReleaseValidity();
      if(!error){
        Database.executeBatch(new BatchResetMembership(batchLogId), 1);
      }
  }

  public static Boolean IsAsyncProcessingRequired(Decimal batchLogActualAmount){
      if( batchLogActualAmount < Integer.valueOf(Label.Batch_Log_Async_Processing_Required)){
          return false;
      } else {
          return true;
      }
  }

  public static void processUpsertResults(List<Database.UpsertResult> results, List<sObject> lstObj, String Classname,String Methodname,
                                                            String ErrorMessage ){
      integer i = 0;
      set<String> messages;
      apexLogHandler.apexLog log;
        for (Database.UpsertResult result : results) {
          messages = new set<String>();
          if (!result.isSuccess()){
            for (Database.Error err : result.getErrors()){
              if(!messages.contains(err.getMessage())) {
                log = new apexLogHandler.apexLog(Classname,Methodname,
                                                 ErrorMessage+ lstObj[i].id + '\n' + err.getMessage());
                messages.add(err.getMessage());
              }
            }
          }
          i++;
        }
      if(log != null) {
        log.saveLogs();
      }
    }

    /* Modified By: Amar Kulkarni (rC) :: 07-Jun-18
     * Desc: TS-276/I-326264 - Adjustment Actual/Expected Count mismatch, cannot release
     * Problem: After refreshing the page user were not able to adjust but to create another D & B Transaction for the giving
    */
    private Boolean isTransactionAlreadyAdjusted() {
        if (String.isBlank(adjustedTransactionId)) {
            return false;
        }
        Opportunity currentTransaction = [
            SELECT Id
                 , recordType.Name
              FROM Opportunity
             WHERE Id = :adjustedTransactionId
             LIMIT 1
        ];

        return currentTransaction.recordType.Name == 'Adjustment';
    }
   /* Mounica V: BGE-41, Preparing the report URL to view all credits*/
  public void ViewAllCredits(){
  reportCreditsURL = '/'+label.BatchLog_Credit_Report_URL;
  reportOppURL = '/'+label.Batch_Log_Opp_Report_ID;
  if(String.valueOf(activeOpportunity.objOppty.accountId).Length() > 15)
  reportCreditsURL = '/'+label.BatchLog_Credit_Report_URL+'?pv0='+String.valueOf(activeOpportunity.objOppty.accountId).substring(0, 15);
  if(activeOpportunity.objOppty.id <> null && String.valueOf(activeOpportunity.objOppty.id).Length() > 15)
  reportOppURL =  '/'+label.Batch_Log_Opp_Report_ID+'?pv0='+String.valueOf(activeOpportunity.objOppty.id).substring(0, 15);
  }

}