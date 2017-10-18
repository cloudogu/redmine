#!groovy

// todo
// - setup output

// required plugins
// - http://wiki.jenkins-ci.org/display/JENKINS/HTML+Publisher+Plugin

node('vagrant') {

    properties([
            // Keep only the last x builds to preserve space
            buildDiscarder(logRotator(numToKeepStr: '10')),
            // Don't run concurrent builds for a branch, because they use the same workspace directory
            disableConcurrentBuilds()
    ])

    stage('Checkout') {
            checkout scm
        dir ('ecosystem') {
            git branch: 'develop', url: 'https://github.com/cloudogu/ecosystem'
        }
    }

    try {

        stage('Provision') {
            timeout(5) {
                writeVagrantConfiguration()
                //sh 'rm -f setup.staging.json setup.json'
                sh 'vagrant up'
            }
        }

        stage('Setup') {
            // TODO new credentials for setup, because new backend
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'cesmarvin-setup', usernameVariable: 'TOKEN_ID', passwordVariable: 'TOKEN_SECRET']]) {
                    sh "vagrant ssh -c \"sudo cesapp login ${env.TOKEN_ID} ${env.TOKEN_SECRET}\""
                }
                writeSetupStagingJSON()
                sh 'vagrant ssh -c "sudo mv /dogu/setup.staging.json /etc/ces/setup.staging.json"'
                sh 'vagrant ssh -c "sudo mv /etc/ces/setup.staging.json /etc/ces/setup.json"'
                sh 'vagrant ssh -c "while sudo pgrep -u root ces-setup > /dev/null; do sleep 1; done"'
                sh 'vagrant ssh -c "sudo journalctl -u ces-setup -n 100"'
            }
        }

        stage('Wait for dependencies') {
            timeout(15) {
                // TODO wait for all
                sh 'vagrant ssh -c "sudo cesapp healthy --wait --timeout 600 --fail-fast cas"'
            }
        }

        stage('Build') {
            sh 'vagrant ssh -c "sudo cesapp build /dogu"'
        }

        stage('Verify') {
            sh 'vagrant ssh -c "sudo cesapp verify /dogu"'
            // TODO create attach unit test results 
        }

    } finally {
        stage('Clean') {
            sh 'vagrant destroy -f'
        }
    }

}

String getCesIP() {
    // log into vagrant vm and get the ip from the eth1, which should the configured private network
    sh "vagrant ssh -c \"ip addr show dev eth1\" | grep 'inet ' | awk '{print \$2}' | awk -F'/' '{print \$1}' > vagrant.ip"
    return readFile('vagrant.ip').trim()
}

String containerIP(container) {
    sh "docker inspect -f {{.NetworkSettings.IPAddress}} ${container.id} > container.ip"
    return readFile('container.ip').trim()
}

void writeVagrantConfiguration() {
    //adjust the vagrant config for local-execution as needed for the integration tests

    writeFile file: 'Vagrantfile', text: """

    Vagrant.configure("2") do |config|
    
    config.vm.box = "cloudogu/ecosystem-basebox"
    config.vm.hostname = "ces"
    config.vm.box_version = "0.5.1"

    # Mount ecosystem and local dogu
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder "ecosystem", "/vagrant"
    config.vm.synced_folder ".", "/dogu"
    
    # Auto correct ssh, so parallel builds are possible
    config.vm.network "forwarded_port", guest: 22, host: 2222, id: 'ssh', auto_correct: true
    config.vm.network "private_network", type: "dhcp"

    config.vm.provision "shell",
    inline: "mkdir /etc/ces && echo 'vagrant' > /etc/ces/type && /vagrant/install.sh"

    config.vm.provider "virtualbox" do |v|
        v.memory = 3072
        # v.cpus = 2
    end
  end
"""
}

void writeSetupStagingJSON() {
    //configure setup
    //      - to install all Dogus
    //      - to work in embedded mode
    //      - have an admin as 'admin/adminpw'

//"fqdn":"${getCesIP()}"

    writeFile file: 'setup.staging.json', text: """
{
  "token":{
    "ID":"",
    "Secret":"",
    "Completed":true
  },
  "region":{
    "locale":"en_US.utf8",
    "timeZone":"Europe/Berlin",
    "completed":true
  },
  "naming":{
    "fqdn":"<<ip>>",
    "hostname":"ces",
    "domain":"ces.local",
    "certificateType":"selfsigned",
    "certificate":"",
    "certificateKey":"",
    "relayHost":"mail.ces.local",
    "completed":true
  },
  "dogus":{
    "defaultDogu":"cockpit",
    "install":[
      "official/registrator",
      "official/ldap",
      "official/cas",
      "official/nginx",
      "official/postfix",
      "official/postgresql"
    ],
    "completed":true
  },
  "admin":{
    "username":"admin",
    "mail":"admin@cloudogu.com",
    "password":"adminpw",
    "adminGroup":"CesAdministrators",
    "adminMember":true,
    "confirmPassword":"adminpw",
    "completed":true
  },
  "userBackend":{
    "port":"389",
    "useUserConnectionToFetchAttributes":true,
    "dsType":"embedded",
    "attributeID":"uid",
    "attributeFullname":"cn",
    "attributeMail":"mail",
    "attributeGroup":"memberOf",
    "searchFilter":"(objectClass=person)",
    "host":"ldap",
    "completed":true
  },
  "unixUser":{
    "Name":"",
    "Password":""
  },
  "registryConfig": {
  }
}"""
}