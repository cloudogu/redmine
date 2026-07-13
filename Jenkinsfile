#!groovy
@Library([
        // renovate: datasource=github-tags depName=cloudogu/ces-build-lib
        'github.com/cloudogu/ces-build-lib@5.5.0',
        // DISABLED renovate: datasource=github-tags depName=cloudogu/dogu-build-lib
        'github.com/cloudogu/dogu-build-lib@fix/vagrant-race',
])
import com.cloudogu.ces.cesbuildlib.*
import com.cloudogu.ces.dogubuildlib.*

String doguName = "redmine"

node('sos-testing-preflight') {
    Git git = new Git(this, "cesmarvin")
    git.committerName = 'cesmarvin'
    git.committerEmail = 'cesmarvin@cloudogu.com'
    GitFlow gitflow = new GitFlow(this, git)
    GitHub github = new GitHub(this, git)
    Changelog changelog = new Changelog(this)
    timestamps {
        //noinspection GroovyAssignabilityCheck
        properties([
                buildDiscarder(logRotator(numToKeepStr: '10')),
                disableConcurrentBuilds(),
                parameters([
                        choice(
                                name: 'PipelineMode',
                                description: 'Which integration phases to run after static checks',
                                choices: ['Full', 'Classic', 'MultiNode'],
                                defaultValue: 'Full',
                        ),
                        booleanParam(
                                name: 'TestDoguUpgrade',
                                description: 'Test dogu upgrade from latest release or optionally from defined version below',
                                defaultValue: false,
                        ),
                        string(
                                name: 'OldDoguVersionForUpgradeTest',
                                description: 'Old Dogu version for the upgrade test (optional; e.g. 3.23.0-1)',
                                defaultValue: '',
                        ),
                        booleanParam(
                                name: 'EnableVideoRecording',
                                description: 'Enables cypress to record video of the integration tests.',
                                defaultValue: true,
                        ),
                        booleanParam(
                                name: 'EnableScreenshotRecording',
                                description: 'Enables cypress to take screenshots of failing integration tests.',
                                defaultValue: true,
                        ),
                        choice(
                                name: 'TrivySeverityLevels',
                                description: 'The levels to scan with trivy',
                                choices: [
                                        TrivySeverityLevel.CRITICAL,
                                        TrivySeverityLevel.HIGH_AND_ABOVE,
                                        TrivySeverityLevel.MEDIUM_AND_ABOVE,
                                        TrivySeverityLevel.ALL
                                ],
                                defaultValue: TrivySeverityLevel.HIGH_AND_ABOVE,
                        ),
                        choice(
                                name: 'TrivyStrategy',
                                description: 'Define whether the build should be unstable, fail or whether the error should be ignored if any vulnerability was found.',
                                choices: [
                                        TrivyScanStrategy.UNSTABLE,
                                        TrivyScanStrategy.FAIL,
                                        TrivyScanStrategy.IGNORE
                                ],
                                defaultValue: TrivyScanStrategy.UNSTABLE,
                        ),
                        string(
                                name: 'ClusterName',
                                description: 'Optional: Name of the multinode integration test cluster. A new instance gets created if this parameter is not supplied',
                                defaultValue: '',
                        ),
                        booleanParam(
                                name: 'KeepCluster',
                                description: 'Optional: If True, the cluster will not be deleted after the build execution',
                                defaultValue: false,
                        ),
                ])
        ])

        stage('Checkout') {
            checkout scm
        }

        stage('Lint') {
            lintDockerfile()
        }

        stage('Check Markdown Links') {
            Markdown markdown = new Markdown(this)
            markdown.check()
        }

        stage('Check Changelog') {
            // This check will skip on non-pull-request.
            checkChangelog()
            checkReleaseNotes()
        }

        stage('Shellcheck') {
            def fileList = sh(script: 'find ./resources/ -type f -regex .*\\.sh -print', returnStdout: true).trim()
            if (fileList) {
                fileList = '"' + fileList.trim().replaceAll('\n', '" "') + '"'
                shellCheck(fileList)
            } else {
                unstable(message: "ShellCheck called but no scripts found!")
            }
        }

        stage('Bats Tests') {
            Bats bats = new Bats(this, docker)
            bats.checkAndExecuteTests()
        }

        def branches = [failFast: false]

        if (params.PipelineMode in ['Full', 'Classic']) {
            EcoSystem ecoSystem = new EcoSystem(this, "gcloud-ces-operations-internal-packer", "jenkins-gcloud-ces-operations-internal")
            branches['Classic'] = {
                try {
                    stage('Provision') {
                        if (gitflow.isPreReleaseBranch()) {
                            sh "make prerelease_namespace"
                        }
                        ecoSystem.provision("/dogu", "n1-standard-4", 30)
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
                    }

                    stage('Trivy scan') {
                        ecoSystem.copyDoguImageToJenkinsWorker("/dogu")
                        Trivy trivy = new Trivy(this)
                        trivy.scanDogu(".", params.TrivySeverityLevels, params.TrivyStrategy)
                        trivy.saveFormattedTrivyReport(TrivyScanFormat.TABLE)
                        trivy.saveFormattedTrivyReport(TrivyScanFormat.JSON)
                        trivy.saveFormattedTrivyReport(TrivyScanFormat.HTML)
                    }

                    // TODO: the old pipe-build-lib pipeline had an "Archive Trivy" stage here that
                    // uploaded trivy/trivyReport.json to trivy.fsn1.your-objectstorage.com (creds:
                    // trivy-archive-s3-keys). Decide whether to port it back before this becomes the
                    // real pipeline, since it may feed a central vulnerability dashboard.

                    stage('Verify') {
                        ecoSystem.verify("/dogu")
                    }

                    stage('Integration Tests') {
                        ecoSystem.runCypressIntegrationTests([cypressImage     : "cypress/included:13.14.2",
                                                              enableVideo      : params.EnableVideoRecording,
                                                              enableScreenshots: params.EnableScreenshotRecording])
                    }

                    if (params.TestDoguUpgrade != null && params.TestDoguUpgrade) {
                        stage('Upgrade dogu') {
                            ecoSystem.purgeDogu(doguName)

                            if (params.OldDoguVersionForUpgradeTest != '' && !params.OldDoguVersionForUpgradeTest.contains('v')) {
                                println "Installing user defined version of dogu: " + params.OldDoguVersionForUpgradeTest
                                ecoSystem.installDogu("official/" + doguName + " " + params.OldDoguVersionForUpgradeTest)
                            } else {
                                println "Installing latest released version of dogu..."
                                ecoSystem.installDogu("official/" + doguName)
                            }
                            ecoSystem.startDogu(doguName)
                            ecoSystem.waitForDogu(doguName)
                            ecoSystem.upgradeDogu(ecoSystem)
                            ecoSystem.waitForDogu(doguName)
                            ecoSystem.waitUntilAvailable(doguName)
                        }

                        stage('Integration Tests - After Upgrade') {
                            ecoSystem.runCypressIntegrationTests([
                                    cypressImage     : "cypress/included:13.14.2",
                                    enableVideo      : params.EnableVideoRecording,
                                    enableScreenshots: params.EnableScreenshotRecording
                            ])
                        }
                    }

                    if (gitflow.isReleaseBranch()) {
                        String releaseVersion = git.getSimpleBranchName()

                        stage('Finish Release') {
                            gitflow.finishRelease(releaseVersion)
                        }

                        stage('Push Dogu to registry') {
                            ecoSystem.push("/dogu")
                        }

                        stage('Add Github-Release') {
                            github.createReleaseWithChangelog(releaseVersion, changelog)
                        }

                        // TODO: the old pipe-build-lib pipeline had a "Notify Webhook - Release" stage
                        // here that posted a release announcement (repo/version/changelog link) to a
                        // webhook. Decide whether to port it back so release notifications keep going out.
                    } else if (gitflow.isPreReleaseBranch()) {
                        stage('Push Prerelease Dogu to registry') {
                            ecoSystem.pushPreRelease("/dogu")
                        }
                    }
                } finally {
                    stage('Clean') {
                        ecoSystem.destroy()
                    }
                }
            }
        }

        if (params.PipelineMode in ['Full', 'MultiNode']) {
            // TODO: handle submodule checkout if redmine ever adds submodules
            MultiNodeEcoSystem mn = new MultiNodeEcoSystem(this, 'jenkins_workspace_gcloud_key', 'automatic_migration_coder_token', doguName)
            branches['MultiNode'] = {
                try {
                    // TODO: TestDoguUpgrade / OldDoguVersionForUpgradeTest are not handled in this
                    // MultiNode branch (the old pipe-build-lib MultinodeStages wired up an upgrade test
                    // here, installing the old version during MN-Setup). Currently this combination
                    // silently no-ops in MultiNode mode; only the Classic branch tests dogu upgrades.
                    stage('MN-Setup') {
                        timeout(time: 70, unit: 'MINUTES') {
                            mn.setup([
                                    clustername    : params.ClusterName,
                                    additionalDogus: ['official/postgresql'],
                                    nodeCount      : '1',
                            ])
                        }
                    }

                    stage('MN-Build') {
                        env.NAMESPACE = 'ecosystem'
                        env.RUNTIME_ENV = 'remote'
                        mn.build(doguName)
                    }

                    stage('MN-Wait for Dogu') {
                        mn.waitForDogu(doguName)
                    }

                    stage('MN-Verify') {
                        mn.verify(doguName)
                    }

                    stage('MN-Integration Tests') {
                        // TEMPORARY: Classic's EcoSystem.updateCypressConfiguration() writes
                        // integrationTests/cypress.env.json into this same shared workspace, and
                        // cypress.env.json outranks cypress.config.js's env values - so it can
                        // silently override MultiNodeEcoSystem's own AdminGroup patch (e.g. to
                        // "CesAdministrators" instead of "cesAdmin"). Remove it before running so
                        // MultiNode's own config wins. Exploratory fix - the real fix belongs in
                        // dogu-build-lib's MultiNodeEcoSystem.runCypressIntegrationTests().
                        sh "rm -f integrationTests/cypress.env.json"
                        mn.runCypressIntegrationTests([
                                cypressImage     : 'cypress/included:13.14.2',
                                enableVideo      : params.EnableVideoRecording,
                                enableScreenshots: params.EnableScreenshotRecording
                        ])
                    }
                } finally {
                    if (!params.KeepCluster) {
                        stage('MN-Clean') {
                            mn.destroy()
                        }
                    }
                }
            }
        }

        parallel(branches)
    }
}
