package com.jeffdouglas.rmaforce;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;
import org.apache.log4j.RollingFileAppender;

import au.com.bytecode.opencsv.CSVWriter;

import com.jeffdouglas.rmaforce.process.DataLoaderProcess;
import com.jeffdouglas.rmaforce.process.SalesOrderItemProcess;
import com.jeffdouglas.rmaforce.process.SalesOrderProcess;
import com.sforce.async.AsyncApiException;
import com.sforce.async.BatchInfo;
import com.sforce.async.BatchStateEnum;
import com.sforce.async.CSVReader;
import com.sforce.async.ContentType;
import com.sforce.async.JobInfo;
import com.sforce.async.JobStateEnum;
import com.sforce.async.RestConnection;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.fault.LoginFault;
import com.sforce.ws.ConnectionException;
import com.sforce.ws.ConnectorConfig;

public class BulkLoader {

  //static Logger logger = Logger.getLogger(BulkLoader.class);
  /** all being loaded from the properties file **/
	// salesforce settings
  private String userName;
  private String password;
  private String endPoint;
  // SQL Azure settings
  private String sqlServerUrl;
  private String sqlServerUsername;
  private String sqlServerPassword;
  // the CSV file being uploaded - either manually or from SQL Azure resultset
  private String workingDir;
  // email settings
  private String smtpUsername;
  private String smtpPassword;
  private String smtpToAddress;
  private String smtpFromAddress;
  private String smtpHost;
  private String smtpPort;
  private String smtpDebug;
  private String smtpAuth;
  private boolean sendErrorEmail;
  
  // flag to determine if an error occurred and send mail
  boolean error = false;
  // location where the properties are stored
  String propertiesFile = "bulkloader.properties";
  
  static Logger logger = Logger.getLogger(BulkLoader.class);
  PatternLayout layout = new PatternLayout("%d: %m%n");
  ConsoleAppender ca = null;
  RollingFileAppender rfa = null;

  public static void main(String[] args) throws AsyncApiException,
      ConnectionException, IOException {  	
    BulkLoader loader = new BulkLoader();
    loader.run();
  }

  /**
   * Allows the user to run multiple operations
   */
  public void run() {
  	
    readProperties();  	
    
    try {
    	
    	// set up debugging
    	ca = new ConsoleAppender();
    	ca.setWriter(new OutputStreamWriter(System.out));
    	ca.setLayout(layout);
    	rfa = new RollingFileAppender(layout, workingDir + "errors.log", true); // here
    	logger.addAppender(ca);
  		logger.addAppender(rfa);
  		logger.setLevel((Level) Level.ERROR);
  		
  		// upload sales order via bulk api
		SalesOrderProcess salesOrders = new SalesOrderProcess(workingDir);
		if (createCSVFromSQLServer(salesOrders)) runJob(salesOrders, userName, password);
		
  		// upload sales order items via bulk api
		SalesOrderItemProcess salesOrderItems = new SalesOrderItemProcess(workingDir);
		if (createCSVFromSQLServer(salesOrderItems)) runJob(salesOrderItems, userName, password);

    } catch (IOException io) {
      logMessage(io.getMessage());
    } catch (LoginFault lf) {
      logMessage("Salesforce login exception: " + lf.getExceptionMessage());
    } catch (Exception e) {
      e.printStackTrace();
      logMessage(e.getMessage());
    }
    
    // send mail if an error 
    if (error && sendErrorEmail)
    	sendEmail();    

  }
  
