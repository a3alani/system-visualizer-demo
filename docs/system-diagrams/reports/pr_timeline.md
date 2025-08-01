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
