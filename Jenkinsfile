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
    cypressImage       : "cypress/included:13.14.2"
])
com.cloudogu.ces.dogubuildlib.EcoSystem ecoSystem = pipe.ecoSystem

pipe.setBuildProperties()
pipe.addDefaultStages()
pipe.overrideStage('Setup') {
  ecoSystem.loginBackend('cesmarvin-setup')
  ecoSystem.setup([additionalDependencies: ['official/postgresql']])
}

pipe.run()
