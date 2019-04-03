#!/bin/bash

#           RHN Classic to RHSM
#             Install package: subscription-manager subscription-manager-migration subscription-manager-migration-data
#             Run script rhn-migrate-classic-to-rhsm
#              *maybe with rhn-migrate-classic-to-rhsm --serverurl=rhnsat.srv.volvo.com (login required)
#             Verify with oo-admin-yum-validator
#           create new puppet.conf,
#           subscription-manager unregister
#           download katello certificates for Satellite 6 capsule
#           register host to capsule with correct activation-keys
#           run puppet agent
#           register result on server & remote location

### Variable declaration

RHNFILE1="/etc/yum/pluginconf.d/rhnplugin.conf"
RHNFILE2="/etc/yum/pluginconf.d/refresh-packagekit.conf"
RHSMFILE1="/etc/yum/pluginconf.d/product-id.conf"
RHSMFILE2="/etc/yum/pluginconf.d/subscription-manager.conf"
CAPSULE="segotl3523.srv.volvo.com"
SLA=$(grep SUPPORTLEVEL /var/log/puppet_configgroups.txt|cut -f2 -d"=")
declare -i OSMAJ
OSMAJ=$(cut -f7 -d" " /etc/redhat-release|cut -f1 -d".")
HOSTFQDN=$(hostname -f)
if [ $SLA = "PREMIUM" ]; then
  ENV="KT_HCL_shared_lce_puppet_prod_cv_puppet_prod_10"
elif [ $SLA = "BASIC" ]; then
   ENV="KT_HCL_shared_lce_puppet_qa_cv_puppet_qa_9"
elif [ $SLA = "STANDARD" ]; then
  ENV="KT_HCL_shared_lce_puppet_dev_cv_puppet_dev_8"
fi
HOSTENV="KT_HCL_shared_lce_puppet_$ENV"
PUPPETCONF="

[main]
vardir = /var/lib/puppet
logdir = /var/log/puppet
rundir = /var/run/puppet
ssldir = \$vardir/ssl

[agent]
pluginsync      = true
report          = true
ignoreschedules = true
daemon          = false
ca_server       = segotl2596.srv.volvo.com
certname        = $HOSTFQDN
environment     = $HOSTENV
server          = $CAPSULE

"
LOGFILE="/var/tmp/migration_sat5to6_$(date '+%Y%M%d').log"

# Redirect to logfile
exec > $LOGFILE 2>&1
#####
# install subscription-manager if it isnt installed to use instead of rhn_reg
if ! rpm -q subscription-manager > /dev/null 2>&1
  yum -y install subscription-manager
fi
yum -y install subscription-manager-migration subscription-manager-migration-data

# Remove RHN CLASSIC
# Disable RHN plugins
if grep -q "^enabled = 1" $RHNFILE1; then sed -i 's/enabled=1/enabled=0/g' $RHNFILE1;fi
if grep -q "^enabled = 1" $RHNFILE2; then sed -i 's/enabled=1/enabled=0/g' $RHNFILE2;fi
# Enable RHSM plugins
if grep -q "^enabled = 0" $RHSMFILE1; then  sed -i 's/enabled=0/enabled=1/g' $RHSMFILE1;fi
if grep -q "^enabled = 0" $RHSMFILE2; then  sed -i 's/enabled=0/enabled=1/g' $RHSMFILE2;fi
chkconfig rhsmcertd off
service rhsmcertd stop
yum clean all
rm -rf /var/cache/yum
mv /etc/sysconfig/rhn/systemid /etc/sysconfig/rhn/rhnclassic.systemid

# Reregister host to Satellite 6 capsule
subscription-manager unregister
subscription-manager clean
wget --no-check-certificate https://$CAPSULE/pub/katello-ca-consumer-latest.noarch.rpm
rpm -ivh katello-ca-consumer-latest.noarch.rpm

subscription-manager register --name=$HOSTFQDN --org="HCL_shared" --activationkey=ak-auto,ak-lcs_6month_rhel$OSMAJ --force
# Enable additional repos
if [[ $OSMAJ = 6 ]]; then
  subscription-manager repos --enable rhel-6-server-rpms --enable rhel-6-server-supplementary* --enable rhel-6-server-rh-common* --enable rhel-6-server-optional* rhel-6-server-satellite-tools-6.2-rpms
elif [[ $OSMAJ = 7 ]]; then
  subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-supplementary* --enable rhel-7-server-rh-common* --enable rhel-7-server-optional*  --enable rhel-7-server-extras* --enable rhel-7-server-satellite-tools-6.2-rpms
fi
# Verify subscription status
SUBSCRIPTION_STATUS=$(subscription-manager list|awk '/^Status:/{ print $2}')
SUBSCRIPTIONS_CONSUMED=$(subscription-manager list --consumed|egrep "^Subscription Name:|^Active:")
YUMREPOS=$(yum repolist)
if [ "$SUBSCRIPTION_STATUS" = "Subscribed"; then
 echo "NOTIFY 2 logfile"
fi

# Puppet configuration & registration
cp /etc/puppet/puppet.conf /etc/puppet/puppet.conf.bak.classic
cat > /etc/puppet/puppet.conf << EOF
$PUPPETCONF
EOF

[[ -d /var/lib/puppet/ssl/ ]] && rm -rf /var/lib/puppet/ssl/ > /dev/null 2>&1
puppet agent -t --onetime --tags no_such_tag --waitforcert 30 --no-daemonize

# Get server out of build mode
# /usr/bin/wget --quiet --output-document=/dev/null --no-check-certificate <%= foreman_url %>
