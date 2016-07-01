<?php

$response="";


if (! in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', '::1'))) 
{
  http_response_code(404);
  $response["status"] ="404";
  $response["data"] = array();
} else {


  $result1 = apc_clear_cache();
  $result2 = apc_clear_cache('user');
  $result3 = apc_clear_cache('opcode');
  $infos = apc_cache_info();
  $infos['apc_clear_cache'] = $result1;
  $infos["apc_clear_cache('user')"] = $result2;
  $infos["apc_clear_cache('opcode')"] = $result3;
  $infos["success"] = $result1 && $result2 && $result3;


  $response["status"] = "200";
  $response["cache_data"] = $infos;

}

header('Content-type: application/json');
echo json_encode($response, JSON_PRETTY_PRINT);





