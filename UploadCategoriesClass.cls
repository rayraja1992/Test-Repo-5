/**
Created by: Raja Bhandari
#####################
Modification Details: 
Name        ||      Reason      ||      Date 


#####################
**/
public class UploadCategoriesClass {
    
    
    @AuraEnabled
    public static String createGroupsAndQueue(List<String> documents){
        ContentVersion cvObj = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :documents[0] AND IsLatest = true];
        String csvAsString = cvObj.VersionData.toString();
        List<String> csvFileLines = csvAsString.split('\n');
        

        List<Group> publicQueueGroupList = new List<Group>();
        List<String> groupNameList = new List<String>();
        
        for(Integer i=1; i < csvFileLines.size(); i++){
        
            String[] csvRecordData = csvFileLines[i].split(',');
            
            if(!groupNameList.contains(csvRecordData[0])){
                groupNameList.add(csvRecordData[0]);
                
                Group groupObj = new Group(Name=csvRecordData[0] + ' Group',doesIncludeBosses=true,Type='Regular');
                publicQueueGroupList.add(groupObj);
                
                Group queueObj = new Group(Name=csvRecordData[0] + ' Queue',DoesSendEmailToMembers=true,Type='Queue');
                publicQueueGroupList.add(queueObj);
            }
            
        }
        
        if(publicQueueGroupList.size() > 0){
            insert publicQueueGroupList;
        }
        
        List<QueueSObject> QueuesObjectList = new List<QueueSObject>();
        
        for(Group queueObj : publicQueueGroupList){
            if(queueObj.Type == 'Queue'){
                QueueSObject queuesSObjectObj = new QueueSObject(QueueID = queueObj.id, SObjectType = 'Case');
                QueuesObjectList.add(queuesSObjectObj);
            }
        }
        
        if(QueuesObjectList.size() > 0){
            //insert QueuesObjectList;
            return 'SUCCESS DONE';
        }
        
