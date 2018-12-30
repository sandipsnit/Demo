 <jdbc-resource enabled="true" jndi-name="${jndiName}" object-type="user" pool-name="${poolName}"/>

 <jdbc-connection-pool allow-non-component-callers="false" associate-with-thread="false" connection-creation-retry-attempts="0" connection-creation-retry-interval-in-seconds="10" connection-leak-reclaim="false" connection-leak-timeout-in-seconds="0" connection-validation-method="auto-commit" datasource-classname="${datasourceClass}" fail-all-connections="false" idle-timeout-in-seconds="300" is-connection-validation-required="false" is-isolation-level-guaranteed="true" lazy-connection-association="false" lazy-connection-enlistment="false" match-connections="false" max-connection-usage-count="0" max-pool-size="32" max-wait-time-in-millis="60000" name="${poolName}" non-transactional-connections="false" pool-resize-quantity="2" res-type="javax.sql.DataSource" statement-timeout-in-seconds="-1" steady-pool-size="8" validate-atmost-once-period-in-seconds="0" wrap-jdbc-objects="false">

	<property name="serverName" value="${serverName}"/>

    <property name="PortNumber" value="${port}"/>

    <property name="DatabaseName" value="${databaseName}"/>

    <property name="User" value="${user}"/>

    <property name="Password" value="${password}"/>

    <property name="URL" value="${url}"/>

    <property name="driverClass" value="${driverClass}"/>

 </jdbc-connection-pool>

 <mail-resource debug="true" enabled="true" from="${mailFrom}" host="${mailHost}" jndi-name="${jndiName}" object-type="user" store-protocol="imap" store-protocol-class="com.sun.mail.imap.IMAPStore" transport-protocol="smtp" transport-protocol-class="com.sun.mail.smtp.SMTPTransport" user="${mailUser}">
         
 </mail-resource>
 
 <admin-object-resource enabled="true" jndi-name="${jndiName}" object-type="user" res-adapter="jmsra" res-type="${resourceType}">
	<description/>
 </admin-object-resource>
  
 <connector-resource enabled="true" jndi-name="${jndiName}" object-type="user" pool-name="${connectorPoolName}">
 	<description/>   
 </connector-resource>
 <connector-connection-pool associate-with-thread="false" connection-creation-retry-attempts="0" connection-creation-retry-interval-in-seconds="10" connection-definition-name="${resourceType}" connection-leak-reclaim="false" connection-leak-timeout-in-seconds="0" fail-all-connections="false" idle-timeout-in-seconds="300" is-connection-validation-required="false" lazy-connection-association="false" lazy-connection-enlistment="false" match-connections="true" max-connection-usage-count="0" max-pool-size="32" max-wait-time-in-millis="60000" name="${connectorPoolName}" pool-resize-quantity="2" resource-adapter-name="jmsra" steady-pool-size="8" validate-atmost-once-period-in-seconds="0"/>
  
