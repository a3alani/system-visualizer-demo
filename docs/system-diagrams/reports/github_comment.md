## 🔍 Automated PR Analysis

### 🟡 Risk Assessment
**AI Risk Score:** 34/100 (Medium)

**Recommendations:**
- Add tests for the changes to reduce risk

### 📈 Commit Progression Analysis

<details>
<summary>🗓️ <strong>Timeline Overview</strong></summary>

```mermaid
graph LR
  subgraph "PR Timeline: Risk Progression"
    C1["76ad123a<br/>Impact: 21<br/>🔒🗄️"]:::mediumRisk
    C1 --> C2
    C2["112c4b6a<br/>Impact: 0<br/>"]:::lowRisk
    C2 --> C3
    C3["11afd2eb<br/>Impact: 15<br/>🔒🗄️"]:::lowRisk
    C3 --> C4
    C4["249b3294<br/>Impact: 13<br/>🗄️"]:::lowRisk
    C4 --> C5
    C5["722ef5cd<br/>Impact: 13<br/>"]:::lowRisk
  end

  subgraph "Cumulative Risk Analysis"
    FinalRisks["Final State<br/>🔒 Security: 4<br/>⚡ Performance: 0<br/>🗄️ Database: 5"]:::finalState
  end

  C5 --> FinalRisks
  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px
  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px
  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px
  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px
  classDef finalState fill:#e1f5fe,stroke:#0277bd,stroke-width:3px

```

</details>

<details>
<summary>📝 <strong>Commit 1: 76ad123a</strong> - ⚡ Add payment security enhancements with risk scenarios</summary>

**Impact Score:** 21/100
**Files Changed:** 3
**Risk Categories:** security, database, test_coverage

```mermaid
graph TD
  subgraph "Commit 1: 76ad123a"
    CommitInfo["📝 76ad123a<br/>Impact: 21/100<br/>Files: 3"]:::mediumRisk
    subgraph "Changed Files"
      test_controller[test_controller]:::controllerFile
      user[user]:::modelFile
      user_service[user_service]:::serviceFile
    end
    SecurityRisks["🔒 Security<br/>3 issues"]:::securityRisk
    CommitInfo --> SecurityRisks
    DatabaseRisks["🗄️ Database<br/>2 issues"]:::databaseRisk
    CommitInfo --> DatabaseRisks
    Test_coverageRisks["🧪 Test Coverage<br/>3 issues"]:::test_coverageRisk
    CommitInfo --> Test_coverageRisks
  end

  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px
  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px
  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px
  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px
  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px
  classDef securityRisk fill:#ffebee,stroke:#d32f2f,stroke-width:2px
  classDef performanceRisk fill:#fff8e1,stroke:#ffa000,stroke-width:2px
  classDef databaseRisk fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
  classDef test_coverageRisk fill:#f1f8e9,stroke:#689f38,stroke-width:2px

```

🔒 **Security Issues:** 3
🗄️ **Database Issues:** 2
🧪 **Test Coverage Issues:** 3

</details>

<details>
<summary>📝 <strong>Commit 2: 112c4b6a</strong> - trigger</summary>

**Impact Score:** 0/100
**Files Changed:** 0

```mermaid
graph TD
  subgraph "Commit 2: 112c4b6a"
    CommitInfo["📝 112c4b6a<br/>Impact: 0/100<br/>Files: 0"]:::lowRisk
  end

  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px
  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px
  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px
  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px
  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px
  classDef securityRisk fill:#ffebee,stroke:#d32f2f,stroke-width:2px
  classDef performanceRisk fill:#fff8e1,stroke:#ffa000,stroke-width:2px
  classDef databaseRisk fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
  classDef test_coverageRisk fill:#f1f8e9,stroke:#689f38,stroke-width:2px

```


</details>

<details>
<summary>📝 <strong>Commit 3: 11afd2eb</strong> - 🔐 Add comprehensive authentication & authorization system</summary>

**Impact Score:** 15/100
**Files Changed:** 2
**Risk Categories:** security, database, test_coverage

```mermaid
graph TD
  subgraph "Commit 3: 11afd2eb"
    CommitInfo["📝 11afd2eb<br/>Impact: 15/100<br/>Files: 2"]:::lowRisk
    subgraph "Changed Files"
      test_controller[test_controller]:::controllerFile
      user[user]:::modelFile
    end
    SecurityRisks["🔒 Security<br/>1 issues"]:::securityRisk
    CommitInfo --> SecurityRisks
    DatabaseRisks["🗄️ Database<br/>1 issues"]:::databaseRisk
    CommitInfo --> DatabaseRisks
    Test_coverageRisks["🧪 Test Coverage<br/>2 issues"]:::test_coverageRisk
    CommitInfo --> Test_coverageRisks
  end

  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px
  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px
  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px
  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px
  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px
  classDef securityRisk fill:#ffebee,stroke:#d32f2f,stroke-width:2px
  classDef performanceRisk fill:#fff8e1,stroke:#ffa000,stroke-width:2px
  classDef databaseRisk fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
  classDef test_coverageRisk fill:#f1f8e9,stroke:#689f38,stroke-width:2px

```