        return 'FAILURE';

    }
    
    @AuraEnabled
    public static String createBusinessProcess(List<String> documents, String accessToken){
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = accessToken;
        
        MetadataService.AllOrNoneHeader_element allOrNoneHeaderObj = new MetadataService.AllOrNoneHeader_element();
        allOrNoneHeaderObj.allOrNone = true;
        service.AllOrNoneHeader  = allOrNoneHeaderObj;
        
        List<MetadataService.Metadata> businessProcessaList = new List<MetadataService.Metadata>();
        
        ContentVersion cvObj = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :documents[0] AND IsLatest = true];
        String csvAsString = cvObj.VersionData.toString();
        List<String> csvFileLines = csvAsString.split('\n');
        
        for(Integer i=1; i < csvFileLines.size(); i++){
            String[] csvRecordData = csvFileLines[i].split(',');
            String caseCategory = csvRecordData[0].stripHtmlTags();
            MetadataService.BusinessProcess businessProcessaObj = new MetadataService.BusinessProcess();
            businessProcessaObj.fullName = caseCategory + ' Support Process';
            businessProcessaObj.description = caseCategory + ' Support Process';
            businessProcessaObj.isActive = true;
            businessProcessaList.add(businessProcessaObj);
        }
        
        //service.createMetadata(businessProcessaList);
        
        return 'SUCCESS DONE';

    }
    @AuraEnabled
    public static String createCaseCateToCaseTypeFieldDepend(List<String> documents, String accessToken){
            
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = accessToken;
        
        MetadataService.AllOrNoneHeader_element allOrNoneHeaderObj = new MetadataService.AllOrNoneHeader_element();
        allOrNoneHeaderObj.allOrNone = true;
        service.AllOrNoneHeader  = allOrNoneHeaderObj;
        
        MetadataService.CustomField customField = (MetadataService.CustomField) service.readMetadata('CustomField', new String[] { 'Case.Case_Type__c' }).getRecords()[0];
        
        List<MetadataService.ValueSettings> ValueSettingsList = new List<MetadataService.ValueSettings>();
        
        Map<String,List<String>> valuesToControllingMap = new Map<String,List<String>>();
                
        ContentVersion cvObj = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :documents[0] AND IsLatest = true];
        String csvAsString = cvObj.VersionData.toString();
        List<String> csvFileLines = csvAsString.split('\n');
        
        for(Integer i=1; i < csvFileLines.size(); i++){
            String[] csvRecordData = csvFileLines[i].split(',');
            String caseCategory = csvRecordData[0].stripHtmlTags();
            String caseType = csvRecordData[1].stripHtmlTags();
             
            if(!valuesToControllingMap.containsKey(caseType)){
                valuesToControllingMap.put(caseType,new List<String>{caseCategory});
            }else{
                List<String> myStringKeys = valuesToControllingMap.get(caseType);
                if(!myStringKeys.contains(caseCategory)){
                    valuesToControllingMap.get(caseType).add(caseCategory);
                }
            }
        }
        system.debug('valuesToControllingMap >'+valuesToControllingMap);
        
        for(String values : valuesToControllingMap.keyset()){
            MetadataService.ValueSettings valueSettingObject = new MetadataService.ValueSettings();
            valueSettingObject.controllingFieldValue = valuesToControllingMap.get(values);
            valueSettingObject.valueName = values;
            ValueSettingsList.add(valueSettingObject);
        }
        system.debug('ValueSettingsList >'+ValueSettingsList);
        
        customField.valueSet.valueSettings = ValueSettingsList;
        
        service.updateMetadata(new MetadataService.Metadata[] { customField });
        
        MetadataService.SaveResult[] results =  service.updateMetadata(new MetadataService.Metadata[] { customField });
        for (MetadataService.SaveResult r : results) {
            if (r.success) {
                system.debug('Updated component: ' + r.fullName);
            } else {
                
                for (MetadataService.Error error   : r.errors) {
                    system.debug('Errors were encountered while updating >'+ r.fullName);
                    system.debug('Error message: ' + error.message);
                    system.debug('Status code: ' + error.statusCode );
                }
            }
        }
        

    }
    
    
    @AuraEnabled
    public static String createTypeToSubTypeFieldDepend(List<String> documents, String accessToken){
            
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = accessToken;
        
        MetadataService.AllOrNoneHeader_element allOrNoneHeaderObj = new MetadataService.AllOrNoneHeader_element();
        allOrNoneHeaderObj.allOrNone = true;
        service.AllOrNoneHeader  = allOrNoneHeaderObj;
        
        MetadataService.CustomField customField = (MetadataService.CustomField) service.readMetadata('CustomField', new String[] { 'Case.Case_Subcategory__c' }).getRecords()[0];
        
        List<MetadataService.ValueSettings> ValueSettingsList = new List<MetadataService.ValueSettings>();
        
        Map<String,List<String>> valuesToControllingMap = new Map<String,List<String>>();
                
        ContentVersion cvObj = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :documents[0] AND IsLatest = true];
        String csvAsString = cvObj.VersionData.toString();
        List<String> csvFileLines = csvAsString.split('\n');
        
        for(Integer i=1; i < csvFileLines.size(); i++){
            String[] csvRecordData = csvFileLines[i].split(',');
            String caseType = csvRecordData[1].stripHtmlTags();
            String caseSubType = csvRecordData[2].stripHtmlTags();
            
            if(caseSubType == 'Unassigned'){
                continue;
            }else{
                
                if(!valuesToControllingMap.containsKey(caseSubType)){
                    valuesToControllingMap.put(caseSubType,new List<String>{caseType});
                }else{
                    List<String> myStringKeys = valuesToControllingMap.get(caseSubType);
                    if(!myStringKeys.contains(caseType)){
                        valuesToControllingMap.get(caseSubType).add(caseType);
                    }
                }
            }
        }
        
        system.debug('>>>'+valuesToControllingMap);
        for(String values : valuesToControllingMap.keyset()){
            MetadataService.ValueSettings valueSettingObject = new MetadataService.ValueSettings();
            valueSettingObject.controllingFieldValue = valuesToControllingMap.get(values);
            valueSettingObject.valueName = values;
            ValueSettingsList.add(valueSettingObject);
        }
        
        system.debug('ValueSettingsList>>>'+ValueSettingsList);
        customField.valueSet.valueSettings = ValueSettingsList;
        
        MetadataService.SaveResult[] results =  service.updateMetadata(new MetadataService.Metadata[] { customField });
        for (MetadataService.SaveResult r : results) {
            if (r.success) {
                system.debug('Updated component: ' + r.fullName);
            } else {
                
                for (MetadataService.Error error   : r.errors) {
                    system.debug('Errors were encountered while updating >'+ r.fullName);
                    system.debug('Error message: ' + error.message);
                    system.debug('Status code: ' + error.statusCode );
                }
            }
        }
        
        return 'SUCCESS DONE';
    }
    
    
    /**
    Description: Get the access token of current org
    **/
    @AuraEnabled
    public Static String getCurrentSFAccessToken(){
        Map<String,Object> responseTokenMap = new Map<String,Object>();
        Authentication_Credential__mdt authencationHeader = [Select Id,
                                                             Access_Token_URL__c,
                                                             Client_Id__c,
                                                             Client_Secret__c,
                                                             Grant_Type__c,
                                                             Method__c,
                                                             Query_Params__c,
                                                             UserName__c,
                                                             Password__c  
                                                             From Authentication_Credential__mdt
                                                             Where DeveloperName =: Label.Organization_Type+'_Current_Salesforce_Auth' 
                                                             limit 1];
             
        Http httpObj = new Http();
        HttpRequest httpReqObj = new HttpRequest();
        httpReqObj.setMethod(authencationHeader.Method__c);
        String endPoint = '';
        String accessTokenURL = '';
        String clientId = '';
        String clientSecret = '';
        String grantType = '';
        String username = '';
        String password = '';
        
        if(!String.isBlank(authencationHeader.Access_Token_URL__c)){
            accessTokenURL = authencationHeader.Access_Token_URL__c;
        }
        if(!String.isBlank(authencationHeader.Client_Id__c)){
            clientId = authencationHeader.Client_Id__c;
        }
        if(!String.isBlank(authencationHeader.Client_Secret__c)){
            clientSecret = authencationHeader.Client_Secret__c;
        }
        if(!String.isBlank(authencationHeader.Grant_Type__c)){
            grantType = authencationHeader.Grant_Type__c;
        }
        if(!String.isBlank(authencationHeader.UserName__c)){
            username = authencationHeader.UserName__c;
        }
        if(!String.isBlank(authencationHeader.Password__c)){
            password = authencationHeader.Password__c;
        }
        
        endPoint = accessTokenURL;
        httpReqObj.setEndpoint(accessTokenURL);
        httpReqObj.setBody('grant_type='+grantType+'&client_id='+clientId+'&client_secret='+clientSecret+'&username='+username+'&password='+password);
        httpReqObj.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        httpReqObj.setTimeout(120000);
        HttpResponse  httpResponseObj = httpObj.send(httpReqObj);
        responseTokenMap.put('Endpoint',httpReqObj.getEndpoint());
        responseTokenMap.put('WebService','CSC_Current_Salesforce_Org');
        responseTokenMap.put('Method','UploadCategoriesClass.getCurrentSFAccessToken');
        responseTokenMap.put('Operation',authencationHeader.Method__c);

        if(httpResponseObj.getStatusCode() == 200 && !String.isBlank(httpResponseObj.getBody())){
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(httpResponseObj.getBody());

            system.debug('getAccessToken > Access Token Map > '+responseMap);

            responseTokenMap.put('Status','SUCCESS');
            responseTokenMap.put('Description','The access token has been fetched successfully!');
            responseTokenMap.put('StatusCode',Integer.valueOf(httpResponseObj.getStatusCode()));
            responseTokenMap.put('Request',httpReqObj.getBody());
            responseTokenMap.put('Response',httpResponseObj.getBody());

            createAPILog(responseTokenMap);
            
            return (String) responseMap.get('access_token');
        }
        else{   
            responseTokenMap.put('Status','FAILED');
            responseTokenMap.put('Description','The access token has NOT been fetched successfully!');
            responseTokenMap.put('Request',httpReqObj.getBody());
            responseTokenMap.put('Response',httpResponseObj.getBody());
            responseTokenMap.put('StatusCode',Integer.valueOf(httpResponseObj.getStatusCode()));

            createAPILog(responseTokenMap);
        }  
        
        return null;
    }
    
    /**
    * @Description To log in API Logger object
    */
    public static void createAPILog(Map<String,Object> responseMap){
        
        APILogger.API_InfoWrapper apiErrorInfoObj = new APILogger.API_InfoWrapper();
        
        apiErrorInfoObj.description = (String)responseMap.get('Description');
        apiErrorInfoObj.endPointURL = (String)responseMap.get('Endpoint');
        apiErrorInfoObj.integrationType = 'REST';
        apiErrorInfoObj.methodName = (String)responseMap.get('Method');
        apiErrorInfoObj.sourceSystem = 'Salesforce';
        apiErrorInfoObj.targetSystem = 'Salesforce'; 
        apiErrorInfoObj.status = (String)responseMap.get('Status'); 
        apiErrorInfoObj.webServiceName = (String)responseMap.get('WebService');
        apiErrorInfoObj.operation = (String)responseMap.get('Operation');
        apiErrorInfoObj.statusCode = (Integer)responseMap.get('StatusCode');
        
        String bodyStr = 'Output : \n \n';
        if(String.isNotBlank(apiErrorInfoObj.endPointURL)){
            bodyStr = 'ENDPOINT: '+ apiErrorInfoObj.endPointURL + '\n \n \n \n';
        }
        if(String.isNotBlank((String)responseMap.get('Request'))){
            bodyStr = bodyStr + 'REQUEST: '+ (String)responseMap.get('Request') + ' \n \n \n \n';
        }
        if(String.isNotBlank((String)responseMap.get('Response'))){
            bodyStr = bodyStr + 'RESPONSE: '+ (String)responseMap.get('Response') + ' \n \n \n \n';
        }
        apiErrorInfoObj.reqAndResStr = bodyStr;
        
        APILogger.createAPIRecord(apiErrorInfoObj);
    }
     
}
