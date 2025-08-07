# DevSecOps Pipeline .NET - OWASP Compliant

Pipeline Jenkins modulaire pour applications .NET avec sécurité intégrée selon standards OWASP.

##  Architecture

### Structure projet
```
├── Jenkinsfile                 # Orchestration pipeline
├── config/
│   ├── pipeline.json          # Configuration principale
│   ├── security.json          # Seuils sécurité OWASP
│   └── environments/
│       ├── dev.json           # Config développement
│       ├── staging.json       # Config pré-production
│       └── prod.json          # Config production
├── scripts/
│   ├── security/              # Scripts sécurité OWASP
│   │   ├── dependency-check.sh
│   │   ├── sast-scan.sh
│   │   └── artifact-signing.sh
│   ├── build/                 # Scripts build .NET
│   │   ├── dotnet-build.sh
│   │   └── validate-build.sh
│   ├── test/                  # Scripts test sécurisés
│   │   ├── run-playwright.sh
│   │   └── sanitize-reports.sh
│   └── utils/                 # Utilitaires
│       ├── git-validation.sh
│       └── cleanup.sh
├── templates/
│   └── suppression.xml        # Suppressions OWASP
├── vars/                      # Jenkins Shared Library
│   ├── securityValidation.groovy
│   ├── secureCheckout.groovy
│   ├── signBuildArtifacts.groovy
│   └── createSecurityAuditLog.groovy
└── docs/
    └── security-runbook.md    # Runbook sécurité
```

### Pipeline stages
```
Security Validation → Secure Checkout → OWASP Dependency Scan → 
Secure Build → SAST Analysis → Secure Testing → Security Audit
```

## Quick Start

### 1. Configuration Jenkins

**Pré-requis :**
- Jenkins avec plugins : Pipeline, SonarQube, HTML Publisher
- OWASP Dependency Check installé
- GPG configuré pour signature d'artefacts
- Credentials configurés : `git-credentials`, `sonarqube-token`, `gpg-private-key`, `gpg-passphrase`

**Setup pipeline :**
```bash
# 1. Cloner le repository
git clone <your-pipeline-repo>

# 2. Copier dans votre projet
cp -r devSecOps-pipeline/* /path/to/your/project/

# 3. Adapter la configuration
vim config/pipeline.json
vim config/security.json
```

### 2. Configuration projet

**Éditer `config/pipeline.json` :**
```json
{
    "project": {
        "name": "your-project-name",
        "version": "1.0.0"
    },
    "repositories": {
        "application": {
            "url": "https://git.company.com/your-app-repo",
            "branch": "main",
            "credentialsId": "git-credentials"
        },
        "tests": {
            "url": "https://git.company.com/your-tests-repo",
            "branch": "main",
            "credentialsId": "git-credentials"
        }
    },
    "build": {
        "dotnet": {
            "version": "8.0",
            "configuration": "Release",
            "treatWarningsAsErrors": true,
            "runAnalyzers": true
        }
    }
}
```

**Configurer les seuils sécurité dans `config/security.json` :**
```json
{
    "owasp": {
        "dependencyCheck": {
            "failOnCVSS": 7.0
        },
        "sast": {
            "thresholds": {
                "highSeverity": 0,
                "mediumSeverity": 5
            }
        }
    }
}
```

### 3. Setup Jenkins Shared Library

**Configuration globale Jenkins :**
1. Manage Jenkins → Configure System → Global Pipeline Libraries
2. Ajouter library : `pipeline-shared-library`
3. Default version : `main`
4. Source : Git avec URL du repository vars/

**Variables environnement requises :**
```bash
# Secrets management
SONAR_TOKEN=<sonarqube-token>
GPG_PRIVATE_KEY=<gpg-private-key-file>  
GPG_PASSPHRASE=<gpg-passphrase>

# Configuration sécurité
ENHANCED_SECURITY=true  # Pour branches protégées
```

## Méthodes Sécurité - Jenkins Shared Library

### 1. securityValidation()

**Fonction :** Validation pré-pipeline complète
```groovy
// Validation dans vars/securityValidation.groovy
- Vérification config/security.json présent
- Validation outils sécurité (dependency-check, gpg, git)
- Contrôle variables environnement sensibles
- Detection branches protégées (enhanced security)
```

