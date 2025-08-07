// Jenkinsfile temporaire pour tester
pipeline {
    agent any
    
    stages {
        stage('Test Structure') {
            steps {
                script {
                    // Vérifier structure après checkout
                    sh 'ls -la'
                    sh 'ls -la vars/'
                    
                    // Test méthode directement
                    echo "load securityValidation()"
                    def securityValidation = load 'vars/securityValidation.groovy'
                    echo"run securityValidation()"
                    securityValidation()
                }
            }
        }
    }
}