🔒 **Security Issues:** 1
🗄️ **Database Issues:** 1
🧪 **Test Coverage Issues:** 2

</details>

<details>
<summary>📝 <strong>Commit 4: 249b3294</strong> - 💳 Integrate comprehensive payment gateway system</summary>

**Impact Score:** 13/100
**Files Changed:** 2
**Risk Categories:** database, test_coverage

```mermaid
graph TD
  subgraph "Commit 4: 249b3294"
    CommitInfo["📝 249b3294<br/>Impact: 13/100<br/>Files: 2"]:::lowRisk
    subgraph "Changed Files"
      document[document]:::modelFile
      user_service[user_service]:::serviceFile
    end
    DatabaseRisks["🗄️ Database<br/>2 issues"]:::databaseRisk
    CommitInfo --> DatabaseRisks
    Test_coverageRisks["🧪 Test Coverage<br/>2 issues"]:::test_coverageRisk
    CommitInfo --> Test_coverageRisks
  end

  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px
  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px
  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px
  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px
  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px
  classDef securityRisk fill:#ffebee,stroke:#d32f2f,stroke-width:2px
  classDef performanceRisk fill:#fff8e1,stroke:#ffa000,stroke-width:2px
  classDef databaseRisk fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
  classDef test_coverageRisk fill:#f1f8e9,stroke:#689f38,stroke-width:2px

```

🗄️ **Database Issues:** 2
🧪 **Test Coverage Issues:** 2

</details>

<details>
<summary>📝 <strong>Commit 5: 722ef5cd</strong> - 📊 Add comprehensive performance monitoring & optimization system</summary>

**Impact Score:** 13/100
**Files Changed:** 2
**Risk Categories:** test_coverage

```mermaid
graph TD
  subgraph "Commit 5: 722ef5cd"
    CommitInfo["📝 722ef5cd<br/>Impact: 13/100<br/>Files: 2"]:::lowRisk
    subgraph "Changed Files"
      firm[firm]:::modelFile
      email_worker[email_worker]:::workerFile
    end
    Test_coverageRisks["🧪 Test Coverage<br/>2 issues"]:::test_coverageRisk
    CommitInfo --> Test_coverageRisks
  end

  classDef lowRisk fill:#ccffcc,stroke:#00cc00,stroke-width:2px
  classDef mediumRisk fill:#ffffcc,stroke:#ffaa00,stroke-width:2px
  classDef highRisk fill:#ffcccc,stroke:#ff6600,stroke-width:2px
  classDef criticalRisk fill:#ff6666,stroke:#cc0000,stroke-width:3px
  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px
  classDef securityRisk fill:#ffebee,stroke:#d32f2f,stroke-width:2px
  classDef performanceRisk fill:#fff8e1,stroke:#ffa000,stroke-width:2px
  classDef databaseRisk fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
  classDef test_coverageRisk fill:#f1f8e9,stroke:#689f38,stroke-width:2px

```

🧪 **Test Coverage Issues:** 2

</details>

### 📊 Change Statistics
- **Files Changed:** 0
- **Models:** 0
- **Controllers:** 0
- **Services:** 0

### ⚠️ Issues Found
- **Performance Risks:** 4
- **Security Risks:** 1
- **Database Impacts:** 3

### 📋 Detailed Reports
View the complete analysis in the generated reports:
- [Risk Assessment](./docs/system-diagrams/reports/pr_risk_assessment.md)
- [Impact Summary](./docs/system-diagrams/reports/pr_impact_summary.md)
- [Visual Diagram](./docs/system-diagrams/reports/enhanced_pr_report.md)
- [📈 Timeline Analysis](./docs/system-diagrams/reports/pr_timeline.md)
- [📚 Commit Analysis Index](./docs/system-diagrams/commits/index.md)

<details>
<summary>🎯 View Overall Dependency Diagram</summary>

```mermaid
graph TD
  subgraph "PR Summary"
    PRInfo["📝 Pull Request<br/>6 files changed<br/>Risk Score: 34/100"]:::riskScore
    subgraph "Changed Files"
      test_controller[test_controller]:::controllerFile
      document[document]:::modelFile
      firm[firm]:::modelFile
      user[user]:::modelFile
      user_service[user_service]:::serviceFile
      email_worker[email_worker]:::workerFile
    end
  end

  classDef modelFile fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
  classDef controllerFile fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
  classDef serviceFile fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
  classDef workerFile fill:#fff3e0,stroke:#f57c00,stroke-width:2px
  classDef riskScore fill:#ffeb3b,stroke:#f57f17,stroke-width:3px
```
</details>

---
_Generated by System Visualizer at 2025-08-01 10:38:05_