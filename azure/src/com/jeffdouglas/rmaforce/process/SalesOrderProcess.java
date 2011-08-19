package com.jeffdouglas.rmaforce.process;

import com.jeffdouglas.rmaforce.process.DataLoaderProcess;

import com.sforce.async.OperationEnum;

public class SalesOrderProcess implements DataLoaderProcess {
  
  private String sobject;
  private String sql;
  private OperationEnum operation;
  private String externalIdFieldName;
  private String csvDirectory;
  
  public SalesOrderProcess(String csvDirectory) {
    this.csvDirectory = csvDirectory;
    sobject = "Sales_Order__c";
    sql = "SELECT ID as 'SQL_Id__c', AccountId as 'Account__r.SQL_Id__c' FROM SalesOrder";
    operation = OperationEnum.upsert;
    externalIdFieldName = "SQL_Id__c";
  }
  
  public String getSobject() {
    return sobject;
  }
  public String getSql() {
    return sql;
  }
  public String getCsvFile() {
    return csvDirectory + sobject + ".csv";
  }

  public OperationEnum getOperation() {
    return operation;
  }
  public String getExternalIdFieldName() {
    return externalIdFieldName;
  }
  
}
