public with sharing class PrintChatterPageController {
    public String recordName {get;set;}
    public List<FeedItem> feedItemsList {get;set;}
    public Map<Id,List<FeedComment>> feedItemsVsFeedCommentsMap {get;set;}
    public Map<Id,List<Surgery__History>> feedItemsVsFeedHistoryMap {get;set;}
    public Map<Id, List<Id>> feedIdVsPublishedVersionId {get;set;}
    public Map<Id, List<Id>> feedCommentIdVsPublishedVersionId {get;set;}
    
    public PrintChatterPageController(){
        try{
            feedItemsList = new List<FeedItem>();
            feedItemsVsFeedCommentsMap = new Map<Id,List<FeedComment>>();
            feedItemsVsFeedHistoryMap = new Map<Id,List<Surgery__History>>();
            feedIdVsPublishedVersionId = new Map<Id, List<Id>>();
            feedCommentIdVsPublishedVersionId = new Map<Id, List<Id>>();
            List<FeedComment> feedCommentsList = new List<FeedComment>();
            List<Surgery__History> feedHistoryList = new List<Surgery__History>();
            Map<Id, Id> feedIdVsContentDocumentId = new Map<Id, Id>();
            Map<Id, Id> feedCommentIdVsContentDocumentId = new Map<Id, Id>();
            Map<Id, Id> contentDocumentIdVsPublishedVersionIdMap = new Map<Id, Id>();
            Map<Id, List<Id>> commentIdVsAllContentDocumentIds = new Map<Id, List<Id>>();
            Map<Id, Id> commentIdVsContentDocumentIdMap = new Map<Id, Id>();
            Set<Id> allContentDocumentIdsOfComments = new Set<Id>();
            Map<Id, List<Id>> feedIdVsAllContentDocumentIds = new Map<Id, List<Id>>();
            Map<Id, Id> feedIdVsContentDocumentIdMap = new Map<Id, Id>();
            Set<Id> allContentDocumentIdsOfFeeds = new Set<Id>();
            Set<Id> feedItemsIdSet = new Set<Id>();
            
            Id sobjectId = ApexPages.currentPage().getParameters().get('SobjectId');
            String sobjectName = String.valueOf(sobjectId.getSObjectType());
            sobjectName = sobjectName.removeEnd('c') + 'History';
            recordName = ApexPages.currentPage().getParameters().get('recordName');
            feedItemsList = [select Id, Body,CreatedDate, CreatedById,CreatedBy.Name,ParentId,HasFeedEntity,Title from FeedItem WHERE ParentId=:sobjectId WITH SECURITY_ENFORCED limit 50000];           
            
            for(FeedItem each : feedItemsList){
                feedItemsIdSet.add(each.Id);
            }
            
            feedCommentsList = [SELECT Id, CommentBody, CreatedDate, CreatedById,CreatedBy.Name, FeedItemId, ParentId FROM FeedComment WHERE ParentId = :sobjectId AND FeedItemId IN :feedItemsIdSet WITH SECURITY_ENFORCED limit 50000];             
            String sQuery = 'SELECT Id,ParentId, OldValue, NewValue,DataType, Field, CreatedById, CreatedDate FROM '+sobjectName+' where ParentId = \''+sobjectId+'\' WITH SECURITY_ENFORCED limit 50000';
            feedHistoryList = Database.query(sQuery);            
            List<String> extractedImageIdList = new List<String>();
            
            for(FeedComment eachComment : feedCommentsList){
                extractedImageIdList = new List<String>();
                extractedImageIdList.clear();
                if(feedItemsVsFeedCommentsMap.containsKey(eachComment.FeedItemId)){
                    feedItemsVsFeedCommentsMap.get(eachComment.FeedItemId).add(eachComment);
                }
                else{
                    List<FeedComment> feedCommentList = new List<FeedComment>();
                    feedCommentList.add(eachComment);
                    feedItemsVsFeedCommentsMap.put(eachComment.FeedItemId,feedCommentList);
                }
                
                if(eachComment.CommentBody != null && eachComment.CommentBody.substringBetween('src="sfdc://', '"') != null){
                    String extractedContentDocumentId = eachComment.CommentBody.substringBetween('src="sfdc://', '"');
                    String tempString = eachComment.CommentBody;
                    Integer countis = tempString.countMatches('sfdc://');
                    if(countis > 0){
                        for(Integer i=0; i<countis; i++){
                            extractedImageIdList.add(tempString.substringBetween('src="sfdc://', '"'));
                            allContentDocumentIdsOfComments.add(tempString.substringBetween('src="sfdc://', '"'));
                            Integer stringIndex = tempString.IndexOf('src="sfdc://');
                            tempString = tempString.left(stringIndex)+tempString.right(tempString.length()-stringIndex-4);
                        }
                    }
                    if(extractedImageIdList.size()>0){
                        for(Integer j=0;j<extractedImageIdList.size();j++){
                            commentIdVsAllContentDocumentIds.put(eachComment.Id,extractedImageIdList);
                            eachComment.CommentBody = eachComment.CommentBody.replace('<img'+eachComment.CommentBody.substringBetween('<img', '</img>')+'</img>', 'image');
                        }
                    }
                    
                    if(extractedContentDocumentId != null){
                        feedCommentIdVsContentDocumentId.put(eachComment.Id,extractedContentDocumentId);
                        eachComment.CommentBody = eachComment.CommentBody.replace('<img'+eachComment.CommentBody.substringBetween('<img', '</img>')+'</img>', 'image');
                    }
                }
                if(!feedCommentIdVsPublishedVersionId.containsKey(eachComment.Id)){
                    List<Id> feedCommentIdsList = new List<Id>();
                    feedCommentIdVsPublishedVersionId.put(eachComment.Id, feedCommentIdsList);
                }
            }
            
            List<String> extractedImageIdListOfFeeds = new List<String>();
            for(FeedItem eachFeedItem : feedItemsList){
                extractedImageIdListOfFeeds = new List<String>();
                extractedImageIdListOfFeeds.clear();
                if(!feedItemsVsFeedCommentsMap.containsKey(eachFeedItem.Id)){
                    List<FeedComment> feedCommentList = new List<FeedComment>();
                    feedItemsVsFeedCommentsMap.put(eachFeedItem.Id, feedCommentList);
                }
                if(eachFeedItem.Body != null && eachFeedItem.Body.substringBetween('src="sfdc://', '"') != null){
                    String extractedContentDocumentId = eachFeedItem.Body.substringBetween('src="sfdc://', '"');
                    String tempString = eachFeedItem.Body;
                    Integer countis = tempString.countMatches('sfdc://');
                    if(countis > 0){
                        for(Integer i=0; i<countis; i++){
                            extractedImageIdListOfFeeds.add(tempString.substringBetween('src="sfdc://', '"'));
                            allContentDocumentIdsOfFeeds.add(tempString.substringBetween('src="sfdc://', '"'));
                            Integer stringIndex = tempString.IndexOf('src="sfdc://');
                            tempString = tempString.left(stringIndex)+tempString.right(tempString.length()-stringIndex-4);
                        }
                    }
                    if(extractedImageIdListOfFeeds.size()>0){
                        for(Integer j=0;j<extractedImageIdListOfFeeds.size();j++){
                            feedIdVsAllContentDocumentIds.put(eachFeedItem.Id,extractedImageIdListOfFeeds);
                            eachFeedItem.Body = eachFeedItem.Body.replace('<img'+eachFeedItem.Body.substringBetween('<img', '</img>')+'</img>', 'image');
                        }
                    }
                }  
                for(Surgery__History eachFeedHistory : feedHistoryList){
                    if(eachFeedItem.CreatedDate == eachFeedHistory.CreatedDate && eachFeedHistory.OldValue!=null && eachFeedHistory.NewValue!=null){
                        if(feedItemsVsFeedHistoryMap.containsKey(eachFeedItem.Id)){
                            feedItemsVsFeedHistoryMap.get(eachFeedItem.Id).add(eachFeedHistory);
                        }else{
                            List<Surgery__History> surgeryHistoryList = new List<Surgery__History>();
                            SurgeryHistoryList.add(eachFeedHistory);
                            feedItemsVsFeedHistoryMap.put(eachFeedItem.Id,surgeryHistoryList);
                        }
                    }
                }
                if(!feedItemsVsFeedHistoryMap.containsKey(eachFeedItem.Id)){
                    List<Surgery__History> surgeryHistoryList = new List<Surgery__History>();
                    feedItemsVsFeedHistoryMap.put(eachFeedItem.Id, surgeryHistoryList);
                }
                
                if(!feedIdVsPublishedVersionId.containsKey(eachFeedItem.Id)){
                    List<Id> feedIdsList = new List<Id>();
                    feedIdVsPublishedVersionId.put(eachFeedItem.Id, feedIdsList);
                }
            }
            
            if(allContentDocumentIdsOfFeeds.size() > 0 || allContentDocumentIdsOfComments.size() > 0){
                List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
                contentDocumentLinkList = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title
                                           FROM ContentDocumentLink 
                                           WHERE ContentDocumentId IN : allContentDocumentIdsOfFeeds 
                                           OR ContentDocumentId IN : allContentDocumentIdsOfComments WITH SECURITY_ENFORCED 
                                           LIMIT 50000];
                
                for(ContentDocumentLink each : contentDocumentLinkList){
                    contentDocumentIdVsPublishedVersionIdMap.put(each.ContentDocumentId, each.ContentDocument.LatestPublishedVersionId);
                }
                
                Set<Id> feedIdAndFeedCommentIdSet = new Set<Id>();
                feedIdAndFeedCommentIdSet.addAll(feedIdVsContentDocumentId.keySet());
                feedIdAndFeedCommentIdSet.addAll(commentIdVsAllContentDocumentIds.keySet());
                
                
                for(Id key : commentIdVsAllContentDocumentIds.keySet()){
                    for(Id eachContentDocumentId : commentIdVsAllContentDocumentIds.get(key)){
                        if(contentDocumentIdVsPublishedVersionIdMap.containsKey(eachContentDocumentId)){
                            List<Id> tempIdList = feedCommentIdVsPublishedVersionId.get(key);
                            tempIdList.add(contentDocumentIdVsPublishedVersionIdMap.get(eachContentDocumentId));
                            feedCommentIdVsPublishedVersionId.put(key, tempIdList);
                        }
                        else{
                            List<Id> tempIdList = new List<Id>();
                            tempIdList.add(contentDocumentIdVsPublishedVersionIdMap.get(eachContentDocumentId));
                            feedCommentIdVsPublishedVersionId.put(key, tempIdList);
                        }
                    }
                }
                for(Id key : feedIdVsAllContentDocumentIds.keySet()){
                    for(Id eachContentDocumentId : feedIdVsAllContentDocumentIds.get(key)){
                        if(contentDocumentIdVsPublishedVersionIdMap.containsKey(eachContentDocumentId)){
                            List<Id> tempIdList = feedIdVsPublishedVersionId.get(key);
                            tempIdList.add(contentDocumentIdVsPublishedVersionIdMap.get(eachContentDocumentId));
                            feedIdVsPublishedVersionId.put(key, tempIdList);
                        }
                        else{
                            List<Id> tempIdList = new List<Id>();
                            tempIdList.add(contentDocumentIdVsPublishedVersionIdMap.get(eachContentDocumentId));
                            feedIdVsPublishedVersionId.put(key, tempIdList);
                        }
                    }
                }
            }
        }catch(exception e){
            System.debug('exception is-->'+e.getMessage()+ ' at line number-->'+e.getLineNumber()+' caused by: '+e.getCause());
        }
    }
}