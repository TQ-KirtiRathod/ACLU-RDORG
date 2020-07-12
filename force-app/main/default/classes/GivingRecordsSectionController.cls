/*
*
*Name  :  GivingRecordsSectionController
*Author:  Appirio India (Sai Krishna )
*Date  :  March 06, 2017
*Purpose : Controller for the GivingRecordListWithAdjustments page. Account Layout displays a section "Giving Information" which 
*          conatins an inline VF page GivingViews_AccountLayout. This shows the opportunities in three sections each having a View More button. 
*          GivingRecordListWithAdjustments opens on the click of this button and shows all opportunities available for that section. 
*          It has a checkbox "Hide Adjustements" that show/hide the adjustment records.
*
*/
public class GivingRecordsSectionController {


    public list<Opportunity> OpptyToDisplay{get;set;}
    public String recordType {get;set;}
    public String fieldSetName {get;set;}
    public transient Map<String,Schema.RecordTypeInfo> opptyRTMap;
    public List<Schema.FieldSetMember> labelFieldSet {get;set;}
    public ApexPages.StandardSetController opp{get; set;} 
    public Integer pageSize;
    public Set<Id> recordTypeId; 
    public Boolean hideAdjustments {get;set;}
    public Boolean isProposal {get;set;}
    public ID accountId {get;set;}
    public String accountName {get;set;}
    public String sectionName {get;set;}
    private String donationRecTypeId;
    private String SoftCrRecTypeId;
    private String adjustmentRecTypeId;
    //Constructor
    public GivingRecordsSectionController(){
        OpptyToDisplay = new List<Opportunity>();
        opptyRTMap = new Map<String,Schema.RecordTypeInfo>();
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        recordTypeId = new Set <Id> (); 
        fieldSetName = ApexPages.currentPage().getParameters().get('fieldSet');//'AccountLayout_DonationSection';
        accountId = ApexPages.currentPage().getParameters().get('accId');
        accountName = [SELECT Id, Name FROM Account WHERE Id=:accountId LIMIT 1].Name;
        if(fieldSetName == 'AccountLayout_DonationSection'){
            recordTypeId.add(opptyRTMap.get('Donation').getRecordTypeId()); 
            recordTypeId.add(opptyRTMap.get('Transaction').getRecordTypeId());
            recordTypeId.add(opptyRTMap.get('Soft Credit').getRecordTypeId()); 
            recordTypeId.add(opptyRTMap.get('Pledge Payment').getRecordTypeId());
            isProposal = false;
            sectionName = 'Donations';
        }
        else if(fieldSetName ==  'AccountLayout_PledgeSection'){
            recordTypeId.add(opptyRTMap.get('Pledge').getRecordTypeId()); 
            //recordTypeId.add(opptyRTMap.get('Pledge Payment').getRecordTypeId());
            isProposal = false;
            sectionName = 'Pledges';
        }
        else if(fieldSetName ==  'AccountLayout_ProposalSection'){
            recordTypeId.add(opptyRTMap.get('Proposal').getRecordTypeId()); 
            recordTypeId.add(opptyRTMap.get('Grant').getRecordTypeId());
            isProposal = true;
            sectionName = 'Proposals';
        }
        donationRecTypeId = opptyRTMap.get('Donation').getRecordTypeId();
        SoftCrRecTypeId = opptyRTMap.get('Soft Credit').getRecordTypeId();
        adjustmentRecTypeId = opptyRTMap.get('Adjustment').getRecordTypeId();
        pageSize = 50;
        hideAdjustments = true;
        loadOpps();
        
    }
    
    /*
    Method hideAdjustments
    @description : hideAdjustmentsChanged
    */
    public void hideAdjustments(){
        opp = null;
        OpptyToDisplay = new List<Opportunity>();
        loadOpps();
    }
    
    /*
    Method loadOpps
    @description : Populates the Variable which holds the Opportunities
    */
    public void loadOpps() {
        set<String> adjustmntList = new Set<String>{'N','D', null};
        if(fieldSetName != null && opp == null) {
            labelFieldSet = this.getFields(fieldSetName);
            Integer i=0;
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : labelFieldSet) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id';
            if(!hideAdjustments) {
                recordTypeId.add(adjustmentRecTypeId);
            } else {
                recordTypeId.remove(adjustmentRecTypeId);
            }
            query += ' FROM Opportunity WHERE RecordTypeId !=: donationRecTypeId AND RecordTypeId =:recordTypeId AND accountId =:accountId' ;
            if(hideAdjustments){
                query += ' AND Adjustment_Code__c =:adjustmntList';// \'N\' OR Adjustment_Code__c = \'D\' ' ;
            }
            /*if(fieldSetName == 'AccountLayout_DonationSection' || fieldSetName == 'AccountLayout_PledgeSection'){
                query += ' AND Adjustment_Code__c != null';
            }*/
            if(fieldSetName == 'AccountLayout_DonationSection') {
                query += ' AND ( RecordTypeId = :SoftCrRecTypeId OR Adjustment_Code__c != null';
                if(!hideAdjustments) {
                    query += ' OR RecordTypeId = :adjustmentRecTypeId';
                }
                query += ')';
                //query += ' AND (RecordTypeId = :donationRecTypeId OR RecordTypeId = :SoftCrRecTypeId OR Adjustment_Code__c != null)';
            }
            query += ' ORDER BY closeDate desc, lastModifiedDate desc LIMIT 10000';
            opp = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            // sets the number of records in each page set
            opp.setPageSize(pageSize);
            for(Opportunity objOppty : (List<Opportunity>)opp.getRecords()) {
                OpptyToDisplay.add(objOppty);
            } 
            
        }
    }
    
    /*
    Method getFields
    @description : Get Opportunity FieldSet Fields 
    */
    public List<Schema.FieldSetMember> getFields(String fsName) {
        return SObjectType.Opportunity.FieldSets.getMap().get(fsName).getFields();
    }
    
    /*
    Method hasNext
    @description : indicates whether there are more records after the current page set. 
    */
    public Boolean hasNext {
        get { 
            if(opp!= null){
                return opp.getHasNext();
            }
            else{
                return true;
            }
        }
        set;
    }

    /*
    Method hasPrevious
    @description : indicates whether there are more records before the current page set. 
    */
    public Boolean hasPrevious {
        get {
            if(opp!= null){
                return opp.getHasPrevious();
            }
            else{
                return true;
            }
        }
        set;
    }
    
    /*
    Method previous
    @description : returns the previous page of records
    */
    public void previous() {
         if(opp!= null){
            opp.previous();
            OpptyToDisplay = (List<Opportunity>)opp.getRecords();
         }
     }

    /*
    Method next
    @description : returns the next page of records
    */
     // returns the next page of records
     public void next() {
         if(opp != null){
            opp.next();
            OpptyToDisplay = (List<Opportunity>)opp.getRecords();
            
         }
     }
    
}