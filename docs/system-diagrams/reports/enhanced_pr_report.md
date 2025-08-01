graph TD
  subgraph "Enhanced PR Report"
    AIRisk["🤖 AI Risk Score: 0/100<br/>Level: Low"]:::lowRisk
    subgraph "Changed Files"
    end

  end

  %% Direct file changes
  %% Dependency relationships

  classDef highImpact fill:#ff6666,stroke:#cc0000,stroke-width:2px
  classDef mediumImpact fill:#ffaa66,stroke:#cc6600,stroke-width:2px
  classDef lowImpact fill:#66ff66,stroke:#00cc00,stroke-width:2px
  classDef highComplexity fill:#ffcccc,stroke:#ff6666,stroke-width:2px
  classDef mediumComplexity fill:#ffffcc,stroke:#ffaa66,stroke-width:2px
  classDef lowComplexity fill:#ccffcc,stroke:#66ff66,stroke-width:2px
  classDef criticalRisk fill:#cc0000,stroke:#990000,stroke-width:3px,color:#ffffff
  classDef highRisk fill:#ff3333,stroke:#cc0000,stroke-width:2px
  classDef mediumRisk fill:#ffaa66,stroke:#cc6600,stroke-width:2px
  classDef lowRisk fill:#66ff66,stroke:#00cc00,stroke-width:2px
