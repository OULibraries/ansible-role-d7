<?php


$response="";

/* Don't let strangers in */

if (! in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', '::1'))) 
{
  http_response_code(404);
  $response["success"] = false;
  $response["data"] = array();
} else {
  /* Clear all APC Caches */
  $result1 = apc_clear_cache();
  $result2 = apc_clear_cache('user');
  $result3 = apc_clear_cache('opcode');
  $infos = apc_cache_info();
  $infos['apc_clear_cache'] = $result1;
  $infos["apc_clear_cache('user')"] = $result2;
  $infos["apc_clear_cache('opcode')"] = $result3;
  $response["success"] = $result1 && $result2 && $result3;
  $response["data"] = $infos;

}

header('Content-type: application/json');
echo json_encode($response, JSON_PRETTY_PRINT);





