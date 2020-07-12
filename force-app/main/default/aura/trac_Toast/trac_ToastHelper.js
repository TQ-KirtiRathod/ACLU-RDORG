/**
 * Created by Surya pratap on 6/18/2019.
 */
({    
    hideToast: function(component) {
        component.set('v.message', '');
        component.set('v.messageType', '');
        component.set('v.title', '');
        
        if(component.get('v.closeParentWindow')) {
            window.close();
        }
    },
    destory: function(component) {
        if(component.get('v.message') && component.get('v.message').length > 0 && component.get('v.autoHide')) {
            window.setTimeout(
                $A.getCallback(function() {
                    if(component.isValid()) {
                        component.set('v.message', '');
                    }
                }), component.get('v.timeoutMS')
            );
        }
    }
})