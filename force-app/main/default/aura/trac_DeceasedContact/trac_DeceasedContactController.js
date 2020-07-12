/**
 * Created by Surya pratap on 6/18/2019.
 */
({
    init : function(component, event, helper) {
        helper.init(component, event);
    },

    deceasedContact : function(component, event, helper) {
        helper.deceasedContacts(component, event);
    },

    updateAndDeceasedContact : function(component, event, helper) {
        helper.updateAndDeceasedContact(component, event);
    },
    
    deceasedContactFinal : function(component, event, helper) {
        helper.deceasedContactFinal(component, event);
    },
    
    closeModal : function(component, event, helper) {
      helper.closeModal(component, event);
    },
})