/**
 * Created by Surya pratap on 6/18/2019.
 */
({
    fetchAndSaveData: function(component, method, params, successCallback, errorCallback) {
        var action = component.get(('c.' + method));
        if(Object.keys(params)) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                successCallback(response.getReturnValue());
            }
            else if(state === 'ERROR') {
                if(errorCallback) {
                    errorCallback(response.getError()?[response.getError()[0].message]:'Unknown Error Occurred!');
                }
            }
                else if(response.getState() === 'INCOMPLETE') {
                    if(errorCallback) {
                        errorCallback('Server could not be reached. Check your internet connection.');
                    }
                }
                    else {
                        if(errorCallback) {
                            errorCallback('Unknown error');
                        }
                    }
        });
        $A.enqueueAction(action);
    },
    
    showToastMessage : function(component, messageType, message) {
        component.set('v.message', message);
        component.set('v.messageType', messageType);
    },
    
    showHideSpinner : function(component, showHideSpinner) {
        component.set('v.showSpinner',showHideSpinner);
    },
    
    closeParentWindow : function(component, closeParentWindow) {
        component.set('v.closeParentWindow', closeParentWindow);
    },

})