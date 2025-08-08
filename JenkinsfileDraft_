@Library('pipeline-poc-shared-library') _

pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'SKIP_SECURITY_VALIDATION', defaultValue: false, description: 'Skip security validation stage')
        booleanParam(name: 'SKIP_DEPENDENCY_SCAN', defaultValue: false, description: 'Skip OWASP dependency scan')
        booleanParam(name: 'SKIP_SAST_ANALYSIS', defaultValue: false, description: 'Skip SAST security analysis')
        booleanParam(name: 'SKIP_SECURE_TESTING', defaultValue: false, description: 'Skip secure testing stage')
        booleanParam(name: 'SKIP_BUILD_SIGNING', defaultValue: false, description: 'Skip build artifacts signing')
        choice(name: 'ENVIRONMENT', choices: ['test', 'staging'], description: 'Target environment')
    }
    
    environment {
        BUILD_HASH = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    }
    
    stages {
        stage('Repository Checkout') {
            steps {
                checkout scm
                
                script {
                    if (!fileExists('config/pipeline.json')) {
                        error "config/pipeline.json expression  found in repository"
                    }
                    echo "Repository checked out, config files available"
                }
            }
        }
        
        stage('Configuration Loading') {
            steps {
                script {
                    def pipelineConfig = readJSON file: 'config/pipeline.json'
                    def securityConfig = readJSON file: 'config/security.json'
                    
                    env.PROJECT_NAME = pipelineConfig.project.name
                    env.APP_REPO_URL = pipelineConfig.repositories.application.url
                    env.TEST_REPO_URL = pipelineConfig.repositories.tests.url
                    
                    echo "Configuration loaded for: ${env.PROJECT_NAME}"
                }
            }
        }
        
        stage('Security Validation') {
            when {
                expression  { !params.SKIP_SECURITY_VALIDATION }
            }
            steps {
                securityValidation()
            }
        }
        
        stage('Secure Checkout') {
            steps {
                script {
                    def pipelineConfig = readJSON file: 'config/pipeline.json'
                    
                    parallel(
                        'App Repository': {
                            secureCheckout('app', pipelineConfig.repositories.application)
                        },
                        'Test Repository': {
                            secureCheckout('tests', pipelineConfig.repositories.tests)
                        }
                    )
                }
            }
        }
        
        stage('OWASP Dependency Scan') {
            when {
                expression  { !params.SKIP_DEPENDENCY_SCAN }
            }
            steps {
                script {
                    echo "Starting OWASP dependency scan..."
                    dir('app') {
                        sh './scripts/security/dependency-check.sh . ../config/security.json'
                    }
                }
            }
            post {
                always { 
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency Check Report'
                    ])
                }
            }
        }
        
        stage('Secure Build') {
            steps {
                script {
                    echo "Starting secure .NET build..."
                    dir('app') {
                        sh '../scripts/build/dotnet-build.sh . ../config/pipeline.json'
                    }
                }
            }
            post {
                success { 
                    script {
                        if (!params.SKIP_BUILD_SIGNING) {
                            signBuildArtifacts('app')
                        } else {
                            echo "Build signing skipped by parameter"
                        }
                    }
                }
            }
        }
        
        stage('SAST Analysis') {
            when {
                expression  { !params.SKIP_SAST_ANALYSIS }
            }
            parallel {
                stage('SonarQube') {
                    steps { 
                        script {
                            dir('app') {
                                withSonarQubeEnv('SonarQube') {
                                    sh '''
                                        sonar-scanner \
                                        -Dsonar.projectKey=spf-invoice-service \
                                        -Dsonar.sources=. \
                                        -Dsonar.exclusions=**/bin/**,**/obj/**,**/wwwroot/lib/** \
                                        -Dsonar.qualitygate.wait=true \
                                        -Dsonar.qualitygate.timeout=300
                                    '''
                                }
                            }
                        }
                    }
                }
                stage('Security Code Scan') {
                    steps { 
                        script {
                            dir('app') {
                                sh '../scripts/security/sast-scan.sh . ../config/security.json'
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        timeout(time: 5, unit: 'MINUTES') {
                            def qualityGate = waitForQualityGate()
                            if (qualityGate.status != 'OK') {
                                error "Quality gate failed: ${qualityGate.status}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Secure Testing') {
            when {
                expression  { !params.SKIP_SECURE_TESTING }
            }
            steps {
                script {
                    echo "Running secure E2E tests..."
                    dir('tests') {
                        sh '../scripts/test/run-playwright.sh .'
                    }
                }
            }
            post {
                always { 
                    script {
                        dir('tests') {
                            sh '../scripts/test/sanitize-reports.sh ./test-results'
                        }
                    }
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'tests/playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Secure Test Report'
                    ])
                }
            }
        } 
        
    }
    
    post {
        always {
            createSecurityAuditLog()
        }
        success {
            echo "Security pipeline completed - All gates passed"
        }
        failure {
            echo "SECURITY ALERT: Pipeline failed - Security review required"
            // emailext (
            //     subject: "SECURITY ALERT: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "Security pipeline failed. Immediate review required.",
            //     to: "security-team@company.com"
            // )
        }
        cleanup {
            // sh '''
                 echo "Secure cleanup..."
            //     find . -name "*.tmp" -delete
            //     find . -name "*.log" -exec rm -f {} + 2>/dev/null || true
            // '''
        }
    }
}