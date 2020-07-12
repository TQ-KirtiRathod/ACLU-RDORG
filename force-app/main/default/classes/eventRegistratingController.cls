/*
*
*Name  :  eventRegistratingController
*Author:  Appirio India (Saikrishna Tavva)
*Date  :  April 24, 2017
*Purpose :  Controller Class for Event_Registration_Page
            Includes
            - Event Registration
            - Add, Delete, Save, Campaign Member population"
*
*/

public class eventRegistratingController {
    public List<CampaignMember> cmpMembers {get;set;}
    public Id CampaignId {get;set;}
    public String CampaignName {get;set;}
    public List<registrationWrapper> registrations;// {get;set;}
    public Integer count =0;
    public Boolean showChild {get;set;}
    public Integer selRow {get;set;}
    public Id oppId {get;set;}
    public Id campaignmemberId {get;set;}
    public CampaignMember newCm{get;set;}
    public Lead newLead{get;set;}
    public String SortingOrder {get;set;}
    public List<String> oppsRecordTypes {get;set;}
    public static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    public String sortColName {get;set;}
    public String firstName{get;set;}
    public String lastName{get;set;}
    //static 
    static{
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
    }
    //Controller
    //public eventRegistratingController(ApexPages.StandardController controller){}
    public eventRegistratingController(){
        CampaignId = (ApexPages.currentPage().getParameters().get('camId') != null) ? ApexPages.currentPage().getParameters().get('camId') : null;
        CampaignName = (ApexPages.currentPage().getParameters().get('cmpName') != null) ? ApexPages.currentPage().getParameters().get('cmpName') : null;
        cmpMembers = new List<CampaignMember> ();
        registrations = new List<registrationWrapper>();
        system.debug('campiId'+CampaignId);
        showChild = false;
        SortingOrder = 'ASC';
        newCm = new CampaignMember();
        newLead = new Lead();
        oppsRecordTypes = new List<String>{'Donation','Pledge'};
        //opptyRTMap = new Map<String,Schema.RecordTypeInfo>();
        sortColName = 'Name';
        
        
        //populateRegistrationWrapper ();
    }
    
    /*Intialisation*/
    // populates the registration wrapper
    public List<registrationWrapper> getRegistrations (){
        system.debug('Entered'+opp.getRecords());
        registrations = new List<registrationWrapper>();
        Map<Id,Opportunity> mapOpps = new Map<Id,Opportunity>();
        Map<Id,List<campaignMemberWrapper>> oppsWithCmpMembers = new Map<Id,List<campaignMemberWrapper>>();
        count =0;
        if(CampaignId != null){
            for(Opportunity opp: (List<Opportunity>)opp.getRecords()){
                 mapOpps.put(opp.Id,opp);
                /*registrations.add(new registrationWrapper(opp,count+1, m));
                count+=1;*/
            }
            
            oppsWithCmpMembers = populatecampaignMembers(mapOpps.KeySet());
            for(opportunity opp: mapOpps.Values()){
                registrations.add(new registrationWrapper(opp,count+1,((oppsWithCmpMembers.get(opp.Id)!= null) ? oppsWithCmpMembers.get(opp.Id): new List<campaignMemberWrapper>())));
                count+=1;
            }
            system.debug('pgNumOnLoad::'+opp.getPageNumber());
        }
        
        return registrations;
    }
    
    // populates the CampaignMembers
    public static Map<Id,List<campaignMemberWrapper>> populatecampaignMembers (Set<Id> oppIds){
        Map<Id,List<campaignMemberWrapper>> fetchCmpMembers = new Map<Id,List<campaignMemberWrapper>> ();
        for(CampaignMember cmpMember: [SELECT Id, Name, Opportunity__c, FirstName,  Vip__c, Speaker__c,  ContactId, LeadId, contact.firstName, contact.LastName, LastName,  Meal_Preference__c, rC_Event__Registered_Venue_Seats__c, rC_Event__Registered_Table_Name__c 
                                        FROM CampaignMember
                                        WHERE Opportunity__c =: oppIds Limit 50000]){
            if(fetchCmpMembers.containsKey(cmpMember.Opportunity__c)){
                Integer cmWrapperSize = fetchCmpMembers.get(cmpMember.Opportunity__c).size();
                
                fetchCmpMembers.get(cmpMember.Opportunity__c).add(new campaignMemberWrapper(cmWrapperSize+1, cmpMember));       
            }
            else{
                fetchCmpMembers.put(cmpMember.Opportunity__c, new List<campaignMemberWrapper>{new campaignMemberWrapper(1, cmpMember)});
            }
        }
        //system.debug('cmpMembers'+fetchCmpMembers);
        return fetchCmpMembers;
    }
    /*Intialisation*/
    
