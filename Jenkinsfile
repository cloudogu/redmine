#!groovy
@Library([
        // renovate: datasource=github-tags depName=cloudogu/ces-build-lib
        'github.com/cloudogu/ces-build-lib@5.6.0',
        // DISABLED renovate: datasource=github-tags depName=cloudogu/dogu-build-lib
        'github.com/cloudogu/dogu-build-lib@test/florian-changes-for-worker-update',
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
                                description: 'Which CES variation to run tests in',
                                choices: ['Both', 'Classic', 'MultiNode'],
                                defaultValue: 'Both',
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

        if (params.PipelineMode in ['Both', 'Classic']) {
            EcoSystem ecoSystem = new EcoSystem(this, "gcloud-ces-operations-internal-packer", "jenkins-gcloud-ces-operations-internal")
            branches['Classic'] = {
                try {
                    stage('Classic: Provision') {
                        if (gitflow.isPreReleaseBranch()) {
                            sh "make prerelease_namespace"
                        }
                        ecoSystem.provision("/dogu", "n1-standard-4", 30)
                    }

                    stage('Classic: Setup') {
                        ecoSystem.loginBackend('cesmarvin-setup')
                        ecoSystem.setup([additionalDependencies: ['official/postgresql']])
                    }

                    stage('Classic: Wait for dependencies') {
                        timeout(15) {
                            ecoSystem.waitForDogu("cas")
                            ecoSystem.waitForDogu("usermgt")
                            ecoSystem.waitForDogu("postgresql")
                        }
                    }

                    stage('Classic: Build') {
                        ecoSystem.build("/dogu")
                    }

                    stage('Classic: Trivy scan') {
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

                    stage('Classic: Verify') {
                        ecoSystem.verify("/dogu")
                    }

                    stage('Classic: Integration Tests') {
                        ecoSystem.runCypressIntegrationTests([cypressImage     : "cypress/included:13.14.2",
                                                              enableVideo      : params.EnableVideoRecording,
                                                              enableScreenshots: params.EnableScreenshotRecording])
                    }

                    if (params.TestDoguUpgrade != null && params.TestDoguUpgrade) {
                        stage('Classic: Upgrade dogu') {
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

                        stage('Classic: Integration Tests (Post-Upgrade)') {
                            ecoSystem.runCypressIntegrationTests([
                                    cypressImage     : "cypress/included:13.14.2",
                                    enableVideo      : params.EnableVideoRecording,
                                    enableScreenshots: params.EnableScreenshotRecording
                            ])
                        }
                    }

                    if (gitflow.isReleaseBranch()) {
                        String releaseVersion = git.getSimpleBranchName()

                        stage('Classic: Finish Release') {
                            gitflow.finishRelease(releaseVersion)
                        }

                        stage('Classic: Push Dogu to registry') {
                            ecoSystem.push("/dogu")
                        }

                        stage('Classic: Add Github-Release') {
                            github.createReleaseWithChangelog(releaseVersion, changelog)
                        }

                        // TODO: the old pipe-build-lib pipeline had a "Notify Webhook - Release" stage
                        // here that posted a release announcement (repo/version/changelog link) to a
                        // webhook. Decide whether to port it back so release notifications keep going out.
                    } else if (gitflow.isPreReleaseBranch()) {
                        stage('Classic: Push Prerelease Dogu to registry') {
                            ecoSystem.pushPreRelease("/dogu")
                        }
                    }
                } finally {
                    stage('Classic: Clean') {
                        ecoSystem.destroy()
                    }
                }
            }
        }

        if (params.PipelineMode in ['Both', 'MultiNode']) {
            // TODO: handle submodule checkout if redmine ever adds submodules
            // NOTE: MultiNode is being migrated from MultiNodeEcoSystem (Coder/GKE) to a local K3d
            // (K3s-in-Docker) cluster, since MultiNodeEcoSystem's admin-credential extraction from the
            // live cluster is broken (returns a Coder team identifier instead of the CES admin
            // username) and K3d takes admin credentials as static config instead. This migration is
            // scoped to redmine only for now; other dogus keep using MultiNodeEcoSystem.
            K3d k3d = new K3d(this, env.WORKSPACE, "${env.WORKSPACE}/k3d", env.PATH)
            String adminGroup = "CesAdministrators"
            String adminUsername = "ces-admin"
            String adminPassword = "Ecosystem2016!"
            branches['MultiNode'] = {
                try {
                    // TODO: TestDoguUpgrade / OldDoguVersionForUpgradeTest are not handled in this
                    // MultiNode branch (the old pipe-build-lib MultinodeStages wired up an upgrade test
                    // here, installing the old version during Setup stage). Currently this combination
                    // silently no-ops in MultiNode mode; only the Classic branch tests dogu upgrades.
                    stage('MultiNode: Setup') {
                        timeout(time: 15, unit: 'MINUTES') {
                            k3d.installKubectlManually()
                            k3d.installHelmManually()
                            k3d.startK3d()
                            k3d.setup([
                                    adminUsername         : adminUsername,
                                    adminPassword          : adminPassword,
                                    adminGroup             : adminGroup,
                                    additionalDependencies: ['official/postgresql']
                            ])
                        }
                    }

                    def doguImage
                    stage('MultiNode: Build') {
                        def doguJson = readJSON(file: 'dogu.json')
                        doguImage = k3d.buildAndPushToLocalRegistry(doguJson.Name, doguJson.Version)

                        String doguCrPath = "target/${doguName}-dogu-cr.yaml"
                        writeFile file: doguCrPath, text: """
apiVersion: k8s.cloudogu.com/v2
kind: Dogu
metadata:
  name: ${doguName}
  labels:
    dogu: ${doguName}
spec:
  name: ${doguJson.Name}
  version: ${doguJson.Version}
"""
                        k3d.installDogu(doguName, doguImage, doguCrPath)

                        // installDogu() patches the Deployment's container image to the pullable
                        // k3d-<registry>:<port> reference, but the k8s-dogu-operator reconciles the
                        // Deployment's image straight back to the dogu descriptor's
                        // k3d-<registry>.local:5000 reference shortly after - and that reference has
                        // no containerd registry config on the node at all (k3d's --registry-use only
                        // configures the k3d-<registry>:<port> host, not the .local:5000 variant), so
                        // containerd defaults to HTTPS and fails with "server gave HTTP response to
                        // HTTPS client" (confirmed via kubectl describe pod on a real run, and
                        // reproduced/verified locally with a throwaway k3d cluster). The imperative
                        // patch loses that race every time, leaving the pod stuck in ImagePullBackOff.
                        // Fix: give the node a containerd hosts.toml for the .local:5000 host too,
                        // mirroring the one k3d already generates for k3d-<registry>:<port>, pointing
                        // at the same registry via plain HTTP. containerd's config_path mechanism
                        // picks this up live, no k3s/containerd restart needed (verified locally).
                        String registryHost = "k3d-${k3d.getRegistryName()}"
                        String registryIp = sh(returnStdout: true, script: "docker inspect -f '{{ (index .NetworkSettings.Networks \"${registryHost}\").IPAddress }}' ${registryHost}").trim()
                        String certsDir = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d/${registryHost}.local:5000"
                        sh "docker exec ${registryHost}-server-0 mkdir -p '${certsDir}'"
                        sh """docker exec ${registryHost}-server-0 sh -c 'cat > "${certsDir}/hosts.toml" <<EOF
server = "http://${registryIp}:5000"

[host."http://${registryIp}:5000"]
  capabilities = ["pull", "resolve"]
EOF'"""
                    }

                    stage('MultiNode: Wait for Dogu') {
                        try {
                            k3d.waitForDeploymentRollout(doguName, 300, 30)
                        } catch (Exception e) {
                            // Diagnostics only, no behavior change: collectAndArchiveLogs() (used in
                            // Clean stage) captures "kubectl describe -l app=ces", which drops the Events
                            // section for multi-match label-selector describes - so past failures never
                            // showed the actual ImagePullBackOff/CrashLoop reason, only the end state.
                            // Dump a single-resource describe (which does include Events) plus recent
                            // cluster events to the console before re-throwing.
                            try {
                                String podName = k3d.kubectl("get pod --template '{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}'", true)
                                        .trim().split("\n").find { it.contains(doguName) }
                                if (podName) {
                                    echo k3d.kubectl("describe pod ${podName}", true)
                                    // kubectl logs without --previous only shows the currently running
                                    // attempt - if the container already crashed (e.g. Exit Code 1 with
                                    // a higher Restart Count), the log of the actual failed attempt is
                                    // otherwise never captured.
                                    try {
                                        echo k3d.kubectl("logs ${podName} --previous", true)
                                    } catch (Exception noPreviousLogs) {
                                        echo "No previous container log for ${podName}: ${noPreviousLogs}"
                                    }
                                    // The previous container log always shows redmine's own
                                    // wait_for_redmine_to_get_healthy() timing out on a 401 from its
                                    // own healthcheck request. redmine_cas's check_password? override
                                    // returns false unconditionally whenever a user has no auth_source
                                    // (true for the internal-only config-admin account) and
                                    // RedmineCas.local_user_enabled? is false - independent of whether
                                    // the password is actually correct. Read the exact credentials
                                    // doguctl is using from /proc/<pid>/cmdline (same technique as the
                                    // describe/logs diagnostics above) and check directly, inside the
                                    // running Rails process, whether that's what's happening - rather
                                    // than guessing further from outside.
                                    try {
                                        String probeScript = '''
PID=$(ps aux | grep "doguctl wait-for-http" | grep -v grep | awk "{print \\$1}")
if [ -z "$PID" ]; then
  echo "No running doguctl wait-for-http process found"
  exit 0
fi
tr "\\0" "\\n" < /proc/$PID/cmdline > /tmp/cmdline_args
AUTH_USER=$(awk "/^-u\\$/{getline; print; exit}" /tmp/cmdline_args)
AUTH_PASS=$(awk "/^-p\\$/{getline; print; exit}" /tmp/cmdline_args)
printf "%s" "$AUTH_USER" > /tmp/auth_user.txt
printf "%s" "$AUTH_PASS" > /tmp/auth_pass.txt
cat > /tmp/auth_check.rb <<RUBY_EOF
login = File.read("/tmp/auth_user.txt")
password = File.read("/tmp/auth_pass.txt")
u = User.find_by_login(login)
if u.nil?
  puts "user not found: #{login}"
else
  puts "login=#{u.login} status=#{u.status} admin=#{u.admin?} auth_source_id=#{u.auth_source_id.inspect} hashed_password_present=#{!u.hashed_password.to_s.empty?}"
  puts "RedmineCas.enabled?=#{RedmineCas.enabled?} RedmineCas.local_user_enabled?=#{RedmineCas.local_user_enabled?}"
  puts "Setting.rest_api_enabled?=#{Setting.rest_api_enabled?}"
  puts "check_password_result=#{u.check_password?(password)}"
end
RUBY_EOF
chown redmine:redmine /tmp/auth_check.rb /tmp/auth_user.txt /tmp/auth_pass.txt
echo "=== auth check via rails runner ==="
su - redmine -c "cd /usr/share/webapps/redmine && RAILS_ENV=production bin/rails runner /tmp/auth_check.rb"
echo "=== authenticated curl ==="
curl -s -o /dev/null -w "HTTP %{http_code}\\n" -u "${AUTH_USER}:${AUTH_PASS}" http://127.0.0.1:3000/redmine/extended_api/v1/settings
rm -f /tmp/auth_user.txt /tmp/auth_pass.txt
'''
                                        echo k3d.kubectl("exec ${podName} -- sh -c '${probeScript}'", true)
                                    } catch (Exception noAuthCheck) {
                                        echo "Failed to run auth check in ${podName}: ${noAuthCheck}"
                                    }
                                }
                                echo k3d.kubectl("get events --sort-by=.lastTimestamp", true)
                            } catch (Exception diagnosticFailure) {
                                echo "Failed to collect diagnostics: ${diagnosticFailure}"
                            }
                            throw e
                        }
                    }

                    stage('MultiNode: Verify') {
                        // Bespoke, redmine-only goss check: K3d has no verify()/goss helper (unlike
                        // EcoSystem.verify(), which shells into a Vagrant VM and runs "cesapp verify" -
                        // that doesn't exist for a k8s-deployed dogu). Downloads a static goss binary,
                        // copies it plus spec/goss/goss.yaml into the running pod, and runs it there.
                        String podName = k3d.kubectl("get pod --template '{{range .items}}{{.metadata.name}}{{\"\\n\"}}{{end}}'", true)
                                .trim().split("\n").find { it.contains(doguName) }
                        if (!podName) {
                            error "Could not find running pod for dogu ${doguName} to run goss verification against."
                        }

                        sh "curl -sSL -o goss https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 && chmod +x goss"
                        k3d.kubectl("cp goss ${podName}:/tmp/goss")
                        k3d.kubectl("cp spec/goss/goss.yaml ${podName}:/tmp/goss.yaml")

                        String verifyReport = k3d.kubectl("exec ${podName} -- /tmp/goss --gossfile /tmp/goss.yaml validate --format junit", true)
                        writeFile encoding: 'UTF-8', file: 'verify.xml', text: verifyReport
                        junit allowEmptyResults: true, testResults: 'verify.xml'
                        archiveArtifacts artifacts: 'verify.xml', allowEmptyArchive: true
                    }

                    stage('MultiNode: Integration Tests') {
                        // Cypress.runIntegrationTests(EcoSystem) can't be reused as-is - its parameter
                        // is statically typed to EcoSystem and K3d isn't one. Reuse what doesn't need an
                        // EcoSystem (config defaults, passwd file, pre/post-test hooks) and drive the
                        // actual cypress run inline, mirroring Cypress.runIntegrationTests().
                        Cypress cypress = new Cypress(this, [
                                cypressImage     : 'cypress/included:13.14.2',
                                enableVideo      : params.EnableVideoRecording,
                                enableScreenshots: params.EnableScreenshotRecording,
                                adminGroup       : adminGroup,
                                adminUsername    : adminUsername,
                                adminPassword    : adminPassword,
                        ])
                        cypress.preTestWork()

                        // Duplicates the one-liner K3d.assignExternalIP() uses internally - that field
                        // is private with no getter, and K3d can't be modified in this change.
                        String externalIP = sh(returnStdout: true, script: 'curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip').trim()
                        String passwdPath = cypress.writePasswd()

                        timeout(time: cypress.config.timeoutInMinutes, unit: 'MINUTES') {
                            String dockerArgs = "--ipc=host"
                            dockerArgs <<= " -e CYPRESS_BASE_URL=https://${externalIP}"
                            dockerArgs <<= " --entrypoint=''"
                            dockerArgs <<= " -v ${pwd()}/${passwdPath}:/etc/passwd:ro"
                            docker.image(cypress.config.cypressImage).inside(dockerArgs) {
                                def runID = UUID.randomUUID().toString()
                                String cypressRunArgs = "-q"
                                cypressRunArgs <<= " --headless"
                                cypressRunArgs <<= " --config screenshotOnRunFailure=" + cypress.config.enableScreenshots
                                cypressRunArgs <<= " --config video=" + cypress.config.enableVideo
                                cypressRunArgs <<= " --reporter junit"
                                cypressRunArgs <<= " --reporter-options mochaFile=cypress-reports/TEST-${runID}-[hash].xml"
                                cypressRunArgs <<= " --env AdminGroup='" + adminGroup.replace("'", "'\\''") + "'"
                                cypressRunArgs <<= " --env AdminUsername='" + adminUsername.replace("'", "'\\''") + "'"
                                cypressRunArgs <<= " --env AdminPassword='" + adminPassword.replace("'", "'\\''") + "'"
                                sh "cd integrationTests/ && rm -rf node_modules && yarn install && yarn cypress run ${cypressRunArgs}"
                            }
                        }

                        cypress.archiveVideosAndScreenshots()
                    }
                } finally {
                    stage('MultiNode: Clean') {
                        k3d.collectAndArchiveLogs()
                        if (!params.KeepCluster) {
                            k3d.deleteK3d()
                        }
                    }
                }
            }
        }

        parallel(branches)
    }
}
