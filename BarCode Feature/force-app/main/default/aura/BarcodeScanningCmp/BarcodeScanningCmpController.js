/**
 * Created by Cloud Analogy on 4/17/2020.
 */
({
    getVcuDetail : function(c, e, h){
        c.set('v.isSpinnerShow',true);
        var barcodeSerial = c.get("v.barcodeSerial");
        if(!$A.util.isUndefinedOrNull(barcodeSerial)){
            h.getVcuDetail_Helper(c, e, h);
        }else{
            c.set('v.isSpinnerShow',false);
        }
    },

    openBarCode : function(c, e, h){
        c.set("v.barcodePrompt", true);
    },

    openVcuFromBarcode : function(c, e, h){
        console.log("Open from Barcode Scanner");
        h.getVcuBarcode_helper(c, e, h);
        c.set("v.barcodePrompt", false);
    },

    changeTransaction : function(c, e, h){
        h.changeTransaction_Helper(c, e, h);
    },

    savePrompt : function(c, e, h){
        var validated = h.validate_Helper(c, e, h);
        console.log('validated .. '+validated);
        if(validated == true){
            h.savePrompt_Helper(c, e, h);
        }
    },

    clearBarcode : function(c, e, h){
        c.set("v.barcodeWrapper" , []);
        c.set("v.barcodeSerial" , '');
        c.set("v.selectedTransType" , '');
    }
})