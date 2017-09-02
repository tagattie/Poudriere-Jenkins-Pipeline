#! groovy

node {
    stage('Checkout script files.') {
        checkout scm
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
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for i386 architecture.') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh i386 native ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for armv6 architecture. (Native building)') {
        try {
            def buildHost="sugarbush"
            def buildUser="root"
            sh "ssh ${buildUser}@${buildHost} /root/bin/BuildPackages.sh armv6 native ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Copy native-built packages to cross build working directory.') {
        try {
            sh "${WORKSPACE}/CopyPackages.sh armv6"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for armv6 architecture. (Cross building)') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh armv6 cross ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for aarch64 architecture. (Native building)') {
        try {
            def buildHost="tamarack"
            def buildUser="root"
            sh "ssh ${buildUser}@${buildHost} /root/bin/BuildPackages.sh aarch64 native ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Copy native-built packages to cross build working directory.') {
        try {
            sh "${WORKSPACE}/CopyPackages.sh aarch64"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for aarch64 architecture. (Cross building)') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh aarch64 cross ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for mips64 architecture. (Cross building)') {
        try {
            sh "${WORKSPACE}/BuildPackages.sh mips64 cross ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Clean up temporary files.') {
        cleanWs notFailBuild: true, patterns: [[pattern: 'poudriere.*', type: 'INCLUDE']]
    }
    stage('Sync built artifact with package server.') {
        try {
            sh "${WORKSPACE}/SyncPackages.sh"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Send notification to Slack.') {
        notifyBuild channelName: channelName, stageName: 'final', buildStatus: currentBuild.result
    }
}

def notifyBuild(String channelName = '#general',
                String stageName,
                String buildStatus = 'START') {

    if (buildStatus == 'START') {
        colorCode = '#BBBBBB' // grey
        statusString = 'started'
    }
    else if (buildStatus == 'SUCCESS') {
        colorCode = '#008800' // green
        statusString = 'finished successful'
    }
    else {
        colorCode = '#BB0000'
        statusString = 'finished failed'
    }

    def message = "Build ${stageName} ${statusString} - ${env.JOB_NAME} #${env.BUILD_NUMBER} (<${env.BUILD_URL}/console|Open>)"

    slackSend channel: channelName, color: colorCode, message: message
}
