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

public class SalesOrderDisplayController implements Controller {

    /** Logger for this class and subclasses */
    protected final Log logger = LogFactory.getLog(getClass());

    public ModelAndView handleRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

		// add the sales order id to the array to be retrieved
		String[] salesOrderIds = { request.getParameter("salesOrderId") };
		
		SObject[] orderOrders = null;
		QueryResult orderItems = null;
		QueryResult rmas = null;
		
		// get a reference to the connection
		PartnerConnection connection = ConnectionManager.getConnectionManager().getConnection();
		
		try {
			orderOrders = connection.retrieve("Id, Name, Account__r.Name, RMAs__c","Sales_Order__c", salesOrderIds);
			orderItems = connection.query("Select Id, Name, Product__r.Name, Quantity__c, CreatedDate from Sales_Order_Item__c where Sales_Order__c = '"+request.getParameter("salesOrderId")+"'");
			rmas = connection.query("Select Id, Name, Status__c, Origin__c, Type__c, Contact_Name__c from RMA__c where Sales_Order__c = '"+request.getParameter("salesOrderId")+"'");
		} catch (ConnectionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}		 	
    	
		ModelAndView modelAndView = new ModelAndView("salesOrderDisplay");
		modelAndView.addObject("salesOrder", orderOrders[0]);
		modelAndView.addObject("orderItems", orderItems.getRecords());		
		modelAndView.addObject("rmas", rmas.getRecords());		

        return modelAndView;
    }
}