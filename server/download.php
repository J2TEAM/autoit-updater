<?php
/*
 * Copyright (C) 2016 Juno_okyo. All rights reserved.
 * 
 * This file is part of AutoIt Updater which is released under MIT LICENSE.
 * See file LICENSE or go to for full license details:
 * https://github.com/J2TeaM/autoit-updater/blob/master/LICENSE
 */
function downloadFile($file) { // $file = include path 
  if(file_exists($file)) {
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename=' . basename($file));
    header('Content-Transfer-Encoding: binary');
    header('Expires: 0');
    header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
    header('Pragma: public');
    header('Content-Length: ' . filesize($file));
    ob_clean();
    flush();
    readfile($file);
    exit;
  }
}

function filter($fileName) {
  $filter = array('..\\', '<', '>', ':', '"', '/', '\\', '|', '?', '*');
  return str_replace($filter, '', $fileName);
}

if (isset($_GET['channel'], $_GET['version'], $_GET['file']) && ! empty($_GET['file'])) {
  $channel = strtolower($_GET['channel']);
  if (in_array($channel, array('stable', 'beta')) && ! empty($_GET['version'])) {
    $slash = DIRECTORY_SEPARATOR;

    // download.php?channel=stable&version=1.0.0&file=setup.exe
    $path = __DIR__ . $slash . 'files' . $slash . $channel . $slash . $_GET['version'] . $slash . filter($_GET['file']);
    downloadFile($path);
  }
}

exit('error');
