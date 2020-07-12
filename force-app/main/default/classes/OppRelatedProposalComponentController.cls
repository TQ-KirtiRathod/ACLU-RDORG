/*
*
*Name  :  OppRelatedProposalComponentController
*Author:  Appirio India (Aashita Sharma)
*Date  :  Jan 23, 2017
*Purpose : Controller class for VF Component OppRelatedProspectsComponent. 
*          It is used as a related list of Prospects on the Opportunity detail page. Inline editing feature is added for the related list.
*
*/
public with sharing class OppRelatedProposalComponentController {

    public String oppId {get; set;}
    public List<Schema.FieldSetMember> proposalFieldSet {get; set;}
    
    public OppRelatedProposalComponentController() {
        proposalFieldSet = SObjectType.Proposal_Detail__c.FieldSets.getMap().get('ProposalDetails').getFields();
    } 
       
    //List to be used in the table
    public List<Proposal_Detail__c> proposalList {get    
    {
        getProposals();
        return proposalList;        
    } 
    set;
    }
    
    //---------------------------------------------------------------------------
    //Method to get the proposal details
    //---------------------------------------------------------------------------
    private void getProposals() {
        String queryString;
        if(oppId != null) {
            queryString = 'select id';
            for(Schema.FieldSetMember fld : proposalFieldSet) {
                queryString += ', ' + fld.getFieldPath();
            }
            queryString += ' from Proposal_Detail__c WHERE Opportunity__c =:oppId';
            proposalList = Database.query(queryString);               
        }
    }
}