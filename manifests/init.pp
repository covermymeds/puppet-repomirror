# == Define: repomirror
#
# Handles the scheduled synchronization of a remote yum repo,
# and the creation of repo metadata.
#
# === Parameters
#
# name      : the name of the repo to sync
# path      : the local path into which the repo will be dowloaded
# owner     : the user who should own $path and the cronjob
# group     : the group who should own $path
# cache     : the directory to use for local caching of metadata
# arch      : the architecture of packages to fetch
# comps     : whether to download comps.xml
# delete    : delete local packages no longer present in repository
# gpg       : Remove packages that fail GPG checking after download
# newest    : whether to only download the newest packages
# norepopath: Don't add the reponame to the download path
# plugins   : wheher to enable yum plugin support
# source    : whether to also sync .src.rpm packages
# workers   : the number of workers to use to process the repo metadata
# hour      : the hour at which the cronjob should execute
# minute    : the minute at which the cronjob should execute
#
# === Examples
#
# repomirror { 'rhel-6-server':
#   path       => '/var/repo/vmware',
#   owner      => 'www-data',
#   group      => 'www-data',
#   cache      => '/var/cache/repomirror/rhel-6-server',
#   comps      => false,
#   norepopath => true,
#   hour       => 5,
#   minute     => 30,
# }
#
# === Author
#
# Scott Merrill <smerrill@covermymeds.com>
#
# === Copyright
#
# Copyright 2014 CoverMyMeds, unless otherwise noted
#
# === License
#
# Released under the terms of the Apache Software License
#   https://www.apache.org/licenses/LICENSE-2.0.txt
#
define repomirror (
  $path       = "/var/repomirror/${name}",
  $owner      = root,
  $group      = root,
  $cache      = "/var/cache/repomirror/${name}",
  $arch       = $::architecture,
  $comps      = true,
  $delete     = false,
  $gpg        = true,
  $newest     = false,
  $norepopath = false,
  $plugins    = true,
  $source     = false,
  $workers    = $::processorcount,
  $hour       = 5,
  $minute     = 10,
) {

  # ensure required packages are installed
  if ! defined(Package['yum-utils']) {
    package { 'yum-utils':
      ensure => present,
    }
  }
  if ! defined(Package['createrepo']) {
    package { 'createrepo':
      ensure => present,
    }
  }

  # make sure we were passed in valid paths
  validate_absolute_path( $path )
  validate_absolute_path( $cache )

  # ensure target directories are present
  if ! defined(File[$path]) {
    file { $path :
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => '0755',
    }
  }

  if ! defined(File[$cache]) {
    file { $cache :
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => '0755',
    }
  }

  # validate options
  if $comps {
    $_comps = '-m'
  } else {
    $_comps = ''
  }

  if $delete {
    $_delete = '-d'
  } else {
    $_delete = ''
  }

  if $gpg {
    $_gpg = '-g'
  } else {
    $_gpg = ''
  }

  if $newest {
    $_newest = '-n'
  } else {
    $_newest = ''
  }

  if $norepopath {
    $_norepo = '--norepopath'
  } else {
    $_norepo = ''
  }

  if $plugins {
    $_plugins = '-l'
  } else {
    $_plugins = ''
  }

  if $source {
    $_source = '--source'
  } else {
    $_source = ''
  }

  $r_cmd = "/usr/bin/reposync -r ${name} -p ${path} -e ${cache} -q"
  $r_args = "-a ${arch} ${_comps} ${_delete} ${_gpg} ${_newest} ${_norepo} ${_plugins} ${_source}"

  $c_cmd = '/usr/bin/createrepo'
  $c_args = "-q -c ${cache} --simple-md-filenames --deltas --workers ${workers}"

  cron { "repomirror-${name}":
    ensure  => present,
    command => "${r_cmd} ${r_args} && ${c_cmd} ${c_args} --update ${path}",
    hour    => $hour,
    minute  => $minute,
    user    => $owner,
  }
}
