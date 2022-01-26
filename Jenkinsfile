#!groovy
@Library(['github.com/cloudogu/ces-build-lib@v1.48.0', 'github.com/cloudogu/dogu-build-lib@v1.5.1']) _
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*
import com.cloudogu.ces.zaleniumbuildlib.*

node('vagrant') {
    String doguName = "redmine"
    String testPluginName = "redmine_noop_plugin"
    String testPluginVersion = "0.0.1"
    Git git = new Git(this, "cesmarvin")
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)

    timestamps {
        properties([
                // Keep only the last x builds to preserve space
                buildDiscarder(logRotator(numToKeepStr: '10')),
                // Don't run concurrent builds for a branch, because they use the same workspace directory
                disableConcurrentBuilds(),
                // Parameter to activate dogu upgrade test on demand
                parameters([
                        booleanParam(defaultValue: false, description: 'Test dogu upgrade from latest release or optionally from defined version below', name: 'TestDoguUpgrade'),
                        booleanParam(defaultValue: true, description: 'Enables cypress to record video of the integration tests.', name: 'EnableVideoRecording'),
                        booleanParam(defaultValue: true, description: 'Enables cypress to take screenshots of failing integration tests.', name: 'EnableScreenshotRecording'),
                        string(defaultValue: '', description: 'Old Dogu version for the upgrade test (optional; e.g. 4.1.0-3)', name: 'OldDoguVersionForUpgradeTest'),
                ])
        ])

        EcoSystem ecoSystem = new EcoSystem(this, "gcloud-ces-operations-internal-packer", "jenkins-gcloud-ces-operations-internal")

        stage('Checkout') {
            checkout scm
        }

        stage('Lint') {
            lintDockerfile()
        }

        stage('Shell-Check') {
            shellCheck("./resources/startup.sh ./resources/post-upgrade.sh ./resources/pre-upgrade.sh ./resources/util.sh ./resources/upgrade-notification.sh ./resources/create-admin.sh ./resources/default-config.sh ./resources/remove-user.sh ./resources/util.sh ./resources/delete-plugin.sh")
        }

        try {
            stage('Shell tests') {
                executeShellTests()
            }

            stage('Provision') {
                prepareTestPlugin(testPluginName, testPluginVersion)
                ecoSystem.provision("/dogu");
            }

            stage('Setup') {
                ecoSystem.loginBackend('cesmarvin-setup')
                ecoSystem.setup([additionalDependencies: ['official/postgresql']])

            }

            stage('Wait for dependencies') {
                timeout(15) {
                    ecoSystem.waitForDogu("cas")
                    ecoSystem.waitForDogu("usermgt")
                    ecoSystem.waitForDogu("postgresql")
                }
            }

            stage('Build') {
                ecoSystem.build("/dogu")
                installTestPlugin(ecoSystem, testPluginName)
            }

            stage('Verify') {
                ecoSystem.verify("/dogu")
            }

            stage('Integration tests') {
                runTests("-e TAGS='not (@after_plugin_deletion and @UpgradeTest)'")

                deletePlugin(ecoSystem, testPluginName)
                restartAndWait(ecoSystem)

                runTests("-e TAGS='@after_plugin_deletion and not @UpgradeTest'")
            }

            if (params.TestDoguUpgrade != null && params.TestDoguUpgrade) {
                stage('Upgrade dogu') {
                    // Remove new dogu that has been built and tested above
                    ecoSystem.purgeDogu(doguName)

                    if (params.OldDoguVersionForUpgradeTest != '' && !params.OldDoguVersionForUpgradeTest.contains('v')) {
                        println "Installing user defined version of dogu: " + params.OldDoguVersionForUpgradeTest
                        ecoSystem.installDogu("official/" + doguName + " " + params.OldDoguVersionForUpgradeTest)
                    } else {
                        println "Installing latest released version of dogu..."
                        ecoSystem.installDogu("official/" + doguName)
                    }
                    installTestPlugin(ecoSystem, testPluginName)
                    ecoSystem.startDogu(doguName)
                    ecoSystem.waitForDogu(doguName)
                    ecoSystem.upgradeDogu(ecoSystem)

                    // Wait for upgraded dogu to get healthy
                    ecoSystem.waitForDogu(doguName)
                    ecoSystem.waitUntilAvailable(doguName)
                }

                stage('Integration Tests - After Upgrade') {
                    // Run integration tests again to verify that the upgrade was successful
                    runTests("-e TAGS='not @after_plugin_deletion'")
                }
            }

            if (gitflow.isReleaseBranch()) {
                String releaseVersion = git.getSimpleBranchName();

                stage('Finish Release') {
                    gitflow.finishRelease(releaseVersion)
                }

                stage('Push Dogu to registry') {
                    ecoSystem.push("/dogu")
                }

                stage('Add Github-Release') {
                    github.createReleaseWithChangelog(releaseVersion, changelog)
                }
            }
        } finally {
            stage('Clean') {
                ecoSystem.destroy()
            }
        }
    }
}

static def restartAndWait(EcoSystem ecoSystem) {
    ecoSystem.vagrant.ssh "sudo docker restart redmine"
    ecoSystem.waitForDogu("redmine")
}

static def deletePlugin(EcoSystem ecoSystem, String name) {
    ecoSystem.vagrant.ssh "sudo cesapp command redmine delete-plugin ${name} --force"
}

def prepareTestPlugin(String name, String version) {
    String archiveName = "v${version}_${name}.tar.gz"

    sh "mkdir -p ${WORKSPACE}/testplugins/${name}"
    sh "wget -O ${archiveName} https://github.com/cloudogu/${name}/archive/v${version}.tar.gz"

    sh "tar xfz ${archiveName} --strip-components=1 -C ${WORKSPACE}/testplugins/${name}"
    sh "rm ${archiveName}"
}

static def installTestPlugin(EcoSystem ecoSystem, String name) {
    ecoSystem.vagrant.ssh "sudo mkdir -p /var/lib/ces/redmine/volumes/plugins/${name}"
    ecoSystem.vagrant.ssh "sudo cp -r /dogu/testplugins/${name}/* /var/lib/ces/redmine/volumes/plugins/"
}

def runTests(String additionalCypressArgs) {
    ecoSystem.runCypressIntegrationTests([
            cypressImage         : "cypress/included:8.7.0",
            enableVideo          : params.EnableVideoRecording,
            enableScreenshots    : params.EnableScreenshotRecording,
            additionalCypressArgs: "${additionalCypressArgs}"
    ])
}

def executeShellTests() {
    def bats_base_image = "bats/bats"
    def bats_custom_image = "cloudogu/bats"
    def bats_tag = "1.2.1"

    def batsImage = docker.build("${bats_custom_image}:${bats_tag}", "--build-arg=BATS_BASE_IMAGE=${bats_base_image} --build-arg=BATS_TAG=${bats_tag} ./unitTests")
    try {
        sh "mkdir -p target"
        sh "mkdir -p testdir"

        batsContainer = batsImage.inside("--entrypoint='' -v ${WORKSPACE}:/workspace -v ${WORKSPACE}/testdir:/usr/share/webapps") {
            sh "make unit-test-shell-ci"
        }
    } finally {
        junit allowEmptyResults: true, testResults: 'target/shell_test_reports/*.xml'
    }
}