  /**
   * Converts SQL Azure resultset to a CSV file
   */
  private boolean createCSVFromSQLServer(DataLoaderProcess process) {
    
    System.out.println("Fetching records from SQL Azure");
    
    Connection conn = null;
    ResultSet rs = null;
    boolean success = false;
    
    try {
      Class.forName("net.sourceforge.jtds.jdbc.Driver").newInstance();
      conn = DriverManager.getConnection(sqlServerUrl, sqlServerUsername, sqlServerPassword);
      
      Statement s = conn.createStatement ();
      s.executeQuery(process.getSql());
      rs = s.getResultSet();
      
      // write the result set to the CSV file
      if (rs != null) {
        CSVWriter writer = new CSVWriter(new FileWriter(process.getCsvFile()), ',');
        writer.writeAll(rs, true);
        writer.close();
        System.out.println("Successfully fetched records from SQL Azure");
        success = true;
      }
      
    } catch (Exception e) {
    	logMessage("Database exception: " + e.toString());
      success = false;
    } finally {
      if (rs != null) {
        try {
          rs.close();
          System.out.println("Resultset terminated");
        } catch (Exception e1) { /* ignore close errors */
        }
      }
      if (conn != null) {
        try {
          conn.close();
          System.out.println("Database connection terminated");
        } catch (Exception e2) { /* ignore close errors */
        }
      }

    }
    return success;
    
  }

  /**
   * Creates a Bulk API job and uploads batches for a CSV file.
   */
  public void runJob(DataLoaderProcess process, String userName, String password) 
  	  throws AsyncApiException, ConnectionException,
      IOException {
    RestConnection connection = getRestConnection(userName, password);
    JobInfo job = createJob(process, connection);
    List<BatchInfo> batchInfoList = createBatchesFromCSVFile(connection, 
    		job, process.getCsvFile());
    closeJob(connection, job.getId());
    awaitCompletion(connection, job, batchInfoList);
    checkResults(connection, job, batchInfoList);
  }
  
  /**
   * Create a new job using the Bulk API.
   */
  private JobInfo createJob(DataLoaderProcess process, RestConnection connection)
      throws AsyncApiException {
    JobInfo job = new JobInfo();
    job.setObject(process.getSobject());
    job.setOperation(process.getOperation());
    job.setExternalIdFieldName(process.getExternalIdFieldName());
    job.setContentType(ContentType.CSV);
    job = connection.createJob(job);
    System.out.println(job);
    return job;
  }

  /**
   * Gets the results of the operation and checks for errors.
   */
  private void checkResults(RestConnection connection, JobInfo job,
      List<BatchInfo> batchInfoList) throws AsyncApiException, IOException {
    // batchInfoList was populated when batches were created and submitted
    for (BatchInfo b : batchInfoList) {
      CSVReader rdr = new CSVReader(connection.getBatchResultStream(
          job.getId(), b.getId()));
      List<String> resultHeader = rdr.nextRecord();
      int resultCols = resultHeader.size();

      List<String> row;
      while ((row = rdr.nextRecord()) != null) {
        Map<String, String> resultInfo = new HashMap<String, String>();
        for (int i = 0; i < resultCols; i++) {
          resultInfo.put(resultHeader.get(i), row.get(i));
        }
        boolean success = Boolean.valueOf(resultInfo.get("Success"));
        boolean created = Boolean.valueOf(resultInfo.get("Created"));
        String id = resultInfo.get("Id");
        String error = resultInfo.get("Error");
        if (success && created) {
          System.out.println("Created row with id " + id);
        } else if (!success) {
        	logMessage("Failed with error: " + error);
          System.out.println("Failed with error: " + error);
        }
      }
    }
  }

  /**
   * Closes the job
   */
  private void closeJob(RestConnection connection, String jobId)
      throws AsyncApiException {
    JobInfo job = new JobInfo();
    job.setId(jobId);
    job.setState(JobStateEnum.Closed);
    connection.updateJob(job);
  }

