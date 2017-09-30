#! /usr/bin/env groovy

////////
// Set this job as "parameterized build" and
// specify the following parameters.
//
// sshCredential (credential for logging into the following hosts)
// sshUser       (user for ssh remote login to native hosts)
//
// Parameters for debugging
// doUpdate      (If y, execute update stage)
// doBuild       (If y, build packages for architectures)
// doSync        (If y, sync artifacts with pkg serving server)
// dryRunUpdate  (If y, dry run update stage)
// dryRunBuild   (If y, dry run build stage)
// dryRunCopy    (If y, dry run copy stage)
// dryRunSync    (If y, dry run sync stage)
// verboseBuild  (If y, update stage verbose output)
// verboseCopy   (If y, copy stage verbose output)
// verboseSync   (If y, sync stage verbose output)
////////

pipeline {
    agent any
    environment {
        // Configuration file (JSON)
        CONFIG='Config.json'
        // Scripts
        UPDATESCRIPT='UpdateTree.sh'
        BUILDSCRIPT='BuildPackages.sh'
        COPYN2CSCRIPT='CopyPackages.sh'
        COPYC2NSCRIPT='SyncNativeCrossPkgDirs.sh'
        SYNCSCRIPT='SyncPackages.sh'
        // Build name based on current date/time
        BUILDNAME=sh (
            returnStdout: true,
            script: 'date "+%Y-%m-%d_%Hh%Mm%Ss"'
        ).trim()
        // ^-- here, new line is accepted
        // FreeBSD versions (used as a part of ABI string)
        MAJORREL=sh (
            returnStdout: true,
            script: $/uname -r|awk -F- '{print $$1}'|awk -F. '{print $$1}'/$).trim()
        // ^-- here, new line causes an error, why???
        MINORREL=sh (
            returnStdout: true,
            script: $/uname -r|awk -F- '{print $$1}'|awk -F. '{print $$2}'/$).trim()
        // Jail name prefix which poudriere will work with
        // Actual jail names will be releng111amd64, releng111i386, etc.
        JAILNAMEPREFIX="releng${MAJORREL}${MINORREL}"
        // Suffix for jail name for cross building
        CROSSSUFFIX="x"
    }
    // parameters {
    // }
    // triggers {
    // }
    stages {
        stage('Checkout Jenkinsfile and other files.') {
            steps {
                timestamps {
                    checkout scm
                    archiveArtifacts 'Jenkinsfile'
                    archiveArtifacts '*.sh'
                }
            }
        }

        stage('Read config file and do some preparations.') {
            steps {
                timestamps {
                    script {
                        config = readJSON(file: "${CONFIG}")
                        buildSteps = config.archs.collectEntries(
                            {
                                [it, transformIntoBuildStep(it)]
                            }
                        )
                        // Here and there this global variable is abused to
                        // store results of each step (SUCCESS or FAILURE) to
                        // determine whether the entire process should be
                        // 'SUCCESS' or 'FAILURE'
                        currentBuild.description += " SUCCESS(config)"
                        notifySlack("${config.slack.channel}", 'Build', 'START')
                    }
                }
            }
        }

        stage('Update ports tree.') {
            when {
                environment name: 'doUpdate', value: 'y'
            }
            steps {
                timestamps {
                    sh "${WORKSPACE}/${UPDATESCRIPT} ${config.poudriere.portsTree}"
                }
            }
            post {
                failure {
                    timestamps {
                        notifySlack("${config.slack.channel}", 'Update Ports Tree', "${currentBuild.currentResult}")
                    }
                }
            }
        }

        stage('Build packages.') {
            when {
                environment name: 'doBuild', value: 'y'
            }
            steps {
                parallel(buildSteps)
            }
            post {
                failure {
                    timestamps {
                        notifySlack("${config.slack.channel}", 'Build pkgs', "${currentBuild.currentResult}")
                    }
                }
            }
        }

        stage('Sync built artifact with package servering host.') {
            when {
                environment name: 'doSync', value: 'y'
            }
            steps {
                timestamps {
                    script {
                        try {
                            def Map archs = config.archs
                            def archlist = ""
                            archs.each {
                                if (it.getValue().get('enabled') == true) {
                                    echo "${it.getValue().get('arch')}"
                                    arch = "${it.getValue().get('arch')}"
                                    if (it.getValue().get('cross') == true) {
                                        echo "${it.getValue().get('cross')}"
                                        arch += "${CROSSSUFFIX}"
                                    }
                                    archlist += "${arch} "
                                }
                            }
                            sh "${WORKSPACE}/${SYNCSCRIPT} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree} ${config.sync.user} ${config.sync.host} ${config.sync.port} ${config.sync.baseDir} ${archlist}"
                            currentBuild.description += ' SUCCESS(sync)'
                        } catch (Exception e) {
                            currentBuild.description += ' FAILURE(sync)'
                            notifySlack("${config.slack.channel}", 'Sync pkgs', 'FAILURE')
                        }
                    }
                }
            }
            post {
                failure {
                    timestamps {
                        notifySlack("${config.slack.channel}", 'Sync pkgs', "${currentBuild.currentResult}")
                    }
                }
            }
        }

        stage('Determine entire build is successful or failed.') {
            steps {
                timestamps {
                    script {
                        if (currentBuild.description.contains('FAILURE')) {
                            currentBuild.result = 'FAILURE'
                        } else {
                            currentBuild.result = 'SUCCESS'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            timestamps {
                // Clean up (= delete) workspace directory
                // deleteDir()
                echo "currentBuild.number: ${currentBuild.number}"
                echo "currentBuild.result: ${currentBuild.result}"
                echo "currentBuild.currentResult: ${currentBuild.currentResult}"
                echo "currentBuild.displayName: ${currentBuild.displayName}"
                echo "currentBuild.description: ${currentBuild.description}"
                echo "currentBuild.id: ${currentBuild.id}"
                echo "currentBuild.timeInMillis: ${currentBuild.timeInMillis}"
                echo "currentBuild.startTimeInMillis: ${currentBuild.startTimeInMillis}"
                echo "currentBuild.duration: ${currentBuild.duration}"
                echo "currentBuild.durationString: ${currentBuild.durationString}"
            }
        }
        success {
            timestamps {
                notifySlack("${config.slack.channel}", 'Build', 'SUCCESS')
            }
        }
        failure {
            timestamps {
                notifySlack("${config.slack.channel}", 'Build', 'FAILURE')
            }
        }
    }
}

def transformIntoBuildStep(String archName) {
    return {
        timestamps {
            script {
                def arch = "${config.archs."${archName}".arch}"

                // First try to cross-build packages (when enabled)
                if ("${config.archs."${archName}"?.enabled}" == "true" &&
                    "${config.archs."${archName}"?.cross}" == "true") {
                    def buildtype = 'cross'

                    try {
                        sh "${WORKSPACE}/${BUILDSCRIPT} ${arch} ${buildtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}"
                        currentBuild.description += " SUCCESS(${arch} ${buildtype})"
                    } catch (Exception e) {
                        currentBuild.description += " FAILURE(${arch} ${buildtype})"
                        notifySlack("${config.slack.channel}", "Build ${arch} (${buildtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}${CROSSSUFFIX}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                    }
                }

                // Copy cross packages -> native working directory
                // (Only when both buildtypes are enabled)
                if ("${config.archs."${archName}"?.cross}" == "true" &&
                    "${config.archs."${archName}"?.native}" == "true") {
                    try {
                        sh "${WORKSPACE}/${COPYC2NSCRIPT} ${arch} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree}"
                        currentBuild.description += " SUCCESS(${arch} cross->native)"
                    } catch (Exception e) {
                        currentBuild.description += " FAILURE(${arch} cross->native)"
                        notifySlack("${config.slack.channel}", "Copy ${arch} cross->native dir", 'FAILURE')
                    }
                }

                // Next try to native-build packages (when enabled)
                if ("${config.archs."${archName}"?.enabled}" == "true" &&
                    "${config.archs."${archName}"?.native}" == "true") {
                    def buildtype = 'native'
                    def nativeHost = "${config.archs."${archName}".nativeHost}"
                    def nativeHostBinDir = "${config.archs."${archName}".nativeHostBinDir}"

                    try {
                        sshagent (credentials: [sshCredential]) {
                            sh """
ssh ${sshUser}@${nativeHost} mkdir -p ${nativeHostBinDir}
scp ${WORKSPACE}/\${BUILDSCRIPT} ${sshUser}@${nativeHost}:${nativeHostBinDir}
ssh ${sshUser}@${nativeHost} \\
    env WORKSPACE=${nativeHostBinDir} PORTSTREE=${config.poudriere.portsTree} dryRunBuild=${dryRunBuild} verboseBuild=${verboseBuild} ${nativeHostBinDir}/\${BUILDSCRIPT} ${arch} ${buildtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}; \\
    rm -f ${nativeHostBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${nativeHostBinDir} || echo ignore
"""
                            currentBuild.description += " SUCCESS(${arch} ${buildtype})"
                        }
                    } catch (Exception e) {
                        currentBuild.description += " FAILURE(${arch} ${buildtype})"
                        sh """
ssh ${sshUser}@${nativeHost} \\
    rm -f ${nativeHostBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${nativeHostBinDir} || echo ignore
"""
                        notifySlack("${config.slack.channel}", "Build ${arch} (${buildtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}armv6-${config.poudriere.portsTree}&build=${BUILDNAME}")
                    }
                }

                // Sync native and cross package directories
                // (Only when both buildtypes are enabled)
                if ("${config.archs."${archName}"?.cross}" == "true" &&
                    "${config.archs."${archName}"?.native}" == "true") {
                    try {
                        sh "${WORKSPACE}/${COPYN2CSCRIPT} ${arch} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree}"
                        currentBuild.description += " SUCCESS(${arch} native->cross)"
                    } catch (Exception e) {
                        currentBuild.description += " FAILURE(${arch} native->cross)"
                        notifySlack("${config.slack.channel}", "Sync ${arch} cross to native dir", 'FAILURE')
                    }
                }
            }
        }
    }
}

def notifySlack(String channelName = '#jenkins',
                String stageName = '',
                String buildStatus,
                String url = "${env.BUILD_URL}console") {

    def colorCode, statusString

    if (buildStatus == 'START') {
        colorCode = '#BBBBBB' // grey
        statusString = 'started'
    }
    else if (buildStatus == 'SUCCESS') {
        colorCode = '#008800' // green
        statusString = 'successful'
    }
    else if (buildStatus == 'FAILURE') {
        colorCode = '#BB0000' // red
        statusString = 'failed'
    }
    else {
        colorCode = '#000000' // black
        statusString = 'unknown'
    }

    def message = "${stageName} ${statusString} - ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${url}|Open>)"

    slackSend channel: channelName, color: colorCode, message: message
}
