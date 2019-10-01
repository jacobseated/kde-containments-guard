#!/usr/bin/php
<?php

$config_file_path = $argv[1];
$backup_file_path = $argv[2];

$config_file_content_full = file_get_contents_utf8($config_file_path);
$backup_file_content = file_get_contents_utf8($backup_file_path);

preg_match('/\[Containments\]\[1\]\[General\]([^\[]+)/i', $config_file_content_full, $matches, PREG_OFFSET_CAPTURE);
$containments_from_config = $matches[0][0];

echo str_replace($containments_from_config, $backup_file_content, $config_file_content_full);

function file_get_contents_utf8($fn)
{
    $content = file_get_contents($fn);
    return mb_convert_encoding($content, 'UTF-8',
        mb_detect_encoding($content, 'UTF-8, ISO-8859-1', true));
}