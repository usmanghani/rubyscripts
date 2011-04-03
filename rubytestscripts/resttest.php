#! /opt/local/bin/php

<?php
	$request = 'https://management.core.windows.net:443/993ad3b2-f875-4311-8459-414334cd16ee/services/hostedservices';
	$session = curl_init();
	curl_setopt($session, CURLOPT_URL, $request);
	curl_setopt($session, CURLOPT_HTTPHEADER, array ('x-ms-version: 2009-10-01'));
	curl_setopt($session, CURLOPT_SSLVERSION, 3);
	curl_setopt($session, CURLOPT_SSLCERT, "/Users/usmanghani/Documents/apicert.pem");
	curl_setopt($session, CURLOPT_SSLKEY, "/Users/usmanghani/Documents/apicert.pem");
	curl_setopt($session, CURLOPT_SSLKEYPASSWD, 'rdPa$$w0rd');
	curl_setopt($session, CURLOPT_SSL_VERIFYPEER, 0); 
	curl_setopt($session, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($session, CURLOPT_SSL_VERIFYHOST, 0);
	curl_setopt($session, CURLOPT_SSLKEYTYPE, "PEM");

	$response = curl_exec($session);

	if(!curl_errno($session))
	{ 
	  $info = curl_getinfo($session); 
	  echo 'Took ' . $info['total_time'] . ' seconds to send a request to ' . $info['url']; 
	} 
	else 
	{ 
	  echo 'Curl error: ' . curl_error($session); 
	} 
 
	curl_close($session);
	echo $response;
?>