#!groovy
@Library([
  'pipe-build-lib',
  'ces-build-lib',
  'dogu-build-lib'
]) _

def pipe = new com.cloudogu.sos.pipebuildlib.DoguPipe(this, [
    doguName           : 'redmine',
    shellScripts       : ['''
                          resources/startup.sh
                          resources/post-upgrade.sh
                          resources/pre-upgrade.sh
                          resources/util.sh
                          resources/upgrade-notification.sh
                          resources/default-config.sh
                          resources/update-password-policy.sh
                          resources/util.sh
                          resources/delete-plugin.sh
                          '''],
    dependencies       : ['cas', 'usermgt', 'postgresql'],
    doBatsTests        : true,
    runIntegrationTests: true,
    cypressImage       : "cypress/included:13.14.2",
    defaultBranch      : "master",
    additionalDogus     : ['official/postgresql', 'official/usermgt', 'official/cas'],
    additionalComponents: ['postgresql', 'usermgt', 'cas']
])
com.cloudogu.ces.dogubuildlib.EcoSystem ecoSystem = pipe.ecoSystem

pipe.setBuildProperties()
pipe.addDefaultStages()

pipe.overrideStage('MS-Setup') {

def defaultSetupConfig = [
                clustername           : pipe.script.params.ClusterName,
                additionalDogus       : ['official/postgresql', 'official/usermgt', 'official/cas'],
                additionalComponents  : [],
                nodeCount             : pipe.nodeCount
            ]

            pipe.additionalDogus.each { d ->
                if (!defaultSetupConfig.additionalDogus.contains(d)) {
                    defaultSetupConfig.additionalDogus << d
                }
            }

            pipe.additionalComponents.each { c ->
                if (!defaultSetupConfig.additionalComponents.contains(c)) {
                    defaultSetupConfig.additionalComponents << c
                }
            }

            if (pipe.script.params.TestDoguUpgrade) {
                if (pipe.script.params.OldDoguVersionForUpgradeTest?.trim() &&
                    !pipe.script.params.OldDoguVersionForUpgradeTest.contains('v')) {
                    pipe.script.echo "Installing user-defined version of dogu: ${pipe.script.params.OldDoguVersionForUpgradeTest}"
                    defaultSetupConfig.additionalDogus << "${pipe.namespace}/${pipe.doguName}@${pipe.script.params.OldDoguVersionForUpgradeTest}"
                } else {
                    pipe.script.echo 'Installing latest released version of dogu...'
                    defaultSetupConfig.additionalDogus << "${pipe.namespace}/${pipe.doguName}"
                    }
            }

            pipe.multiNodeEcoSystem.setup(defaultSetupConfig)
}

pipe.overrideStage('Setup') {
  ecoSystem.loginBackend('cesmarvin-setup')
  ecoSystem.setup([additionalDependencies: ['official/postgresql']])
}

pipe.run()
