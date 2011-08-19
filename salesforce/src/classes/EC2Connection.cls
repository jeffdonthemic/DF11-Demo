public class EC2Connection {
	public AWSKeys k {get;set;}
    public String AccessKey {get;set;}
    public String SecretKey {get;set;}
    //String AccessKey= k.key ; 
    //String SecretKey= k.secret;
    
    String ec2version = '2008-05-05'; //Amazon API version.
    
    
    public EC2Connection(String AWSCredentialName){
      	//k = new AWSKeys(AWSCredentialName);
      	k = new AWSKeys(AWSCredentialName);
      	AccessKey=k.key;
      	SecretKey=k.secret;
    }
    
    public EC2Connection(){
    	
    }
    
    
    //method that wraps the DescribeImages action.
    //Owner was added or we'll exceed the callout limit of 100000 (by default Amazon will return all public images)
    //This needs to be made generic but it'll take some work :
    //The request params need to be sorted case insensitive (if only Map had a 'sort' method)
    public List<EC2Image> DescribeImages(String owner) {
    	
    	//this needs to be the same as the querystring but without the '?' '=' and '&', no urlencoding and not the signature itself
    	String tosign = 'ActionDescribeImagesAWSAccessKeyId'+AccessKey+'Owner.1'+owner+'SignatureVersion1Timestamp'+TimeStamp()+'Version'+ec2version;
    	String signature = make_sig(tosign);
    	String querystring = '?Action=DescribeImages&AWSAccessKeyId='+AccessKey+'&Owner.1='+owner+'&SignatureVersion=1&Timestamp='+EncodingUtil.urlEncode(TimeStamp(), 'UTF-8')+'&Version='+ec2version+'&Signature='+EncodingUtil.urlEncode(signature, 'UTF-8');
    	
    	HttpResponse res =  makerequest(querystring);
    	return parseDescribeImagesReponse(res.getBody());
    }
    
    //launch a specific AMI by its Image Id - one image at once only
    public HttpResponse RunInstances(String imageId) {
    	String tosign = 'ActionRunInstancesAWSAccessKeyId'+AccessKey+'ImageId'+imageId+'MaxCount1MinCount1SignatureVersion1Timestamp'+TimeStamp()+'Version'+ec2version;
    	String signature = make_sig(tosign);
    	String querystring = '?Action=RunInstances&AWSAccessKeyId='+AccessKey+'&ImageId='+imageId+'&MaxCount=1&MinCount=1&SignatureVersion=1&Timestamp='+EncodingUtil.urlEncode(TimeStamp(), 'UTF-8')+'&Version='+ec2version+'&Signature='+EncodingUtil.urlEncode(signature, 'UTF-8');
    	
    	HttpResponse res =  makerequest(querystring);
    	return res; //this should be wrapped in a DOM or object and returned to the controller
    }
    
    //terminate a specific instance by its Instance Id - one instance at once only
    public HttpResponse TerminateInstances(String instanceId) {
    	String tosign = 'ActionTerminateInstancesAWSAccessKeyId'+AccessKey+'InstanceId.1'+instanceId+'SignatureVersion1Timestamp'+TimeStamp()+'Version'+ec2version;
    	String signature = make_sig(tosign);
    	String querystring = '?Action=TerminateInstances&AWSAccessKeyId='+AccessKey+'&InstanceId.1='+instanceId+'&SignatureVersion=1&Timestamp='+EncodingUtil.urlEncode(TimeStamp(), 'UTF-8')+'&Version='+ec2version+'&Signature='+EncodingUtil.urlEncode(signature, 'UTF-8');
    	
    	HttpResponse res =  makerequest(querystring);
    	return res;
    }
    
    //reboot a specific instance by its Instance Id
    public HttpResponse RebootInstances(String instanceId) {
    	String tosign = 'ActionRebootInstancesAWSAccessKeyId'+AccessKey+'InstanceId.1'+instanceId+'SignatureVersion1Timestamp'+TimeStamp()+'Version'+ec2version;
    	String signature = make_sig(tosign);
    	String querystring = '?Action=RebootInstances&AWSAccessKeyId='+AccessKey+'&InstanceId.1='+instanceId+'&SignatureVersion=1&Timestamp='+EncodingUtil.urlEncode(TimeStamp(), 'UTF-8')+'&Version='+ec2version+'&Signature='+EncodingUtil.urlEncode(signature, 'UTF-8');
    	
    	HttpResponse res =  makerequest(querystring);
    	return res;
    }
    
    //get an overview of my running instances
    public List<EC2Instance> DescribeInstances() {
    	String tosign = 'ActionDescribeInstancesAWSAccessKeyId'+AccessKey+'SignatureVersion1Timestamp'+TimeStamp()+'Version'+ec2version;
    	String signature = make_sig(tosign);
    	String querystring = '?Action=DescribeInstances&AWSAccessKeyId='+AccessKey+'&SignatureVersion=1&Timestamp='+EncodingUtil.urlEncode(TimeStamp(), 'UTF-8')+'&Version='+ec2version+'&Signature='+EncodingUtil.urlEncode(signature, 'UTF-8');
    	
    	HttpResponse res =  makerequest(querystring);
    	return parseDescribeInstancesResponse(res.getBody());
    }

    
    //make the request to Amazon EC2, this just wraps the Http communication
    public HttpResponse makerequest(String querystring) { 
    	
    	HttpRequest req = new HttpRequest(); 		
		req.setMethod('GET');
		req.setCompressed(true);
		req.setEndpoint('https://ec2.amazonaws.com/'+querystring);
		
		Http http = new Http();
    	HttpResponse res = http.send(req);
    	    	
    	return res;
    }
    
    //** Helper methods **//
    //method that will sign
    private String make_sig(string canonicalBuffer) {        
        String macUrl ;
        String signingKey = EncodingUtil.base64Encode(Blob.valueOf(SecretKey));
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(canonicalBuffer),blob.valueof(SecretKey)); 
        macUrl = EncodingUtil.base64Encode(mac);                
        return macUrl;
    }
    
    //get a datetime 'now' formatted as '2006-12-08T07:48:03Z'
    private String TimeStamp() {
    	Datetime now = Datetime.now();
    	return now.formatGmt('yyyy-MM-dd')+'T'+now.formatGmt('HH:mm:ss')+'Z';
    }
    
    //** Value objects **//
    
    //AMI Image information
    public class EC2Image {
    	public String imageId {get;set;}
    	public String imageLocation {get;set;}
    	public String imageState {get;set;}
    	public String imageOwnerId {get;set;}
    	public String isPublic {get;set;}
    	public String architecture {get;set;}
    	public String imageType {get;set;}	
    }
    
    //Instance information
    public class EC2Instance {
    	public String instanceId {get;set;}
    	public String imageId {get;set;}
    	public String instanceStateCode {get;set;}
    	public String instanceStateName {get;set;}
    	public String privateDNSName {get;set;}
    	public String dnsName {get;set;}
    	public String amiLaunchIndex {get;set;}
    	public String launchTime {get;set;}
    	public String availabilityZone {get;set;}
    }
    
    
    //** XML to Value objects **//
    public List<EC2Image> parseDescribeImagesReponse(string body) {  //	system.debug( body );
    	
    	List<EC2Image> images = new List<EC2Image>();
 		AWS_XMLDom dom = new AWS_XMLDom(body);
		
		for(AWS_XMLDom.Element e: dom.getElementsByTagName('item') ) {
			EC2Image image = new EC2Image(); 
			image.imageId = e.getValue('imageId');
			image.imageLocation = e.getValue('imageLocation');
			image.imageState = e.getValue('imageState');
			image.imageOwnerId = e.getValue('imageOwnerId');
			image.isPublic = e.getValue('isPublic');
			image.architecture = e.getValue('architecture');
			image.imageType = e.getValue('imageType');
			images.add( image);
		}
		
		return images;
    }
   
    
    //parseDescribeInstances
    //turn the HttpResponse into a List of EC2Instance objects
    public List<EC2Instance> parseDescribeInstancesResponse(string body) {  //system.debug( body );
    	
    	List<EC2Instance> ec2instances = new List<EC2Instance>();
    	    	
    	//create a DOM for the response
    	AWS_XMLDom dom = new AWS_XMLDom(body);
		
		//Need to investigate the exact dom structure better but I'll start with the InstancesSet
		List<AWS_XMLDom.Element> instances = dom.getElementsByTagName('instancesSet');
							
		for(AWS_XMLDom.Element instanceEl:instances) {
			System.debug('Entered intances LOOP *************');
			EC2Instance ec2instance = new EC2Instance();
			//copy the properties
			ec2instance.instanceId = instanceEl.getElementByTagName('instanceId').NodeValue;
			ec2instance.imageId = instanceEl.getElementByTagName('imageId').NodeValue;
			ec2instance.instanceStateCode = instanceEl.getElementByTagName('code').NodeValue; //perhaps I'd better work with getElementByPath here
			ec2instance.instanceStateName = instanceEl.getElementByTagName('name').NodeValue;
			ec2instance.privateDNSName = instanceEl.getElementByTagName('privateDNSName').NodeValue;
			ec2instance.dnsName = instanceEl.getElementByTagName('dnsName').NodeValue;
			ec2instance.amiLaunchIndex = instanceEl.getElementByTagName('amiLaunchIndex').NodeValue;
			ec2instance.launchTime = instanceEl.getElementByTagName('launchTime').NodeValue;
			ec2instance.availabilityZone = instanceEl.getElementByTagName('availabilityZone').NodeValue;
		    ec2instances.add(ec2instance);
		}
		
    	return ec2instances;	
    }      
    
	public static testmethod void t1() {
		try{ 
			EC2Connection cc = new EC2Connection(); 
			system.assert( cc.TimeStamp() != null );
			EC2Image ei = new EC2Image();
			EC2Instance ec2i  =new EC2Instance(); 
			List<EC2Image> di =  cc.DescribeImages('owner');
		}catch(Exception ex){
		}
	}
	public static testmethod void t2() { 
		try{
			EC2Connection cc = new EC2Connection(); 
			HttpResponse t2 =  cc.RunInstances('imageid');
		}catch(Exception ex){
		}
	
	}
	
	public static testmethod void t3() { 
		try{
			EC2Connection cc = new EC2Connection(); 
			HttpResponse t2 =  cc.TerminateInstances('imageid');
		}catch(Exception ex){
		}
	}
	public static testmethod void t4() { 
		try{
			EC2Connection cc = new EC2Connection(); 
			HttpResponse t2 =  cc.RebootInstances('imageid');
		}catch(Exception ex){
		}
	}
	public static testmethod void t5() { 
		try{
			EC2Connection cc = new EC2Connection(); 
			List<EC2Instance> t2 =  cc.DescribeInstances();
		}catch(Exception ex){
		}
	}
	public static testmethod void t6() { 
		try{
			EC2Connection cc = new EC2Connection(); 
			string tst_msg = '<?xml version="1.0"?><DescribeImagesResponse xmlns="http://ec2.amazonaws.com/doc/2008-05-05/"><imagesSet><item><imageId>aki-9800e5f1</imageId><imageLocation>ec2-public-images/vmlinuz-2.6.18-xenU-ec2-v1.0.x86_64.aki.manifest.xml</imageLocation>'+
	        '<imageState>available</imageState><imageOwnerId>amazon</imageOwnerId><isPublic>true</isPublic><architecture>x86_64</architecture><imageType>kernel</imageType>' + 
	        '</item><item><imageId>aki-9b00e5f2</imageId><imageLocation>ec2-public-images/vmlinuz-2.6.18-xenU-ec2-v1.0.i386.aki.manifest.xml</imageLocation><imageState>available</imageState>'+
			'<imageOwnerId>amazon</imageOwnerId><isPublic>true</isPublic><architecture>i386</architecture><imageType>kernel</imageType></item>' +
			'</imagesSet></DescribeImagesResponse>';
			List<EC2Image> imagelist =  cc.parseDescribeImagesReponse(tst_msg);
			
			string test_msg2 = 
			'<?xml version="1.0"?><DescribeInstancesResponse xmlns="http://ec2.amazonaws.com/doc/2008-05-05/"><reservationSet><item><reservationId>r-caf32da3</reservationId><ownerId>99999999914</ownerId><groupSet><item><groupId>general</groupId></item></groupSet><instancesSet><item><instanceId>i-9415bbfd</instanceId><imageId>ami-2c2fcb45</imageId><instanceState><code>16</code><name>running</name></instanceState><privateDnsName>domU-12-31-39-00-B5-26.compute-1.internal</privateDnsName><dnsName>ec2-75-101-158-228.compute-1.amazonaws.com</dnsName>'+
			'<reason/><keyName>ssh-1</keyName><amiLaunchIndex>0</amiLaunchIndex><productCodes/><instanceType>m1.small</instanceType><launchTime>2008-10-21T17:22:01.000Z</launchTime><placement><availabilityZone>us-east-1c</availabilityZone></placement></item></instancesSet></item>    </reservationSet></DescribeInstancesResponse>';
			List<EC2Instance> instList = cc.parseDescribeInstancesResponse(test_msg2);
		}catch(Exception ex){
		}
		 
	}	
}