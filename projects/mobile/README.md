# Mobile Security Pipeline

iOS and Android security testing pipeline covering the OWASP Mobile Security Testing Guide (MSTG). Static analysis, dynamic analysis, certificate pinning, and secret detection run against both platforms.

---

## Security Controls

| Control                  | iOS                     | Android                       | Tool                      |
| ------------------------ | ----------------------- | ----------------------------- | ------------------------- |
| SAST                     | `security-config.swift` | `SecurityConfig.kt`           | Semgrep custom rules      |
| Certificate pinning      | `security-config.swift` | `network_security_config.xml` | Manual + MobSF validation |
| Root/jailbreak detection | Yes                     | Yes                           | Runtime check             |
| Obfuscation              | Bitcode                 | ProGuard/R8                   | Build config              |
| Secret detection         | All source files        | All source files              | detect-secrets            |
| Dynamic analysis         | APK/IPA upload          | APK/IPA upload                | MobSF DAST                |

---

## Local Run

```bash
# MobSF dynamic analysis dashboard
open http://localhost:8008   # Upload APK or IPA for analysis

# Run secret detection on all mobile source
cd projects/mobile
detect-secrets scan ios/ android/

# Run Semgrep SAST
semgrep --config=testing/semgrep-rules/ ios/ android/
```

---

## Key Files

```
mobile/
├── ios/
│   ├── security-config.swift       # Certificate pinning + jailbreak detection
│   └── ...                         # Swift app source
├── android/
│   ├── SecurityConfig.kt           # Certificate pinning + root detection
│   ├── res/xml/network_security_config.xml  # Network security configuration
│   └── ...                         # Kotlin app source
└── testing/
    ├── semgrep-rules/              # Custom Semgrep rules for mobile security
    ├── mobsf-config.json           # MobSF scan configuration
    └── dast-config.yaml            # DAST pipeline configuration
```

---

## Demo: Secret Leak Detection

```bash
# Inject a hardcoded API key into Android source
./shared/scripts/demo-mobile-leak.sh inject

# Run Semgrep — catches the hardcoded credential
./shared/scripts/demo-mobile-leak.sh scan

# Clean up
./shared/scripts/demo-mobile-leak.sh clean
```

The scan output shows the file, line number, and rule that fired (`hardcoded-api-key`).
