/******************************************************************
 Name : RmaS3
 Created By : Jeff Douglas
 Created Date : July 2, 2011
 Description : Send an attachment to S3
********************************************************************/

public with sharing class RmaS3 {
	
	@future(callout=true)
  public static void syncAttachment(ID id){
  	
  	Attachment a = [select id, name, body, bodyLength from attachment where id = :id];
    
    AWSKeys credentials = new AWSKeys('DF11 Preso Account');
    S3.AmazonS3 as3 = new S3.AmazonS3(credentials.key,credentials.secret);
    String bucket = 'RMAforce';
    String bucketOwnerId = 'c0aed198b5797f01aa5daa3f0c45205adaa97ab3dfb5c014ec5495713dee76e9';
    String accessType = 'public-read';
    String s3Message = 'Error';
    Datetime now = Datetime.now();
    
    try{  
      String encodedBody = EncodingUtil.base64Encode(a.Body);
                  
      Boolean putObjResult = as3.PutObjectInline_ACL(bucket,a.Name,null,
        encodedBody,a.BodyLength,accessType,as3.key,now,
        as3.signature('PutObjectInline',now),as3.secret, bucketOwnerId);
        
      if(putObjResult==true){
        System.debug('putobjectinline successful');
        s3Message = 'Success';
      }
    
    }catch(System.CalloutException callout){
      System.debug('CALLOUT EXCEPTION: ' + callout);
      s3Message =   callout.getMessage();

    }catch(Exception ex){
      System.debug('EXCEPTION: ' + ex);
      s3Message =   ex.getMessage();
        
    }
    
    System.debug('============== S3Message: ' + s3Message);
 
  }

}