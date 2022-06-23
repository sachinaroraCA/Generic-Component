@isTest
public class BarcodeControllerTest {
    
    @isTest
    public static void displayResult(){
        
        Barcode_Serial__c barcodeObject = new Barcode_Serial__c();
        barcodeObject.Vcu_Serial__c  = 'testing';    
        Upsert barcodeObject;
        
        PageReference pageRef = Page.BarcodeScanVF_Page;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',barcodeObject.id);
        
        
        VCU__c vcuObject = new VCU__c();
        vcuObject.Name = 'testing';
        vcuObject.VCU_Status__c = 'Allocated';
        vcuObject.In_Service_Date__c = Date.today();
        Upsert vcuObject;
        
        
        VCU_Transaction__c vcuTransactionObject = new VCU_Transaction__c(); 
        vcuTransactionObject.Reason_for_Curbside_Cleaning__c = 'testing';
        Upsert vcuTransactionObject;
        
        Repair_Log__c repairLogObject = new Repair_Log__c();
        repairLogObject.Repair_Return_Date__c = Date.today();
        Upsert repairLogObject;
        
        Maintence_Log__c maintenceObject = new Maintence_Log__c();
        maintenceObject.Maintenance_Date__c = Date.today();
        maintenceObject.Antimicrobial_Treatment__c = true;
        maintenceObject.Filter_Cleaned__c = true;
        maintenceObject.Electrical_Cords__c = true;
        maintenceObject.Patient_Manual__c = true;
        maintenceObject.Clean_Tag__c = true;
        Upsert maintenceObject;
        
        
        VCU__c vcuObjectNew = new VCU__c();
        vcuObjectNew.Name = 'testing';
        vcuObjectNew.VCU_Status__c = 'Allocated';
        vcuObjectNew.In_Service_Date__c = Date.today();
        Upsert vcuObjectNew;
        
        VCU_Transaction__c vcuTransactionObjectNew = new VCU_Transaction__c(); 
        vcuTransactionObjectNew.Reason_for_Curbside_Cleaning__c = 'testing';
        Upsert vcuTransactionObjectNew;
        
        Repair_Log__c repairLogObjectNew = new Repair_Log__c();
        repairLogObjectNew.Repair_Return_Date__c = Date.today();
        Upsert repairLogObjectNew;
        
        Maintence_Log__c maintenceObjectNew = new Maintence_Log__c();
        maintenceObjectNew.Maintenance_Date__c = Date.today();
        maintenceObjectNew.Antimicrobial_Treatment__c = true;
        maintenceObjectNew.Filter_Cleaned__c = true;
        maintenceObjectNew.Electrical_Cords__c = true;
        maintenceObjectNew.Patient_Manual__c = true;
        maintenceObjectNew.Clean_Tag__c = true;
        Upsert maintenceObjectNew;
        
        barcodeWrapper wrapperObj = new barcodeWrapper();
        wrapperObj.vcuObj = vcuObjectNew;
        wrapperObj.vcuTransaction = vcuTransactionObjectNew;
        wrapperObj.status = 'Warehouse Clean';
        wrapperObj.repairLog = repairLogObjectNew;
        wrapperObj.maintenanceLog = maintenceObjectNew;
        wrapperObj.existingRepairLog =repairLogObject;
        
        String myJSON = JSON.serialize(wrapperObj);
        
        
        test.startTest();
        BarcodeController barObject = new BarcodeController();
        barObject.setBarcode();
        BarcodeController.getBarcode_apex();
        BarcodeController.barcodeWrapper result = BarcodeController.getBarCodeDetail_Apex(vcuObject.Name);
        BarcodeController.saveBarcode_Apex(myJSON);
        BarcodeController.saveBarcode_Apex(vcuObject.VCU_Status__c);
        BarcodeController.getTransactionTypes('Warehouse Swap');
        BarcodeController.getTransactionTypes('Assigned');
        BarcodeController.getTransactionTypes('Pickup');
        BarcodeController.getTransactionTypes('Re-Assigned');
        BarcodeController.getTransactionTypes('Curbside Clean');
        BarcodeController.getTransactionTypes('Warehouse Clean');
        BarcodeController.getTransactionTypes('Re-Allocated');
        BarcodeController.getTransactionTypes('Out for Repairs');
        BarcodeController.getTransactionTypes('Facility');
        BarcodeController.getTransactionTypes('Quarantine');
        BarcodeController.getTransactionTypes(null);
        test.stopTest();
        
    }
    public class barcodeWrapper{
        public VCU__c vcuObj {get;set;}
        //public List<picklistWrapper> transactionType {get;set;}
        public VCU_Transaction__c vcuTransaction {get;set;}
        public String status{get; set;}
        public Repair_Log__c repairLog{get; set;}
        public Maintence_Log__c  maintenanceLog {get;set;}
        public Repair_Log__c existingRepairLog {get;set;}
        //public List<picklistWrapper> coveredByWarrantyPicklist {get;set;}
    }
}