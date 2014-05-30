#repomirror

####Table of Contents
1. [Overview](#overview)
2. [Parameters](#parameters)
3. [Usage](#usage)
  * [Simple Example](#simple-example)
  * [Hiera Example](#hiera-example)
4. [Limitations](#limitations)
5. [License](#license)

##Overview
The repomirror module uses [reposync](http://yum.baseurl.org/gitweb?p=yum-utils.git;a=blob;f=reposync.py;hb=HEAD) from the [yum-utils](http://yum.baseurl.org/) package to locally mirror an upstream yum repository.  It also invokes [createrepo](http://createrepo.baseurl.org/) to create the necessary metadata for the local mirror.

The goal of this module is to use packages that are available within a base installation of RHEL / CentOS / etc. without having to rely on [EPEL](https://fedoraproject.org/wiki/EPEL).

##Parameters
Most of the paramaters of the `repomirror` defined type match the command line arguments for `reposync` and `createrepo`.

###`name`
The name of the repository to sync.  The name must match the repository ID from a yum repository defined somewhere in `/etc/yum.repos.d/`. 

###`path`
The local path into which the packages will be downloaded.

Default: /var/repomirror/${name}

###`owner`
The owner of the files downloaded, as well as the directory containing them. This cron job will execute as this user, too.

Default: root

###`group`
The group owner of the files downloaded, as well as the directory containing them.

Default: root

###`cache`
The directory to use for caching metadata.

Default: /var/cache/repomirror/${name}

###`arch`
The architecture of the packages to download.

Default: $::architecture

###`comps`
Whether to download the comps.xml file, which defines the various package groupings.

Default: true

###`delete`
Whether to delete local packages no longer present in repository

Default: false

###`gpg`
Whether to remove packages that fail GPG signature checking after downloading.

Default: true

###`newest`
Whether to download only the newest packages.

Default: false

###`norepopath`
Don't add the reponame to the download path. When this option is not set (the default), the RPMs will be downloaded to ${path}/${name}. When this option is set, the RPMs will be downloaded to ${path}.

Default: false

###`plugins`
Whether to enable yum plugin support

Default: true

###`source`
Whether to also download source RPMs

Default: false

###`workers`
The number of `createrepo` worker processes to spawn to read RPMs.

Default: $::processorcount

###`hour`
The hour at which the cron job should commence.

Default: 5

###`minute`
The minute at which the cron job should commence.

Default: 10

##Usage
This module contains a single defined type, `repomirror`. The name of each instance of this defined type should be the repository ID of a yum repository listed in a file in `/etc/yum/repos.d/` on the target host.

If `/etc/yum.repos.d/puppetlabs.repo` contains the following:
```
[puppetlabs-products]
name=Puppet Labs Products El 6 - $basearch
baseurl=http://yum.puppetlabs.com/el/6/products/$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
```
you would use `puppetlabs-products` as the name of the `repomirror` instance.

Each instance of the `repomirror` defined type will create a cron job on the target host.

###Simple Example
```
  repomirror { 'base':
    path       => '/pub/repos/centos6',
    owner      => root,
    group      => root,
    cache      => '/var/cache/repos/centos6',
    norepopath => true,
    hour       => 2,
    minute     => 15,
  }
```
The above example will mirror the repository with repo ID `base` to `/pub/repos/centos6`, and use `/var/cache/repos/centos6` for the cache. Because the `norepopath` option was specified as `true`, the RPMs will be downloaded directly to `/pub/repos/centos6`.

The follow cron job will be defined for the root user:
```
# Puppet Name: repomirror-base
15 2 * * * /usr/bin/reposync -r  -p /pub/repos/centos6 -e /var/cache/repos/centos6 -q -a x86_64 -m  -g  --norepopath -l  && /usr/bin/createrepo -q -c /var/cache/repos/centos6 --simple-md-filenames --deltas --workers 1 --update /pub/repos/centos6
``` 

###Hiera Example
A simple Puppet module can be written to collect a hash of hashes stored in Hiera, and use the [create_resources](http://docs.puppetlabs.com/references/latest/function.html#createresources) function to instantiate them in bulk.

```
class yum_mirror ( $repos ) {
  validate_hash( $repos )

  create_resources( repomirror, $repos )
}
```

Add this bit of Hiera:
```
---
yum_mirror::repos:
  base:
    path: /pub/repos/centos6
    hour: 4
    minute: 30
  puppetlabs-products:
    path: /pub/repos/puppet
    hour: 5
    minute: 30
```

Two cron jobs will be created: one at 4:30 AM for the CentOS 'base' repo, and one at 5:30 AM for the Puppet Labs 'puppetlabs-products' repo.

##Limitations
The `repomirror` defined type **does not** create the parent directories of the local mirror or the cache.  That is to say, given the following implementation:
```
  repomirror{ 'base':
    path  => '/pub/repos/centos-6',
    cache => '/var/cache/repos/centos-6',
  }
```
The directories `/pub/repos/` and `/var/cache/repos/` **will not** be created. It is up to you to create these directories.

Additionally, `repomirror` **does not** address serving your local mirror to external clients.  You are responsible for setting up a web server yourself.

##License
This module is released under the terms of the Apache Software License version 2: [https://www.apache.org/licenses/LICENSE-2.0.txt](https://www.apache.org/licenses/LICENSE-2.0.txt)
