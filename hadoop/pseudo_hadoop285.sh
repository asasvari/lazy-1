#!/bin/sh
apt update -y
# Set up SSH for passwordless login
apt install -y openssh-server
apt install -y openssh-client
mkdir /var/run/sshd
chmod 0755 /var/run/sshd
ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa
/usr/bin/ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -C '' -N ''
/usr/bin/ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -C '' -N ''
nohup /usr/sbin/sshd -D&
cat $HOME/.ssh/id_rsa.pub  > $HOME/.ssh/authorized_keys
USER=$(id -u -n)

# Downloads Hadoop 2.8.5 and configures to  run it on a single-node in a pseudo-distributed mode 

wget https://archive.apache.org/dist/hadoop/core/hadoop-2.8.5/hadoop-2.8.5.tar.gz
tar xf hadoop-2.8.5.tar.gz
cd hadoop-2.8.5

cat >etc/hadoop/hdfs-site.xml <<ENDL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
   </property>
</configuration>
ENDL

cat >etc/hadoop/core-site.xml <<ENDL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
  <property>
    <name>hadoop.proxyuser.$USER.hosts</name>
    <value>*</value>
  </property>
  <property>
    <name>hadoop.proxyuser.$USER.groups</name>
    <value>*</value>
  </property>
</configuration>
ENDL

cat >etc/hadoop/mapred-site.xml <<ENDL
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
ENDL

cat >etc/hadoop/yarn-site.xml<<ENDL
<?xml version="1.0"?>
<!--
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. See accompanying LICENSE file.
-->

<!-- Site specific YARN configuration properties -->
<configuration> 
        <property>
                <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
                <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        </property>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
        </property>
        <property>
                <name>yarn.log-aggregation-enable</name>
                <value>true</value>
        </property>
        <property>
                <name>yarn.nodemanager.delete.debug-delay-sec</name>
                <value>100000</value>
        </property>


        <property>
                <description>Where to aggregate logs to.</description>
                <name>yarn.nodemanager.remote-app-log-dir</name>
                <value>/tmp/logs</value>
        </property>
</configuration>
ENDL

# Format namenode and start hadoop
ssh-keyscan -t rsa,dsa localhost,0.0.0.0 2>&1 >> ~/.ssh/known_hosts # doing it here to make sure sshd has been started
export JAVA_HOME=/opt/java/openjdk/
export PATH=/hadoop-2.8.5/bin/:/hadoop-2.8.5/sbin/:$PATH

sed -i '1i export JAVA_HOME=/opt/java/openjdk/' ./etc/hadoop/hadoop-env.sh
sed -i '1i #!/bin/env bash' ./etc/hadoop/hadoop-env.sh

hdfs namenode -format
start-dfs.sh
start-yarn.sh

# Hadoop things
hdfs dfs -mkdir -p /user/$USER
mkdir -p /$USER/input
cp /hadoop-2.8.5/etc/hadoop/*.xml /$USER/input
hdfs dfs -put -f /$USER/input
hadoop jar /hadoop-2.8.5/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.8.5.jar grep input output 'dfs[a-z.]+'
hdfs dfs -ls /user/$USER/output/
