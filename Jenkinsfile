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

        stage('Read config file.') {
            steps {
                timestamps {
                    script {
                        config = readJSON(file: "${CONFIG}")
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
                parallel(
                    'amd64 packages': {
                        timestamps {
                            script {
                                if ("${config.archs.amd64?.enabled}" == "true") {
                                    def arch = "${config.archs.amd64.arch}"
                                    def archtype = 'native'
                                    try {
                                        sh "${WORKSPACE}/${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch})"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch})"
                                        notifySlack("${config.slack.channel}", "Build ${arch} pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                }
                            }
                        }
                    },
                    'i386 packages': {
                        timestamps {
                            script {
                                if ("${config.archs.i386?.enabled}" == "true") {
                                    def arch = "${config.archs.i386.arch}"
                                    def archtype = 'native'
                                    try {
                                        sh "${WORKSPACE}/${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch})"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch})"
                                        notifySlack("${config.slack.channel}", "Build ${arch} pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                }
                            }
                        }
                    },
                    'armv6 packages': {
                        timestamps {
                            script {
                                if ("${config.archs.armv6?.enabled}" == "true" &&
                                    "${config.archs.armv6?.native}" == "true") {
                                    def arch = "${config.archs.armv6.arch}"
                                    def archtype = 'native'
                                    def remoteHost = "${config.archs.armv6.nativeHost}"
                                    def remoteBinDir = "${config.archs.armv6.nativeBinDir}"
                                    // Build packages for armv6 (Native building)
                                    try {
                                        sshagent (credentials: [sshCredential]) {
                                            sh """
ssh ${sshUser}@${remoteHost} mkdir -p ${remoteBinDir}
scp ${WORKSPACE}/\${BUILDSCRIPT} ${sshUser}@${remoteHost}:${remoteBinDir}
ssh ${sshUser}@${armv6Host} \\
    env WORKSPACE=${remoteBinDir} PORTSTREE=${config.poudriere.portsTree} dryRunBuild=${dryRunBuild} verboseBuild=${verboseBuild} ${remoteBinDir}/\${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.json.pkgListDir} ${config.poudriere.portsTree}; \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                            currentBuild.description += " SUCCESS(${arch} ${archtype})"
                                        }
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} ${archtype})"
                                        sh """
ssh ${sshUser}@${remoteHost} \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                        notifySlack("${config.slack.channel}", "Build ${arch} (${archtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}armv6-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                    // Copy armv6 native packages -> cross working directory.
                                    try {
                                        sh "${WORKSPACE}/${COPYN2CSCRIPT} ${arch} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} native->cross)"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} native->cross)"
                                        notifySlack("${config.slack.channel}", "Copy ${arch} native to cross dir", 'FAILURE')
                                    }
                                }
                                if ("${config.archs.armv6?.enabled}" == "true" &&
                                    "${config.archs.armv6?.cross}" == "true") {
                                    def arch = "${config.archs.armv6.arch}"
                                    def archtype = 'cross'
                                    // Build packages for armv6 (Cross building)
                                    try {
                                        sh "${WORKSPACE}/${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} ${archtype})"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} ${archtype})"
                                        notifySlack("${config.slack.channel}", "Build ${arch} (${archtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}${CROSSSUFFIX}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                    // Sync armv6 cross packages -> native directory.
                                    try {
                                        sh "${WORKSPACE}/${COPYC2NSCRIPT} ${arch} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} cross->native)"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} cross->native)"
                                        notifySlack("${config.slack.channel}", "Sync ${arch} cross to native dir", 'FAILURE')
                                    }
                                }
                            }
                        }
                    },
                    'aarch64 packages': {
                        timestamps {
                            script {
                                if ("${config.archs.aarch64?.enabled}" == "true" &&
                                    "${config.archs.aarch64?.native}" == "true") {
                                    def arch = "${config.archs.aarch64.arch}"
                                    def archtype = 'native'
                                    def remoteHost = "${config.archs.aarch64.nativeHost}"
                                    def remoteBinDir = "${config.archs.aarch64.nativeBinDir}"
                                    // Build packages for aarch64 (Native building)
                                    try {
                                        sshagent (credentials: [sshCredential]) {
                                            sh """
ssh ${sshUser}@${remoteHost} mkdir -p ${remoteBinDir}
scp ${WORKSPACE}/\${BUILDSCRIPT} ${sshUser}@${remoteHost}:${remoteBinDir}
ssh ${sshUser}@${remoteHost} \\
    env WORKSPACE=${remoteBinDir} PORTSTREE=${config.poudriere.portsTree} dryRunBuild=${dryRunBuild} verboseBuild=${verboseBuild} ${remoteBinDir}/\${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}; \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                            currentBuild.description += " SUCCESS(${arch} ${archtype})"
                                        }
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} ${archtype})"
                                        sh """
ssh ${sshUser}@${remoteHost} \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                        notifySlack("${config.slack.channel}", "Build ${arch} (${archtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                    // Copy aarch64 native packages -> cross working directory.
                                    try {
                                        sh "${WORKSPACE}/${COPYN2CSCRIPT} ${arch} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} native->cross)"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} native->cross)"
                                        notifySlack("${config.slack.channel}", "Copy ${arch} native to cross dir", 'FAILURE')
                                    }
                                }
                                if ("${config.archs.aarch64?.enabled}" == "true" &&
                                    "${config.archs.aarch64?.cross}" == "true") {
                                    def arch = "${config.archs.aarch64.arch}"
                                    def archtype = 'cross'
                                    // Build packages for aarch64 (Cross building)
                                    try {
                                        sh "${WORKSPACE}/${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} ${archtype})"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} ${archtype})"
                                        notifySlack("${config.slack.channel}", "Build ${arch} (${archtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}${CROSSSUFFIX}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                    // Sync aarch64 cross packages -> native directory.
                                    try {
                                        sh "${WORKSPACE}/${COPYC2NSCRIPT} ${arch} ${config.poudriere.pkgBaseDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} cross->native)"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} cross->native)"
                                        notifySlack("${config.slack.channel}", "Sync ${arch} cross to native dir", 'FAILURE')
                                    }
                                }
                            }
                        }
                    },
                    'mips64 packages': {
                        timestamps {
                            script {
                                if ("${config.archs.mips64?.enabled}" == "true" &&
                                    "${config.archs.mips64?.cross}" == "true") {
                                    def arch = "${config.archs.mips64.arch}"
                                    def archtype = 'cross'
                                    try {
                                        sh "${WORKSPACE}/${BUILDSCRIPT} ${arch} ${archtype} ${BUILDNAME} ${JAILNAMEPREFIX} ${config.poudriere.pkgListDir} ${config.poudriere.portsTree}"
                                        currentBuild.description += " SUCCESS(${arch} ${archtype})"
                                    } catch (Exception e) {
                                        currentBuild.description += " FAILURE(${arch} ${archtype})"
                                        notifySlack("${config.slack.channel}", "Build ${arch} (${archtype}) pkgs", 'FAILURE', "${config.poudriere.urlBase}?mastername=${JAILNAMEPREFIX}${arch}${CROSSSUFFIX}-${config.poudriere.portsTree}&build=${BUILDNAME}")
                                    }
                                }
                            }
                        }
                    }
                )
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
                            sh "${WORKSPACE}/${SYNCSCRIPT} ${archlist}"
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
