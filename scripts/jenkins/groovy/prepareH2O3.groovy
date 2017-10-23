def call(final String mode, final String nodeLabel) {

  // Archive scripts so we don't have to do additional checkouts when changing node
  archiveArtifacts artifacts: "h2o-3/scripts/jenkins/groovy/*", allowEmptyArchive: false

  // Load build script and execute it
  def buildH2O3 = load('h2o-3/scripts/jenkins/groovy/buildH2O3.groovy')
  buildH2O3()

  def buildConfig = load('h2o-3/scripts/jenkins/groovy/buildConfig.groovy')
  def commitMessage = sh(script: 'cd h2o-3 && git log -1 --pretty=%B', returnStdout: true).trim()
  buildConfig.initialize(mode, nodeLabel, commitMessage, detectChanges())
  return buildConfig
}

def detectChanges() {
  sh 'cd h2o-3 && git fetch --no-tags --progress https://github.com/h2oai/h2o-3 +refs/heads/master:refs/remotes/origin/master'
  def mergeBaseSHA = sh(script: "cd h2o-3 && git merge-base HEAD origin/master", returnStdout: true).trim()
  def changes = sh(script: "cd h2o-3 && git diff --name-only ${mergeBaseSHA}", returnStdout: true).trim().tokenize('\n')

  def changesMap = [
    py: false,
    r: false,
    js: false,
    java: false
  ]

  for (change in changes) {
    if (change.startsWith('h2o-py/') || change == 'h2o-bindings/bin/gen_python.py') {
      changesMap['py'] = true
    } else if (change.startsWith('h2o-r/') ||  change == 'h2o-bindings/bin/gen_R.py') {
      changesMap['r'] = true
    } else if (change.endsWith('.md')) {
      // no need to run any tests if only .md files are changed
    } else {
      markAllForRun(changesMap)
    }
  }

  return [
    py: true,
    r: true,
    js: false,
    java: false
  ]
}

def markAllForRun(map) {
  map.each { k,v ->
    map[k] = true
  }
}

return this
