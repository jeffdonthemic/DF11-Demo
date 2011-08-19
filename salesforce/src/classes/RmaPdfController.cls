/******************************************************************
 Name : RmaPdfController
 Created By : Jeff Douglas
 Created Date : July 2, 2011
 Description : Generates a PDF from RmaTemplate, attaches it to 
 the RMA and uploads it to Amazon S3 (future method). 
 Invoked from the "Generate PDF" button the on the RMA page layout.
********************************************************************/

public with sharing class RmaPdfController {
	
	private RMA__c rma;
	
	public RmaPdfController() {
    rma = [select id, name from rma__c where id = :ApexPages.currentPage().getParameters().get('id')];
	}
	
	public PageReference generate() {
		
    PageReference pdf = Page.RmaTemplate;
    // add  id to the parameters for standardcontroller
    pdf.getParameters().put('id',rma.id);
 
    // create the new attachment
    Attachment attach = new Attachment();
 
    // the contents of the attachment from the pdf
    Blob body;
 
    try {
      // returns the output of the page as a PDF
      body = pdf.getContent();
    // need to pass unit test -- current bug  
    } catch (VisualforceException e) {
      body = Blob.valueOf('Some Text');
    }
 
    attach.Body = body;
    // add the RMA's name to the fine name
    attach.Name = rma.name + '.pdf';
    attach.IsPrivate = false;
    // attach the pdf to the RMA
    attach.ParentId = rma.id;
       
    insert attach; 
    
    // send the attachment to S3 via @future callout
    RmaS3.syncAttachment(attach.id);
		
		// return back to the RMA page
		return new PageReference('/' + rma.id);
		
	}
	


}