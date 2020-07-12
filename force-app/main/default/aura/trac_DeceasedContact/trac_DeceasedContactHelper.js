/**
 * Created by Surya pratap on 6/18/2019.
 */
({
    init : function(component, event) {
        var self = this;
        self.showHideSpinner(component, true);
        self.fetchAndSaveData(component, 'getContact',
                              {
                                  'recordId': component.get('v.recordId')
                              },
                              function(response) {
                                  self.showHideSpinner(component, false);
                                  if(response) {
                                      component.set('v.contactRecord',response);
                                      component.set('v.isDeceasedContact', false);
                                     
                                      if(response.rC_Bios__Deceased__c) {
                                          component.set('v.isContactAlreadyDeceased', true);
                                      } else {
                                          component.set('v.isDeceasedContact', false);
                                      } 
                                  }
                              });
        
    },
    
    deceasedContacts : function(component, event) {
        this.getDeceasedContactDayMonthAndYearPicklistValues(component, event);
        component.set('v.isDeceasedContact', true);
        component.set('v.contactRecord.rC_Bios__Deceased__c',true);
    },
    
    updateAndDeceasedContact : function(component, event) {
        var self = this;
        
        self.showHideSpinner(component, true);
        self.closeParentWindow(component,true);
        self.fetchAndSaveData(component, 'updateContact',
                              {
                                  'contactJSON':JSON.stringify(component.get('v.contactRecord'))
                              },
                              function(response) {
                                  self.showHideSpinner(component, false);
                                  if(response) {
                                      var resp = JSON.parse(response);
                                      self.showToastMessage(component, resp.status, resp.message);
                                  }
                              });
    },
    
    validateContactRecord : function(component) {
        var self = this;
        var isValid = true;
        var contactRecord = component.get('v.contactRecord');
        
        self.closeParentWindow(component,false);
        if(!contactRecord || !contactRecord.rC_Bios__Deceased_Year__c) {
            self.showToastMessage(component, 'error', 'Deceased year field is required');
            isValid = false;
        } else {
            self.showToastMessage(component, '','');
        }
        return isValid;
    },
    
    getDeceasedContactDayMonthAndYearPicklistValues : function(component, event) {
        var self = this
        self.showHideSpinner(component, true);
        self.fetchAndSaveData(component, 'getDeceasedDateAndHelpTextInfo',
                              {},
                              function(response) {
                                  self.showHideSpinner(component, false);
                                  if(response) {
                                      var resp = JSON.parse(response);
                                      component.set('v.deceasedDate', resp.DeceasedDate);
                                      component.set('v.isDeceasedContactHelpText', resp.HelpText);
                                  }
                              });
    },
    
    deceasedContactFinal : function(component, event) {
        if(this.validateContactRecord(component)) {
            component.set('v.isDeceasedFinalContact', true);
        }
    },
    
    closeModal : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        window.close();
    },
})