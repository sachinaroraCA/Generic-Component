@IsTest
public class PrintChatterPageControllerTestClass {
    @testSetup
    public static void setup(){
        Patient__c currentPatient = new Patient__c();
        currentPatient.Name = 'Patient';
        
        Surgery__c surgeryObject = new Surgery__c();
        surgeryObject.Field_Technician__c = 'Test Account';
        surgeryObject.Name = 'Test surgery';
        surgeryObject.Type__c = 'Initial Surgery';
        surgeryObject.Diagnosis__c = 'Diagnosis'; 
        surgeryObject.Patient_Name__c = currentPatient.Id;
        surgeryObject.Date_of_Service__c = System.today();
        surgeryObject.Order_Script_Received__c = System.today();
        surgeryObject.Surgery_Status__c = 'Surgery Entered';
        
        if(surgeryObject!=null){
            insert surgeryObject;
        }
        
        surgeryObject.Surgery_Status__c = 'In Service Scheduled';
        update surgeryObject;
        
        FeedItem feed = new FeedItem();
        feed.Body = 'Test image src="sfdc://" image test';
        feed.ParentId = surgeryObject.Id;
        insert feed;        
        
        ContentVersion content = new ContentVersion(); 
        content.Title='Feed_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=surgeryObject.Id;
        contentlink.ContentDocumentId=[select ContentDocumentId from ContentVersion where id = :content.id].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        feed.Body = 'Test imagesrc="sfdc://'+contentlink.ContentDocumentId+'" image test'; 
        update feed;
        
        FeedComment feedComment = new FeedComment();
        feedComment.CommentBody = 'Test imagesrc="sfdc://"image test';
        feedComment.FeedItemId = feed.Id;
        insert feedComment;
        
        ContentVersion commentContent=new ContentVersion(); 
        commentContent.Title='FeedComment_Picture'; 
        commentContent.PathOnClient='/' + commentContent.Title + '.jpg'; 
        Blob commentBodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        commentContent.VersionData=commentBodyBlob; 
        commentContent.origin = 'H';
        insert commentContent;
        
        ContentDocumentLink commentContentlink=new ContentDocumentLink();
        commentContentlink.LinkedEntityId=surgeryObject.Id;
        commentContentlink.ContentDocumentId=[select ContentDocumentId from ContentVersion where id =: commentContent.id].ContentDocumentId;
        commentContentlink.ShareType = 'I';
        commentContentlink.Visibility = 'AllUsers';         
        insert commentContentlink;
        
        feedComment.CommentBody = 'Test imagesrc="sfdc://'+contentlink.ContentDocumentId+'" image test';
        update feedComment;
    }
    @isTest
    public static void PrintChatterPageControllerTest(){
        Test.startTest();
        Surgery__c currentSurgery = new Surgery__c();
        currentSurgery = [SELECT Id, Name FROM Surgery__c];
        PageReference pageRef = Page.PrintChatterPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('sobjectId',String.valueOf(currentSurgery.Id));
        PrintChatterPageController controller = new PrintChatterPageController();
        System.assertEquals('Test surgery',currentSurgery.Name);
        Test.stopTest();
    }
}