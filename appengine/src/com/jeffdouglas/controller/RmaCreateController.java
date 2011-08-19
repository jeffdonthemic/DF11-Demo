package com.jeffdouglas.controller;

import org.springframework.web.servlet.mvc.SimpleFormController;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.validation.BindException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.QueryResult;
import com.sforce.ws.ConnectionException;
import com.sforce.soap.partner.SaveResult; 
import com.sforce.soap.partner.sobject.SObject;

import com.jeffdouglas.model.*;
import com.jeffdouglas.service.ConnectionManager;

public class RmaCreateController extends SimpleFormController {

    /** Logger for this class and subclasses */
    protected final Log logger = LogFactory.getLog(getClass());
    
    
   protected ModelAndView showForm(HttpServletRequest request, 
    		HttpServletResponse response, 
    		BindException errors) throws Exception {
    
		// add the sales order id to the array to be retrieved
		String[] salesOrderIds = { request.getParameter("salesOrderId") };
		
		SObject[] orderOrders = null;
		QueryResult orderItems = null;
		
		// get a reference to the connection
		PartnerConnection connection = ConnectionManager.getConnectionManager().getConnection();
		
		try {
			orderOrders = connection.retrieve("Id, Name, Account__c, " +
					"Account__r.Name, RMAs__c","Sales_Order__c", salesOrderIds);
			orderItems = connection.query("Select Id, Name, Product__r.Name, Quantity__c, " +
					"CreatedDate from Sales_Order_Item__c where " +
					"Sales_Order__c = '"+request.getParameter("salesOrderId")+"'");
		} catch (ConnectionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}		 	
    	
		ModelAndView modelAndView = super.showForm(request, response, errors);
		modelAndView.addObject("salesOrder", orderOrders[0]);
		modelAndView.addObject("orderItems", orderItems.getRecords());			
		
		return modelAndView;
	}    
    
	protected ModelAndView onSubmit(HttpServletRequest request, 
			HttpServletResponse response, Object command,
			BindException errors) throws Exception {
		
		// cast the posted command data as an account
		RmaCommand cmd = (RmaCommand) command;
		SaveResult[] rmaResults = null;
		
        // populate the new rma
        SObject rma = new SObject();
        rma.setType("RMA__c");
        rma.setField("Account__c", cmd.getAccount());
        rma.setField("Contact_Email__c", cmd.getContactEmail());
        rma.setField("Contact_Name__c", cmd.getContactName());
        rma.setField("Contact_Phone__c", cmd.getContactPhone());
        rma.setField("Description__c", cmd.getDescription());
        rma.setField("Type__c", cmd.getReason());
        rma.setField("Sales_Order__c", cmd.getSalesOrder());
        rma.setField("Origin__c", "Web");
        
        // populate a new rma item
        SObject rmaItem = new SObject();
        rmaItem.setType("RMA_Item__c");
        rmaItem.setField("Quantity__c", cmd.getQuantity());
        rmaItem.setField("Sales_Order_Item__c", cmd.getProduct());
        
        SObject[] rmas = {rma};
        SObject[] rmaItems = {rmaItem};
        
		// get a reference to the connection
		PartnerConnection connection = ConnectionManager.getConnectionManager().getConnection();
        
		try {
			// create the RMA
			rmaResults = connection.create(rmas);
			
			// create the RMA item
	        rmaItem.setField("RMA__c", rmaResults[0].getId());
	        connection.create(rmaItems);
			
		} catch (ConnectionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}	
		
		// TODO Check for errors in results
		
		ModelAndView modelAndView = new ModelAndView(getSuccessView());
		modelAndView.addObject("rmaId", rmaResults[0].getId());

        return modelAndView;
    }
}