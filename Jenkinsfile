#!groovy

pipeline {
    agent {
        label "docker"
    }
    options {
        timestamps()
        timeout(time: 3, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '5'))
        disableConcurrentBuilds()
    }
    environment {
        // In case another branch beside master or develop should be deployed, enter it here
        BRANCH_TO_DEPLOY = 'xyz'
        GITHUB_TOKEN = credentials('cdc81429-53c7-4521-81e9-83a7992bca76')
        DISCORD_WEBHOOK = credentials('991ce248-5da9-4068-9aea-8a6c2c388a19')
        CURRENT_DATE = sh(
                script: "printf \$(date +%Y-%m-%d)",
                returnStdout: true
        )
    }
    parameters {
        string(name: 'ALIAS_RELEASE', defaultValue: '', description: 'Which release of Aliaswallet should be used? (i. e. 4.3.0 or Build123)')
        string(name: 'GIT_COMMIT_SHORT', defaultValue: '', description: 'Git short commit, which is part of the name of required archive.')
    }
    stages {
        stage('Notification') {
            steps {
                // Using result state 'ABORTED' to mark the message on discord with a white border.
                // Makes it easier to distinguish job-start from job-finished
                discordSend(
                        description: "Started build #$env.BUILD_NUMBER",
                        image: '',
                        link: "$env.BUILD_URL",
                        successful: true,
                        result: "ABORTED",
                        thumbnail: 'https://wiki.jenkins-ci.org/download/attachments/2916393/headshot.png',
                        title: "$env.JOB_NAME",
                        webhookURL: "${DISCORD_WEBHOOK}"
                )
            }
        }
        stage('Check if required parameters given') {
            when {
                allOf {
                    expression { ALIAS_RELEASE == "" }
                    expression { GIT_COMMIT_SHORT == "" }
                }
            }
            steps {
                script {
                    // Abort build if required params are empty
                    currentBuild.result = 'ABORTED'
                    error('ALIAS_RELEASE and GIT_COMMIT_SHORT must be given!')
                }
            }
        }
        stage('Build image') {
            steps {
                script {
                    sh(
                            script: """
                                sudo modprobe loop max_loop=256
                                rm -rf ${WORKSPACE}/work
                                echo IMG_NAME=Aliaswallet > config
                                echo ALIAS_RELEASE=${ALIAS_RELEASE} >> config
                                echo GIT_COMMIT_SHORT=${GIT_COMMIT_SHORT} >> config
                                echo ENABLE_SSH=1 >> config
                                cat config
                                touch ./stage4/SKIP ./stage4/SKIP_IMAGES ./stage5/SKIP ./stage5/SKIP_IMAGES
                                ./build-docker.sh
                            """
                    )
                }
            }
        }
        stage('Deploy image') {
            steps {
                script {
                    sh(
                            script: """
                                docker run \\
                                    --rm \\
                                    -t \\
                                    -e GITHUB_TOKEN=${GITHUB_TOKEN} \\
                                    -v ${WORKSPACE}/deploy/:/filesToUpload \\
                                    aliascash/github-uploader:latest \\
                                    github-release upload \\
                                        --user aliascash \\
                                        --repo alias-wallet \\
                                        --tag ${ALIAS_RELEASE} \\
                                        --name "Alias-${ALIAS_RELEASE}-${GIT_COMMIT_SHORT}-RaspbianLight.zip" \\
                                        --file /filesToUpload/image_${CURRENT_DATE}-Aliaswallet-lite.zip \\
                                        --replace
                            """
                    )
                }
            }
        }
    }
    post {
        always {
            sh "docker system prune --all --force"
        }
        success {
            script {
                if (!hudson.model.Result.SUCCESS.equals(currentBuild.getPreviousBuild()?.getResult())) {
                    emailext(
                            subject: "GREEN: '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                            body: '${JELLY_SCRIPT,template="html"}',
                            recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
//                            to: "to@be.defined",
//                            replyTo: "to@be.defined"
                    )
                }
                discordSend(
                        description: "Build #$env.BUILD_NUMBER finished successfully",
                        image: '',
                        link: "$env.BUILD_URL",
                        successful: true,
                        thumbnail: 'https://wiki.jenkins-ci.org/download/attachments/2916393/headshot.png',
                        title: "$env.JOB_NAME",
                        webhookURL: "${DISCORD_WEBHOOK}"
                )
            }
        }
        unstable {
            emailext(
                    subject: "YELLOW: '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                    body: '${JELLY_SCRIPT,template="html"}',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
//                    to: "to@be.defined",
//                    replyTo: "to@be.defined"
            )
            discordSend(
                    description: "Build #$env.BUILD_NUMBER finished unstable",
                    image: '',
                    link: "$env.BUILD_URL",
                    successful: true,
                    result: "UNSTABLE",
                    thumbnail: 'https://wiki.jenkins-ci.org/download/attachments/2916393/headshot.png',
                    title: "$env.JOB_NAME",
                    webhookURL: "${DISCORD_WEBHOOK}"
            )
        }
        failure {
            emailext(
                    subject: "RED: '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                    body: '${JELLY_SCRIPT,template="html"}',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
//                    to: "to@be.defined",
//                    replyTo: "to@be.defined"
            )
            discordSend(
                    description: "Build #$env.BUILD_NUMBER failed!",
                    image: '',
                    link: "$env.BUILD_URL",
                    successful: false,
                    thumbnail: 'https://wiki.jenkins-ci.org/download/attachments/2916393/headshot.png',
                    title: "$env.JOB_NAME",
                    webhookURL: "${DISCORD_WEBHOOK}"
            )
        }
    }
}
