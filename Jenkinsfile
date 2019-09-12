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
    }
    parameters {
        string(name: 'SPECTRECOIN_RELEASE', defaultValue: '3.0.8', description: 'Which release of Spectrecoin should be used?')
        string(name: 'GIT_COMMIT_SHORT', defaultValue: '69e1d6cd', description: 'Git short commit, which is part of the name of required archive.')
        string(name: 'BLOCKCHAIN_ARCHIVE_VERSION', defaultValue: '2019-09-04', description: 'Which date has the bootstrapped blockchain archive?', trim: false)
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
            steps {
                script {
                    sh(
                            script: """
                                if [ -z "${GIT_COMMIT_SHORT}" ] ; then
                                    echo "Parameter GIT_COMMIT_SHORT is required!"
                                    exit 1
                                fi
                            """
                    )
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
                                echo IMG_NAME=Spectrecoin > config
                                echo SPECTRECOIN_RELEASE=${SPECTRECOIN_RELEASE} >> config
                                echo GIT_COMMIT_SHORT=${GIT_COMMIT_SHORT} >> config
                                echo BLOCKCHAIN_ARCHIVE_VERSION=${BLOCKCHAIN_ARCHIVE_VERSION} >> config
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
                    def CURRENT_DATE = sh(
                            script: "printf \$(date +%Y-%m-%d)",
                            returnStdout: true
                    )
                    sh(
                            script: """
                                docker run \\
                                    --rm \\
                                    -t \\
                                    -e GITHUB_TOKEN=${GITHUB_TOKEN} \\
                                    -v ${WORKSPACE}/deploy/:/filesToUpload spectreproject/github-uploader:latest \\
                                    github-release upload \\
                                        --user spectrecoin \\
                                        --repo spectre \\
                                        --tag ${SPECTRECOIN_RELEASE} \\
                                        --name "Spectrecoin-${SPECTRECOIN_RELEASE}-${GIT_COMMIT_SHORT}-RaspbianLightBuster.zip" \\
                                        --file /filesToUpload/image_${CURRENT_DATE}-Spectrecoin.zip \\
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