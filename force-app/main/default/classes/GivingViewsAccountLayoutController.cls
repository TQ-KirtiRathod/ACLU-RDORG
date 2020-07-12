/*
*
*Name  :  GivingViewsAccountLayoutController
*Author:  Appirio India (Sai Krishna )
*Date  :  March 06, 2017
*Purpose : Controller class for GivingViewsOnAccountLayout VF Component. It is a generic component to display opportunities on the 
*          custom VF page GivingViews_AccountLayout added on the Account Layout. Displays all the related opps in three sections : 
*          Donations & Pledge Payments, Pledges, Proposals & Grants.
* Modified by :: roundCorner Inc. :: 29 -Jan-2019 :: Zendesk: #55332
*
*/
public with sharing class GivingViewsAccountLayoutController {
    public list<Opportunity> OpptyToDisplay;
    public Set<Id> recordTypeId; 
    public String fieldSetName ;
    public transient Map<String,Schema.RecordTypeInfo> opptyRTMap;
    public List<Schema.FieldSetMember> labelFieldSet {get;set;}
    public ID accountId {get;set;}
    public String sectionName {get;set;}
	public String parentGivingName {get;set;}
    public String batchLogName{get;set;}
    public String primaryCampaignSource {get;set;}
    public string portfolio1 {get; set;}
    //Getter Setter Methods
    public void setfieldSetName(String name){
        fieldSetName = name;    
    } 
    
    public String getfieldSetName(){
        return fieldSetName; 
    }
    
    public void setOpptyToDisplay(List<Opportunity> Opps){
        OpptyToDisplay = opps; 
    }
    
    public List<Opportunity> getOpptyToDisplay(){
         //Zendesk: #55332 
        parentGivingName = 'Parent Opportunity'; 
        batchLogName = 'Batch Log';
        primaryCampaignSource = 'Primary Campaign Source';
        portfolio1 = 'Portfolio 1';
        //End : Zendesk: #55332 
        set<String> adjustmntList = new Set<String>{'N','D', null};
        List<Opportunity> opps = new List<Opportunity>();
        if(fieldSetName != null && OpptyToDisplay == null) {
            opptyRTMap = new Map<String,Schema.RecordTypeInfo>();
            opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
            recordTypeId = new Set <Id> (); 
            if(fieldSetName == 'AccountLayout_DonationSection'){
                recordTypeId.add(opptyRTMap.get('Donation').getRecordTypeId()); 
                recordTypeId.add(opptyRTMap.get('Transaction').getRecordTypeId());
                recordTypeId.add(opptyRTMap.get('Soft Credit').getRecordTypeId());
                recordTypeId.add(opptyRTMap.get('Pledge Payment').getRecordTypeId());
                sectionName = 'Donations & Pledge Payments';
            }
            else if(fieldSetName ==  'AccountLayout_PledgeSection'){
                recordTypeId.add(opptyRTMap.get('Pledge').getRecordTypeId()); 
                //recordTypeId.add(opptyRTMap.get('Pledge Payment').getRecordTypeId());
                sectionName = 'Pledges';
            }
            else if(fieldSetName ==  'AccountLayout_ProposalSection'){
                recordTypeId.add(opptyRTMap.get('Proposal').getRecordTypeId()); 
                recordTypeId.add(opptyRTMap.get('Grant').getRecordTypeId()); 
                sectionName = 'Proposals & Grants';
            }
            labelFieldSet = this.getFields(fieldSetName);
            //Integer i=0;
            String donationRecTypeId = opptyRTMap.get('Donation').getRecordTypeId();
            String SoftCrRecTypeId = opptyRTMap.get('Soft Credit').getRecordTypeId();
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : labelFieldSet) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id, Campaign.Name, Portfolio__r.Name';
            query += ' FROM Opportunity WHERE RecordTypeId =:recordTypeId AND accountId =:accountId' ;
            query += ' AND Adjustment_Code__c =:adjustmntList';
            //change for issue I-280025
            /*if(fieldSetName == 'AccountLayout_DonationSection' || fieldSetName == 'AccountLayout_PledgeSection'){
                query += ' AND Adjustment_Code__c != null';
            }*/
            if(fieldSetName == 'AccountLayout_DonationSection') {
                query += ' AND (RecordTypeId = :SoftCrRecTypeId OR Adjustment_Code__c != null)';
            }
            
            query += ' ORDER BY closeDate desc,rC_Giving__Last_Giving_Amount_Adjustment_Date__c desc LIMIT 5';
            system.debug(query);
            opps = Database.Query(query);
            
            return opps;
        }else{
           return null;
        }
    }
    /*
    Method url
    @description : redirects to the page
    */
    public pageReference url(){
        String url = '/apex/GivingRecordListWithAdjustments?fieldSet='+fieldSetName+'&accId='+accountId;
        pageReference page = new pageReference(url);
        return page;
    }   
    
    /*
    Method getFields
    @description : Get Opportunity FieldSet Fields
    */
    public List<Schema.FieldSetMember> getFields(String fsName) {
        return SObjectType.Opportunity.FieldSets.getMap().get(fsName).getFields();
    }
}