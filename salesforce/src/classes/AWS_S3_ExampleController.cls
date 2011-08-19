/*
Copyright (c) 2008 salesforce.com, inc.
All rights reserved.
  
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


/*
   This Apex Class is used as a custom Visualforce controller and provides many examples of 
   how to use the Force Toolkit for Amazon Web Services (specifically the S3.cls apex class)
   
   The AWS_S3_Examples.page Visualforce page uses this controller so please reference that Visualforce page code for more information. 
   
      
   
*/
public class AWS_S3_ExampleController { 

    private String AWSCredentialName = 'DF11 Preso Account'; //Modify this string variable to be the name of the AWS Credential record that contains the proper AWS keys and secret
    public String bucketNameToCreate {get;set;}
    public String bucketNameToDelete {get;set;} 
    public String bucketSelected {get;set;}
    public String bucketToList {get;set;}
    public String bucketToUploadObject {get;set;}
    public S3.ListEntry[] bucketList {get;set;}    
    public String bucketNameForCreate {get;set;}
    public String bucketNameForDelete {get;set;}
    public S3.ListAllMyBucketsEntry[] allBucketList {get;set;}
    public String accessTypeSelected {get;set;}
    public String bucketNameToModifyAccess {get;set;}
    public String OwnerId {get;set;}
    public Boolean renderListBucketResults {get;set;}
    public String listBucketErrorMsg {get;set;}
    public String createBucketErrorMsg {get;set;}
    public String deleteBucketErrorMsg {get;set;}
    public String deleteObjectErrorMsg {get;set;}
    public String uploadObjectErrorMsg {get;set;}
    public String uploadObjectErrorMsg2 {get;set;}
    public String objectToDelete {get;set;}
    public String folderIdSelected {get;set;}
    public String bucketSelectToUploadForceDoc {get;set;}
    public String docToUploadName {get;set;}
    public String docToUploadId {get;set;}
    public Blob fileBlob {get;set;}
    public Integer fileSize {get;set;}
    public String fileName {get;set;}
    
    
	/* Constructor
	   Sets the AWS key and secret
	*/
	public AWS_S3_ExampleController() {
		
		
    }
    
     
    /*
       This method is called when the AWS_S3_Examples Visualforce page is loaded. It verifies that the AWS Keys can be found
       in the AWSKeys__c custom object by the specified name, as set in the string variable AWSCredentialsName. 
       
       Any errors are added to the ApexPage and displayed in the Visualforce page. 
    */
    public PageReference constructor(){
    	try{
			
			AWSKeys credentials = new AWSKeys(AWSCredentialName);
			as3 = new S3.AmazonS3(credentials.key,credentials.secret);
			//as3.secret = credentials.secret;
			//as3.key = credentials.key;
			S3Key= credentials.key;
			renderListBucketResults = false;
			listBucketErrorMsg =null;
			createBucketErrorMsg=null;
			deleteBucketErrorMsg=null;
		
		}catch(AWSKeys.AWSKeysException AWSEx){
		     System.debug('Caught exception in AWS_S3_ExampleController: ' + AWSEx);
		     ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, AWSEx.getMessage());
			 ApexPages.addMessage(errorMsg);
			 //throw new AWSKeys.AWSKeysException(AWSEx);
		  	 //ApexPages.addMessage(AWSEx);    
		}
		
		
		
    
       return null;	
    }
    
    public String S3Key {get;set;}
    
	public S3.AmazonS3 as3 { get; private set; } //This object represents an instance of the Amazon S3 toolkit and makes all the Web Service calls to AWS. 
	
	
	public S3.ListBucketResult listbucket {get;set;}
	public String selectedBucket {get;set;}
	
	
	//Method to return a string array for all the buckets in your AWS S3 account
	public String[] allBuckets { get {
		try{
	    
		Datetime now = Datetime.now();
		
		//This performs the Web Service call to Amazon S3 and retrieves all the Buckets in your AWS Account. 
		S3.ListAllMyBucketsResult allBuckets = as3.ListAllMyBuckets(as3.key,now,as3.signature('ListAllMyBuckets',now));
		
		
		//Store the Canonical User Id for your account
		OwnerId = allBuckets.Owner.Id;
		System.debug('============== OwnerId ' + OwnerId);
		
		S3.ListAllMyBucketsList bucketList = allBuckets.Buckets;
		S3.ListAllMyBucketsEntry[] buckets = bucketList.Bucket;
		allBucketList = buckets;
		
		String[] bucketNames = new String[]{};
		
		
		//Loop through each bucket entry to get the bucket name and store in string array. 
		for(S3.ListAllMyBucketsEntry bucket: buckets){
			 System.debug('Found bucket with name: ' + bucket.Name);
			 
			 bucketNames.add(bucket.name);
			
		}
		
    	return bucketNames;
    	
		}catch (System.NullPointerException e) {
		   return null;
		}catch(Exception ex){
		   //System.debug(ex);
		   System.debug('caught exception in listallmybuckets');
		   ApexPages.addMessages(ex);
		   return null;	
		}
        
		}//end getter
		set;
	 }
	 
	 
	 //This is used by the sample Visualforce page to display a list of all folders in the org
	 public List<SelectOption> getFolders(){
	    List<SelectOption> options = new List<SelectOption>();
	    try{
		    Folder[] folders = [select id, name from Folder where Type='Document'];
	   	 	for(Folder f: folders){
	   	 	   System.debug('folder id['+f.id+'] name['+ f.name +']');
	   	 	   options.add(new SelectOption(f.id,f.name));	
	   	 	}
	   	 	return options;
	    }catch(Exception ex){
	       return null;	
	    }
	 }
	 
	 public List<Document> docs {get {
	   
	     if(folderIdSelected!=null){
		     List<Document> results = [select id, name from Document where FolderId = :folderIdSelected];
		     return results;	
	 	 }else
	 	   return null;
	 	
	 }
	 }
	 
	 
	 //This is used by the sample Visualforce page to display a list of access control options to the user
	 public List<SelectOption> getAccessTypes(){
	    List<SelectOption> options = new List<SelectOption>();
   	 	options.add(new SelectOption('private','private'));
   	 	options.add(new SelectOption('public-read','public-read'));	
   	 	options.add(new SelectOption('public-write','public-write'));
   	 	//options.add(new SelectOption('authenticated-read','authenticated-read'));
   	 	return options;
	 }
	 
	 
	 //This is used by the sample Visualforce page to display the list of all buckets created in your AWS account. 
	 public List<SelectOption> getBucketNames() {
   	 	List<SelectOption> options = new List<SelectOption>();
   	 	
   	 	String[] bckts = allBuckets;
   	 	if(bckts!=null){
	   	 	for(String bucket : allBuckets){
	   	 	   options.add(new SelectOption(bucket,bucket));	
	   	 	}
	   	 	return options;
   	 	}
   	 	else
   	 	  return null;
     }
	 
	
	/*
	   Method to create a bucket on AWS S3 
	
	*/
	public PageReference createBucket(){
	  try{	 
	  	   createBucketErrorMsg= null;
		   Datetime now = Datetime.now();        
		   System.debug('about to create S3 bucket called: ' + bucketNameToCreate);
		   
		   
		   //This performs the Web Service call to Amazon S3 and create a new bucket.
	       S3.CreateBucketResult createBucketReslt = as3.CreateBucket(bucketNameToCreate,null,as3.key,now,as3.signature('CreateBucket',now));
	       System.debug('Successfully created a Bucket with Name: ' + createBucketReslt.BucketName);
	       createBucketErrorMsg='Success';
	       return null;
       }
       catch(System.CalloutException callout){
		  System.debug('CALLOUT EXCEPTION: ' + callout);
		  ApexPages.addMessages(callout);
		  createBucketErrorMsg = callout.getMessage();
		  return null;	
	   }
       catch(Exception ex){
		   System.debug(ex);
		   ApexPages.addMessages(ex);
		   createBucketErrorMsg = ex.getMessage();
		   return null;	
	   }
       
	}
	
	
	/*
	   Method to delete a bucket on AWS S3 
	
	*/
	public PageReference deleteBucket(){
	  try{	 
	  	   deleteBucketErrorMsg= null;
		   Datetime now = Datetime.now();        
		   System.debug('about to delete S3 bucket called: ' + bucketNameToDelete);
		   
		   
		   //This performs the Web Service call to Amazon S3 and create a new bucket.
	       S3.Status deleteBucketReslt = as3.DeleteBucket(bucketNameToDelete,as3.key,now,as3.signature('DeleteBucket',now), as3.secret);
	       deleteBucketErrorMsg = deleteBucketReslt.Description;
	       		
	       System.debug('Successfully deleted a Bucket: ' + deleteBucketReslt.Description);
	       return null;
       }
       catch(System.CalloutException callout){
		  System.debug('CALLOUT EXCEPTION: ' + callout);
		  ApexPages.addMessages(callout);
		  deleteBucketErrorMsg = callout.getMessage();
		  return null;	
	   }
       catch(Exception ex){
		   System.debug(ex);
		   ApexPages.addMessages(ex);
		   deleteBucketErrorMsg = ex.getMessage();
		   return null;	
	   }
       
	}
	
	
	/*
	   Method to create an object on AWS S3 
	
	*/
	public PageReference deleteObject(){
		try{
		   deleteObjectErrorMsg= null;
		   Datetime now = Datetime.now();        
		   
		   objectToDelete = ApexPages.currentPage().getParameters().get('keyToDelete');
		   System.debug('about to delete S3 object with key: ' + objectToDelete);
		   //This performs the Web Service call to Amazon S3 and create a new bucket.
	       S3.Status deleteObjectReslt= as3.DeleteObject(bucketToList,objectToDelete,as3.key,now,as3.signature('DeleteObject',now), as3.secret);
	       deleteObjectErrorMsg = 'Success';
	       		
	       System.debug('Successfully deleted a Bucket: ' + deleteObjectReslt.Description);
	       return null;
       } catch(System.CalloutException callout){
		  System.debug('CALLOUT EXCEPTION: ' + callout);
		  ApexPages.addMessages(callout);
		  deleteObjectErrorMsg = callout.getMessage();
		  return null;	
	   }
       catch(Exception ex){
		   System.debug(ex);
		   ApexPages.addMessages(ex);
		   deleteObjectErrorMsg = ex.getMessage();
		   return null;	
	   }
	 	
	}
	
	
	/*
	   Method to list a bucket on AWS S3 
	
	*/
	public PageReference listBucket(){
		try{
			listBucketErrorMsg=  null;
		    Datetime now = Datetime.now();
			Integer maxNumberToList = 25; //Set the number of Objects to return for a specific Bucket
			String Prefix = null; //Limits the response to keys that begin with the indicated prefix. You can use prefixes to separate a bucket into different sets of keys in a way similar to how a file system uses folders. This is an optional argument.
			String Marker = null; //Indicates where in the bucket to begin listing. The list includes only keys that occur alphabetically after marker. This is convenient for pagination: To get the next page of results use the last key of the current page as the marker. The most keys you'd like to see in the response body. The server might return less than this number of keys, but will not return more. This is an optional argument.
			String Delimiter = null; //Causes keys that contain the same string between the prefix and the first occurrence of the delimiter to be rolled up into a single result element in the CommonPrefixes collection. These rolled-up keys are not returned elsewhere in the response. 
			
			System.debug('Going to execute S3 ListBucket service for bucket: ' + bucketToList);
			
			//This performs the Web Service call to Amazon S3 and retrieves all the objects in the specified bucket
			S3.ListBucketResult objectsForBucket = as3.ListBucket(bucketToList, Prefix, Marker,maxNumberToList, Delimiter,as3.key,now,as3.signature('ListBucket',now),as3.secret);
	        bucketList = objectsForBucket.Contents;
	    
		    return null;
		}catch(System.CalloutException callout){
		  System.debug('CALLOUT EXCEPTION: ' + callout);
		  ApexPages.addMessages(callout);
		  listBucketErrorMsg = 	callout.getMessage();
		  return null; 	
	    }catch(Exception ex){
		    System.debug('EXCEPTION: ' + ex);
		    listBucketErrorMsg = 	ex.getMessage();
		    ApexPages.addMessages(ex);
		    return null;	
		}
	}
	
	
	
	public PageReference updateBucketToUpload(){
	    policy = getPolicy();
	    System.debug('tempPolicy: ' + tempPolicy);
	    return null;	
	}
	
	public PageReference updateAccessTypeSelected(){
	   //policy=getPolicy();
	   //System.debug('tempPolicy: ' + tempPolicy);
	   return null;	
	}
	
	public PageReference updateFolderId(){
		return null;
	}	
	
			
	/*
	    This method uploads a file from the filesystem and puts it in S3. 
	    It also supports setting the Access Control policy. 
	*/
	public pageReference syncFilesystemDoc(){
		try{  
		  Datetime now = Datetime.now();
		  
		  String docBody = EncodingUtil.base64Encode(fileBlob);
		  
		  //TODO - make sure doc.bodyLength is not greater than 100000 to avoid apex limits
		  System.debug('body length: ' + fileSize);
		  uploadObjectErrorMsg = 'Error';
		  Boolean putObjResult = as3.PutObjectInline_ACL(bucketToUploadObject,fileName,null,docBody,fileSize,accessTypeSelected,as3.key,now,as3.signature('PutObjectInline',now),as3.secret, OwnerId);
		  if(putObjResult==true){
		  	  System.debug('putobjectinline successful');
		  	  uploadObjectErrorMsg = 'Success';
		  }
		  
	  
	  	}catch(System.CalloutException callout){
		  System.debug('CALLOUT EXCEPTION: ' + callout);
		  uploadObjectErrorMsg = 	callout.getMessage();
 	
	    }catch(Exception ex){
		    System.debug('EXCEPTION: ' + ex);
		    uploadObjectErrorMsg = 	ex.getMessage();
		}
	   
	  return null;	
	}
	
	/*
	    This method uploads a file from the Document object in Force.com and puts it in S3. 
	    It also supports setting the Access Control policy. 
	*/
	public pageReference syncForceDoc(){
		try{  
		  Datetime now = Datetime.now();
		  
		  docToUploadId = ApexPages.currentPage().getParameters().get('docIdToUpload');
		  Document doc= [select id, body, bodyLength , name from Document where id = :docToUploadId];
		  String docBody = EncodingUtil.base64Encode(doc.body);
		  
		  //TODO - make sure doc.bodyLength is not greater than 100000 to avoid apex limits 
		  System.debug('body length: ' + doc.bodyLength);
		  
		  /*
		   
		  NOTE: This is purposely commented out. But it shows a valid example of how to construct metadata entries
		  
		  S3.MetadataEntry[] metadataentries = new S3.MetadataEntry[]{};
		  S3.MetadataEntry entry = new S3.MetadataEntry();
		  entry.Name='sampleName';
		  entry.Value='sampleValue';
		  metadataentries.add(entry);
		  */
		  
		  uploadObjectErrorMsg2 = 'Error';
		  Boolean putObjResult = as3.PutObjectInline_ACL(bucketToUploadObject,doc.name,null,docBody,doc.bodyLength,accessTypeSelected,as3.key,now,as3.signature('PutObjectInline',now),as3.secret, OwnerId);
		  if(putObjResult==true){
		  	  System.debug('putobjectinline successful');
		  	  uploadObjectErrorMsg2 = 'Success';
		  }
		  
	  
	  	}catch(System.CalloutException callout){
		  System.debug('CALLOUT EXCEPTION: ' + callout);
		  uploadObjectErrorMsg2 = 	callout.getMessage();

	    }catch(Exception ex){
		    System.debug('EXCEPTION: ' + ex);
		    uploadObjectErrorMsg2 = 	ex.getMessage();
		    
		}
	   
	  return null;	
	}
	
	
	public pageReference redirectToS3Key() {
        
        
        //get the filename in urlencoded format
        String filename = EncodingUtil.urlEncode(ApexPages.currentPage().getParameters().get('filename'), 'UTF-8');
        //String bucket = EncodingUtil.urlEncode(ApexPages.currentPage().getParameters().get('bucket'), 'UTF-8');
        System.debug('redirectToS3Key filename: ' + filename);
        Datetime now = DateTime.now();
        Datetime expireson = now.AddSeconds(120);
        Long Lexpires = expireson.getTime()/1000;
        
        System.debug('key: ' + as3.key);
        System.debug('secret: ' + as3.secret);
        //String codedFilename=  EncodingUtil.urlEncode(filename,'UTF-8');
       // System.debug('codedFilename: '+codedFilename); 
        String stringtosign = 'GET\n\n\n'+Lexpires+'\n/'+bucketToList+'/'+filename;
        System.debug('redirectToS3Key stringstosign: ' + stringtosign);
        String signed = make_sig(stringtosign);
        System.debug('signed: ' + signed);
        String codedsigned = EncodingUtil.urlEncode(signed,'UTF-8');
        System.debug('codedsigned: ' + codedsigned);
        String url = 'http://'+bucketToList+'.s3.amazonaws.com/'+filename+'?AWSAccessKeyId='+as3.key+'&Expires='+Lexpires+'&Signature='+signed;
        System.debug('url: ' + url);
        PageReference newPage = new PageReference(url);
        System.debug('newPage url: ' + newPage.getUrl());
        return newPage;
        
    }
	
	
	/*
	   --------------------------------------------------------------------------------
	   This section of Apex Code below are for the HTML FORM POST to upload a large file. 
	
	*/
	
	public String policy = '{ "expiration": "2008-12-12T12:00:00.000Z","conditions": [  {"acl": "'+accessTypeSelected+'" },{"bucket": "'+bucketToUploadObject+'" }, ["starts-with", "$key", ""] ]}';
	//public String policy = '';
	
	public string tempPolicy { get ; set; }
	
	public String getPolicy() {
		String temp= '{ "expiration": "2008-12-12T12:00:00.000Z","conditions": [ ';
		temp+='{"bucket": "' + bucketToUploadObject + '" },';
		temp+=' ["starts-with", "$key", ""],';
		temp +='  {"acl": "'+accessTypeSelected+'" }';
		temp+=']}';
		tempPolicy = temp;
		policy=temp;
		System.debug('inside getPolicy...:' + policy);
        return EncodingUtil.base64Encode(Blob.valueOf(policy));
    }
    
    
    public String getSignedPolicy() {    
        return make_sig(EncodingUtil.base64Encode(Blob.valueOf(policy)));        
    }
    
    //just to run some test with amazon's signature's tester
    public String getHexPolicy() {
        String p = getPolicy();
        return EncodingUtil.convertToHex(Blob.valueOf(p));
    }
    

    //method that will sign
    private String make_sig(string canonicalBuffer) {        
        String macUrl ;
        String signingKey = EncodingUtil.base64Encode(Blob.valueOf(as3.secret));
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(canonicalBuffer),blob.valueof(as3.secret)); 
        macUrl = EncodingUtil.base64Encode(mac);                
        return macUrl;
    }
    
    
     private String createTestCredentials(){
       
        AWSKey__c testKey = new AWSKey__c(name='test keys',key__c='key',secret__c='secret');
        insert testKey;
        return testKey.name;
         
     } 
     
	 public static testmethod void test1() {
	 	    
	 	    AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.getPolicy(); 
	 		system.assert( c.allBuckets == null );
	 		
	 		c.AWSCredentialName = 'does not exist';
	 		c.constructor();
	 		
	 }
	
	 public static testmethod void test2() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
			String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
			try{
				system.debug ( c.getFolders() );
				//system.assert( c.docs != null );
				system.debug ( c.getAccessTypes() );
			}catch(Exception ex){
			}
			//c.allbuckets = new string[]{'f','b'};
			//system.debug( c.allBuckets );
			//c.getBucketNames();
			
			
	 }
	 public static testmethod void test3() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.createBucket();
	 }
	 public static testmethod void test4() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.deleteBucket();
	 }
	 public static testmethod void test5() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.deleteObject();
	 }
	 public static testmethod void test6() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.listBucket();
	 }
	 public static testmethod void test7() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		
	 		try{
	 			c.make_sig( 'foo');
	 		}catch(Exception ex){
			}
	 		//c.redirectToS3Key();
	 }
	 
	 public static testmethod void test8() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		try{
	 			c.getHexPolicy( );
	 			c.getSignedPolicy();
	 		}catch(Exception ex){
			}
	 }
	 
	  public static testmethod void test9() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		try 	{c.getBucketNames( );
	 		} catch(exception ee ) { 
	 		}
	 }
	 
	 public static testmethod void test10() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		try{
	 			c.syncForceDoc();
	 		}catch(Exception ex){
			}
	 }
	 public static testmethod void test11() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.updateBucketToUpload();
	 }
	 public static testmethod void test12() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.updateFolderId();
	 }
	 public static testmethod void test13() {
	 	AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 	String credName = c.createTestCredentials();
	 	c.AWSCredentialName = credName;
	 	c.constructor();
	 	PageReference pageRef = Page.AWS_S3_Examples;
	 	
        pageRef.getParameters().put('filename','foo');
        Test.setCurrentPage(pageRef);
        c.bucketToList='testBucket';
	 	try{
	 		c.redirectToS3Key();
	 	}catch(Exception ex){
			}
	 	
	 }
	 
	public static testmethod void test14() {
	 		AWS_S3_ExampleController c = new AWS_S3_ExampleController();
	 		String credName = c.createTestCredentials();
	 		c.AWSCredentialName = credName;
	 		c.constructor();
	 		c.updateAccessTypeSelected();
	 		try{
	 			c.syncFilesystemDoc();
	 		}catch(Exception ex){
			}
	 }	 
}