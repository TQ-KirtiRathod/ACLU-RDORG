/*
*
*Name  :  OpportunityAsyncProcessor
*Author:  Appirio  (Tom Burre)
*Date  :  May 28, 2018
*Purpose : Class to process Async Requests created for Account. Contains method to rollup to Proposal Detail record
*	Ticket 		Modified Date		Modified by				Purpose
*   #74075        02/26/2020		 SFDO (Kirti Rathod)    set the expiration date to null 
*/
public without sharing class OpportunityAsyncProcessor {

  public list<ID> proposal_Ids;
  public static String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  public static String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  public static String OPPORTUNITY_RT_SOFT_CREDIT_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
  public static String OPPORTUNITY_RT_PROPOSAL_ID = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
  public AsyncRequest__c asyncRequest ;//Added by - Kirti Rathod - #74075
  // Added
  public list<Opportunity> OpportunityObjs = new list<Opportunity>();
  public list<Proposal_Detail__c> listProposalDetailsToUpdate = new List<Proposal_Detail__c>();
  //Ended
  public OpportunityAsyncProcessor( AsyncRequest__c request ) {
    proposal_Ids = request.Params__c.split(',');
    asyncRequest =  request;//Added by - Kirti Rathod - #74075
  }

  /*
  *Author:  Appirio India (Aashita Sharma)
  *Date  :  Jan 30, 2018
  *Purpose : Singe AsyncType method to roll up to proposal detail if opportunity is complete.
  */
    public void opp_rollToProposal() {
      
      
        Map<Id, ProposalDetailFieldsWrapper> proposalIdWithPDFieldsWrapperMap = new Map<Id, ProposalDetailFieldsWrapper>();
        ProposalDetailFieldsWrapper currentWrap;
        //Query all the opportunity related to Proposal(proposal_Ids)
        for( Opportunity opp : [SELECT Id, Description, Proposal__c, Program_Type__c,Deposit_Site__c,rC_Giving__Closed_Amount__c,
                                  rC_Giving__Parent__c, Amount, rC_Giving__Affiliation__c, StageName, 
                                  rC_Giving__Parent__r.rC_Giving__Parent__c, RecordTypeId, RecordType.Name 
                                FROM Opportunity
                                WHERE  
                                  StageName = 'Completed'
                                  AND Amount != NULL
                                  AND (Program_Type__c Like '1%' OR Program_Type__c Like '2%' OR Program_Type__c Like '3%'
                                       OR Program_Type__c Like '4%' OR Program_Type__c Like '5%')
                                  AND (
                                        (RecordTypeId =: OPPORTUNITY_RT_SOFT_CREDIT_Id AND Proposal__c in: proposal_Ids)
                                        OR (
                                          RecordTypeId IN (:OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                          AND rC_Giving__Parent__r.rC_Giving__Parent__c IN: proposal_Ids 
                                        )
                                      )]
        ){
            if( opp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id ){
                if( !proposalIdWithPDFieldsWrapperMap.containsKey( opp.Proposal__c )){
                    proposalIdWithPDFieldsWrapperMap.put( opp.Proposal__c, new ProposalDetailFieldsWrapper( 0,0,0,0 ) );
                }
                currentWrap = proposalIdWithPDFieldsWrapperMap.get(opp.Proposal__c);
                proposalIdWithPDFieldsWrapperMap.put( opp.Proposal__c,calculateProposalDetailFields(currentWrap, opp ));
            } else {
                if( !proposalIdWithPDFieldsWrapperMap.containsKey( opp.rC_Giving__Parent__r.rC_Giving__Parent__c )){
                    proposalIdWithPDFieldsWrapperMap.put( opp.rC_Giving__Parent__r.rC_Giving__Parent__c, new ProposalDetailFieldsWrapper( 0,0,0,0 ) );
                }
                currentWrap = proposalIdWithPDFieldsWrapperMap.get( opp.rC_Giving__Parent__r.rC_Giving__Parent__c );
                proposalIdWithPDFieldsWrapperMap.put( opp.rC_Giving__Parent__r.rC_Giving__Parent__c,calculateProposalDetailFields(currentWrap, opp ));
            }
        }
        
        //For case: If opp record is deleted and there is no other opp for Porposal, 
        //then that proposal will not be added in map(there will be no query result for that)
        for( Id propsalId : proposal_Ids ){
            if( !proposalIdWithPDFieldsWrapperMap.containsKey(propsalId) ){
                proposalIdWithPDFieldsWrapperMap.put( propsalId, new ProposalDetailFieldsWrapper( 0,0,0,0 ) );
            }
        }
        
        for(Proposal_Detail__c pd : [SELECT ID, National_Banked_c3_Closed_Amount__c, National_Banked_c4_Closed_Amount__c, Name,
                                        Affiliate_Banked_c4_Closed_Amount__c, Affiliate_Banked_c3_Closed_Amount__c, Opportunity__c
                                    FROM Proposal_Detail__c
                                    WHERE Opportunity__c IN: proposalIdWithPDFieldsWrapperMap.keySet()]
        ) {
            if( pd.National_Banked_c3_Closed_Amount__c != NULL || proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).nationalC3ClosedAmount != 0)
                pd.National_Banked_c3_Closed_Amount__c = proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).nationalC3ClosedAmount;
            if( pd.National_Banked_c4_Closed_Amount__c != NULL || proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).nationalC4ClosedAmount != 0)
                pd.National_Banked_c4_Closed_Amount__c = proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).nationalC4ClosedAmount;
            if( pd.Affiliate_Banked_c3_Closed_Amount__c != NULL || proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).affiliateC3ClosedAmount != 0)
                pd.Affiliate_Banked_c3_Closed_Amount__c = proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).affiliateC3ClosedAmount;
            if( pd.Affiliate_Banked_c4_Closed_Amount__c != NULL || proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).affiliateC4ClosedAmount != 0)
                pd.Affiliate_Banked_c4_Closed_Amount__c = proposalIdWithPDFieldsWrapperMap.get(pd.Opportunity__c).affiliateC4ClosedAmount;
            listProposalDetailsToUpdate.add(pd);                      
        }
        
        if(!listProposalDetailsToUpdate.isEmpty()) {
            update listProposalDetailsToUpdate;
        }   
    
  }
  
  
    public class ProposalDetailFieldsWrapper{
        Decimal nationalC3ClosedAmount;
        Decimal nationalC4ClosedAmount;
        Decimal affiliateC3ClosedAmount;
        Decimal affiliateC4ClosedAmount;
        
        public ProposalDetailFieldsWrapper(Decimal a, Decimal b, Decimal c, Decimal d){
            nationalC3ClosedAmount = a;
            nationalC4ClosedAmount = b;
            affiliateC3ClosedAmount = c;
            affiliateC4ClosedAmount = d;
        }
    }

    //Add the opp amount into wrapper fields
    public ProposalDetailFieldsWrapper calculateProposalDetailFields ( ProposalDetailFieldsWrapper pdWrap , Opportunity opp ) {
        Decimal amt = opp.Amount != NULL ? opp.Amount : 0 ;
        if( opp.Deposit_Site__c.startsWith('NA') ){
            if( opp.Program_Type__c.contains('1') || opp.Program_Type__c.contains('2') ){
                pdWrap.nationalC3ClosedAmount += amt;
            } else if( opp.Program_Type__c.contains('4')){
                pdWrap.nationalC4ClosedAmount += amt;
            }
        } else {
            if( opp.Program_Type__c.contains('5') ){
                pdWrap.affiliateC3ClosedAmount += amt;
            } else if( opp.Program_Type__c.contains('3')){
                pdWrap.affiliateC4ClosedAmount += amt;
            }
        }
        return pdWrap;
    }
    
    /*Created By :: Zendesk #67681 :: Used to set Affiliation Opportunity beased on Account*/
    public void setAffiliationOnGiving() {
        if(proposal_Ids != null && proposal_Ids.size() > 0) {
            Map<id,String> failedReasons = new Map<id,String>();
            List<Opportunity> updateOpList = new List<opportunity>();
            List<opportunity> updateSharingCodeOverride = new List<opportunity>();
             List<Account> updateAccounts = new List<Account>();
            List<Opportunity> opList = [SELECT  id
                                             , Name
                                             , Account_Affiliation__c
                                        	 , Account.FirstMembership__c
                                             , Sharing_Code__c
                                             , Sharing_Code_Description__c
                                             , Sharing_Entity__c
                                             , Sharing_Entity_Affiliation__c
                                             , Account.Affiliation__c
                                             , rC_Giving__Parent__c
                                             , Account.Lock_Affiliation__c
                                             , accountId
                                             , CampaignIdText__c
                                             , Amount
                                             , Campaign_Type__c
                                             , Program_Type__c
                                             , rC_Giving__Is_Sustainer__c
                                             , Deposit_Site__c
                                             , Revenue_Affiliation__c
                                             , RecordTypeId
                                             , CloseDate
                                             , Sharing_Entity_Override__c
                                        FROM Opportunity
                                       WHERE id IN : proposal_Ids];
            List<Opportunity> opOldList = new List<Opportunity>();
            Set<Id> accountIds = new Set<Id>();	
            Set<Id> oppIds = new Set<Id>();
            opOldList = opList.deepClone(true,false,false);
            for(Opportunity op :opList){
                System.debug(op.Account_Affiliation__c);
                if(op.Account_Affiliation__c != op.Account.Affiliation__c ) {
                       op.Account_Affiliation__c = op.Account.Affiliation__c;
                        if(op.Sharing_Code_Override__c == false) {
                            updateSharingCodeOverride.add(op);
                            op.Sharing_Code_Override__c = true;
                        }
                        //SFDO - #74075 - by Kirti Rathod - set the expiration date to null 
                        if(op.Account.FirstMembership__c) {
                            oppIds.add(op.id);
                            if(!accountIds.Contains(op.accountId)) {
                                Account accObj = new Account();
                                accObj.id = op.accountId;
                                accObj.FirstMembership__c = false;
                                updateAccounts.add(accObj);
                                accountIds.add(accObj.id);
                            }      
                        }
                    updateOpList.add(op);
                } 
            }
            //SFDO - #74075
            RevenueSharingShareCodes.setShareCode(updateOpList,oppIds);
            
            for(Opportunity op :updateSharingCodeOverride) {
                 op.Sharing_Code_Override__c = false;
            }
            //SFDO - Added by - Kirti Rathod START- #74075 -  update the account and oplist
            savePoint sp = Database.setSavepoint(); 
            if(updateOpList.size() > 0) {
                try {
                    Update updateAccounts;
                    Update updateOpList;
                }Catch(Exception ex) {
                    Database.rollback(sp);
                    //Update Asyncrequest with failed reason
                    asyncRequest.Error_Message__c = ex.getMessage()+ex.getStackTraceString();
                    asyncRequest.Error__c = true;
                    update asyncRequest;
                    return;
                }
               //SFDO - Added by - Kirti Rathod END- #74075 -  update the account and oplist 
            } 
            Map<id,Opportunity> opNewList = new Map<id,Opportunity>([SELECT  id
                                                                         , Name
                                                                         , Account_Affiliation__c
                                                                         , Sharing_Code__c
                                                                         , Sharing_Code_Description__c
                                                                         , Sharing_Entity__c
                                                                         , Sharing_Entity_Affiliation__c
                                                                         , Revenue_Affiliation__c
                                                                    FROM Opportunity
                                                                   WHERE id IN : proposal_Ids]);
            if(updateOpList.size() > 0) {
                sendEmail(opNewList,opOldList);
            }
        }
    }
    /*Created By :: Zendesk #67681 :: Used to send Email*/
    public void sendEmail(Map<id,Opportunity> newList,List<Opportunity> oldList) {
        Schema.DescribeSObjectResult d = Opportunity.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> oppFieldMap = d.fields.getMap();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(String.isBlank(Label.NotifyUserOnAffiliationChange)) {
            email.setTargetObjectId(UserInfo.getUserId());
        }else {
           List<String> lstEmail = Label.NotifyUserOnAffiliationChange.split(',');
           email.setToAddresses(lstEmail);
        }        
        String body ='Organization Name: '+ UserInfo.getOrganizationName() +'Organization ID: '+ UserInfo.getOrganizationID();
        String header = '';
        String csvBody ='';
        
        header += 'ID'+','+'Giving Name'+', Account Id';
        header += ', Old value :'+oppFieldMap.get('account_affiliation__c').getDescribe().getLabel();
        header += ', New value :'+oppFieldMap.get('account_affiliation__c').getDescribe().getLabel(); 
        header += ', Old value :'+oppFieldMap.get('sharing_entity__c').getDescribe().getLabel()+', New value :'+oppFieldMap.get('sharing_entity__c').getDescribe().getLabel();
        header += ', Old value :'+oppFieldMap.get('sharing_entity_affiliation__c').getDescribe().getLabel()+', New value :'+oppFieldMap.get('sharing_entity_affiliation__c').getDescribe().getLabel();
        header += ', Old value :'+oppFieldMap.get('revenue_affiliation__c').getDescribe().getLabel() +', New value :'+oppFieldMap.get('revenue_affiliation__c').getDescribe().getLabel();
        header += ', Old value :'+oppFieldMap.get('sharing_code_description__c').getDescribe().getLabel() +', New value :'+oppFieldMap.get('sharing_code_description__c').getDescribe().getLabel();
        
       
        if(oldList != null && oldList.size() > 0) {
            for(Opportunity op : oldList) { 
                csvBody +=  '\n'+op.id+','+op.Name+','+op.accountId+','+op.Account_Affiliation__c+','+newList.get(op.id).Account_Affiliation__c;
                if(op.Sharing_Entity__c != newList.get(op.id).Sharing_Entity__c) {
                    csvBody += ','+op.Sharing_Entity__c+','+newList.get(op.id).Sharing_Entity__c;   
                }else {
                    csvBody +=','+''+','+'';
                }if(op.Sharing_Entity_Affiliation__c != newList.get(op.id).Sharing_Entity_Affiliation__c) {
                    csvBody += ','+op.Sharing_Entity_Affiliation__c+','+newList.get(op.id).Sharing_Entity_Affiliation__c;   
                }else {
                    csvBody +=','+''+','+'';
                }if(op.Revenue_Affiliation__c != newList.get(op.id).Revenue_Affiliation__c) {
                    csvBody += ','+op.Revenue_Affiliation__c+','+newList.get(op.id).Revenue_Affiliation__c;   
                }else {
                    csvBody +=','+''+','+'';
                }if(op.Sharing_Code_Description__c != newList.get(op.id).Sharing_Code_Description__c) {
                        csvBody += ','+op.Sharing_Code_Description__c+','+newList.get(op.id).Sharing_Code_Description__c;   
                }else {
                    csvBody +=','+''+','+'';
                }
            }
        }
        String csvContent = header+csvBody;
        Blob pdf = Blob.valueOf(csvContent);
        Messaging.EmailFileAttachment paymentPDFAttachemnt = new Messaging.EmailFileAttachment();
        paymentPDFAttachemnt.setFileName('OpportunityAffiliationChange.csv');
        paymentPDFAttachemnt.setContentType('application/csv');
        paymentPDFAttachemnt.setBody(pdf);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {paymentPDFAttachemnt});
        email.plainTextBody = body; 
        email.saveAsActivity = false;
        email.setSenderDisplayName('ACLU Oppportunity Affliliation Change');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }

}