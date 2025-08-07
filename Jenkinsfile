@Library('pipeline-poc-shared-library') _

pipeline {
    agent any
    
environment {
        // Variables simples uniquement dans environment
        BUILD_HASH = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    }
    
    stages {
        stage('Configuration Loading') {
            steps {
                script {
                    // Chargement configs dans script block
                    env.PIPELINE_CONFIG_JSON = readFile('config/pipeline.json')
                    env.SECURITY_CONFIG_JSON = readFile('config/security.json')
                    env.ENV_CONFIG_JSON = readFile("config/environments/${params.ENVIRONMENT ?: 'test'}.json")
                    
                    // Parse JSON quand nécessaire
                    def pipelineConfig = readJSON text: env.PIPELINE_CONFIG_JSON
                    def securityConfig = readJSON text: env.SECURITY_CONFIG_JSON
                    
                    echo "✅ Configuration loaded for: ${pipelineConfig.project.name}"
                }
            }
        }
        
        stage('Security Validation') {
            steps {
                securityValidation()
            }
        }
        
        stage('Secure Checkout') {
            steps {
                script {
                    def pipelineConfig = readJSON text: env.PIPELINE_CONFIG_JSON
                    
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
    
    /**post {
        always { 
            createSecurityAuditLog()
            secureCleanup()
        }
        success { notifySecurityTeam('SUCCESS') }
        failure { notifySecurityTeam('FAILURE') }
    }**/
    post {
    always {
        script {
            echo "🧹 Pipeline cleanup completed"
        }
    }
    
    success {
        echo "SUCCESS: Security pipeline completed - All gates passed"
    }
    
    failure {
        echo "SECURITY ALERT: Pipeline failed - Security review required"
    }
}
}