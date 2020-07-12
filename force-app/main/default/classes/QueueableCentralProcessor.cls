/*
*
*Name  :  QueueableCentralProcessor
*Author:  Appirio  (Tom Burre)
*Date  :  May 28, 2017
*Purpose : Contains methods to enqueue AsyncApexJobs
*
*/
public without sharing class QueueableCentralProcessor implements queueable, Database.AllowsCallouts {
  public void execute(QueueableContext context) {
    if(!QueueableControlSetting.appEnabled) return; // On/off switch

    list<AsyncRequest__c> requests; 
    Schema.SObjectType shareObjType;
     
    try {
      requests = [SELECT ID, AsyncType__c, Params__c, Object_API_Name__c,AutoRetry_Count__c,Error_Message__c
                  FROM AsyncRequest__c
                  WHERE Error__c = false
                  AND CreatedById = :UserInfo.getUserId()
                  LIMIT 1 FOR UPDATE];
    } catch(Exception ex) {
      return; 
    }

    if(requests.size()== 0){
      return;
    }

    AsyncRequest__c currentRequest = requests[0];

    try {
        
            
      // All calls to SObject implementation classes
      if(currentRequest.Object_API_Name__c == 'Opportunity') { 
        OpportunityAsyncProcessor oppProcessor = new OpportunityAsyncProcessor(currentRequest);
        if(currentRequest.AsyncType__c=='opp_rollToProposal') {
          oppProcessor.opp_rollToProposal();
        } else if(currentRequest.AsyncType__c.equalsIgnorecase('Opportunity_AffiliationSet')) {//Zendesk : #67681
            oppProcessor.setAffiliationOnGiving();
        }
        /*if(currentRequest.AsyncType__c=='opp_AddToDescription') {
          oppProcessor.opp_AddToDescription();

        // Add more here
        // But may just want one method per object if we're only using this for afterInsert/Update like
        // oppProcessor.processAllOppAsyncEvents(). Then send over a map of "key=Event, value=ListOfIds"
        } else if(currentRequest.AsyncType__c=='opp_All') {
          oppProcessor.opp_All();
        }*/

        //update oppProcessor.listProposalDetailsToUpdate;
      }

      // Add other object implementations
      // if(currentRequest.Object_API_Name__c == 'Account') {
      //   AccountAsyncProcessor oppProcessor = new AccountAsyncProcessor(currentRequest);
      // etc...
      

      if(currentRequest.Object_API_Name__c == 'Account') {
        
        if(currentRequest.AsyncType__c=='account_AffiliationChange') {
            AccountAsyncProcessor actProcessor = new AccountAsyncProcessor(currentRequest);
            actProcessor.account_AffiliationChange();
        }
        // Not necessary unless we implement some other account processing; affiliation change does
        // its own upsert of email objects.
        //update actProcessor.AccountObjs;        
        
        if(currentRequest.AsyncType__c=='Create_Sharing'){
            RecordAccessQueueableClass recordAccessUtil = new RecordAccessQueueableClass(currentRequest);
            recordAccessUtil.createChildSharing();
        }
          
        //Modified by :roundCorner Inc. 06-Dec-18 :: Ticket#61850
        //The intetion here to create a async request is to update account billing address if its blank and 
        //BU has the value in custom address fields
        if(currentRequest.AsyncType__c == 'account_CustomCommitAddress') {
            AccountAsyncProcessor actProcessor = new AccountAsyncProcessor(); 
            actProcessor.account_CustomCommitAddress(currentRequest);
        }
      }


      
      if(currentRequest.Object_API_Name__c == 'Email__c') {
        EmailAsyncProcessor emailProcessor = new EmailAsyncProcessor(currentRequest);
        if(currentRequest.AsyncType__c=='email_primarySet') {
          emailProcessor.email_primarySet();
        }

        /*update emailProcessor.EmailObjs;*/
      }
      
      //I-305949
      if(currentRequest.Object_API_Name__c == 'rC_Bios__Account_Address__c') {
        AccountAddressAsyncProcessor accAddrProcessor = new AccountAddressAsyncProcessor(currentRequest);
        if(currentRequest.AsyncType__c=='accAddr_updateCountryCode') {
          accAddrProcessor.accAddr_updateCountryCode();
        }

        update accAddrProcessor.accAddrObjs;
      }
      
      if(currentRequest.Object_API_Name__c == 'Account_Team__c') {
        AccountTeamAsyncProcessor accTeamProcessor = new AccountTeamAsyncProcessor(currentRequest);
        if(currentRequest.AsyncType__c=='grantUserAccess') {
          accTeamProcessor.createUserSharing();
        }
        
        if(currentRequest.AsyncType__c=='removeUserAccess') { 
          accTeamProcessor.deleteUserSharing();
        }
      }
      if(currentRequest.Object_API_Name__c == 'Batch_Log__c') {
        BatchLogAsyncProcess batchLogAsycnReq = new BatchLogAsyncProcess(currentRequest);
        if(currentRequest.AsyncType__c=='updateBatchLog_Status') {
          batchLogAsycnReq.updateBatchLogStatus();
        }
      }
      
      
      if(currentRequest.AsyncType__c=='share_WithAccountTeam') {
          if(currentRequest.Object_API_Name__c == 'Confidential_Data__c') {
              shareObjType = Confidential_Data__Share.getSobjectType();
          } else if(currentRequest.Object_API_Name__c == 'rC_Giving__Payment_Method__c') {
              shareObjType = rC_Giving__Payment_Method__Share.getSobjectType();
          } else if(currentRequest.Object_API_Name__c == 'rC_Bios__Preference__c') {
              shareObjType = rC_Bios__Preference__Share.getSobjectType();
          } else if(currentRequest.Object_API_Name__c == 'rC_Giving__Planned_Giving__c') {
              shareObjType = rC_Giving__Planned_Giving__Share.getSobjectType();
          } else if(currentRequest.Object_API_Name__c == 'Prospect_Research__c') {
              shareObjType = Prospect_Research__Share.getSobjectType();
          } else if(currentRequest.Object_API_Name__c == 'rC_Bios__Relationship__c') {
              shareObjType = rC_Bios__Relationship__Share.getSobjectType();
          } else if(currentRequest.Object_API_Name__c == 'rC_Bios__Salutation__c') {
              shareObjType = rC_Bios__Salutation__Share.getSobjectType();
          }
          AccountTeamAsyncProcessor accTeamProcessor = new AccountTeamAsyncProcessor(currentRequest, shareObjType);
          accTeamProcessor.shareWithAccountTeam(); 
      }
      
      delete currentRequest;
      // Optional
      database.emptyRecycleBin(new List<ID>{currentRequest.id});

    } catch(Exception ex) {
        currentRequest.Error__c = true;
        currentRequest.Error_Message__c = ex.getMessage();
        currentRequest.AutoRetry_Count__c = currentRequest.AutoRetry_Count__c != null ? currentRequest.AutoRetry_Count__c +1 : 1;
        update currentRequest;
        

    }

    // IMPORTANT: If one exists, this queues up next Queueable Apex job (AsyncRequest__c) from the current Running User
    list<AsyncRequest__c> moreRequests = [SELECT ID, AsyncType__c, Params__c, Object_API_Name__c
                                          FROM AsyncRequest__c
                                          WHERE Error__c = false
                                          AND ID <> :currentRequest.id
                                          AND CreatedById = :UserInfo.getUserId()
                                          LIMIT 1 ];
    if(moreRequests.size()==0){
      return;
    }
    
    // There are more jobs to process! so kick it off again!!
    try {
      enqueueAsyncRequest(context.getJobId());
    } catch(Exception ex) {
      tryToQueue();
    }

  }

  public static void enqueueAsyncRequest(ID currentJobId) {
    list<AsyncApexJob> jobs = [SELECT ID, Status, ExtendedStatus
                              FROM AsyncApexJob
                              WHERE JobType = 'Queueable'
                              AND (status='Queued' OR Status='Holding')
                              // This line is key as it ensures only one Queueable job at a time per User
                              AND CreatedById = :userinfo.getUserID()
                              AND ApexClass.Name='QueueableCentralProcessor'
                              AND ID != :currentJobId LIMIT 1 ];

    if(jobs.size()==1) return;  // Already have one queued that isn't this one.

    system.enqueueJob(new QueueableCentralProcessor());
  }


  @future
  private static void tryToQueue(){
    if(!QueueableControlSetting.appEnabled) return; // On/off switch 

    try {
      if(Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
        enqueueAsyncRequest(null);
      }
    } catch(Exception ex) {
        // Wait for someone else to make a request...
        // Or maybe use scheduled Apex?
    }
  }


}