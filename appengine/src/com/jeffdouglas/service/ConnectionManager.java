package com.jeffdouglas.service;

import java.util.logging.Logger;

import java.util.Map;
import javax.cache.Cache;
import javax.cache.CacheException;
import javax.cache.CacheFactory;
import javax.cache.CacheManager;
import com.google.appengine.api.memcache.stdimpl.GCacheFactory;
import java.util.Properties;

import com.sforce.soap.partner.Connector;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.ws.ConnectionException;
import com.sforce.ws.ConnectorConfig;

public class ConnectionManager {
	
	private static ConnectionManager ref;
	private static final Logger logger = Logger.getLogger(ConnectionManager.class.getName());
	private static PartnerConnection connection;
	private static ConnectorConfig config;
	private Cache cache;
	private static final String username = "YOUR-SFDC-USERNAME";
	private static final String password = "YOUR-SFDC-PASSWORD-AND-TOKEN";
	private static final String SESSION_KEY = "sessionKey";
	private static final String SESSION_VALUE = "sessionValue";
	
	private ConnectionManager() { }

	public static ConnectionManager getConnectionManager() {
		if (ref == null)
			ref = new ConnectionManager();
		return ref;
	}
	
	public PartnerConnection getConnection() {
		
		Map props = new Properties();
		props.put(new Integer(GCacheFactory.EXPIRATION_DELTA), new Integer(3600)); // 1 hour
		
        try {
            CacheFactory cacheFactory = CacheManager.getInstance().getCacheFactory();
            cache = cacheFactory.createCache(props);
        } catch (CacheException e) {
        	logger.warning("CacheException " +e.getMessage()); 
        }
        
        if (!cache.containsKey(SESSION_KEY)) {
			try { 
				logger.info("===========> Fetching new connection....");
				config = new ConnectorConfig();
				config.setUsername(username);
				config.setPassword(password);
				connection = Connector.newConnection(config);
			} catch ( ConnectionException ce) {
				logger.warning("ConnectionException " +ce.getMessage()); 
			}        	
        	// cache the key for the specified time period
        	cache.put(SESSION_KEY, SESSION_VALUE);
        } else {
        	logger.info("===========> Using existing connection....");
        }
        
        logger.info("===========> SessionId...."+config.getSessionId());
        
		return connection;
	}

	public Object clone() throws CloneNotSupportedException {
		throw new CloneNotSupportedException(); 
	}

}