@Library('pipeline-poc-shared-library') _

pipeline {
    agent any
    
    environment {
        PIPELINE_CONFIG = readJSON file: "config/pipeline.json"
        SECURITY_CONFIG = readJSON file: "config/security.json"
        ENV_CONFIG = readJSON file: "config/environments/${params.ENVIRONMENT ?: 'test'}.json"
        BUILD_HASH = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    }
    
    stages {
        stage('Security Validation') {
            steps {
                securityValidation()
            }
        }
        
        stage('Secure Checkout') {
            parallel {
                stage('App Repository') {
                    steps {
                        secureCheckout('app', PIPELINE_CONFIG.repositories.application)
                    }
                }
                stage('Test Repository') {
                    steps {
                        secureCheckout('tests', PIPELINE_CONFIG.repositories.tests)
                    }
                }
            }
        }
        
        stage('OWASP Dependency Scan') {
            steps {
                dependencySecurityScan('app')
            }
            post {
                always { publishSecurityReports('dependency') }
            }
        }
        
        stage('Secure Build') {
            steps {
                dotnetSecureBuild('app')
            }
            post {
                success { signBuildArtifacts('app') }
            }
        }
        
        stage('SAST Analysis') {
            parallel {
                stage('SonarQube') {
                    steps { sonarSecurityAnalysis('app') }
                }
                stage('Security Code Scan') {
                    steps { securityCodeScan('app') }
                }
            }
        }
        
        stage('Secure Testing') {
            when { expression { params.RUN_TESTS != 'false' } }
            steps {
                secureE2ETests('tests')
            }
            post {
                always { 
                    sanitizeTestReports('tests')
                    publishSecurityReports('tests')
                }
            }
        }
    }
    
    post {
        always { 
            createSecurityAuditLog()
            secureCleanup()
        }
        success { notifySecurityTeam('SUCCESS') }
        failure { notifySecurityTeam('FAILURE') }
    }
}