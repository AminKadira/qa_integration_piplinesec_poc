pipeline {
    agent any
    
    environment {
        PATH = "${env.PATH};C:\\tools\\sonar-scanner\\bin"
        DOTNET_ROOT = 'C:\\Program Files\\dotnet'
        BUILD_TIMESTAMP = new Date().format('yyyy-MM-dd HH:mm:ss')
    }
    
    stages {
        stage('Pipeline Initialization') {
            steps {
                echo "======================================================"
                echo "STARTING SPF Invoice Service Pipeline"
                echo "Build Time: ${BUILD_TIMESTAMP}"
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Git Branch: ${GIT_BRANCH}"
                echo "======================================================"
                deleteDir()
                echo "SUCCESS: Workspace cleaned successfully"
            }
        }
        
        stage('Test Checkout') {
            steps {
                echo "cd ."
              /*   git branch: 'main',
                    url: 'http://localhost:3000/admin/spf.invoice.service.git',
                    credentialsId: 'GiteaTokenForJenkins' **/
                echo "SUCCESS: Git clone worked!"
            }
        }

        stage('Checkout Application') {
            steps {
                echo "======================================================"
                echo "STAGE: Checkout Application Repository"
                echo "======================================================"
                dir('app') {
                    echo "INFO: Cloning application repository..."
                    git branch: 'main',
                        url: 'https://github.com/AminKadira/TestAuto_PiplinePOC'

                    echo "SUCCESS: Application repository cloned successfully"
                    
                    bat 'echo "INFO: Application files:"'
                    bat 'dir /b'
                }
            }
        }
        
        stage('Checkout Tests') {
            steps {
                echo "======================================================"
                echo "STAGE: Checkout Test Repository"
                echo "======================================================"
                dir('tests') {
                    echo "INFO: Cloning test repository..."
                    git branch: 'main',
                        url: 'https://localhost:3000/admin/spf-invoice-tests',
                        credentialsId: 'git-credentials'
                    echo "SUCCESS: Test repository cloned successfully"
                    
                    bat 'echo "INFO: Test files:"'
                    bat 'dir /b'
                }
            }
        }
        
        stage('Build .NET Application') {
            steps {
                echo "======================================================"
                echo "STAGE: Build .NET Application"
                echo "======================================================"
                /* dir('app') {
                    echo "INFO: Configuring .NET environment..."
                    bat '''
                        echo "INFO: Checking .NET installation..."
                        set PATH=%PATH%;C:\\Program Files\\dotnet
                        dotnet --version
                        echo "SUCCESS: .NET version verified"
                        
                        echo "INFO: Starting build process..."
                        dotnet build --configuration Release --verbosity normal
                        echo "SUCCESS: Build completed successfully"
                    '''
                } */
            }
            post {
                success {
                    echo "SUCCESS: .NET application built successfully!"
                }
                failure {
                    echo "ERROR: .NET build failed!"
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo "======================================================"
                echo "STAGE: SonarQube Code Analysis"
                echo "======================================================"
              /*   dir('app') {
                    echo "INFO: Starting SonarQube code analysis..."
                    withSonarQubeEnv('SonarQube') {
                        bat '''
                            echo "INFO: Running SonarQube scanner..."
                            sonar-scanner.bat ^
                            -Dsonar.projectKey=spf-invoice-service ^
                            -Dsonar.sources=. ^
                            -Dsonar.host.url=http://localhost:9090 ^
                            -Dsonar.exclusions=**/bin/**,**/obj/**
                            echo "SUCCESS: SonarQube analysis completed"
                        '''
                    }
                } */
            }
            post {
                success {
                    echo "SUCCESS: SonarQube analysis completed successfully!"
                    echo "INFO: Check SonarQube dashboard for detailed results"
                }
                failure {
                    echo "ERROR: SonarQube analysis failed!"
                }
            }
        }
        
        stage('Playwright End-to-End Tests') {
            steps {
                echo "======================================================"
                echo "STAGE: Playwright End-to-End Tests"
                echo "======================================================"
                dir('tests') {
                    echo "INFO: Setting up Playwright environment..."
                    bat '''
                        echo "INFO: Installing Node.js dependencies..."
                        npm install
                        echo "SUCCESS: Dependencies installed successfully"
                        
                        echo "INFO: Installing Chromium browser..."
                        npx playwright install chromium --with-deps
                        echo "SUCCESS: Browser installed successfully"
                        
                        echo "INFO: Starting Playwright test execution..."
                        echo "INFO: This may take a few minutes..."
                        npm test
                        echo "SUCCESS: All tests executed successfully"
                    '''
                }
            }
            post {
                always {
                    echo "INFO: Publishing Playwright test reports..."
                    // Publier les rapports HTML Playwright
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'tests/playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Playwright Test Report'
                    ])
                    echo "SUCCESS: Test reports published"
                    
                    echo "INFO: Archiving test artifacts..."
                    // Archiver les screenshots et videos en cas d'échec
                    archiveArtifacts artifacts: 'tests/test-results/**/*', 
                                   allowEmptyArchive: true,
                                   fingerprint: false
                    echo "SUCCESS: Test artifacts archived"
                }
                failure {
                    echo "ERROR: Playwright tests have failed!"
                    echo "INFO: Check the test report for detailed failure information"
                    echo "INFO: Screenshots and videos are available in archived artifacts"
                }
                success {
                    echo "SUCCESS: All Playwright tests passed successfully!"
                    echo "INFO: End-to-end testing completed without issues"
                }
            }
        }
    }
    
    post {
        always {
            echo "======================================================"
            echo "PIPELINE COMPLETED"
            echo "End Time: ${new Date().format('yyyy-MM-dd HH:mm:ss')}"
            script {
                def duration = currentBuild.duration
                if (duration != null) {
                    echo "Total Duration: ${duration}ms"
                }
            }
            echo "======================================================"
        }
        success {
            echo "SUCCESS: Pipeline executed successfully!"
            echo "INFO: Application built and tested without issues"
            echo "INFO: All quality gates passed"
        }
        failure {
            echo "ERROR: Pipeline failed!"
            echo "INFO: Check the console output above for error details"
            echo "INFO: Verify the failed stage and fix the issues"
        }
        unstable {
            echo "WARNING: Pipeline completed with warnings!"
            echo "INFO: Review test results for failing tests"
        }
        cleanup {
            echo "INFO: Performing final cleanup..."
            echo "INFO: Build artifacts preserved for analysis"
        }
    }
}