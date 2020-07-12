/*
*
*Name  :  AddPreferenceController
*Author:  ACLU  (David Reed)
*Date  :  June 12, 2017
*Purpose : Controller class for AddPreference Page, used when adding preferences in account record
*
* Modified by :: roundCorner Inc. :: 18-Jan-2019 :: Zendesk: #55328
* Description :: When user leaves it null on save, populate with Today
* 
* Modified by :: roundCorner Inc. :: 21-Jan-2019 :: Zendesk: #58568
* Description :: When user cancels from Preference, they should be redirected to Account record
*
* Modified by :: SFDO :: 22-Apr-2019 :: Zendesk: #66345
* Description :: Added Active flag in the filter query to pull only active preferences
* Change Log  :: Traction(Mounica V), January 31,2020-Ticket:BGE-02 : Included the logic to eliminate creation of duplicate preferences from Account.
*/
public with sharing class AddPreferenceController {
    private ApexPages.StandardController c;
    public String filter { get; set; }
    public Integer page { get; set; }
    public Integer pages { get; private set; }
    public Integer count { get; private set; }
    public rC_Bios__Preference__c p { get; set; }
    public rC_Bios__Preference_Code__c pc { get; set; }
    public List<rC_Bios__Preference_Code__c> filteredPreferenceCodes { get; private set; }
    public String selectedCategory { get; set; }
    private Map<String, String> PageParameters = new Map<String, String>();

    // pageSize cannot exceed 1,000, which is the limit on collection size in Visualforce components.
    public Integer pageSize {
        get;
        set {
            pageSize = Math.min(Math.abs(value), 1000);
            if (pageSize == 0) {
                pageSize = 1000;
            }
            filterPreferenceCodes();
        }
    }

    public AddPreferenceController(ApexPages.StandardController ctrlr) {
        c = ctrlr;

        if (!Test.isRunningTest())
	        c.addFields(new List<String>{'rC_Bios__Code_Value__c', 'rC_Bios__Account__c', 'rC_Bios__Account__r.Name'});
        p = (rC_Bios__Preference__c)ctrlr.getRecord();
        if (p.rC_Bios__Code_Value__c != null && p.rC_Bios__Code_Value__c != '') {
            updatePreferenceCode();
        }

        filter = '';
        pageSize = 1000;
    }

    public Boolean getCanUserEdit() {
        return PreferenceUtility.canUserEditCodeValue(PreferenceUtility.isAffiliateUser(), 
                                                      p.rC_Bios__Code_Value__c) 
          && Schema.sObjectType.rC_Bios__Preference__c.isUpdateable();
    }

    public void updatePreferenceCode() {
        if (p.rC_Bios__Code_Value__c != null && p.rC_Bios__Code_Value__c != '') {
            List<rC_Bios__Preference_Code__c> pcs = [SELECT Id, rC_Bios__Code_Value__c, Description__c
                                                     FROM rC_Bios__Preference_Code__c
                                                     WHERE rC_Bios__Code_Value__c = :p.rC_Bios__Code_Value__c];
            if (pcs.size() == 1) {
                pc = pcs[0];
            } else {
                pc = null;
           		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
                                                           String.format('The Preference Code ({0}) associated with this Preference does not exist.',
                                                                         new List<String>{p.rC_Bios__Code_Value__c})));
            }
        } else {
            pc = null;
        }
    }

    public static String getWhereClause(String filter, String category) {
        // Construct and return a WHERE clause for our Dynamic SOQL filter
        String whereClause = '';
        Integer count;

        // Only applies for affiliate users or where a filter/category restriction is in effect. Otherwise blank.
        if (!String.isBlank(filter) || !String.isBlank(category) || PreferenceUtility.isAffiliateUser()) {
            whereClause = 'WHERE ';

            if (!String.isBlank(filter)) {
                whereClause += '(rC_Bios__Code_Value__c LIKE \'' + String.escapeSingleQuotes(filter) + '\' OR Description__c LIKE \'' + String.escapeSingleQuotes(filter) + '\') ';
            }

            if (!String.isBlank(category)) {
                if (!String.isBlank(filter)) {
                    whereClause += 'AND ';
                }

                whereClause += 'rC_Bios__Category__c = \'' + String.escapeSingleQuotes(category) + '\' ';

            }

            if (PreferenceUtility.isAffiliateUser()) {
                if (!String.isBlank(filter) || !String.isBlank(category)) {
                    whereClause += 'AND ';
                }
                // Simply don't display to affiliate users codes they're not allowed to add.
                whereClause += '((NOT rC_Bios__Code_Value__c LIKE \'N%\') AND ((NOT rC_Bios__Code_Value__c LIKE \'O%\') OR rC_Bios__Code_Value__c LIKE \'OXX%\')) ';
            }
        }
        //BEGIN:#66345
        whereClause = String.isNotBlank(whereClause) ? whereClause + ' AND Active__c = true ' : ' WHERE Active__c = true ';
		//END:#66345
        return whereClause;
    }

    public List<SelectOption> getCategorySelectOptions() {
        List<SelectOption> categories = new List<SelectOption>();

        categories.add(new SelectOption('', 'All Categories'));

        for (Schema.PicklistEntry p : rC_Bios__Preference__c.rC_Bios__Category__c.getDescribe().getPicklistValues()) {
            if (p.isActive()) {
                categories.add(new SelectOption(p.getValue(), p.getLabel()));
            }
        }

        return categories;
    }

    public PageReference filterPreferenceCodes() {
        // Rerun our query to apply current filters.
        filteredPreferenceCodes = new List<rC_Bios__Preference_Code__c>();
        page = 0;
        count = Database.countQuery('SELECT COUNT() ' +
                                    'FROM rC_Bios__Preference_Code__c ' +
                                    getWhereClause('%' + filter + '%', selectedCategory));

        pages = (Integer)Math.ceil((Double)count / (Double)pageSize);
        // next() will query the first page of results.
        next();

        return null;
    }

    public PageReference next() {
        // Query the next page of results with our current filters.
        if (pages > 0 && page < pages) {
            Integer offset;

            page += 1;
            offset = (page - 1) * pageSize;

            filteredPreferenceCodes = Database.query('SELECT Id, Name, rC_Bios__Code_Value__c, Description__c, rC_Bios__Category__c ' +
                                                      'FROM rC_Bios__Preference_Code__c ' +
                                                      getWhereClause('%' + filter + '%', selectedCategory) +
                                                      'ORDER BY rC_Bios__Code_Value__c ' +
                                                      'LIMIT :pageSize ' +
                                                      'OFFSET :offset');
        }

        return null;
    }

    public PageReference prev() {
        // Query the previous page of results with our current filters.
        if (pages > 0 && page > 1) {
            Integer offset;

            page -= 1;
            offset = (page - 1) * pageSize;

            filteredPreferenceCodes = Database.query('SELECT Id, Name, rC_Bios__Code_Value__c, Description__c, rC_Bios__Category__c ' +
                                                     'FROM rC_Bios__Preference_Code__c ' +
                                                     getWhereClause('%' + filter + '%', selectedCategory) +
                                                     'ORDER BY rC_Bios__Code_Value__c ' +
                                                     'LIMIT :pageSize ' +
                                                     'OFFSET :offset');
        }

        return null;
    }


    public PageReference selectPreferenceCode() {
        // The accessor for the apex:param handles updating p.
		updatePreferenceCode();
        return null;
    }

    public PageReference save() {
        // Override to provide some additional checking.
        // Marking the fields below Required on the layout results in errors upon AJAX requests, so we'll check here.
		
        if (p.rC_Bios__Account__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You must associate this Preference with an Account.'));
        }

        if (p.rC_Bios__Code_Value__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'You must associate this Preference with an Preference Code.'));
        }

        //Zendesk: #55328
        if(p.rC_Bios__Start_Date__c == null) {
            p.rC_Bios__Start_Date__c = System.today();
        }//End :: #55328
        
        if(p.rC_Bios__Account__c <> null && p.rC_Bios__Code_Value__c <> null ){ //BGE-02    
        p.Bup_Sequence__c = 'Manually Created from Account';
        checkForDupe(p.rC_Bios__Code_Value__c,p.rC_Bios__Account__c,p.rC_Bios__Contact__c); 
        }//BGE-02 END
        // Call through to the main controller's save.
        if (ApexPages.getMessages().size() == 0) {
			c.save();
        }
        
        // If the main controller threw an error (or we did above), reload this page.
        if (ApexPages.getMessages().size() > 0) {
            return null;
        }

        // If no errors, we'll redirect to the account.
        return new ApexPages.StandardController(new Account(Id = p.rC_Bios__Account__c)).view();
    }

    public PageReference saveAndNew() {
         
        PageReference pr = save();

        // null indicates an error occurred
        if (pr != null) {
            pr = new PageReference('/' + rC_Bios__Preference__c.sObjectType.getDescribe().getKeyPrefix() + '/e');

            pr.getParameters().put('CF00N36000008gj62', p.rC_Bios__Account__r.Name);
            pr.getParameters().put('CF00N36000008gj62_lkid', p.rC_Bios__Account__c);
            pr.getParameters().put('retURL', new ApexPages.StandardController(new Account(Id = p.rC_Bios__Account__c)).view().getUrl());
            pr.getParameters().put('cancelURL', new ApexPages.StandardController(new Account(Id = p.rC_Bios__Account__c)).view().getUrl());
            pr.setRedirect(true);
        }

        return pr;
    }
       
      //   Zendesk: #58568
      // Created a method to redirect to Account detail page
     public PageReference cancel() {
         PageReference pr;
         if(p.rC_Bios__Account__c != null) {
             pr  = new PageReference(URL.getSalesforceBaseUrl().toExternalForm()+'/'+p.rC_Bios__Account__c);
         }
         else {
             pr  = new PageReference(URL.getSalesforceBaseUrl().toExternalForm()+'/'+rC_Bios__Preference__c.sObjectType.getDescribe().getKeyPrefix()); 
         }
         
         pr.setRedirect(true);

         return pr;
     }
    //  End Zendesk: #58568
    
    /*Traction(Mounica), January 28,2020, BGE-2 : Prevent duplicate preference creation*/
     Public void checkForDupe(String sCodeValue,String sAccount,String sContact){

        String queryString = 'SELECT Id,rC_Bios__Active__c,rC_Bios__End_Date__c,rC_Bios__Comments__c,rC_Bios__Contact__c,rC_Bios__Status__c,rC_Bios__Code_Value__c,rC_Bios__Account__c from rC_Bios__Preference__c ';
        queryString += 'Where rC_Bios__Code_Value__c = \'' + sCodeValue + '\' AND rC_Bios__Account__c = \'' + sAccount + '\' ';
        
        if(p.rC_Bios__Contact__c <> null)
        queryString += 'AND rC_Bios__Contact__c =  \'' + sContact + '\'';
        
        List<rC_Bios__Preference__c> lstPreferences = database.query(queryString);
        
        PageParameters = ApexPages.currentPage().getParameters();
        String sCurrentId = '';
        
        if (PageParameters.get('id') != null){
         sCurrentId = PageParameters.get('id') ;
         }
        
        if(lstPreferences.size() > 0)
            {
           for(rC_Bios__Preference__c oPre : lstPreferences){
           
           if(sCurrentId == '' || (sCurrentId <> null && sCurrentId != oPre.id)){
           if(p.rC_Bios__Contact__c <> null && oPre.rC_Bios__Contact__c <> null && p.rC_Bios__Contact__c == oPre.rC_Bios__Contact__c) { 
              if(oPre.rC_Bios__Active__c == True && P.rC_Bios__Active__c == True && oPre.rC_Bios__End_Date__c == null && p.rC_Bios__End_Date__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An Active preference without an End Date and with the selected Contact already exists on this Account.'));
                }
           }
           else if(oPre.rC_Bios__Contact__c == null && p.rC_Bios__Contact__c == null) { 
              if(oPre.rC_Bios__Active__c == True && P.rC_Bios__Active__c == True && oPre.rC_Bios__End_Date__c == null && p.rC_Bios__End_Date__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An Active preference without an End Date already exists on this Account.'));
                 
              }
             }
          }
        }
       }  
     }
    
}