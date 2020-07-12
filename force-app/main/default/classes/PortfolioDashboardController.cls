/*
*
*Name  :  PortfolioDashboardController
*Author:  Appirio India (Meghna Vijay)
*Date  :  May 15, 2017
*Purpose :  Controller Class for the PortfolioDashboard vf page
            This class is used for showing Portfolio records in Dashboard format based on filter criteria (Affiliate, Team Role, Specific User, Fiscal Year)
            The class summarizes data multiple groupings of data so it can presented in a report format"
*
*/
public with sharing class PortfolioDashboardController {
    
    /*for filtering report based on Affiliate*/
    public String selectedAffiliate {get; set;} 
    /*If map is empty then show an error message*/
    public Boolean donorsflag{get;set;}  
    public Boolean teamRolesFlag{get;set;}  
    public Boolean solicitorFlag{get;set;}  
    
    /*for filtering report based on Team Role*/
    public String selectedTeamRole{get;set;} 
    
    /*for filtering report based on Fiscal Year*/
    public String selectedFiscalYear{get;set;}
    
    /*For storing confidential data*/
    public Confidential_Data__c confidentialData {get;set;}
    /*for portfolio lookup*/
    public Opportunity fakeOpportunity{get;set;}
    /*For storing Team Member's Data */
    public Map<String, List<performanceByTeamMemberWrapper>> mapTeamRoleWithWrapperList{get;set;} //Performance By Team Member
    /*For storing Solicitor's Data */
    public Map<String, List<performanceByTeamMemberWrapper>> mapSolicitorWithWrapperList{get;set;} //Performance By Solicitor
    /*For storing Donors's Data */
    public Map<String, List<performanceByTeamMemberWrapper>> mapAccountNameWithStageAndAmount{get;set;}  //Donors In Portfolio
    public Map<String, Double> mapTypeOfAmountWithTotalAmount{get;set;}  //Overall Portfolio Performance
    public List<gaugeData> gaugeDataList{get;set;}  //gague details
    public Double gageMax {get; set;}
    
    public String stageIdentify {get; set;}  //Proposal By Pipeline Stage details
    public String stageQualify {get; set;}
    public String stageInProgress {get; set;}
    public String stageNoProgress {get; set;}
    public String stageCultivation {get; set;}
    public String stageSolicitation {get; set;}
    public String stageNegotiation {get; set;}
    public String stageVerbal {get; set;}
    public String stageWrittenPledge {get; set;}
    public String stageMadeGift {get; set;}
    public String stageStewardship {get; set;}
    public String stageRejected {get; set;}
    public String stageDeferred {get; set;}
    public String stageCancelled {get; set;}
    public String stageClosed {get; set;}
    public String stageComplete {get; set;}
    
    public Double totalPortClosedAmount {get;set;}
    public Double totalPortRequestedAmount {get;set;}
    
    private Id proposalRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    
   
    /*This is constructor that loads defaults value when a page will be load.*/
    public PortfolioDashboardController() {
        confidentialData = new Confidential_Data__c();
        fakeOpportunity = new Opportunity(RecordTypeID = proposalRecordTypeId);
        Integer currentFY = getCY();
        totalPortClosedAmount = 0.0;
        totalPortRequestedAmount = 0.0;
        
        if(String.isNotBlank(apexPages.currentPage().getParameters().get('portfolioID'))){
            fakeOpportunity.Portfolio__c = apexPages.currentPage().getParameters().get('portfolioID');
            if(apexPages.currentPage().getParameters().get('fy') == 'all') {
                selectedFiscalYear = 'na';
            }
            //selectedFiscalYear = String.valueOf(currentFY)+'\',\''+String.valueOf(currentFY-1) ;
            showReport(); //if we have a portfolioID we want to display the report right away
        }
    }

    /*
    Method Name:    getPrimaryAffiliate()
    Parameter:      None
    Return Type:    List<SelectOption>
    Description:    this method will return the list of global picklist(Primary_Affiliate__c).
    */
    public List<SelectOption> getPrimaryAffiliate() {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType ObjectSchema = schemaMap.get('user'); 
        List<SelectOption> options = new List<SelectOption>();
        // gets Primary_Affiliate__c from user object which is also a global picklist
        Schema.DescribeFieldResult fieldResult = ObjectSchema.getDescribe().fields.getMap().get('Primary_Affiliate__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel().substring(0,2), f.getValue().substring(0,2)));
        }       
        return options; 
    }
    
    /*
    Method Name:    getTeamRoles()
    Parameter:      None
    Return Type:    List<SelectOption>
    Description:    this method will return the list of global picklist(TeamMemberRole).
    */
    public List<SelectOption> getTeamRoles(){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType ObjectSchema = schemaMap.get('opportunityteammember'); 
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = ObjectSchema.getDescribe().fields.getMap().get('TeamMemberRole').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption(' ', '-None-'));     
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;    
    }
    
     /*
    Method Name:    getYearOptions()
    Parameter:      None
    Return Type:    List<SelectOption>
    Description:    This method will return Previous, Current year.
    */
    public List<SelectOption> getYearOptions() {
        List<SelectOption> fiscalYearOptions = new List<SelectOption>();

        Integer currentFY = getCY();
        fiscalYearOptions.add(new SelectOption('na', '-None-'));
        fiscalYearOptions.add(new SelectOption(String.valueOf(currentFY),'Current FY'));
        fiscalYearOptions.add(new SelectOption(String.valueOf(currentFY-1),'Previous FY'));
        fiscalYearOptions.add(new SelectOption(String.valueOf(currentFY)+'\',\''+String.valueOf(currentFY-1),'Current Year + Previous FY'));
        return fiscalYearOptions;
    }
    
    /*
    Method Name:    showReport()
    Parameter:      None
    Return Type:    List<SelectOption>
    Description:    This method will show report/data when user clicks on show report button.
    */
    public void showReport() {
        Double totalRequestedAmount = 0.0;
        Double totalClosedAmount = 0.0;
        Double totalPledgedAmount = 0.0;
        totalPortClosedAmount = 0.0;
        totalPortRequestedAmount = 0.0;
        mapTypeOfAmountWithTotalAmount = new Map<String, Double>();

        stageIdentify = 0 + ', $0';
        stageQualify = 0 + ', $0';
        stageInProgress = 0 + ', $0';
        stageNoProgress = 0 + ', $0';
        stageCultivation = 0 + ', $0';
        stageSolicitation = 0 + ', $0';
        stageNegotiation = 0 + ', $0';
        stageVerbal = 0 + ', $0';
        stageWrittenPledge = 0 + ', $0';
        stageMadeGift = 0 + ', $0';
        stageStewardship = 0 + ', $0';
        stageRejected = 0 + ', $0';
        stageDeferred = 0 + ', $0';
        stageCancelled = 0 + ', $0';
        stageClosed = 0 + ', $0';
        stageComplete = 0 + ', $0';

        String role = '';
        donorsflag = false;
        solicitorFlag = false;
        teamRolesFlag = false;
        String affiliateString = selectedAffiliate;
        String userId = confidentialData.Completed_By__c;  //filter selected user
        Id portfolioId = fakeOpportunity.Portfolio__c;
        Set<String> opportunityIdSet = new Set<String>();
        Map<String, Set<String>> mapTeamRoleWithUserIdSet = new Map<String, Set<String>>();
        Map<String, performanceByTeamMemberWrapper> mapUserIdWithPerformanceTeamWrapper = new Map<String, performanceByTeamMemberWrapper>();
        Map<String, performanceByTeamMemberWrapper> mapSolicitorUserIdWithPerformanceTeamWrapper = new Map<String, performanceByTeamMemberWrapper>();
        mapTeamRoleWithWrapperList = new Map<String, List<performanceByTeamMemberWrapper>>();
        mapSolicitorWithWrapperList = new Map<String, List<performanceByTeamMemberWrapper>>();
        mapAccountNameWithStageAndAmount = new Map<String, List<performanceByTeamMemberWrapper>>();
        gaugeDataList = new List<gaugeData>();
        List<Opportunity> opptys = new List<Opportunity>();

        //builds query for Team Member information
        String opportunityTeamMemberQuery = 'SELECT TeamMemberRole, isSolicitor__c, OpportunityId, '+ 
                'Opportunity.rC_Giving__Affiliation__c, Opportunity.Portfolio__r.Affiliate__c, UserId, '+
                'Opportunity.Fiscal_Year__c, Opportunity.rC_Giving__Requested_Amount__c, '+
                'Opportunity.rC_Giving__Closed_Amount__c, Opportunity.Closed_Amount_Total__c, '+
                'Opportunity.Account.Name, Opportunity.StageName, Opportunity.Outstanding_Pledge_Amount__c, User.Name '+
                'FROM OpportunityTeamMember WHERE ';
        String filter = '';
        String filterTeamMember = '';
        if(String.isNotBlank(selectedTeamRole)) {
            filterTeamMember += ' TeamMemberRole =: selectedTeamRole AND';
        }           
        if(String.isNotBlank(userId)) {
            filterTeamMember += ' UserId =: userId AND';
        } 
        if(String.isNotBlank(portfolioId)){
            filterTeamMember += ' (Opportunity.Portfolio__c = :portfolioId OR Opportunity.Portfolio_2__c = :portfolioId '+
                                   'OR Opportunity.Portfolio_3__c = :portfolioId ) AND';
            filter += ' (Portfolio__c = \''+portfolioId+'\' OR Portfolio_2__c = \''+portfolioId+
                         '\' OR Portfolio_3__c = \''+portfolioId+'\'  ) AND';
        } else if(String.isNotBlank(selectedAffiliate)) { //we only want to do portfolio or affiliate not both
            filterTeamMember += ' (Opportunity.Portfolio__r.Affiliate__c =: affiliateString '+
                                 ' OR Opportunity.Portfolio_2__r.Affiliate__c =: affiliateString '+ 
                                 ' OR Opportunity.Portfolio_3__r.Affiliate__c =: affiliateString ) AND';
            filter += ' (Portfolio__r.Affiliate__c = \''+affiliateString+
                       '\' OR Portfolio_2__r.Affiliate__c = \''+affiliateString+
                       '\' OR Portfolio_3__r.Affiliate__c = \''+affiliateString+ '\') AND';
        }  
        if(String.isNotBlank(selectedFiscalYear) && selectedFiscalYear!='na' ) {
            filterTeamMember += ' Opportunity.Fiscal_Year__c IN ( \''+selectedFiscalYear+'\' ) AND';
            filter += ' Fiscal_Year__c IN ( \''+selectedFiscalYear+'\' ) AND'; 
        }
        opportunityTeamMemberQuery += filterTeamMember + 
                                    ' Opportunity.RecordTypeId =: proposalRecordTypeId ORDER BY TeamMemberRole';
        

        //processes Team Member information
        List<OpportunityTeamMember> opptyTeamMemberList = Database.query(opportunityTeamMemberQuery);
        String key;
        for(OpportunityTeamMember opptyTeam : opptyTeamMemberList) {
            //opportunities returned from team member search, basis for other querries
            opportunityIdSet.add(opptyTeam.OpportunityId); 
            key = opptyTeam.TeamMemberRole + '_' + opptyTeam.isSolicitor__c;
            if(!mapTeamRoleWithUserIdSet.containsKey(key) && 
                (opptyTeam.TeamMemberRole != null || opptyTeam.TeamMemberRole != ' ')) {
                mapTeamRoleWithUserIdSet.put(key, new Set<String>{opptyTeam.UserId});
            } else {
                mapTeamRoleWithUserIdSet.get(key).add(opptyTeam.UserId);
            }
             
            if(opptyTeam.isSolicitor__c) {
                createMapTeamWithWrapper(mapSolicitorUserIdWithPerformanceTeamWrapper, opptyTeam);
            } else {
                createMapTeamWithWrapper(mapUserIdWithPerformanceTeamWrapper, opptyTeam);
            }
        } //end Team Member information creation


        String oppQry = 'SELECT Id, rC_Giving__Affiliation__c, Portfolio__r.Name, Account.Name, StageName,'+
                  'rC_Giving__Requested_Amount__c, rC_Giving__Closed_Amount__c, Closed_Amount_Total__c, '+
                  'Outstanding_Pledge_Amount__c '+
                  'FROM Opportunity WHERE ';
        if(String.isNotBlank(selectedTeamRole) || String.isNotBlank(userId)){
                  oppQry += 'ID IN :opportunityIdSet';
        } else {
            oppQry += filter + ' RecordTypeId = \''+proposalRecordTypeId+'\'';
        }

        opptys = Database.query(oppQry);

        //gets donors in portfolio
        for(Opportunity oppty : opptys) {
            totalPortClosedAmount += makeOperandable(oppty.Closed_Amount_Total__c); 
            totalPortRequestedAmount += makeOperandable(oppty.rC_Giving__Requested_Amount__c);
            
            if(!mapAccountNameWithStageAndAmount.containsKey(oppty.Account.Name)) {
                performanceByTeamMemberWrapper wrapper =  new performanceByTeamMemberWrapper();
                wrapper.stageName = oppty.StageName;
                wrapper.requestedAmount = oppty.rC_Giving__Requested_Amount__c;
                wrapper.closedAmount = oppty.Closed_Amount_Total__c;
                wrapper.AccountName = oppty.Account.Name;
                mapAccountNameWithStageAndAmount.put(oppty.id, new List<performanceByTeamMemberWrapper>{wrapper}); 
            } else {
                for(performanceByTeamMemberWrapper wrapperInst : mapAccountNameWithStageAndAmount.get(oppty.Account.Name)) {
                    if(wrapperInst.stageName == oppty.StageName) {
                       wrapperInst.requestedAmount += oppty.rC_Giving__Requested_Amount__c;
                       wrapperInst.closedAmount += oppty.Closed_Amount_Total__c;
                    }
                }
            }
        } 

        //building Data for Pipeline report
        Integer totalOpportunities = opportunityIdSet.size();
        String oppAggQry = 'SELECT COUNT(Id) total, SUM(rC_Giving__Requested_Amount__c) RequestAmt, StageName '+
                           'FROM Opportunity WHERE ';
        if(String.isNotBlank(selectedTeamRole) || String.isNotBlank(userId)){
                  oppAggQry += ' ID IN :opportunityIdSet';
        } else {
            oppAggQry += filter + ' RecordTypeId = \''+proposalRecordTypeId+'\'';
        }
        oppAggQry += ' GROUP BY StageName';
        
        List<AggregateResult> opptyAggs = Database.query(oppAggQry);
        for(AggregateResult aggregateOpptys : opptyAggs) {

            if(opptyAggs.size() > 0 ){
                if(aggregateOpptys.get('StageName') == '01. Identify') {
                    stageIdentify = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt') ;
                }
                if(aggregateOpptys.get('StageName') == '01.1 Qualify') {
                    stageQualify =  aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt') ;
                }
                if(aggregateOpptys.get('StageName') == '02. Strategy/In Progress') {
                    stageInProgress =  aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '02.1 No Progress') {
                    stageNoProgress =  aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '02.5 Cultivation') {
                    stageCultivation = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '03. Solicitation') {
                    stageSolicitation = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '04. Negotiation') {
                    stageNegotiation = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '05. Verbal Pledge') {
                    stageVerbal = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '05.1 Written Pledge') {
                    stageWrittenPledge = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '06. Made Gift') {
                    stageMadeGift = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '06.1 Stewardship') {
                    stageStewardship  = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '07. Rejected') {
                    stageRejected  = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '08. Deferred') {
                    stageDeferred  = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '09. Cancelled') {
                    stageCancelled = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '09.1 Closed') {
                    stageClosed = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                }
                if(aggregateOpptys.get('StageName') == '10. Complete') {
                    stageComplete = aggregateOpptys.get('total') +', $'+aggregateOpptys.get('RequestAmt');
                } 
            }
        }


        //populates the values for Performance By Team Member and Performance By Solicitor
        for(String teamMember : mapTeamRoleWithUserIdSet.keyset()) {
            List<performanceByTeamMemberWrapper> performanceTeamWrapperList = new List<performanceByTeamMemberWrapper>();
            List<performanceByTeamMemberWrapper> solicitorPerformanceTeamWrapperList = new List<performanceByTeamMemberWrapper>();
            for(String userIdSet : mapTeamRoleWithUserIdSet.get(teamMember)) {
                role = teamMember.split('_')[0];
                if(teamMember.split('_')[1] == 'true') {
                    solicitorPerformanceTeamWrapperList.add(mapSolicitorUserIdWithPerformanceTeamWrapper.get(userIdSet));
                    mapSolicitorWithWrapperList.put(role, solicitorPerformanceTeamWrapperList);
                }
                else {
                    performanceTeamWrapperList.add(mapUserIdWithPerformanceTeamWrapper.get(userIdSet));
                    mapTeamRoleWithWrapperList.put(role, performanceTeamWrapperList); 
                }
            }
        }    
         
        //builds data for gague and Overall Portfolio Performance
        for(Opportunity opty : opptys) {
            if(opty.rC_Giving__Requested_Amount__c != NULL && opty.rC_Giving__Requested_Amount__c>=0 ){
                totalRequestedAmount += opty.rC_Giving__Requested_Amount__c;
            }
            //if(opty.Outstanding_Pledge_Amount__c!= NULL && opty.Outstanding_Pledge_Amount__c>=0 ){     
            if(opty.Outstanding_Pledge_Amount__c!= NULL ){ 
                totalPledgedAmount += opty.Outstanding_Pledge_Amount__c;
            }
            if(opty.Closed_Amount_Total__c!= NULL && opty.Closed_Amount_Total__c>=0 ){
                totalClosedAmount += opty.Closed_Amount_Total__c;

            }
        }

        //Overall Portfolio Performance
        mapTypeOfAmountWithTotalAmount.put('Total Open Pledged Amount', totalPledgedAmount);
        mapTypeOfAmountWithTotalAmount.put('Total Closed Amount', totalClosedAmount);
        mapTypeOfAmountWithTotalAmount.put('Total Goal Amount', totalRequestedAmount);
        
        //gague information
        gaugeDataList.add(new gaugeData('Total CLosed', Integer.valueOf(totalClosedAmount)));
        gageMax = totalRequestedAmount;
        if(mapAccountNameWithStageAndAmount.isEmpty()){
            donorsflag = true;
        }
        if(mapTeamRoleWithWrapperList.isEmpty()){
            teamRolesFlag = true;
        }
        if(mapSolicitorWithWrapperList.isEmpty()){
            solicitorFlag = true;
        }
    } 
    
    /*
    Method Name:    createMapTeamWithWrapper()
    Parameter:      Map<String, performanceByTeamMemberWrapper> userIdWithWrapperMap, OpportunityTeamMember opptyTeam
    Return Type:    Void
    Description:    This method will stores the performance wrapper records into a map .
    */
    public void createMapTeamWithWrapper(Map<String, performanceByTeamMemberWrapper> userIdWithWrapperMap, OpportunityTeamMember opptyTeam) {
        if(!userIdWithWrapperMap.containsKey(opptyTeam.UserId)) {
            performanceByTeamMemberWrapper wrapperInstance = new performanceByTeamMemberWrapper();
            wrapperInstance.requestedAmount = Double.valueOf(checkNum(opptyTeam.Opportunity.rC_Giving__Requested_Amount__c));
            wrapperInstance.closedAmount = Double.valueOf(checkNum(opptyTeam.Opportunity.Closed_Amount_Total__c));
            wrapperInstance.pledgedAmount = Double.valueOf(checkNum(opptyTeam.Opportunity.Outstanding_Pledge_Amount__c));
            wrapperInstance.userName = opptyTeam.User.Name;
            userIdWithWrapperMap.put(opptyTeam.UserId, wrapperInstance);
        } else {
            userIdWithWrapperMap.get(opptyTeam.UserId).requestedAmount += Double.valueOf(checkNum(opptyTeam.Opportunity.rC_Giving__Requested_Amount__c));
            userIdWithWrapperMap.get(opptyTeam.UserId).closedAmount += Double.valueOf(checkNum(opptyTeam.Opportunity.Closed_Amount_Total__c));
            userIdWithWrapperMap.get(opptyTeam.UserId).pledgedAmount += Double.valueOf(checkNum(opptyTeam.Opportunity.Outstanding_Pledge_Amount__c)); 
        }
    }
    
    public Decimal makeOperandable(Decimal input) { return (input == null) ? 0 : input; }

    /* This is an inner class that is used for storing Team member values.*/   
    public class performanceByTeamMemberWrapper {
        public Double requestedAmount{get;set;}
        public Double pledgedAmount{get;set;}
        public Double closedAmount{get;set;}
        public String userName {get;set;}
        public String stageName {get;set;}
        public String AccountName {get;set;}
        
        /*This is a default constructor.*/
        public performanceByTeamMemberWrapper() {
            requestedAmount = 0.0;
            pledgedAmount = 0.0;
            closedAmount = 0.0;
            userName = '';
            stageName = '';
            AccountName = '';  
        }
    }

    /*This is an inner class that is used for showing gauge's data.*/
    public class gaugeData {
        public String name {get; set;}
        public Integer size { get; set; }
        public gaugeData( String name, Integer data) {
            this.name=name;
            this.size = data;
       }
    } 

    private Decimal checkNum(Decimal d){
        return (d == null) ? 0 : d;
    }

    private Integer getCY() {
        Organization orgInfo = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                                FROM Organization
                                WHERE id=:Userinfo.getOrganizationId()];

        Date today = system.today();
        Integer currentFY;
        if (today.month() >= orgInfo.FiscalYearStartMonth) {
            currentFY = today.year() + 1;  //this is correct
        } else{
            currentFY = today.year();
        }
        return currentFY;
    }
       
}