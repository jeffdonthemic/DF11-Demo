public class S3FormController {
	
 	public AWSKeys credentials {get;set;} 
 	private String AWSCredentialName = 'DF11 Preso Account'; //Modify this string variable to be the name of the AWS Credential record that contains the proper AWS keys and secret
 	public string secret { get {return credentials.secret;} }
	public string key { get {return credentials.key;} }
	
	public AWS_S3_Object__c record; //  { get { return (AWS_S3_Object__c)con.getRecord(); }}
	public S3.AmazonS3 as3 { get; private set; }
 	public String serverURL {get;set;}
 	
 	ApexPages.StandardController con;
 	public S3FormController(ApexPages.StandardController stdController) {
        this.con = stdController;
        system.debug( con.getRecord() );
		try { 
		this.record = [select id,bucket_name__c,content_type__c, file_name__c, access__c from AWS_S3_Object__c where id = :con.getRecord().id limit 1];
		} catch( Exception ee) { 
			this.record = new 	AWS_S3_Object__c(); 
		}
		//as3 = new S3.AmazonS3(credentials.key,credentials.secret);
    }
    
    
     /*
       This method is called when the news3object Visualforce page is loaded. It verifies that the AWS Keys can be found
       in the AWSKeys__c custom object by the specified name, as set in the string variable AWSCredentialsName. 
       
       Any errors are added to the ApexPage and displayed in the Visualforce page. 
    */
    public PageReference constructor(){
    	try{
			
			credentials = new AWSKeys(AWSCredentialName);
			as3 = new S3.AmazonS3(credentials.key,credentials.secret);
		
		}catch(AWSKeys.AWSKeysException AWSEx){
		     System.debug('Caught exception in AWS_S3_ExampleController: ' + AWSEx);
		     ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, AWSEx.getMessage());
			 ApexPages.addMessage(errorMsg);
			 //throw new AWSKeys.AWSKeysException(AWSEx);
		  	 //ApexPages.addMessage(AWSEx);    
		}	
    
       return null;	
    }
    

	datetime expire = system.now().addDays(1);
	String formattedexpire = expire.formatGmt('yyyy-MM-dd')+'T'+
		expire.formatGmt('HH:mm:ss')+'.'+expire.formatGMT('SSS')+'Z';           
	      
	string policy { get {return 
		'{ "expiration": "'+formattedexpire+'","conditions": [ {"bucket": "'+
    	record.Bucket_Name__c +'" } ,{ "acl": "'+
    	record.Access__c +'" },'+
    //	'{"success_action_status": "201" },'+
    	'{"content-type":"'+record.Content_Type__c+'"},'+
    	'{"success_action_redirect": "https://'+serverurl+'/'+record.id+'"},' +
    	'["starts-with", "$key", ""] ]}'; 	} } 
    
    public String getPolicy() {
        return EncodingUtil.base64Encode(Blob.valueOf(policy));
    }
    
    public String getSignedPolicy() {    
        return make_sig(EncodingUtil.base64Encode(Blob.valueOf(policy)));        
    }
    
    // tester
    public String getHexPolicy() {
        String p = getPolicy();
        return EncodingUtil.convertToHex(Blob.valueOf(p));
    }
    
    //method that will sign
    private String make_sig(string canonicalBuffer) {        
        String macUrl ;
        String signingKey = EncodingUtil.base64Encode(Blob.valueOf(secret));
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(canonicalBuffer),blob.valueof(Secret)); 
        macUrl = EncodingUtil.base64Encode(mac);                
        return macUrl;
    }
    
    public String bucketToList {get;set;}
	public List<SelectOption> getBucketOptions(){
		try{
			Datetime now = Datetime.now();
			S3.ListAllMyBucketsResult allBuckets = as3.ListAllMyBuckets(
				key,now,as3.signature('ListAllMyBuckets',now));
			
			List<SelectOption> options = new List<SelectOption>();
	   	 	
	   	 	for(S3.ListAllMyBucketsEntry bucket:  allBuckets.Buckets.Bucket ){
	   	 		options.add(new SelectOption(bucket.Name,bucket.Name));	
	   	 	}
		   	return options;
	   	}catch (System.NullPointerException e) {
		   return null;
		}catch(Exception ex){
		   //System.debug(ex);
		   System.debug('caught exception in listallmybuckets');
		   ApexPages.addMessages(ex);
		   return null;	
		}
	}
	
	public pageReference save1() {
		con.save();
		PageReference p = new PageReference('/apex/news3object2?id='+ con.getRecord().id );
		p.getParameters().put('urlParam',serverURL);
		p.setRedirect(true);
		return p;	
	}
	
	public pageReference page2onLoad(){
	   PageReference tempPageRef = constructor();
	   // Need to get the salesforce.com server from the URL
	   System.debug('serverURL: ' +  ApexPages.currentPage().getParameters().get('urlParam'));
	   serverURL = ApexPages.currentPage().getParameters().get('urlParam');
	   //System.debug('serverURL: ' + serverURL);
	   String urlDomain = serverURL.substring(serverURL.indexOf('://')+3,serverURL.indexOf('/services'));
	   System.debug('URL Domain: ' + urlDomain);
	   serverURL = urlDomain;
	   return null;	
	}

     	 
	public static testmethod void t1() {
		AWS_S3_Object__c a = new AWS_S3_Object__c();
		
		S3FormController s3 = new S3FormController(
			new ApexPages.StandardController( a ) );
		
		AWSKey__c testKey = new AWSKey__c(name='test keys',key__c='key',secret__c='secret');
        insert testKey;

		s3.AWSCredentialName = testKey.name;
		s3.constructor();
		system.debug( s3.secret + ' '+ s3.key ); 
		system.debug( s3.getpolicy() ); 
		system.debug( s3.getSignedPolicy() ); 
		system.debug( s3.getHexPolicy() ); 
		
		PageReference pageRef = Page.news3object;
		pageRef.getParameters().put('urlParam','https://na22.salseforce.com/services/soap/14.0/c/');
        Test.setCurrentPage(pageRef);
        
		s3.save1();
		s3.page2onLoad(); 
		system.debug( s3.getBucketOptions() );
	}
	
	public static testmethod void t2() {
		AWS_S3_Object__c a = new AWS_S3_Object__c();
		S3FormController s3 = new S3FormController(new ApexPages.StandardController( a ) );
		s3.AWSCredentialName = 'bad key name';
		s3.constructor();
	}
}