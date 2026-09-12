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
    // Default cypress/included:13.17.0 bundles Node 22.13, too old for
    // cosmiconfig@10 (pulled in by @badeball/cypress-cucumber-preprocessor@28,
    // required for cypress@16 compatibility). Override to an image with a
    // newer bundled Node until the shared pipeline lib's own default catches up.
    cypressImage        : "cypress/included:16.0.0",
    defaultBranch      : "master",
    additionalDogus     : ['official/postgresql', 'official/usermgt', 'official/cas'],
])
com.cloudogu.ces.dogubuildlib.EcoSystem ecoSystem = pipe.ecoSystem

pipe.setBuildProperties()
pipe.addDefaultStages()

pipe.overrideStage('Setup') {
  ecoSystem.loginBackend('cesmarvin-setup')
  ecoSystem.setup([additionalDependencies: ['official/postgresql']])
}

pipe.run()