**Critères bloquants :**
- Absence configuration sécurité
- Outils sécurité manquants
- Variables sensibles non définies

### 2. secureCheckout()

**Fonction :** Checkout sécurisé avec validation
```groovy  
// Usage dans Jenkinsfile
secureCheckout('app', PIPELINE_CONFIG.repositories.application)
```

**Fonctionnalités sécurité :**
- Nettoyage workspace sécurisé
- Validation URL repository (pas localhost en prod)
- Vérification signatures commits (branches protégées)
- Scan basique secrets dans historique
- Export variables sécurité (REPO_COMMIT_HASH, REPO_BRANCH)

### 3. signBuildArtifacts()

**Fonction :** Signature cryptographique artefacts
```groovy
// Post-build automatique
signBuildArtifacts('app')
```

**Process sécurisé :**
- Import clé GPG privée temporaire
- Signature détachée artefacts (.dll, .exe, .nupkg)
- Vérification signatures générées
- Génération manifest signatures avec hashes SHA256
- Nettoyage automatique clés privées
- Archive signatures avec artefacts

### 4. createSecurityAuditLog()

**Fonction :** Audit trail complet compliance
```groovy
// Post-pipeline toujours exécuté
createSecurityAuditLog()
```

**Données auditées :**
- Metadata pipeline (timestamp, build, commit)
- Status sécurité (enhanced, signatures, SAST, OWASP)
- Compliance OWASP (quality gate, vulnérabilités, seuils)
- Repository information (commit, branch, URL)
- Export JSON + Markdown + HTML report

## Sécurité OWASP

### Security Gates intégrés

**1. Pre-Pipeline Security Validation**
```bash
# Validation complète avant exécution
Configuration sécurité présente
Outils sécurité disponibles  
Credentials configurés
Enhanced security (branches protégées)
```

**2. Secure Repository Management**
```bash
# Checkout sécurisé avec validation
Nettoyage workspace sécurisé
Validation URLs repository
Vérification signatures commits
Scan secrets historique basique
```

**3. Cryptographic Artifact Signing**
```bash
# Signature GPG automatique
Signature détachée tous artefacts
Vérification intégrité signatures
Manifest signatures avec hashes
Nettoyage clés privées post-usage
```

**4. Comprehensive Security Audit**
```bash
# Audit trail compliance
Export JSON/Markdown/HTML
Traçabilité complète pipeline
Status OWASP compliance
Archiving sécurisé rapports
```

### Configuration sécurité

**Seuils par défaut :**
- CVSS Score : ≥ 7.0 → Build FAILED
- Vulnérabilités High : 0 toléré
- Vulnérabilités Medium : 5 maximum

**Enhanced Security (branches protégées) :**
- Validation signatures commits
- Contrôles renforcés URL repositories
- Audit logging complet

## 🛠️ Scripts disponibles

### Scripts sécurité
```bash
# Scan vulnérabilités dépendances
./scripts/security/dependency-check.sh ./app

# Analyse SAST
./scripts/security/sast-scan.sh ./app

# Signature artefacts (legacy - maintenant intégré)
./scripts/security/artifact-signing.sh ./app/bin
```

### Scripts build
```bash
# Build sécurisé .NET
./scripts/build/dotnet-build.sh ./app

# Validation build
./scripts/build/validate-build.sh ./app/bin
```

### Scripts test
```bash
# Tests E2E sécurisés
./scripts/test/run-playwright.sh ./tests

# Nettoyage rapports
./scripts/test/sanitize-reports.sh ./tests/reports
```

## Rapports et monitoring

### Rapports générés
- **Security Audit Report** : `security-audit.json` + `security-audit.md`
- **OWASP Dependency Check** : `dependency-check-report.html`
- **SonarQube Quality Gate** : Dashboard SonarQube
- **Artifact Signatures** : `signatures.manifest.asc`
- **Playwright Tests** : `playwright-report/index.html`

### Audit trail sécurisé

