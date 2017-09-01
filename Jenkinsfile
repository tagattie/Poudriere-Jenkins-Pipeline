#! groovy

node {
    stage('Checkout script files.') {
        checkout scm
    }
    stage('Set buildname based on date/time.') {
        sh "${WORKSPACE}/SetBuildName.sh"
    }
    stage('Update ports tree.') {
        sh "${WORKSPACE}/UpdateTree.sh"
    }
    stage('Build packages for amd64 architecture.') {
        def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
        try {
            sh "${WORKSPACE}/BuildPackages.sh amd64 native ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for i386 architecture.') {
        def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
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
            def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
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
        def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
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
            def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
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
        def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
        try {
            sh "${WORKSPACE}/BuildPackages.sh aarch64 cross ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Build packages for mips64 architecture. (Cross building)') {
        def buildName=readFile encoding: 'utf-8', file: 'poudriere.buildname'
        try {
            sh "${WORKSPACE}/BuildPackages.sh mips64 cross ${buildName}"
            currentBuild.result = "SUCCESS"
        } catch (Exception e) {
            currentBuild.result = "FAILURE"
        }
    }
    stage('Clean up temporary files.') {
        cleanWs notFailBuild: true, patterns: [[pattern: 'poudriere.buildname', type: 'INCLUDE']]
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
        slackSend channel: "#jenkins", message: "Build finished - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
    }
}
