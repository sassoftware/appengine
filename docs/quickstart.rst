Developer Quick Start Guide
***************************

The following is a brief guide on how to deploy a SAS App Engine and prepare it
for developing and testing App Engine components in-place.

Installation
============

First, obtain the Installable ISO media.
The weekly developer build can be downloaded from the following location:
https://sas-app-engine-ci.s3.amazonaws.com/appengine-8-devel-x86_64.iso

Next, create a virtual machine in which to install the App Engine.
The following minimum requirements are recommended:

* 64-bit CPU
* 2 GiB RAM minimum, 4 GiB recommended
* 100 GB disk space
* Internet connection

Attach the ISO to the virtual machine and proceed with installation.
By default, half of the available disk space will be reserved for image
building. If you customize the partitioning scheme you must leave unallocated
LVM space for image builds. Do not enable disk encryption.

System Configuration
====================

After the install, a number of system configuration files should be adjusted.
Log into the console with username ``root`` and the password chosen at install
time.

**/etc/sysconfig/network** : App Engine requires a valid hostname other than
"localhost". If one has not been assigned by DHCP, set it here. The hostname
*must* be resolveable, so if it is not then add it to **/etc/hosts** as well.
If the hostname was changed, reboot or set it manually with the ``hostname``
command.

**/etc/ssh/sshd_config** : The ``amiconfig`` daemon disables password SSH logins
by default. Find the line containing ``PasswordAuthentication yes`` and delete
it. Also run ``chkconfig amiconfig off`` to prevent it from undoing this change
in the future. Run ``service sshd restart`` so the changes take effect.

At this point you may wish to switch to using SSH for convenience rather than
direct console access.

**/root/.conaryrc** : Create this file with the contents::

    includeConfigFile https://updates.sas.com/conaryrc

This will ensure that system updates can find the App Engine upstream
repositories.

**/etc/conary/system-model** : Change group-rbuilder-dist to
``group-rbuilder-devel``. Run ``conary updateall``. This will both bring the App
Engine to the latest build if the ISO is out of date, and also install all of
the developer tools and libraries that are not in the ISO.

App Engine Configuration
========================

Edit **/etc/rbuilder.pp**. Set ``$admin_email``. It is recommended to set
project_domain to something unique to your App Engine install, for example
"bobs-appengine". Repository hostnames for newly created projects will be
constructed from this value. It does not need to be resolveable. Namespace and
project_domain can be changed later, but will not affect existing projects.

Run ``puppet apply --debug /etc/rbuilder.pp``. This will adjust additional
system configuration, create the App Engine configuration, and start services.

Run ``/usr/share/rbuilder/scripts/mint-admin user-add`` to create your
App Engine user account. Do not name the account "admin".

Create a non-root system user for development purposes, using ``useradd``. It
does not have to have the same name as the App Engine user created above.

Developer Setup
===============

This section details how to check out the App Engine source code, build it, and
reconfigure the running App Engine run out of the checkout instead of the
installed packages. It is not necessary to perform this step immediately; you
can come back to it after verifying initial operation of the App Engine
installation if you wish.

First, as root, create a directory in which to place the checkout. ::

    mkdir /srv/code
    chown myuser:myuser /srv/code

Then, as the non-root user, checkout the App Engine codebase from Github. ::

    sudo -u myuser -i
    cd /srv/code
    git clone https://github.com/sassoftware/appengine -b master
    ./appengine/multigit
    make -C appengine

Finally, as root, insert the newly-built checkout into the Python search path::

    make -C /srv/code/appengine install-pth

Reboot the App Engine to complete the initial setup.

rbuild Configuration
====================

**rbuild** is the primary command-line tool for interacting with an App Engine.

Switch to the development user by logging out and back in or using ``sudo -u
myuser -i``. Run ``rbuild config --ask``. You can accept the defaults when
present.

Run ``rbuild config --conaryrc --rmakerc`` to finish preparing the rbuild environment.

Example Project
===============

The following will create an example project with a CentOS minimal install and
some extra packages and build an image.

Create a project and branch to work in. Run ``rbuild create project`` and
give the following answers::

    Project name:           Example Project
    Project description:
    Unique name:            example
    Domain name:

Create a branch of the project using ``rbuild create branch``::

    Project name:           example
    Branch name:            1
    Branch description:
    Namespace:
    Platform:               1 (or whichever number corresponds to CentOS 6)

Now initialize the checkout with ``rbuild init example 1`` and ``cd
example-1/Development``.

Next create "image definitions", which describe which kind of images this
project will build. Run ``rbuild add imagedef vmwareImage x86_64`` to add a
VMware Workstation image output. For "Image name" give "vmware64", and leave
the rest of the answers at their defaults. To see what other image types are
available, see ``rbuild list imagetypes``.

Create a "group recipe" to describe which components will go into the image.
Run ``rbuild checkout group-example-appliance``, then edit
``group-example-appliance/group-example-appliance.recipe``. Set the "version"
variable to a non-empty string (e.g. "1"). Change "pass" at the end to the following::

    r.add("rsync")
    r.add("vim-enhanced")

Save and close the recipe, then run ``rbuild build groups`` and finally
``rbuild build images``. At the end of the image build, rbuild will print a url
which you can download to get your VMware image.
