#! /usr/bin/env groovy

////////
// Set this job as "parameterized build" and
// specify the following parameters.
//
// sshCredential (credential for logging into the following hosts)
// sshUser       (user for ssh remote login)
// remoteBinDir  (directory for storing scripts and configs)
// armv6Host     (native build host of armv6 packages)
// aarch64Host   (native build host of aarch64 packages)
// channelName   (Slack channel for notification use)
////////

node {
    stage('Checkout script files.') {
        checkout scm
        notifySlack(channelName, 'START')
    }
    stage('Set buildname based on date/time.') {
        sh "${WORKSPACE}/SetBuildName.sh"
        buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
    }
    stage('Update ports tree.') {
        sh "${WORKSPACE}/UpdateTree.sh"
    }

    stage('Build packages for amd64 architecture.') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh amd64 native ${buildName}"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'amd64', currentBuild.result)
        }
    }

    stage('Build packages for i386 architecture.') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh i386 native ${buildName}"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'i386', currentBuild.result)
        }
    }

    stage('Build packages for armv6 architecture. (Native building)') {
        def scriptName = 'BuildPackages.sh'
        def confName = 'local.conf'
        try {
            sshagent (credentials: [sshCredential]) {
                sh "ssh ${sshUser}@${armv6Host} mkdir -p ${remoteBinDir}"
                sh "scp ${WORKSPACE}/${scriptName} ${sshUser}@${armv6Host}:${remoteBinDir}"
                sh "scp ${WORKSPACE}/${confName} ${sshUser}@${armv6Host}:${remoteBinDir}"
                sh "ssh ${sshUser}@${armv6Host} ${remoteBinDir}/${scriptName} armv6 native ${buildName}"
                sh "ssh ${sshUser}@${armv6Host} rm -f ${remoteBinDir}/${scriptName} ${remoteBinDir}/${confName}"
                // Don't treat directory removal failure as stage failure
                sh "ssh ${sshUser}@${armv6Host} rmdir ${remoteBinDir} || echo ignore"
            }
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            sh "ssh ${sshUser}@${armv6Host} rm -f ${remoteBinDir}/${scriptName} ${remoteBinDir}/${confName}"
            sh "ssh ${sshUser}@${armv6Host} rmdir ${remoteBinDir} || echo ignore"
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'armv6 native', currentBuild.result)
        }
    }
    stage('Copy native-built packages to cross build working directory.') {
        try {
            sh "${WORKSPACE}/CopyPackages.sh armv6"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
        }
    }
    stage('Build packages for armv6 architecture. (Cross building)') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh armv6 cross ${buildName}"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'armv6 cross', currentBuild.result)
        }
    }
    stage('Sync armv6 native and cross-built package directories.') {
        try {
            sh "${WORKSPACE}/SyncNativeCrossPkgDirs.sh armv6"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
        }
    }

    stage('Build packages for aarch64 architecture. (Native building)') {
        def scriptName = 'BuildPackages.sh'
        def confName = 'local.conf'
        try {
            sshagent (credentials: [sshCredential]) {
                sh "ssh ${sshUser}@${aarch64Host} mkdir -p ${remoteBinDir}"
                sh "scp ${WORKSPACE}/${scriptName} ${sshUser}@${aarch64Host}:${remoteBinDir}"
                sh "scp ${WORKSPACE}/${confName} ${sshUser}@${aarch64Host}:${remoteBinDir}"
                sh "ssh ${sshUser}@${aarch64Host} ${remoteBinDir}/${scriptName} aarch64 native ${buildName}"
                sh "ssh ${sshUser}@${aarch64Host} rm -f ${remoteBinDir}/${scriptName} ${remoteBinDir}/${confName}"
                // Don't treat directory removal failure as stage failure
                sh "ssh ${sshUser}@${aarch64Host} rmdir ${remoteBinDir} || echo ignore"
            }
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            sh "ssh ${sshUser}@${aarch64Host} rm -f ${remoteBinDir}/${scriptName} ${remoteBinDir}/${confName}"
            sh "ssh ${sshUser}@${aarch64Host} rmdir ${remoteBinDir} || echo ignore"
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'aarch64 native', currentBuild.result)
        }
    }
    stage('Copy native-built packages to cross build working directory.') {
        try {
            sh "${WORKSPACE}/CopyPackages.sh aarch64"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
        }
    }
    stage('Build packages for aarch64 architecture. (Cross building)') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh aarch64 cross ${buildName}"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'aarch64 native', currentBuild.result)
        }
    }
    stage('Sync aarch64 native and cross-built package directories.') {
        try {
            sh "${WORKSPACE}/SyncNativeCrossPkgDirs.sh aarch64"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
        }
    }

    stage('Build packages for mips64 architecture. (Cross building)') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh mips64 cross ${buildName}"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'mips64 cross', currentBuild.result)
        }
    }

    stage('Clean up temporary files.') {
        cleanWs notFailBuild: true, patterns: [[pattern: 'poudriere.*', type: 'INCLUDE']]
    }
    stage('Sync built artifact with package server.') {
        try {
            sh "${WORKSPACE}/SyncPackages.sh"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
            currentBuild.result = 'FAILURE'
            notifySlack(channelName, 'sync', currentBuild.result)
        }
    }
    stage('Send notification to Slack.') {
        notifySlack(channelName, 'finally', currentBuild.result)
    }
}

def notifySlack(String channelName = '#general',
                String stageName = '',
                String buildStatus) {

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
