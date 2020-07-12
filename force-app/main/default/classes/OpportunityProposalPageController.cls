/*
*
*Name  :  OpportunityProposalPageController
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  Feb 02, 2018
*Purpose : Controller Class for OpportunityProposalPage.
*          Page is displayed in applet on Proposal page to expose Proposal Details
*
*/
public class OpportunityProposalPageController {
    public Opportunity OppRecord{get;set;}
    public Proposal_Detail__c propDetail{get;set;}
    public Boolean isInsert{get;set;}
    public Boolean hasProposalDetail = false;
    public Id proposalRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    public String prefixOpportunityObj = Opportunity.SObjectType.getDescribe().getKeyPrefix();
    public Id accontId;
    public OpportunityProposalPageController( ApexPages.StandardController stdController ){
        this.OppRecord = (Opportunity)stdController.getRecord();
        accontId = ApexPages.currentPage().getParameters().get('accid');
        propDetail = new Proposal_Detail__c();
        if( ApexPages.currentPage().getParameters().get('id') != null ){ 
            isInsert = false;
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : this.getFieldProposalDetail()) {
                query += f.getFieldPath() + ', ';
            }
            query += 'Id, Opportunity__c FROM Proposal_Detail__c WHERE Opportunity__c =\''+OppRecord.id+'\' LIMIT 1';

            for(Proposal_Detail__c pd:Database.query(query)){
                propDetail = pd;
                this.hasProposalDetail = TRUE;
            }
        } else {
            isInsert = True;
            this.hasProposalDetail = false;
        }
    }
    
    public PageReference saveOpportunityAndPortFolioRecord(){
        try{
            if( OppRecord.recordTypeId == NULL ){
                OppRecord.recordTypeId = proposalRecordTypeId;
            }
            upsert OppRecord;
            
            if( (proposaldetailFieldUpdate() && !hasProposalDetail) || hasProposalDetail ){
                if( propDetail.Opportunity__c == NULL ){
                    propDetail.Opportunity__c = OppRecord.Id;
                }
                upsert propDetail;
            }
            
        } 
        Catch(Exception ex){
            ApexPages.addMessages(ex);
            return null;
        }
        return returnToViewPage();
    }
    
    public PageReference returnToViewPage(){
        if( OppRecord.Id != NULL ){
            return new PageReference('/'+OppRecord.Id);
        } else {
            Schema.DescribeSObjectResult result = Opportunity.SObjectType.getDescribe(); 
              PageReference pageRef = new PageReference('/' + result.getKeyPrefix()); 
              pageRef.setRedirect(true); 
              return pageRef; 
        }
        
    }
    
    public List<Schema.FieldSetMember> getFieldProposalDetail() {
        return SObjectType.Proposal_Detail__c.FieldSets.Proposal_Edit_Proposal_Detail.getFields();
    }
    
    public Boolean proposaldetailFieldUpdate(){
        for(Schema.FieldSetMember f : this.getFieldProposalDetail()) {
            if( propDetail.get(f.getFieldPath()) != NULL ){
                return TRUE;
            }
        }
        return false;
    }
    
    public PageReference redirectToOtherPage(){
        if( OppRecord.recordTypeId != proposalRecordTypeId ){
            String prefix = Opportunity.SObjectType.getDescribe().getKeyPrefix();
            String returnURL;
            if( accontId != NULL ){
                returnURL = '/apex/rC_Giving__Opportunity_RedirectRecordType?retURL=%2F'+prefixOpportunityObj+'%2Fo&RecordType='+OppRecord.recordTypeId+'&ent=Opportunity&save_new=1&sfdc.override=1&accId='+accontId;
            } else {
                returnURL = '/apex/rC_Giving__Opportunity_RedirectRecordType?retURL=%2F'+prefixOpportunityObj+'%2Fo&RecordType='+OppRecord.recordTypeId+'&ent=Opportunity&save_new=1&sfdc.override=1';
            }
            return new PageReference(returnURL);
        } else return null;
    }
    
    
}