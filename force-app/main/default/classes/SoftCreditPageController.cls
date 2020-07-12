/*
*
*Name  :  SoftCreditPageController
*Author:  Appirio India (Saikrishna Tavva)
*Date  :  June 13, 2017
*Purpose :  Controller class for SoftCreditPage which is initiated in BGE
            Logic includes getters, setters, creating and updating soft credit records
*
*/
global class SoftCreditPageController {

  public static Map<String, Schema.RecordTypeInfo> opptyRtMap{get;set;}
  public List<OpportunityWrapper> childOppWrapperLst {get;set;}
  public OpportunityWrapper activeOpportunity {get; set;}
  public String childOppWrapperLstJSON {
    get {
      return JSON.serialize(childOppWrapperLst);
    }
  }
  public static Opportunity temporaryOpportunity {get;set;}
  public Decimal sumOfAmountOfAllSoftCredits {get;set;}
  public map<String,Integer> softColOrderMap {get;set;}
  public static Boolean userHasPledgeAccess {get;set;}
  public Set<Id> setSoftCreditAccountIds {get;set;}
  public Boolean isParentReleased {get;set;}//sai 7/7-Change
  public String softCreditHeaders {get;set;}
  public Opportunity OppToUpdate {get;set;}
  public opportunity parentOpp {get;set;}
  public Boolean closeIHOPopup {get;set;}
  public String ImoaccountName {get;set;}
  public static String accType {get;set;}
  public Batch_Log__c batchLog {get;set;}
  public Boolean isAdjustBatch {get;set;}
  public Boolean isChanged {get;set;}
  public Boolean isMatchingAmount {get;set;}
  public String affiliateCode {get;set;}
  public Boolean isError {get;set;}
  public Id ParentOppId {get;set;}
  public Id relatedTransactionId {get;set;}
  public Id batchLogId {get;set;}
  public Integer selectdOpptyForImo;
  public static Integer staticPageSize;
  public String relation;
  public Decimal parentAmountfield {get;set;}
  
  // Gift Error Messages
  public static final String ACCOUNT_REQUIRED = 'Account field is required on all Gifts.';
  public static final String SC_TYPE_REQUIRED = 'Soft Credit Type field is required on all Gifts.';
  public static final String AMOUNT_REQUIRED = 'Amount field is required on all Gifts.';
  public static final String NO_ZERO_DOLLAR_GIFTS = 'You are not allowed to create $0 Gifts.';
  public static final String TRIBUTE_TYPE_REQUIRED = 'Tribute Type field is required';


  static{
    temporaryOpportunity = new Opportunity();
    opptyRtMap = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName();
  }

  // Constructor
  public SoftCreditPageController(ApexPages.standardController controller) {
    childOppWrapperLst = new List<OpportunityWrapper>();
    softColOrderMap = new Map<String,Integer>();
    setSoftCreditAccountIds = new set<Id>();
    softCreditHeaders = '';
    sumOfAmountOfAllSoftCredits = 0;
    isError = isChanged = isMatchingAmount = false;
    isParentReleased = (apexPages.currentPage().getParameters().get('isReleased') != null? Boolean.valueOf(apexPages.currentPage().getParameters().get('isReleased')): false); //sai:7/7-Change
    userHasPledgeAccess = BatchLogDetailPageController.hide_OpenProsposals();
    parentOppId = String.valueOf(ApexPages.currentPage().getParameters().get('parentOppId'));
    batchLogId = String.valueOf(ApexPages.currentPage().getParameters().get('batchLogId'));
    parentOpp= new Opportunity();

    if(batchLogId != null) {
      batchLog = [ SELECT Id, Name, Batch_Log_Type__c, Default_Campaign__r.rC_Giving__Sub_Affiliation__c, Batch_Type__c, Accounting_Date__c, 
                    Default_Campaign__c, Default_Campaign__r.rC_Giving__Source_Code__c, Default_Campaign__r.Name, Batch_Log_Status__c, Bank_Date__c, 
                    Deposit_Site__c, Default_Payment__c, Batch_Date__c, Actual_Amount__c, Expected_Amount__c, Actual_Count__c, Expected_Count__c, 
                    Tax_Date__c, Payment_Subtype__c, Program_Type__c, Affiliation__c, Days_Open__c
                   FROM Batch_Log__c 
                   WHERE Id =: batchLogId ];
      affiliateCode = batchLog.Name.substring(0,2);
      isAdjustBatch = batchLog.Batch_Type__c == 'Adjustment' ? true : false;
    }
    
    if(parentOppId != null) {
      parentOpp = [SELECT Id, rC_Giving__Parent__c, account.Account_Number__c, Bank_Date__c, closeDate, account.Name, rC_Giving__Giving_Amount__c, amount, recordType.Name FROM Opportunity WHERE Id=:parentOppId LIMIT 1 ];
      
      if(isAdjustBatch) {
        List<opportunity> objDTrans=[SELECT Id, amount FROM Opportunity WHERE rC_Giving__Parent__c=: parentOppId AND (Adjustment_Code__c = 'D' 
                                                                                                OR Adjustment_Code__c = 'N'  ) Limit 1];
        parentAmountfield = (objDTrans != null && !objDTrans.IsEmpty()&& objDTrans[0] != null)? objDTrans[0].amount:0;
      }
      else {
        parentAmountfield = Parentopp.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId() && Parentopp.Amount != null ? Parentopp.Amount
                                                        : (Parentopp.rC_Giving__Giving_Amount__c != null ?  Parentopp.rC_Giving__Giving_Amount__c : 0.0);
      }
    }
    populateChildOpportunityWrapper();
    sftAmount();
  }

  //Recalculates sftAmount
  public void updateSftAmount(){
    sftAmount();
  }

  //Remoting Function
  @RemoteAction
  global static List<String> populateAccountLookup(String row, String accNumber){
    List<Account> accs = [Select Id, Name From Account WHERE Account_Number__c =: accNumber LIMIT 50000 ];
    if(accs.size() == 1 && !accs.IsEmpty()){
      List<String> result = new List<String>();
      result.add('True');
      result.add(String.ValueOf(accs[0].Id));
      result.add(String.ValueOf(accs[0].Name));
      return result;
    }
    else{
      List<String> result = new List<String>();
      result.add('FaLsE');
      return result;
    }
  }

  //get Relevant Acknowledgment Code
  public List<SelectOption> getAcknowledgementCodePicklist(){
    List<SelectOption> acknowledgementCodePicklist = new List<selectOption>();
    acknowledgementCodePicklist.add(new SelectOption('','None'));
    List<Acknowledgement_Code_Mapping__mdt> acknowledgementCodeValues = new List<Acknowledgement_Code_Mapping__mdt>();
    String affiliationCode;
    List<Acknowledgement_Code_Mapping__mdt> AckCodeMapping = new List<Acknowledgement_Code_Mapping__mdt>();
    if(!String.IsBlank(affiliateCode)){
      affiliationCode = String.ValueOf(affiliateCode).Substring(0,2);
      AckCodeMapping = [SELECT Id,Acknowledgement_Code__c, Batch_Log_Affiliation_Code__c  FROM Acknowledgement_Code_Mapping__mdt WHERE Batch_Log_Affiliation_Code__c =: affiliationCode LIMIT 1];
    }

    if(AckCodeMapping.size()>0 && AckCodeMapping[0].Acknowledgement_Code__c != null && !AckCodeMapping.isEmpty()){
      for(String str: String.ValueOf(AckCodeMapping[0].Acknowledgement_Code__c).Split(';')){
        acknowledgementCodePicklist.add(new SelectOption(str,str));
      }
    }
    return acknowledgementCodePicklist;
  }

  // Get Opportunity FieldSet Fields
  public List<Schema.FieldSetMember> getFields(String fsName) {
    return SObjectType.Opportunity.FieldSets.getMap().get(fsName).getFields();
  }


  public void populateChildOpportunityWrapper() {
    childOppWrapperLst = new List<OpportunityWrapper>();

    Integer K=0;
    for(Schema.FieldSetMember f : this.getFields('Soft_Credit_FieldSet')){
      softColOrderMap.put(f.getLabel(),K++);
    }

    String query = 'SELECT ';
    for(Schema.FieldSetMember f : SObjectType.Opportunity.FieldSets.Soft_Credit_FieldSet.getFields()) {
      query += f.getFieldPath() + ', ';
    }

    query += 'Id, Batch_Log__c, Account.Account_Type__c, Program_Type__c, Opportunity.rC_Giving__Campaign_Source_Code__c, rC_Giving__Tribute_Type__c, Honoree_Title__c, Honoree_First_Name__c, Honoree_Middle_Name__c, Honoree_Last_Name__c, ';
    query += 'Honoree_Suffix__c, Non_Person__c, Tribute_Message_Body__c, Ack_Recipient_Account__c, Ack_Recipient_Account__r.Name, Ack_Recipient_Account__r.Account_Type__c, Ack_Recipient_Full_Name__c, Ack_Recipient_Street_Line_1__c,';
    query += 'Ack_Recipient_Street_Line_2__c, Posted_to_GL_Checkbox__c, rC_Giving__Transaction_Type__c, Ack_Recipient_City__c, Ack_Recipient_State__c, Campaign.Name, Ack_Recipient_Country__c, Recordtype.Name, ';
    query += ' Adjustment_Reason_Type__c, account.Name, Adjustment_Code__c, rC_Giving__Parent__c, Related_Transaction__c, rC_Giving__Current_Giving_Amount__c, Recipient_Acknowledgment_Code__c, ';
    query += ' rC_Giving__Source_Code__c, rC_Giving__Last_Giving_Amount_Adjustment_Date__c, Recipient_Acknowledgement_Status__c, Proposal__r.name ';
    query += ' FROM Opportunity WHERE ((rC_Giving__Parent__c = \''+parentOppId+'\' AND RecordType.Name = \'Soft Credit\') OR (rC_Giving__Parent__r.rC_Giving__Parent__c = \''+parentOppId+'\' AND RecordType.Name = \'Soft Credit\') OR  (RecordType.Name = \'Pledge Payment\' AND Related_Transaction__c= \''+parentOppId+'\' ) OR (RecordType.Name = \'Pledge Payment\' AND Related_Transaction__r.rC_Giving__Parent__c= \''+parentOppId+'\' ))';

    if(isAdjustBatch) {
      query += ' AND Adjustment_Code__c != \'A\'';
      query += ' AND Adjustment_Code__c != \'B\'';
    }

    Integer count=0;
    for(Opportunity objOppty : Database.query(query)) {
      childOppWrapperLst.add(new OpportunityWrapper(objOppty, count + 1, false, false, false));
      setSoftCreditAccountIds.add(objOppty.accountId);
      count = count + 1; // Maintaining Total Record countsts.
    }

    populateChildShowPledges();
  }

  public void populateChildShowPledges (){
    Map<Id, List<Opportunity>> mapOpportunities = new Map<Id,List<Opportunity>>();

    for(Opportunity Opp: [SELECT Id, Name, accountId, RecordTypeId, recordType.Name, rC_Giving__Giving_Amount__c, amount, closeDate, campaignId, 
                            campaign.Name, campaign.rC_Giving__Source_Code__c, StageName, rC_Giving__Parent__c
                          FROM Opportunity 
                          WHERE accountId =: setSoftCreditAccountIds 
                            AND (RecordTypeId =: opptyRTMap.get('Grant').getRecordTypeId() 
                              OR RecordTypeId =: opptyRTMap.get('Proposal').getRecordTypeId() 
                              OR (RecordTypeId =: opptyRTMap.get('Pledge Payment').getRecordTypeId() AND stageName = 'Open' ))]) {
      if(mapOpportunities.ContainsKey(opp.accountId)) {
        mapOpportunities.get(opp.accountId).add(opp);
      }
      else {
        mapOpportunities.put(opp.accountId,new List<Opportunity>{opp});
      }
    }

    for(opportunityWrapper objWrapper: childOppWrapperLst) {
      if(mapOpportunities.containsKey(objWrapper.objOppty.accountId) && !mapOpportunities.get(objWrapper.objOppty.accountId).IsEmpty() ) {
        if(userHasPledgeAccess == false) {
          for(Opportunity obj: mapOpportunities.get(objWrapper.objOppty.accountId)){
            if(obj.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId()){
              objWrapper.showOpenPledgeIcon = true;
              break;
            }
          }
        }
        else {
          objWrapper.showOpenPledgeIcon = true;
        }
      }
    }
  }

  //Add Child Rows
  public void addChildRows(){//change
    OpportunityWrapper objWrapper = new OpportunityWrapper(new Opportunity(), childOppWrapperLst.size() + 1, false, false, true);
    
    objWrapper.objOppty.StageName = ACLU_Constants.CONST_OPPTY_STAGE_OPEN;
    objWrapper.objOppty.rC_Giving__Parent__c = parentOppId;
    objWrapper.selectedRT = 'Soft Credit';
    objWrapper.objOppty.RecordTypeId = opptyRTMap.get('Soft Credit').getRecordTypeId();
    objWrapper.objOppty.Name = 'Dummy Name';// Will be updated by Workflow Rule.
    Opportunity opp = [SELECT Id, recordType.Name, rC_Giving__Parent__r.CampaignId,rC_Giving__Parent__r.Campaign.Name, CloseDate,Campaign.Name, CampaignId, RecordTypeId, Restriction__c From Opportunity Where Id =: parentOppId LIMIT 1];
    objWrapper.objOppty.CloseDate = opp.CloseDate;
    if(opp.recordType.Name != ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT){
      objWrapper.campaignName = opp.Campaign.Name;
      objWrapper.objOppty.CampaignId = opp.CampaignId;
    }
    else{
      objWrapper.campaignName = opp.rC_Giving__Parent__r.Campaign.Name;
      objWrapper.objOppty.CampaignId = opp.rC_Giving__Parent__r.CampaignId;
    }
    objWrapper.objOppty.Restriction__c = opp.Restriction__c;
    objWrapper.objOppty.Deposit_Site__c = objWrapper.objOppty.Related_Transaction__r.Deposit_Site__c;
    objWrapper.objOppty.Adjustment_Code__c = '';
    objWrapper.objOppty.rC_Giving__Payment_Method__c = 'Cash/Check';
    objWrapper.objOppty.IsCreatedFromBatchLog__c = true;
    objWrapper.objOppty.Batch_Log__c = batchLogId;
    //T-647274 update (Populate dates on creation of Soft credit)
    objWrapper.objOppty.Batch_Date__c = batchLog.Batch_Date__c;
    objWrapper.objOppty.Bank_Date__c = batchLog.Bank_Date__c;
    objWrapper.objOppty.Tax_Date__c = batchLog.Tax_Date__c;
    
    childOppWrapperLst.add(objWrapper);

    // Fetch Related Transaction Of Donation
    objWrapper.objOppty.Related_Transaction__c = getRelatedTransactionId();
    ImoaccountName = null;
  }
    
  //getrelatedTransactionId
  public Id getRelatedTransactionId(){
    Id opptyId;
    
    if(parentOpp.RecordTypeId == opptyRTMap.get('Donation').getRecordTypeId()) {
      //Assuming Donation will always have 1 Transaction only.
      Opportunity theTransaction = [SELECT Id FROM Opportunity WHERE RecordTypeId =: opptyRTMap.get('Transaction').getRecordTypeId() AND rC_Giving__Parent__c =: parentOppId LIMIT 1];
      opptyId= theTransaction.Id;
    } else if(parentOpp.RecordTypeId == opptyRTMap.get('Pledge Payment').getRecordTypeId()) {
      opptyId= parentOppId;
    }
    return opptyId;
  }

    // Method To Delete Soft Credit Opportunity Row.
  public PageReference deleteSoftCRow() {
    List<Opportunity> sCreditToDelete = new List<Opportunity>();
    Integer rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('delSoftC_Index'));
    if(childOppWrapperLst.get(rowIndex - 1).objOppty.Id != null){
      Opportunity delOpp = childOppWrapperLst.get(rowIndex - 1).objOppty;
      delOpp.rC_Giving__Tribute_Type__c = null;
      delOpp.Honoree_Title__c = null;
      delOpp.Honoree_First_Name__c = null;
      delOpp.Honoree_Middle_Name__c = null;
      delOpp.Honoree_Last_Name__c = null;
      delOpp.Honoree_Suffix__c = null;
      delOpp.Non_Person__c = null;
      delOpp.Recipient_Acknowledgment_Code__c = null;
      delOpp.Recipient_Acknowledgement_Status__c = null;
      delOpp.Tribute_Message_Body__c = null;
      delOpp.Ack_Recipient_Full_Name__c = null;
      delOpp.Ack_Recipient_Street_Line_1__c = null;
      delOpp.Ack_Recipient_Street_Line_2__c = null;
      delOpp.Ack_Recipient_City__c = null;
      delOpp.Ack_Recipient_State__c = null;
      delOpp.Ack_Recipient_Country__c = null;
      delOpp.Ack_Recipient_Outside_Salutation__c = null;
      delOpp.Ack_Recipient_Account__c = null;
      delOpp.Ack_Recipient_Account_Number__c = null;
      delOpp.Related_Transaction__c = null;
      delOpp.IsCreatedFromBatchLog__c = false;
      delOpp.Batch_Log__c = null;
      delOpp.rC_Giving__Hard_Credit_Account__c = null;
      delOpp.StageName = 'Open';
      delOpp.Third_Party_Pledge_Payment__c = false;
      sCreditToDelete.add(delOpp);
    }
    
    if(sCreditToDelete.isEmpty()) {
      refreshOppt();
    } else {
      Savepoint beforeSaving;
      try {
        // Create a savepoint to prevent partial DML updates
        beforeSaving = Database.setSavePoint();
        if (sCreditToDelete[0].RecordTypeId != opptyRTMap.get('Pledge Payment').getRecordTypeId()) {
          delete sCreditToDelete;
        }
        else{
          update sCreditToDelete;
        }
        //Separate DML to update the SoftCredit field.
        Boolean hasScredit = hasSoftCredit(parentOppId);
        updateHasSoftCreditFlag(hasScredit);
        refreshOppt();
        isChanged = true;
      }
      catch(exception e) {
        Database.rollback(beforeSaving);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('SoftCreditPageController','deleteSoftCRow',e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
    }
    return null;
  }

  public Void sftAmount(){
    sumOfAmountOfAllSoftCredits =0;
    for(OpportunityWrapper objWrapper : childOppWrapperLst){
      sumOfAmountOfAllSoftCredits = objWrapper.objOppty.Amount!= null ? sumOfAmountOfAllSoftCredits + objWrapper.objOppty.Amount : sumOfAmountOfAllSoftCredits;
    }
  }

  public void saveOneRow() {
    Boolean receivedError = saveChildRows(new OpportunityWrapper[] {activeOpportunity});
  }

  // Save Child Rows
  public Boolean saveChildRows(OpportunityWrapper[] opportunityWrappers){//change
    list<Opportunity> lstOpps = new list<Opportunity>();
    isError = false;
    for(OpportunityWrapper objWrapper : opportunityWrappers) {
      if(objWrapper.isNew) {
        objWrapper.objOppty.RecordTypeId = opptyRTMap.get('Soft Credit').getRecordTypeId();
      }
      
      if(isAdjustBatch){
        objWrapper.objOppty.Adjustment__c = true;
      }
      
      lstOpps.add(objWrapper.objOppty);
    }

    if ( !opportunityIsValid(opportunityWrappers)) {
      isError = true;
    } else if(!lstOpps.isEmpty()) {
      /*if(sumOfAmountOfAllSoftCredits == parentAmountfield ) {*/
      Savepoint beforeSaving;
      try {
        beforeSaving = Database.setSavePoint();
        upsert lstOpps;
        ImoaccountName = null;
        //Separate DML to update the SoftCredit field.
        Boolean hasScredit = hasSoftCredit(parentOppId);
        updateHasSoftCreditFlag(hasScredit);
        refreshOppt();
        isChanged = true;
      } catch(Exception e) {
        Database.rollback(beforeSaving);
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: '+Label.Exception_error_message);
        ApexPages.addMessage(myMsg);
        isError = true;
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('SoftCreditPageController','saveChildRows',e.getMessage());
        log.logException(e);
        log.saveLogs();
      }
      /*}
      else {
        isError = true;
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Total Amount of Soft Credit[s] do not match with Hard Credit Amount.');
          ApexPages.addMessage(myMsg);
          isError = true;
      }*/
    }
    return isError;
  }

  // Verifies the Required fields and sets field level errors
  public Boolean opportunityIsValid (OpportunityWrapper[] opportunityWrappers) {
    Boolean isValid = true;
    for (OpportunityWrapper objWrapper : opportunityWrappers) {
      Opportunity opp = objWrapper.objOppty;
      String rowName = 'Row # ' + String.valueOf(objWrapper.recCount);
      
      if (String.IsBlank(opp.AccountId)) {
        isValid = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ACCOUNT_REQUIRED));
      }
      if (String.IsBlank(opp.Soft_Credit_Type__c)) {
        isValid = false;
        opp.Soft_Credit_Type__c.addError(SC_TYPE_REQUIRED);
      }
      if (opp.Amount == null) {
        isValid = false;
        opp.Amount.addError(AMOUNT_REQUIRED);
      }
      if (opp.Amount == 0 && !isAdjustBatch) {
        isValid = false;
        opp.Amount.addError(NO_ZERO_DOLLAR_GIFTS);
      }
      // TributeType Required if any of IMO fields are populated
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
          String tributeError = TRIBUTE_TYPE_REQUIRED +
            ' since there are values in the field(s) ' +
            String.join(nonBlankFields,', ');
          opp.rC_Giving__Tribute_Type__c.addError(tributeError);
        }
      }
    }
    return isValid;
  }

  //update SoftCredit Flag on the Parent and RelatedTransaction records
  public void updateHasSoftCreditFlag(Boolean hasScredit){
    List<Opportunity> updateSoftCreditIndication= new List<Opportunity>();
    Id relatedTrnsId = getRelatedTransactionId();
    
    //Update Has Softcredit flag on the Pledge Payment/Donation record
    updateSoftCreditIndication.add(new Opportunity(Id =parentOppId, Has_Soft_Credits__c= hasScredit));
    if(parentOppId != relatedTrnsId){ 
        //Update Has Softcredit flag on Transaction Record
        updateSoftCreditIndication.add(new Opportunity(Id =relatedTrnsId, Has_Soft_Credits__c= hasScredit));
    }else{
        //Update Has Softcredit flag on Pledge Record (If PP as BatchLogItem)
        //This helps to show the Indication in Adjust batches as we are Pledges are BatchLogItems.
        updateSoftCreditIndication.add(new Opportunity(Id =parentOpp.rC_Giving__Parent__c, Has_Soft_Credits__c= hasScredit));
    }
    
    if(!updateSoftCreditIndication.isEmpty()){
      update updateSoftCreditIndication;
    }
  }

  // Update the SoftCredit to Open PledgePayments
  public PageReference updateParent(){
    isError = false;
    List<Opportunity> oppsToDel = new List<Opportunity>();
    Integer irow= Integer.ValueOf(Apexpages.currentPage().getParameters().get('row'));
    Id oppId = Id.valueOf(Apexpages.currentPage().getParameters().get('OpportId'));
    Boolean isOpenedFromSoftCreditTable = ApexPages.currentPage().getParameters().get('isOpenfromSft') != null ? Boolean.ValueOf(ApexPages.currentPage().getParameters().get('isOpenfromSft')) : false;
    Boolean isPledgePayment = Boolean.ValueOf(Apexpages.currentPage().getParameters().get('isPledgePayment'));
    string dynamicQuery = 'SELECT ';
    List <Opportunity> oppsToUpdate = new List <Opportunity>();
    List <Opportunity> oppsToAdd = new List <Opportunity>();

    if(isPledgePayment) {
      for(Schema.FieldSetMember f : this.getFields('Soft_Credit_FieldSet')) {
        dynamicQuery += f.getFieldPath() + ', ';
      }
      dynamicQuery += 'Id, IsCreatedFromBatchLog__c, Related_Transaction__c ';
      dynamicQuery += 'FROM Opportunity WHERE Id=:oppId LIMIT 1';

      Opportunity childOpp = Database.query(dynamicQuery);
      for(OpportunityWrapper wrapper: childoppWrapperLst) {
        if(wrapper.recCount == irow) {
          String srcCode = wrapper.hiddenSourceCode;
          childOpp.Batch_Log__c = batchLogId;
          childOpp.IsCreatedFromBatchLog__c = true;
          childOpp.Related_Transaction__c = wrapper.objOppty.Related_Transaction__c;
          childOpp.stageName = 'Open';
          childOpp.Proposal__c = wrapper.objOppty.Proposal__c;
          childOpp.Third_Party_Pledge_Payment__c = true;
          childOpp.Deposit_Site__c = batchLog.Deposit_Site__c;
          childOpp.Bank_Date__c = parentOpp.Bank_Date__c;
          childOpp.Batch_Date__c = (wrapper.objOppty.closeDate != null)?wrapper.objOppty.closeDate:parentOpp.closeDate;
          childOpp.Closedate = (wrapper.objOppty.closeDate != null)?wrapper.objOppty.closeDate:parentOpp.closeDate;
          childOpp.Tax_Date__c = wrapper.objOppty.Tax_Date__c;
          childOpp.Soft_Credit_Type__c = (String.isNotBlank(wrapper.ObjOppty.Soft_Credit_Type__c)) ? wrapper.ObjOppty.Soft_Credit_Type__c : 'TP - Third Party (eg Fidelity)';
          wrapper.selectedRT = ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT;

          if(wrapper.objOppty.Id != null) {
            oppsToDel.add(wrapper.objOppty);
          }
          wrapper.objOppty = childOpp;
          wrapper.isNew = false;
          wrapper.isPledgePaymentRecord = true;
          wrapper.objOppty.recordTypeId = opptyRTMap.get(wrapper.selectedRT).getRecordTypeId();
          oppsToUpdate.add(childOpp);

          // Update the Third_Party_Pledge_Payment__c to true on Donation/Pledge records. for Event Revenue report .
          if(!String.IsBlank(childOpp.Related_Transaction__c)) {
            Opportunity opp = [SELECT id, rC_Giving__Parent__c,rC_Giving__Parent__r.recordtypeId FROM Opportunity WHERE Id=:childOpp.Related_Transaction__c ];
            if(!String.IsBlank(opp.rC_Giving__Parent__c) && (opp.rC_Giving__Parent__r.recordTypeId == opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_DONATION).getRecordTypeId())) {
              oppsToUpdate.add(new Opportunity(Id=opp.rC_Giving__Parent__c, Third_Party_Pledge_Payment__c = true ));
            }
          }
        }
      }
    }else {
      for (OpportunityWrapper wrapper : childoppWrapperLst) {
        if (wrapper.recCount == irow) {
          wrapper.objOppty.Proposal__c = oppId;
          if(wrapper.objOppty.Id != null) {
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
      // Create a savepoint to prevent partial DML updates
      beforeSaving = Database.setSavePoint();
      if(!oppsToAdd.IsEmpty()) {
        insert oppsToAdd;
      }
      if(!oppsToUpdate.IsEmpty()) {
        update oppsToUpdate;
      }
      if(!oppsToDel.isEmpty()) {
        delete oppsToDel;
      }
      //Separate DML to update the SoftCredit field.
      Boolean hasScredit = hasSoftCredit(parentOppId);
      updateHasSoftCreditFlag(hasScredit);
      refreshOppt();
      isChanged = true;
    } catch(Exception e) {
      Database.rollback(beforeSaving);
      if (e.getTypeName() == 'System.DmlException') {
        for (Integer row = 0; row < e.getNumDml(); row++) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getDmlMessage(row)));
        }
      } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Exception_error_message));
      }
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('SoftCreditPageController','updateParent',e.getMessage());
      log.logException(e);
      log.saveLogs();
      isError = true;
    }
    return null;
  }

    // Method to Export Soft Credits through 'Export Soft Credits' Button.
  public PageReference exportSoftCredits() {
    String fieldValue;
    softCreditHeaders = '';
    Boolean isPopulatedHeader = false;

    for(OpportunityWrapper opptyWrapper : childOppWrapperLst) {
      fieldValue = '';
      for(Schema.FieldSetMember f : SObjectType.Opportunity.FieldSets.Soft_Credit_FieldSet.getFields()) {
        if(!isPopulatedHeader) {
          softCreditHeaders = softCreditHeaders == '' ? f.getLabel() : softCreditHeaders + ',  ' + f.getLabel();
        }
        if(f.getFieldPath() == Label.Opportunity_RecordType_API_Name) {
          fieldValue = opptyWrapper.selectedRT;
        } else if(f.getFieldPath() == Label.Opportunity_Account_API_Name) {
          fieldValue = opptyWrapper.accountName;
        } else if(f.getFieldPath() == Label.Opportunity_Campaign_API_Name) {
          fieldValue = opptyWrapper.campaignName;
        } else {
          fieldValue = String.ValueOf(opptyWrapper.objOppty.get(f.getFieldPath()));
        }
        opptyWrapper.csvRecord = opptyWrapper.csvRecord == null ? (fieldValue != null ? fieldValue : '') :
                                  opptyWrapper.csvRecord + ',   '+ (fieldValue != null ? fieldValue : '');
      }
      isPopulatedHeader = true;
    }
    return Page.SoftCreditCsvExportPage;
  }

  public void populateAckFields() {
    Map<Id, Account> billingAddressToAccMap = new Map<Id, Account>();
    String accNumber, accName ;
    if(activeOpportunity != null && activeOpportunity.objOppty != null && !String.isBlank(activeOpportunity.objOppty.Ack_Recipient_Account__c)) {
      for(Account acc : [SELECT Id, Name, Account_Number__c, rC_Bios__Preferred_Billing_Address__c, Formal_Outside_1__c
                         FROM Account
                         WHERE Id =: activeOpportunity.objOppty.Ack_Recipient_Account__c LIMIT 1]) {
        accNumber = acc.Account_Number__c;
        accName = acc.Name;
        if(!String.IsBlank(acc.rC_Bios__Preferred_Billing_Address__c)){
          billingAddressToAccMap.put(acc.rC_Bios__Preferred_Billing_Address__c, acc);
        }
      }
    }
    //If the account doesnt have Preferred Addres
    if(billingAddressToAccMap.keySet().ISEmpty() || billingAddressToAccMap.Keyset() == null){
      activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = accName;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_2__c = null;
      activeOpportunity.objOppty.Ack_Recipient_City__c = null;
      activeOpportunity.objOppty.Ack_Recipient_State__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Country__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Outside_Salutation__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Account_Number__c = accNumber;
    }
    for(rC_Bios__Address__c objAddress : [SELECT Id, rC_Bios__Street_Line_1__c, rC_Bios__Street_Line_2__c, rC_Bios__City__c,
                                          rC_Bios__State__c, rC_Bios__Country__c
                                          FROM rC_Bios__Address__c
                                          WHERE Id =: billingAddressToAccMap.keySet()]) {
      activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = billingAddressToAccMap.get(objAddress.Id).Name;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c = objAddress.rC_Bios__Street_Line_1__c;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_2__c = objAddress.rC_Bios__Street_Line_2__c;
      activeOpportunity.objOppty.Ack_Recipient_City__c = objAddress.rC_Bios__City__c;
      activeOpportunity.objOppty.Ack_Recipient_State__c = objAddress.rC_Bios__State__c;
      activeOpportunity.objOppty.Ack_Recipient_Country__c = objAddress.rC_Bios__Country__c;
      activeOpportunity.objOppty.Ack_Recipient_Outside_Salutation__c = billingAddressToAccMap.get(objAddress.Id).Formal_Outside_1__c;
      activeOpportunity.objOppty.Ack_Recipient_Account_Number__c = accNumber;
    }
    defaultReciepientAckStatusCode();
  }
  
  //populate default ReciepientackStatusCode.
  public void defaultReciepientAckStatusCode (){
      if(activeOpportunity != null && activeOpportunity.objOppty.Ack_Recipient_Account__c != null
         && activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c == null){
          activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c = 'N - Not Acknowledged';
      }
  }

  public void deleteIHOValues(){
    if(activeOpportunity.objOppty != null ){
      activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Street_Line_2__c = null;
      activeOpportunity.objOppty.Ack_Recipient_City__c = null;
      activeOpportunity.objOppty.Ack_Recipient_State__c = null;
      activeOpportunity.objOppty.Ack_Recipient_Country__c = null;
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

  //End IHO/IMO CODE
  public Boolean hasSoftCredit(Id parentOppId){
    List<Opportunity> opps= [SELECT Id FROM Opportunity WHERE ((rC_Giving__Parent__c =:parentOppId AND RecordType.Name = 'Soft Credit') OR (RecordType.Name = 'Pledge Payment' AND Related_Transaction__c=: parentOppId ) OR (RecordType.Name = 'Pledge Payment' AND Related_Transaction__r.rC_Giving__Parent__c=:parentOppId)) LIMIT 1];
    return ((!opps.isEmpty()) ? true : false);
  }

  //Changes the boolean Value to show/hide OpenPledges Icon
  public void populatePledgeBoolean(){
    Id selaccId= Id.ValueOf((Apexpages.currentPage().getParameters().get('selAccId')!= null ? Apexpages.currentPage().getParameters().get('selAccId'): null ));
    Integer selRow= Integer.ValueOf(Apexpages.currentPage().getParameters().get('selRow'));
    if(selaccId != null){
      for(OpportunityWrapper wrapper: childOppWrapperLst){
        if(wrapper.recCount == (selRow+1)){
          wrapper.showOpenPledgeIcon = BatchLogDetailPageController.checkOpenPledges(selaccId);
        }
      }
    }
  }

  // Opportunity Wrapper Class
  global class OpportunityWrapper {
    public Opportunity objOppty{get;set;}
    public Integer recCount{get;set;}
    public String selectedRT{get;set;}
    public Boolean isNew{get;set;}
    public String campaignName{get;set;}
    public Boolean isSplit{get;set;}
    public Boolean isSplitParent{get;set;}
    public String accountName{get;set;}
    public String accountNumber{get;set;}
    public String SourceCode {get;set;}
    public Boolean showOpenPledgeIcon {get;set;}
    public Boolean hasSoftCredits {get;set;}
    public Boolean isPledgePaymentRecord {get;set;}
    public String csvRecord {get;set;}
    public String accountType {get;set;}
    public String campProductsIds {get;set;}
    public String hiddenSourceCode {get;set;}
    public String programType {get;set;}
    public String proposalName {get;set;}
    
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
    
    public Boolean hasImoValues{
      get{
        return (
          objOppty != null 
          && (
            String.isNotBlank(objOppty.rC_Giving__Tribute_Type__c) || String.IsNotBlank(objOppty.Ack_Recipient_Full_Name__c) 
            || String.IsNotBlank(objOppty.Tribute_Message_Body__c) || String.IsNotBlank(objOppty.Ack_Recipient_Account__c) 
            || String.IsNotBlank(objOppty.Honoree_Title__c) || String.IsNotBlank(objOppty.Honoree_First_Name__c) 
            || String.IsNotBlank(objOppty.Honoree_Middle_Name__c) || String.IsNotBlank(objOppty.Honoree_Last_Name__c) 
            || String.IsNotBlank(objOppty.Honoree_Suffix__c) || String.IsNotBlank(objOppty.Non_Person__c) 
            || String.IsNotBlank(objOppty.Recipient_Acknowledgment_Code__c) || String.IsNotBlank(objOppty.Recipient_Acknowledgement_Status__c)
          )
        );
      }
    }

    public opportunityWrapper(Opportunity objOppty, Integer recCount, Boolean isSplit, Boolean isSplitParent, Boolean isNew) {
      this.objOppty = objOppty;
      this.recCount = recCount;
      this.isNew = isNew;
      this.isSplit = isSplit;
      this.campaignName  = objOppty.Campaign.Name;
      this.selectedRT = objOppty.RecordType.Name;
      this.isSplitParent = isSplitParent;
      this.accountName = objOppty.account.Name;
      if(String.IsBlank(objOppty.accountId)){
        this.showOpenPledgeIcon = BatchLogDetailPageController.checkOpenPledges(objOppty.accountId);
      }
      else{
        this.showOpenPledgeIcon = false;
      }
      this.isPledgePaymentRecord = (this.selectedRT == 'Pledge Payment')?true:false;
      this.accountType = objOppty.account.Account_Type__c;
      this.hiddenSourceCode = objOppty.rC_Giving__Campaign_Source_Code__c;
      this.programType = objOppty.Program_Type__c;
      this.proposalName = objOppty.Proposal__r.Name;
    }
  }

  public void changeActiveOppt() {
    Integer activeOpptyIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('activeOpptyIndex'));
    if (childOppWrapperLst.size() > activeOpptyIndex) {
      activeOpportunity = childOppWrapperLst[activeOpptyIndex];
      ImoaccountName = activeOpportunity.objOppty.Ack_Recipient_Account__r.name;
    }
  }
  
  public void cancelRowChange() {
    refreshOppt();
  }
  
  public void refreshOppt() {
    softColOrderMap = new Map<String, Integer>();
    setSoftCreditAccountIds = new set<Id>();
    populateChildOpportunityWrapper();
    activeOpportunity = null;
    sftAmount();
  }
  
  public void saveAndValidateAmount() {
    isError = false;
    if (activeOpportunity != null) {
      saveOneRow();
    } else {
      refreshOppt();
    }
    isMatchingAmount = false;
    if (childOppWrapperLst.size() == 0 || sumOfAmountOfAllSoftCredits == parentAmountfield ) {
      isMatchingAmount = true;
    }
  }
}