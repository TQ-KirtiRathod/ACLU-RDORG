/*
*
*Name  :  MultiselectController
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  April 19, 2017
*Purpose : Controller class for MultiselectPicklist VF Component. It is used to display the custom multi select picklist for 
*          available and selected DDPs on RunDrawloopPackages VF Page.
*
*/
public with sharing class MultiselectController {
    // SelectOption lists for public consumption
    public SelectOption[] leftOptions { get; set; }
    public SelectOption[] rightOptions { get; set; }
    
    // Parse &-separated values and labels from value and 
    // put them in option
    private void setOptions(SelectOption[] options, String value) {
        System.debug(options+'<');
        if(options != null) {
            options.clear();
            String[] parts = value.split('&');
            for (Integer i=0; i<parts.size()/2; i++) {
                options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
                  EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
            }
        }
    }
    
    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden { get; set {
           leftOptionsHidden = value;
           setOptions(leftOptions, value);
        }
    }
    
    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden { get; set {
           rightOptionsHidden = value;
           setOptions(rightOptions, value);
        }
    }
}