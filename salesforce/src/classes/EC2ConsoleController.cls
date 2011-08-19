public class EC2ConsoleController {


    EC2Connection ec2;
    private String AWSCredentialName = 'force_demo_ag'; //Modify this string variable to be the name of the AWS Credential record that contains the proper AWS keys and secret
    public List<EC2Connection.EC2Image> images {get;set;}
    public List<EC2Connection.EC2Instance> instances {get;set;}
    public String owner {get;set;}
    
    public EC2ConsoleController() {
        //ec2 = new EC2Connection(AWSCredentialName);      
        //this.owner = 'amazon'; //default owner
        //try { 
       // 	getdescribeImages();
       // 	getdescribeInstances();
       // } catch( exception ee ) {}     
    }


    
    /*
       This method is called when the AWS_S3_Examples Visualforce page is loaded. It verifies that the AWS Keys can be found
       in the AWSKeys__c custom object by the specified name, as set in the string variable AWSCredentialsName. 
       
       Any errors are added to the ApexPage and displayed in the Visualforce page. 
    */
    public PageReference constructor(){
    	try{
			
			AWSKeys credentials = new AWSKeys(AWSCredentialName);
			
			ec2 = new EC2Connection(AWSCredentialName);      
        	this.owner = 'amazon'; //default owner
	        try { 
	        	getdescribeImages();
	        	getdescribeInstances();
	        } catch( exception ee ) {}
			
		
		}catch(AWSKeys.AWSKeysException AWSEx){
		     System.debug('Caught exception in AWS_S3_ExampleController: ' + AWSEx);
		     ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.FATAL, AWSEx.getMessage());
			 ApexPages.addMessage(errorMsg);
			 //throw new AWSKeys.AWSKeysException(AWSEx);
		  	 //ApexPages.addMessage(AWSEx);    
		}
		
		
		
    
       return null;	
    }
    
    //get public AMI images descriptions
    public void getdescribeImages() {        
        this.images = ec2.DescribeImages(owner);
    }
    
    
    //get running instances    
    public void getdescribeInstances() {
        this.instances = ec2.DescribeInstances();
    }
    
    //start up an EC2 image
    public void RunInstances() {
        String imageId = System.currentPageReference().getParameters().get('imageId');
        ec2.RunInstances(imageId); 
        refreshInstances();     
    }
    
    //terminate an EC2 image
    public void TerminateInstances() {
        String instanceId = System.currentPageReference().getParameters().get('instanceId');
        ec2.TerminateInstances(instanceId);
        refreshInstances();
    }
    
    //reboot an EC2 image
    public void RebootInstances() {
        String instanceId = System.currentPageReference().getParameters().get('instanceId');
        ec2.RebootInstances(instanceId);
        refreshInstances();
    }
    
    //reload Instances
    public void refreshInstances() {
        getdescribeInstances();     
    }
    
    //reload images
    public void refreshImages() {
        //System.debug('Owner : '+owner);
        this.images = ec2.DescribeImages(owner);
    }
    
    //for the owner selectlist
    public List<SelectOption> getOwners() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('amazon','Amazon'));
        options.add(new SelectOption('self','My Images'));          
        return options;
    }
    
      private String createTestCredentials(){
       
        AWSKey__c testKey = new AWSKey__c(name='test keys',key__c='key',secret__c='secret');
        insert testKey;
        return testKey.name;
        
     }
     
    // EC2ConsoleController.t1();
	public static testmethod void t1() { 
		EC2ConsoleController ecc = new EC2ConsoleController();
		String credName = ecc.createTestCredentials();
	 	ecc.AWSCredentialName = credName;
	 	ecc.constructor();
		ecc.getdescribeInstances();	
	}
	public static testmethod void t2() { 
		try{
		EC2ConsoleController ecc = new EC2ConsoleController();
		ecc.getdescribeImages();
		}catch(Exception ex){
		}	
	}
	public static testmethod void t3() { 
		try{
			EC2ConsoleController ecc = new EC2ConsoleController();
			ecc.refreshImages();	
		}catch(Exception ex){
		}
	}
	public static testmethod void t4() {
		try{ 
			EC2ConsoleController ecc = new EC2ConsoleController();
			ecc.RebootInstances();
		}catch(Exception ex){
		}	
	}
	public static testmethod void t5() { 
		try{
			EC2ConsoleController ecc = new EC2ConsoleController();
			ecc.getOwners();
			ecc.TerminateInstances();
		}catch(Exception ex){
		}
			
	}
	public static testmethod void t6() { 
		try{
			EC2ConsoleController ecc = new EC2ConsoleController();
			ecc.RunInstances();
		}catch(Exception ex){
		}	
	}
}