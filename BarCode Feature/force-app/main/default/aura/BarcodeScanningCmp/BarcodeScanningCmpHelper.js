/**
 * Created by Cloud Analogy on 4/17/2020.
 */
({
    getVcuDetail_Helper : function(c, e, h){
        try{
            console.log('getBarCodeDetail_Apex ??');
            var action = c.get('c.getBarCodeDetail_Apex');
            action.setParams({
                "vcuSerial" : c.get("v.barcodeSerial")
            });
            action.setCallback(this, $A.getCallback(function (r) {
                console.log('r.getState() >> '+r.getState());
                console.log('response >> '+JSON.stringify(r.getReturnValue()));
                if(r.getState() == 'SUCCESS'){
                    var response = r.getReturnValue();
                    console.log('response >> '+JSON.stringify(response));
                    c.set("v.barcodeWrapper" , response);
                }
                c.set('v.isSpinnerShow',false);
            }));
            $A.enqueueAction(action);
        }catch(error){
            console.log('Exceptions >> '+error.message);
        }
    },

    changeTransaction_Helper : function(c, e, h){
        var selectedTransType = c.get("v.selectedTransType");
        var bcWrapper = c.get("v.barcodeWrapper");

        if(selectedTransType == 'Out for Repairs' ){
           bcWrapper.repairLog.VCU_Serial_Number__c = bcWrapper.vcuObj.Id;
        }

        if((bcWrapper.status=='Allocated' ||  bcWrapper.status =='Re-Assigned' || bcWrapper.status =='Warehouse Clean' || bcWrapper.status =='Curbside Clean' || bcWrapper.status =='Re-Allocated') && selectedTransType == 'Facility'){
            if(!$A.util.isUndefinedOrNull(bcWrapper.vcuObj.Facility__c)) bcWrapper.vcuTransaction.Facility__c = bcWrapper.vcuObj.Facility__c;
        }

        if(selectedTransType == 'Assigned' || selectedTransType == 'Re-Assigned' || selectedTransType == 'Re-Allocated' || selectedTransType == 'Allocated' || selectedTransType=='Pickup' ){
            if(!$A.util.isUndefinedOrNull(bcWrapper.vcuObj.Current_Surgery__c)) bcWrapper.vcuTransaction.Surgery__c = bcWrapper.vcuObj.Current_Surgery__c;
        }
        /*else{
            bcWrapper.vcuTransaction.Surgery__c = {Id : '', Name : ''};
        }*/

        if(selectedTransType=='Pickup'){
           if(!$A.util.isUndefinedOrNull(bcWrapper.vcuObj.Last_Warehouse__c))  bcWrapper.vcuTransaction.Warehouse__c = bcWrapper.vcuObj.Last_Warehouse__c;
        }else if(selectedTransType == 'Warehouse Clean' || selectedTransType == 'Warehouse Swap'){
            if(!$A.util.isUndefinedOrNull(bcWrapper.vcuObj.Current_Warehouse__c))  bcWrapper.vcuTransaction.Warehouse__c = bcWrapper.vcuObj.Current_Warehouse__c;
        }/*else{
            bcWrapper.vcuTransaction.Warehouse__c ;
        }*/

        if(selectedTransType=='Warehouse Clean' || selectedTransType=='Curbside Cleaning'){
            bcWrapper.maintenanceLog.VCU_Serial_Number__c = bcWrapper.vcuObj.Id;
        }

        if(selectedTransType == 'Warehouse Clean' && bcWrapper.status == 'Out for Repairs'){
            if(!$A.util.isUndefinedOrNull(bcWrapper.existingRepairLog)) bcWrapper.repairLog = bcWrapper.existingRepairLog;
        }
        c.set("v.barcodeWrapper", bcWrapper);
        console.log('bcWrapper ,, '+JSON.stringify(bcWrapper));
    },

    validate_Helper : function(c, e, h){
        var bcWrapper = c.get("v.barcodeWrapper");
        var status = '';
        var selectedTransType = c.get("v.selectedTransType");
        if(!$A.util.isUndefinedOrNull(bcWrapper)){
            if(!$A.util.isUndefinedOrNull(bcWrapper.status)){
               status = bcWrapper.status;
            }
        }else { return false; }
        
        if((status=='Allocated' || status=='Re-Assigned' || status=='Warehouse Clean' || status=='Curbside Clean' || status=='Re-Allocated') && selectedTransType=='Facility'){
             bcWrapper.vcuObj.Facility__c = bcWrapper.vcuTransaction.Facility__c;
             //update vcuList[0];
        }
        /*if(selectedTransType == 'Out for Repairs'){
            bcWrapper.vcuTransaction.Transaction_Type__c = selectedTransType;
        }*/
        if(!$A.util.isUndefinedOrNull(selectedTransType)){
            bcWrapper.vcuTransaction.Transaction_Type__c = selectedTransType;
        }

        if((selectedTransType == 'Allocated' || selectedTransType == 'Assigned' || selectedTransType =='Re-Assigned') && ($A.util.isUndefinedOrNull(bcWrapper.vcuTransaction.Surgery__c) || $A.util.isEmpty(bcWrapper.vcuTransaction.Surgery__c)))
        {
            /*c.set("v.errorMessage", 'Please Enter the Surgery.');
            c.find("VCU_Transaction_Surgery").set("v.error", 'Please Enter the Surgery.');*/
            h.showToast(c,e,h, 'Error!', 'error', 'Please Enter the Surgery.');
            return false;
        }

        else if(selectedTransType == 'Warehouse Swap' && ($A.util.isUndefinedOrNull(bcWrapper.vcuTransaction.Warehouse__c) || $A.util.isEmpty(bcWrapper.vcuTransaction.Warehouse__c)))
        {
             /*c.set("v.errorMessage", 'Please Enter the Warehouse.');
             c.find("WarehouseSwap").set("v.error", 'Please Enter the Warehouse.');*/
             h.showToast(c,e,h, 'Error!', 'error', 'Please Enter the Warehouse.');
            return false;
        }
        else if(selectedTransType == 'Facility' && ($A.util.isUndefinedOrNull(bcWrapper.vcuTransaction.Facility__c) || $A.util.isEmpty(bcWrapper.vcuTransaction.Facility__c)))
        {
            /*c.set("v.errorMessage", 'Please Enter the Facility.');
            c.find("facilityTrans").set("v.error", 'Please Enter the Facility.');*/
            h.showToast(c,e,h, 'Error!', 'error', 'Please Enter the Facility.');
            return false;
        }
        else if(selectedTransType == 'Re-Assigned' && ($A.util.isUndefinedOrNull(bcWrapper.vcuTransaction.Reason_for_Re_Assignment__c) || $A.util.isEmpty(bcWrapper.vcuTransaction.Reason_for_Re_Assignment__c)))
        {
            h.showToast(c,e,h, 'Error!', 'error', 'Please Enter the Reason for Reassignment.');
            return false;
        }
        else if((status=='Facility' || status=='Pickup') && selectedTransType == 'Curbside Cleaning' && ($A.util.isUndefinedOrNull(bcWrapper.vcuTransaction.Reason_for_Curbside_Cleaning__c) || $A.util.isEmpty(bcWrapper.vcuTransaction.Reason_for_Curbside_Cleaning__c)))
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please Enter the Reason for Curbside Cleaning.');
            return false;
        }

        else if((status=='Pickup' || status=='Out for Repairs' || status=='Facility') && (selectedTransType == 'Warehouse Clean' || selectedTransType == 'Curbside Cleaning')  && bcWrapper.maintenanceLog.Antimicrobial_Treatment__c == false)
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please check the Antimicrobial treatment field.');
            return false;
        }
        else if((status=='Pickup' || status=='Out for Repairs') && selectedTransType == 'Warehouse Clean' && bcWrapper.maintenanceLog.Filter_Cleaned__c == false)
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please check the Filter cleaned field.');
            return false;
        }
        else if((status=='Pickup' || status=='Out for Repairs') && selectedTransType == 'Warehouse Clean' && bcWrapper.maintenanceLog.Electrical_Cords__c == false)
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please check the Electrical cords field.');
            return null;
        }
        else if((status=='Pickup' || status=='Out for Repairs' || status=='Facility') && (selectedTransType == 'Warehouse Clean'|| selectedTransType == 'Curbside Cleaning') && bcWrapper.maintenanceLog.Patient_Manual__c == false)
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please check the Patient Manual field.');
            return false;
        }
        else if((status=='Pickup'|| status=='Out for Repairs') && selectedTransType == 'Warehouse Clean' && bcWrapper.maintenanceLog.Clean_Tag__c == false )
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please check the Clean Tag field.');
            return false;
        }
        else if((status=='Facility' || status=='Pickup') && selectedTransType == 'Curbside Cleaning' && bcWrapper.maintenanceLog.Swap_Filter__c ==false)
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please check the Swap Filter Field.');
            return false;
        }
        else if((status=='Facility' || status=='Pickup') && selectedTransType == 'Curbside Cleaning' && bcWrapper.maintenanceLog.Refill_Fluid__c ==false)
        {
           h.showToast(c, e, h, 'Error!', 'error', 'Please check the Refill fluid Field.');
           return false;
        }
        else if((status=='Out for Repairs' || status=='Pickup' || status=='Facility') && (selectedTransType == 'Warehouse Clean' || selectedTransType == 'Curbside Cleaning') &&
            ($A.util.isUndefinedOrNull(bcWrapper.maintenanceLog.VCU_Serial_Number__c) || $A.util.isEmpty(bcWrapper.maintenanceLog.VCU_Serial_Number__c)))
        {
           h.showToast(c, e, h, 'Error!', 'error', 'Please Enter the VCU.');
           return false;
        }
        else if( (status=='Pickup' || status=='Out for Repairs') && selectedTransType == 'Warehouse Clean'  &&
            ($A.util.isUndefinedOrNull(bcWrapper.maintenanceLog.Performed_By__c) || $A.util.isEmpty(bcWrapper.maintenanceLog.Performed_By__c)))
        {
           h.showToast(c, e, h, 'Error!', 'error', 'Please Enter the Performed By field.');
           return false;
        }
        else if(selectedTransType == 'Warehouse Clean' && (status=='Out for Repairs' || status=='Pickup') &&
             ($A.util.isUndefinedOrNull(bcWrapper.maintenanceLog.Maintenance_Date__c) || $A.util.isEmpty(bcWrapper.maintenanceLog.Maintenance_Date__c)))
        {
           h.showToast(c, e, h, 'Error!', 'error', 'Please Enter the Maintenance Date.');
           return false;
        }
        else if((status=='Pickup' || status=='Out for Repairs' || status=='Facility') && (selectedTransType == 'Warehouse Clean' || selectedTransType == 'Curbside Cleaning') &&
         ($A.util.isUndefinedOrNull(bcWrapper.maintenanceLog.Current_Unit_Hours__c) || $A.util.isEmpty(bcWrapper.maintenanceLog.Current_Unit_Hours__c)))
        {
            h.showToast(c, e, h, 'Error!', 'error', 'Please Enter the Current Unit Hours.');
            return false;
        }

        return true;
    },

    savePrompt_Helper : function(c, e, h){
        try{
            var bcWrapper = c.get("v.barcodeWrapper");
            console.log('bcWrapper >> '+JSON.stringify(bcWrapper));
            var action = c.get('c.saveBarcode_Apex');
            action.setParams({
                "bcWrapperJson" : JSON.stringify(bcWrapper)
            });
            action.setCallback(this, $A.getCallback(function (r) {
                console.log('r.getState() >> '+r.getState());
                if(r.getState() == 'SUCCESS'){
                    h.showToast(c, e, h, 'Success!', 'success', 'Your Entries have been saved successfully!');
                    c.set("v.barcodeWrapper" , []);
                    c.set("v.barcodeSerial" , '');
                    c.set("v.selectedTransType" , '');
                }else{
                    h.showToast(c, e, h, 'Error!', 'error', r.getState());
                }
            }));
            $A.enqueueAction(action);
        }catch(error){
            console.log('Exceptions >> '+error.message);
            h.showToast(c, e, h, 'Error!', 'error', error.message);
        }
    },

    getVcuBarcode_helper : function(c, e, h){
        //getBarcode_apex
        try{
            var action = c.get('c.getBarcode_apex');
            action.setParams({ });
            action.setCallback(this, $A.getCallback(function (r) {
                console.log('r.getState() >> '+r.getState());
                console.log('response >> '+JSON.stringify(r.getReturnValue()));
                if(r.getState() == 'SUCCESS'){
                    var response = r.getReturnValue();
                    console.log('response >> '+JSON.stringify(response));
                    c.set("v.barcodeSerial" , response);
                    if(response != null){
                       h.getVcuDetail_Helper(c, e, h);
                    }else{
                        c.set("v.barcodeWrapper" , []);
                        c.set("v.selectedTransType" , '');
                    }
                }
            }));
            $A.enqueueAction(action);
        }catch(error){
            console.log('Exceptions >> '+error.message);
        }
    },

    showToast : function(component, event, helper, title, errorType, message) {
        /*var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type" : errorType,
            "message": message
        });
        toastEvent.fire();*/
        console.log('in toast');
        helper.showToast_Helper(component, errorType, message);
    },
    
    showToast_Helper: function (component, variant, message) {
        console.log('in toast 2');
        component.set('v.variant', variant);
        component.set('v.message', message);
        component.set('v.showToast', true);
    },


})