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
////////

pipeline {
    agent any
    environment {
        // For debugging
        DO_UPDATE='y'
        DO_BUILD='y'
        DO_COPY='y'
        DO_SYNC='y'
        DRYRUN_UPDATE='y'
        DRYRUN_BUILD='y'
        DRYRUN_COPY='y'
        DRYRUN_SYNC='y'
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
//            checkout scm
                notifySlack(SLACKCHANNELNAME, '', 'START')
            }
        }

        stage('Update ports tree.') {
            when {
                environment name: 'DO_UPDATE', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/UpdateTree.sh"
            }
        }

        stage('Build packages for amd64 architecture.') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/${BUILDSCRIPT} amd64 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'amd64', 'FAILURE')
                }
            }
        }

        stage('Build packages for i386 architecture.') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/${BUILDSCRIPT} i386 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'i386', 'FAILURE')
                }
            }
        }

        stage('Build packages for armv6 architecture. (Native building)') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sshagent (credentials: [sshCredential]) {
                    sh "ssh ${sshUser}@${armv6Host} mkdir -p ${remoteBinDir}"
                    sh "scp ${WORKSPACE}/${BUILDSCRIPT} ${sshUser}@${armv6Host}:${remoteBinDir}"
                    sh "ssh ${sshUser}@${armv6Host} env WORKSPACE=${remoteBinDir} PORTSTREE=${PORTSTREE} DRYRUN_BUILD=${DRYRUN_BUILD} ${remoteBinDir}/${BUILDSCRIPT} armv6 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                    sh "ssh ${sshUser}@${armv6Host} rm -f ${remoteBinDir}/${BUILDSCRIPT}"
                    // Don't treat directory removal failure as stage failure
                    sh "ssh ${sshUser}@${armv6Host} rmdir ${remoteBinDir} || echo ignore"
                }
            }
            post {
                failure {
                    sh "ssh ${sshUser}@${armv6Host} rm -f ${remoteBinDir}/${BUILDSCRIPT} ${remoteBinDir}/poudriere.*"
                    sh "ssh ${sshUser}@${armv6Host} rmdir ${remoteBinDir} || echo ignore"
                    notifySlack(SLACKCHANNELNAME, 'armv6 native build', 'FAILURE')
                }
            }
        }
        stage('Copy armv6 natively-built packages to cross-build working directory.') {
            when {
                environment name: 'DO_COPY', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/CopyPackages.sh armv6"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'armv6 copy native -> cross', 'FAILURE')
                }
            }
        }
        stage('Build packages for armv6 architecture. (Cross building)') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/${BUILDSCRIPT} armv6 cross ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'armv6 cross', 'FAILURE')
                }
            }
        }
        stage('Sync armv6 native and cross-built package directories.') {
            when {
                environment name: 'DO_COPY', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/SyncNativeCrossPkgDirs.sh armv6"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'armv6 copy cross -> native', 'FAILURE')
                }
            }
        }

        stage('Build packages for aarch64 architecture. (Native building)') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sshagent (credentials: [sshCredential]) {
                    sh "ssh ${sshUser}@${aarch64Host} mkdir -p ${remoteBinDir}"
                    sh "scp ${WORKSPACE}/${BUILDSCRIPT} ${sshUser}@${aarch64Host}:${remoteBinDir}"
                    sh "ssh ${sshUser}@${aarch64Host} env WORKSPACE=${remoteBinDir} PORTSTREE=${PORTSTREE} DRYRUN_BUILD=${DRYRUN_BUILD} ${remoteBinDir}/${BUILDSCRIPT} aarch64 native ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
                    sh "ssh ${sshUser}@${aarch64Host} rm -f ${remoteBinDir}/${BUILDSCRIPT}"
                    // Don't treat directory removal failure as stage failure
                    sh "ssh ${sshUser}@${aarch64Host} rmdir ${remoteBinDir} || echo ignore"
                }
            }
            post {
                failure {
                    sh "ssh ${sshUser}@${aarch64Host} rm -f ${remoteBinDir}/${scriptName} ${remoteBinDir}/poudriere.*"
                    sh "ssh ${sshUser}@${aarch64Host} rmdir ${remoteBinDir} || echo ignore"
                    notifySlack(SLACKCHANNELNAME, 'aarch64 native', 'FAILURE')
                }
            }
        }
        stage('Copy aarch64 natively-built packages to cross-build working directory.') {
            when {
                environment name: 'DO_COPY', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/CopyPackages.sh aarch64"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'aarch64 copy native -> cross', 'FAILURE')
                }
            }
        }
        stage('Build packages for aarch64 architecture. (Cross building)') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/${BUILDSCRIPT} aarch64 cross ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'aarch64 cross', 'FAILURE')
                }
            }
        }
        stage('Sync aarch64 native and cross-built package directories.') {
            when {
                environment name: 'DO_COPY', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/SyncNativeCrossPkgDirs.sh aarch64"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'aarch64 copy cross -> native', 'FAILURE')
                }
            }
        }

        stage('Build packages for mips64 architecture. (Cross building)') {
            when {
                environment name: 'DO_BUILD', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/${BUILDSCRIPT} mips64 cross ${BUILDNAME} ${JAILNAMEPREFIX} ${PKGLISTDIR}"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'mips64 cross', 'FAILURE')
                }
            }
        }

        stage('Sync built artifact with package servering host.') {
            when {
                environment name: 'DO_SYNC', value: 'y'
            }
            steps {
                sh "${WORKSPACE}/SyncPackages.sh"
            }
            post {
                failure {
                    notifySlack(SLACKCHANNELNAME, 'sync', 'FAILURE')
                }
            }
        }
    }

    post {
            // always {
            //     // Clean up (= delete) workspace directory
            //     deleteDir()
            // }
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
                String buildStatus = 'START') {

    def colorCode, statusString

    if (buildStatus == 'START') {
        colorCode = '#BBBBBB' // grey
        statusString = 'started'
    }
    else if (buildStatus == 'SUCCESS') {
        colorCode = '#008800' // green
        statusString = 'finished successful'
    }
    else {
        colorCode = '#BB0000' // red
        statusString = 'finished failed'
    }

    def message = "Build ${stageName} ${statusString} - ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}console|Open>)"

    slackSend channel: channelName, color: colorCode, message: message
}
