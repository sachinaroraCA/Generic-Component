/**
* Created by Cloud Analogy on 4/17/2020.
*/

public with sharing class BarcodeController {
    
    public void setBarcode(){
        try {
            string barCode = Apexpages.currentPage().getParameters().get('barcodeSerial');
            Barcode_Serial__c barCodeCustom = Barcode_Serial__c.getOrgDefaults();
            if (barCodeCustom == null) {
                barCodeCustom = new Barcode_Serial__c();
            }
            barCodeCustom.Vcu_Serial__c = barCode;
            upsert barCodeCustom;
        }catch(Exception ex){
            System.debug('The exception is : '+ex.getMessage()+' at line number '+ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public Static String getBarcode_apex(){
        try {
            String barCodeCustom = Barcode_Serial__c.getOrgDefaults().Vcu_Serial__c;
            Barcode_Serial__c  barcodeUpdate = Barcode_Serial__c.getOrgDefaults();
            if(barcodeUpdate == null){
                barcodeUpdate = new Barcode_Serial__c();
            }
            barcodeUpdate.Vcu_Serial__c = '';
            upsert barcodeUpdate;
            return barCodeCustom;
        }catch(Exception ex){
            System.debug('The exception is : '+ex.getMessage()+' at line number '+ex.getLineNumber());
        }
        return null;
    }
    
    @AuraEnabled
    public static barcodeWrapper getBarCodeDetail_Apex(String vcuSerial, Id currentSurgeryId){
        try {
            barcodeWrapper bcWrapper = new barcodeWrapper();            
            bcWrapper.vcuObj = getVCUs_Apex(vcuSerial);
            
            bcWrapper.currentSurgeryObject = getCurrentSurgery(currentSurgeryId);
            System.debug('bcWrapper.currentSurgeryObject.Equipment_and_Supplies__c >> '+bcWrapper.currentSurgeryObject.Equipment_and_Supplies__c);
            bcWrapper.relatedSurgeryOfCurrentSurgery = getRelatedSurgeryOfCurrentSurgery(currentSurgeryId,bcWrapper.currentSurgeryObject.Patient_Name__c);
            bcWrapper.patientRelatedSurgery = getPatientRelatedSurgery(vcuSerial,currentSurgeryId);
            
            if (bcWrapper.vcuObj != null) {
                bcWrapper.transactionType = getTransactionTypes(bcWrapper.vcuObj.VCU_Status__c,bcWrapper.vcuObj.Reason_for_VCU_Unit_Swap__c,bcWrapper.relatedSurgeryOfCurrentSurgery,bcWrapper.patientRelatedSurgery,bcWrapper.currentSurgeryObject.Equipment_and_Supplies__c);
                bcWrapper.vcuObj.Reason_for_VCU_Unit_Swap__c = null;
                bcWrapper.status = bcWrapper.vcuObj.VCU_Status__c;
                if (bcWrapper.status == 'Out for Repairs') {
                    bcWrapper.repairLog.VCU_Serial_Number__c = bcWrapper.vcuObj.Id;
                }
                LIST<Repair_Log__c> repair_logs = getRepairLog(vcuSerial);
                if (repair_logs.size() > 0) {
                    bcWrapper.existingRepairLog = repair_logs[0];
                }
                bcWrapper.coveredByWarrantyPicklist = getCoveredByWarrantyPicklist();
            }
            return bcWrapper;
        }catch(Exception ex){
            System.debug('The exception is : '+ex.getMessage()+' at line number '+ex.getLineNumber());
        }
        return null;
    }
    
    @AuraEnabled
    public static void saveBarcode_Apex(String bcWrapperJson,String vcuSerial, Id currentSurgeryId){
        try {
            barcodeWrapper bcWrapper = new barcodeWrapper();                         
            
            if(String.isNotEmpty(bcWrapperJson) && bcWrapperJson != null) {
                bcWrapper = (barcodeWrapper) JSON.deserialize(bcWrapperJson, barcodeWrapper.class);
            }
            if (bcWrapper != null) {           
                if(bcWrapper.vcuTransaction.Transaction_Type__c == 'Pickup'){                 
                    bcWrapper.vcuObj = checkPickupTransactionType(bcWrapperJson,vcuSerial,currentSurgeryId,bcWrapper.currentSurgeryObject.Patient_Name__r.Name);
			}
                if ((bcWrapper.status == 'Allocated' || bcWrapper.status == 'Re-Assigned' || bcWrapper.status == 'Warehouse Clean' || bcWrapper.status == 'Curbside Clean' || bcWrapper.status == 'Re-Allocated') && bcWrapper.vcuTransaction.Transaction_Type__c == 'Facility') {
                    update bcWrapper.vcuObj;
                }
                else if(bcWrapper.status == 'Pickup' && (bcWrapper.vcuTransaction.Transaction_Type__c == 'Warehouse Clean' || bcWrapper.vcuTransaction.Transaction_Type__c == 'Curbside Clean')){
                    bcWrapper.vcuObj.Current_Surgery__c = null;
                    update bcWrapper.vcuObj;
                }
                
                bcWrapper.vcuTransaction.VCU__c = bcWrapper.vcuObj.id;
                bcWrapper.maintenanceLog.VCU_Serial_Number__c = bcWrapper.vcuObj.id;
                bcWrapper.maintenanceLog.Filter_Cleaned__c = true;
                bcWrapper.maintenanceLog.Antimicrobial_Treatment__c = true;
                bcWrapper.maintenanceLog.Electrical_Cords__c = true;
                bcWrapper.maintenanceLog.Patient_Manual__c = true;
                bcWrapper.maintenanceLog.Clean_Tag__c = true;
                bcWrapper.repairLog.VCU_Serial_Number__c = bcWrapper.vcuObj.id;
                bcWrapper.repairLog.Repair_Return_Date__c = system.today();
                
                if (bcWrapper.vcuTransaction.Surgery__c != null) {
                    List<Surgery__c> surgeryList = [select id,Equipment_and_Supplies__c,Warehouse_Allocated_VCU__c,Unit_Swapped__c,Patient_Name__c,Related_Surgery__c,Surgery_Status__c,Field_Tech_that_Inserviced_Patient__c,Field_Tech_that_PU_equipment__c from Surgery__c where Id = :bcWrapper.vcuTransaction.Surgery__c WITH SECURITY_ENFORCED];                                                                     
                    if (!surgeryList.isEmpty()) {
                        if ((bcWrapper.status == 'Warehouse Clean' || bcWrapper.status == 'Curbside Clean' || bcWrapper.status == 'Allocated' || bcWrapper.status == 'Re-Allocated') && bcWrapper.vcuTransaction.Transaction_Type__c == 'Assigned' || bcWrapper.vcuTransaction.Transaction_Type__c == 'Re-Assigned') {
                            surgeryList[0].Equipment_and_Supplies__c = bcWrapper.vcuObj.Name;
                            surgeryList[0].Surgery_Status__c = 'In Service Completed';
                            surgeryList[0].Field_Tech_that_Inserviced_Patient__c = UserInfo.getName();
                        }
                        //updated
                        if ((bcWrapper.status == 'Assigned' || bcWrapper.status == 'Re-Assigned') && bcWrapper.vcuTransaction.Transaction_Type__c == 'Assigned') {
                            surgeryList[0].Equipment_and_Supplies__c = bcWrapper.vcuObj.Name;
                            surgeryList[0].Surgery_Status__c = 'In Service Completed';
                            surgeryList[0].Field_Tech_that_Inserviced_Patient__c = UserInfo.getName();
                        }
                        if (bcWrapper.vcuTransaction.Transaction_Type__c == 'Allocated' || bcWrapper.vcuTransaction.Transaction_Type__c == 'Re-Allocated') {
                            surgeryList[0].Warehouse_Allocated_VCU__c = bcWrapper.vcuObj.Name;
                        }
                        if (bcWrapper.status == 'Allocated' && bcWrapper.vcuTransaction.Transaction_Type__c == 'Unallocate') {
                            surgeryList[0].Warehouse_Allocated_VCU__c = '';
                        }
                        //Modified by ANUJ GOEL.
                        if (bcWrapper.vcuTransaction.Transaction_Type__c == 'Pickup') {
                            surgeryList[0].Surgery_Status__c = 'Pickup Service Completed';
                            surgeryList[0].Field_Tech_that_PU_equipment__c = UserInfo.getName();
                            bcWrapper.vcuObj.Reason_for_VCU_Unit_Swap__c=null;
                            Database.update(bcWrapper.vcuObj);
                        } 
                        if (bcWrapper.vcuTransaction.Transaction_Type__c == 'Transfer to an additional event') {
                            VCU_Transaction__c vcuTransactionToInsertRecord = new VCU_Transaction__c();                                                 
                            if(bcWrapper.relatedSurgeryOfCurrentSurgery!=null){         
                                bcWrapper.relatedSurgeryOfCurrentSurgery.Surgery_Status__c = 'In Service Completed'; 
                                bcWrapper.relatedSurgeryOfCurrentSurgery.Field_Tech_that_Inserviced_Patient__c = UserInfo.getName();
                                surgeryList[0].Surgery_Status__c = 'Pickup Service Completed';
                                surgeryList[0].Field_Tech_that_PU_equipment__c = UserInfo.getName();
                                bcWrapper.relatedSurgeryOfCurrentSurgery.Equipment_and_Supplies__c = bcWrapper.vcuObj.Name;
								bcWrapper.vcuObj.Current_Surgery__c = bcWrapper.relatedSurgeryOfCurrentSurgery.Id; 
                                bcWrapper.vcuObj.VCU_Status__c = 'Assigned';
                                bcWrapper.vcuTransaction.Surgery__c = surgeryList[0].Id;
                                bcWrapper.vcuTransaction.Warehouse__c = bcWrapper.vcuObj.Last_Warehouse__c;
                                bcWrapper.vcuTransaction.Transaction_Type__c = 'Pickup';
                                Database.insert(bcWrapper.vcuTransaction);                                                               
                                vcuTransactionToInsertRecord.Surgery__c = bcWrapper.relatedSurgeryOfCurrentSurgery.Id;                                
                                vcuTransactionToInsertRecord.Transaction_Type__c = 'Assigned';
                                vcuTransactionToInsertRecord.VCU__c = bcWrapper.vcuObj.Id;                               
                                Database.insert(vcuTransactionToInsertRecord);
                                Database.update(bcWrapper.relatedSurgeryOfCurrentSurgery);
                                update bcWrapper.vcuObj;
                            }
                        }
                        if(bcWrapper.vcuTransaction.Transaction_Type__c == 'Assign to this Surgery'){
                            bcWrapper.vcuObj.VCU_Status__c = 'Assigned';
                            bcWrapper.vcuObj.Current_Surgery__c = surgeryList[0].Id;  
                            surgeryList[0].Field_Tech_that_Inserviced_Patient__c = UserInfo.getName();
                            surgeryList[0].Equipment_and_Supplies__c = bcWrapper.vcuObj.Name;
                            update bcWrapper.vcuObj;
                            //update surgeryList;
                            
                        }
                        
                        if(bcWrapper.status == 'Assigned' && bcWrapper.vcuTransaction.Transaction_Type__c == 'VCU Unit Swap') {                    
                            surgeryList[0].Unit_Swapped__c = surgeryList[0].Equipment_and_Supplies__c;
                            surgeryList[0].Equipment_and_Supplies__c = null;
                            surgeryList[0].Warehouse_Allocated_VCU__c = null;
                            bcWrapper.vcuObj.Current_Surgery__c = null;
                            bcWrapper.vcuObj.VCU_Status__c = 'Pickup';
                            Database.update(bcWrapper.vcuObj);
                        } 
                        update surgeryList[0];                                              
                    }
                }
                
                Database.SaveResult sr = Database.insert(bcWrapper.vcuTransaction, false);                                             
                if (bcWrapper.vcuTransaction.Transaction_Type__c == 'Curbside Cleaning') {
                    bcWrapper.maintenanceLog.recordtypeId = [select id from RecordType where name = 'Curbside' limit 1].Id;
                    upsert bcWrapper.maintenanceLog;
                }
                if ((bcWrapper.status == 'Pickup' || bcWrapper.status == 'Out for Repairs' || bcWrapper.status == 'Warehouse Swap') && (bcWrapper.vcuTransaction.Transaction_Type__c == 'Warehouse Clean' || bcWrapper.vcuTransaction.Transaction_Type__c == 'Quarantine')) {
                    upsert bcWrapper.maintenanceLog;
                }
                
                if (bcWrapper.status == 'Out for Repairs' && bcWrapper.vcuTransaction.Transaction_Type__c == 'Warehouse Clean') {
                    Database.SaveResult sr3 = Database.update(bcWrapper.repairLog, false);
                } else if (bcWrapper.status == 'Warehouse Clean' && bcWrapper.vcuTransaction.Transaction_Type__c == 'Out for Repairs') {
                    Database.SaveResult sr2 = Database.insert(bcWrapper.repairLog, false);
                }
            }
        }catch (Exception ex){
            System.debug('The exception is : '+ex.getMessage()+' at line number '+ex.getLineNumber());
        }
    }
    public static VCU__c getVCUs_Apex(String vcuSerial){
        List<VCU__c> vcuList = new List<VCU__c>();
        vcuList = [SELECT Id, Name, VCU_Status__c, Facility__c, Current_Warehouse__c,
                   Current_Warehouse__r.Name, Current_Surgery__c,Reason_for_VCU_Unit_Swap__c,
                   Current_Surgery__r.Equipment_and_Supplies__c, Current_Surgery__r.Name, Current_Surgery__r.Related_Surgery__c, Last_Warehouse__c
                   FROM VCU__c
                   where Name = :vcuSerial WITH SECURITY_ENFORCED
                  ];
        if(vcuList.size() > 0){
            return vcuList[0];
        }
        return null;
    }
    //Modified by ANUJ GOEL.
        
    public static VCU__c checkPickupTransactionType(String bcWrapperJson,String vcuSerial, Id currentSurgeryId,String surgeryPatientName){
        try{
            barcodeWrapper bcWrapper = new barcodeWrapper();             
            bcWrapper.vcuObj = getVCUs_Apex(vcuSerial);
            if(currentSurgeryId == bcWrapper.vcuObj.Current_Surgery__r.Id){
                List<VCU_Transaction__c> TransactionTypeDetails = new List<VCU_Transaction__c>();      
                TransactionTypeDetails = [SELECT Created_Date__c,Surgery__r.Id,Surgery__r.Patient_Name__r.Name,Surgery__r.Name,Transaction_Type__c,Name,VCU__r.Name,CreatedDate FROM VCU_Transaction__c 
                                          WHERE VCU__r.Name = :vcuSerial AND Surgery__r.Id != :currentSurgeryId AND Surgery__r.Patient_Name__r.Name = :surgeryPatientName WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC limit 50000]; 
                if(TransactionTypeDetails.size()>0){
                    for(VCU_Transaction__c eachTransactionType : TransactionTypeDetails){                 
                        if(eachTransactionType.Transaction_Type__c == 'Assigned'){
                            Integer countPickupRecord = 0;
                            for(VCU_Transaction__c eachTransactionTypeDetail : TransactionTypeDetails){                                
                                if(eachTransactionTypeDetail.Transaction_Type__c == 'Pickup' && eachTransactionTypeDetail.CreatedDate>eachTransactionType.CreatedDate && eachTransactionTypeDetail.Surgery__c == eachTransactionType.Surgery__c){                                    
                                    bcWrapper.vcuObj.Current_Surgery__c = currentSurgeryId;
                                    countPickupRecord++;
                                    break;
                                }
                            }
                            if(countPickupRecord == 0){                                     
                                bcWrapper.vcuObj.Current_Surgery__c = eachTransactionType.Surgery__c;
                                break;
                            }
                        }                 
                    }
                    update bcWrapper.vcuObj;                    
                }
            }
                return bcWrapper.vcuObj;
        }catch(Exception ex){
            System.debug('The exception is : '+ex.getMessage()+' at line number '+ex.getLineNumber());
        }
                return null;
    }
    
    
     public static Surgery__c getRelatedSurgeryOfCurrentSurgery(Id currentSurgeryId,String patientOfCurrentSurgery){
        List<Surgery__c> relatedSurgeries = new List<Surgery__c>();
        relatedSurgeries = [SELECT id,Name,Related_Surgery__c,Related_Surgery__r.id,Type__c,Surgery_Status__c,Equipment_and_Supplies__c,Warehouse_Allocated_VCU__c,Field_Tech_that_Inserviced_Patient__c,Patient_Name__c FROM Surgery__c WHERE Related_Surgery__r.id = :currentSurgeryId AND Type__c!='Initial Surgery' AND Surgery_Status__c ='Surgery Entered' AND Equipment_and_Supplies__c = null AND Patient_Name__c = :patientOfCurrentSurgery WITH SECURITY_ENFORCED limit 50000];
        if(relatedSurgeries.size() > 0){
            return relatedSurgeries[0];
        }
        return null;
    }
    
    
    public static String getPatientRelatedSurgery(String vcuSerial,Id currentSurgeryId){
        try{            
            String temp=null;
            Surgery__c currentSurgery = [SELECT id,Patient_Name__c,Related_Surgery__c FROM Surgery__c WHERE Id = :currentSurgeryId limit 50000];
            List<Surgery__c> allSurgeries = new List<Surgery__c>();
            
            allSurgeries = [SELECT id,Patient_Name__c,Related_Surgery__c,Equipment_and_Supplies__c FROM Surgery__c WHERE id!= :currentSurgery.Id WITH SECURITY_ENFORCED LIMIT 50000];
            List<Surgery__c> oldSurgery = new List<Surgery__c>();   
            if(allSurgeries.size()>0){
                for(Surgery__c eachSurgery : allSurgeries){
                    if(eachSurgery.Patient_Name__c == currentSurgery.Patient_Name__c){
                        oldSurgery.add(eachSurgery);                             
                    }
                }
                if(oldSurgery.size()>0){
                    for(Surgery__c each: oldSurgery){
                        if(each.Equipment_and_Supplies__c == vcuSerial){                             
                            temp = 'true';
                            break;
                        }else{
                            temp = 'false';
                        }
                    }
                }else{
                    temp = 'false';
                }
            }else{
                temp = 'false';
            }
            return temp;
        }catch(Exception e){
            System.debug('Error : '+e.getMessage()+' at line : '+e.getLineNumber());
        }
        return null;
    }
    public static Surgery__c getCurrentSurgery(Id currentSurgeryId){
        Surgery__c currentSurgery = new Surgery__c();
        currentSurgery = [SELECT Id,Name, Equipment_and_Supplies__c,Patient_Name__r.Name,Related_Surgery__c,Type__c,Patient_Name__c FROM Surgery__c where Id = :currentSurgeryId WITH SECURITY_ENFORCED];
        if(currentSurgery!=null){
            return currentSurgery;
        }
        return null;
    }
    //
    public static List<picklistWrapper> getTransactionTypes(String status,String VCUUnitSwapReason,Surgery__c relatedSurgeryOfCurrentSurgery, String showAssignedTypeForRelatedPatientSur, String checkDeliveredVCU){   
        Schema.DescribeFieldResult fieldResult = VCU_Transaction__c.Transaction_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<picklistWrapper> picklistString = new List<picklistWrapper>();
        System.debug('checkDeliveredVCU >> '+checkDeliveredVCU);
        System.debug('showAssignedTypeForRelatedPatientSur >> '+showAssignedTypeForRelatedPatientSur);
        for( Schema.PicklistEntry f : ple){
            if(status == 'Warehouse Swap'){
                if(f.getLabel() == 'Warehouse Clean'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }            
            else if(status == 'Assigned' && showAssignedTypeForRelatedPatientSur == 'true' && checkDeliveredVCU == null){
                if(f.getLabel() == 'Assign to this Surgery'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Assigned' && relatedSurgeryOfCurrentSurgery == null){
                if(f.getLabel() == 'Pickup' || f.getLabel() == 'VCU Unit Swap'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Assigned' && relatedSurgeryOfCurrentSurgery != null){
                if(f.getLabel() == 'Pickup' || f.getLabel() == 'VCU Unit Swap' || f.getLabel() == 'Transfer to an additional event'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Re-Assigned' && showAssignedTypeForRelatedPatientSur == 'true' && checkDeliveredVCU == null){
                if(f.getLabel() == 'Assign to this Surgery'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Re-Assigned'){
                if(f.getLabel() == 'Pickup' || f.getLabel() == 'Re-Assigned' || f.getLabel() == 'Facility'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Pickup'  && VCUUnitSwapReason == null){
                if(f.getLabel() == 'Warehouse Clean' || f.getLabel() == 'Curbside Cleaning'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Pickup'  && VCUUnitSwapReason != null){
                if(f.getLabel() == 'Quarantine'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Warehouse Clean'){
                if(f.getLabel() == 'Allocated' || f.getLabel() == 'Assigned' || f.getLabel() == 'Warehouse Swap'
                   || f.getLabel() == 'Out for Repairs' || f.getLabel() == 'Facility' || f.getLabel() == 'Quarantine'){
                       picklistWrapper typ = new picklistWrapper();
                       typ.label = f.getLabel();
                       typ.value =  f.getValue();
                       picklistString.add(typ);
                   }
            }else if(status == 'Curbside Clean'){
                if(f.getLabel() == 'Assigned' || f.getLabel() == 'Warehouse Swap'
                   || f.getLabel() == 'Facility' || f.getLabel() == 'Allocated'){
                       picklistWrapper typ = new picklistWrapper();
                       typ.label = f.getLabel();
                       typ.value =  f.getValue();
                       picklistString.add(typ);
                   }
            }else if(status == 'Allocated'){
                if(f.getLabel() == 'Assigned' || f.getLabel() == 'Re-Assigned' || f.getLabel() == 'Facility'
                   || f.getLabel() == 'Unallocate' || f.getLabel() == 'Re-Allocated' ){
                       picklistWrapper typ = new picklistWrapper();
                       typ.label = f.getLabel();
                       typ.value =  f.getValue();
                       picklistString.add(typ);
                   }
            }else if(status == 'Re-Allocated'){
                if(f.getLabel() == 'Assigned' || f.getLabel() == 'Re-Assigned'
                   || f.getLabel() == 'Facility'|| f.getLabel() == 'Re-Allocated' ){
                       picklistWrapper typ = new picklistWrapper();
                       typ.label = f.getLabel();
                       typ.value =  f.getValue();
                       picklistString.add(typ);
                   }
            }else if(status == 'Out for Repairs'){
                if(f.getLabel() == 'Warehouse Clean'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Facility'){
                if(f.getLabel() == 'Pickup' || f.getlabel() == 'Curbside Cleaning'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == 'Quarantine'){
                if(f.getLabel() == 'Out for Repairs' || f.getlabel() == 'Warehouse Clean'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }else if(status == null){
                if(f.getLabel() == 'Pickup'){
                    picklistWrapper typ = new picklistWrapper();
                    typ.label = f.getLabel();
                    typ.value =  f.getValue();
                    picklistString.add(typ);
                }
            }
        }
        return picklistString;
    }
    
    public static List<picklistWrapper> getCoveredByWarrantyPicklist(){
        Schema.DescribeFieldResult fieldResult = Repair_Log__c.Covered_By_Warranty__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<picklistWrapper> picklistWrappers = new List<picklistWrapper>();
        for( Schema.PicklistEntry f : ple){
            picklistWrapper pcw = new picklistWrapper();
            pcw.label = f.getLabel();
            pcw.value =  f.getValue();
            picklistWrappers.add(pcw);
        }
        return picklistWrappers;
    }
    
    public static LIST<Repair_Log__c> getRepairLog(String str_code){
        LIST<Repair_Log__c> getExistingRepair = new List<Repair_Log__c>();
        getExistingRepair = [SELECT id ,CreatedDate,Repair_Return_Date__c ,Repair_Invoice_Number__c ,Repair_Invoice_Date__c ,Covered_By_Warranty__c ,Repair_Cost_Actual__c ,Repairs_Performed__c FROM Repair_Log__c  where VCU_Serial_Number__r.Name = :str_code WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
        return getExistingRepair;
    }
    public class barcodeWrapper{
        @AuraEnabled public VCU__c vcuObj {get;set;}
        @AuraEnabled public Surgery__c relatedSurgeryOfCurrentSurgery {get;set;}
        @AuraEnabled public Surgery__c currentSurgeryObject {get;set;}
        @AuraEnabled public String patientRelatedSurgery {get;set;}
        @AuraEnabled public String checkPickuptransctionType {get;set;}
        @AuraEnabled public String TransactionTypeDetails {get;set;}
        @AuraEnabled public List<picklistWrapper> transactionType {get;set;}
        @AuraEnabled public VCU_Transaction__c vcuTransaction {get;set;}
        @AuraEnabled public String status{get; set;}
        @AuraEnabled public Repair_Log__c repairLog{get; set;}
        @AuraEnabled public Maintence_Log__c  maintenanceLog {get;set;}
        @AuraEnabled public Repair_Log__c existingRepairLog {get;set;}
        @AuraEnabled public List<picklistWrapper> coveredByWarrantyPicklist {get;set;}
        
        barcodeWrapper(){
            status = '';
            vcuObj = new VCU__c();
            transactionType = new List<picklistWrapper>();
            vcuTransaction = new VCU_Transaction__c();
            repairLog = new Repair_Log__c();
            maintenanceLog = new Maintence_Log__c();
            existingRepairLog = new Repair_Log__c();
            coveredByWarrantyPicklist = new List<picklistWrapper>();
            
            maintenanceLog.Filter_Cleaned__c = false;
            maintenanceLog.Electrical_Cords__c = false;
            maintenanceLog.Clean_Tag__c = false;
            maintenanceLog.Refill_Fluid__c = false;
            maintenanceLog.Patient_Manual__c = false;
            maintenanceLog.Antimicrobial_Treatment__c = false;
            maintenanceLog.Performed_By__c = UserInfo.getUserId();
            maintenanceLog.Maintenance_Date__c = Date.today();
        }
    }
    
    public class picklistWrapper{
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
    }
}