**security-audit.json structure :**
```json
{
    "metadata": {
        "timestamp": "2024-08-07T14:30:00Z",
        "pipeline": "spf-invoice-service",
        "buildHash": "abc123..."
    },
    "security": {
        "enhancedSecurity": true,
        "artifactsSigned": true,
        "sastAnalysis": true,
        "dependencyCheck": true
    },
    "compliance": {
        "owaspCompliant": true,
        "vulnerabilitiesFound": 0
    }
}
```

## Configuration environnements

### Multi-environment support

**Fichiers par environnement :**
- `config/environments/dev.json` : Développement
- `config/environments/staging.json` : Pré-production  
- `config/environments/prod.json` : Production

**Enhanced Security automatique :**
```json
{
    "security": {
        "protectedBranches": ["main", "master", "release/*"],
        "enforceCommitSignatures": true,
        "blockLocalhostUrls": true
    }
}
```

## Troubleshooting

### Erreurs sécurité communes

**1. Security Validation failed**
```bash
# Vérifier configuration
ls -la config/security.json
cat config/security.json | jq .

# Vérifier outils sécurité
which dependency-check.sh
gpg --version
```

**2. Secure Checkout failed**
```bash
# URLs localhost en production
# Éditer config/pipeline.json avec URLs HTTPS

# Signatures commits manquantes
git log --show-signature -1
git config --global user.signingkey <key-id>
```

**3. Artifact Signing failed**
```bash
# Vérifier credentials GPG
echo $GPG_PASSPHRASE | gpg --batch --decrypt test-file

# Import clé manuelle test
gpg --import gpg-private-key.asc
gpg --list-secret-keys
```

**4. Security Audit incomplete**
```bash
# Vérifier variables environnement
env | grep -E "(SONAR|OWASP|SECURITY)"

# Forcer génération audit
./vars/createSecurityAuditLog.groovy
```

### Debug mode sécurité
```bash
# Activer debug complet
export DEBUG_SECURITY=1
export ENHANCED_SECURITY=true

# Logs détaillés méthodes sécurité
tail -f /var/log/jenkins/jenkins.log | grep "SECURITY"
```

## Maintenance

### Mise à jour seuils sécurité
1. Éditer `config/security.json`
2. Tester avec pipeline de validation
3. Commit et push - application automatique

### Gestion signatures GPG
```bash
# Rotation clés GPG
gpg --gen-key
gpg --export-secret-keys > new-private-key.asc

# Update Jenkins credentials
# Manage Jenkins → Credentials → Update gpg-private-key
```

### Extension méthodes sécurité
1. Ajouter méthode dans `vars/newSecurityMethod.groovy`
2. Intégrer dans `Jenkinsfile` 
3. Tester avec pipeline non-prod
4. Documentation update

## Documentation

- **Security Implementation** : `docs/security-implementation.md`
- **Jenkins Shared Library** : `docs/shared-library-guide.md`
- **Compliance Runbook** : `docs/compliance-runbook.md`
- **GPG Key Management** : `docs/gpg-key-management.md`

## Contributing

### Standards sécurité

**Shared Library développement :**
```groovy
// vars/newMethod.groovy
def call(Map config = [:]) {
    script {
        echo " Security method: ${config.method}"
        
        // Validation input
        if (!config.required) {
            error "SECURITY: Required parameter missing"
        }
        
        // Implementation sécurisée
        // ...
        
        echo " Security method completed"
    }
}
```

**Tests méthodes sécurité :**
```bash
# Test unitaire shared library
./test-shared-library.sh vars/securityValidation.groovy

# Test intégration pipeline
jenkinsfile-runner --file Jenkinsfile --runTests
```

## License

MIT License - voir `LICENSE` file pour détails.

## Support

- **Security Issues** : security-team@company.com
- **Technical Support** : devops-team@company.com
- **Documentation** : Wiki projet Jenkins
- **Emergency** : On-call DevSecOps team

## Security Compliance

**Standards respectés :**
- OWASP DevSecOps Guideline
- NIST Cybersecurity Framework
- ISO 27001 Development Security
- SANS Secure Development

**Audit externe :**
- Pen testing quarterly
- Security review code changes
- Compliance assessment annual

---

**Note :** Pipeline testé avec Jenkins 2.4+, .NET 8.0, OWASP Dependency Check 9.0+, GPG 2.2+