  /**
   * Wait for a job to complete by polling the Bulk API.
   */
  private void awaitCompletion(RestConnection connection, JobInfo job,
      List<BatchInfo> batchInfoList) throws AsyncApiException {
    long sleepTime = 0L;
    Set<String> incomplete = new HashSet<String>();
    for (BatchInfo bi : batchInfoList) {
      incomplete.add(bi.getId());
    }
    while (!incomplete.isEmpty()) {
      try {
        Thread.sleep(sleepTime);
      } catch (InterruptedException e) {
      }
      System.out.println("Awaiting results..." + incomplete.size());
      sleepTime = 10000L;
      BatchInfo[] statusList = connection.getBatchInfoList(job.getId())
          .getBatchInfo();
      for (BatchInfo b : statusList) {
        if (b.getState() == BatchStateEnum.Completed
            || b.getState() == BatchStateEnum.Failed) {
          if (incomplete.remove(b.getId())) {
            System.out.println("BATCH STATUS:\n" + b);
          }
        }
      }
    }
  }

  /**
   * Create the RestConnection used to call Bulk API operations.
   */
  private RestConnection getRestConnection(String userName, String password)
      throws ConnectionException, AsyncApiException {
    ConnectorConfig partnerConfig = new ConnectorConfig();
    partnerConfig.setUsername(userName);
    partnerConfig.setPassword(password);
    partnerConfig.setAuthEndpoint(endPoint);
    // Creating the connection automatically handles login and stores
    // the session in partnerConfig
    new PartnerConnection(partnerConfig);
    // When PartnerConnection is instantiated, a login is implicitly
    // executed and, if successful,
    // a valid session is stored in the ConnectorConfig instance.
    // Use this key to initialize a RestConnection:
    ConnectorConfig config = new ConnectorConfig();
    config.setSessionId(partnerConfig.getSessionId());
    // The endpoint for the Bulk API service is the same as for the normal
    // SOAP uri until the /Soap/ part. From here it's '/async/versionNumber'
    String soapEndpoint = partnerConfig.getServiceEndpoint();
    String apiVersion = "17.0";
    String restEndpoint = soapEndpoint.substring(0, soapEndpoint
        .indexOf("Soap/"))
        + "async/" + apiVersion;
    config.setRestEndpoint(restEndpoint);
    // This should only be false when doing debugging.
    config.setCompression(true);
    // Set this to true to see HTTP requests and responses on stdout
    config.setTraceMessage(false);
    RestConnection connection = new RestConnection(config);
    return connection;
  }

  /**
   * Create and upload batches using a CSV file. The file into the appropriate
   * size batch files.
   */
  private List<BatchInfo> createBatchesFromCSVFile(RestConnection connection,
      JobInfo jobInfo, String csvFileName) throws IOException,
      AsyncApiException {
    List<BatchInfo> batchInfos = new ArrayList<BatchInfo>();
    BufferedReader rdr = new BufferedReader(new InputStreamReader(
        new FileInputStream(csvFileName)));
    // read the CSV header row
    byte[] headerBytes = (rdr.readLine() + "\n").getBytes("UTF-8");
    int headerBytesLength = headerBytes.length;
    File tmpFile = File.createTempFile("bulkAPIInsert", ".csv");

    // Split the CSV file into multiple batches
    try {
      FileOutputStream tmpOut = new FileOutputStream(tmpFile);
      int maxBytesPerBatch = 10000000; // 10 million bytes per batch
      int maxRowsPerBatch = 10000; // 10 thousand rows per batch
      int currentBytes = 0;
      int currentLines = 0;
      String nextLine;
      while ((nextLine = rdr.readLine()) != null) {
        byte[] bytes = (nextLine + "\n").getBytes("UTF-8");
        // Create a new batch when our batch size limit is reached
        if (currentBytes + bytes.length > maxBytesPerBatch
            || currentLines > maxRowsPerBatch) {
          createBatch(tmpOut, tmpFile, batchInfos, connection, jobInfo);
          currentBytes = 0;
          currentLines = 0;
        }
        if (currentBytes == 0) {
          tmpOut = new FileOutputStream(tmpFile);
          tmpOut.write(headerBytes);
          currentBytes = headerBytesLength;
          currentLines = 1;
        }
        tmpOut.write(bytes);
        currentBytes += bytes.length;
        currentLines++;
      }
      // Finished processing all rows
      // Create a final batch for any remaining data
      if (currentLines > 1) {
        createBatch(tmpOut, tmpFile, batchInfos, connection, jobInfo);
      }
    } finally {
      tmpFile.delete();
    }
    return batchInfos;
  }

