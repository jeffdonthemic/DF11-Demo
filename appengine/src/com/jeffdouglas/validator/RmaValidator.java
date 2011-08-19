package com.jeffdouglas.validator;

import org.springframework.validation.Errors;
import org.springframework.validation.ValidationUtils;
import org.springframework.validation.Validator;

public class RmaValidator implements Validator {
	
	public boolean supports(Class aClass) {
		return com.jeffdouglas.model.RmaCommand.class.equals(aClass);
	}	
 
	public void validate(Object obj, Errors errors) {
		 
		ValidationUtils.rejectIfEmptyOrWhitespace(errors, "contactName", "field.required", "Required field");
		ValidationUtils.rejectIfEmptyOrWhitespace(errors, "contactEmail", "field.required", "Required field");
		ValidationUtils.rejectIfEmptyOrWhitespace(errors, "contactPhone", "field.required", "Required field");
		
	}

}
