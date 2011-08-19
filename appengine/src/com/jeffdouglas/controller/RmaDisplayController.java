package com.jeffdouglas.controller;

import org.springframework.web.servlet.mvc.Controller;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;
import java.io.IOException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.jeffdouglas.service.ConnectionManager;

import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.QueryResult;
import com.sforce.ws.ConnectionException;
import com.sforce.soap.partner.sobject.SObject;

public class RmaDisplayController implements Controller {

    /** Logger for this class and subclasses */
    protected final Log logger = LogFactory.getLog(getClass());

    public ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

		// add the sales order id to the array to be retrieved
		String[] rmaIds = { request.getParameter("rmaId") };
		
		SObject[] rmas = null;
		QueryResult rmaItems = null;
		QueryResult attachments = null;
		
		// get a reference to the connection
		PartnerConnection connection = ConnectionManager.getConnectionManager().getConnection();
		
		try {
			rmas = connection.retrieve("Id, Name, Contact_Email__c, Contact_Name__c, Contact_Phone__c," +
					"Description__c, Origin__c, Status__c, Type__c, CreatedDate, Sales_Order__c," +
					"Sales_Order__r.Name","RMA__c", rmaIds);
			rmaItems = connection.query("Select Name, Quantity__c, Sales_Order_Item__r.Name from " +
					"RMA_Item__c where RMA__c = '"+request.getParameter("rmaId")+"'");
			attachments = connection.query("select Id, Name from Attachment where ParentId = '" + 
					request.getParameter("rmaId")+"'");
		} catch (ConnectionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}		 	
    	
		ModelAndView modelAndView = new ModelAndView("rmaDisplay");
		modelAndView.addObject("rma", rmas[0]);		
		modelAndView.addObject("items", rmaItems.getRecords());
		modelAndView.addObject("attachments", attachments.getRecords());
		
        return modelAndView;
    }
}