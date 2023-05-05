#!groovy
@Library(['github.com/cloudogu/ces-build-lib@1.64.2', 'github.com/cloudogu/dogu-build-lib@v2.1.0']) _
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*
import com.cloudogu.ces.zaleniumbuildlib.*

node('vagrant') {
    String doguName = "redmine"
    String testPluginName = "redmine_noop_plugin"
    String testPluginRepoName = "redmine-noop-plugin"
    String testPluginVersion = "0.0.1"

    Git git = new Git(this, "cesmarvin")
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)
    Markdown markdown = new Markdown(this, "3.11.0")
    Trivy trivy = new Trivy(this, ecoSystem)

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
                        choice(name: 'TrivyScanLevels', choices: [TrivyScanLevel.CRITICAL, TrivyScanLevel.HIGH, TrivyScanLevel.MEDIUM, TrivyScanLevel.ALL], description: 'The levels to scan with trivy'),
                        choice(name: 'TrivyStrategy', choices: [TrivyScanStrategy.UNSTABLE, TrivyScanStrategy.FAIL, TrivyScanStrategy.IGNORE], description: 'Define whether the build should be unstable, fail or whether the error should be ignored if any vulnerability was found.'),

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
            shellCheck("./resources/startup.sh ./resources/post-upgrade.sh ./resources/pre-upgrade.sh ./resources/util.sh ./resources/upgrade-notification.sh ./resources/default-config.sh ./resources/util.sh ./resources/delete-plugin.sh")
        }

        stage('Check markdown links') {
            markdown.check()
        }


        try {
            stage('Bats Tests') {
                Bats bats = new Bats(this, docker)
                bats.checkAndExecuteTests()
            }

            stage('Provision') {
                prepareTestPlugin(testPluginName, testPluginVersion, testPluginRepoName)
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
            parallel(
                "trivy-scan": {
                    stage('Trivy scan') {
                       parallel({"html-report": trivy.scanDogu("/dogu", TrivyScanFormat.HTML, params.TrivyScanLevels, params.TrivyStrategy)})
                       parallel({"json-report": trivy.scanDogu("/dogu", TrivyScanFormat.JSON, params.TrivyScanLevels, params.TrivyStrategy)})
                       parallel({"plain-report": trivy.scanDogu("/dogu", TrivyScanFormat.PLAIN, params.TrivyScanLevels, params.TrivyStrategy)})
                    }
                },
                "verify-dogu": {
                    stage('Verify') {
                        ecoSystem.verify("/dogu")
                    }
                }
            )
            stage('Integration tests') {
                runIntegrationTests(ecoSystem, "-e TAGS='not (@after_plugin_deletion or @UpgradeTest)'")

                deletePlugin(ecoSystem, testPluginName)
                restartAndWait(ecoSystem)

                runIntegrationTests(ecoSystem, "-e TAGS='@after_plugin_deletion and not @UpgradeTest'")
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
                    runIntegrationTests(ecoSystem, "-e TAGS='not @after_plugin_deletion'")
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

def prepareTestPlugin(String name, String version, String repoName="") {
    if (repoName == "") {
        repoName = name
    }
    String archiveName = "v${version}_${name}.tar.gz"

    sh "mkdir -p ${WORKSPACE}/testplugins/${name}"
    sh "wget -O ${archiveName} https://github.com/cloudogu/${repoName}/archive/v${version}.tar.gz"

    sh "tar xfz ${archiveName} --strip-components=1 -C ${WORKSPACE}/testplugins/${name}"
    sh "rm ${archiveName}"
}

static def installTestPlugin(EcoSystem ecoSystem, String name) {
    ecoSystem.vagrant.ssh "sudo mkdir -p /var/lib/ces/redmine/volumes/plugins/${name}"
    ecoSystem.vagrant.ssh "sudo cp -r /dogu/testplugins/${name} /var/lib/ces/redmine/volumes/plugins/"
}

def runIntegrationTests(EcoSystem ecoSystem, String additionalCypressArgs) {
    ecoSystem.runCypressIntegrationTests([
            cypressImage         : "cypress/included:8.7.0",
            enableVideo          : params.EnableVideoRecording,
            enableScreenshots    : params.EnableScreenshotRecording,
            additionalCypressArgs: "${additionalCypressArgs}"
    ])
}
