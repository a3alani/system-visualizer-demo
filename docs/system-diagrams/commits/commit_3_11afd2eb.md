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
