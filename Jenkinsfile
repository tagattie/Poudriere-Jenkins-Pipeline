#! /usr/bin/env groovy

////////
// Set this job as "parameterized build" and
// specify the following parameters.
//
// sshCredential (credential for logging into the following hosts)
// sshUser       (user for ssh remote login to native hosts)
// remoteBinDir  (directory for storing scripts and configs)
// armv6Host     (native build host of armv6 packages)
// aarch64Host   (native build host of aarch64 packages)
// syncUser      (user for ssh remote login to pkg serving host)
// syncHost      (pkg serving host)
// syncPort      (port for ssh remote login to pkg serving host)
// syncBase      (base directory for storing packages)
// poudriereUrl  (URL of poudriere build logs)
//
// Parameters for debugging
// doUpdate      (If y, execute update stage)
// doBuild       (If y, build packages for architectures)
// doCopy        (If y, copy native->cross, cross->native packages)
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
        // Script for package building
        BUILDSCRIPT='BuildPackages.sh'
        // Ports tree name which poudriere will work on
        PORTSTREE='default'
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
        // Directory where lists of packages to be built reside
        PKGLISTDIR='/usr/local/etc/poudriere.d'
        // Base directory where built packages are stored
        PKGBASEDIR='/var/poudriere/data/packages'
        // List of architectures for which packages are built
        ////
        //// NOTE: Add postfix "x" to archname for cross compiling
        ////       (i.e. where you specified -x option
        ////       when creating the jail)
        ////
        ARCHLIST='amd64 i386 armv6x aarch64x mips64x'
        // Channel name for Slack notification
        SLACKCHANNELNAME='#jenkins'
    }
    // parameters {
    // }
    // triggers {
    // }
    stages {
        stage('Checkout Jenkinsfile and other files.') {
            steps {
                checkout scm
                archiveArtifacts 'Jenkinsfile'
                archiveArtifacts '*.sh'
                notifySlack(SLACKCHANNELNAME, '', 'START')
            }
        }

        stage('Update ports tree.') {
            when {
                environment name: 'doUpdate', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/UpdateTree.sh"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'stage Update Ports Tree', "${currentBuild.currentResult}")
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
                        script {
                            try {
                                sh "${WORKSPACE}/${BUILDSCRIPT} amd64 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Build amd64 Packages', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}amd64-${PORTSTREE}&build=${BUILDNAME}")
                            }
                        }
                    },
                    'i386 packages': {
                        script {
                            try {
                                sh "${WORKSPACE}/${BUILDSCRIPT} i386 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Build i386 Packages', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}i386-${PORTSTREE}&build=${BUILDNAME}")
                            }
                        }
                    },
                    'armv6 packages': {
                        script {
                            // Build packages for armv6 (Native building)
                            try {
                                sshagent (credentials: [sshCredential]) {
                                    sh """
ssh ${sshUser}@${armv6Host} mkdir -p ${remoteBinDir}
scp ${WORKSPACE}/\${BUILDSCRIPT} ${sshUser}@${armv6Host}:${remoteBinDir}
ssh ${sshUser}@${armv6Host} \\
    env WORKSPACE=${remoteBinDir} PORTSTREE=${PORTSTREE} dryRunBuild=${dryRunBuild} verboseBuild=${verboseBuild} ${remoteBinDir}/\${BUILDSCRIPT} armv6 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}; \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                }
                            } catch (Exception e) {
                                sh """
ssh ${sshUser}@${armv6Host} \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                notifySlack(SLACKCHANNELNAME, 'stage Build armv6 Packages (Native)', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}armv6-${PORTSTREE}&build=${BUILDNAME}")
                            }
                            // Copy armv6 native packages -> cross working directory.
                            try {
                                sh "${WORKSPACE}/CopyPackages.sh armv6"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Copy armv6 Native -> Cross Directory', 'FAILURE')
                            }
                            // Build packages for armv6 (Cross building)
                            try {
                                sh "${WORKSPACE}/${BUILDSCRIPT} armv6 cross ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Build armv6 Packages (Cross)', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}amrv6x-${PORTSTREE}&build=${BUILDNAME}")
                            }
                            // Sync armv6 cross packages -> native directory.
                            try {
                                sh "${WORKSPACE}/SyncNativeCrossPkgDirs.sh armv6"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Sync armv6 Cross -> Native Directory', 'FAILURE')
                            }
                        }
                    },
                    'aarch64 packages': {
                        script {
                            // Build packages for aarch64 (Native building)
                            try {
                                sshagent (credentials: [sshCredential]) {
                                    sh """
ssh ${sshUser}@${aarch64Host} mkdir -p ${remoteBinDir}
scp ${WORKSPACE}/\${BUILDSCRIPT} ${sshUser}@${aarch64Host}:${remoteBinDir}
ssh ${sshUser}@${aarch64Host} \\
    env WORKSPACE=${remoteBinDir} PORTSTREE=${PORTSTREE} dryRunBuild=${dryRunBuild} verboseBuild=${verboseBuild} ${remoteBinDir}/\${BUILDSCRIPT} aarch64 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}; \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                }
                            } catch (Exception e) {
                                sh """
ssh ${sshUser}@${aarch64Host} \\
    rm -f ${remoteBinDir}/\${BUILDSCRIPT}; \\
    rmdir ${remoteBinDir} || echo ignore
"""
                                notifySlack(SLACKCHANNELNAME, 'stage Build aarch64 Packages (Native)', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}aarch64-${PORTSTREE}&build=${BUILDNAME}")
                            }
                            // Copy aarch64 native packages -> cross working directory.
                            try {
                                sh "${WORKSPACE}/CopyPackages.sh aarch64"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Copy aarch64 Native -> Cross Directory', 'FAILURE')
                            }
                            // Build packages for aarch64 (Cross building)
                            try {
                                sh "${WORKSPACE}/${BUILDSCRIPT} aarch64 cross ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Build aarch64 Packages (Cross)', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}aarch64x-${PORTSTREE}&build=${BUILDNAME}")
                            }
                            // Sync aarch64 cross packages -> native directory.
                            try {
                                sh "${WORKSPACE}/SyncNativeCrossPkgDirs.sh aarch64"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Sync aarch64 Cross -> Native Directory', 'FAILURE')
                            }
                        }
                    },
                    'mips64 packages': {
                        script {
                            try {
                                sh "${WORKSPACE}/${BUILDSCRIPT} mips64 cross ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                            } catch (Exception e) {
                                notifySlack(SLACKCHANNELNAME, 'stage Build mips64 Packages (Cross)', 'FAILURE', "${poudriereUrl}?mastername=${JAILNAMEPREFIX}mips64-${PORTSTREE}&build=${BUILDNAME}")
                            }
                        }
                    }
                )
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'stage Build', "${currentBuild.currentResult}")
                }
            }
        }

        stage('Sync built artifact with package servering host.') {
            when {
                environment name: 'doSync', value: 'y'
            }
            steps {
                script {
                    try {
                        sh "${WORKSPACE}/SyncPackages.sh"
                    } catch (Exception e) {
                        notifySlack(SLACKCHANNELNAME, 'stage Sync', 'FAILURE')
                    }
                }
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'stage Sync', "${currentBuild.currentResult}")
                }
            }
        }
    }

    post {
        always {
            // Clean up (= delete) workspace directory
            deleteDir()
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
        success {
            notifySlack(SLACKCHANNELNAME, '', 'SUCCESS')
        }
        failure {
            notifySlack(SLACKCHANNELNAME, '', 'FAILURE')
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

    def message = "Build ${stageName} ${statusString} - ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${url}|Open>)"

    slackSend channel: channelName, color: colorCode, message: message
}
