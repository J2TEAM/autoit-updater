<?php
define('UPLOAD_DIR', __DIR__ . DIRECTORY_SEPARATOR . 'upload' . DIRECTORY_SEPARATOR);
define('DOWNLOAD_URL', 'http://localhost/upload/'); // CHANGE TO YOUR URL

if ( ! file_exists(UPLOAD_DIR)) {
  mkdir(UPLOAD_DIR);
}

function getChangelog($file) {
  $file = UPLOAD_DIR . $file;
  return (file_exists($file)) ? file_get_contents($file) : NULL;
}

if (isset($_SERVER['HTTP_USER_AGENT']) AND strpos(strtolower($_SERVER['HTTP_USER_AGENT']), 'autoit updater') !== FALSE) {
  $data = array(
    'base_url' => DOWNLOAD_URL,
    'stable' => array(
      'name'      => 'setup-1.0.1.exe',
      'version'   => '1.0.1',
      'changelog' => getChangelog('changelog.txt')
    ),
    'beta' => array(
      'name'      => 'setup-beta-1.0.1.exe',
      'version'   => '1.0.1',
      'changelog' => getChangelog('changelog-beta.txt')
    )
  );

  if ( ! file_exists(UPLOAD_DIR . $data['stable']['name'])) {
    $data = NULL;
  }
} else {
  $data = NULL;
}

header('Content-Type: application/vnd.api+json');
echo json_encode(array('data' => $data));