    /*Pagination*/
    // instantiate the StandardSetController from a query locator
    public ApexPages.StandardSetController opp {
        get {
            if(opp == null) {
                system.debug('EntereStandardController');
               //List<string> oppsRecordTypes = new List<String>{'Donation','Pledge'};
                opp = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, account.Name, Name, CloseDate,   rC_Giving__Giving_Amount__c,  rC_Giving__Closed_Amount__c, StageName,
                                    (SELECT Id,quantity, UnitPrice, Product2.Name , totalPrice, Product2Id,Product2.isAd__c,product2.isDiscount_Item__c  FROM OpportunityLineItems WHERE product2.recordType.name = 'Item' ) 
                                    FROM Opportunity 
                                    WHERE RecordType.Name =: oppsRecordTypes AND CampaignId =: ApexPages.currentPage().getParameters().get('camId') ORDER BY Name ASC LIMIT 100]));
                // sets the number of records in each page set
                opp.setPageSize(50);
            }
            return opp;
        }
        set;
    }
    
    
    
    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return opp.getHasNext();
        }
        set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return opp.getHasPrevious();
        }
        set;
    }
    
    // returns the previous page of records
    public void previous() {
         opp.previous();
    }
    
    // returns the next page of records
    public void next() {
         opp.next();
    }
    /*Pagination*/
    
    /*Add Campaign Member PopUp Section*/
    // Adds the campaignMembers to the selected Opp
    public void addCampaingMemeber(){
        oppId = ApexPages.currentPage().getParameters().get('selOppId'); 
        selRow = Integer.ValueOf(ApexPages.currentPage().getParameters().get('selOppRow'));
        newCm = new CampaignMember(Opportunity__c = oppId, rC_Event__Registered_Status__c='Registered',Is_Created_From_Event_Page__c = true);
        newLead = new Lead(LeadSource = 'Event Manual');
        showChild = true;/*
        if(oppId != null){
            cmpMembers.add(new CampaignMember(Opportunity__c = oppId,Status ='Sent', CampaignId= CampaignId));
        }*/
    }
    
    //Delete the campaign member
    public void deleteCmMember(){
        Id campaignMemberId = ApexPages.currentPage().getParameters().get('cmpMeId'); 
        try{
            Delete new Campaignmember(Id= campaignMemberId);
        }
        catch(exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
            showChild = true;
        }
        
    }
    
    //Save the Newly added Campaign Member
    public pageReference savenewCampaignMember(){
        List<CampaignMember> createCMs = new List<CampaignMember>();
        firstName = ApexPages.currentPage().getParameters().get('firName'); 
        lastName = ApexPages.currentPage().getParameters().get('lstName');
        system.debug('Debugs>>>' + firstName + ' ' + lastname);
        newLead.firstName = firstName;
        newlead.lastName = lastname;
        firstName = '';
        lastName = '';
        
        //newCm.Opportunity__c = oppId;
        newCm.campaignId = this.CampaignId;
        /*if(newCm.newCm.LeadId == null && newCm.contactId == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
        }*/
        system.debug('newCm : ' + newCm);
        system.debug('newCm.LeadId : ' + newCm.LeadId);
        system.debug('newLead : ' + newLead);
        if(newCm.LeadId != null && (String.IsBlank(newLead.firstName) && String.IsBlank(newLead.lastName)) ){
            createCMs.add(new CampaignMember(Opportunity__c = oppId, campaignId = this.CampaignId, leadId= newCm.leadId,rC_Event__Registered_Status__c = 'Registered',Is_Created_From_Event_Page__c = true));
            newCm.leadId = null;
        }
        if(newCm.contactId != null){
            createCMs.add(newCm);
        }
        try{
            system.debug('SaveNewCM:>>>>'+newCm);
            system.debug('seleOppRow:>>>>'+selRow);
            system.debug('seleOppId:>>>>'+oppId);
            system.debug('contactId:>>>>'+newCm.contactId);
            system.debug('createCMs:>>>>'+createCMs);
            system.debug('newLead.firstName:>>>>'+newLead.firstName);
            system.debug('newLead.lastName:>>>>'+newLead.lastName);
            if(!String.IsBlank(newLead.lastName)){
                newLead.company = !String.IsBlank(newLead.firstName) ? newLead.firstName+' '+ newLead.LastName : newLead.LastName;
                upsert newLead;
                createCMs.add(new CampaignMember(Opportunity__c = oppId, campaignId = this.CampaignId, leadId= newLead.Id, Meal_Preference__c = newCM.Meal_Preference__c, rC_Event__Registered_Status__c =' Registered', Is_Created_From_Event_Page__c = true));
            }
            insert createCMs;
            system.debug('SaveNewCM:AfterInser>>>>'+newCm);
            system.debug('SaveCMs:AfterInser>>>>'+createCMs);
            system.debug('SaveNewLead>>>>'+newLead.Id);
            /*for(registrationWrapper reg: registrations){
                if(reg.recCount == selRow){
                    system.debug('beforeSize::::>>>'+reg.cmpMembers.Size());
                    List<Campaignmember> lcms = new List<Campaignmember>();
                    lcms = reg.cmpMembers;
                    lcms.add(newCm);
                    reg.cmpMembers = lcms;
                    system.debug('AfterSize::::>>>'+reg.cmpMembers.Size());
                }
            }*/
            //getregistrations();
            showChild = false;
            //newCm = new CampaignMember();
            newLead = new Lead(LeadSource = 'Event Manual');
        }
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
            showChild = true;
            return null;
        }
        
        return null;
    }
    
    //Cancel the CampaignMembers
    public void closeSec(){
        showChild = false;
    }
    
    /*Add Campaign Member PopUp Section*/
    
    /*Sorting*/
    //Sort method
    public void sortName(){
        //sortColName = ApexPages.currentPage().getParameters().get('sortColName'); 
        Set<Id> selOppIdsToSort = new Set<Id>();
        String query;
        Integer pgNum = opp.getPageNumber();
        Integer totalSize = opp.getPageSize();
        //List<string> oppsRecordTypes = new List<String>{'Donation','Pledge'};
        List<Opportunity> sortedOpps = new List<Opportunity>();
        for(Opportunity objOpp: (List<Opportunity>)opp.getRecords()){
            selOppIdsToSort.add(objOpp.Id);
        }
        if(SortingOrder=='ASC' || SortingOrder == null){
            SortingOrder = 'DESC';
            query = 'SELECT Id, account.Name, Name, CloseDate,  rC_Giving__Giving_Amount__c, rC_Giving__Closed_Amount__c, StageName,'+
                                '(SELECT Id, quantity, UnitPrice,Product2Id, totalPrice, Product2.Name ,  Product2.isAd__c, product2.isDiscount_Item__c  FROM OpportunityLineItems WHERE product2.recordType.name = \'Item\') '+
                                'FROM Opportunity '+
                                'WHERE RecordType.Name =: oppsRecordTypes AND CampaignId =: CampaignId ORDER BY '+ sortColName +' '+ SortingOrder+ ' LIMIT 100';
            
        }
        else{
            SortingOrder = 'ASC';
            query = 'SELECT Id, account.Name, Name, CloseDate,  rC_Giving__Giving_Amount__c, rC_Giving__Closed_Amount__c, StageName,'+
                                '(SELECT Id, quantity, UnitPrice,Product2Id, Product2.Name , Product2.isAd__c, totalPrice, product2.isDiscount_Item__c  FROM OpportunityLineItems WHERE product2.recordType.name = \'Item\') '+
                                'FROM Opportunity '+
                                'WHERE RecordType.Name =: oppsRecordTypes AND CampaignId =: CampaignId ORDER BY '+ sortColName +' '+ SortingOrder+ ' LIMIT 100';
        }
        //oppsWithCmpMembers = populatecampaignMembers(selOppIdsToSort);
        system.debug('query'+query);
        system.debug('pgNum'+opp.getPageNumber());
        opp = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        //opp.setpageNumber(totalSize-(pgNum-1));
        opp.setPageSize(50);
        
    }
    /*Sorting*/
    
    /* Button Urls to navigate to Page */
    // Navigates to the Campaign manage seating Page
    public pageReference manageSeat(){
        return new PageReference('/apex/rC_Event__Campaign_Manage?id='+CampaignId);
    }
    
    // Navigates to the Campaign manage Attributes Page
    public pageReference campaignAttributes(){
        return new PageReference('/apex/rC_Event__Campaign_Manage?id='+CampaignId+'&currentTab=groups');
    }
    
    // Navigates to the New Pledge 
    public pageReference newPledge(){
        
        return new PageReference('/setup/ui/recordtypeselect.jsp?ent=Opportunity&retURL=%2F006%2Fo&save_new_url=%2F006%2Fe%3FretURL%3D%252F006%252Fo&p3='+String.ValueOf(opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_PLEDGE).getRecordTypeId()).substring(0,15));
    }
    /* Button Urls to navigate to Page */
    
    //opens the CampaignMembers list (on Select Opportunity record to show the registrations)
    /*public void campaignMembersList(){
        
        //Integer recCount = (ApexPages.currentPage().getParameters().get('selRec') != null) ? Integer.ValueOf(ApexPages.currentPage().getParameters().get('selRec')) : null;
        showChild = true;
        system.debug('cmpMemebr'+showChild);
        system.debug('selRow'+selRow);
        for(registrationWrapper rw: registrations){
            system.debug('recCount'+rw.recCount);
            // close the section if any other row was opened already
            if(rw.showCampaignMembers == true){
                rw.showCampaignMembers = false;
            }
            if(rw.recCount == selRow){
                system.debug('SelRow'+rw.objOppty.Id);
                rw.showCampaignMembers = true;
                oppId = rw.ObjOppty.Id;
            }
        }
        system.debug('oppId'+oppId);
        if(oppId != null){
            //populatecampaignMembers(oppId);
        }
    }*/
    
    //saves the campaignMembers
    public pageReference saveCampaignMembers(){
        selRow = Integer.ValueOf(ApexPages.currentPage().getParameters().get('selRec'));
        try{
            List<campaignMemberWrapper> updateCmpMemberWrapper = new List<campaignMemberWrapper>();
            List<CampaignMember> updateCmpMembers = new List<CampaignMember>();
            List<Lead> updateLeads = new List<Lead>();
            //system.debug('SelRow>>>>>'+selRow);
            for(registrationWrapper wrap: registrations){
                if(wrap.recCount == selRow){
                    updateCmpMemberWrapper = wrap.cmpMembers;   
                }
            }
            //system.debug('updateCmpMembers>>>>'+updateCmpMembers);
            
            for(campaignMemberWrapper objCmp: updateCmpMemberWrapper){
                if(objCmp.campaignmember.leadId != null){
                    updateLeads.add(new Lead(Id=objCmp.campaignmember.LeadId, LastName = objCmp.campaignmember.LastName, FirstName = objCmp.campaignmember.FirstName));
                }
                updateCmpMembers.add(objCmp.campaignmember);
                //system.debug('cmpMembers:'+objCmp.cmp.Meal_Preference__c);
            }
            
            system.debug('cmpMembers:'+cmpMembers);
            if(!updateCmpMembers.IsEmpty()){
                update updateCmpMembers;
            }
            if(!updateLeads.isEmpty()){
                update updateLeads;
            }
            
        }
        catch(exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: '+e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        return null;
    }
    
    /*Wrapper Classes */
    //Opps Wrapper Class
    public class registrationWrapper {
        public Opportunity objOppty {get;Set;}
        public Integer recCount {get;set;} 
        public Integer tickets {get;set;}
        public Integer ads {get;set;}
        public Decimal package_TicketPrice {get;set;}
        public Boolean showCampaignMembers {get;set;}
        public Decimal discountAmount{get;set;}
        public List<campaignMemberWrapper> cmpMembers {get;set;}
                
        public registrationWrapper (Opportunity obj, Integer recCount, List<campaignMemberWrapper> cmpMem){
            this.objOppty = obj;
            this.ads = 0;
            this.package_TicketPrice = 0;
            this.tickets = 0;
            this.recCount = recCount;
            //this.showCampaignMembers = camMember;
            this.cmpMembers = cmpMem;
            this.discountAmount =0;
            if(!objOppty.opportunitylineItems.IsEmpty() && objOppty.opportunitylineItems.Size()>0){
                for(OpportunityLineItem oli: objOppty.opportunitylineItems){
                    package_TicketPrice = package_TicketPrice + oli.totalPrice;
                    if(oli.product2.isAd__c == true && oli.product2.Name !='Discount Item'){
                        this.ads+=this.ads+1;
                    }
                    if(oli.product2.isAd__c == false && oli.product2.isDiscount_Item__c == false && oli.product2.Name !='Discount Item'){
                        this.tickets = this.tickets+Integer.ValueOf(oli.quantity);
                    }
                    if(oli.product2.isDiscount_Item__c == true && oli.product2.Name !='Discount Item'){
                        this.discountAmount += oli.totalPrice;
                    }
                }
            }
            //this.discountAmount = objOppty.rC_Giving__Giving_Amount__c - this.package_TicketPrice;
        }
    }
    
    //Campaing Member Wrapper Class
    public Class campaignMemberWrapper {
        public Integer Count {get;set;}
        public CampaignMember campaignmember {get;set;}
        public campaignMemberWrapper (Integer Count, CampaignMember cmpmember){
            this.Count = Count;
            this.campaignmember = cmpmember;
        }
    }
}