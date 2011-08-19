package com.jeffdouglas.controller;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.validation.BindException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.SimpleFormController;

import com.jeffdouglas.model.SearchCommand;
import com.jeffdouglas.service.ConnectionManager;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.QueryResult;
import com.sforce.ws.ConnectionException;

public class SalesOrderLookupController extends SimpleFormController {
	
    /** Logger for this class and subclasses */
    protected final Log logger = LogFactory.getLog(getClass());

	protected ModelAndView onSubmit(HttpServletRequest request, 
			HttpServletResponse response, Object command,
			BindException errors) throws Exception {
		
		SearchCommand cmd = (SearchCommand) command;
				
		// get a reference to the connection
		PartnerConnection connection = ConnectionManager.getConnectionManager().getConnection();
		
		QueryResult result = null;
		try {
			result = connection.query("Select Id, Name, Account__r.Name, RMAs__c from Sales_Order__c " +
					"Where Name LIKE '" + cmd.getName() + "%'");
		} catch (ConnectionException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NullPointerException npe) {
			// TODO Auto-generated catch block
			npe.printStackTrace();
			logger.error("NullPointerException: "+npe.getCause().toString());
		}
				
		ModelAndView modelAndView = new ModelAndView("salesOrderLookup");
		modelAndView.addObject("salesOrders", result.getRecords());

        return modelAndView;
    }

}
