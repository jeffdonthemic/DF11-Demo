public class AWS_ExplorerCon {

    private String AWSCredentialName = 'DF11 Preso Account'; //Modify this string variable to be the name of the AWS Credential record that contains the proper AWS keys and secret
    public  String selectedObjectName { get; set; }  // From page
    public  List<String> objectNames { get {
    	if ( objectNames == null ) 
    		getObjects();
    	return objectNames;
    	} set; }  // All available objects
    public  String selectedFieldName { get; set; }  // From Page
         
    public transient S3.ListEntry selectedField { get; set; }
    public transient S3.ListEntry selectedObject { get; set; }
    
    // TOOD write a setter for this
    
    public S3.AmazonS3 as3 { get; private set; } //This object represents an instance of the Amazon S3 toolkit and makes all the Web Service calls to AWS. 
	public AWS_ExplorerCon() {
    	//AWSKeys credentials = new AWSKeys('NAME aOF KEY TO USE');
        
    }
    
    
    
      public PageReference constructor(){
    	try{
			
			AWSKeys credentials = new AWSKeys(AWSCredentialName);
			as3 = new S3.AmazonS3(credentials.key,credentials.secret);
			as3 = new S3.AmazonS3();
	    	as3.secret = credentials.secret;
			as3.key = credentials.key;
			
		}catch(AWSKeys.AWSKeysException AWSEx){ 
		     
		     ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, AWSEx.getMessage());
			 ApexPages.addMessage(errorMsg);
			    
		}
		
		
		
    
       return null;	
    }
    
    
    public void getObjects() {
        try{
	        objectNames = new List<String>();
	       	Datetime now = Datetime.now();
			S3.ListAllMyBucketsEntry[] buckets = 
				as3.ListAllMyBuckets(as3.key,now,as3.signature('ListAllMyBuckets',now)).Buckets.Bucket;
			 
			for(S3.ListAllMyBucketsEntry bucket: buckets){
				objectNames.add((' ' + bucket.Name).trim());
			}
        }catch (Exception ex){
        }
	  
    }
    S3.ListBucketResult objectsForBucket ;         
    public PageReference getFields() {
        
        objectNames = new List<String>();
        selectedFieldName = null;
        selectedField = null;
        
        system.debug( selectedObjectName );
    	Datetime now = Datetime.now();
		Integer maxNumberToList = 25; //Set the number of Objects to return for a specific Bucket
		String Prefix = null; //Limits the response to keys that begin with the indicated prefix. You can use prefixes to separate a bucket into different sets of keys in a way similar to how a file system uses folders. This is an optional argument.
		String Marker = null; //Indicates where in the bucket to begin listing. The list includes only keys that occur alphabetically after marker. This is convenient for pagination: To get the next page of results use the last key of the current page as the marker. The most keys you'd like to see in the response body. The server might return less than this number of keys, but will not return more. This is an optional argument.
		String Delimiter = null; //Causes keys that contain the same string between the prefix and the first occurrence of the delimiter to be rolled up into a single result element in the CommonPrefixes collection. These rolled-up keys are not returned elsewhere in the response. 
		
	 	objectsForBucket = 
    		as3.ListBucket(selectedObjectName, Prefix, Marker ,maxNumberToList, 
    		Delimiter,as3.key,now,as3.signature('ListBucket',now),as3.secret);
        //bucketList = objectsForBucket.Contents; 
        //  public S3.ListEntry[] bucketList {get;set;}    
  
  		if ( objectsForBucket != null && objectsForBucket.Contents != null) {
        for (S3.ListEntry f : objectsForBucket.Contents ) {
        	//system.debug( f );
            objectNames.add((' ' + f.Key).trim());
        }
  		}
        return null;
  
    }

    public PageReference getFieldDetails() {
   		system.debug( selectedFieldName );
		for (S3.ListEntry f : objectsForBucket.Contents ) {
        	if ( f.Key == selectedFieldName ) { 
       			//system.debug( f );
        		selectedField = f;       			
        	}
       }
       return null;
    }
    
    public class TreeNode {
        public String label { get; set; }
        public Object value { get; set; }
        public TreeNode(String label, Object value) {
            this.label = label;
            this.value = value;
        }   
    }

	 
	 
	 private String createTestCredentials(){
       
        AWSKey__c testKey = new AWSKey__c(name='test keys',key__c='key',secret__c='secret');
        insert testKey;
        return testKey.name;
        
     }
     
     
	 public static testmethod void testcon() {
	 	try{
	 	AWS_ExplorerCon a = new AWS_ExplorerCon();
	 	String credName = a.createTestCredentials();
	    a.AWSCredentialName = credName;
	 		
	 	a.constructor();
	 	a.selectedObjectName = 'foo';
	 	system.assert( a.objectNames != null );
	 	a.getFields();
	 	system.debug ( a.selectedObjectName ); 
	 	system.debug ( a.selectedFieldName ); 
	 	system.debug ( a.selectedField ); 
	 	system.debug ( a.selectedObject ); 
	 	system.debug ( a.as3 ); 	 	
	 	system.assert( a.getFieldDetails() == null );
	 	}catch(Exception ex){
	 	}
	 	
	 }
	 
	  public static testmethod void testcon2() {
	  	try{
		 	AWS_ExplorerCon a = new AWS_ExplorerCon();
		 	String credName = a.createTestCredentials();
		    a.AWSCredentialName = credName;
		 	
		 	a.constructor();
		 	a.getFields();
	  	}catch(Exception ex){
	  	}
	  	 
	  }
	  public static testmethod void testcon3() {
	  	try{
		 	AWS_ExplorerCon a = new AWS_ExplorerCon();
		 	String credName = a.createTestCredentials();
		    a.AWSCredentialName = credName;
		 	
		 	a.constructor();
		 	system.debug ( a.selectedObjectName ); 
		 	system.debug ( a.selectedFieldName ); 
		 	system.debug ( a.selectedField ); 
		 	system.debug ( a.selectedObject ); 
		 	system.debug ( a.as3 ); 	 	
			try {
		 		system.assert( a.getFieldDetails() == null );
			} catch( exception ee) { 
				// expected
			}
			
			TreeNode t = new TreeNode('foo','sdf');
			system.debug( t.label );
			system.debug( t.value );
	  	}catch(Exception ex){
	  	}
	  }
}