  /**
   * Create a batch by uploading the contents of the file. This closes the
   * output stream.
   */
  private void createBatch(FileOutputStream tmpOut, File tmpFile,
      List<BatchInfo> batchInfos, RestConnection connection, JobInfo jobInfo)
      throws IOException, AsyncApiException {
    tmpOut.flush();
    tmpOut.close();
    FileInputStream tmpInputStream = new FileInputStream(tmpFile);
    try {
      BatchInfo batchInfo = connection.createBatchFromStream(jobInfo,
          tmpInputStream);
      System.out.println(batchInfo);
      batchInfos.add(batchInfo);

    } finally {
      tmpInputStream.close();
    }
  }
  
  private void readProperties() {
	  	
    //create an instance of properties class
    Properties props = new Properties();

    //try retrieve data from file
    try {
    	props.load(new FileInputStream(propertiesFile));
    	
    } catch(IOException e) {
    	try {
    	props.load(new FileInputStream("/Users/Jeff/Documents/workspaces/df11/Bulk Loader/" + propertiesFile));
    	} catch(IOException e2) {
    		logMessage(e2.getMessage());
    	}
    }
    
  	userName = props.getProperty("userName");
  	password = props.getProperty("password");
  	endPoint = props.getProperty("endPoint");
  	sqlServerUrl = props.getProperty("sqlServerUrl");
  	sqlServerPassword = props.getProperty("sqlServerPassword");
  	sqlServerUsername = props.getProperty("sqlServerUsername");
  	workingDir = props.getProperty("workingDir");
  	smtpHost = props.getProperty("smtpHost");
  	smtpPort = props.getProperty("smtpPort");
  	smtpDebug = props.getProperty("smtpDebug");
  	smtpAuth = props.getProperty("smtpAuth");
  	props.getProperty("smtpEnableTtls");
  	smtpToAddress = props.getProperty("smtpToAddress");
  	smtpFromAddress = props.getProperty("smtpFromAddress");
  	smtpUsername = props.getProperty("smtpUsername");
  	smtpPassword = props.getProperty("smtpPassword");
  	sendErrorEmail = Boolean.valueOf(props.getProperty("sendErrorEmail"));
    
  }
	  
  public void sendEmail() {   	
		
	Properties props = new Properties();
	props.put("mail.smtp.host", smtpHost);
	props.put("mail.smtp.port", smtpPort);
	props.put("mail.debug", smtpDebug);
	props.put("mail.smtp.auth", smtpAuth);
	props.put("mail.smtp.starttls.enable", "true");
	
	Session s = Session.getInstance(props, null);
	s.setDebug(true);
	MimeMessage message = new MimeMessage(s);

	try {
		
		InternetAddress fromAddress = new InternetAddress(smtpFromAddress);
		InternetAddress toAddress[] = new InternetAddress[1];
		toAddress[0] = new InternetAddress(smtpToAddress);

		message.setSentDate( new Date() );
		message.setFrom( fromAddress );
		message.addRecipients(Message.RecipientType.TO, toAddress);

		message.setSubject("Error Loading Vendor Data into Salesforce.com");
		message.setContent("There was an error loading vendor data into Salesforce.com. Please check the log file " +
  		"on the server for more info.", "text/html");			

		Transport tr = s.getTransport("smtp");			
		tr.connect(smtpHost, smtpUsername, smtpPassword);
		message.saveChanges();
		tr.sendMessage(message, message.getAllRecipients());
		tr.close();
		
		logMessage("Email notification sent to: "+smtpToAddress);

    }
    catch(AddressException ae) {
    	ae.printStackTrace();
    } catch(MessagingException me) {
    	me.printStackTrace();
    }   
	
  }
  
  private void logMessage(String msg) {
  	error = true;
  	logger.error(msg);
  }
  
}