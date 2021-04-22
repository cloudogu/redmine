#!groovy
@Library(['github.com/cloudogu/ces-build-lib@1.47.0', 'github.com/cloudogu/dogu-build-lib@v1.2.0']) _
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*
import com.cloudogu.ces.zaleniumbuildlib.*

node('vagrant') {
    String doguName = "redmine"
    Git git = new Git(this, "cesmarvin")
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)

    timestamps{
        properties([
                // Keep only the last x builds to preserve space
                buildDiscarder(logRotator(numToKeepStr: '10')),
                // Don't run concurrent builds for a branch, because they use the same workspace directory
                disableConcurrentBuilds(),
                // Parameter to activate dogu upgrade test on demand
                parameters([
                    booleanParam(defaultValue: false, description: 'Test dogu upgrade from latest release or optionally from defined version below', name: 'TestDoguUpgrade'),
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
            shellCheck("./resources/startup.sh ./resources/post-upgrade.sh ./resources/pre-upgrade.sh ./resources/util.sh ./resources/upgrade-notification.sh")
        }

        try {

            stage('Provision') {
                ecoSystem.provision("/dogu");
            }

            stage('Setup') {
                ecoSystem.loginBackend('cesmarvin-setup')
                ecoSystem.setup([ additionalDependencies: [ 'official/postgresql' ] ])

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
            }

            stage('Verify') {
                ecoSystem.verify("/dogu")
            }

            stage('Integration tests') {
                println "cleaning up previous test results..."
                sh "rm -rf integrationTests/cypress/videos"
                sh "rm -rf integrationTests/cypress/screenshots"
                sh "rm -rf integrationTests/cypress-reports"

                try {
                    def runID = UUID.randomUUID().toString()
                    def reportName = "TEST-${runID}-[hash].xml"
                    def testArgs = "-q --headless --record false --reporter junit --reporter-options mochaFile=cypress-reports/${reportName}"
                    String externalIP = ecoSystem.externalIP
                    docker.image("cypress/included:7.1.0").inside("--ipc=host -v ${WORKSPACE}/integrationTests:/integrationTests -w /integrationTests -e XDG_CONFIG_HOME=/integrationTests -e YARN_CACHE_FOLDER=/integrationTests -e CYPRESS_BASE_URL=https://${externalIP} --entrypoint=''") {
                        sh "cd integrationTests && yarn install && cypress run ${testArgs}"
                    }
                }
                finally {
                    catchError {
                        println "archiving videos and screenshots from test execution..."
                        junit allowEmptyResults: true, testResults: 'integrationTests/cypress-reports/TEST-*.xml'
                        archiveArtifacts "integrationTests/cypress/videos/**/*.mp4"
                    }
                }
            }

            if (params.TestDoguUpgrade != null && params.TestDoguUpgrade){
                stage('Upgrade dogu') {
                    // Remove new dogu that has been built and tested above
                    ecoSystem.purgeDogu(doguName)

                    if (params.OldDoguVersionForUpgradeTest != '' && !params.OldDoguVersionForUpgradeTest.contains('v')){
                        println "Installing user defined version of dogu: " + params.OldDoguVersionForUpgradeTest
                        ecoSystem.installDogu("official/" + doguName + " " + params.OldDoguVersionForUpgradeTest)
                    } else {
                        println "Installing latest released version of dogu..."
                        ecoSystem.installDogu("official/" + doguName)
                    }
                    ecoSystem.startDogu(doguName)
                    ecoSystem.waitForDogu(doguName)
                    ecoSystem.upgradeDogu(ecoSystem)

                    // Wait for upgraded dogu to get healthy
                    ecoSystem.waitForDogu(doguName)
                }

                stage('Integration Tests - After Upgrade') {
                    println "cleaning up previous test results..."
                    sh "rm -rf integrationTests/cypress/videos"
                    sh "rm -rf integrationTests/cypress/screenshots"
                    sh "rm -rf integrationTests/cypress-reports"

                    try {
                        def runID = UUID.randomUUID().toString()
                        def reportName = "TEST-${runID}-[hash].xml"
                        def testArgs = "-q --headless --record false --reporter junit --reporter-options mochaFile=cypress-reports/${reportName}"
                        String externalIP = ecoSystem.externalIP
                        docker.image("cypress/included:7.1.0").inside("--ipc=host -v ${WORKSPACE}/integrationTests:/integrationTests -w /integrationTests -e XDG_CONFIG_HOME=/integrationTests -e YARN_CACHE_FOLDER=/integrationTests -e CYPRESS_BASE_URL=https://${externalIP} --entrypoint=''") {
                            sh "cd integrationTests && yarn install && cypress run ${testArgs}"
                        }
                    }
                    finally {
                        catchError {
                            println "archiving videos and screenshots from test execution..."
                            junit allowEmptyResults: true, testResults: 'integrationTests/cypress-reports/TEST-*.xml'
                            archiveArtifacts "integrationTests/cypress/videos/**/*.mp4"
                        }
                    }
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

                stage ('Add Github-Release'){
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
