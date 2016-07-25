<?php
/*
 * Copyright (C) 2016 Juno_okyo. All rights reserved.
 * 
 * This file is part of AutoIt Updater which is released under MIT LICENSE.
 * See file LICENSE or go to for full license details:
 * https://github.com/J2TeaM/autoit-updater/blob/master/LICENSE
 */
define('FILES_DIR', __DIR__ . DIRECTORY_SEPARATOR . 'files' . DIRECTORY_SEPARATOR);

if ( ! file_exists(FILES_DIR)) {
  mkdir(FILES_DIR);
}

function getChangelog($file) {
  return (file_exists($file)) ? file_get_contents($file) : NULL;
}

function showData($data) {
  header('Content-Type: application/vnd.api+json');
  echo json_encode(array('data' => $data));
  exit;
}

if (isset($_SERVER['HTTP_USER_AGENT']) AND strpos(strtolower($_SERVER['HTTP_USER_AGENT']), 'autoit updater') !== FALSE) { 
  if (isset($_GET['channel'])) {
    $channel = strtolower($_GET['channel']);

    if (file_exists(FILES_DIR . $channel)) {
      // Get latest version
      $dirs = scandir(FILES_DIR . $channel, 1);
      $dirs = array_filter($dirs, function($file) {
        return ( ! in_array($file, array('.', '..')) && is_dir(FILES_DIR . strtolower($_GET['channel']) . DIRECTORY_SEPARATOR . $file));
      });
      $latestVersion = array_shift($dirs);
      unset($dirs);

      // Get setup and changelog
      $path = FILES_DIR . $channel . DIRECTORY_SEPARATOR . $latestVersion . DIRECTORY_SEPARATOR;
      $dirs = scandir($path);
      $txt = array_filter($dirs, function($file) {
        $extension = explode('.', $file);
        return strtolower(end($extension)) === 'txt';
      });
      $exe = array_filter($dirs, function($file) {
        $extension = explode('.', $file);
        return strtolower(end($extension)) === 'exe';
      });

      if (count($txt) > 0 && count($exe) > 0) {
        $changelog = array_shift($txt);
        $setup = array_shift($exe);
        unset($txt, $exe);

        $data = array(
          'version'   => $latestVersion,
          'name'      => $setup,
          'changelog' => getChangelog($path . $changelog)
        );

        showData($data);
      }
    }
  }
}

showData(NULL);
