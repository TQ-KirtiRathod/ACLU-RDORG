/*
*
*Name  :  createInlineOpportunityItemsCtrl
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Feb 05, 2017
*Purpose : Controller Class for createInlineOpportunityItems Page. 
*          This is likely depreciated, could not find where this is actually used but keeping in case
*
*/
public class createInlineOpportunityItemsCtrl {
    public List<OpportunityWrapper> opportunityWrapperLst {get;set;}
    public Batch_Log__c objBatchLog {get;set;}
    public List<Schema.FieldSetMember> labelFieldSet {get;set;}
    public Integer count = 0;
    public String fieldSetName;
    public static Map<String, String> batchTypeToFieldSetMap;
    public List<Opportunity> opptyLst;
    public static Map<String, Schema.RecordTypeInfo> opptyRtMap;
    public String selectedRT {get;set;}
    public List<SelectOption> getRecTypeValues() {
        List<SelectOption> recTypeOptions = new List<SelectOption>();
        recTypeOptions.add(new SelectOption('Donation','Donation'));
        recTypeOptions.add(new SelectOption('Pledge','Pledge'));
        recTypeOptions.add(new SelectOption('Pledge Payment','Pledge Payment'));
        return recTypeOptions;
    }
    
    static {
        batchTypeToFieldSetMap = new Map<String, String>();
        opptyRtMap = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName();
        Map<String, Batch_Type_To_Oppty_Field_Set_Mapping__c> fieldSetMapping = Batch_Type_To_Oppty_Field_Set_Mapping__c.getAll();
        if(fieldSetMapping != null) {
            for(Batch_Type_To_Oppty_Field_Set_Mapping__c cSetting : fieldSetMapping.values()) {
                batchTypeToFieldSetMap.put(cSetting.Batch_Type__c, cSetting.Field_Set_Name__c);
            }
        }
    }
    
    // Get Opportunity FieldSet Fields 
    public List<Schema.FieldSetMember> getFields(String fsName) {
        return SObjectType.Opportunity.FieldSets.getMap().get(fsName).getFields();
    }
    
    // Constructor
    public createInlineOpportunityItemsCtrl(ApexPages.standardController controller) {
        opportunityWrapperLst = new List<OpportunityWrapper>();
        opptyLst = new List<Opportunity>();
        
        Id batchLogId = controller.getId();
        
        if(batchLogId != null) {
            objBatchLog = [SELECT Id, Batch_Type__c, Bank_Date__c, Default_Campaign__c, Deposit_Site__c FROM Batch_Log__c WHERE Id =: batchLogId];
        }
        
        // Select Oppty Field Set based on Batch Type.
        if(!batchTypeToFieldSetMap.isEmpty() && batchTypeToFieldSetMap.containsKey(objBatchLog.Batch_Type__c)) {
            fieldSetName = batchTypeToFieldSetMap.get(objBatchLog.Batch_Type__c);
        }
        
        if(fieldSetName != null) {
            labelFieldSet = this.getFields(fieldSetName);
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : labelFieldSet) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id, Name FROM Opportunity WHERE Batch_Log__c = \''+objBatchLog.Id+'\'';
            
            for(Opportunity objOppty : Database.query(query)) {
                opportunityWrapperLst.add(new OpportunityWrapper(objOppty, count + 1, false));
                count = count + 1;
            }
        }
    }
    
    // Method To Add Opportunity Rows.
    public void addRows() {
        opportunityWrapperLst.add(new OpportunityWrapper(new Opportunity(), count + 1, objBatchLog, true));
        count = count + 1;
    }
    
    // Method To Delete Opportunity Row.
    public void deleteRow() {
        Integer rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
        opportunityWrapperLst.remove(rowIndex - 1);
        count = count - 1; 
    }
    
    // Method To Save Opportunity Rows.
    public void saveRows() {
        
        for(OpportunityWrapper objWrapper : opportunityWrapperLst) {
            if(objWrapper.isNew) {
                opptyLst.add(objWrapper.objOppty);
            }
        }
        
        if(!opptyLst.isEmpty()) {
            try{
                insert opptyLst;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('createInlineOpportunityItemsCtrl','saveRows',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    // Do Nothing.
    public void None() {
        
    }
    
    public void restrictCC() {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You are not allowed to Select Existing Charge Cards as Payment Method.'));
    }
    
    // Opportunity Wrapper Class
    public class OpportunityWrapper {
        public Opportunity objOppty{get;set;}
        public Integer recCount{get;set;}
        public Boolean isNew{get;set;}
        
        public opportunityWrapper(Opportunity objOppty, Integer recCount, Batch_Log__c batchLogRec, Boolean isNew) {
            objOppty.Batch_Log__c = batchLogRec.Id;
            if(batchLogRec.Bank_Date__c != null) {
                objOppty.Bank_Date__c = batchLogRec.Bank_Date__c;
            }
            if(batchLogRec.Default_Campaign__c != null) {
                objOppty.CampaignId = batchLogRec.Default_Campaign__c;
            }
            objOppty.CloseDate = system.today(); 
            objOppty.StageName = 'Completed';
            objOppty.Deposit_Site__c = batchLogRec.Deposit_Site__c;
            objOppty.Batch_Sequence__c = String.ValueOf(recCount);
            this.objOppty = objOppty;
            this.recCount = recCount;
            this.isNew = isNew;
        }
        
        public opportunityWrapper(Opportunity objOppty, Integer recCount, Boolean isNew) {
            this.objOppty = objOppty;
            this.recCount = recCount;
            this.isNew = isNew;
        }
    }
}